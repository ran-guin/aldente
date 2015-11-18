###################################################################################################################################
# TCGA::Statistics_Views.pm
#
#
#
###################################################################################################################################
package TCGA::Statistics_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs );

#############################################
#

#
# Return: html page
###################
sub home_page {
###################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'id' );
    my $id    = $args{-id};
    my $Model = $args{-Model} || $self->{Model};
    my $dbc   = $args{-dbc} || $Model->{'dbc'};
	my @options = ('Show Shipment Summary' ,	'Show Organization Summary', 'Show Tissue Type Summary','Show Histology Summary');
	
	
	my $page  = alDente::Form::start_alDente_form(-dbc=>$dbc).
      $q->hidden( -name => 'cgi_application', -value => 'TCGA::Statistics_App', -force => 1 ) .
      $q->submit( -name  => 'rm',			  -value => 'Show Shipment Summary',       -force => 1, -class => "Std") .
      $q->submit( -name  => 'rm',			  -value => 'Show Organization Summary',       -force => 1, -class => "Std") .
      $q->submit( -name  => 'rm',			  -value => 'Show Tissue Type Summary',       -force => 1, -class => "Std") .
      $q->submit( -name  => 'rm',			  -value => 'Show Histology Summary',       -force => 1, -class => "Std") .
      $q->submit( -name  => 'rm',			  -value => 'Show Project Summary',       -force => 1, -class => "Std") .
#      $q->submit( -name  => 'rm',			  -value => 'Show Shipment Summary',       -force => 1, -class => "Std") .
#      $q->submit( -name  => 'rm',			  -value => 'Show Shipment Summary',       -force => 1, -class => "Std") .
      $q->end_form();
	my $page  = alDente::Form::start_alDente_form(-dbc=>$dbc).
	    $q->hidden( -name => 'cgi_application', -value => 'TCGA::Statistics_App',  -force => 1 ) .
	    $q->submit( -name  => 'View Summary',   -value => 'View Summary', -class => "Std", -force => 1) .
        $q->popup_menu(  -name    => 'rm', 		-values  => \@options, 					   -force => 1  ).
	    $q->end_form();	

    return $page;
}



