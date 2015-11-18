###################################################################################################################################
# alDente::QC_Batch_Views.pm
#
# View methods for QC_Batch functionality
#
#
###################################################################################################################################
package alDente::QC_Batch_Views;

use strict;
use CGI qw(:standard);
use LampLite::Bootstrap;

##
use alDente::Tools;
use alDente::QC_Batch;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use vars qw(%Configs );
my $BS = new Bootstrap;

#
# QC Batch home page (no batch currently defined)
#
#
#
#################
sub home_page {
#################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $page = '<h2>QC Batch home page</h2>';
    $page .= $dbc->Table_retrieve_display(
        'QC_Batch,QC_Batch_Type,QC_Batch_Member', [ 'FK_QC_Batch__ID', 'FK_QC_Batch_Type__ID', 'QC_Batch_Number', 'Batch_Count as Items', 'QC_Batch_Initiated as Defined', 'FK_Employee__ID as Defined_By', 'QC_Batch_Status as Status', 'QC_Batch_Notes' ],
        "WHERE FK_QC_Batch_Type__ID = QC_Batch_Type_ID AND FK_QC_Batch__ID=QC_Batch_ID AND QC_Batch_Status != 'Expired' AND QC_Member_Status NOT IN ('Rejected','Released') GROUP BY QC_Batch_ID",
        -title       => 'Currently unresolved QC Batches',
        -alt_message => 'No currently unresolved QC Batches',
        -return_html => 1
    );

    $page .= '<hr>';

    $page .= create_tree( -tree => { 'New QC Batch' => new_Batch_form($dbc) } );
    $page .= create_tree( -tree => { 'QC Report'    => new_Report($dbc) } );

	## display admin functions for QC admins
    my $access = $dbc->get_local('Access');
    if ( ( grep {/Admin/xmsi} @{ $access->{$Current_Department} } ) || $access->{'LIMS Admin'} ) {
    	$page .= create_tree( -tree => {'QC_Batch_Type Maintenance( Admin Only )' => maintain_QC_Batch_type( -dbc => $dbc ) } );
    }

    return $page;
}

