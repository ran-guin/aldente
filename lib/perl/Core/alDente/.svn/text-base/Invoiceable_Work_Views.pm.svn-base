###################################################################################################################################
# alDente::Invoiceable_Work_Views
#
#
#
#
###################################################################################################################################
package alDente::Invoiceable_Work_Views;
use base alDente::Object_Views;
use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules
use alDente::Invoiceable_Work;
use alDente::Invoice;

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $id   = $args{-id};
    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    my $Model = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id );
    $self->{dbc}   = $dbc;
    $self->{id}    = $id;
    $self->{Model} = $Model;

    return $self;
}

#############################################
#
# Standard view for single Invoiceable Work record
#
# Return: html page
###################
sub home_page {
###################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'dbc, id' );
    my $model = $args{-model};

    my $Invoiceable_Work = $model->{Invoiceable_Work};
    $Invoiceable_Work ||= $self->{Invoiceable_Work};

    my $dbc = $args{-dbc} || $Invoiceable_Work->dbc();
    my $id  = $args{-id}  || $Invoiceable_Work->{id};

    my $page;

    if ( !$Invoiceable_Work ) {
        $Invoiceable_Work = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id, -initialize => 0 );
    }

    my $info = $Invoiceable_Work->get_work_info( -dbc => $dbc, -id => $id );
    my $src_display = &get_src_table( -dbc => $dbc, -id => $id );

    $page
        .= $info
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Source_List' )
        . "<br><br>"
        . $Invoiceable_Work->change_billable_btn( -dbc => $dbc )
        . "<br><br>"
        . "<u>List of Sources and their Invoices</u> <br>"
        . $src_display . "<br>"
        . hidden( -name => 'ID', -value => $id, -force => 1 )
        . end_form();

    my $child_src_display;

    my $has_children = $Invoiceable_Work->has_multiple_invoiceable_work_ref( -dbc => $dbc, -id => $id );

    if ($has_children) {
        $child_src_display = &get_child_src_table( -dbc => $dbc, -parent => $has_children );

        my %layers;
        $layers{'Child Invoiceable Work Reference Items (click to show)'} = $child_src_display;

        $page .= define_Layers( -layers => \%layers, -layer_type => 'accordion' );
    }

    ## A warning message which lets you know if the work funding is different from the plate funding
    $Invoiceable_Work->funding_warning( -dbc => $dbc, -id => $id );

    # Putting it all together
    my $homepage = Views::Table_Print(
        content => [ [ &Views::Heading("Invoiceable Work ID: $id") ], [ $page, $Invoiceable_Work->display_Record ] ],
        print => 0
    );

    return $homepage;
}

#############################################
# Page for choosing/confirming which child Invoiceable_Work_Reference items to apply change
# in funding to.
#
# Should only be used when the Invoiceable_Work item being edited has children IWR records.
######################
sub confirm_update_funding_page {
######################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc, id, funding' );

    my $Invoiceable_Work = $self->{Invoiceable_Work};

    my $dbc = $args{-dbc} || $Invoiceable_Work->dbc();
    my $id  = $args{-id}  || $Invoiceable_Work->{id};
    my $funding = $args{-funding};

    my $page;

    if ( !$Invoiceable_Work ) {
        $Invoiceable_Work = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id, -initialize => 0 );
    }

    my $info              = $Invoiceable_Work->get_work_info( -dbc      => $dbc, -id => $id );
    my $child_iwr_display = &get_child_invoiceable_work_ref_table( -dbc => $dbc, -id => $id );

    $page .= "<div class='alert alert-danger'><b>The Invoiceable_Work item you have chosen to update has children Invoiceable_Work_Reference items.
             <br>Please select the items where you would like to change the funding to: '$funding'</b></div>"
        . $info
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirm Update Funding' )
        . "<br><br>"
        . $child_iwr_display
        . &confirm_update_funding_btn( -dbc => $dbc, -funding => $funding )
        . hidden( -name => 'ID', -value => $id, -force => 1 )
        . end_form();

    # Putting it all together
    my $confirm_update_page = Views::Table_Print(
        content => [ [ &Views::Heading("Invoiceable Work ID: $id") ], [ $page, $Invoiceable_Work->display_Record ] ],
        print => 0
    );

    return $confirm_update_page;
}

