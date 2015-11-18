###################################################################################################################################
# alDente::Validation.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package TCGA::Validation;
use base alDente::Validation;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
use CGI qw(:standard);

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## alDente modules
use alDente::Source;

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self = {};    ## if object is NOT a DB_Object

    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    my ($project_id) = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name = 'TCGA'" );
    my @empty;

    $self->{messages}   = \@empty;
    $self->{project_id} = $project_id;

    return $self;
}

#########################################################################
# Validate TCGA Barcode Also known as Exernal Identifier
#
###########################
sub validate_Barcode {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'barcode' );
    my $barcode = $args{-barcode};
    my $quiet   = $args{-quiet};
    my $dbc     = $self->{dbc};
    my %results;

    my @sources = $dbc->Table_find( 'Source', 'Source_ID', "WHERE External_Identifier = '$barcode'" );
    for my $source (@sources) {
        my $ok = $self->validate_Source( -id => $source );
        $results{$source} = $ok;
    }
    unless ( $quiet && int @{ $self->{messages} } ) {
        for my $message ( @{ $self->{messages} } ) {
            Message $message;
        }
    }

    return \%results;
}

###########################
sub validate_Source {
###########################
    my $self   = shift;
    my $dbc    = $self->{dbc};
    my %args   = filter_input( \@_, -mandatory => 'id' );
    my $id     = $args{-id};
    my $Source = new alDente::Source( -dbc => $dbc, -id => $id );

    ## Simple Test
    my $barcode = $Source->value('Source.External_Identifier');
    if ( $barcode !~ /^TCGA/ ) {
        push @{ $self->{messages} }, "Barcode $barcode is not a TCGA barcode";
        return;
    }

    my $project_ok = $self->validate_Project( -Source          => $Source );
    my $patient_ok = $self->validate_Patient( -Source          => $Source );
    my $tss_ok     = $self->validate_TSS_Code( -Source         => $Source );
    my $plate_ok   = $self->validate_Plate_Identifier( -Source => $Source );

    if ( $project_ok && $patient_ok && $tss_ok && $plate_ok ) {
        push @{ $self->{messages} }, "Source $id Passed Validation";
        return 1;
    }
    else {
        push @{ $self->{messages} }, "Source $id Failed Validation";
        return;
    }
}

###########################
sub validate_Project {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'Source' );
    my $Source  = $args{-Source};
    my $barcode = $Source->value('Source.External_Identifier');
    my $id      = $Source->value('Source.Source_ID');
    my $pr_id   = $Source->value('Source.FKReference_Project__ID');

    if ( $pr_id != $self->{project_id} ) {
        push @{ $self->{messages} }, "Project (ID = $pr_id) is not TCGA for SRC$id";
        return;
    }
    return 1;
}

###########################
sub validate_Patient {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'Source' );
    my $Source  = $args{-Source};
    my $patient = $Source->value('Patient.Patient_Identifier');
    my $barcode = $Source->value('Source.External_Identifier');
    my $id      = $Source->value('Source.Source_ID');

    if ( !$patient ) {
        push @{ $self->{messages} }, "Not Patient Record for SRC$id";
        return;
    }

    if ( $barcode !~ /^$patient/ ) {
        push @{ $self->{messages} }, "Barcode ($barcode) and Patient_Name ($patient) don't match for SRC$id";
        return;
    }
    return 1;
}

###########################
sub validate_Plate_Identifier {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'Source' );
    my $Source  = $args{-Source};
    my $dbc     = $self->{dbc};
    my $barcode = $Source->value('Source.External_Identifier');
    my $id      = $Source->value('Source.Source_ID');

    my $plate_identifier = $self->get_Data_Element( -barcode => $barcode, -element => 'Plate' );
    my ($src_pi) = $dbc->Table_find( 'Attribute, Source_Attribute', "Attribute_Value", " WHERE Attribute_Name = 'Plate_Identifier' and FK_Source__ID = $id and FK_Attribute__ID = Attribute_ID" );
    if ( $src_pi != $plate_identifier || !$src_pi ) {
        push @{ $self->{messages} }, "Plate Identifer for SRC$id ($src_pi) does not match barcode ($plate_identifier)";
        return;
    }
    else {
        return 1;
    }

}

###########################
sub validate_TSS_Code {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'Source' );
    my $Source  = $args{-Source};
    my $dbc     = $self->{dbc};
    my $barcode = $Source->value('Source.External_Identifier');
    my $id      = $Source->value('Source.Source_ID');

    my $tss_code = $self->get_Data_Element( -barcode => $barcode, -element => 'TSS' );
    my %tss_info = $dbc->Table_retrieve( 'Tissue_Source_Site', [ 'FKSupplier_Organization__ID', 'FK_BCR_Study__ID' ], " WHERE Tissue_Source_Site_Code = '$tss_code'" );
    my ($bcr_study) = $dbc->Table_find( 'Attribute, Source_Attribute',            "Attribute_Value",             " WHERE Attribute_Name = 'BCR_Study' and FK_Source__ID = $id and FK_Attribute__ID = Attribute_ID" );
    my ($bcr_org)   = $dbc->Table_find( 'Attribute, Source_Attribute, BCR_Batch', "FKSupplier_Organization__ID", " WHERE Attribute_Name = 'BCR_Batch' and FK_Source__ID = $id and FK_Attribute__ID = Attribute_ID AND Attribute_Value = BCR_Batch_ID" );

    unless ( $bcr_org && $bcr_study ) {
        push @{ $self->{messages} }, "The TSS Code: $tss_code is missing information";
        return;
    }

    if ( !$tss_info{FKSupplier_Organization__ID}[0] || $tss_info{FKSupplier_Organization__ID}[0] != $bcr_org ) {
        push @{ $self->{messages} }, "The TSS Code: $tss_code does not match SRC$id organization [($tss_info{FKSupplier_Organization__ID}[0] <>  $bcr_org  ]";
        return;
    }

    if ( !$tss_info{FK_BCR_Study__ID}[0] || $tss_info{FK_BCR_Study__ID}[0] != $bcr_study ) {
        push @{ $self->{messages} }, "The TSS Code: $tss_code does not match SRC$id BCR_Study [($tss_info{FK_BCR_Study__ID}[0] <>  $bcr_study  ]";
        return;
    }

    return 1;
}

###########################
sub get_Data_Element {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'barcode,element' );
    my $barcode = $args{-barcode};
    my $element = $args{-element};                                        #enum (Project,TSS,Participant,Sample,Vial,Portion,Analyte,Plate,Center)
    my %value;

    if ( $barcode =~ /^(TCGA)\-(..)\-(....)\-(..)(.)\-(..)(.)\-(....)\-(..)$/ ) {
        $value{Project}     = $1;
        $value{TSS}         = $2;
        $value{Participant} = $3;
        $value{Sample}      = $4;
        $value{Vial}        = $5;
        $value{Portion}     = $6;
        $value{Analyte}     = $7;
        $value{Plate}       = $8;
        $value{Center}      = $9;
    }
    else {
        push @{ $self->{messages} }, "Incorrect barcode format: $barcode";
        return;

    }
    return $value{$element};

}

1;