########################
sub new_Batch_form {
########################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $new = '<h2>Define New QC Batch</h2>';
    $new .= alDente::Form::start_alDente_form( -dbc => $dbc );    # 'qc_batch');
    $new .= hidden( -name => 'cgi_application', -value => 'alDente::QC_Batch_App', -force => 1 );

    ## automatically fill Batch_Name based upon Catalog or Stock Name chosen (and append with lot number if specified) ##
    my $Cat_onchange       = "SetSelection(this.form,'QC_By','By Catalog Number', 'By Catalog Number');";
    my $Stock_onchange     = "SetSelection(this.form,'QC_By','By Stock','By Stock');";
    my $untracked_onchange = "SetSelection(this.form,'QC_By','Untracked','Untracked');";
    my $class_onchange     = "SetSelection(this.form,'QC_By','By ID','By ID');";

    my $cat_option
        = 'Catalog Number:<BR>'
        . textfield( -name => 'Catalog_Number', -id => 'catnum', -size => 20, -force => 1, -onchange => $Cat_onchange )
        . '<BR>Lot Number (optional):<BR>'
        . textfield( -name => 'Cat_Lot_Number', -size => 20, -force => 1 )
        . '<BR>Received Since:<BR>'
        . textfield( -name => 'Cat_Received_Since', -id => 'Cat_Received_Since', -onclick => $BS->calendar( -id => 'Cat_Received_Since', -step => 1 ) )
        . '<BR>Received Until:<BR>'
        . textfield( -name => 'Cat_Received_Until', -id => 'Cat_Received_Until', -onclick => $BS->calendar( -id => 'Cat_Received_Until', -step => 1 ) );

    #			   . alDente::Tools::search_list(-dbc=>$dbc,-name=>'Stock.Stock_Received');

    #	   my @valid_items = $dbc->get_FK_info('FK_Stock_Catalog__ID',-list=>1,-join_tables=>'Object_Class',-join_condition=>'

    my $stock_option = 'Stock Item:<BR>'
        . alDente::Tools::search_list(
        -dbc            => $dbc,
        -name           => 'FK_Stock_Catalog__ID',
        -join_tables    => 'Object_Class',
        -join_condition => 'Stock_Type=Object_Class',
        -filter         => 1,
        -search         => 1,
        -id             => 'Stock',
        -onchange       => $Stock_onchange
        )
        . '<BR>Lot Number (optional):<BR>'
        . textfield( -name => 'Stock_Lot_Number', -size => 20, -force => 1 )
        . '<BR>Received Since:<BR>'
        . textfield( -name => 'Lot_Received_Since', -id => 'Lot_Received_Since', -onclick => $BS->calendar( -id => 'Lot_Received_Since', -step => 1 ) )
        . '<BR>Received Until:<BR>'
        . textfield( -name => 'Lot_Received_Until', -id => 'Lot_Received_Until', -onclick => $BS->calendar( -id => 'Lot_Received_Until', -step => 1 ) );

    my $ids_option
        = 'Class:<BR>'
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Object_Class__ID', -onchange => $class_onchange )
        . '<BR>ID List:<BR>'
        . Show_Tool_Tip( textfield( -name => 'Batch_IDs', -size => 20, -force => 1, -onclick => $class_onchange ), "Scan items or enter IDs.  Range values ok (eg '34-45' or 'Pla34-Pla45')" );

    my @untracked_list = $dbc->get_FK_info( -field => 'FK_Stock_Catalog__ID', -condition => "Stock_Type = 'Untracked'", -list => 1 );

    my $untracked_option;
    if (@untracked_list) {
        my $local_org = 27;        ## <custom> .. remove
        my $new_link  = Link_To(
            $dbc->homelink(),
            ' add type',
            '&cgi_application=SDB::DB_Form_App&rm=New+Record&Auto=1&Table=Stock_Catalog&Grey=Stock_Type,Stock_Source,Stock_Status,Stock_Size,Stock_Size_Units,FK_Organization__ID,FKVendor_Organization__ID'
                . "&Stock_Type=Untracked&Stock_Source=Made in House&Stock_Status=Active&Stock_Size=0&Stock_Size_Units=n/a&FK_Organization__ID=$local_org&FKVendor_Organization__ID=$local_org"
        );
        $untracked_option = 'Untracked Item: ' . $new_link . '<BR>' . Show_Tool_Tip(
            popup_menu( -name => 'Untracked', -values => [ '', @untracked_list ], -default => '', -force => 1, -onclick => $untracked_onchange ),

            #		     alDente::Tools::search_list(-dbc=>$dbc, -name=>'Untracked', -list=> \@untracked_list, -option_condition=>"Stock_Type = 'Untracked'", -onchange=>$untracked_onchange),
            'Select this option if you are QCing items that are not otherwise barcoded or tracked within the LIMS'
            )
            . '<BR>Using Solution/Reagent ID:<BR>'
            . Show_Tool_Tip( textfield( -name => 'FK_Solution__ID', -size => 20, -default => '', -force => 1 ), ' <- enter Solution_ID if applicable (optional)<BR>' )
            . '<BR>Items in Batch: '
            . textfield( -name => 'Count', - value => '', -size => 5 );
    }

    my $options = new HTML_Table( -border => 5 );
    $options->Set_Headers(
        [ radio_group( -name => 'QC_By', -value => 'By Catalog Number' ), radio_group( -name => 'QC_By', -value => 'By Stock' ), radio_group( -name => 'QC_By', -value => 'By ID' ), radio_group( -name => 'QC_By', -value => 'Untracked' ) ] );
    $options->Set_Row( [ $cat_option, $stock_option, $ids_option, $untracked_option ] );

    $new .= $options->Printout(0);
    $new .= '<p ></p>';

    $new .= "QC Batch Type: "
        . alDente::Tools::search_list(
        -dbc    => $dbc,
        -name   => 'FK_QC_Batch_Type__ID',
        -breaks => 1,
        -width  => 80,
        -mode   => 'Popup',
        -force  => 1,
        );
    $new .= "<validator  name='FK_QC_Batch_Type__ID'  mandatory='1' prompt='QC Batch Type'> </validator>";    ## make FK_QC_Batch_Type__ID mandatory ##

    $new .= submit( -name => 'rm', -value => 'Add QC Batch', -onclick => "return validateForm(this.form,0)", -class => 'Action' );    # -onclick=>"requireFill(this.form, 'QC_Batch_Name','','new_batch')");
    $new .= '<P>Notes:<BR>' . textarea( -name => 'QC_Batch_Comments', -rows => 3, -columns => 75 );

    $new .= end_form();

    return $new;
}

