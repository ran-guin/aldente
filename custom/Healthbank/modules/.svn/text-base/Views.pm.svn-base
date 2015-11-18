package Healthbank::Views;

use base alDente::Department_Views;
#use base alDente::Object_Views;

use strict;
use warnings;
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::CustomSettings;

use Healthbank::Model;
use LampLite::Bootstrap;
use LampLite::CGI;
use SDB::HTML;
use LampLite::HTML;

my $BS = new Bootstrap;
my $q = new LampLite::CGI;

my ( $session, $account_name );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};
    $self->{dbc} = $dbc;
    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}


#
# Custom page to show Onyx formatting and to provide simple user tools (eg decode or encode Onyx codes)
#
#####################
sub onyx_home_page {
#####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $message = $args{-message};
    my $error = $args{-error};
   
    my $page = page_heading("Onyx Barcoding");
    
    my $img = '/' . $dbc->config('IMAGE_DIR') . "/../help_images/Onyx_Barcodes.png";
    $img = "<IMG SRC='$img'></IMG>\n";

    if ($message) { 
        $page .= $BS->message($message)
    }
    if ($error) {
        $page .= $BS->error($error);
    }

    my $Onyx_Code = $self->Model->onyx_formats();
    
    my $table = new HTML_Table(-title=>'Onyx Formats for Sample Type', -width=>'100%');
    $table->Set_Headers(['Code','Format','Sample Volume','Content', '#', 'Starting #']);
   
    my @formats = sort keys %$Onyx_Code;
    
    foreach my $format (@formats) {
        my $desc = $Onyx_Code->{$format}{Format};
        my $volume = $Onyx_Code->{$format}{Volume};
        my $content = $Onyx_Code->{$format}{Content};
        my $count = $q->textfield(-name=>"$format-count", -class=>'narrow-txt');
        my $start = $q->textfield(-name=>"$format-start", -class=>'narrow-txt');
        $table->Set_Row([$format, $desc, $volume, $content, $count, $start]);
    }

    my $format_block = alDente::Form::start_alDente_form($dbc,'decode_onyx');
    $format_block .=  $q->hidden(-name=>'cgi_application', -value=>'Healthbank::App', -force=>1); 
    $format_block .= $q->textarea(-name=>'Onyx_Barcode', -size=>500, -class=>'superwide-txt');
    $format_block .= $q->submit(-name=>'rm', -value=>'Decrypt Onyx Barcode', -class=>'Std', -onclick=>'return validateForm(this.form)'); 
    $format_block .= set_validator(-name=>'Onyx_Barcode', -mandatory=>1);
    $format_block .= $q->end_form();
  
    $format_block .= '<hr>';

    $format_block .= section_heading('Generate your own Onyx Barcode');

    $format_block .= alDente::Form::start_alDente_form($dbc,'encode_onyx');
    $format_block .=  $q->hidden(-name=>'cgi_application', -value=>'Healthbank::App', -force=>1); 
    $format_block .= 'Project: ' . $q->radio_group(-name=>'Project', -values=>['BC','SHE']) . '<BR>';
    $format_block .= 'Subject: ' . $q->textfield(-name=>'Subject', -size=>50) . '<BR>';
    $format_block .= $q->submit(-name=>'rm', -value=>'Generate Onyx Barcode', -class=>'Std', -onclick=>'return validateForm(this.form)');

    $format_block .= $table->Printout(0);
    $format_block .= $q->submit(-name=>'rm', -value=>'Generate Onyx Barcode', -class=>'Std', -onclick=>'return validateForm(this.form)');
    $format_block .= set_validator(-name=>'Subject', -mandatory=>1, -format=>'^\d{6}$', -prompt=>'Subject must be 6 digits');
    $format_block .= $q->end_form();

    $page .= $BS->row( [ $img, $format_block ], -span=>[6,6] );

    $table->Printout(0);

    return $page

}
    
##########################
sub show_discrepencies {
##########################

}

##########################
sub sample_prep_page {
##########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'mobile');
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $mobile = $args{-mobile};

    my $page;

    $page .= $self->scan_onyx_tubes( -dbc=>$dbc, -mobile=>$mobile );

    $page .= '<hr>';

    $page .= $self->scan_lims_barcode( -dbc=>$dbc, -mobile=>$mobile );

    #    if (!$mobile) {
    ## only show this if this is not running in mobile mode ##

    return $page;
}

