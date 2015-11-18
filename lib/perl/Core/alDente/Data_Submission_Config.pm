################################################################################
#
# Data_Submission_Config.pm
#
# This module creates data submission configs
################################################################################

package alDente::Data_Submission_Config;

##############################
# superclasses               #
##############################
@ISA = qw(Exporter);

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use YAML;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::RGmath;

##############################
# constructor                #
##############################
sub new {
    my $this                     = shift;
    my %args                     = &filter_input( \@_, -args => 'name, path, source_xml_template_path' );
    my $class                    = ref($this) || $this;
    my $target                   = $args{-target};
    my $name                     = $args{-name};
    my $path                     = $args{-path};
    my $config_path              = $path . "/$name/";
    my $source_xml_template_path = $args{-source_xml_template_path};
    if ( !-d $config_path ) {
        my ( $stdout, $stderr ) = try_system_command("mkdir $config_path");
        if ($stderr) {
            Message("ERROR: The following error occurred when trying to run \'mkdir $config_path\'\n$stderr");
            Message("No Data_Submission_Config object cteared!");
            return;
        }
    }
    my $self = {};
    $self->{target}                   = $target;
    $self->{name}                     = $name;
    $self->{config_path}              = $config_path;
    $self->{source_xml_template_path} = $source_xml_template_path;
    bless( $self, $class );
    return $self;
}

sub create_config {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'type' );
    my $type = lc( $args{-type} );
    my $name = $self->{name};

    if ( $type eq 'sample' || $type eq 'all' ) {
        $self->create_sample_config();

        #if( $self->{name} =~ /EDACC/i ){
        $self->create_sample_cell_line_config();
        $self->create_sample_primary_cell_config();
        $self->create_sample_primary_cell_culture_config();
        $self->create_sample_primary_tissue_config();

        #}
    }
    if ( $type eq 'experiment' || $type eq 'all' ) {
        $self->create_experiment_config();
        $self->create_experiment_lib_layout_single_config();
        $self->create_experiment_lib_layout_paired_config();
        $self->create_experiment_spot_decode_spec_single_config();
        $self->create_experiment_spot_decode_spec_paired_config();
        $self->create_experiment_platform_illumina_config();
        $self->create_experiment_platform_solid_config();
        $self->create_experiment_platform_ls454_config();
    }
    if ( $type eq 'study' || $type eq 'all' ) {
        $self->create_study_config();
    }
    if ( $type eq 'run' || $type eq 'all' ) {
        if ( $name =~ /fastq/ ) {
            $self->create_fastq_run_config();
        }
        else {
            $self->create_run_config();
        }

        $self->create_run_spot_decode_spec_single_config();
        $self->create_run_spot_decode_spec_paired_config();
        $self->create_run_platform_illumina_config();
        $self->create_run_platform_solid_config();
        $self->create_run_platform_ls454_config();
    }

    #    if( $type eq 'submission' || $type eq 'all' && $name =~ /NCBI/i ) {
    if ( $type eq 'submission' || $type eq 'all' ) {
        $self->create_submission_config();
        $self->create_submission_run_config();

        #$self->create_submission_add_run_config();
        #$self->create_submission_action_add_config() ;
    }
    if ( $type eq 'analysis' || $type eq 'all' ) {
        $self->create_analysis_config();
        $self->create_analysis_analysis_type_abdMeasurement_config();
        $self->create_analysis_analysis_type_assembly_config();
        $self->create_analysis_analysis_type_refAlignment_config();
        $self->create_analysis_analysis_type_report_config();
        $self->create_analysis_analysis_type_seqAnnotation_config();
    }
}

sub create_sample_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $schema   = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.sample.xsd";
    my $template = $config_path . 'sample_template.xml';
    my $source_template;
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @template_header;
    my @user_input;
    my @function_input;
    my @use_NA_if_null;

    # common fields for all templates
    push @fields,
        (
        'study', 'study_description', 'taxonomy_id', 'original_source_description', 'patient_identifier AS ANONYMIZED_NAME',
        'Study_Attr2', 'Common_Name', 'library', "CASE WHEN (Biological_Condition ='Normal') THEN ('None') ELSE Biological_Condition END AS DISEASE",
        'Biomaterial_Provider', 'Biomaterial_Type', "GROUP_CONCAT(distinct plate_id) AS plate_ids",
        );

    ## required fields ##
    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }
    else {
        push @required_fields, ( 'study', );
    }

    ## source template ##
    if ( $name =~ /WTSS/ || $name =~ /NCBI_RNAseq/ || $name =~ /NCBI_WGS/ || $name =~ /NCBI_miRNA_Seq/ ) {    ## sample attributes not necessary
        $source_template = "$source_xml_template_path/sample_template_no_attribute.xml";
    }
    else {
        $source_template = "$source_xml_template_path/sample_template_with_attribute.xml";
    }

    ## TAGs ##
    if ( $name !~ /WTSS/ && $name !~ /NCBI_RNAseq/ && $name !~ /NCBI_WGS/ && $name !~ /NCBI_miRNA_Seq/ ) {
        $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG'} = [];

        push @{ $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG'} }, ( 'MOLECULE', 'DISEASE', 'BIOMATERIAL_PROVIDER', 'BIOMATERIAL_TYPE', );

        $custom_configs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} = {
            'Cell Line'            => $config_path . 'sample_cell_line_config.yml',
            'Primary Cell'         => $config_path . 'sample_primary_cell_config.yml',
            'Primary Cell Culture' => $config_path . 'sample_primary_cell_culture_config.yml',
            'Primary Tissue'       => $config_path . 'sample_primary_tissue_config.yml'
        };
    }

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SAMPLE_SET.xmlns:xsi'}                          = '';
    $Alias{'SAMPLE_SET.xsi:noNamespaceSchemaLocation'}      = '';
    $Alias{'SAMPLE_SET.SAMPLE.alias'}                       = 'study';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_NAME.TAXON_ID'}        = 'taxonomy_id';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_NAME.ANONYMIZED_NAME'} = 'ANONYMIZED_NAME';

    #$Alias{'SAMPLE_SET.SAMPLE.DESCRIPTION'} = 'original_source_description';
    $Alias{'SAMPLE_SET.SAMPLE.DESCRIPTION'}                                                 = "study_description";
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DISEASE'}              = 'DISEASE';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_PROVIDER'} = 'Biomaterial_Provider';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'}     = "Biomaterial_Type";

    if ( $name =~ /EDACC/ ) {
        $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_NAME.COMMON_NAME'}                         = 'Study_Attr2';
        $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MOLECULE'} = "";              # static
    }
    else {
        $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_NAME.COMMON_NAME'}                         = 'Common_Name';    # Taxonomy.Common_Name
        $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MOLECULE'} = "";               # not defined
    }

    ## static ##
    $static_data{'SAMPLE_SET.xmlns:xsi'}                     = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'SAMPLE_SET.xsi:noNamespaceSchemaLocation'} = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.sample.xsd';
    if ( $name =~ /EDACC/ ) {
        $static_data{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MOLECULE'} = "genomic DNA";
    }

    push @template_header, 'SAMPLE_SET';

    $hash{schema}          = $schema;
    $hash{template}        = $template;
    $hash{field}           = \@fields;
    $hash{required_field}  = \@required_fields;
    $hash{TAG}             = \%TAGs;
    $hash{Alia}            = \%Alias;
    $hash{custom_config}   = \%custom_configs;
    $hash{static_data}     = \%static_data;
    $hash{template_header} = \@template_header;
    $hash{user_input}      = \@user_input;
    $hash{function_input}  = \@function_input;
    $hash{use_NA_if_null}  = \@use_NA_if_null;

    YAML::DumpFile( $config_path . 'sample_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_sample_cell_line_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template = '';
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @use_NA_if_null;
    my @user_input;

    ## fields ##
    push @fields, ( 'host', 'Biomaterial_Type', 'sex', 'Lineage', 'Cellular_Condition', 'Differentiation_Method', 'Passage', 'Medium', );
    if ( $name =~ /EDACC/i ) {
        push @fields, ( 'Batch_Number', );
    }

    ## required fields ##
    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

    #push @use_NA_if_null, @fields;

    ## TAGs ##
    $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} = [];
    push @{ $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} }, ( 'BIOMATERIAL_TYPE', 'LINE', 'LINEAGE', 'DIFFERENTIATION_STAGE', 'DIFFERENTIATION_METHOD', 'PASSAGE', 'MEDIUM', 'SEX' );
    if ( $name =~ /EDACC/ ) {
        push @{ $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} }, 'BATCH';
    }

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'}       = "Biomaterial_Type";
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.LINE'}                   = 'host';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.LINEAGE'}                = 'Lineage';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DIFFERENTIATION_STAGE'}  = 'Cellular_Condition';       # attribute
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DIFFERENTIATION_METHOD'} = 'Differentiation_Method';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.PASSAGE'}                = 'Passage';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MEDIUM'}                 = 'Medium';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.SEX'}                    = 'sex';
    if ( $name =~ /EDACC/i ) {

        #	$Alias{'SAMPLE_SET.SAMPLE.SAMPLE_NAME.COMMON_NAME'} = 'Sample_Common_Name_Cell_Line'; # overwrite this element, current value for cell line is the combination of LINE and BIOMATERIAL_TYPE
        #	$Alias{'SAMPLE_SET.SAMPLE.DESCRIPTION'} = 'Sample_Description_Cell_Line'; # overwrite this element
        $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BATCH'} = 'Batch_Number';
    }

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{user_input}     = \@user_input;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{use_NA_if_null} = \@use_NA_if_null;

    YAML::DumpFile( $config_path . 'sample_cell_line_config.yml', \%hash );
}

sub create_sample_primary_cell_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template = '';
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @use_NA_if_null;

    ## fields ##
    push @fields, (
        "CASE WHEN patient_sex = 'M' THEN 'Male' WHEN patient_sex = 'F' THEN 'Female' ELSE '' END AS Donor_Sex",
        'Biomaterial_Type',

        #'subtissue',
        'anatomic_site_name',
        "CASE WHEN length( Markers ) > 0 THEN Markers ELSE '' END AS Sample_Markers",
        'Patient_Identifier AS DONOR_ID',
        "CASE WHEN length(Patient_Age_at_Donation) > 0 THEN CONCAT(Patient_Age_at_Donation,' years') END AS Donor_Age",
        'Patient_Health_Status AS Donor_Health_Status',
        'Patient_Ethnicity AS Donor_Ethnicity',
        "CASE WHEN length(Passage) > 0 THEN Passage ELSE '' END AS Sample_Passage",
        'Karyotype',
        "CASE WHEN length(Parity) > 0 THEN Parity ELSE '' END AS Sample_Parity",
        "CASE WHEN length(Blood_Type) > 0 THEN Blood_Type ELSE '' END AS Sample_Blood_Type",
    );

    push @use_NA_if_null, ( 'Sample_Markers', 'Sample_Passage', 'Sample_Parity' );

    ## required fields ##
    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

    ## TAGs ##
    $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'}
        = [ 'BIOMATERIAL_TYPE', 'CELL_TYPE', 'MARKERS', 'DONOR_ID', 'DONOR_AGE', 'DONOR_HEALTH_STATUS', 'DONOR_SEX', 'DONOR_ETHNICITY', 'PASSAGE_IF_EXPANDED', 'KARYOTYPE', 'PARITY', 'BLOOD_TYPE', ];

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} = "Biomaterial_Type";

    #$Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.CELL_TYPE'} = 'Original_Source_Cell_Type';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.CELL_TYPE'}           = 'anatomic_site_name';    # subtissue
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MARKERS'}             = 'Sample_Markers';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ID'}            = 'DONOR_ID';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_AGE'}           = 'Donor_Age';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_HEALTH_STATUS'} = 'Donor_Health_Status';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_SEX'}           = 'Donor_Sex';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ETHNICITY'}     = 'Donor_Ethnicity';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.PASSAGE_IF_EXPANDED'} = 'Sample_Passage';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.KARYOTYPE'}           = 'Karyotype';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.PARITY'}              = 'Sample_Parity';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BLOOD_TYPE'}          = 'Sample_Blood_Type';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{use_NA_if_null} = \@use_NA_if_null;

    YAML::DumpFile( $config_path . 'sample_primary_cell_config.yml', \%hash );
}

sub create_sample_primary_cell_culture_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template = '';
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @use_NA_if_null;

    ## fields ##
    push @fields,
        (
        "CASE WHEN patient_sex = 'M' THEN 'Male' WHEN patient_sex = 'F' THEN 'Female' ELSE 'Unknown' END AS Donor_Sex",
        'Biomaterial_Type', 'anatomic_site_name', 'Markers',
        'Patient_Identifier AS DONOR_ID',
        "CASE WHEN length(Patient_Age_at_Donation) > 0 THEN CONCAT(Patient_Age_at_Donation,' years') END AS Donor_Age",
        'Patient_Health_Status AS Donor_Health_Status',
        'Patient_Ethnicity AS Donor_Ethnicity',
        'Passage', 'Culture_Conditions', 'Karyotype', 'Parity',
        );

    #push @use_NA_if_null, @fields;

    ## required fields ##
    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

    ## TAGs ##
    $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'}
        = [ 'BIOMATERIAL_TYPE', 'CELL_TYPE', 'MARKERS', 'CULTURE_CONDITIONS', 'DONOR_ID', 'DONOR_AGE', 'DONOR_HEALTH_STATUS', 'DONOR_SEX', 'DONOR_ETHNICITY', 'PASSAGE_IF_EXPANDED', 'KARYOTYPE', 'PARITY', ];

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'}    = "Biomaterial_Type";
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.CELL_TYPE'}           = 'anatomic_site_name';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MARKERS'}             = 'Markers';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.CULTURE_CONDITIONS'}  = 'Culture_Conditions';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ID'}            = 'DONOT_ID';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_AGE'}           = 'Donor_Age';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_HEALTH_STATUS'} = 'Donor_Health_Status';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_SEX'}           = 'Donor_Sex';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ETHNICITY'}     = 'Donor_Ethnicity';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.PASSAGE_IF_EXPANDED'} = 'Passage';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.KARYOTYPE'}           = 'Karyotype';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.PARITY'}              = 'Parity';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{use_NA_if_null} = \@use_NA_if_null;

    YAML::DumpFile( $config_path . 'sample_primary_cell_culture_config.yml', \%hash );
}

sub create_sample_primary_tissue_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template = '';
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @use_NA_if_null;

    ## fields ##
    push @fields, (
        "CASE WHEN patient_sex = 'M' THEN 'Male' WHEN patient_sex = 'F' THEN 'Female' ELSE 'Unknown' END AS Donor_Sex",
        'Biomaterial_Type',

        #"CASE WHEN LENGTH(anatomic_site_name) > 0 THEN CONCAT( tissue, ' - ', anatomic_site_name ) ELSE tissue END AS SAMPLE_TISSUE_TYPE",
        "anatomic_site AS SAMPLE_TISSUE_TYPE",
        'Tissue_Depot', 'Collection_Method',
        'Patient_Identifier AS DONOR_ID',
        "CASE WHEN length(Patient_Age_at_Donation) > 0 THEN CONCAT(Patient_Age_at_Donation,' years') END AS Donor_Age",
        'Patient_Health_Status AS Donor_Health_Status',
        'Patient_Ethnicity AS Donor_Ethnicity',
    );

    #push @use_NA_if_null, @fields;

    ## required fields ##
    if ( $name =~ /EDACC/i ) {
        push @required_fields, ( 'patient_sex', 'Biomaterial_Type', 'SAMPLE_TISSUE_TYPE', 'Tissue_Depot', 'Collection_Method', 'original_source_name', 'Donor_Age', 'Donor_Health_Status', 'Donor_Ethnicity', );
    }

    ## TAGs ##
    $TAGs{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} = [ 'BIOMATERIAL_TYPE', 'TISSUE_TYPE', 'TISSUE_DEPOT', 'COLLECTION_METHOD', 'DONOR_ID', 'DONOR_AGE', 'DONOR_HEALTH_STATUS', 'DONOR_SEX', 'DONOR_ETHNICITY', ];

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE'} = "Biomaterial_Type";

    #$Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.TISSUE_TYPE'} = 'Tissue_Type';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.TISSUE_TYPE'}         = "SAMPLE_TISSUE_TYPE";
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.TISSUE_DEPOT'}        = 'Tissue_Depot';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.COLLECTION_METHOD'}   = 'Collection_Method';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ID'}            = 'DONOR_ID';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_AGE'}           = 'Donor_Age';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_HEALTH_STATUS'} = 'Donor_Health_Status';

    #$Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_SEX'} = 'sex';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_SEX'}       = 'Donor_Sex';
    $Alias{'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.DONOR_ETHNICITY'} = 'Donor_Ethnicity';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{use_NA_if_null} = \@use_NA_if_null;

    YAML::DumpFile( $config_path . 'sample_primary_tissue_config.yml', \%hash );
}

