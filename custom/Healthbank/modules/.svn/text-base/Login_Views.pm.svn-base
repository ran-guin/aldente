###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package Healthbank::Login_Views;

use base alDente::Login_Views;

use strict;

## Standard modules ##
use LampLite::CGI;
use LampLite::Bootstrap();

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

use RGTools::RGIO;
use RGTools::Views;

use LampLite::HTML;

use Healthbank::Menu;
use Healthbank::Model;

############## 
sub relogin {
##############
    my $self = shift;
    my %args = @_;
    return $self->SUPER::relogin(%args);
}

# Return: customized footer spec
#############
sub footer {
#############
     my $self = shift;   
    return; 
}

#
# custom login page (may call standard login page with extra sections appended)
#
# CUSTOM - move app to same level (not SDB::Session)
#############################################################
#
#
#
# Return: html page
#############################################################
sub display_Login_page {
#############################################################
    my $self     = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->param('dbc');

    my @login_extras;
    my $other_versions = $self->aldente_versions( -dbc => $dbc );
    push @login_extras, ['Other Versions:', $other_versions];
    
    my $page = $self->SUPER::display_Login_page(%args, -append=>\@login_extras, -app=>'Healthbank::Login_App', -clear=>['Database_Mode', 'CGISESSID'], -title=>"Log into BC Generations");

    return "<center><div style='max-width:500px'>\n$page</div></center>\n"
}