######################
sub scan_onyx_tubes {
######################
    my $self  = shift;
    my %args = filter_input(\@_, -args=>'mobile');
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $mobile = $args{-mobile};

    my $rm = 'Activate and Prepare Samples';
    if ( $mobile ) { $rm = 'Activate Samples' }
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -framework=>'bootstrap');
    $Form->append(-label=>'Scan Onyx Tubes:', -input=>$q->textfield(-placeholder  => 'Scan new Onyx Barcodes Here', -name => 'Onyx_Barcode', -tooltip      => 'Scan any number of sample Onyx barcodes'));
    $Form->append(-label=>"Starting Location: ", -input=>$q->textfield( -name => 'FK_Rack__ID', -size => 20, -value => '', -force => 1 ));
    $Form->append(-label=>'Add Comments (optional): ', -input=>$q->textfield(-placeholder  => 'Add Optional Comments Here', -name => 'Comments', -tooltip => 'Comments will be annotated to these Source Tubes'));
    $Form->append(-label=>'', -input=> $q->submit(-name=>'rm', -value=>$rm, -force=>1, -class=>'Action btn', -onClick=>'return validateForm(this.form)') );
    
    my $start_tag = alDente::Form::start_alDente_form($dbc, 'New Onyx Barcodes')
         . $q->hidden(-name=>'cgi_application', -value=>'Healthbank::App', -force=>1)
         . set_validator( -name => 'Onyx_Barcode', -mandatory => 1, -format => 'BC', -prompt => 'You must scan the Onyx barcodes for the blood samples you wish to activate' )
#         . set_validator( -name => 'FK_Rack__ID', -mandatory => 1, -prompt => 'You must scan the box you are placing these into' )
         . $q->hidden( -name => 'FK_Site__ID', -value => $dbc->{site_id} );  
  
    my $page = $Form->generate(-open=>1, -close=>1, -tag => $start_tag);
    
    return $page;
}

######################
sub scan_lims_barcode {
######################
    my $self  = shift;
    my %args = filter_input(\@_, -args=>'mobile');
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $mobile = $args{-mobile};

    my $rm = 'Scan';
    my $app = 'alDente::Scanner_App';
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -framework=>'bootstrap');
    $Form->append(-label=>'Scan LIMS Barcode:', -input=>$q->textfield(-placeholder  => 'LIMS Barcode', -name => 'Barcode', -tooltip      => 'Scan valid LIMS barcode(s)'));
    $Form->append(-label=>'', -input=> $q->submit(-name=>'rm', -value=>$rm, -force=>1, -class=>'Action btn', -onClick=>'return validateForm(this.form)') );

    my $start_tag = alDente::Form::start_alDente_form($dbc, 'LIMS Barcode')
    . $q->hidden(-name=>'cgi_application', -value=>$app, -force=>1)
    . set_validator( -name => 'Barcode', -mandatory => 1, -prompt => 'You must scan something in this field to continue' );

    my $page = $Form->generate(-open=>1, -close=>1, -tag => $start_tag);

    return $page;    

}


##################
sub _admin_page {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc,condition');
    my $dbc = $args{-dbc} || $self->dbc;
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

    $output .= '<p ></p>' . alDente::Form::start_alDente_form($dbc, 'backfill') . $q->hidden( -name => 'cgi_application', -value => 'Healthbank::App', -force => 1 );
    $output .= 'Check ' . $q->textfield( -name => 'Times', -size => 5, -default => 1 ) . 'Subjects; Starting at #' . $q->textfield( -name => 'Start', -size => 5, -default => '' );
    $output .= $q->submit( -name => 'rm', -value => 'Backfill Check', -class => 'Search', -force => 1 );
    $output .= $q->end_form();

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
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc,prefix');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $prefix = $args{-prefix};   ## specify prefix for samples (eg BC or SHE)
    my $layer  = $args{-layer};

    my $layered;
    if ($layer) { $layered = "[ by $layer]" }

    my $page
        = alDente::Form::start_alDente_form($dbc, 'bcg_summary') . '<p ></p>'
        . section_heading("Retrieve Subject / Sample Summary $layered")
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
        . 'Subject Range: '
        . Show_Tool_Tip($q->textfield( -name => 'from_subject', -size => 6, -class=>'short-txt'), 'Starting with Subject #')
        . ' -> '
        . Show_Tool_Tip($q->textfield( -name => 'to_subject', -size => 6, -class=>'short-txt'), 'Ending with Subject #')
        . ' Exclude Subjects: '
        . Show_Tool_Tip( $q->textfield( -name => 'exclude_subjects', -size => 12), 'Enter comma-delimited list of subjects from given range to exclude');

    ## add option to specify minimum or maximum initial_time_to_freeze attribute
    $page .= '<p ></p>' 
        . ' Initial Freeze Time Range (in hrs): ' 
        . Show_Tool_Tip( $q->textfield( -name => 'min_freeze_time', -size => 3, -class=>'narrow-txt') , "Minimum Freeze Time") 
        . ' -> ' 
        . Show_Tool_Tip( $q->textfield( -name => 'max_freeze_time', -size => 3 , -class=>'narrow-txt'), "Maximum Freeze Time") 
        . ' (only applicable when retrieving times)';

    $page .= '<p ></p>' . ' Custom condition: ' . Show_Tool_Tip($q->textfield( -name => 'Condition', size => 50 ), 'Optional SQL database query condition');

    #		    . '<BR>Onyx Barcode: ' . alDente::Tools::search_list(-dbc=>$dbc, -table=>'Source', -name => 'External_Identifier', -search=>1, -filter=>1)
    
    
    if ($layer) { $page .= $q->hidden(-name=>'Layer', -value=>$layer, -force=>1) }
    
    my $app = ref $self->App || $self->App;  
    
    $page
        .= '<p ></p>'
        . display_date_field( -dbc => $dbc, -field_name => 'date_range', -default => '', -range => 1, -quick_link => [ 'Today', '7 days', '1 month', '1 year' ], -linefeed => 1 ) . '<p ></p>'
        . $q->submit( -name => 'rm', -value => 'Generate Summary', -class => 'Std' )
        . $q->hidden( -name => 'cgi_application', -value => $app, -force => 1 )
        . $q->end_form();
        
    return $page;
}