sub create_experiment_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %TAGs;

    my $config_href = $self->set_common_experiment_config( -config_path => $config_path );

    #print "common configs:\n";
    #print Dumper $config_href;

    ######## EDACC common config ##############
    if ( $self->{target} =~ /EDACC/i ) {
        my $edacc = $self->set_common_edacc_config();

        #print "common edacc configs:\n";
        #print Dumper $edacc;
        $config_href = $self->merge_config( -general => $config_href, -custom => $edacc );
    }

    ########## branch out for different experiment types
    if ( $name =~ /MeDIP_Seq/i ) {
        my $custom = $self->set_MeDIP_seq_config();

        #print "common medip configs:\n";
        #print Dumper $custom;
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );

        #print "configs after merge:\n";
        #print Dumper $config_href;
    }
    elsif ( $name =~ /MRE_Seq/i ) {
        my $custom = $self->set_MRE_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /ChIP_Seq_input/i ) {
        my $custom = $self->set_ChIP_seq_input_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /ChIP_Seq/i ) {
        my $custom = $self->set_ChIP_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /smRNA_Seq/i ) {
        my $custom = $self->set_smRNA_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /mRNA_Seq/i ) {
        my $custom = $self->set_mRNA_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /Bisulfite/i ) {
        my $custom = $self->set_Bisulfite_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /RNAseq/i ) {
        my $custom = $self->set_RNA_seq_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /WTSS/ ) {
        my $custom = $self->set_WTSS_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    ################## special templates ###################
    if ( $name eq 'NCBI_RNAseq_TCGA' ) {
        my $custom = $self->set_NCBI_RNAseq_TCGA_exp_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name eq 'NCBI_RNAseq_NBL' ) {
        my $custom = $self->set_NCBI_RNAseq_NBL_exp_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }

    my $source_template = "$source_xml_template_path/" . $config_href->{source_template};
    my $template        = $config_href->{template};

    my %hash;
    $hash{schema}                                                                     = $config_href->{schema};
    $hash{template}                                                                   = $template;
    $hash{custom_config}                                                              = $config_href->{custom_config};
    $hash{template_header}                                                            = $config_href->{template_header};
    $hash{field}                                                                      = $config_href->{fields};
    $hash{required_field}                                                             = $config_href->{required_fields};
    $hash{user_input}                                                                 = $config_href->{user_input};
    $hash{use_NA_if_null}                                                             = $config_href->{use_NA_if_null};
    $hash{function_input}                                                             = $config_href->{function_input};
    $TAGs{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG'} = $config_href->{tags};
    $hash{TAG}                                                                        = \%TAGs;
    $hash{Alia}                                                                       = $config_href->{aliases};
    $hash{static_data}                                                                = $config_href->{static_data};

    YAML::DumpFile( $config_path . 'experiment_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

=begin
sub create_experiment_config {
	my $self = shift;
	my $name = $self->{name};
	my $config_path = $self->{config_path};
	my $source_xml_template_path = $self->{source_xml_template_path};

my %hash;

my 		$schema = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.experiment.xsd";
my    	$template = $config_path . 'experiment_template.xml';
my 		$source_template;
my    	@fields;
my		@required_fields;
my		%TAGs;
my		%Alias;
my		%custom_configs;
my   	%static_data;
my		@template_header;
my 		@user_input;
my		@use_NA_if_null;
my		@function_input;





## fields
elsif( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' ) {
	$source_template = "$source_xml_template_path/experiment_template_no_attribute_TCGA.xml";
	push @fields, (
	);
}
elsif( $name eq 'NCBI_RNAseq_TCGA' ) {
	$source_template = "$source_xml_template_path/experiment_template_with_attribute_TCGA.xml";
	push @fields, (
	);
}
elsif( $name eq 'NCBI_RNAseq' || $name eq 'NCBI_miRNA_Seq' ) {
	$source_template = "$source_xml_template_path/experiment_template_with_attribute.xml";
	push @fields, (
	);
}
elsif( $name =~ 'NCBI_WGS' ) {
	$source_template = "$source_xml_template_path/experiment_template_no_attribute.xml";
	push @fields, (
	);
}
elsif( $name =~ /WTSS/ ) { ## experiment attributes not necessary 
	$source_template = "$source_xml_template_path/experiment_template_no_attribute.xml";
	push @fields, (
	"Library_Strategy",
	'Data_Submission_Library_Source',
	'Library_Selection',
	);
}


## tags
elsif( $name =~ /NCBI_RNAseq/ || $name eq 'NCBI_miRNA_Seq' ) {
	push @{$TAGs{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG'}}, (
		"LIBRARY_STRATEGY",
	);
}


## aliases
elsif( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' || $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.TITLE'} = ''; # static
}
else {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.TITLE'} = "EXPERIMENT_TITLE"; # function input ## common experiment config
}

if( $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'} = ''; # static  
}
else {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.refname'} = 'STUDY_refname';  ##common experiment config
} 
        


elsif( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' || $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = ''; # static, same as LIBRARY_STRATEGY
}
else {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'library_description'; ##common experiment config
}


#$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'} = "sample_name";
if( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' || $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'} = "study_description";
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = ""; # static
}
else {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'} = "study_description"; ##common experiment config
}


if( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' || $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_NAME'} = "library";
}
else {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_NAME'} = "library"; ##common experiment config
}


if( $name eq 'EDACC_ChIP_Seq_input' || $name eq 'EDACC_ChIP_Seq' || $name eq 'EDACC_MRE_Seq' || $name eq 'EDACC_smRNA_Seq' ||  $name eq 'EDACC_mRNA_Seq'|| $name eq 'EDACC_MeDIP_Seq') {
}
elsif( $name eq 'EDACC_Bisulfite_Seq' ) {
}
elsif( $name eq 'NCBI_RNAseq'  || $name eq 'NCBI_WGS' || $name eq 'NCBI_miRNA_Seq' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = ''; # static
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'} = ''; # static
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = ''; # static
	$Alias{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = ''; # static
}
elsif( $name eq 'SRA_MeDIP_Seq_EDACC_format' ) {
}
else { ##common experiment config
}


if( $name eq 'NCBI_RNAseq_EZH2' || $name eq 'NCBI_WGS_EZH2' || $name eq 'NCBI_RNAseq_TCGA' ) {
	$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = ''; # static
}
else {
	##common experiment config
}

        



          
elsif( $name =~ /NCBI_RNAseq/ ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'RNA-Seq'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'} = 'TRANSCRIPTOMIC'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'cDNA'; # static for each template
		if( $name eq 'NCBI_RNAseq_EZH2' ) {
			$static_data{'EXPERIMENT_SET.EXPERIMENT.TITLE'} = 'RNAseq (polyA+) of DLBCL tumor sample'; # static
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'RNAseq polyA+'; 
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = "PolyA+ RNA was purified using the MACS mRNA isolation kit (Miltenyi Biotec, Bergisch Gladbach, Germany), from 5-10ug of DNaseI-treated total RNA as per the manufacturer's instructions. Double-stranded cDNA was synthesized from the purified polyA+RNA using the Superscript Double-Stranded cDNA Synthesis kit (Invitrogen, Carlsbad, CA, USA) and random hexamer primers (Invitrogen) at a concentration of 5µM. The cDNA was fragmented by sonication and a paired-end sequencing library prepared following the Illumina paired-end library preparation protocol (Illumina, Hayward, CA, USA)."; # static
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = "NCBI";
		}
		elsif( $name eq 'NCBI_RNAseq_TCGA' ){
			$static_data{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'} = 'SRP000677'; # static  
			$static_data{'EXPERIMENT_SET.EXPERIMENT.TITLE'} = ''; # static ??
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'RNAseq'; # ??
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = ""; # static ??
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = "NCBI";
		}
}
elsif( $name eq 'NCBI_miRNA_Seq' ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'OTHER'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'} = 'TRANSCRIPTOMIC'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'cDNA'; # static for each template
		$static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = 'miRNA-Seq'; # static
}
elsif( $name =~ /NCBI_WGS/ ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'WGS'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'} = 'GENOMIC'; # static for each template
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'RANDOM'; # static for each template
		if( $name eq 'NCBI_WGS_EZH2' ) {
			$static_data{'EXPERIMENT_SET.EXPERIMENT.TITLE'} = 'WGS of DLBCL tumor sample'; # static
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'WGS of DLBCL tumor sample'; 
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = "Genomic DNA for construction of whole genome shotgun sequencing (WGSS) libraries was prepared from the same biopsy material using the Qiagen AllPrep DNA/RNA Mini Kit (Qiagen, Valencia, CA, USA). DNA quality was assessed by spectrophotometry (260/280 and 260/230) and gel electrophoresis before library construction. Depending on the availability of DNA, between 2 and 10µg was used in WGSS library construction. Briefly, DNA was sheared for 10 min using a Sonic Dismembrator 550 with a power setting of \"7\" in pulses of 30 seconds interspersed with 30 seconds of cooling (Cup Horn, Fisher Scientific, Ottawa, Ontario, Canada), and analyzed on 8% PAGE gels. The 200-300bp DNA fraction was excised and eluted from the gel slice overnight at 4°C in 300 µl of elution buffer (5:1, LoTE buffer (3 mM Tris-HCl, pH 7.5, 0.2 mM EDTA)-7.5 M ammonium acetate), and was purified using a Spin-X Filter Tube (Fisher Scientific), and by ethanol precipitation. WGSS libraries were prepared using a modified paired-end protocol supplied by Illumina Inc. (Illumina, Hayward, USA). This involved DNA end-repair and formation of 3' A overhangs using Klenow fragment (3' to 5' exo minus) and ligation to Illumina PE adapters (with 5' overhangs). Adapter-ligated products were purified on Qiaquick spin columns (Qiagen, Valencia, CA, USA) and PCR-amplified using Phusion DNA polymerase (NEB, Ipswich, MA, USA) and 10 cycles with the PE primer 1.0 and 2.0 (Illumina). PCR products of the desired size range were purified from adapter ligation artifacts using 8% PAGE gels. DNA quality was assessed and quantified using an Agilent DNA 1000 series II assay (Agilent, Santa Clara CA, USA) and Nanodrop 7500 spectrophotometer (Nanodrop, Wilmington, DE, USA) and DNA was subsequently diluted to 10nM. The final concentration was confirmed using a Quant-iT dsDNA HS assay kit and Qubit fluorometer (Invitrogen, Carlsbad, CA, USA)."; # static
			$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = "NCBI";
		}
}


$hash{schema} = $schema;
$hash{template} = $template;
$hash{custom_config} = \%custom_configs;
$hash{template_header} = \@template_header;

$hash{field} = \@fields;
$hash{required_field} = \@required_fields;
$hash{user_input} = \@user_input;
$hash{use_NA_if_null} = \@use_NA_if_null;
$hash{function_input} = \@function_input;
$hash{TAG} = \%TAGs;
$hash{Alia} = \%Alias;
$hash{static_data} = \%static_data;

YAML::DumpFile( $config_path . 'experiment_config.yml', \%hash );
try_system_command(-command=>"cp $source_template $template");
}
=cut

sub create_experiment_lib_layout_single_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_lib_layout_single_template.xml';
    my $source_template = "$source_xml_template_path/experiment_lib_layout_single_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_lib_layout_single_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_lib_layout_paired_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template = $config_path . 'experiment_lib_layout_paired_template.xml';
    my $source_template;
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    if ( $name eq 'NCBI_RNAseq_EZH2' ) {
        $source_template = "$source_xml_template_path/experiment_lib_layout_paired_template_with_attribute.xml";
        push @fields, ( "Avg_DNA_bp_size-119 AS NOMINAL_LENGTH", );
    }
    elsif ( $name eq 'NCBI_WGS_EZH2' ) {
        $source_template = "$source_xml_template_path/experiment_lib_layout_paired_template_with_attribute.xml";
        push @fields, ( "164 AS NOMINAL_LENGTH", );
    }

    if ( $name eq 'NCBI_RNAseq_TCGA' || $name eq 'NCBI_RNAseq_NBL' ) {
        $source_template = "$source_xml_template_path/experiment_lib_layout_paired_template_with_attribute.xml";
        push @fields, ( "Avg_DNA_bp_size-119 AS NOMINAL_LENGTH", );
    }
    else {
        $source_template = "$source_xml_template_path/experiment_lib_layout_paired_template_no_attribute.xml";

        #$source_template = "$source_xml_template_path/experiment_lib_layout_paired_template_with_attribute.xml";
        #push @fields, (
        #	"Avg_DNA_bp_size-119 AS NOMINAL_LENGTH",
        #	## the line below caused error. Both Library_Strategy and Avg_DNA_bp_size are attributes. Don't know why yet.
        #	#"CASE WHEN Library_Strategy = 'RNA_Seq' THEN Avg_DNA_bp_size-119 ELSE '' END AS NOMINAL_LENGTH",
        #);
    }

## alias from XML Tag names -> LIMS alias names
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.ORIENTATION'}    = '';                 # genomic PE libraries (forward-reverse), mate-pair libraries (forward-forward)
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.NOMINAL_LENGTH'} = "NOMINAL_LENGTH";
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.NOMINAL_SDEV'}   = '';

    if ( $name eq 'NCBI_RNAseq_EZH2' ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.ORIENTATION'}  = 'forward-reverse';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.NOMINAL_SDEV'} = '50';
    }
    elsif ( $name eq 'NCBI_WGS_EZH2' ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.ORIENTATION'}  = 'forward-reverse';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.NOMINAL_SDEV'} = '12';
    }
    elsif ( $name eq 'NCBI_RNAseq_TCGA' ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.ORIENTATION'}  = 'forward-reverse';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.NOMINAL_SDEV'} = '';                  # not applicable
    }
    else {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT.PAIRED.ORIENTATION'} = 'forward-reverse';
    }

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_lib_layout_paired_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_platform_illumina_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_platform_illumina_template.xml';
    my $source_template = "$source_xml_template_path/experiment_platform_illumina_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    #push @fields, ( 'current_model', 'Cycle_Sequence', 'cycles' );
    push @fields, ( 'current_model', "CASE WHEN SolexaRun.SolexaRun_Type = 'Single' THEN cycles WHEN SolexaRun.SolexaRun_Type = 'Paired' THEN 2*cycles END as sequence_length" );

    if ( $name =~ /EDACC/i ) {
        @required_fields = ( 'current_model', 'sequence_length' );
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ILLUMINA.INSTRUMENT_MODEL'} = 'current_model';     # attribute
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ILLUMINA.SEQUENCE_LENGTH'}  = 'sequence_length';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_platform_illumina_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_platform_illumina_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'run_platform_illumina_template.xml';
    my $source_template = "$source_xml_template_path/run_platform_illumina_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    #push @fields, ( 'current_model', 'Cycle_Sequence', 'cycles' );
    push @fields, ( 'current_model', "CASE WHEN SolexaRun.SolexaRun_Type = 'Single' THEN cycles WHEN SolexaRun.SolexaRun_Type = 'Paired' THEN 2*cycles END as sequence_length" );

    if ( $name =~ /EDACC/i ) {
        @required_fields = ( 'current_model', 'sequence_length' );
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'RUN_SET.RUN.PLATFORM.ILLUMINA.INSTRUMENT_MODEL'} = 'current_model';     # attribute
                                                                                    #$Alias{'RUN_SET.RUN.PLATFORM.ILLUMINA.CYCLE_SEQUENCE'}   = 'Cycle_Sequence';    # attribute
                                                                                    #$Alias{'RUN_SET.RUN.PLATFORM.ILLUMINA.CYCLE_COUNT'}      = 'cycles';
    $Alias{'RUN_SET.RUN.PLATFORM.ILLUMINA.SEQUENCE_LENGTH'}  = 'sequence_length';

    #$static_data{'RUN_SET.RUN.PLATFORM.ILLUMINA.INSTRUMENT_MODEL'} = ['Illumina Genome Analyzer II'];
    #$static_data{'RUN_SET.RUN.PLATFORM.ILLUMINA.CYCLE_SEQUENCE'} =  ['ACGT'];
    #$static_data{'RUN_SET.RUN.PLATFORM.ILLUMINA.CYCLE_COUNT'} =  ['50'];

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'run_platform_illumina_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_platform_ls454_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_platform_LS454_template.xml';
    my $source_template = "$source_xml_template_path/experiment_platform_LS454_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ( 'current_model', 'Cycle_Sequence', 'cycles', );

    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.LS454.INSTRUMENT_MODEL'} = 'current_model';     # attribute
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.LS454.FLOW_SEQUENCE'}    = 'Cycle_Sequence';    # attribute
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.LS454.FLOW_COUNT'}       = 'cycles';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_platform_LS454_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_platform_ls454_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'run_platform_LS454_template.xml';
    my $source_template = "$source_xml_template_path/run_platform_LS454_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ( 'current_model', 'Cycle_Sequence', 'cycles', );

    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'RUN_SET.RUN.PLATFORM.LS454.INSTRUMENT_MODEL'} = 'current_model';     # attribute
    $Alias{'RUN_SET.RUN.PLATFORM.LS454.FLOW_SEQUENCE'}    = 'Cycle_Sequence';    # attribute
    $Alias{'RUN_SET.RUN.PLATFORM.LS454.FLOW_COUNT'}       = 'cycles';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'run_platform_LS454_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_platform_solid_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_platform_solid_template.xml';
    my $source_template = "$source_xml_template_path/experiment_platform_solid_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ();

    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ABI_SOLID.INSTRUMENT_MODEL'}   = 'current_model';    # attribute
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ABI_SOLID.COLOR_MATRIX.COLOR'} = '';
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ABI_SOLID.COLOR_MATRIX_CODE'}  = '';
    $Alias{'EXPERIMENT_SET.EXPERIMENT.PLATFORM.ABI_SOLID.CYCLE_COUNT'}        = '';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_platform_solid_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_platform_solid_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'run_platform_solid_template.xml';
    my $source_template = "$source_xml_template_path/run_platform_solid_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ();

    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }

## alias from XML Tag names -> LIMS alias names

    $Alias{'RUN_SET.RUN.PLATFORM.ABI_SOLID.INSTRUMENT_MODEL'}   = 'current_model';    # attribute
    $Alias{'RUN_SET.RUN.PLATFORM.ABI_SOLID.COLOR_MATRIX.COLOR'} = '';
    $Alias{'RUN_SET.RUN.PLATFORM.ABI_SOLID.COLOR_MATRIX_CODE'}  = '';
    $Alias{'RUN_SET.RUN.PLATFORM.ABI_SOLID.CYCLE_COUNT'}        = '';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'run_platform_solid_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_spot_decode_spec_single_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_spot_decode_spec_single_template.xml';
    my $source_template = "$source_xml_template_path/experiment_spot_decode_spec_single_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