######################
# Generate a button for appending Invoiceable_Work comments
# It is mainly used in views
#
# <snip>
#	alDente::Invoiceable_Work_Views::append_iw_comment_btn(-dbc=>$self->{dbc}, -from_view => 1 );
# <snip>
#
# Return:
#	HTML string
######################
sub append_iw_comment_btn {
######################
    my %args      = filter_input( \@_, -args => 'dbc' );
    my $dbc       = $args{-dbc};
    my $from_view = $args{-from_view};

    my $validation_filter = '';
    if ($from_view) {
        $validation_filter .= "sub_cgi_app( 'alDente::Invoiceable_Work_App');";
    }

    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('IW_comments_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Append Invoiceable Work Item Comment', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Append comments to the selected Invoiceable Work" );

    $output .= hspace(10) . set_validator( -name => 'IW_Comments', -id => 'IW_comments_validator' ) . " Work Item Comments: " . textfield( -name => 'IW_Comments', -size => 30, -default => '' );

    if ($from_view) {
        $output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $output .= hidden( -name => 'RUN_CGI_APP', -value => 'AFTER', -force => 1 );
    }
    else {
        $output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoiceable_Work_App', -force => 1 );
    }

    return $output;
}

##############################
# Button to confirm which Invoiceable_Work_Reference items to
# update FKApplicable_Funding__ID for
##############################
sub confirm_update_funding_btn {
##############################
    my %args    = filter_input( \@_, -args => 'dbc, funding' );
    my $dbc     = $args{-dbc};
    my $funding = $args{-funding};

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Update Funding', -class => 'Action', -force => 1 ), "Confirm update of applicable fundings for selected Invoiceable_Work_Reference items" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoiceable_Work_App', -force => 1 );
    $form_output .= hidden( -name => 'FK_Funding__ID', -value => $funding, -force => 1 );

    return $form_output;
}

##############################
# Displays table of all child Invoiceable_Work_Reference items of a given
# Invoiceable_Work item.
# To be used when updating the funding of and Invoiceable_Work item that has
# children Invoiceable_Work_Reference items
#
# Input: Invoiceable_Work_ID
# Output: HTML table with child invoiceable work reference information
##############################
sub get_child_invoiceable_work_ref_table {
##############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc, id' );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id};

    my ($parent_iwr) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKReferenced_Invoiceable_Work__ID = $id AND FKParent_Invoiceable_Work_Reference__ID IS NULL" );

    my $to_be_updated = $dbc->Table_retrieve_display(
        'Invoiceable_Work_Reference LEFT JOIN Sample ON Sample.FK_Source__ID = Invoiceable_Work_Reference.FK_Source__ID',
        [ 'Invoiceable_Work_Reference_ID AS Child_Work_Reference_ID', 'Invoiceable_Work_Reference.FK_Source__ID AS Child_Source_ID', 'GROUP_CONCAT(FK_Library__Name) AS Library_Name', 'FKApplicable_Funding__ID AS Current_Funding' ],
        "WHERE FKParent_Invoiceable_Work_Reference__ID = $parent_iwr GROUP BY Invoiceable_Work_Reference_ID ORDER BY Invoiceable_Work_Reference_ID",
        -title            => "Children Invoiceable_Work_Reference records of Invoiceable_Work item: $id",
        -selectable_field => 'Child_Work_Reference_ID',
        -return_html      => 1,
        -alt_message      => "No children found for Invoiceable_Work item $id",
        -space_words      => 1,
        -style            => "white-space: normal; "
    );
}

