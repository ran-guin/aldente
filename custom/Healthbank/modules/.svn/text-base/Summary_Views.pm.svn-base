package Healthbank::Summary_Views;

use base Healthbank::Views;

use strict;
use warnings;

use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Healthbank::Model;
use LampLite::Bootstrap;
use LampLite::CGI;

my $BS = new Bootstrap;
my $q = new LampLite::CGI;

my ( $session, $account_name );

############################
sub prompt_for_summary {
############################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc,prefix');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $prefix = $args{-prefix};   ## specify prefix for samples (eg BC or SHE)
    my $layer  = $args{-layer};

    my $layered;
    if ($layer) { $layered = "[ by $layer]" }

    my $page = section_heading("Retrieve Subject / Sample Summary $layered");
    my $tag = alDente::Form::start_alDente_form($dbc, 'bcg_summary');
    
    eval "require LampLite::Form";
    my $Form = new LampLite::Form(-dbc=>$dbc, -label_style=>'text-align:right');
    my $include_options = $q->checkbox( -name => 'Include Times', -checked => 0, -force => 1 )
        . ' (retrieves storage times for samples - <B>much SLOWER to load</B>)<BR>'
        . $q->checkbox( -name => 'Include Test Samples', -checked => 0, -force => 1 )
        . hspace(5)
        . $q->checkbox( -name => 'Include Production Samples', -checked => 1, -force => 1 );

    $Form->append('Include', $include_options, -no_format=>1);
    
    $Form->append('Project:', $q->radio_group(-name=>'Prefix', -values=>['BC','SHE'], -default=>$prefix, -force=>1));
    $Form->append('Subject Range:', 
        Show_Tool_Tip($q->textfield( -name => 'from_subject', -size => 6, -class=>'short-txt'), 'Starting with Subject #')
        . ' -> '
        . Show_Tool_Tip($q->textfield( -name => 'to_subject', -size => 6, -class=>'short-txt'), 'Ending with Subject #')
        . ' - Exclude: ' . Show_Tool_Tip( $q->textfield( -name => 'exclude_subjects', -size => 12), 'Enter comma-delimited list of subjects from given range to exclude')
    );
    $Form->append('Initial Freeze Time Range (in hrs):', 
        Show_Tool_Tip( $q->textfield( -name => 'min_freeze_time', -size => 3, -class=>'narrow-txt') , "Minimum Freeze Time") 
        . ' -> ' 
        . Show_Tool_Tip( $q->textfield( -name => 'max_freeze_time', -size => 3 , -class=>'narrow-txt'), "Maximum Freeze Time") 
        . ' (only applicable when retrieving times)', -no_format=>1
    );
    
    $Form->append(' Custom condition: ', Show_Tool_Tip($q->textfield( -name => 'Condition', size => 50 ), 'Optional SQL database query condition'));

    $Form->append('Recieved:', 
        display_date_field( -dbc => $dbc, -field_name => 'date_range', -default => '', -range => 1, -quick_link => [ 'Today', '7 days', '1 month', '1 year' ]),
        -no_format=>1,
        );
    
    $Form->append( '' , $q->submit( -name => 'rm', -value => 'Generate Summary', -label=>'Re-Generate Summary', -class => 'Std' )); 
    $Form->append('', $q->checkbox(-name=>'include_breakdown', -label=>'Include Breakdown [Collected / Stored / Exported]', -tooltip=>'Breakdown summary for Collected (SRC) / Stored (BCG) / and Exported Samples') );
    
    my $app = ref $self->App || $self->App;
    my $include = $q->hidden( -name => 'cgi_application', -value => $app, -force => 1 ).
        $q->hidden(-name=>'Layer', -value=>$layer, -force=>1);

    return $Form->generate(-tag=>$tag, -close=>1, -include=>$include);
}