## alias from XML Tag names -> LIMS alias names
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.NUMBER_OF_READS_PER_SPOT'}   = '';                    # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'}       = '';                    # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}        = '';                    # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'}       = '';                    # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'}       = '';                    # static data in template
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '0';                   # static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}  = 'Forward';             # static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = 'Application Read';    # static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'} = '1';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_spot_decode_spec_single_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_spot_decode_spec_single_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'run_spot_decode_spec_single_template.xml';
    my $source_template = "$source_xml_template_path/run_spot_decode_spec_single_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

## alias from XML Tag names -> LIMS alias names
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.NUMBER_OF_READS_PER_SPOT'} = '';    # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'}     = '';    # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}      = '';    # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'}     = '';    # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'}     = '';    # static data in template

    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.NUMBER_OF_READS_PER_SPOT'} = '';    # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'}     = '';    # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}      = '';    # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'}     = '';    # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'}     = '';    # static data in template
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '0'; # static data
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'} = 'Forward'; # static data
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = 'Application Read'; # static data
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'} = '1';

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'run_spot_decode_spec_single_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_experiment_spot_decode_spec_paired_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'experiment_spot_decode_spec_paired_template.xml';
    my $source_template = "$source_xml_template_path/experiment_spot_decode_spec_paired_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ( 'submission_experiment_paired_2nd_base_coord', );

## alias from XML Tag names -> LIMS alias names
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'}       = '';                                              # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}        = '';                                              # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'}       = '';                                              # static data in template
    $Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'}       = 'submission_experiment_paired_2nd_base_coord';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '1';                                             # static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}  = 'Reverse';                                       # static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = 'Application Read';                              # static data

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'experiment_spot_decode_spec_paired_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_spot_decode_spec_paired_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'run_spot_decode_spec_paired_template.xml';
    my $source_template = "$source_xml_template_path/run_spot_decode_spec_paired_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ( 'submission_experiment_paired_2nd_base_coord', );

## alias from XML Tag names -> LIMS alias names
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '';                                              # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}  = '';                                              # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = '';                                              # static data in template
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'} = 'submission_experiment_paired_2nd_base_coord';

    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '';                                              # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'}  = '';                                              # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = '';                                              # static data in template
    #$Alias{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.BASE_COORD'} = 'submission_experiment_paired_2nd_base_coord';
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_INDEX'} = '1'; # static data
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_TYPE'} = 'Reverse'; # static data
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC.READ_SPEC.READ_CLASS'} = 'Application Read'; # static data

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'run_spot_decode_spec_paired_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_study_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.study.xsd";
    my $template        = $config_path . 'study_template.xml';
    my $source_template = "$source_xml_template_path/study_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    push @fields, ( 'study', 'Study_Title', 'Study_Type', 'Study_Abstract', 'Study_Center', "Group_CONCAT( distinct project ) AS CENTER_PROJECT_NAME", 'External_Project_ID', 'study_description', 'Study_Contributors', );

=begin
if( $name =~ /EDACC/i ) {
	@required_fields = @fields;
}
else {
	push @required_fields, (
	'study',
	'Study_Title',
	'Study_Type',
	'Study_Center',
	'project',
	'External_Project_ID',
	);
}
=cut

    $TAGs{'STUDY.STUDY_ATTRIBUTES.STUDY_ATTRIBUTE.TAG'} = [ 'CONTRIBUTOR', ];

## alias from XML Tag names -> LIMS alias names
    $Alias{'STUDY.xmlns:xsi'}                     = '';               # static data
    $Alias{'STUDY.xsi:noNamespaceSchemaLocation'} = '';               # static data
    $Alias{'STUDY.alias'}                         = 'study';
    $Alias{'STUDY.center_name'}                   = 'Study_Center';

    $Alias{'STUDY.DESCRIPTOR.STUDY_TITLE'}                            = 'Study_Title';           # Study attribute
    $Alias{'STUDY.DESCRIPTOR.STUDY_TYPE.existing_study_type'}         = 'Study_Type';            # Study attribute
    $Alias{'STUDY.DESCRIPTOR.STUDY_ABSTRACT'}                         = 'Study_Abstract';        # Study attribute
                                                                                                 #$Alias{'STUDY.DESCRIPTOR.CENTER_NAME'}                    = 'Study_Center';           # Study attribute
    $Alias{'STUDY.DESCRIPTOR.CENTER_PROJECT_NAME'}                    = 'CENTER_PROJECT_NAME';
    $Alias{'STUDY.DESCRIPTOR.RELATED_STUDIES.STUDY.SRA_LINK.refname'} = 'External_Project_ID';

    #$Alias{'STUDY.DESCRIPTOR.PROJECT_ID'}                     = 'External_Project_ID';    # Study attribute
    $Alias{'STUDY.DESCRIPTOR.STUDY_DESCRIPTION'} = 'study_description';

    $Alias{'STUDY.STUDY_ATTRIBUTES.STUDY_ATTRIBUTE.TAG.CONTRIBUTOR'} = 'Study_Contributors';     # Study attribute

    $static_data{'STUDY.xmlns:xsi'}                     = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'STUDY.xsi:noNamespaceSchemaLocation'} = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.study.xsd';

    #$static_data{'STUDY.DESCRIPTOR.CENTER_NAME'} = 'BCCAGSC';

    $hash{schema}         = $schema;
    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'study_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_run_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.run.xsd";
    my $template        = $config_path . 'run_template.xml';
    my $source_template = "$source_xml_template_path/run_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @template_header;
    my @function_input;

    $custom_configs{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC'} = {
        'Single' => $config_path . 'run_spot_decode_spec_single_config.yml',
        'Paired' => $config_path . 'run_spot_decode_spec_paired_config.yml',
    };

    $custom_configs{'RUN_SET.RUN.PLATFORM'} = {
        'ILLUMINA'  => $config_path . 'run_platform_illumina_config.yml',
        'ABI_SOLID' => $config_path . 'run_platform_solid_config.yml',
        'LS454'     => $config_path . 'run_platform_LS454_config.yml',
    };

    push @function_input, ( "get_program(pipeline_name,'RTA') AS BASE_CALLER", "get_version(pipeline_name,'RTA') AS VERSION", );

    push @fields, (
        "run_name",
        'current_model',
        'machine',
        'run_time_xml_datetime_format',
        'run_id',
        'solexarun_type',
        'pipeline_name',
        'flowcell_code',
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN ('ILLUMINA') WHEN (Equipment_Category.Sub_Category = 'Solid') THEN ('ABI_SOLID') ELSE ('unspecified') END AS submission_run_platform",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SolexaRun.Lane WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'NA' END AS `RUN_SET.RUN.DATA_BLOCK.sector`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SolexaRun.Lane, '.srf' ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SOLIDRun.Lane, '.srf' ) END AS `RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",

#"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SUM( Solexa_Read.Number_Reads ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `RUN_SET.RUN.DATA_BLOCK.total_reads`",

        #"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( 'SOLEXA', substr(Equipment.Equipment_Name,4) ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `RUN_SET.RUN.DATA_BLOCK.name`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN flowcell_code WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `RUN_SET.RUN.DATA_BLOCK.name`",
    );

#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Library.Library_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Library.Library_Name, '_', 'SOLID specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
#	'Data_Block_Name',

## for LS_454
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SolexaRun.Lane WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'NA' WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN 'NA' END AS `RUN_SET.RUN.DATA_BLOCK.sector`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SolexaRun.Lane, '.srf' ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SOLIDRun.Lane, '.srf' ) WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', LS_454Run.Lane, '.srf' ) END AS `RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN CONCAT( Sample.Sample_Name, '_', '454 specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SUM( Solexa_Read.Number_Reads ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN SUM( LS_454Analysis.Number_Reads ) END AS `RUN_SET.RUN.DATA_BLOCK.total_reads`",

    if ( $name =~ /EDACC/i ) {
        push @required_fields,
            (
            "run_name",                      'current_model',                   'machine',                                      'run_time_xml_datetime_format',
            'run_id',                        "`RUN_SET.RUN.DATA_BLOCK.sector`", "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`", "`RUN_SET.RUN.EXPERIMENT_REF.refname`",
            "`RUN_SET.RUN.DATA_BLOCK.name`", 'submission_run_platform',
            );

        #	"`RUN_SET.RUN.DATA_BLOCK.total_reads`",

    }
    else {
        push @required_fields, ( 'run_name', 'current_model', 'machine', 'run_time_xml_datetime_format', 'run_id', "`RUN_SET.RUN.DATA_BLOCK.sector`", "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`", 'submission_run_platform', 'solexarun_type', );

    }

    #push @function_input, (
    #	'get_number_of_reads_and_data_block_name',
    #);

    $TAGs{'RUN_SET.RUN.RUN_ATTRIBUTES.RUN_ATTRIBUTE.TAG'} = ['RUN'];

## alias from XML Tag names -> LIMS alias names
    $Alias{'RUN_SET.xmlns:xsi'}                     = '';    # static data
    $Alias{'RUN_SET.xsi:noNamespaceSchemaLocation'} = '';    # static data

    $Alias{'RUN_SET.RUN.alias'} = "run_name";

    #$Alias{'RUN_SET.RUN.instrument_model'}  = 'current_model';                  # attribute
    $Alias{'RUN_SET.RUN.instrument_name'}   = 'machine';
    $Alias{'RUN_SET.RUN.run_center'}        = '';                               # static data
    $Alias{'RUN_SET.RUN.run_date'}          = 'run_time_xml_datetime_format';
    $Alias{'RUN_SET.RUN.total_data_blocks'} = '';                               # static data

    $Alias{'RUN_SET.RUN.EXPERIMENT_REF.refname'}           = "`RUN_SET.RUN.EXPERIMENT_REF.refname`";    # "submission_experiment_alias";
    $Alias{'RUN_SET.RUN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC'} = 'solexarun_type';
    $Alias{'RUN_SET.RUN.PLATFORM'}                         = "submission_run_platform";                 # use Stock_Catalog.Model temporary

    $Alias{'RUN_SET.RUN.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'} = 'BASE_CALLER';
    $Alias{'RUN_SET.RUN.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'} = 'VERSION';

    #$Alias{'RUN_SET.RUN.DATA_BLOCK.format_code'} = '';                                        # static data

    #$Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = 'get_number_of_reads_and_data_block_name';
    #$Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = 'Data_Block_Name'; # Run attribute
    $Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = "`RUN_SET.RUN.DATA_BLOCK.name`";

    $Alias{'RUN_SET.RUN.DATA_BLOCK.number_channels'} = '';                                              # static data
    $Alias{'RUN_SET.RUN.DATA_BLOCK.region'}          = '';                                              # static data
    $Alias{'RUN_SET.RUN.DATA_BLOCK.sector'}          = "`RUN_SET.RUN.DATA_BLOCK.sector`";               # 'lane';

    #$Alias{'RUN_SET.RUN.DATA_BLOCK.total_reads'} = 'get_number_of_reads_and_data_block_name'; # function input
    $Alias{'RUN_SET.RUN.DATA_BLOCK.total_reads'} = "`RUN_SET.RUN.DATA_BLOCK.total_reads`";              # 'submission_run_total_reads';

    $Alias{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename'} = "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`";
    $Alias{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filetype'} = '';                                               # static data

    $Alias{'RUN_SET.RUN.RUN_ATTRIBUTES.RUN_ATTRIBUTE.TAG.RUN'} = 'run_id';

    $static_data{'RUN_SET.xmlns:xsi'}                          = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'RUN_SET.xsi:noNamespaceSchemaLocation'}      = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.run.xsd';
    $static_data{'RUN_SET.RUN.run_center'}                     = 'BCCAGSC';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filetype'} = 'srf';
    $static_data{'RUN_SET.RUN.total_data_blocks'}              = '1';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.format_code'}         = '1';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.number_channels'}     = '4';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.region'}              = '0';

    push @template_header, 'RUN_SET';

    $hash{schema}          = $schema;
    $hash{template}        = $template;
    $hash{field}           = \@fields;
    $hash{required_field}  = \@required_fields;
    $hash{TAG}             = \%TAGs;
    $hash{Alia}            = \%Alias;
    $hash{custom_config}   = \%custom_configs;
    $hash{static_data}     = \%static_data;
    $hash{template_header} = \@template_header;
    $hash{function_input}  = \@function_input;

    YAML::DumpFile( $config_path . 'run_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_fastq_run_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.run.xsd";
    my $template        = $config_path . 'run_template.xml';
    my $source_template = "$source_xml_template_path/run_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @template_header;
    my @function_input;

    push @fields,
        (
        "run_name",
        'current_model',
        'machine',
        'run_time_xml_datetime_format',
        'run_id',
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SolexaRun.Lane WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'NA' END AS `RUN_SET.RUN.DATA_BLOCK.sector`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( '190-9?_', Library_Name, '_', Flowcell.Flowcell_Code, '_LANE', SolexaRun.Lane, '.fastq' ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SOLIDRun.Lane, '.srf' ) END AS `RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SUM( Solexa_Read.Number_Reads ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `RUN_SET.RUN.DATA_BLOCK.total_reads`",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( 'SOLEXA', substr(Equipment.Equipment_Name,4) ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `RUN_SET.RUN.DATA_BLOCK.name`",
        "Library_Name",
        "study_description",
        );

#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Library.Library_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Library.Library_Name, '_', 'SOLID specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
#	'Data_Block_Name',

## for LS_454
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SolexaRun.Lane WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'NA' WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN 'NA' END AS `RUN_SET.RUN.DATA_BLOCK.sector`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SolexaRun.Lane, '.srf' ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', SOLIDRun.Lane, '.srf' ) WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN CONCAT( 'Run', Run.Run_ID, 'Lane', LS_454Run.Lane, '.srf' ) END AS `RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN CONCAT( Sample.Sample_Name, '_', '454 specific container id' ) END AS `RUN_SET.RUN.EXPERIMENT_REF.refname`",
#	"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SUM( Solexa_Read.Number_Reads ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' WHEN (Equipment_Category.Sub_Category = 'LS_454') THEN SUM( LS_454Analysis.Number_Reads ) END AS `RUN_SET.RUN.DATA_BLOCK.total_reads`",

    if ( $name =~ /EDACC/i ) {
        push @required_fields,
            ( "run_name", 'current_model', 'machine', 'run_time_xml_datetime_format', 'run_id', "`RUN_SET.RUN.DATA_BLOCK.sector`", "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`", "`RUN_SET.RUN.EXPERIMENT_REF.refname`", "`RUN_SET.RUN.DATA_BLOCK.name`", );

        #	"`RUN_SET.RUN.DATA_BLOCK.total_reads`",

    }
    else {
        push @required_fields, ( 'run_name', 'current_model', 'machine', 'run_time_xml_datetime_format', 'run_id', "`RUN_SET.RUN.DATA_BLOCK.sector`", "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`", );

    }

    #push @function_input, (
    #	'get_number_of_reads_and_data_block_name',
    #);

    $TAGs{'RUN_SET.RUN.RUN_ATTRIBUTES.RUN_ATTRIBUTE.TAG'} = [ 'run', ];

## alias from XML Tag names -> LIMS alias names
    $Alias{'RUN_SET.xmlns:xsi'}                     = '';    # static data
    $Alias{'RUN_SET.xsi:noNamespaceSchemaLocation'} = '';    # static data

    $Alias{'RUN_SET.RUN.alias'}             = "run_name";
    $Alias{'RUN_SET.RUN.instrument_model'}  = 'current_model';                  # attribute
    $Alias{'RUN_SET.RUN.instrument_name'}   = 'machine';
    $Alias{'RUN_SET.RUN.run_center'}        = '';                               # static data
    $Alias{'RUN_SET.RUN.run_date'}          = 'run_time_xml_datetime_format';
    $Alias{'RUN_SET.RUN.total_data_blocks'} = '';                               # static data

    $Alias{'RUN_SET.RUN.EXPERIMENT_REF.refname'} = "`RUN_SET.RUN.EXPERIMENT_REF.refname`";    # "submission_experiment_alias";

    $Alias{'RUN_SET.RUN.DATA_BLOCK.format_code'} = '';                                        # static data

    #$Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = 'get_number_of_reads_and_data_block_name';
    #$Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = 'Data_Block_Name'; # Run attribute
    $Alias{'RUN_SET.RUN.DATA_BLOCK.name'} = "`RUN_SET.RUN.DATA_BLOCK.name`";

    $Alias{'RUN_SET.RUN.DATA_BLOCK.number_channels'} = '';                                    # static data
    $Alias{'RUN_SET.RUN.DATA_BLOCK.region'}          = '';                                    # static data
    $Alias{'RUN_SET.RUN.DATA_BLOCK.sector'}          = "`RUN_SET.RUN.DATA_BLOCK.sector`";     # 'lane';

    #$Alias{'RUN_SET.RUN.DATA_BLOCK.total_reads'} = 'get_number_of_reads_and_data_block_name'; # function input
    $Alias{'RUN_SET.RUN.DATA_BLOCK.total_reads'} = "`RUN_SET.RUN.DATA_BLOCK.total_reads`";    # 'submission_run_total_reads';

    $Alias{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename'} = "`RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filename`";
    $Alias{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filetype'} = '';                                               # static data

    $Alias{'RUN_SET.RUN.RUN_ATTRIBUTES.RUN_ATTRIBUTE.TAG.run'} = 'run_id';

    $static_data{'RUN_SET.xmlns:xsi'}                          = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'RUN_SET.xsi:noNamespaceSchemaLocation'}      = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.run.xsd';
    $static_data{'RUN_SET.RUN.run_center'}                     = 'BCCAGSC';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.FILES.FILE.filetype'} = 'fastq';
    $static_data{'RUN_SET.RUN.total_data_blocks'}              = '1';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.format_code'}         = '1';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.number_channels'}     = '4';
    $static_data{'RUN_SET.RUN.DATA_BLOCK.region'}              = '0';

    push @template_header, 'RUN_SET';

    $hash{schema}          = $schema;
    $hash{template}        = $template;
    $hash{field}           = \@fields;
    $hash{required_field}  = \@required_fields;
    $hash{TAG}             = \%TAGs;
    $hash{Alia}            = \%Alias;
    $hash{custom_config}   = \%custom_configs;
    $hash{static_data}     = \%static_data;
    $hash{template_header} = \@template_header;
    $hash{function_input}  = \@function_input;

    YAML::DumpFile( $config_path . 'run_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

=begin
#################################
# Set the common analysis config. This should apply to all templates
#
# Return: Hash ref
##################################
sub set_common_analysis_config_old {
##################################
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'config_path', -mandatory => 'config_path' );
    my $config_path     = $args{-config_path};
    my @fields          = ();
    my @function_input  = ();
    my @user_input      = ();
    my @required_fields = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases         = ();
    my %static_data     = ();
    my %custom_configs  = ();

    my @template_header = ('ANALYSIS_SET');
    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.analysis.xsd";
    my $template        = $config_path . 'analysis_template.xml';

    ## custom configs
    $custom_configs{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'} = {
        'ASSEMBLY'              => $config_path . 'analysis_analysis_type_assembly_config.yml',
        'REFERENCE_ALIGNMENT'   => $config_path . 'analysis_analysis_type_refAlignment_config.yml',
        'SEQUENCE_ANNOTATION'   => $config_path . 'analysis_analysis_type_seqAnnotation_config.yml',
        'ABUNDANCE_MEASUREMENT' => $config_path . 'analysis_analysis_type_abdMeasurement_config.yml',
        'REPORT'                => $config_path . 'analysis_analysis_type_report_config.yml',
    };

    ## common fields for all templates
    push @fields,
        (
        'study',
        'project',
        'library',
        'trace_submission_id',
        'submission_volume_name',
        "GROUP_CONCAT( distinct CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END ) AS experiment_aliases",
        );

    push @function_input,
        (
        "get_analysis_file_name(submission_volume_name,library) AS analysis_file_name",
        "get_analysis_file_checksum(submission_volume_name,library) AS analysis_file_checksum",
        "get_analysis_file_type(submission_volume_name) AS analysis_file_type",
        "get_analysis_type(submission_volume_name) AS analysis_type",
        "get_target_sra_object_type(submission_volume_name) AS target_sra_object_type",
        "get_analysis_study_accession(submission_volume_name) AS analysis_study_accession",
        "get_analysis_target_refname(submission_volume_name,library) AS analysis_target_refname",
        "get_analysis_description(submission_volume_name) AS Analysis_Description",
        );

    push @required_fields, ( 'study', );

    ## alias from XML Tag names
    $aliases{'ANALYSIS_SET.xmlns:xsi'}                     = '';                           # static
    $aliases{'ANALYSIS_SET.xsi:noNamespaceSchemaLocation'} = '';                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.alias'}                = "library";
    $aliases{'ANALYSIS_SET.ANALYSIS.center_name'}          = '';                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.TITLE'}                = 'library';
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.accession'}  = 'analysis_study_accession';

    #$aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.refname'}          = 'study';
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.refcenter'}                     = '';                           # when absent, the namespace is assumed to be the current submission
    $aliases{'ANALYSIS_SET.ANALYSIS.DESCRIPTION'}                             = "Analysis_Description";       # get from the input file analysis_manifest.xml
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'}                           = "analysis_type";              # customizable;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.sra_object_type'} = "target_sra_object_type";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.accession'}       = "";                           # get from input if needed
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.refname'}         = "analysis_target_refname";    # generate automatically base on sra_object_type
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.refcenter'}       = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.filename'}            = "analysis_file_name";         #;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.filetype'}            = "analysis_file_type";         #;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.checksum_method'}     = '';                           # static;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.checksum'}            = "analysis_file_checksum";     #;

    ## static data
    $static_data{'ANALYSIS_SET.xmlns:xsi'}                                    = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'ANALYSIS_SET.xsi:noNamespaceSchemaLocation'}                = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.analysis.xsd';
    $static_data{'ANALYSIS_SET.ANALYSIS.center_name'}                         = 'BCCAGSC';
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.refcenter'}   = "NCBI";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.checksum_method'} = 'MD5';

    my %return;
    $return{'source_template'} = "analysis_template_no_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;
    $return{'custom_config'}   = \%custom_configs;
    $return{'schema'}          = $schema;
    $return{'template'}        = $template;
    $return{'template_header'} = \@template_header;

    return \%return;
}
=cut