###############################################
#
# Home page for a previously defined QC Batch
#
#
###################
sub Batch_home {
###################
    my %args     = filter_input( \@_, -args => 'dbc,batch', -mandatory => 'dbc,batch' );
    my $dbc      = $args{-dbc};
    my $batch_id = $args{-batch};

    my %info = $dbc->Table_retrieve(
        'QC_Batch,QC_Batch_Type',
        [ 'QC_Batch_Type_Name', 'QC_Batch_Number', 'QC_Batch_Initiated', 'QC_Batch_Status', 'FK_Employee__ID', 'QC_Batch_Notes' ],
        "WHERE FK_QC_Batch_Type__ID = QC_Batch_Type_ID and QC_Batch_ID = $batch_id"
    );
    my $name      = $info{QC_Batch_Type_Name}[0];
    my $number    = $info{QC_Batch_Number}[0];
    my $status    = $info{QC_Batch_Status}[0];
    my $initiated = $info{QC_Batch_Initiated}[0];
    my $emp       = alDente_ref( 'Employee', $info{FK_Employee__ID}[0], -dbc => $dbc );
    my $notes     = $info{QC_Batch_Notes}[0];

    my $member_status = join ',', $dbc->Table_find( 'QC_Batch_Member', 'QC_Member_Status', "WHERE FK_QC_Batch__ID = $batch_id", -distinct => 1 );

    my $page = "<h2>QC Batch $batch_id: ($status)</h2>";
    $page .= "<h2><u>$name #$number</u></h2>";
    $page .= "(initiated $initiated by $emp)";
    $page .= "<h2>Members $member_status</h2>";

    $page .= "Notes: $notes<P>";
    $page .= Link_To( $dbc->config('homelink'), '[Edit details]', "&Search=1&Table=QC_Batch&Search+List=$batch_id" ) . '<P>';

    $page .= alDente::Form::start_alDente_form( $dbc, 'qc_batch' ) . hidden( -name => 'cgi_application', -value => 'alDente::QC_Batch_App', -force => 1 );

    if ($batch_id) { $page .= hidden( -name => 'Batch_ID', -value => $batch_id, -force => 1 ) }

    $page .= batch_details( $dbc, $batch_id );

    $page .= Show_Tool_Tip( textfield( -name => 'Comments', -size => 40, -default => '', -force => 1 ), 'Include any comments you like relating to this status change' );
    $page .= '<p ></p>';
    $page .= "<validator  name='Comments'  mandatory='1' prompt=>'QC Update Comments'> </validator>";

    if ( $status eq 'Passed' ) {
        $page .= QC_button('Re-Test');
        $page .= '<hr>';
        $page .= QC_button('Release');
    }
    elsif ( $status eq 'Failed' ) {
        $page .= QC_button('Re-Test');
        $page .= '<hr>';
        $page .= QC_button('Release') . hspace(10) . QC_button('Reject');
    }
    elsif ( $status eq 'Pending' ) {
        $page .= QC_button('Pass');
        $page .= &hspace(10);
        $page .= QC_button('Fail');
        $page .= &hspace(10);
        $page .= QC_button('Set Expired');
    }
    elsif ( $status eq 'Re-Test' ) {
        $page .= QC_button('Pass');
        $page .= &hspace(10);
        $page .= QC_button('Fail');
        $page .= &hspace(10);
        $page .= QC_button('Set Expired');
    }
    elsif ( $status eq 'Expired' ) {
        $page .= QC_button('Re-Test');
    }
    else {
        $page .= "Status: $status unrecognized";
    }

    #    $page .= '<p ></p>' . QC_button('Review History for','Search');
    $page .= end_form();
    return $page;
}