#####################
# This function is used to get a table with source information in it
# Input: Invoiceable_Work_ID
# Output: HTML table with source information
#
#####################
sub get_src_table {
#####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc, id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $src_table = $dbc->Table_retrieve_display(
        'Invoiceable_Work_Reference IWR
            LEFT JOIN Invoiceable_Work_Reference IWR2 ON IWR.Invoiceable_Work_Reference_ID = IWR2.FKParent_Invoiceable_Work_Reference__ID LEFT JOIN Funding ON IWR2.FKApplicable_Funding__ID = Funding_ID',
        [   'DISTINCT IWR.Invoiceable_Work_Reference_ID AS Work_Reference_ID',
            'IWR.FKApplicable_Funding__ID AS Funding',
            'IWR.FK_Source__ID AS Source_ID',
            'IWR.FK_Invoice__ID AS Invoice_ID',
            'GROUP_CONCAT(DISTINCT IWR.Billable) AS Billable',

            #            'GROUP_CONCAT(DISTINCT IWR2.Invoiceable_Work_Reference_ID) AS Child_Work_Reference_ID',
            #            'GROUP_CONCAT(DISTINCT IWR2.FK_Source__ID) AS Child_Source_ID',
            #            "GROUP_CONCAT(IFNULL(Funding_Name, 'NULL')) AS Child_Funding",
            'GROUP_CONCAT(DISTINCT IWR.Invoice_Status) AS Invoice_Status'
        ],
        "WHERE IWR.FKReferenced_Invoiceable_Work__ID in ($id)
        GROUP BY IWR.Invoiceable_Work_Reference_ID
        HAVING SUM(IWR.Indexed) IS NULL OR GROUP_CONCAT(DISTINCT IWR2.Invoiceable_Work_Reference_ID) IS NOT NULL
        ORDER BY Work_Reference_ID",
        -title           => 'List of Sources and their Invoices',
        -return_html     => 1,
        -list_in_folders => [ 'Child_Work_Reference_ID', 'Child_Source_ID', 'Child_Funding' ],
        -alt_message     => "No source information found"
    );

    return $src_table;
}

#####################
# This function is used to get a table with source information for an invoiceable work item's children if they exist
# Input: Invoiceable_Work_ID
# Output: HTML table with source information for child invoiceable work reference items
#####################
sub get_child_src_table {
#####################
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'dbc, id' );
    my $dbc        = $args{-dbc};
    my $parent_iwr = $args{-parent};

    my $child_src_table = $dbc->Table_retrieve_display(
        'Invoiceable_Work_Reference LEFT JOIN Sample ON Sample.FK_Source__ID = Invoiceable_Work_Reference.FK_Source__ID',
        [   'Invoiceable_Work_Reference_ID AS Child_Work_Reference_ID',
            'Invoiceable_Work_Reference.FK_Source__ID AS Child_Source_ID',
            'GROUP_CONCAT(Sample.FK_Library__Name) AS Associated_Libraries',
            'Invoiceable_Work_Reference.FKApplicable_Funding__ID AS Child_Funding'
        ],
        "WHERE FKParent_Invoiceable_Work_Reference__ID = $parent_iwr GROUP BY Invoiceable_Work_Reference_ID",
        -title           => 'List of Child Invoiceable Work Reference Items',
        -return_html     => 1,
        -list_in_folders => [ 'Child_Work_Reference_ID', 'Child_Source_ID', 'Associated_Libraries', 'Child_Funding' ],
        -alt_message     => "No child invoiceable work reference information found"
    );

    return $child_src_table;
}