sub set_NCBI_TCGA_analysis_config {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @fields, (
        "library",

#"Group_CONCAT( distinct CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END ) AS EXPERIMENT_REFs",
#"CONCAT( library, '_2_lanes_dupsFlagged.bam' ) AS ANALYSIS_filename",
    );

    #		"CONCAT( '/projects/analysis/analysis5/', library, '/meta_bwa/', library, '_2_lanes_dupsFlagged.bam' ) AS ANALYSIS_filename_with_path",

    push @function_input, (
        "submission_concat('Reference alignment of ',library) AS TCGA_title",
        "get_analysis_target_refcenter(submission_volume_name,library) AS analysis_target_refcenter",

        #"submission_concat(EXPERIMENT_REFs,-noescape) AS EXPERIMENT_REF",    # just want to substitute ',' with ',,'
        "get_file_checksum(ANALYSIS_filename) AS FILE_checksum",
    );
    push @required_fields, ( "library", "ANALYSIS_filename", );

    ## TAGs
    #push @tags, ( 'alignment_program', 'alignment_program_version', 'reference_genome', );

    ## aliases
    $aliases{'ANALYSIS_SET.ANALYSIS.alias'}                                   = "library";
    $aliases{'ANALYSIS_SET.ANALYSIS.TITLE'}                                   = 'TCGA_title';
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.accession'}                     = '';                            # static
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.refname'}                       = '';
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'}                           = "";                            # static;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.sra_object_type'} = "";                            # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.refname'}         = "EXPERIMENT_REF";              # use EXPERIMENT alias
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.filename'}            = "ANALYSIS_filename";           #;
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.filetype'}            = "";                            # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.checksum'}            = "FILE_checksum";               #;
    $aliases{'ANALYSIS_SET.ANALYSIS.TARGETS.TARGET.refcenter'}                = "analysis_target_refcenter";

    ## static data
    $static_data{'ANALYSIS_SET.ANALYSIS.STUDY_REF.accession'}          = 'SRP000677';                          # static
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'}                = "REFERENCE_ALIGNMENT";                # customizable;
                                                                                                               #$static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TARGETS.TARGET.sra_object_type'} = "EXPERIMENT";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_FILES.FILE.filetype'} = ".bam";                               # static

    $return{'source_template'} = "analysis_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

=begin
sub set_NCBI_EZH2_analysis_config_old {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @function_input,
        (
        "submission_concat('Reference alignment of DLBCL tumor sample ',library) AS Analysis_Title",
        "get_analysis_date(submission_volume_name,library) AS Analysis_Date",
        "get_processing_directive('withJunctionsOnGenome',submission_volume_name,library) AS With_Junctions_On_Genome",
        "get_processing_directive('dupsFlagged',submission_volume_name,library) AS Duplicates_Flagged",
        "is_chastity_failed_reads_removed(submission_volume_name,library) AS Chastity_Removed",
        );

    #        "get_processing_directive('chastityFlagged',submission_volume_name,library) AS Chastity_Flagged",
    #        "is_chastity_failed_reads_included(submission_volume_name,library) AS Chastity_Failed_Reads_Included",
    #        "is_shadow_reads_included(submission_volume_name,library) AS Shadow_Reads_Included",

    ## TAGs
    push @tags, (
        'Alignment_Program',
        'Reference_Assembly',
        'Analysis_Date',    # this should be the date stamp of the bam file in ISO format
        'With_Junctions_On_Genome',
        'Duplicates_Flagged',
        'Unaligned_Reads_Included',
        'Duplicate_Reads_Removed',
        'Chastity_Removed',
    );

    #	'Alignment_Program_Version',
    #	'Chastity_Failed_Reads_Included',
    #	'Shadow_Reads_Included'

    ## aliases
    $aliases{'ANALYSIS_SET.ANALYSIS.TITLE'} = "Analysis_Title";

    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_LINKS.ANALYSIS_LINK.URL_LINK.LABEL'} = "library";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_LINKS.ANALYSIS_LINK.URL_LINK.URL'}   = "";

    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Alignment_Program'}         = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Alignment_Program_Version'} = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Reference_Assembly'}        = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Analysis_Date'}             = "Analysis_Date";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.With_Junctions_On_Genome'}  = "With_Junctions_On_Genome";

    #$aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Chastity_Flagged'}          = "Chastity_Flagged";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Duplicates_Flagged'} = "Duplicates_Flagged";

    #$aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Chastity_Failed_Reads_Included'}          = "Chastity_Failed_Reads_Included";
    #$aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Shadow_Reads_Included'}          = "Shadow_Reads_Included";

    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Unaligned_Reads_Included'} = "";                            # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Duplicate_Reads_Removed'}  = "";                            # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Chastity_Removed'}         = "Chastity_Removed";

    ## static data
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Alignment_Program'}  = "BWA 0.7.1";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Reference_Assembly'} = "NCBI_36_Ensembl_variant";

    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Unaligned_Reads_Included'} = "Yes";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Duplicate_Reads_Removed'}  = "No";

    #$static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Chastity_Removed'}          = "No"; ## ? need to check

    $return{'source_template'} = "analysis_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}
=cut

#################################
# Set the common analysis config.
#
# Return: Hash ref
##################################
sub set_common_analysis_config {
##################################
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'config_path', -mandatory => 'config_path' );
    my $config_path     = $args{-config_path};
    my @fields          = ();
    my @function_input  = ();
    my @user_input      = ();
    my @required_fields = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases         = ();
    my %static_data     = ();
    my %custom_configs  = ();

    my @template_header = ('ANALYSIS_SET');
    my $schema          = "http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-2/SRA.analysis.xsd";
    my $template        = $config_path . 'analysis_template.xml';

    ## custom configs
    $custom_configs{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'} = { 'REFERENCE_ALIGNMENT' => $config_path . 'analysis_analysis_type_refAlignment_config.yml', };

    ## common fields for all templates
    push @fields, (
        'library',
        'study',
        'project',
        'trace_submission_id',
        'submission_volume_name',
        "GROUP_CONCAT( distinct Sample.Sample_Name ) AS experiment_aliases",

#"GROUP_CONCAT( distinct CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END ) AS experiment_aliases",
    );

    push @function_input,
        (
        "get_analysis_date(submission_volume_name,library) AS Analysis_Date",
        "get_analysis_study_accession(submission_volume_name) AS analysis_study_accession",
        "get_analysis_description(submission_volume_name) AS Analysis_Description",
        "get_analysis_type(submission_volume_name) AS analysis_type",
        "get_target_sra_object_type(submission_volume_name) AS target_sra_object_type",
        "get_analysis_target_refname(submission_volume_name,library) AS analysis_target_refname",
        "get_analysis_file_name(submission_volume_name,library) AS analysis_file_name",
        "get_analysis_file_type(submission_volume_name) AS analysis_file_type",
        "get_analysis_file_checksum(submission_volume_name,library) AS analysis_file_checksum",
        );

    push @required_fields, ('library');

    ## alias
    $aliases{'ANALYSIS_SET.xmlns:xsi'}                     = '';                # static
    $aliases{'ANALYSIS_SET.xsi:noNamespaceSchemaLocation'} = '';                # static
    $aliases{'ANALYSIS_SET.ANALYSIS.alias'}                = "library";
    $aliases{'ANALYSIS_SET.ANALYSIS.center_name'}          = '';                # static
    $aliases{'ANALYSIS_SET.ANALYSIS.broker_name'}          = '';                #
    $aliases{'ANALYSIS_SET.ANALYSIS.analysis_center'}      = '';                # static
    $aliases{'ANALYSIS_SET.ANALYSIS.analysis_date'}        = 'Analysis_Date';

    $aliases{'ANALYSIS_SET.ANALYSIS.TITLE'}               = 'library';
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.accession'} = 'analysis_study_accession';

    #$aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.refname'}          = 'study';
    $aliases{'ANALYSIS_SET.ANALYSIS.STUDY_REF.refcenter'}            = '';                           # when absent, the namespace is assumed to be the current submission
    $aliases{'ANALYSIS_SET.ANALYSIS.DESCRIPTION'}                    = "Analysis_Description";       # get from the input file analysis_manifest.xml
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE'}                  = "analysis_type";              # customizable;
    $aliases{'ANALYSIS_SET.ANALYSIS.TARGETS.TARGET.sra_object_type'} = "target_sra_object_type";
    $aliases{'ANALYSIS_SET.ANALYSIS.TARGETS.TARGET.accession'}       = "";                           # get from input if needed
    $aliases{'ANALYSIS_SET.ANALYSIS.TARGETS.TARGET.refname'}         = "analysis_target_refname";    # generate automatically base on sra_object_type
                                                                                                     #$aliases{'ANALYSIS_SET.ANALYSIS.TARGETS.TARGET.refcenter'}       = "";                           # static

    $aliases{'ANALYSIS_SET.ANALYSIS.DATA_BLOCK.FILES.FILE.filename'}        = "analysis_file_name";        #;
    $aliases{'ANALYSIS_SET.ANALYSIS.DATA_BLOCK.FILES.FILE.filetype'}        = "analysis_file_type";        #;
    $aliases{'ANALYSIS_SET.ANALYSIS.DATA_BLOCK.FILES.FILE.checksum_method'} = '';                          # static;
    $aliases{'ANALYSIS_SET.ANALYSIS.DATA_BLOCK.FILES.FILE.checksum'}        = "analysis_file_checksum";    #;

    ## static data
    $static_data{'ANALYSIS_SET.xmlns:xsi'}                     = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'ANALYSIS_SET.xsi:noNamespaceSchemaLocation'} = $schema;
    $static_data{'ANALYSIS_SET.ANALYSIS.center_name'}          = 'BCCAGSC';

    #$static_data{'ANALYSIS_SET.ANALYSIS.broker_name'}          = 'dbGaP';
    $static_data{'ANALYSIS_SET.ANALYSIS.analysis_center'}                       = 'BCCAGSC';
    $static_data{'ANALYSIS_SET.ANALYSIS.DATA_BLOCK.FILES.FILE.checksum_method'} = 'MD5';

    my %return;
    $return{'source_template'} = "analysis_template_no_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;
    $return{'custom_config'}   = \%custom_configs;
    $return{'schema'}          = $schema;
    $return{'template'}        = $template;
    $return{'template_header'} = \@template_header;

    return \%return;
}

sub set_analysis_ref_alignment_config {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @function_input, ( "get_processing_directive('dupsFlagged',submission_volume_name,library) AS Duplicates_Flagged", );

    ## TAGs
    #push @tags, ();

    ## aliases
    #  set value in specific project submission config for the following aliases
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.ASSEMBLY.STANDARD.short_name'}                             = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.section_name'}            = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.STEP_INDEX'}              = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PREV_STEP_INDEX'}         = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.NOTES'}                   = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_unaligned_reads'} = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_marks_duplicate_reads'}    = "Duplicates_Flagged";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_failed_reads'}    = "";

    $return{'source_template'} = "analysis_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

sub set_NCBI_EZH2_analysis_config {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @function_input,
        (
        "submission_concat('Reference alignment of DLBCL tumor sample ',library) AS Analysis_Title",
        "get_processing_directive('withJunctionsOnGenome',submission_volume_name,library) AS With_Junctions_On_Genome",
        "is_chastity_failed_reads_removed(submission_volume_name,library) AS Chastity_Removed",
        );

    ## TAGs
    push @tags, ( 'With_Junctions_On_Genome', 'Duplicate_Reads_Removed', 'Chastity_Removed', );

    ## aliases
    $aliases{'ANALYSIS_SET.ANALYSIS.TITLE'} = "Analysis_Title";

    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.ASSEMBLY.STANDARD.short_name'}                             = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.section_name'}            = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.STEP_INDEX'}              = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PREV_STEP_INDEX'}         = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.NOTES'}                   = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_unaligned_reads'} = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_failed_reads'}    = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.With_Junctions_On_Genome'}                        = "With_Junctions_On_Genome";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Duplicate_Reads_Removed'}                         = "";                           # static
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Chastity_Removed'}                                = "Chastity_Removed";

    ## static data
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.ASSEMBLY.STANDARD.short_name'}                             = "NCBI36_BCCAGSC_variant";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.section_name'}            = "Alignment";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.STEP_INDEX'}              = "1";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PREV_STEP_INDEX'}         = "NIL";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'}                 = "BWA";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'}                 = "0.7.1";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_unaligned_reads'} = "true";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_failed_reads'}    = "true";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG.Duplicate_Reads_Removed'}                         = "false";

    $return{'source_template'} = "analysis_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