#######################
sub batch_details {
#######################
    my $dbc      = shift;
    my $batch_id = shift;

    my $individuals = 1;

    my $page;

    if ($individuals) {
        my ($class) = $dbc->Table_find( 'QC_Batch_Member,QC_Batch,Object_Class', 'Object_Class', "WHERE FK_QC_Batch__ID = QC_Batch_ID AND FK_Object_Class__ID=Object_Class_ID AND QC_Batch_ID = $batch_id" );
        if ( !$class ) { Message("Class undefined"); return }

        if ( $class eq 'Untracked' ) {
            $page .= $dbc->Table_retrieve_display(
                "QC_Batch_Member,QC_Batch", [ 'FK_Object_Class__ID as Class', 'FK_Solution__ID as Solution', 'QC_Batch_Initiated', 'QC_Member_Status as QC_Status', 'Batch_Count as Items' ],
                "WHERE FK_QC_Batch__ID = QC_Batch_ID AND QC_Batch_ID = $batch_id",
                -title       => 'QC Batch Members',
                -return_html => 1
            );
        }
        else {
            my @fields = ( 'FK_Object_Class__ID as Class', "$class.${class}_ID", "${class}_Status as Status", 'QC_Member_Status as Member_Status' );

            if ( alDente::QC_Batch::local_QC_tracking( -dbc => $dbc, -class => $class ) ) { push @fields, 'QC_Status' }

            my ($location_field) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$class' and (Field_Name like 'FK%_Rack__ID' OR Field_Name like 'FK%Location__ID' OR Field_Name like 'FK%_Site__ID')" );
            if ($location_field) { push @fields, "$class.$location_field as Location" }

            $page .= $dbc->Table_retrieve_display(
                "QC_Batch_Member,QC_Batch,$class", \@fields, "WHERE $class.${class}_ID = Object_ID AND FK_QC_Batch__ID = QC_Batch_ID AND QC_Batch_ID = $batch_id",
                -title       => 'QC Batch Members',
                -return_html => 1
            );
        }
    }
    else {
        $page .= $dbc->Table_retrieve_display(
            'QC_Batch_Member,QC_Batch', [ 'Batch_Count as Items', 'FK_Object_Class__ID', 'Min(Object_ID) as Min_ID', 'Max(Object_ID) as Max_ID', 'QC_Member_Status as Status' ],
            "WHERE FK_QC_Batch__ID = QC_Batch_ID AND QC_Batch_ID = $batch_id GROUP BY QC_Member_Status",
            -title       => 'QC Batch Members',
            -return_html => 1
        );
    }
    $page .= '<hr>';
    my $history = $dbc->Table_retrieve_display(
        'Change_History,DBField', [ 'Field_Name', 'Old_Value as Changed_From', 'New_Value as Changed_To', 'Modified_Date as Changed_On', 'FK_Employee__ID as Changed_By', 'Comment' ],
        "WHERE FK_DBField__ID=DBField_ID AND (Field_Name = 'QC_Batch_Status' OR Field_Name = 'QC_Member_Status') AND Record_ID = $batch_id ORDER BY Changed_On",
        -title       => "History of QC Status updates for Batch $batch_id",
        -return_html => 10
    );

    $page .= create_tree( -tree => { 'History' => $history } );

    return $page;
}