#########################
sub healthbank_summary {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $prefix = $args{-prefix};
    my $condition = $args{-condition} || 1;
    my $debug  = $args{-debug};
    my $source_condition = $args{-source_condition};
    my $plate_condition = $args{-plate_condition} || 1;

    if ($plate_condition) { $condition .= " AND $plate_condition" }
    if ($source_condition) { $condition .= " AND $source_condition" }

    ## get some overview tables (previously in Administration layer) ##
    my $tables            = 'Plate,Plate_Sample,Sample,Source,Original_Source,Patient';
    my $summary_condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID";


    if ($plate_condition =~ /FreezeTime/) {
        my ($freeze_time) = $dbc->Table_find('Attribute', "Attribute_ID", "WHERE Attribute_Name = 'initial_time_to_freeze'");
        $tables .= " LEFT JOIN Plate_Attribute as FreezeTime ON FreezeTime.FK_Plate__ID=Plate.Plate_ID AND FK_Attribute__ID = $freeze_time";
    }
        
    if ($prefix) { $condition .= " AND Plate_Label LIKE '$prefix%'" }
    

    my $source_only_tables = "Source, Original_Source, Patient LEFT JOIN Sample ON Sample.FK_Source__ID=Source_ID";
    my $source_only_condition =  "WHERE Source.FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID";
    
    my $summary = $dbc->Table_retrieve_display(
        $source_only_tables, [ 'Source.FK_Sample_Type__ID as Sample_Type', 'Source.FK_Plate_Format__ID as Format','count(distinct Sample_ID) as Samples_Generated', 'count(distinct Source_ID) as Sources', 'count(distinct External_Identifier) as Unique_IDs', 'count(distinct FK_Patient__ID) as Subjects' ],
        "$source_only_condition AND $source_condition GROUP BY Source.FK_Plate_Format__ID,Source.FK_Sample_Type__ID",
        -title       => 'Sample Collection Summary [even if not aliquoted out to cryovials]',
        -return_html => 1,
        -debug=>$debug,
    );

    my $active = $dbc->Table_retrieve_display(
        $tables, [ 'Plate.FK_Plate_Format__ID as Format', 'Plate.FK_Sample_Type__ID as Sample_Type', 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct FK_Patient__ID) as Subjects' ],
        "$summary_condition AND Plate.Plate_Status = 'Active' AND $condition GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Total Samples Currently Stored',
        -total_columns => 'Active_Tubes',
        -return_html   => 1,
        -debug=>$debug,
    );
    
    my $plate_class = 3;
    my $exported = $dbc->Table_retrieve_display(
        "$tables LEFT JOIN Shipped_Object ON FK_Object_Class__ID=$plate_class AND Object_ID=Plate.Plate_ID LEFT JOIN Shipment ON Shipped_Object.FK_Shipment__ID=Shipment_ID", 
        [ 'Plate.FK_Plate_Format__ID as Format', 'Plate.FK_Sample_Type__ID as Sample_Type', 'count(distinct Plate_ID) as Exported_Tubes', 'count(distinct FK_Patient__ID) as Subjects', 'FKTarget_Site__ID as Target_Site', 'Shipped_Object.FK_Shipment__ID as Shipment'],
        "$summary_condition AND Plate.Plate_Status = 'Exported' AND $condition GROUP BY Target_Site, Shipment, Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Total Samples Currently Stored',
        -total_columns => 'Exported_Tubes',
        -layer => 'Target_Site',
        -return_html   => 1,
        -debug=>$debug,
    );
    
    my $details = create_tree(-tree=> {'Sample Collection Query' => "SELECT * FROM $tables $summary_condition AND Plate.Plate_Status = 'Active' AND $condition" }); 
    
    my $page = subsection_heading("Breakdown Summary by Sample Type / Format");
    
    $page .= $BS->accordion( -layers=> [ 
        { 'label' => 'Collected (SRC records)', 'content' => $summary } , 
        { 'label' => 'Stored (BCG records)', 'content' => $active },
        { 'label' => 'Exported (BCG records exported)', 'content' => $exported }
        ]);
        
    return $page . $details;
}

return 1;