###########################################
# Create config for SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_config();
#
# Return:	None
#############################################
sub create_analysis_config {
#################################
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %TAGs;

    my $config_href = $self->set_common_analysis_config( -config_path => $config_path );

    #print "common configs:\n";
    #print Dumper $config_href;

    ################## special templates ###################
    if ( $name =~ /NCBI_.*_TCGA/ ) {

        #my $custom = $self->set_analysis_ref_alignment_config();
        #$config_href = $self->merge_config( -general => $config_href, -custom => $custom );
        my $custom = $self->set_NCBI_TCGA_analysis_config();
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );
    }
    elsif ( $name =~ /NCBI_.*_EZH2/ ) {
        my $custom = $self->set_NCBI_EZH2_analysis_config();

        #print "EZH2 config:\n";
        #print Dumper $custom;
        $config_href = $self->merge_config( -general => $config_href, -custom => $custom );

        #print "after merge:\n";
        #print Dumper $config_href;
    }

    my $source_template = "$source_xml_template_path/SRA_1-2/" . $config_href->{source_template};
    my $template        = $config_href->{template};

    my %hash;
    $hash{schema}                                                             = $config_href->{schema};
    $hash{template}                                                           = $template;
    $hash{custom_config}                                                      = $config_href->{custom_config};
    $hash{template_header}                                                    = $config_href->{template_header};
    $hash{field}                                                              = $config_href->{fields};
    $hash{required_field}                                                     = $config_href->{required_fields};
    $hash{user_input}                                                         = $config_href->{user_input};
    $hash{use_NA_if_null}                                                     = $config_href->{use_NA_if_null};
    $hash{function_input}                                                     = $config_href->{function_input};
    $TAGs{'ANALYSIS_SET.ANALYSIS.ANALYSIS_ATTRIBUTES.ANALYSIS_ATTRIBUTE.TAG'} = $config_href->{tags};
    $hash{TAG}                                                                = \%TAGs;
    $hash{Alia}                                                               = $config_href->{aliases};
    $hash{static_data}                                                        = $config_href->{static_data};

    YAML::DumpFile( $config_path . 'analysis_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

###########################################
# Create config for the analysis type ASSEMBLY of the SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_analysis_type_assembly_config();
#
# Return:	None
#############################################
sub create_analysis_analysis_type_assembly_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'analysis_analysis_type_assembly_template.xml';
    my $source_template = "$source_xml_template_path/analysis_analysis_type_assembly_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'analysis_analysis_type_assembly_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

###########################################
# Create config for the analysis type REFERENCE_ALIGNMENT of the SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_analysis_type_refAlignment_config();
#
# Return:	None
#############################################
sub create_analysis_analysis_type_refAlignment_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'analysis_analysis_type_refAlignment_template.xml';
    my $source_template = "$source_xml_template_path/SRA_1-2/analysis_analysis_type_refAlignment_template.xml";
    my @fields;
    my @required_fields;
    my @function_input = ();
    my %TAGs;
    my %aliases;
    my %custom_configs;
    my %static_data;

    push @function_input, ( "get_processing_directive('dupsFlagged',submission_volume_name,library) AS Duplicates_Flagged", );

    ## TAGs
    #push @tags, ();

    ## aliases

    +    #  set value in specific project submission config for the following aliases
        $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.ASSEMBLY.STANDARD.short_name'}                         = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.section_name'}            = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.STEP_INDEX'}              = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PREV_STEP_INDEX'}         = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'}                 = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.NOTES'}                   = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_unaligned_reads'} = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_marks_duplicate_reads'}    = "";
    $aliases{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_failed_reads'}    = "";

    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.ASSEMBLY.STANDARD.short_name'}                             = "NCBI36_BCCAGSC_variant";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.section_name'}            = "Alignment";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.STEP_INDEX'}              = "1";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PREV_STEP_INDEX'}         = "NIL";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'}                 = "BWA";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'}                 = "0.7.1";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_unaligned_reads'} = "true";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_marks_duplicate_reads'}    = "true";
    $static_data{'ANALYSIS_SET.ANALYSIS.ANALYSIS_TYPE.REFERENCE_ALIGNMENT.PROCESSING.DIRECTIVES.alignment_includes_failed_reads'}    = "true";

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{function_input} = \@function_input;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%aliases;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'analysis_analysis_type_refAlignment_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

###########################################
# Create config for the analysis type SEQUENCE_ANNOTATION of the SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_analysis_type_assembly_config();
#
# Return:	None
#############################################
sub create_analysis_analysis_type_seqAnnotation_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'analysis_analysis_type_seqAnnotation_template.xml';
    my $source_template = "$source_xml_template_path/analysis_analysis_type_seqAnnotation_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'analysis_analysis_type_seqAnnotation_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

###########################################
# Create config for the analysis type ABUNDANCE_MEASUREMENT of the SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_analysis_type_assembly_config();
#
# Return:	None
#############################################
sub create_analysis_analysis_type_abdMeasurement_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'analysis_analysis_type_abdMeasurement_template.xml';
    my $source_template = "$source_xml_template_path/analysis_analysis_type_abdMeasurement_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'analysis_analysis_type_abdMeasurement_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

###########################################
# Create config for the analysis type REPORT of the SRA ANALYSIS object.
# This subroutine will create the YAML config file and copy over the xml template
#
# Usage:	create_analysis_analysis_type_assembly_config();
#
# Return:	None
#############################################
sub create_analysis_analysis_type_report_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $template        = $config_path . 'analysis_analysis_type_report_template.xml';
    my $source_template = "$source_xml_template_path/analysis_analysis_type_report_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;

    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;

    YAML::DumpFile( $config_path . 'analysis_analysis_type_report_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_submission_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;

    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd";
    my $template        = $config_path . 'submission_template.xml';
    my $source_template = "$source_xml_template_path/submission_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @user_input;
    my @function_input;

    push @fields, ( 'submission_volume_name', );

    if ( $name =~ /EDACC/i ) {
        @required_fields = @fields;
    }
    else {
        push @required_fields, ( 'submission_volume_name', );
    }

    push @user_input, ();

    #		'submission_name',
    #		'contact_name',
    #		'submission_comment',

    push @function_input, ( 'current_xml_dateTime', 'submission_action', 'submission_add_source', 'submission_add_schema', 'submission_filename', 'submission_checksum', );

=begin
	$custom_configs{'SUBMISSION.ACTIONS.ACTION'} = {
			'ADD'	=>	$config_path . 'submission_action_add_config.yml',
	};
=cut

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SUBMISSION.xmlns:xsi'}                     = '';    # static data
    $Alias{'SUBMISSION.xsi:noNamespaceSchemaLocation'} = '';    # static data

    $Alias{'SUBMISSION.center_name'}                       = '';                         # static data
    $Alias{'SUBMISSION.lab_name'}                          = 'lab_name';                 # user input
                                                                                         #$Alias{'SUBMISSION.submission_comment'} = 'submission_comment'; # user input
    $Alias{'SUBMISSION.submission_comment'}                = '';                         # leave blank
    $Alias{'SUBMISSION.submission_date'}                   = 'current_xml_dateTime';     # function input
                                                                                         #$Alias{'SUBMISSION.submission_id'} = 'submission_name'; # user input
    $Alias{'SUBMISSION.alias'}                             = 'submission_volume_name';
    $Alias{'SUBMISSION.CONTACTS.CONTACT.name'}             = '';                         # leave blank
    $Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = '';                         # static data
    $Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'}  = '';                         # static data
                                                                                         #$Alias{'SUBMISSION.ACTIONS.requestor'} = 'action_requestor'; # user input
                                                                                         #$Alias{'SUBMISSION.ACTIONS.request_date'} = 'current_xml_dateTime'; # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION'}                    = 'submission_action';        # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION.ADD.source'}         = 'submission_add_source';    # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION.ADD.schema'}         = 'submission_add_schema';    # function input
    $Alias{'SUBMISSION.FILES.FILE.checksum'}               = 'submission_checksum';      # function input
    $Alias{'SUBMISSION.FILES.FILE.filename'}               = 'submission_filename';      # function input
    $Alias{'SUBMISSION.FILES.FILE.checksum_method'}        = '';                         # static data

    $static_data{'SUBMISSION.xmlns:xsi'}                         = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'SUBMISSION.xsi:noNamespaceSchemaLocation'}     = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd';
    $static_data{'SUBMISSION.center_name'}                       = 'BCCAGSC';
    $static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = 'aldente@bcgsc.ca';
    $static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'}  = 'aldente@bcgsc.ca';
    $static_data{'SUBMISSION.FILES.FILE.checksum_method'}        = 'MD5';

    $hash{schema}         = $schema;
    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{user_input}     = \@user_input;
    $hash{function_input} = \@function_input;

    YAML::DumpFile( $config_path . 'submission_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

sub create_submission_run_config {
    my $self                     = shift;
    my $name                     = $self->{name};
    my $config_path              = $self->{config_path};
    my $source_xml_template_path = $self->{source_xml_template_path};

    my %hash;
    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd";
    my $template        = $config_path . 'submission_template.xml';
    my $source_template = "$source_xml_template_path/submission_template.xml";
    my @fields;
    my @required_fields;
    my %TAGs;
    my %Alias;
    my %custom_configs;
    my %static_data;
    my @user_input;
    my @function_input;

    push @fields, ( "submission_volume_name", "run_id", "lane", );

    #		"CASE WHEN LENGTH(submission_volume_name) > 0 THEN CONCAT( submission_volume_name, '_run', run_id) END AS submission_run_submission_id",

    push @required_fields, ( "submission_volume_name", "run_id", "lane", );

    #		'submission_run_submission_id',

    push @user_input, ();

    #		'contact_name',
    #		'submission_comment',

    push @function_input, ( 'current_xml_dateTime', 'submission_run_action', 'submission_run_add_source', 'submission_run_add_schema', 'submission_run_filename', 'submission_run_checksum', );

    ## alias from XML Tag names -> LIMS alias names
    $Alias{'SUBMISSION.xmlns:xsi'}                     = '';    # static data
    $Alias{'SUBMISSION.xsi:noNamespaceSchemaLocation'} = '';    # static data

    $Alias{'SUBMISSION.center_name'}                       = '';                             # static data
    $Alias{'SUBMISSION.lab_name'}                          = 'lab_name';                     # user input
                                                                                             #$Alias{'SUBMISSION.submission_comment'} = 'submission_comment'; # user input
    $Alias{'SUBMISSION.submission_comment'}                = '';                             # leave blank
    $Alias{'SUBMISSION.submission_date'}                   = 'current_xml_dateTime';         # function input
                                                                                             #$Alias{'SUBMISSION.submission_id'} = 'submission_volume_name';
                                                                                             #$Alias{'SUBMISSION.submission_id'} = 'submission_run_submission_id';
    $Alias{'SUBMISSION.alias'}                             = 'submission_volume_name';
    $Alias{'SUBMISSION.CONTACTS.CONTACT.name'}             = '';                             # leave blank
    $Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = '';                             # static data
    $Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'}  = '';                             # static data
                                                                                             #$Alias{'SUBMISSION.ACTIONS.requestor'} = 'action_requestor'; # user input
                                                                                             #$Alias{'SUBMISSION.ACTIONS.request_date'} = 'current_xml_dateTime'; # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION'}                    = 'submission_run_action';        # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION.ADD.source'}         = 'submission_run_add_source';    # function input
    $Alias{'SUBMISSION.ACTIONS.ACTION.ADD.schema'}         = 'submission_run_add_schema';    # function input
    $Alias{'SUBMISSION.FILES.FILE.checksum'}               = 'submission_run_checksum';      # function input
    $Alias{'SUBMISSION.FILES.FILE.filename'}               = 'submission_run_filename';      # function input
    $Alias{'SUBMISSION.FILES.FILE.checksum_method'}        = '';                             # static data

    $static_data{'SUBMISSION.xmlns:xsi'}                         = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'SUBMISSION.xsi:noNamespaceSchemaLocation'}     = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd';
    $static_data{'SUBMISSION.center_name'}                       = 'BCCAGSC';
    $static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = 'aldente@bcgsc.ca';
    $static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'}  = 'aldente@bcgsc.ca';
    $static_data{'SUBMISSION.FILES.FILE.checksum_method'}        = 'MD5';

    $hash{schema}         = $schema;
    $hash{template}       = $template;
    $hash{field}          = \@fields;
    $hash{required_field} = \@required_fields;
    $hash{TAG}            = \%TAGs;
    $hash{Alia}           = \%Alias;
    $hash{custom_config}  = \%custom_configs;
    $hash{static_data}    = \%static_data;
    $hash{user_input}     = \@user_input;
    $hash{function_input} = \@function_input;
    YAML::DumpFile( $config_path . 'submission_run_config.yml', \%hash );
    try_system_command( -command => "cp $source_template $template" );
}

=begin
sub create_submission_add_run_config {
	my $self = shift;
	my $name = $self->{name};
	my $config_path = $self->{config_path};
	my $source_xml_template_path = $self->{source_xml_template_path};

my %hash;

my 		$schema = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd";
my    	$template = $config_path . 'submission_template.xml';
my		$source_template = 	"$source_xml_template_path/submission_template.xml";
my    	@fields;
my		@required_fields;
my		%TAGs;
my		%Alias;
my		%custom_configs;
my   	%static_data;
my 		@user_input;
my		@function_input;

push @fields, (
);

if( $name =~ /EDACC/i ) {
	@required_fields = @fields;
}
else {
	push @required_fields, (
	);

}

push @user_input, (
	'submission_name',
	'submission_comment',
	'contact_name',
);

push @function_input, (
	'current_xml_dateTime',
	'submission_add_run_source',
	'submission_filename',
	'submission_checksum',
);

## alias from XML Tag names -> LIMS alias names 
$Alias{'SUBMISSION.xmlns:xsi'} = ''; # static data
$Alias{'SUBMISSION.xsi:noNamespaceSchemaLocation'} = ''; # static data

$Alias{'SUBMISSION.center_name'} = ''; # static data
$Alias{'SUBMISSION.lab_name'} = 'lab_name'; # user input
$Alias{'SUBMISSION.submission_comment'} = 'submission_comment'; # user input
$Alias{'SUBMISSION.submission_date'} = 'current_xml_dateTime'; # function input
$Alias{'SUBMISSION.submission_id'} = 'submission_name'; # user input
$Alias{'SUBMISSION.CONTACTS.CONTACT.name'} = 'contact_name'; # user input
$Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = ''; # static data
$Alias{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'} = ''; # static data
#$Alias{'SUBMISSION.ACTIONS.requestor'} = 'action_requestor'; # user input
#$Alias{'SUBMISSION.ACTIONS.request_date'} = 'current_xml_dateTime'; # function input
$Alias{'SUBMISSION.ACTIONS.ACTION'} = ''; # static
$Alias{'SUBMISSION.ACTIONS.ACTION.ADD.source'} = 'submission_add_run_source'; # function input
$Alias{'SUBMISSION.ACTIONS.ACTION.ADD.schema'} = ''; # static
$Alias{'SUBMISSION.FILES.FILE.checksum'} = 'submission_checksum'; # function input
$Alias{'SUBMISSION.FILES.FILE.filename'} = 'submission_filename'; # function input
$Alias{'SUBMISSION.FILES.FILE.checksum_method'} = ''; # static data


$static_data{'SUBMISSION.xmlns:xsi'} = 'http://www.w3.org/2001/XMLSchema-instance';
$static_data{'SUBMISSION.xsi:noNamespaceSchemaLocation'} = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.submission.xsd';
$static_data{'SUBMISSION.center_name'} = 'BCCAGSC';
$static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_status'} = 'aldente@bcgsc.ca'; 
$static_data{'SUBMISSION.CONTACTS.CONTACT.inform_on_error'} = 'aldente@bcgsc.ca'; 
$static_data{'SUBMISSION.FILES.FILE.checksum_method'} = 'MD5';
$static_data{'SUBMISSION.ACTIONS.ACTION'} = 'ADD'; # static
$static_data{'SUBMISSION.ACTIONS.ACTION.ADD.schema'} = 'run'; # static

$hash{schema} = $schema;
$hash{template} = $template;
$hash{field} = \@fields;
$hash{required_field} = \@required_fields;
$hash{TAG} = \%TAGs;
$hash{Alia} = \%Alias;
$hash{custom_config} = \%custom_configs;
$hash{static_data} = \%static_data;
$hash{user_input} = \@user_input;
$hash{function_input} = \@function_input;

YAML::DumpFile( $config_path . 'submission_add_run_config.yml', \%hash );

## the following command commentted out because the submission_template.xml should be copied over already in create_submission_config()
#try_system_command(-command=>"cp $source_template $template");
}
=cut

=begin
sub create_submission_action_add_config {
	my $self = shift;
	my $name = $self->{name};
	my $config_path = $self->{config_path};
	my $source_xml_template_path = $self->{source_xml_template_path};

my %hash;

my    	$template = $config_path . 'submission_action_add_template.xml';
my		$source_template = 	"";
my    	@fields;
my		@required_fields;
my		%TAGs;
my		%Alias;
my		%custom_configs;
my   	%static_data;
my 		@user_input;
my		@function_input;


push @function_input, (
	'submission_add_source',
	'submission_add_schema',
);

## alias from XML Tag names -> LIMS alias names 
#$Alias{'SUBMISSION.ACTIONS.ACTION'} = 'submission_add'; # function input
$Alias{'SUBMISSION.ACTIONS.ACTION.ADD.source'} = 'submission_add_source'; # function input
$Alias{'SUBMISSION.ACTIONS.ACTION.ADD.schema'} = 'submission_add_schema'; # function input

$hash{template} = $template;
$hash{field} = \@fields;
$hash{required_field} = \@required_fields;
$hash{TAG} = \%TAGs;
$hash{Alia} = \%Alias;
$hash{custom_config} = \%custom_configs;
$hash{static_data} = \%static_data;
$hash{user_input} = \@user_input;
$hash{function_input} = \@function_input;

YAML::DumpFile( $config_path . 'submission_action_add_config.yml', \%hash );
try_system_command(-command=>"cp $source_template $template");
}
=cut

###################################
# Generate experiment configurations for MeDIP_Seq experiment type
#
# Return: hash ref
###################################
sub set_MeDIP_seq_config {
#################
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields, ( 'Sonicator_Type', 'sonication_time_min', "Starting_DNA_Amount_ug", 'Bead_Type', "Bead_Amount_ul", 'Antibody_Name', 'Antibody_Provider', 'Antibody_Catalog', 'Antibody_Lot', 'anatomic_site_name', 'anatomic_site' );
    push @required_fields, @fields;

    ## the following two fields do not need to add to @required_fields
    push @fields, ( 'Antibody_amount_ug', 'Antibody_amount_ul', );

    push @function_input, (

        #"submission_concat('MeDIP-Seq',' ',tissue,' ',anatomic_site_name) AS EXPERIMENT_TITLE",
        "submission_concat('MeDIP-Seq',' ',anatomic_site) AS EXPERIMENT_TITLE",

        #"submission_concat('MeDIP-Seq ',Antibody_Name,' ',tissue) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat('MeDIP-Seq ',Antibody_Name,' ',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat(Upstream_Lab,' MeDIP Protocol') AS Upstream_Lab_Protocol",
        "get_best_unit(sonication_time_min,'min') AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
        "get_best_unit(Starting_DNA_Amount_ug,'ug') AS CHROMATIN_AMOUNT",
        "get_best_unit(Bead_Amount_ul,'ul') AS BEAD_AMOUNT",
        "get_antibody_amount(Antibody_amount_ug,'ug',Antibody_amount_ul,'ul') AS Antibody_Amount",
    );
    push @required_fields, @function_input if ( $target =~ /EDACC/i );

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );
    #push @use_NA_if_null, ('Antibody_Amount') if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags,
        (
        'EXTRACTION_PROTOCOL',        'EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR', 'EXTRACTION_PROTOCOL_SONICATION_CYCLES', 'MeDIP_PROTOCOL',          'MeDIP_PROTOCOL_DNA_AMOUNT', 'MeDIP_PROTOCOL_BEAD_TYPE',
        'MeDIP_PROTOCOL_BEAD_AMOUNT', 'MeDIP_PROTOCOL_ANTIBODY_AMOUNT',        'MeDIP_ANTIBODY',                        'MeDIP_ANTIBODY_PROVIDER', 'MeDIP_ANTIBODY_CATALOG',    'MeDIP_ANTIBODY_LOT',
        );
    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                                           = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                                             = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                                          = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}                              = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL'}                   = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR'} = 'Sonicator_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_SONICATION_CYCLES'} = 'EXTRACTION_PROTOCOL_SONICATION_CYCLES';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_PROTOCOL'}                        = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_PROTOCOL_DNA_AMOUNT'}             = 'CHROMATIN_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_PROTOCOL_BEAD_TYPE'}              = 'Bead_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_PROTOCOL_BEAD_AMOUNT'}            = 'BEAD_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_PROTOCOL_ANTIBODY_AMOUNT'}        = 'Antibody_Amount';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_ANTIBODY'}                        = 'Antibody_Name';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_ANTIBODY_PROVIDER'}               = 'Antibody_Provider';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_ANTIBODY_CATALOG'}                = 'Antibody_Catalog';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MeDIP_ANTIBODY_LOT'}                    = 'Antibody_Lot';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                       = '';                                        # static

    ## target based configs
    if ( $target =~ /EDACC/i ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                     = 'MeDIP-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                       = 'GENOMIC';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                    = '5-methylcytidine antibody';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'DNA Methylation';
    }
    elsif ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = '';                                                         # static

        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                     = 'MeDIP-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                       = 'GENOMIC';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                    = 'other';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'DNA Methylation';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for MRE_Seq experiment type