#
# Page generated for Export layer on homepage
#
####################
sub _export_page {
####################
    my $self = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc} || $self->dbc();
    
    my $output = alDente::Rack_Views::manifest_form($dbc);

    return $output;
}

#
# Page generated for Search layer on homepage
#
###################
sub _search_page {
###################
    my $self = shift;
    my %args          = filter_input( \@_, -args => 'dbc,url_condition' );
    my $dbc           = $args{-dbc} || $self->dbc();
    my $url_condition = $args{-url_condition};

    my $search;

	my $view_dir = "$Configs{views_dir}/$Configs{DATABASE}/Group/3/general";

    if ($url_condition) { $url_condition = '&' . $url_condition }
	my $url_condition_subject = $url_condition . "&cgi_application=alDente::View_App&rm=Display" . "&File=$view_dir/BCG_Samples_by_Subject.yml" . "&Generate+Results=1";
	my $url_condition_content = $url_condition . "&cgi_application=alDente::View_App&rm=Display" . "&File=$view_dir/BCG_Samples_by_Content.yml" . "&Generate+Results=1";
	my $url_condition_source  = $url_condition . "&cgi_application=alDente::View_App&rm=Display" . "&File=$view_dir/BCG_source_finder.yml" . "&Generate+Results=1";

    $search .= subsection_heading('Recently Generated samples') . Link_To( $dbc->homelink(), ' Sample Finder', "&cgi_application=alDente::View_App&rm=Display&File=$view_dir/BCG_tube_finder.yml&Source+Call=alDente::View_App" );

    $search .= '<p ></p>' . Link_To( $dbc->homelink(), ' Samples by Subject ID', $url_condition_subject );

    $search .= '<p ></p>' . Link_To( $dbc->homelink(), ' Samples by Content', $url_condition_content );

    $search .= '<p ></p>' . Link_To( $dbc->homelink(), 'Search Received Shipments', "&TableName=Shipment&Search+for=Search+Records" );

    my $create = subsection_heading('Create new records') . Link_To( $dbc->homelink(), ' Add Patient Centre', '&New+Entry=New+Service_Centre' );

    my $plates
        = subsection_heading('Search Barcoded Records')
        . Link_To( $dbc->homelink(), ' Container (BCG) Records',           '&cgi_application=SDB::DB_Object_App&rm=Search+Records&Table=Plate' ) . '<p ></p>'
        . Link_To( $dbc->homelink(), ' Original Blood Tube (SRC) Records', $url_condition_source );

    my $output =  &Views::Table_Print( content => [ [ $search], [$create], [$plates ] ], print => 0 );

    return $output;
}

#######################################
sub link_shipment_to_onyx_tubes {
#######################################
    my $self = shift;
    my %args          = filter_input( \@_, -args=>'dbc, include');
    my $dbc     = $args{-dbc} || $self->dbc();
    my $include = $args{-include};

    my $cgi_application = 'Healthbank::App';
    my $rm              = 'Link Shipment to Onyx Tubes';

    $include .= 'From Onyx Barcodes: ' 
        . Show_Tool_Tip( $q->textfield( -name => 'Onyx Barcode', -size => 50 ), 'Scan one or more Onyx barcodes to link to this shipment' );

    $include .= '<p ></p>' . 'Temporary Storage Location: ' 
        . Show_Tool_Tip( $q->textfield( -name => 'FK_Rack__ID', -size => 20 ), 'Scan barcode for rack location where these samples are to be stored at least temporarily' );

#    $include .= set_validator( -name => 'FK_Rack__ID', -mandatory => 1, -prompt => 'You must enter at least a temporary storage location at this time' );
    
    require alDente::Attribute_Views;
    
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


return 1;