#####################
# Input: List of sources or Libraries
# Return: Array of tables containing Invoiceable work for corresponding sources or libraries depending on input
# Will be used for the projects team invoice work report, provides breakout for invoiceable work
###############################################
sub get_invoiceable_work_for_invoice_report {
###############################################
    my %args              = &filter_input( \@_, -args => 'dbc,library_list|source_list', -mandatory => 'dbc,library_list|source_list' );
    my $dbc               = $args{-dbc};
    my $library_list      = $args{-library_list};                                                                                          # array of libraries from Key field of view
    my $source_list       = $args{-source_list};                                                                                           # array of sources from Key field of view
    my $extra_condition   = $args{-extra_condition};
    my $default_field_ref = [
        'work_id',            'library_strategy', 'work_type',      'work_date', 'pla',             'tra',       'libs_pool', 'machine',
        'SolexaRun_Mode',     'run_status',       'run_validation', 'run_id',    'run_started',     'run_type',  'billable',  'billable_comments',
        'work_item_comments', 'assoc_invoice',    'draft_name',     'invoiced',  'run_analysis_id', 'ra_run_id', 'mra_id',    'ra_batch_id'
    ];

    my $custom_field_ref = $args{-field_list} || $default_field_ref;                                                                       #provide a custom field list, or it will use default

    my @key_list;
    my $keys;

    if ( $library_list && !$source_list ) {
        @key_list = Cast_List( -list => $library_list, -to => 'Array' );                                                                   #array for merge_data_for_column
        $keys = Cast_List( -list => $library_list, -to => 'String', -autoquote => 1 );                                                     #autoquote for SQL IN query
    }
    elsif ( !$library_list && $source_list ) {
        @key_list = Cast_List( -list => $source_list, -to => 'Array' );                                                                    #array for merge_data_for_column
        $keys = Cast_List( -list => $source_list, -to => 'String', -autoquote => 1 );                                                      #autoquote for SQL IN query
    }
    else {
        return;
    }

    #  custom_field_ref is an empty array; use default fields
    if ( !@$custom_field_ref ) {
        $custom_field_ref = $default_field_ref;
    }

    my $grouping_field = "Li.Library_Name";

    my %iw_fields = (
        'work_id',          "IW.Invoiceable_Work_ID AS Work_ID",
        'library_strategy', "GROUP_CONCAT(DISTINCT (CASE WHEN IP.Invoiceable_Prep_ID > 0 THEN Library_Strategy_Lookup.Library_Strategy_Name END )) AS Library_Strategy",
        'work_type',
        "Group_Concat(DISTINCT CASE WHEN IW.Invoiceable_Work_Type = 'Run' THEN CONCAT(IRT.Invoice_Run_Type_Name) WHEN IW.Invoiceable_Work_Type = 'Prep' THEN CONCAT(IPP.Invoice_Protocol_Name) WHEN IW.Invoiceable_Work_Type = 'Analysis' THEN CONCAT(IPI.Invoice_Pipeline_Name) END) as Work_Type",
        'work_date',          "IW.Invoiceable_Work_DateTime AS Work_Date",
        'pla',                "IW.FK_Plate__ID AS PLA",
        'tra',                "IW.FK_Tray__ID AS TRA",
        'machine',            'RunBatch.FK_Equipment__ID AS Machine',
        'solexarun_mode',     "SolexaRun.SolexaRun_Mode",
        'run_status',         "GROUP_CONCAT(DISTINCT Run.Run_Status) AS Run_Status",
        'run_validation',     "GROUP_CONCAT(DISTINCT Run.Run_Validation) AS Run_Validation",
        'run_id',             "GROUP_CONCAT(DISTINCT Run.Run_ID) AS Run_IDs",
        'run_started',        "GROUP_CONCAT(DISTINCT Run.Run_DateTime) AS Run_Started",
        'run_type',           "CONCAT(MAX(Solexa_Read.Read_Length) , ' bp ' , Left(Solexa_Read.End_Read_Type , 1) , 'ET') AS Run_Type",
        'run_analysis_id',    "RA.Run_Analysis_ID as Run_Analysis_ID",
        'ra_run_id',          "RA.FK_Run__ID as Run_Analysis_Run_ID",
        'mra_id',             "MRA.Multiplex_Run_Analysis_ID as Multiplex_Run_Analysis_ID",
        'ra_batch_id',        "RA.FK_Run_Analysis_Batch__ID as Run_Analysis_Batch_ID",
        'billable',           "GROUP_CONCAT(DISTINCT IWR.Billable) AS Billable",
        'billable_comments',  "GROUP_CONCAT(DISTINCT IW.Invoiceable_Work_Comments) AS Billable_Comments",
        'work_item_comments', "GROUP_CONCAT(DISTINCT IW.Invoiceable_Work_Item_Comments) AS Work_Item_Comments",
        'assoc_invoice',      "GROUP_CONCAT(DISTINCT IWR.FK_Invoice__ID) AS Assoc_Invoice",
        'draft_name',         "GROUP_CONCAT(DISTINCT Invoice.Invoice_Draft_Name) AS Draft_Name",
        'invoiced',           "GROUP_CONCAT(DISTINCT IWR.Invoiceable_Work_Reference_Invoiced) AS Invoiced",

        #'all_reads',          "FORMAT((SUM(SequenceAnalysis.Wells)/COUNT(DISTINCT Work_Request.Work_Request_ID)), 2) AS All_Reads",
        'all_reads', "SequenceAnalysis.AllReads AS All_Reads",

        #'no_grow',            "FORMAT((SUM(SequenceAnalysis.Wells)/COUNT(DISTINCT Work_Request.Work_Request_ID)), 2) AS Reads_excluding_No_Grows",
        'no_grow',       "SequenceAnalysis.Wells AS Reads_Excluding_No_Grows",
        'src_rcvd',      "GROUP_CONCAT(DISTINCT Source.Received_Date) AS Src_Rcvd",
        'pipeline_name', "GROUP_CONCAT(DISTINCT CONCAT(Pip.Pipeline_Code,' : ', Pip.Pipeline_Name) SEPARATOR ', ') AS Pipeline",

        #'pipeline_name',      "Pip.Pipeline_Name AS Pipeline_Name",
        'primer_name', "PM.Primer_Name AS Primer",
        'vector_type', "Vector.Vector_Type AS Starting_Material"
    );

    my @fields = ();

    #adds fields in custom order, or default if not specified
    foreach my $c_field (@$custom_field_ref) {
        my $field = $iw_fields{ lc($c_field) };
        if ($field) {
            push @fields, $field;
        }
    }

    my $base_tables = "Invoiceable_Work IW, Invoiceable_Work_Reference IWR, Library_Source";

    my $join_tables = " 
                        LEFT JOIN Plate WkPl ON WkPl.Plate_ID = IW.FK_Plate__ID
                        LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                        LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                        LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
                        LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                        LEFT JOIN Library Li ON Li.Library_Name = COALESCE(WkPl.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
						LEFT JOIN Invoiceable_Prep IP ON IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
						LEFT JOIN Invoiceable_Run IR ON IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID 
						LEFT JOIN Invoiceable_Run_Analysis as IRA ON IRA.FK_Invoiceable_Work__ID=IW.Invoiceable_Work_ID	
						LEFT JOIN Invoice_Protocol IPP ON IPP.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID
						LEFT JOIN Invoice_Run_Type IRT ON IRT.Invoice_Run_Type_ID = IR.FK_Invoice_Run_Type__ID
						LEFT JOIN Invoice_Pipeline AS IPI ON IPI.Invoice_Pipeline_ID = IRA.FK_Invoice_Pipeline__ID
                        LEFT JOIN Pipeline Pip ON COALESCE(WkPl.FK_Pipeline__ID = Pip.Pipeline_ID, IPI.FK_Pipeline__ID)
						LEFT JOIN Plate_Attribute AS Library_Strategy ON Library_Strategy.FK_Plate__ID = IW.FK_Plate__ID AND Library_Strategy.FK_Attribute__ID = 246
						LEFT JOIN Library_Strategy AS Library_Strategy_Lookup ON Library_Strategy_Lookup.Library_Strategy_ID = Library_Strategy.Attribute_Value
						LEFT JOIN Run ON IR.FK_Run__ID=Run_ID
                        LEFT JOIN SolexaRun ON SolexaRun.FK_Run__ID=Run_ID
						LEFT JOIN RunBatch ON Run.FK_RunBatch__ID=RunBatch_ID
                        LEFT JOIN Run_Analysis ON Run_Analysis.FK_Run__ID=Run_ID						
                        LEFT JOIN Solexa_Read ON Solexa_Read.FK_Run__ID=Run_ID
                        LEFT JOIN Invoice ON Invoice.Invoice_ID = IWR.FK_Invoice__ID
                        LEFT JOIN SequenceRun ON Run.Run_ID = SequenceRun.FK_Run__ID
                        LEFT JOIN SequenceAnalysis ON SequenceAnalysis.FK_SequenceRun__ID = SequenceRun.SequenceRun_ID
                        LEFT JOIN Work_Request ON WkPl.FK_Library__Name = Work_Request.FK_Library__Name
                        LEFT JOIN Source ON IWR.FK_Source__ID = Source.Source_ID
                        LEFT JOIN Source ChildSource ON ChildSource.FKOriginal_Source__ID = Source.Source_ID
                        LEFT JOIN Branch_Condition BC ON WkPl.FK_Branch__Code = BC.FK_Branch__Code
                        LEFT JOIN Primer PM ON PM.Primer_ID = BC.Object_ID
                        LEFT JOIN LibraryVector LV ON LV.FK_Library__Name = WkPl.FK_Library__Name
                        LEFT JOIN Vector ON Vector.Vector_ID = LV.FK_Vector__ID
                       ";

    my $conditions = "
			( Solexa_Read.End_Read_Type IS NULL OR Solexa_Read.End_Read_Type NOT LIKE 'IDX%' ) 
            AND IW.Invoiceable_Work_ID = IWR.FKReferenced_Invoiceable_Work__ID
            AND (Library_Source.FK_Library__Name = Li.Library_Name AND Library_Source.FK_Source__ID = ChildSource.Source_ID)
			";

    my $sql = $dbc->{SQL};

    #check for any input in 'Invoiced' field
    my $invoiced;

    if ( $sql =~ m/IWR.Invoiceable_Work_Reference_Invoiced = \'No\'/ ) {
        $invoiced = "No";
    }
    elsif ( $sql =~ m/IWR.Invoiceable_Work_Reference_Invoiced = \'Yes\'/ ) {
        $invoiced = "Yes";
    }
    else {
        $invoiced = "";
    }

    #Add an extra condition to filter 'Invoiced' input field only if $invoiced is not empty string, either 'Yes' or 'No'
    if ($invoiced) {
        $conditions .= " AND IWR.Invoiceable_Work_Reference_Invoiced = '$invoiced' ";
    }

    my $group_by            = 'IW.Invoiceable_Work_ID';
    my $additional_ordering = ' ,IW.Invoiceable_Work_DateTime';    # by default must order by grouping field

    # adapt breakout for source, addition of fields, tables, and conditions etc...

    if ($source_list) {
        $grouping_field = "ChildSource.Source_ID";

        my @src_additional_fields = (
            'GROUP_CONCAT(DISTINCT Li.FK_Project__ID) AS Project',
            'GROUP_CONCAT(DISTINCT IWR.FKApplicable_Funding__ID) AS SOW',
            'GROUP_CONCAT(DISTINCT Li.Library_Name) AS Library',
            'GROUP_CONCAT(DISTINCT  (CASE WHEN IP.Invoiceable_Prep_ID > 0 THEN Li.Library_Description END)) AS Lib_Description',
            'GROUP_CONCAT(DISTINCT (CASE WHEN IP.Invoiceable_Prep_ID > 0 THEN Li.Library_Status END)) AS Lib_Status',
            'GROUP_CONCAT(DISTINCT (CASE WHEN IP.Invoiceable_Prep_ID > 0 THEN Li.Library_Completion_Date END)) AS Lib_Completed'
        );
        unshift( @fields, @src_additional_fields );

        $conditions .= " AND ChildSource.Source_ID IN ($keys)";
        $additional_ordering = ', Li.Library_Name' . $additional_ordering;
    }
    else {
        unshift( @fields, 'GROUP_CONCAT(DISTINCT IWR.FKApplicable_Funding__ID) AS SOW' );

        #only show directly invoiceable_work...
        $conditions .= "  	
        	AND Li.Library_Name IN ($keys)";
    }

    $conditions .= " AND $extra_condition" if $extra_condition;

    my $tables = $base_tables . $join_tables;
    my %results = $dbc->Table_retrieve( $tables, [ $grouping_field, @fields, ], "WHERE $conditions GROUP BY $group_by ORDER BY $grouping_field $additional_ordering" );

    # data should be ordered by grouping field before being passed into merge data for grouping
    return alDente::View::merge_data_for_table_column( %args, -dbc => $dbc, -data_hash => \%results, -key_list => \@key_list, -grouping_field => $grouping_field, -field_order => \@fields, -total_columns => 'All_Reads, Reads_Excluding_No_Grows' );
}

1;