#############################################################
sub shipment_summary {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc};
    my $Model = $self->param('Model');

    my $page =   $dbc->Table_retrieve_display('Source,Original_Source, Shipment, Tissue LEFT JOIN Source_Attribute ON Source_Attribute.FK_Source__ID=Source_ID AND FK_Attribute__ID=304 Left Join Organization on Shipment.FKSupplier_Organization__ID = Organization_ID',
					[ 'Shipment_ID', 'Organization_Name','Received_Date','Attribute_Value as Batch', 'Source_Type', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens', 'Count(Distinct Mid(External_Identifier,22,4)) as Plates','Min(Original_Source_Name) as First_Sample', 'Max(Original_Source_Name) as Last_Sample', 'GROUP_CONCAT(DISTINCT Tissue_Name) AS Tissue_Types'],
					"WHERE FK_Tissue__ID=Tissue_ID AND FK_Shipment__ID=Shipment_ID AND FK_Original_Source__ID=Original_Source_ID GROUP BY Shipment_ID, Batch ORDER BY Shipment_ID",
					-return_html=>1,
					-title=>'Current Samples Tracked with Patient_ID reference',
					-total_columns=>'Samples,Sources,Specimens',
					-print_link=>1,
					);

    return $page;
}
#############################################################
sub organization_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc   = $args{-dbc};

   my $left =  $dbc->Table_retrieve_display('Shipment, Organization , Source, Original_Source',
					[ 'Organization_Name', 'count(distinct Shipment_ID) as Shipments', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens', 
					'Min(Original_Source_Name) as First_Sample', 'Max(Original_Source_Name) as Last_Sample'],
					"WHERE FKSupplier_Organization__ID = Organization_ID  and FK_Shipment__ID = Shipment_ID and FK_Original_Source__ID = Original_Source_ID
					group by Organization_ID",
					-return_html=>1,
					-title=>'Supplier Organizations Shipment Summary',
					-total_columns=>'Samples,Sources,Specimens',
					-print_link=>1 );
					
	my $right = $dbc->Table_retrieve_display('Shipment, Organization , Source',
			[ 'Organization_Name', 'Source_Status', 'Count(Distinct Source_ID) as Sources'],
			"WHERE FKSupplier_Organization__ID = Organization_ID  and FK_Shipment__ID = Shipment_ID
			group by Organization_ID, Source_Status order by Organization_Name",
			-return_html=>1,
			-title=>'Source Status',
			-total_columns=>'Samples,Sources,Specimens',
			-layer => 'Source_Status',
			-print_link=>1 );	
					
	my $page = &Views::Table_Print(content => [[$left, $right ]], print=>0 );

    return $page;
}
#############################################################
sub tissue_type_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc};

    my $table_1 = $dbc->Table_retrieve_display('Tissue, Original_Source, Source',
			[ 'Tissue_Name', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens'	],
			"WHERE  FK_Tissue__ID = Tissue_ID and FK_Original_Source__ID = Original_Source_ID AND FK_Shipment__ID > 0 Group by Tissue_ID order by Tissue_Name",
			-return_html=>1,
			-title=>'Tissue Type Summary',
			-total_columns=>'Samples,Sources,Specimens',
			-print_link=>1,	);

    my $table_2 = $dbc->Table_retrieve_display('Tissue, Original_Source, Source',
			[ 'Tissue_Name', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens','Source_Status'	],
			"WHERE  FK_Tissue__ID = Tissue_ID and FK_Original_Source__ID = Original_Source_ID AND FK_Shipment__ID > 0 Group by Tissue_ID, Source_Status order by Tissue_Name",
			-return_html=>1,
			-title=>'Tissue Type Summary',
			-total_columns=>'Samples,Sources,Specimens',
			-layer=>'Source_Status',
			-print_link=>1,			);
	my $page = &Views::Table_Print(content => [[$table_1, $table_2 ]], print=>0 );
    return $page;
}
#############################################################
sub histology_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc};

    my $left = $dbc->Table_retrieve_display('Original_Source,Original_Source_Attribute, Source,Attribute, Tissue',
			['Attribute_Value as Histology', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens', 'GROUP_CONCAT(DISTINCT Tissue_Name) AS Tissues','Source_Type'	],
			"WHERE FK_Tissue__ID = Tissue_ID and  Original_Source_Attribute.FK_Original_Source__ID = Original_Source_ID AND Source.FK_Original_Source__ID = Original_Source_ID AND FK_Shipment__ID > 0 AND FK_Attribute__ID= Attribute_ID and Attribute_Name = 'Biological_Condition' Group by Attribute_Value",
			-return_html=>1,
			-title=>'Histology Summary',
			-total_columns=>'Samples,Sources,Specimens',
			-print_link=>1,
			);
    
	my $right = $dbc->Table_retrieve_display('Original_Source,Original_Source_Attribute, Source,Attribute',
			['Attribute_Value as Histology', 'Count(Distinct Source_ID) as Sources', 'Count(Distinct Original_Source_ID) as Specimens','Source_Status'	],
			"WHERE  Original_Source_Attribute.FK_Original_Source__ID = Original_Source_ID AND Source.FK_Original_Source__ID = Original_Source_ID AND FK_Shipment__ID > 0 AND FK_Attribute__ID= Attribute_ID and Attribute_Name = 'Biological_Condition' Group by Attribute_Value, Source_Status",
			-return_html=>1,
			-title=>'Histology Summary',
			-total_columns=>'Samples,Sources,Specimens',
			-layer => 'Source_Status',
			-print_link=>1,
			);
   my $page = &Views::Table_Print(content => [[$left, $right ]], print=>0 );
   return $page;
}
#############################################################
sub list_page_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc};

    my $Model = $self->param('Model');
    my $dbc      = $Model->param('dbc');

    my $page = 'list';

    return $page;
}

1;