#######################
sub confirm_Batch {
#######################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $ids        = $args{-ids};
    my $class      = $args{-class};
    my $name       = $args{-name};
    my $comments   = $args{-comments};
    my $catalog_id = $args{-catalog_id};
    my $search_by  = $args{-search_by};

    my $page;

    my $tables    = "$class,Stock,Stock_Catalog";
    my $condition = "WHERE Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID AND $class.FK_Stock__ID=Stock_ID AND ${class}_ID IN ($ids)";

    my %Stock_catalog_options = $dbc->Table_retrieve( $tables, [ 'Stock_Catalog_ID', "Group_Concat(${class}_ID) as IDs" ], "$condition GROUP BY Stock_Catalog_ID" );
    my $options = int( @{ $Stock_catalog_options{Stock_Catalog_ID} } );

    if ( $options > 1 ) {
        $dbc->session->warning("Found $options options - You can only choose one of these potential options below to treat as as single batch");
        $page .= '<p ></p>';
    }

    my $i = 0;
    while ( $Stock_catalog_options{Stock_Catalog_ID}[$i] ) {
        my $stock_cat = $Stock_catalog_options{Stock_Catalog_ID}[$i];
        my $ids       = $Stock_catalog_options{IDs}[$i];
        $i++;

        my $display = $dbc->Table_retrieve_display(
            "$class,Stock,Stock_Catalog",
            [   'Stock_ID',
                'FK_Stock_Catalog__ID as Item',
                'Stock_Received',
                'Count(*) as Items',
                'Stock_Catalog_Number as Catalog_No',
                'Stock_Lot_Number as Lot_No',
                'FK_Organization__ID',
                "Min(${class}_ID) as First_Barcode",
                "Max(${class}_ID) as Last_Barcode"
            ],
            "$condition AND Stock_Catalog_ID = $stock_cat GROUP BY Stock_ID",
            -selectable_field => 'Stock_ID',
            -return_html      => 1,
            -total_columns    => 'Items'
        );

        $page .= alDente::Form::start_alDente_form( $dbc, 'confirm_qc_batch' );
        $page .= $display;

        $page
            .= hidden( -name => 'cgi_application',     -value => 'alDente::QC_Batch_App', -force => 1 )
            . hidden( -name  => 'Batch_IDs',           -value => $ids,                    -force => 1 )
            . hidden( -name  => 'FK_Object_Class__ID', -value => $class,                  -force => 1 )
            . hidden( -name  => 'Stock_Catalog_ID',    -value => $stock_cat,              -force => 1 )
            . hidden( -name  => 'QC_Batch_Type_Name',  -value => $name,                   -force => 1 )
            . hidden( -name  => 'QC_Batch_Comments',   -value => $comments )
            . hidden( -name  => 'Confirmed',           -value => 1,                       -force => 1 )
            . hidden( -name  => 'QC_By',               -value => $search_by,              -force => 1 );

        $page .= submit( -name => 'rm', -value => 'Confirm QC Batch', -class => 'Action', -force => 1 );
        $page .= end_form();
    }

    $page .= "<P>";
    $page .= '<P>... or try adjusting options again below:';
    $page .= '<hr>';
    $page .= new_Batch_form($dbc);

    return $page;
}

######################
sub view_History {
######################
    my $dbc   = shift;
    my $Batch = shift;

    print HTML_Dump $Batch;

    return "History of Batch...";
}

#
#
#
#

####################
sub QC_button {
####################
    my $action = shift;
    my $class = shift || 'Action';

    my $validate;
    if ( $action !~ /Pass/ ) { $validate = "return validateForm(this.form,0)" }

    return Show_Tool_Tip( submit( -name => 'rm', -value => "$action QC Batch", -class => $class, -onclick => $validate ), "$action QC for all items in this Batch" );
}