#############################################################
#
# Move to Healthbank scope ... 
#
#############################################################
sub aldente_versions {
#############################################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $dbc            = $args{-dbc} || $self->param('dbc');

    my $other_versions = '';

    my $master = 'hblims01';
    my $dev    = 'hblims01';
    my $domain = '.bcgsc.ca';
    
    my $Target = {
        'Production' => "http://$master$domain/SDB/cgi-bin/barcode.pl?Database_Mode=PRODUCTION",
        'Test' => "http://$master$domain/SDB_test/cgi-bin/barcode.pl?Database_Mode=TEST",
        'Alpha' => "http://$dev$domain/SDB_alpha/cgi-bin/alDente.pl?Database_Mode=DEV",
        'Beta' => "http://$master$domain/SDB_beta/cgi-bin/alDente.pl?Database_Mode=BETA",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/alDente.pl?Database_Mode=DEV",    
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

#
# Custom page to show Onyx formatting and to provide simple user tools (eg decode or encode Onyx codes)
#
#####################
sub onyx_home_page {
#####################
    my $dbc = shift;
    my $page = "<h3>Onyx Barcoding</h3>";

    my $img = "<IMG SRC='/SDB_alpha/images/help_images/Onyx_Barcodes.png'> </IMG>\n";

    my $Onyx_Code = Healthbank::onyx_formats();
    
    my $table = new HTML_Table(-title=>'Onyx Formats for Sample Type', -width=>'100%');
    $table->Set_Headers(['Code','Format','Volume','Content', 'Number']);
   
    my @formats = sort keys %$Onyx_Code;
    
    foreach my $format (@formats) {
        my $desc = $Onyx_Code->{$format}{Format};
        my $volume = $Onyx_Code->{$format}{Volume};
        my $content = $Onyx_Code->{$format}{Content};
        my $count = $q->textfield(-name=>"$format-count", -size=>4);
        
        $table->Set_Row([$format, $desc, $volume, $content, $count]);
    }

    my $format_block = alDente::Form::start_alDente_form($dbc,'decode_onyx');
    $format_block .=  $q->hidden(-name=>'cgi_application', -value=>'Healthbank::App', -force=>1); 
    $format_block .= $q->textarea(-name=>'Onyx_Barcode', -size=>500, -class=>'superwide-txt');
    $format_block .= $q->submit(-name=>'rm', -value=>'Decrypt Onyx Barcode', -class=>'Srch', -onclick=>'return validateForm(this.form)'); 
    $format_block .= set_validator(-name=>'Onyx_Barcode', -mandatory=>1);
    $format_block .= $q->end_form();
  
    $format_block .= '<hr>';

    $format_block .= '<h3>Generate your own Onyx Barcode</h3>';

    $format_block .= alDente::Form::start_alDente_form($dbc,'encode_onyx');
    $format_block .=  $q->hidden(-name=>'cgi_application', -value=>'Healthbank::App', -force=>1); 
    $format_block .= 'Project: ' . $q->radio_group(-name=>'Project', -values=>['BC','SHE']) . '<BR>';
    $format_block .= 'Subject: ' . $q->textfield(-name=>'Subject', -size=>50) . '<BR>';

    $format_block .= $table->Printout(0);
    $format_block .= $q->submit(-name=>'rm', -value=>'Generate Onyx Barcode', -class=>'Srch', -onclick=>'return validateForm(this.form)');
    $format_block .= set_validator(-name=>'Subject', -mandatory=>1, -format=>'^\d{6}$', -prompt=>'Subject must be 6 digits');
    $format_block .= $q->end_form();

    $page .= $BS->row( [ $img, $format_block ], [6,6] );

    $table->Printout(0);

    return $page

}
    
##########################
sub show_discrepencies {
##########################

}

##################
sub _admin_page {
##################
    my %args = filter_input(\@_, -args=>'dbc,condition');
    my $dbc = $args{-dbc};
    my $extra_condition = $args{-condition} || 1;

    my $tables    = 'Plate,Plate_Sample,Sample,Source,Original_Source,Patient';
    my $condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $extra_condition";

    my $yesterday = $dbc->Table_retrieve_display(
        $tables, [ 'Plate.FK_Plate_Format__ID', 'Plate.FK_Sample_Type__ID', 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct Original_Source_Name) as Subjects' ],
        "$condition AND Plate.Plate_Status = 'Active' AND Plate_Created >= SUBDATE(CURDATE(), INTERVAL 1 Day) AND Plate_Created < CURDATE() GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Samples Generated Yesterday',
        -total_columns => 'Active_Tubes',
        -return_html   => 1
    );

    my $today = $dbc->Table_retrieve_display(
        $tables, [ 'Plate.FK_Plate_Format__ID', 'Plate.FK_Sample_Type__ID', 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct Original_Source_Name) as Subjects' ],
        "$condition AND Plate.Plate_Status = 'Active' AND Plate_Created >= CURDATE() GROUP BY Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID",
        -title         => 'Samples Generated Yesterday',
        -total_columns => 'Active_Tubes',
        -return_html   => 1
    );

    my $collected = $dbc->Table_retrieve_display(
        'Source, Original_Source, Patient',
        [   'Source.FK_Plate_Format__ID as Format',
            'count(DISTINCT Source_ID) as Collected',
            'count(DISTINCT Patient_Identifier) AS Subjects',
            'Min(Patient_Identifier) AS First_Subject',
            'Max(Patient_Identifier) AS Last_Subject'
        ],
        "WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $extra_condition GROUP BY Source.FK_Plate_Format__ID",
        -title         => 'Blood Samples Originally Collected',
        -total_columns => 'Collected,Subjects',
        -return_html   => 1
    );

    my $output = $collected;

    $output .= '<hr>';

    $output .= '<p ></p>';
    $output .= Link_To( $dbc->homelink(), ' View Discrepencies (slow)', '&cgi_application=BC_Generations::Department_App&rm=Missing Samples' );
    $output .= '<p ></p>';

    $output .= create_tree( -tree => { ' Generated as of Yesterday' => $yesterday } );
    $output .= create_tree( -tree => { ' Generated Today'           => $today } );
    $output .= '<hr>';

    $output .= '<p ></p>' . alDente::Form::start_alDente_form($dbc, 'backfill') . hidden( -name => 'cgi_application', -value => 'Healthbank::App', -force => 1 );
    $output .= 'Check ' . textfield( -name => 'Times', -size => 5, -default => 1 ) . 'Subjects; Starting at #' . textfield( -name => 'Start', -size => 5, -default => '' );
    $output .= submit( -name => 'rm', -value => 'Backfill Check', -class => 'Search', -force => 1 );
    $output .= end_form();

    $output .= '<HR>';
    $output .= Link_To( $dbc->homelink(), 'Fix EDTA WBC, Plasma Locations', '&cgi_application=Healthbank::App&rm=Fix EDTA' );

    $output .= '<HR>';
    $output .= Link_To( $dbc->homelink(), 'View Service Centres', '&cgi_application=SDB::DB_Form_App&rm=View+Lookup&Table=Service_Centre' );
    return $output;
}

#########################
sub view_discrepencies {
#########################
    my $dbc = shift;
    my $output;

    my $tables    = 'Plate,Plate_Sample,Sample,Source,Original_Source';
    my $condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID";

    my $Format   = { 'ACD' => 1, 'SST'  => 2, 'EDTA' => 3, 'Urine' => 4 };
    my $Expected = { 'ACD' => 1, 'EDTA' => 3, 'SST'  => 2, 'Urine' => 1 };

    my %C_layers;
    foreach my $type ( keys %{$Format} ) {
        my $collection_differences = $dbc->Table_retrieve_display(
            $tables . " LEFT JOIN Source AS $type ON $type.FK_Original_Source__ID = Source.FK_Original_Source__ID AND $type.FK_Plate_Format__ID=$Format->{$type}",
            [ 'Left(Source.External_Identifier,8) as Subject', "count(distinct $type.Source_ID) as $type" ],
            "$condition Group by Source.FK_Original_Source__ID"
                . " Having Count(distinct $type.Source_ID)/$Expected->{$type} < 1",
            -title       => 'Missing Blood Collection',
            -return_html => 1
        );

        $C_layers{$type} = $collection_differences;
    }
    my $layered_C_differences = define_Layers( -layers => \%C_layers );
    $output .= '<h2>Blood Collection Discrepencies</h2>' . $layered_C_differences;

    my $Sample = { 'WBC' => 7, 'RBC' => 6, 'Serum' => 5, 'Plasma' => 10, 'Urine' => 8 };
    $Expected = { 'WBC' => 3, 'RBC' => 3, 'Serum' => 3, 'Plasma' => 3, 'Urine' => 1 };

    my %layers;
    foreach my $type ( keys %{$Sample} ) {
        my $type_differences = $dbc->Table_retrieve_display(
            $tables . " LEFT JOIN Plate AS $type ON $type.FKOriginal_Plate__ID=Plate.Plate_ID AND $type.FK_Sample_Type__ID=$Sample->{$type} AND $type.Plate_Status = 'Active'",
            [ 'Left(External_Identifier,8) as Subject', "count(distinct $type.Plate_ID) as $type" ],
            "$condition Group by Left(External_Identifier,8) "
                . " Having Count(distinct $type.Plate_ID)/$Expected->{$type} < 1",
            -title       => "Missing $type Samples",
            -return_html => 1
        );

        $layers{$type} = $type_differences;
    }
    my $layered_B_differences = define_Layers( -layers => \%layers );
    $output .= '<h2>Sample Type Discrepencies</h2>' . $layered_B_differences;

    return $output;
}

############################
sub prompt_for_summary {
############################
    my %args = filter_input(\@_, -args=>'dbc,prefix');
    my $dbc = $args{-dbc};
    my $prefix = $args{-prefix};   ## specify prefix for samples (eg BC or SHE)
    my $layer  = $args{-layer};

    my $q = new CGI;
    my $page
        = alDente::Form::start_alDente_form($dbc, 'bcg_summary') . '<p ></p>'
        . '<h2>Retrieve Subject / Sample Summary</h2>' . '<BR>'
        . $q->checkbox( -name => 'Include Times', -checked => 0, -force => 1 )
        . ' (retrieves storage times for samples - <B>much SLOWER to load</B>)<BR>'
        . $q->checkbox( -name => 'Include Test Samples', -checked => 0, -force => 1 )
        . hspace(5)
        . $q->checkbox( -name => 'Include Production Samples', -checked => 1, -force => 1 );

    if ( $dbc->get_local('user_name') eq 'Admin' ) { $page .= '<BR>' . $q->checkbox( -name => 'Debug', -checked => 0, -force => 1 ); }

    ## add option to choose subject range or exclude subjects ##
    $page
        .= '<p ></p>'
        . 'Include: ' . $q->radio_group(-name=>'Prefix', -values=>['BC','SHE'], -default=>$prefix, -force=>1)
        . '<br>'
        . 'Start with Subject: '
        . $q->textfield( -name => 'from_subject', -size => 6 )
        . ' Stop on Subject: '
        . $q->textfield( -name => 'to_subject', -size => 6 )
        . ' Exclude Subjects: '
        . $q->textfield( -name => 'exclude_subjects', -size => 12 );

    ## add option to specify minimum or maximum initial_time_to_freeze attribute
    $page .= '<p ></p>' . 'Min Initial Freeze Time: ' . $q->textfield( -name => 'min_freeze_time', -size => 3 ) . 'Max Initial Freeze Time: ' . $q->textfield( -name => 'max_freeze_time', -size => 3 ) . ' (only applicable when retrieving times)';

    $page .= '<p ></p>' . 'Custom condition: ' . $q->textfield( -name => 'Condition', size => 50 );

    #		    . '<BR>Onyx Barcode: ' . alDente::Tools::search_list(-dbc=>$dbc, -table=>'Source', -name => 'External_Identifier', -search=>1, -filter=>1)
    
    
    if ($layer) { $page .= $q->hidden(-name=>'Layer', -value=>$layer, -force=>1) }
    
    $page
        .= '<p ></p>'
        . display_date_field( -dbc => $dbc, -field_name => 'date_range', -default => '', -range => 1, -quick_link => [ 'Today', '7 days', '1 month', '1 year' ], -linefeed => 1 ) . '<p ></p>'
        . $q->submit( -name => 'rm', -value => 'Generate Summary', -class => 'Std' )
        . $q->hidden( -name => 'cgi_application', -value => 'Healthbank::App', -force => 1 )
        . $q->end_form();
        
    return $page;
}

#
# Page generated for Export layer on homepage
#
####################
sub _export_page {
####################
    my $dbc    = shift;
    my $output = alDente::Rack_Views::manifest_form($dbc);

    return $output;
}

#######################################
sub link_shipment_to_onyx_tubes {
#######################################
    my $dbc     = shift;
    my $include = shift;

    my $cgi_application = 'Healthbank::App';
    my $rm              = 'Link Shipment to Onyx Tubes';

    $include .= 'From Onyx Barcodes: ' . Show_Tool_Tip( textfield( -name => 'Onyx Barcode', -size => 50 ), 'Scan one or more Onyx barcodes to link to this shipment' );

    $include .= '<p ></p>' . 'Temporary Storage Location: ' . Show_Tool_Tip( textfield( -name => 'FK_Rack__ID', -size => 20 ), 'Scan barcode for rack location where these samples are to be stored at least temporarily' );

    $include .= set_validator( -name => 'FK_Rack__ID', -mandatory => 1, -prompt => 'You must enter at least a temporary storage location at this time' );
    my $page = &alDente::Attribute_Views::choose_Attributes( -dbc => $dbc, -class => 'Source', -include => $include, -cgi_application => $cgi_application, -rm => $rm, -checked => 1, -mandatory => ['Onyx Barcode'] );

    return $page;
}

################
sub overview {
################
    my %args = filter_input(\@_, -args=>'dbc');
    my $dbc = $args{-dbc};
    my $prefix = $args{-prefix};
    my $condition = $args{-condition} || 1;
    my $debug  = $args{-debug};
    my $source_condition = $args{-source_condition};
    my $plate_condition = $args{-plate_condition};

    if ($plate_condition) { $condition .= $plate_condition }
    if ($source_condition) { $condition .= $source_condition }
    
    if ($prefix) { $condition .= " AND Plate_Label LIKE '$prefix%'" }
    
    ## get some overview tables (previously in Administration layer) ##
    my $tables            = 'Plate,Plate_Sample,Sample,Source,Original_Source,Patient';
    my $summary_condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID";

    
    my $summary = $dbc->Table_retrieve_display(
        $tables, [ 'count(distinct Plate_ID) as Active_Tubes', 'count(distinct Source_ID) as Vaccuum_Tubes_Drawn', 'count(distinct External_Identifier) as Blood_Tubes', 'count(distinct FK_Patient__ID) as Subjects' ],
        "$summary_condition AND Plate.Plate_Status = 'Active' AND $condition",
        -title       => 'Sample Collection Summary',
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
    
    my $details = create_tree(-tree=> {'Sample Collection Query' => "SELECT * FROM $tables $summary_condition AND Plate.Plate_Status = 'Active' AND $condition" }); 

    return $summary . '<p ></p>' . $active . '<p ></p>' . $details;
}

1;