#
# Return: hash ref
###################################
sub set_MRE_seq_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields, ( "Starting_DNA_Amount_ug", 'Restriction_Enzyme_Site', "Library_size_distribution_bp", "flowcell_code", "lane", 'anatomic_site', 'anatomic_site_name' );

    #			'Library_Upper_Protocol',
    #			"CASE WHEN LENGTH(Size_fraction_used_bp) > 0 THEN CONCAT( Size_fraction_used_bp, ' bp' ) END AS MRE_PROTOCOL_SIZE_FRACTION",
    push @function_input, (
        "submission_concat('MRE-Seq',' ',anatomic_site) AS EXPERIMENT_TITLE",
        "submission_concat('MRE-Seq_',Restriction_Enzyme_Site,'_',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat(Upstream_Lab,' MRE Protocol') AS Upstream_Lab_Protocol",

        #
        # Regarding MRE_PROTOCOL_SIZE_FRACTION, from JIRA tick LIMS-5023
        # Perhaps a better size fraction tracking would be the attribute called "Library_size_distribution_bp", a read out from Agilent DNA chip, reflecting the actual size range of a library, just have to minus the adapter bp.
        # The adapter size given by Angela is 119 bp
        "get_size_fraction(flowcell_code,lane,Library_size_distribution_bp,'bp') AS Size_Fraction",
        "get_best_unit(Starting_DNA_Amount_ug,'ug') AS CHROMATIN_AMOUNT",
    );
    push @required_fields, ( @fields, @function_input ) if ( $target =~ /EDACC/i );

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );
    #push @use_NA_if_null, ('CHROMATIN_AMOUNT') if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags, ( 'MRE_PROTOCOL', 'MRE_PROTOCOL_CHROMATIN_AMOUNT', 'MRE_PROTOCOL_RESTRICTION_ENZYME', 'MRE_PROTOCOL_SIZE_FRACTION', );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                                     = '';                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                                       = '';                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                                    = '';                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}                        = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRE_PROTOCOL'}                    = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRE_PROTOCOL_CHROMATIN_AMOUNT'}   = 'CHROMATIN_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRE_PROTOCOL_RESTRICTION_ENZYME'} = 'Restriction_Enzyme_Site';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRE_PROTOCOL_SIZE_FRACTION'}      = 'Size_Fraction';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                 = '';                          # static

    ## static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                       = 'GENOMIC';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'DNA Methylation';

    ## target based configs
    if ( $target =~ /EDACC/i ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = 'MRE-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'Restriction Digest';
    }
    elsif ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = '';    # static

        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = 'MRE-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'other';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for ChIP_Seq experiment type
#
# Return: hash ref
###################################
sub set_ChIP_seq_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields,
        (
        "anatomic_site_name", "CASE WHEN LENGTH(Antibody_Name) > 0 THEN CONCAT( 'Histone ', Antibody_Name ) END AS ChIP_Seq_EXPERIMENT_TYPE",
        'Sonicator_Type', "sonication_time_min", "chromatin_used_ug", 'Bead_Type', "Bead_Amount_ul", 'Antibody_Name', 'Antibody_Provider', 'Antibody_Catalog', 'Antibody_Lot', "Library_size_distribution_bp",
        "flowcell_code", "lane",
        );

    #		"CASE WHEN LENGTH(sonication_time_min) > 0 THEN CONCAT( sonication_time_min, ' min') END AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
    #		"CASE WHEN LENGTH(chromatin_used_ug) > 0 THEN CONCAT( chromatin_used_ug, ' ug' ) END AS CHROMATIN_AMOUNT",
    #		"CASE WHEN LENGTH(Bead_Amount_ul) > 0 THEN CONCAT( Bead_Amount_ul, ' ul' ) END AS BEAD_AMOUNT",
    #		'Extraction_Protocol',
    #		'Library_Upper_Protocol',
    if ( $target =~ /EDACC/i ) { push @required_fields, @fields }

    ## the following two fields do not need to add to @required_fields
    push @fields, ( 'Antibody_amount_ug', 'Antibody_amount_ul', );

    push @function_input,
        (
        "submission_concat(Antibody_Name,' ',anatomic_site_name) AS Experiment_Title",
        "submission_concat('ChIP-Seq ',Antibody_Name,' ',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat(Upstream_Lab,' Protocol') AS Upstream_Lab_Protocol",
        "get_best_unit(sonication_time_min,'min') AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
        "get_best_unit(chromatin_used_ug,'ug') AS CHROMATIN_AMOUNT",
        "get_antibody_amount(Antibody_amount_ug,'ug',Antibody_amount_ul,'ul') AS Antibody_Amount",
        "get_best_unit(Bead_Amount_ul,'ul') AS BEAD_AMOUNT",
        "get_size_fraction(flowcell_code,lane,Library_size_distribution_bp,'bp') AS Size_Fraction",
        );

    if ( $target =~ /EDACC/i ) { push @required_fields, @function_input }
    else {
        push @required_fields, ( 'Antibody_Name', 'ChIP_Seq_EXPERIMENT_TYPE' );
    }

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags, (

        'EXTRACTION_PROTOCOL',
        'EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR',
        'EXTRACTION_PROTOCOL_SONICATION_CYCLES',
        'CHIP_PROTOCOL',
        'CHIP_PROTOCOL_CHROMATIN_AMOUNT',
        'CHIP_PROTOCOL_BEAD_TYPE',
        'CHIP_PROTOCOL_BEAD_AMOUNT',
        'CHIP_PROTOCOL_ANTIBODY_AMOUNT',
        'SIZE_FRACTION',
        'CHIP_ANTIBODY',
        'CHIP_ANTIBODY_PROVIDER',
        'CHIP_ANTIBODY_CATALOG',
        'CHIP_ANTIBODY_LOT',
    );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.TITLE'}                                                   = 'Experiment_Title';        # same as experiment_type
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}              = '';                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                = '';                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}             = '';                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = 'Upstream_Lab_Protocol';

    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL'}                   = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR'} = 'Sonicator_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_SONICATION_CYCLES'} = 'EXTRACTION_PROTOCOL_SONICATION_CYCLES';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL'}                         = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL_CHROMATIN_AMOUNT'}        = 'CHROMATIN_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL_BEAD_TYPE'}               = 'Bead_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL_BEAD_AMOUNT'}             = 'BEAD_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL_ANTIBODY_AMOUNT'}         = 'Antibody_Amount';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.SIZE_FRACTION'}                         = 'Size_Fraction';                           #?
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_ANTIBODY'}                         = 'Antibody_Name';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_ANTIBODY_PROVIDER'}                = 'Antibody_Provider';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_ANTIBODY_CATALOG'}                 = 'Antibody_Catalog';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_ANTIBODY_LOT'}                     = 'Antibody_Lot';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                       = 'ChIP_Seq_EXPERIMENT_TYPE';

    ## static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = 'ChIP-Seq';                                                                     # ChIP-Seq accepted by SRA
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}    = 'GENOMIC';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'ChIP';                                                                         # ChIP accepted by SRA

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for ChIP_Seq_input experiment type
#
# Return: hash ref
###################################
sub set_ChIP_seq_input_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields, ( 'sonication_time_min', 'Sonicator_Type', "chromatin_used_ug", "Library_size_distribution_bp", "flowcell_code", "lane", "anatomic_site_name" );

    #			"CASE WHEN LENGTH(sonication_time_min) > 0 THEN CONCAT( sonication_time_min, ' min') END AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
    #			'Extraction_Protocol',
    push @function_input,
        (
        "get_input_experiment_title(flowcell_code,lane,Library_size_distribution_bp,'bp',anatomic_site_name) AS EXPERIMENT_TITLE",
        "submission_concat('ChIP-Seq Input ',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat(Upstream_Lab,' Protocol') AS Upstream_Lab_Protocol",
        "get_best_unit(chromatin_used_ug,'ug') AS CHROMATIN_AMOUNT",
        "get_best_unit(sonication_time_min,'min') AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
        "get_size_fraction(flowcell_code,lane,Library_size_distribution_bp,'bp') AS Size_Fraction",
        );
    push @required_fields, ( @fields, @function_input ) if ( $target =~ /EDACC/i );

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags, ( 'EXTRACTION_PROTOCOL', 'EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR', 'EXTRACTION_PROTOCOL_SONICATION_CYCLES', 'CHIP_PROTOCOL', 'CHIP_PROTOCOL_CHROMATIN_AMOUNT', 'SIZE_FRACTION', );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                                           = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                                             = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                                          = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}                              = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL'}                   = 'Upstream_Lab_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR'} = 'Sonicator_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_SONICATION_CYCLES'} = 'EXTRACTION_PROTOCOL_SONICATION_CYCLES';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL'}                         = '';                                        # static for this template
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL_CHROMATIN_AMOUNT'}        = 'CHROMATIN_AMOUNT';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.SIZE_FRACTION'}                         = 'Size_Fraction';                           #?
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                       = '';                                        # static

    ## static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                     = 'ChIP-Seq';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                       = 'GENOMIC';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                    = 'RANDOM';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'ChIP-Seq Input';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.CHIP_PROTOCOL'}   = 'Input';

    ## target based configs
    if ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'}     = '';                                                     # static
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = 'ChIP-Seq Input';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for Bisulfite_Seq experiment type
#
# Return: hash ref
###################################
sub set_Bisulfite_seq_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields,
        (
        'Library_Selection', 'Extraction_Protocol', 'Sonicator_Type', "CASE WHEN LENGTH(sonication_time_min) > 0 THEN CONCAT( sonication_time_min, ' min') END AS EXTRACTION_PROTOCOL_SONICATION_CYCLES",
        'size_fraction_used', 'Library_size_distribution_bp',
        'Library_Upper_Protocol', 'PCR_cycle',
        );
    push @function_input, ( "submission_concat('Bisulfite-Seq_',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION", );
    push @required_fields, ( @fields, @function_input ) if ( $target =~ /EDACC/i );
    push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags,
        (
        'EXTRACTION_PROTOCOL',                          'EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR', 'EXTRACTION_PROTOCOL_SONICATION_CYCLES',     'DNA_PREPARATION_INITIAL_DNA_QNTY',
        'DNA_PREPARATION_FRAGMENT_SIZE_RANGE',          'DNA_PREPARATION_ADAPTOR_SEQUENCE',      'DNA_PREPARATION_ADAPTOR_LIGATION_PROTOCOL', 'DNA_PREPARATION_POST-LIGATION_FRAGMENT_SIZE_SELECTION',
        'BISULFITE_CONVERSION_PROTOCOL',                'BISULFITE_CONVERSION_PERCENT',          'LIBRARY_GENERATION_PCR_TEMPLATE_CONC',      'LIBRARY_GENERATION_PCR_POLYMERASE_TYPE',
        'LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM', 'LIBRARY_GENERATION_PCR_NUMBER_CYCLES',  'LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE',  'LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE',
        'LIBRARY_GENERATION_PCR_PRIMER_CONC',           'LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL',
        );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                                                           = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                                                             = '';                                        # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                                                          = 'Library_Selection';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL'}                                   = 'Extraction_Protocol';                     # actually not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_TYPE_OF_SONICATOR'}                 = 'Sonicator_Type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_SONICATION_CYCLES'}                 = 'EXTRACTION_PROTOCOL_SONICATION_CYCLES';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.DNA_PREPARATION_INITIAL_DNA_QNTY'}                      = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.DNA_PREPARATION_FRAGMENT_SIZE_RANGE'}                   = 'size_fraction_used';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.DNA_PREPARATION_ADAPTOR_SEQUENCE'}                      = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.DNA_PREPARATION_ADAPTOR_LIGATION_PROTOCOL'}             = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.DNA_PREPARATION_POST-LIGATION_FRAGMENT_SIZE_SELECTION'} = 'Library_size_distribution_bp';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.BISULFITE_CONVERSION_PROTOCOL'}                         = 'Library_Upper_Protocol';                  # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.BISULFITE_CONVERSION_PERCENT'}                          = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE_CONC'}                  = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE'}                = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM'}          = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES'}                  = 'PCR_cycle';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE'}              = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE'}              = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC'}                    = '';                                        # not tracked
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL'}     = '';                                        # not tracked

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                     = 'Bisulfite-Seq';                                                             # Bisulfite-Seq accepted by SRA
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                       = 'GENOMIC';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'DNA Methylation';

    ## target based configs
    #if( $target =~ /EDACC/i ) {
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = ''; # "RANDOM" or "Reduced Representation"
    #}

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for mRNA_Seq experiment type
#
# Return: hash ref
###################################
sub set_mRNA_seq_config {
    my $self             = shift;
    my %args             = &filter_input( \@_, -args => 'use_default_tags' );
    my $target           = $self->{target};
    my $use_default_tags = $args{-use_default_tags};
    $use_default_tags = 1 if ( !defined $use_default_tags );
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    if ($use_default_tags) {
        push @fields,
            (
            "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'Miltenyi-Biotec MACS mRNA purification' ELSE 'NA' END AS mRNA_Seq_EXTRACTION_PROTOCOL_RNA_ENRICHMENT",
            "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'NNNNNN' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE",
            "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'Invitrogen Superscript II RT' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL",
            "PCR_cycle",
            "CONCAT( 'RI', 'N ', RIN ) AS RNA_PREPARATION_INITIAL_RNA_QLTY",
            'anatomic_site',
            'anatomic_site_name',
            "flowcell_code",
            "lane",
            "Library_size_distribution_bp",
            "Starting_RNA_amount_ng",
            "plate_id",
            );

        #			'Extraction_Protocol',
        #			"LIB_GEN_PCR_F_PRIMER_SEQUENCE",
        #			"LIB_GEN_PCR_R_PRIMER_SEQUENCE",
    }
    push @function_input, (

        #"submission_concat('RNA-Seq',' ',tissue) AS EXPERIMENT_TITLE",
        #"get_mRNA_Seq_experiment_title(plate_ids,tissue,anatomic_site_name) AS EXPERIMENT_TITLE",
        "get_mRNA_Seq_experiment_title(plate_ids,anatomic_site) AS EXPERIMENT_TITLE",

        #"get_mRNA_Seq_experiment_description(plate_ids,tissue) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "get_mRNA_Seq_experiment_description(plate_ids,anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION",
        "submission_concat(Upstream_Lab,' Protocol') AS Upstream_Lab_Protocol",
        "get_size_fraction(flowcell_code,lane,Library_size_distribution_bp,'bp') AS Size_Fraction",
        "get_best_unit(Starting_RNA_amount_ng,'ng') AS RNA_PREPARATION_INITIAL_RNA_QNTY",
        "get_PCR_primer_sequence(plate_id,'PE Primer 1.0') AS PCR_F_Primer_Sequence",
        "get_PCR_primer_sequence(plate_id,'PE Primer 2.0') AS PCR_R_Primer_Sequence",
    );
    push @required_fields, ( @fields, @function_input ) if ( $target =~ /EDACC/i );

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );

    ## TAGs
    if ($use_default_tags) {
        push @tags, ('EXPERIMENT_TYPE');
        push @tags,
            (
            "EXTRACTION_PROTOCOL",                                   "EXTRACTION_PROTOCOL_MRNA_ENRICHMENT",            "RNA_PREPARATION_INITIAL_RNA_QLTY",             "RNA_PREPARATION_INITIAL_RNA_QNTY",
            "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE", "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL", "LIBRARY_GENERATION_PCR_TEMPLATE",              "LIBRARY_FRAGMENTATION",
            "LIBRARY_FRAGMENT_SIZE_RANGE",                           "LIBRARY_GENERATION_PCR_POLYMERASE_TYPE",         "LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM", "LIBRARY_GENERATION_PCR_NUMBER_CYCLES",
            "LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE",              "LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE",       "LIBRARY_GENERATION_PCR_PRIMER_CONC",           "LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL",
            );

        ## the following were removed on Sep 7, 2010
        #	"EXTRACTION_PROTOCOL_FRAGMENTATION",
        #	"MRNA_PREPARATION_INITIAL_MRNA_QNTY",
        #	"MRNA_PREPARATION_FRAGMENT_SIZE_RANGE",
        #	"RNA_PREPARATION_5'_RNA_ADAPTER_SEQUENCE",
        #	"RNA_PREPARATION_3'_RNA_ADAPTER_SEQUENCE",
        #	"RNA_PREPARATION_5'_DEPHOSPHORYLATION",
        #	"RNA_PREPARATION_5'_PHOSPHORYLATION",
        #	"RNA_PREPARATION_3'_RNA_ADAPTER_LIGATION_PROTOCOL",
        #	"RNA_PREPARATION_5'_RNA_ADAPTER_LIGATION_PROTOCOL",

    }

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}              = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}             = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = '';    # static
    if ($use_default_tags) {
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL"}                                   = 'Upstream_Lab_Protocol';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_MRNA_ENRICHMENT"}                   = 'mRNA_Seq_EXTRACTION_PROTOCOL_RNA_ENRICHMENT';                      #
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_RNA_QLTY"}                      = 'RNA_PREPARATION_INITIAL_RNA_QLTY';                                 # RIN <INSERT RIN NUMBER>
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_RNA_QNTY"}                      = 'RNA_PREPARATION_INITIAL_RNA_QNTY';                                 #
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE"} = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL"}        = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"}              = '';                 # static                                                                # static
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}                        = '';                 # static                                                                #  ?
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"}                  = 'Size_Fraction';    # ?
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"}       = '';                 # static                                                                # static
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '';                 # static                                                                # static
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES"}         = 'PCR_cycle';        # plate attribute
             #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = 'LIB_GEN_PCR_F_PRIMER_SEQUENCE';
             #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = 'LIB_GEN_PCR_R_PRIMER_SEQUENCE';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"}          = 'PCR_F_Primer_Sequence';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"}          = 'PCR_R_Primer_Sequence';
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '';                        # static
        $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '';                        # static

        ## removed on Sep 7, 2010
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_FRAGMENTATION"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRNA_PREPARATION_INITIAL_MRNA_QNTY"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRNA_PREPARATION_FRAGMENT_SIZE_RANGE"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_SEQUENCE"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_SEQUENCE"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_DEPHOSPHORYLATION"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_PHOSPHORYLATION"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_LIGATION_PROTOCOL"} = ''; # not applicable, static 'NA'
        #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_LIGATION_PROTOCOL"} = ''; # not applicable, static 'NA'

    }

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'cDNA';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}
        = 'PolyA+ RNA was purified using the MACS mRNA isolation kit (Miltenyi Biotec, Bergisch Gladbach, Germany), from 2-10ug of DNaseI-treated total RNA as per the manufacturer’s instructions. Double-stranded cDNA was synthesized from the purified polyA+ RNA using the Superscript Double-Stranded cDNA Synthesis kit (Invitrogen, Carlsbad, CA, USA) and random hexamer primers (Invitrogen) at a concentration of 5µM. The cDNA was fragmented by sonication and a paired-end sequencing library prepared following the Illumina paired-end library preparation protocol (Illumina, Hayward, CA, USA).';
    if ($use_default_tags) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                        = 'mRNA-Seq';
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"}        = 'cDNA';
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}                  = 'COVARIS E210';
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"} = 'Phusion';