###################
sub new_Report {
###################
    my $dbc = shift;

    my $page = alDente::Form::start_alDente_form( $dbc, 'report' );
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::QC_Batch_App', -force => 1 );
    $page .= '<P>Batch Type: ' . alDente::Tools::search_list( -dbc => $dbc, -mode => 'scroll', -table => 'QC_Batch', -field => 'FK_QC_Batch_Type__ID', -filter => 1, -search => 1 );
    $page .= '<P>Status: ' . alDente::Tools::search_list( -dbc => $dbc, -mode => 'checkbox', -table => 'QC_Batch', -field => 'QC_Batch_Status' );
    $page .= '<P>Member Status: ' . alDente::Tools::search_list( -dbc => $dbc, -mode => 'checkbox', -table => 'QC_Batch_Member', -field => 'QC_Member_Status', -default => '' );    # Released,Quarantined,Rejected');
    $page .= '<P>Manufacturer: '
        . alDente::Tools::search_list( -dbc => $dbc, -join_tables => 'Stock_Catalog,QC_Batch', -join_condition => 'Stock_Catalog.FK_Organization__ID=Organization_ID AND FK_Stock_Catalog__ID=Stock_Catalog_ID', -field => 'FK_Organization__ID' );
    $page
        .= '<P>Received between '
        . textfield( -name => 'Since', -id => 'Received_Since', -onclick => $BS->calendar( -id => 'Received_Since', -step => 1 ) ) . ' and '
        . textfield( -name => 'Until', -id => 'Received_Until', -onclick => $BS->calendar( -id => 'Received_Until', -step => 1 ) );

    $page .= '<P>Search comments for string: ' . textfield( -name => 'Comment_String', -size => 40 );

    $page .= '<p ></p>' . submit( -name => 'rm', -value => 'Generate QC Report', -class => 'Search' );
    $page .= '<p ></p>' . 'Group By: ' . radio_group( -name => 'Group_By', -values => [ 'QC_Batch_ID', 'Name', 'Month', 'Status' ], -default => 'Name', -force => 1 );
    $page .= end_form();

    return $page;
}

#########################
sub display_Report {
#########################
    my %args         = filter_input( \@_, -args => 'dbc,name,manufacturer' );
    my $dbc          = $args{-dbc};
    my $name         = Cast_List( -list => $args{-name}, -to => 'string', -autoquote => 1 );
    my $manufacturer = $args{-manufacturer};
    my $since        = $args{-since};
    my $until        = $args{ -until };
            my $condition = $args{-condition} || 1;
            my $group     = $args{-group}     || 'QC_Batch_Type_ID';
            my $status = Cast_List( -list => $args{-status}, -to => 'string', -autoquote => 1 );
    my $member_status = Cast_List( -list => $args{-member_status}, -to => 'string', -autoquote => 1 );
    my $comments = $args{-comments};

    my $report = "<H2>QC Batch Report</H2>";
    if ($name) {
        $report    .= "Batch Type: $name<P>";
        $condition .= " AND QC_Batch_Type_Name IN ($name)";
    }

    #    $report .= "Manufacturer: $manufacturer<P>";
    if ( $since || $until ) {
        $report .= "Date Range: $since .. $until<P>";
        if ($since) { $condition .= " AND QC_Batch_Initiated > '$since'" }
        if ($until) { $condition .= " AND QC_Batch_Initiated < '$until'" }
    }

    if ($status) {
        $report    .= "Status: $status<P>";
        $condition .= " AND QC_Batch_Status IN ($status)";
    }
    if ($comments) {
        $report    .= "Comment string: *$comments*<P>";
        $condition .= " AND QC_Batch_Notes LIKE '%$comments%'";
    }
    if ($manufacturer) {
        Message("Manufacturer not included in report at this stage - if needed request upgrade from LIMS team");
    }

    my $tables = 'QC_Batch,QC_Batch_Type';
    my @fields = (
        'Count(*) as Batch_Count',
        $group,
        'Sum(Batch_Count) as Total_Items',
        'Min(QC_Batch_Number) as First_Batch',
        'Min(QC_Batch_Initiated) as First_Batch_Started',
        'Max(QC_Batch_Number) as Last_Batch',
        'Max(QC_Batch_Initiated) as Last_Batch_Started',
        'QC_Batch_Status'
    );
    if ($member_status) {
        $report    .= "Batch Member Status: $status<P>";
        $condition .= " AND QC_Member_Status IN ($member_status)";
        $tables    .= ' LEFT JOIN QC_Batch_Member ON FK_QC_Batch__ID=QC_Batch_ID';
        @fields = (
            'Count(Distinct QC_Batch_ID) as Batch_Count',
            $group,
            'Min(QC_Batch_Number) as First_Batch',
            'Min(QC_Batch_Initiated) as First_Batch_Started',
            'Max(QC_Batch_Number) as Last_Batch',
            'Max(QC_Batch_Initiated) as Last_Batch_Started',
            'QC_Batch_Status',
            'Group_Concat(QC_Member_Status) as Member_Status',
            'Group_Concat(Distinct QC_Member_Status) as Member_Status'
        );    ## remove item count if including Batch_Member records
    }

    #$group =~s/ as \w+//i;  ## clear label for group specification
    $report .= $dbc->Table_retrieve_display(
         $tables, \@fields, "WHERE FK_QC_Batch_Type__ID = QC_Batch_Type_ID AND $condition",
        -group       => $group,
        -regroup     => 'QC_Batch_ID AS QC_Batch',
        -title       => 'Retrieved QC_Batch Records',
        -return_html => 1
    );

    return $report;
}

