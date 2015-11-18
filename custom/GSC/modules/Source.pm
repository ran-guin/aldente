#!/usr/bin/perl
###################################################################################################################################
# Source.pm
#
###################################################################################################################################
package GSC::Source;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::Source);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

use Benchmark;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::HTML;

##############################
# global_vars                #
##############################
#use vars qw($dbc $user_id $user);
#use vars qw($MenuSearch $scanner_mode %Settings );
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

### Global variables

### Modular variables

############################
sub Update_labels {
############################
    # Description:
    #    This method replaces 2 fields and an attribute with 3 attributes placed to replace them
    #
    # Input:
    #    Source_IDs (comma deliminated list of source ids)
    #
    # Conditions:
    #     1. replacement attributes should be there
    #     2. Sources should belong to project list 
    #     3. Sample_type should be 'Flow through RNA'
############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc} || $args{-dbc};
    my $ids  = $args{-ids};

    my $sample_type = 'Flow through RNA';

	my $project_list = "'TCGA','NCI_Burkitts','POG'";
	my @project_ids = $dbc -> Table_find ('Project','Project_ID',"WHERE Project_Name IN ($project_list)" );
	my $list = join ',', @project_ids;
	

    $dbc->start_trans( -name => 'GSC_Labels' );

    ## Replacing Field External ID with miRNA_External_Identifier
    my $ei_count = $dbc->Table_update_array(
        'Source, Sample_Type , Source_Attribute , Attribute', ['External_Identifier'], ['Attribute_Value'],
        " WHERE FK_Sample_Type__ID= Sample_Type_ID AND Sample_Type = '$sample_type' AND FKReference_Project__ID IN ($list)  
      AND Source_ID IN ($ids) AND FK_Source__ID= Source_ID AND FK_Attribute__ID= Attribute_ID AND Attribute_Name = 'miRNA_External_Identifier'"
    );
    $dbc -> message ("Updated 'External Identifier' for $ei_count records");

    ## Replacing Field Source_Label with miRNA_Source_Label
    my $sl_count = $dbc->Table_update_array(
        'Source, Sample_Type , Source_Attribute , Attribute', ['Source_Label'], ['Attribute_Value'],
        " WHERE FK_Sample_Type__ID= Sample_Type_ID AND Sample_Type = '$sample_type' AND FKReference_Project__ID IN ($list) 
       AND Source_ID IN ($ids) AND FK_Source__ID= Source_ID AND FK_Attribute__ID= Attribute_ID AND Attribute_Name = 'miRNA_Source_Label'"
    );

     $dbc -> message ( "Updated 'Source Label' for $sl_count records");

    ## Replacing attribute Alternate_External_Identifier with miRNA_Alternate_External_Identifier
    my @sa_ids = $dbc->Table_find(
        'Source, Sample_Type , Source_Attribute , Attribute', 'Source_Attribute_ID',
        "WHERE FK_Sample_Type__ID= Sample_Type_ID AND Sample_Type = '$sample_type' AND FKReference_Project__ID IN ($list) 
       AND Source_ID IN ($ids) AND FK_Source__ID= Source_ID AND FK_Attribute__ID= Attribute_ID AND Attribute_Name = 'Alternate_External_Identifier'"
    );

    my @mi_sa_ids = $dbc->Table_find(
        'Source , Sample_Type , Source_Attribute , Attribute', 'Source_Attribute_ID',
        "WHERE FK_Sample_Type__ID= Sample_Type_ID AND Sample_Type = '$sample_type' AND FKReference_Project__ID IN ($list) 
        AND Source_ID IN ($ids) AND FK_Source__ID= Source_ID AND FK_Attribute__ID= Attribute_ID AND Attribute_Name = 'miRNA_Alternate_External_Identifier'"
    );

    if ( $mi_sa_ids[0] ) {
        my $aei_count;
        my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'Alternate_External_Identifier'" );
        if ( $sa_ids[0] ) {
            ## if there is already records for alternate external_id they should be deleted
            my $sa_list = join ',', @sa_ids;
            $dbc->delete_records( -table => 'Source_Attribute', -dfield => 'Source_Attribute_ID', -id_list => $sa_list, -quiet => 1 );
        }
        my $counter;
        for my $mi_sa (@mi_sa_ids) {
            my ($aei_count) = $dbc->Table_copy( -table => 'Source_Attribute', -condition => "where Source_Attribute_ID = ($mi_sa)", -exclude => [ 'Source_Attribute_ID', 'FK_Attribute__ID' ], -replace => [ '', $attribute_id ] );
            if ($aei_count) { $counter++ }
        }
         $dbc -> message ("Updated 'Alternate External Identifier' for $counter records");
    }

    $dbc->finish_trans('GSC_Labels');

    return;

}

return 1;