#$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '98°C 30 sec, 10 cycle of 98°C 10 sec, 65°C 30 sec, 72°C 30 sec, then 72°C 5 min, 4°C forever'; # disabled on Sep 7, 2010
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"}      = '98C 30 sec, 10 cycle of 98C 10 sec, 65C 30 sec, 72C 30 sec, then 72C 5 min, 4C hold';
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '0.5uM';
        $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '8% Novex TBE PAGE gel purification';

        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL"} = 'Invitrogen Trizol RNA extraction'; # static temporarily for 20100224 EDACC submission
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = "5' AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT";       # static temporarily
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = "5' CAAGCAGAAGACGGCATACGAGATCGGTCTCGGCATTCCTGCTGAACCGCTCTTCCGATCT";    # static temporarily

        ## removed on Sep 7, 2010
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_FRAGMENTATION"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRNA_PREPARATION_INITIAL_MRNA_QNTY"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.MRNA_PREPARATION_FRAGMENT_SIZE_RANGE"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_SEQUENCE"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_SEQUENCE"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_DEPHOSPHORYLATION"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_PHOSPHORYLATION"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_LIGATION_PROTOCOL"} = 'NA'; # not applicable, static 'NA'
        #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_LIGATION_PROTOCOL"} = 'NA'; # not applicable, static 'NA'

    }
    ## target based configs
    if ( $target =~ /EDACC/i ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'mRNA-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}   = 'RNA';
    }
    elsif ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = '';    # static

        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                      = 'RNA-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                        = 'TRANSCRIPTOMIC';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = 'mRNA-Seq';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for smRNA_Seq experiment type
#
# Return: hash ref
###################################
sub set_smRNA_seq_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @fields,
        (
        "EXTRACTION_PROTOCOL_SMRNA_ENRICHMENT",   "CASE WHEN LENGTH(Starting_RNA_amount_ng) > 0 THEN CONCAT( Starting_RNA_amount_ng, ' ng') END AS SMRNA_PREPARATION_INITIAL_SMRNA_QNTY",
        "RNA_PREPARATION_5_RNA_ADAPTER_SEQUENCE", "RNA_PREPARATION_3_RNA_ADAPTER_SEQUENCE",
        "RNA_PREP_REV_TRANSCRIPTION_PRIMER_SEQ",  "RNA_PREP_3_RNA_ADAPTER_LIG_PROTOCOL",
        "RNA_PREP_5_RNA_ADAPTER_LIG_PROTOCOL",    "RNA_PREP_REV_TRANSCRIPTION_PROTOCOL",
        "LIBRARY_GENERATION_PCR_TEMPLATE",        "LIBRARY_GENERATION_PCR_POLYMERASE_TYPE",
        "LIB_GEN_PCR_THERMOCYCLING_PROGRAM",      "PCR_cycle",
        "LIB_GEN_PCR_F_PRIMER_SEQUENCE",          "LIB_GEN_PCR_R_PRIMER_SEQUENCE",
        "LIBRARY_GENERATION_PCR_PRIMER_CONC",     "LIB_GEN_PCR_PRODUCT_ISOLATION_PROTOCOL",
        );

    #			"Extraction_Protocol",
    push @function_input,
        ( "submission_concat('smRNA-Seq',' analysis of ', library) AS EXPERIMENT_TITLE", "submission_concat('smRNA-Seq_',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION", "submission_concat(Upstream_Lab,' smRNA Protocol') AS Upstream_Lab_Protocol", );
    push @required_fields, ( @fields, @function_input ) if ( $target =~ /EDACC/i );

    #push @use_NA_if_null, @fields if ( $target =~ /EDACC/i );

    ## TAGs
    push @tags,
        (
        "EXTRACTION_PROTOCOL",                            "EXTRACTION_PROTOCOL_SMRNA_ENRICHMENT",                  "SMRNA_PREPARATION_INITIAL_SMRNA_QNTY",             "RNA_PREPARATION_5'_RNA_ADAPTER_SEQUENCE",
        "RNA_PREPARATION_3'_RNA_ADAPTER_SEQUENCE",        "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE", "RNA_PREPARATION_3'_RNA_ADAPTER_LIGATION_PROTOCOL", "RNA_PREPARATION_5'_RNA_ADAPTER_LIGATION_PROTOCOL",
        "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL", "LIBRARY_GENERATION_PCR_TEMPLATE",                       "LIBRARY_GENERATION_PCR_POLYMERASE_TYPE",           "LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM",
        "LIBRARY_GENERATION_PCR_NUMBER_CYCLES",           "LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE",              "LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE",         "LIBRARY_GENERATION_PCR_PRIMER_CONC",
        "LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL",
        );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                                                           = '';                                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                                                             = '';                                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                                                          = '';                                          # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}                                              = 'Upstream_Lab_Protocol';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL"}                                   = 'Upstream_Lab_Protocol';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_SMRNA_ENRICHMENT"}                  = 'EXTRACTION_PROTOCOL_SMRNA_ENRICHMENT';      # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.SMRNA_PREPARATION_INITIAL_SMRNA_QNTY"}                  = 'SMRNA_PREPARATION_INITIAL_SMRNA_QNTY';      # plate attribute Starting_RNA_amount_ng
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_SEQUENCE"}               = 'RNA_PREPARATION_5_RNA_ADAPTER_SEQUENCE';    # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_SEQUENCE"}               = 'RNA_PREPARATION_3_RNA_ADAPTER_SEQUENCE';    # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE"} = 'RNA_PREP_REV_TRANSCRIPTION_PRIMER_SEQ';     # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_3'_RNA_ADAPTER_LIGATION_PROTOCOL"}      = 'RNA_PREP_3_RNA_ADAPTER_LIG_PROTOCOL';       # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_5'_RNA_ADAPTER_LIGATION_PROTOCOL"}      = 'RNA_PREP_5_RNA_ADAPTER_LIG_PROTOCOL';       # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL"}        = 'RNA_PREP_REV_TRANSCRIPTION_PROTOCOL';       # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"}                       = 'LIBRARY_GENERATION_PCR_TEMPLATE';           # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"}                = 'LIBRARY_GENERATION_PCR_POLYMERASE_TYPE';    # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"}          = 'LIB_GEN_PCR_THERMOCYCLING_PROGRAM';         # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES"}                  = 'PCR_cycle';                                 # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = 'LIB_GEN_PCR_F_PRIMER_SEQUENCE';         # plate attribute, Stock_Catalog_Description, not sure how to get this yet
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = 'LIB_GEN_PCR_R_PRIMER_SEQUENCE';         # plate attribute, Stock_Catalog_Description, not sure how to get this yet
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}       = 'LIBRARY_GENERATION_PCR_PRIMER_CONC';    # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = 'LIB_GEN_PCR_PRODUCT_ISOLATION_PROTOCOL';    # plate attribute

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'}                    = 'cDNA';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = 'smRNA-Seq';

    ## target based configs
    if ( $target =~ /EDACC/i ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'smRNA-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}   = 'RNA';
    }
    elsif ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = '';                                                                       # static

        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}                      = 'OTHER';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}                        = 'TRANSCRIPTOMIC';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = 'smRNA-Seq';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for RNASeq experiment type
#
# Return: hash ref
###################################
sub set_RNA_seq_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @function_input, ( "submission_concat('RNA-Seq',' analysis of ', library) AS EXPERIMENT_TITLE", "submission_concat('RNA-Seq_',anatomic_site) AS EXPERIMENT_DESIGN_DESCRIPTION", );
    push @required_fields, @function_input if ( $target =~ /EDACC/i );

    ## TAGs

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}    = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = '';    # static

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'cDNA';

    ## target based configs
    if ( $target =~ /NCBI/i ) {
        push @tags, ("LIBRARY_STRATEGY");
        $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_STRATEGY'} = '';    # static

        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'RNA-Seq';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}   = 'TRANSCRIPTOMIC';
    }

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Generate experiment configurations for WTSS experiment type
#
# Return: hash ref
###################################
sub set_WTSS_config {
    my $self   = shift;
    my $target = $self->{target};
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    ## fields, function_input, user_input, required fields, use_NA_if_null
    push @function_input, ( "submission_concat('WTSS',' analysis of ', library) AS EXPERIMENT_TITLE", );
    push @required_fields, @function_input if ( $target =~ /EDACC/i );

    ## TAGs

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}    = '';    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = '';    # static

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'cDNA';

    ## target based configs
    if ( $target =~ /NCBI/i ) {
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'} = 'AMPLICON';
        $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}   = 'NON GENOMIC';
    }

    $return{'source_template'} = "experiment_template_no_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

##########################
# Set the common EDACC config
#
# Return: Hash ref
###############################
sub set_common_edacc_config {
############################
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @user_input      = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases         = ();
    my %static_data     = ();

    ## fields, function_input, user_input, required fields, use_NA_if_null
    ## TAGs
    ## aliases
    ## target based configs
    push @required_fields, (
        "`EXPERIMENT_SET.EXPERIMENT.alias`",
        "study", "library",
        "runs", "solexarun_type", "Sequence_Space",

        #"`EXPERIMENT_SET.EXPERIMENT.expected_number_reads`",
        #"`EXPERIMENT_SET.EXPERIMENT.expected_number_spots`",
        'Library_Strategy',
    );

    #            "Lib_Construction_Protocol",
    #    push @use_NA_if_null, 'Lib_Construction_Protocol';

    push @tags, ('EXPERIMENT_TYPE');

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'EXPERIMENT_DESIGN_DESCRIPTION';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'} = '';    # static

    $return{'source_template'} = "experiment_template_with_attribute.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

#################################
# Set the common experiment config. This should apply to all templates
#
# Return: Hash ref
##################################
sub set_common_experiment_config {
##################################
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'config_path', -mandatory => 'config_path' );
    my $config_path     = $args{-config_path};
    my @fields          = ();
    my @function_input  = ();
    my @user_input      = ();
    my @required_fields = ();
    my @use_NA_if_null  = ();
    my @tags            = ();
    my %aliases         = ();
    my %static_data     = ();
    my %custom_configs  = ();

    my @template_header = ('EXPERIMENT_SET');
    my $schema          = "http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.experiment.xsd";
    my $template        = $config_path . 'experiment_template.xml';

    ## custom configs
    $custom_configs{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT'} = {
        'Single' => $config_path . 'experiment_lib_layout_single_config.yml',
        'Paired' => $config_path . 'experiment_lib_layout_paired_config.yml',
    };
    $custom_configs{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC'} = {
        'Single' => $config_path . 'experiment_spot_decode_spec_single_config.yml',
        'Paired' => $config_path . 'experiment_spot_decode_spec_paired_config.yml',
    };

    $custom_configs{'EXPERIMENT_SET.EXPERIMENT.PLATFORM'} = {
        'ILLUMINA'  => $config_path . 'experiment_platform_illumina_config.yml',
        'ABI_SOLID' => $config_path . 'experiment_platform_solid_config.yml',
        'LS454'     => $config_path . 'experiment_platform_LS454_config.yml',
    };

    ## common fields for all templates
    push @fields, (
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END AS `EXPERIMENT_SET.EXPERIMENT.alias`",

#"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN CONCAT( Sample.Sample_Name, '_', Flowcell.Flowcell_Code ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN CONCAT( Sample.Sample_Name, '_', 'SOLID specific container id' ) END AS `EXPERIMENT_SET.EXPERIMENT.alias`",
        'study',
        "library",
        "CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN ('ILLUMINA') WHEN (Equipment_Category.Sub_Category = 'Solid') THEN ('ABI_SOLID') ELSE ('unspecified') END AS submission_experiment_platform",
        'runs',
        'Lib_Construction_Protocol',
        'solexarun_type',
        'Sequence_Space',

        #"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer') THEN SUM( Solexa_Read.Number_Reads ) WHEN (Equipment_Category.Sub_Category = 'Solid') THEN 'not defined' END AS `EXPERIMENT_SET.EXPERIMENT.expected_number_reads`",
        #"CASE WHEN (Equipment_Category.Sub_Category ='Genome Analyzer' && solexarun_type = 'Single' ) THEN SUM( Solexa_Read.Number_Reads ) "
        #    . " WHEN (Equipment_Category.Sub_Category ='Genome Analyzer' && solexarun_type = 'Paired' ) THEN FLOOR(SUM( Solexa_Read.Number_Reads )/2) "
        #    . " WHEN (Equipment_Category.Sub_Category = 'Solid' ) THEN 'not defined' END "
        #    . " AS `EXPERIMENT_SET.EXPERIMENT.expected_number_spots`",
        "pipeline_name",
        'Library_Strategy',
        'anatomic_site',
        'library_description',
        'Data_Submission_Library_Source',
        'Library_Selection',
        "CONCAT( SUBSTRING(contact,INSTR(contact,' ')+1 ), ' Lab' ) AS Upstream_Lab",

        #"GROUP_CONCAT(distinct plate_id) AS plate_ids",
    );

    push @function_input,
        (
        "submission_concat(Library_Strategy,' analysis of ', library) AS EXPERIMENT_TITLE",
        "get_program(pipeline_name, 'RTA') AS BASE_CALLER",
        "get_version(pipeline_name,'RTA') AS VERSION",
        "submission_concat(library_description,'') AS EXPERIMENT_DESIGN_DESCRIPTION",
        );
    push @user_input, ('STUDY_refname');
    push @required_fields, ( "`EXPERIMENT_SET.EXPERIMENT.alias`", 'study', 'library', 'runs', 'Library_Strategy', );

    ## alias from XML Tag names -> LIMS alias names
    $aliases{'EXPERIMENT_SET.xmlns:xsi'}                       = '';                                     # static data
    $aliases{'EXPERIMENT_SET.xsi:noNamespaceSchemaLocation'}   = '';                                     # static data
    $aliases{'EXPERIMENT_SET.EXPERIMENT.alias'}                = "`EXPERIMENT_SET.EXPERIMENT.alias`";    #'submission_experiment_alias';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.expected_number_runs'} = 'runs';

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.expected_number_reads'} = "`EXPERIMENT_SET.EXPERIMENT.expected_number_reads`";    # 'submission_run_total_reads'; #
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.expected_number_spots'} = "`EXPERIMENT_SET.EXPERIMENT.expected_number_spots`";    #
    $aliases{'EXPERIMENT_SET.EXPERIMENT.center_name'}       = '';                                        # static data
    $aliases{'EXPERIMENT_SET.EXPERIMENT.TITLE'}             = "EXPERIMENT_TITLE";                        # function input
    $aliases{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.refname'} = 'STUDY_refname';

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'library_description';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'}              = 'EXPERIMENT_DESIGN_DESCRIPTION';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'}       = "study";
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_NAME'} = "library";

    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_STRATEGY'}  = "Library_Strategy";
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SOURCE'}    = 'Data_Submission_Library_Source';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_SELECTION'} = 'Library_Selection';

    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.POOLING_STRATEGY'}              = '';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.LIBRARY_LAYOUT'}                = 'solexarun_type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = 'Lib_Construction_Protocol';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SPOT_DESCRIPTOR.SPOT_DECODE_SPEC'}                 = 'solexarun_type';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.PLATFORM'}                                                = "submission_experiment_platform";    # use Stock_Catalog.Model temporary

    $aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.PROGRAM'} = 'BASE_CALLER';
    $aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.VERSION'} = 'VERSION';

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.BASE_CALLS.SEQUENCE_SPACE'}                    = 'Sequence_Space';                    # attribute
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.BASE_CALLS.BASE_CALLER'}                       = 'BASE_CALLER';
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.NUMBER_OF_LEVELS'}              = '';                                  # static
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.MULTIPLIER'}                    = '';                                  # static
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.QUALITY_SCORER'}                = 'QUALITY_SCORER';
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.qtype'}                         = '';                                  # static
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.NUMBER_OF_LEVELS'}              = '';                                  # static
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.MULTIPLIER'}                    = '';                                  # static

    ## static data
    $static_data{'EXPERIMENT_SET.xmlns:xsi'}                     = 'http://www.w3.org/2001/XMLSchema-instance';
    $static_data{'EXPERIMENT_SET.xsi:noNamespaceSchemaLocation'} = 'http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.experiment.xsd';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.center_name'}        = 'BCCAGSC';

    #$static_data{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.QUALITY_SCORES.NUMBER_OF_LEVELS'} = '80';
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.PIPELINE.PIPE_SECTION.MULTIPLIER'}       = '1';
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.qtype'}            = 'phred';
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.NUMBER_OF_LEVELS'} = '80';
    #$static_data{'EXPERIMENT_SET.EXPERIMENT.PROCESSING.QUALITY_SCORES.MULTIPLIER'}       = '1';
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.POOLING_STRATEGY'} = 'none';

    my %return;
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'user_input'}      = \@user_input;
    $return{'use_NA_if_null'}  = \@use_NA_if_null;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;
    $return{'custom_config'}   = \%custom_configs;
    $return{'schema'}          = $schema;
    $return{'template'}        = $template;
    $return{'template_header'} = \@template_header;
    $return{'source_template'} = "experiment_template_no_attribute.xml";

    return \%return;
}