sub maintain_QC_Batch_type {
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    #my $page = '<h2>Maintain QC Batch Type</h2>';
    my $page = '<BR>';
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc );   
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::QC_Batch_App', -force => 1 );

    my $format = $dbc->get_field_format( -field => 'QC_Batch_Type_Name', -table => 'QC_Batch_Type'); 

    $page .= 'QC Batch Type Name: ' . textfield( -name => 'New_QC_Batch_Type_Name', -id => 'New_QC_Batch_Type_Name', -size => 50 );
    $page .= set_validator( -name=>'New_QC_Batch_Type_Name', -format => $format, -mandatory => 1, -prompt => "Please enter a valid QC_Batch_Type_Name (Maximum 80 characters)" );
    $page .= submit( -name => 'rm', -value => 'Add QC Batch Type', -onclick => "return validateForm(this.form,0,'','New_QC_Batch_Type_Name')", -class => 'Action' );

    my $qc_batch_type_spec =  "<BR><BR>Choose a QC Batch Type: "
        . alDente::Tools::search_list(
        -dbc    => $dbc,
        -name   => 'FK_QC_Batch_Type__ID',
        -breaks => 1,
        -width  => 80,
        -mode   => 'Popup',
        -force  => 1,
        );
    my $change_button = submit( -name => 'rm', -value => 'Change Name', -onclick => "validateForm(this.form,0,'','FK_QC_Batch_Type__ID'); return validateForm(this.form,0,'','Revised_QC_Batch_Type_Name');", -class => 'Action' );
    my $revised_name_spec = textfield( -name => 'Revised_QC_Batch_Type_Name', -id => 'Revised_QC_Batch_Type_Name', -size => 50 );
    my $delete_button = submit( -name => 'rm', -value => 'Delete', -onclick => "validateForm(this.form,0,'','FK_QC_Batch_Type__ID');", -class => 'Action' );
	my $table = HTML_Table->new();
	$table->Set_Row( [$qc_batch_type_spec, $change_button, $revised_name_spec ] );
	$table->Set_Row( ['', $delete_button, '' ] );
	$page .= $table->Printout(0);

    $page .= set_validator( -name => 'FK_QC_Batch_Type__ID', -mandatory => 1,-prompt => "Please select an existing QC Batch Type to edit" );
    $page .= set_validator( -name => 'Revised_QC_Batch_Type_Name',-format => $format, -mandatory => 1,-prompt => "Please enter a valid QC_Batch_Type_Name (Maximum 80 characters)" );

    $page .= end_form();
    return $page;
}

return 1;