###########################
# Merge the custom configs with the general configs. Override the general config with the custom config if conflict.
#
# Arguments:
#	-general	=> the general config hash ref
#	-custom		=> the custom config hash ref
#
# Return: hash ref
###############################
sub merge_config {
####################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'general,custom', -mandatory => 'general,custom' );
    my $general = $args{-general};
    my $custom  = $args{-custom};

    my %return = %$general;
    foreach my $key ( keys %$custom ) {

        if ( !exists $return{$key} ) {
            $return{$key} = $custom->{$key};
        }
        else {
            my $type = ref $custom->{$key};
            if ( $type eq 'ARRAY' ) {    # union the arrays
                if ( $key eq 'function_input' ) {    # override the same alias
                    foreach my $elem ( @{ $custom->{$key} } ) {
                        if ( $elem =~ /.+\s+AS\s+([\w.`]+){1}\s*$/ ) {
                            my $alias = $1;
                            my $found = 0;
                            for ( my $i = 0; $i < scalar( @{ $return{$key} } ); $i++ ) {
                                my $elem2 = $return{$key}[$i];
                                if ( $elem2 =~ /.+\s+AS\s+([\w.`]+){1}\s*$/ ) {
                                    my $alias2 = $1;
                                    if ( $alias eq $alias2 ) {    # override
                                        $return{$key}[$i] = $elem;
                                        $found++;
                                    }
                                }
                            }
                            push @{ $return{$key} }, $elem if ( !$found );
                        }
                        else {                                    # not in alias format
                            push @{ $return{$key} }, $elem unless ( grep /^$elem$/, @{ $return{$key} } );
                        }
                    }
                }
                else {
                    $return{$key} = &RGmath::union( $return{$key}, $custom->{$key} );
                }
            }
            elsif ( $type eq 'HASH' ) {
                foreach my $key2 ( keys %{ $custom->{$key} } ) {
                    $return{$key}{$key2} = $custom->{$key}{$key2};
                }
            }
            else {
                $return{$key} = $custom->{$key};
            }
        }
    }
    return \%return;
}

sub set_NCBI_RNAseq_TCGA_exp_config {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @fields,
        (
        "Study_Description",
        "original_source_name",
        "CASE WHEN original_source_name like 'AML%' THEN 'AML_RNA-Seq' ELSE CONCAT(original_source_name, '_RNA-Seq') END AS EXPERIMENT_DESIGN_DESCRIPTION",
        "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'Miltenyi-Biotec MultiMACS mRNA purification' ELSE 'NA' END AS mRNA_Seq_EXTRACTION_PROTOCOL_RNA_ENRICHMENT",
        "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'NNNNNN' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE",
        "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'Invitrogen Superscript II RT' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL",
        "flowcell_code",
        "lane",
        "RIN",
        "CONCAT( 'RI', 'N ', RIN ) AS RNA_PREPARATION_INITIAL_RNA_QLTY",
        "Library_size_distribution_bp",
        "PCR_cycle",
        );

    #			"PCR_cycle", # not entered in database, but static 15 for TCGA project

    #"RNA_PREPARATION_INITIAL_RNA_QLTY",

    push @function_input, ( "get_library_index(flowcell_code,lane) AS LIBRARY_INDEX", "get_size_fraction(flowcell_code,lane,Library_size_distribution_bp,'bp') AS Size_Fraction", );

    push @required_fields, ( "Study_Description", "RIN", "LIBRARY_INDEX" );

    #push @required_fields, ( @fields, @function_input );

    ## TAGs
    #push @tags, ('EXPERIMENT_TYPE');
    #push @tags,
    #   (
    #   "EXTRACTION_PROTOCOL_MRNA_ENRICHMENT",            "RNA_PREPARATION_INITIAL_RNA_QLTY",             "RNA_PREPARATION_INITIAL_MRNA_QNTY",    "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE",
    #   "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL", "LIBRARY_GENERATION_PCR_TEMPLATE",              "LIBRARY_FRAGMENTATION",                "LIBRARY_FRAGMENT_SIZE_RANGE",
    #   "LIBRARY_GENERATION_PCR_POLYMERASE_TYPE",         "LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM", "LIBRARY_GENERATION_PCR_NUMBER_CYCLES", "LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE",
    #   "LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE",       "LIBRARY_INDEX",                                "LIBRARY_GENERATION_PCR_PRIMER_CONC",   "LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL",
    #  );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'} = '';    # static
                                                                       #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.accession'} = "Study_Attr3";

    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'} = "Study_Description";

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = ""; # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = '';    # static

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_MRNA_ENRICHMENT"}                   = 'mRNA_Seq_EXTRACTION_PROTOCOL_RNA_ENRICHMENT';                      #
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_RNA_QLTY"}                      = 'RNA_PREPARATION_INITIAL_RNA_QLTY';                                 # RIN <INSERT RIN NUMBER>
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_MRNA_QNTY"}                     = '';                                                                 # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE"} = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE';

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL"} = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"}                = '';                                                                        # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}                          = '';                                                                        # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"}                    = 'Size_Fraction';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"}         = '';                                                                        # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"}   = '';                                                                        # static

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES"}     = 'PCR_cycle';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = '';                                                                              # static for the TCGA project
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = '';                                                                              # static for the TCGA project
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_INDEX"}                            = 'LIBRARY_INDEX';                                                                 # <INSERT INDEX STRING HERE>

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '';                                                                     # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '';                                                                     # static

    ## static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'}       = 'SRP000677';    # static
                                                                                          #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = "NCBI";
                                                                                          #$static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = "BCCAGSC Indexed Plate Based mRNA-seq";
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'RNA-Seq';

    #$static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                   = 'mRNA-Seq';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_MRNA_QNTY"} = '2ug';

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"} = 'cDNA';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}           = 'COVARIS E210';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"}            = '100-300bp';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"} = 'Phusion';

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '98C 30 sec, 10 cycle of 98C 10 sec, 65C 30 sec, 72C 30 sec, then 72C 5 min, 4C hold';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '98Â°C 30 sec, 10 cycle of 98Â°C 10 sec, 65Â°C 30 sec, 72Â°C 30 sec, then 72Â°C 5 min, 4Â°C hold';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES"} = '15';    # static for the TCGA project

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '0.5uM';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '8% Novex TBE PAGE gel purification';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL"} = 'Invitrogen Trizol RNA extraction'; # static temporarily for 20100224 EDACC submission
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = "5' AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT";             # static for the TCGA project
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = "5' CAAGCAGAAGACGGCATACGAGATNNNNNNCGGTCTCGGCATTCCTGCTGAACCGCTCTTCCGATCT";    # static for the TCGA project

    $return{'source_template'} = "experiment_template_with_attribute_TCGA.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

sub set_NCBI_RNAseq_NBL_exp_config {
    my $self = shift;
    my %return;

    my @fields          = ();
    my @required_fields = ();
    my @function_input  = ();
    my @tags            = ();
    my %aliases;
    my %static_data;

    push @fields,
        (
        "study_description",
        "original_source_name",
        "CASE WHEN original_source_name like 'NBL%' THEN 'NBL_RNA-Seq' ELSE CONCAT(original_source_name, '_RNA-Seq') END AS EXPERIMENT_DESIGN_DESCRIPTION",
        'Extraction_Protocol',
        "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'NNNNNN' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE",
        "CASE WHEN Library_Strategy = 'RNA_Seq' THEN 'Invitrogen Superscript II RT' ELSE 'NA' END AS mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL",
        "flowcell_code",
        "lane",
        "CONCAT( 'RI', 'N ', RIN ) AS RNA_PREPARATION_INITIAL_RNA_QLTY",
        "Starting_RNA_amount_ng",
        "PCR_cycle",
        "size_fraction_used",
        );

    #			"CASE WHEN LENGTH(Starting_RNA_amount_ng) > 0 THEN CONCAT( Starting_RNA_amount_ng/1000, 'ug' ) ELSE 'NA' AS RNA_PREPARATION_INITIAL_MRNA_QNTY",

    push @required_fields, ("study_description");
    push @function_input,  ( "convert_units(Starting_RNA_amount_ng,'ng','ug') AS RNA_PREPARATION_INITIAL_MRNA_QNTY", );

    ## TAGs
    push @tags, ('EXPERIMENT_TYPE');
    push @tags,
        (
        "EXTRACTION_PROTOCOL_MRNA_ENRICHMENT",            "RNA_PREPARATION_INITIAL_RNA_QLTY",             "RNA_PREPARATION_INITIAL_MRNA_QNTY",    "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE",
        "RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL", "LIBRARY_GENERATION_PCR_TEMPLATE",              "LIBRARY_FRAGMENTATION",                "LIBRARY_FRAGMENT_SIZE_RANGE",
        "LIBRARY_GENERATION_PCR_POLYMERASE_TYPE",         "LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM", "LIBRARY_GENERATION_PCR_NUMBER_CYCLES", "LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE",
        "LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE",       "LIBRARY_GENERATION_PCR_PRIMER_CONC",           "LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL",
        );

    ## aliases
    $aliases{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'}                = '';                    # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.accession'} = "study_description";

    #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refname'} = "study_description";
    #$aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.SAMPLE_DESCRIPTOR.refcenter'} = ""; # static
    $aliases{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'} = '';    # static

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_MRNA_ENRICHMENT"}                   = '';                                                                 # static for NBL submissions
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_RNA_QLTY"}                      = 'RNA_PREPARATION_INITIAL_RNA_QLTY';                                 # RIN <INSERT RIN NUMBER>
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_INITIAL_MRNA_QNTY"}                     = 'RNA_PREPARATION_INITIAL_MRNA_QNTY';                                # plate attribute Starting_RNA_amount_ng
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE"} = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PRIMER_SEQUENCE';

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL"} = 'mRNA_Seq_RNA_PREPARATION_REVERSE_TRANSCRIPTION_PROTOCOL';
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"}                = '';                                                                        # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}                          = '';                                                                        # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"}                    = 'size_fraction_used';

    #$aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"} = ''; # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"}       = '';                                                                          # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '';                                                                          # static

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_NUMBER_CYCLES"}     = 'PCR_cycle';                                                                     # plate attribute
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = '';                                                                              # static for the NBL submissions
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = '';                                                                              # static for the NBL submissions

    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '';                                                                     # static
    $aliases{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '';                                                                     # static

    ## static data
    $static_data{'EXPERIMENT_SET.EXPERIMENT.STUDY_REF.accession'} = 'phs000218.v1.p1';                                                                                                                               # static
    $static_data{'EXPERIMENT_SET.EXPERIMENT.TITLE'}               = "RNA-seq (polyA+) of a Neuroblastoma tumor sample";

    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.LIBRARY_DESCRIPTOR.Lib_Construction_PROTOCOL'}
        = "PolyA+ RNA was purified using the MACS mRNA isolation kit (Miltenyi Biotec, Bergisch Gladbach, Germany), from 5-10ug of DNaseI-treated total RNA as per the manufacturer’s instructions. Double-stranded cDNA was synthesized from the purified polyA+ RNA using the Superscript Double-Stranded cDNA Synthesis kit (Invitrogen, Carlsbad, CA, USA) and random hexamer primers (Invitrogen) at a concentration of 5µM. The cDNA was fragmented by sonication and a paired-end sequencing library prepared following the Illumina paired-end library preparation protocol (Illumina, Hayward, CA, USA). ";
    $static_data{'EXPERIMENT_SET.EXPERIMENT.DESIGN.DESIGN_DESCRIPTION'} = 'RNAseq polyA+';

    $static_data{'EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXPERIMENT_TYPE'}                     = 'mRNA-Seq';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL_MRNA_ENRICHMENT"} = 'Miltenyi-Biotec MACS mRNA purification';                                         # static for NBL submissions

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_TEMPLATE"} = 'cDNA';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENTATION"}           = 'COVARIS E210';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_FRAGMENT_SIZE_RANGE"} = '100-300bp';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_POLYMERASE_TYPE"} = 'Phusion';

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '98C 30 sec, 10 cycle of 98C 10 sec, 65C 30 sec, 72C 30 sec, then 72C 5 min, 4C hold';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_THERMOCYCLING_PROGRAM"} = '98Â°C 30 sec, 10 cycle of 98Â°C 10 sec, 65Â°C 30 sec, 72Â°C 30 sec, then 72Â°C 5 min, 4Â°C hold';

    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRIMER_CONC"}                = '0.5uM';
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_PRODUCT_ISOLATION_PROTOCOL"} = '8% Novex TBE PAGE gel purification';

    #$static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.EXTRACTION_PROTOCOL"} = 'Invitrogen Trizol RNA extraction'; # static temporarily for 20100224 EDACC submission
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_F_PRIMER_SEQUENCE"} = "5' AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT";       # static for the NBL submissions
    $static_data{"EXPERIMENT_SET.EXPERIMENT.EXPERIMENT_ATTRIBUTES.EXPERIMENT_ATTRIBUTE.TAG.LIBRARY_GENERATION_PCR_R_PRIMER_SEQUENCE"} = "5' CAAGCAGAAGACGGCATACGAGATCGGTCTCGGCATTCCTGCTGAACCGCTCTTCCGATCT";    # static for the NBL submissions

    $return{'source_template'} = "experiment_template_with_attribute_TCGA.xml";
    $return{'fields'}          = \@fields;
    $return{'required_fields'} = \@required_fields;
    $return{'function_input'}  = \@function_input;
    $return{'tags'}            = \@tags;
    $return{'aliases'}         = \%aliases;
    $return{'static_data'}     = \%static_data;

    return \%return;
}

return 1;
