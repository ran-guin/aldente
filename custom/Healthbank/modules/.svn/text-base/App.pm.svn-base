##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Healthbank::App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

use Healthbank::Model;
use Healthbank::Views;
use LampLite::Bootstrap;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $BS = new Bootstrap();

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
        'Activate Blood Tubes'             => 'receive_blood_tubes',
        'Activate and Prepare Blood Tubes' => 'receive_blood_tubes',
        'Activate Samples'             => 'receive_blood_tubes',
        'Activate and Prepare Samples' => 'receive_blood_tubes',
        'Backfill Check'                   => 'test_check',
        'Help'                             => 'help',
        'Fix EDTA'                         => '_temporary_fix',
        'Link Shipment to Onyx Tubes'      => 'link_shipment_to_Onyx',
        'Onyx Barcoding' => 'show_Onyx_page',
        'Generate Onyx Barcode' => 'generate_Onyx_Barcode',
        'Decrypt Onyx Barcode' => 'decrypt_Onyx_Barcode',
);

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#################
sub get_list {
#################
    my $self      = shift;
    my $field     = shift;
    my $condition = shift || 1;

    my $dbc = $self->param('dbc');
    my @list = $dbc->Table_find_array( 'Source, Plate_Format', $field, "where FK_Plate_Format__ID=Plate_Format.Plate_Format_ID AND $condition" );

    return @list;
}



#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes
##################
sub home_page {
##################

    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @other_run_modes = ( 'Display Samples', 'Display Tubes', 'Display Preps' );

    my $home_form = $self->help();

    return $home_form;
}

###########
sub help {
############

    my $page;

    $page .= "<B>General Instructions:</B>";
    $page .= "<H2>BCG_Mobile Section</H2>";
    $page .= "This section (if visible) is used for mobile transfer of blood tubes directly into transport boxes for shipping";
    $page .= "<UL>";
    $page .= "<LI><B>Activate Blood Tubes:</B>";
    $page .= "<OL>";
    $page .= "<LI>Scan onyx barcodes into the textfield (under the AC Collection section)";
    $page .= "<BR>If you don't see the AC Collection layer, just click on the 'BCG_Mobile' Icon or choose the 'BCG_Mobile' tab at the top right of the screen to regenerate the main page)";
    $page .= "<LI>Go to the box where it says 'Scan new Blood Tubes Here -->' and Scan the barcodes on the blood collection tubes that you have collected";
    $page .= "<LI>Go to the box where it says 'Specify Starting Location:' and Scan the Transport Box that you are placing samples into ";
    $page .= "<LI>If you wish to note anything unusual, enter any comments you may have in the Comments section";
    $page .= "<LI>Press the 'Activate Blood Tubes' button";
    $page .= "<LI>... This will initialize these samples into the LIMS for further handling and transport";
    $page .= "</OL>";

    $page .= "<p ></p>";
    $page .= "<LI><B>Moving Transport Boxes into a Shipping Container</B>";
    $page .= "<OL>";
    $page .= "<LI>Go to either the box beside the 'Scan' button or the section at the bottom of the 'AC Collection' page where it says 'Scan LIMS Barcodes Here -->'";
    $page .= "<LI>Scan in all of the transport boxes and the shipping container that you are placing them into";
    $page .= "<LI>Press the 'Scan' button beside the box that you have just scanned the barcodes into";
    $page .= "<LI>You will then see a confirmation page.  Check  that this is what you want to do and press the 'Confirm Relocation' button";
    $page .= "</OL>";

    $page .= "<p ></p>";
    $page .= "<LI><B>Exporting Samples</B>";
    $page .= "<OL>";
    $page .= "<LI>Go to the 'Export' layer by clicking on the 'Export' tab on the main page";
    $page .= "<LI>Scan the shipping container that you wish to export";
    $page .= "<LI>Choose the target location (contact administrators if you are unsure or the target is not in the available list)";
    $page .= "<LI>Click on the 'Generate Shipping Manifest' button";
    $page .= "<LI>Enter information as requested";
    $page .= "<LI>Confirm the information is correct and press the 'Ship Samples' button";
    $page .= "<LI>Print out a copy of the manifest to keep for your records and/or to include with the shipping container";
    $page .= "</OL>";
    $page .= "</UL>";

    $page .= "<p ></p>";
    $page .= "<H2>BC Generations Section</H2>";
    $page .= "This section is used for normal sample handling";
    $page .= "<UL>";
    $page .= "<LI><B>Prepare Blood Tubes:</B>";
    $page .= "<OL>";
    $page .= "<LI>Scan onyx barcodes into the textfield (under the Sample Preparation section)";
    $page .= "<BR>If you don't see the Sample Preparation layer, just click on the 'BC Generations' Icon or tab at the top of the screen to regenerate the main page)";
    $page .= "<LI>Press the 'Prepare Blood Tubes' button";
    $page .= "<LI>Choose the sample handling protocol you wish to use and click on the 'Continue Protocol' button";
    $page .= "<LI>Follow instructions as requested and enter information as required";
    $page .= "</OL>";

    $page .= "<p ></p>";
    $page .= "<LI><B>Importing Samples</B>";
    $page .= "<OL>";
    $page .= "<LI>Go to the 'In Transit' layer by clicking on the 'Import' tab on the main page";
    $page .= "<BR>You don't need to go to this view, but it will show you what is currently in transit";
    $page .= "<LI>Scan the shipping container that you wish to Import beside the scan button on any page";
    $page .= "<LI>Press the 'Scan' button";
    $page .= "<LI>Click on the 'Receive Shipment' button.  (Note if this button does not appear after scanning a shipping container, then the container has already been received)";
    $page .= "<LI>Enter information as requested";
    $page .= "<LI>Print out a copy of the manifest to keep for your records";
    $page .= "</OL>";

    $page .= "<p ></p>";
    $page .= "<LI><B>Store Tubes:</B>";
    $page .= "<OL>";
    $page .= "<LI>Scan any number of cryovials into the scan field at the top left section of the screen";
    $page .= "<LI>Press the 'Scan' button";
    $page .= "</OL>";
    $page .= "</UL>";
    $page .= "<p ></p>";
    return $page;
}

#
# run mode: display_sources shows information about sources collected, based on user-entered $q->parameters
#
#############################
sub receive_blood_tubes {
#############################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $receive_only = $q->param('rm') eq 'Activate Blood Tubes';

    my $onyx_barcode  = $q->param('Onyx_Barcode');
    my $comments = $q->param('Comments');

    my $rack = get_Table_Param( -dbc => $dbc, -field => 'FK_Rack__ID', -convert_fk => 1 );

    my $printer_group_id = $dbc->session->param('printer_group_id') || return $self->prompt_for_session_info('printer_group_id');

    my $plate_list = $self->Model->redefine_tube( -dbc => $dbc, -barcode => $onyx_barcode, -comments => $comments, -rack => $rack, -receive => $receive_only );
    my @plate_ids = split ',', $plate_list;

    my @unique_list = @{ unique_items( \@plate_ids ) };

    if ( int(@unique_list) < int(@plate_ids) ) {
        my (%ID, @dups);
        map { if ($ID{$_}) { push @dups, $dbc->Table_find('Plate','Plate_Label',"WHERE Plate_ID = '$_'") } $ID{$_}++ } @plate_ids;
        $dbc->error("Error: Duplicate Onyx barcodes scanned (@dups).  Please scan only unique Onyx barcodes.");
        return;
    }

    $dbc->{current_plates} = \@plate_ids;

    if ($receive_only) {
        $dbc->session->message("Activated  LIMS Tubes: $plate_list");

        alDente::Rack::relocate_Rack( $dbc, $rack, -ignore => int(@plate_ids) );

        return;
    }

    my $output;

    if ( !$plate_list ) {return}
    $plate_list ||= '0';
    my @types = $dbc->Table_find( 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID IN ($plate_list)", -distinct => 1 );

    ## get distinct list of format types
    if ( int(@types) > 1 ) {
        $dbc->session->warning("You cannot prepare tubes of different type together - Please try scanning tubes again if you wish to start a handling protocol");
    }

    if (@plate_ids) {
        ## go to standard 'Start Protocol' page for applicable type ##
        my $plate_count = int(@plate_ids);
        Message("Start protocol for $plate_count container(s) ($plate_list)");

        my $scanner_mode = 0;
        $current_plates = $plate_list;

        my $Tubes = new alDente::Container(-dbc=>$dbc, -id=>$plate_list);
        my $plate_page = $Tubes->View->std_home_page( -id => $plate_list );

        $output .= $plate_page;                                            ##  &alDente::Info::GoHome( $dbc, -table=>'Plate',-id=>$plate_list);
        $output .= '<hr>';
        $output .= $self->View->sample_prep_page($dbc);

    }
    else {
        Message("Please try scanning Onyx barcode again");
    }
    return $output;
}

#
# Quick reference to enable rapid generation of new patient barcodes for backfilling.
# This page also shows current records for a subset of subjects
#
#
#################
sub test_check {
#################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $q = $self->query();

    my $count = $q->param('Times') || 5;
    my $start = $q->param('Start') || 1;
    my $list  = $q->param('List');

    my $page;
    my @all_cryos;
    my @all_plates;

    my @samples = ( $start .. $start + $count - 1 );
    if ($list) { @samples = split ',', $list }    ## override

    my ( @acds, @ssts, @edtas, @ucups );
    
    my $separator = ", ";
    foreach my $sample (@samples) {
        my $subject = sprintf 'BC%06d', $sample;

        $page .= $dbc->Table_retrieve_display(
            'Plate,Sample,Plate_Format,Plate_Sample,Source,Original_Source,Sample_Type',
            [   "GROUP_CONCAT(Plate_ID SEPARATOR '$separator') AS Tube_IDs",
                "GROUP_CONCAT(distinct Plate.FK_Rack__ID SEPARATOR '$separator') as Racks",
                "GROUP_CONCAT(distinct Plate_Status) as Status",
                "GROUP_CONCAT(distinct External_Identifier SEPARATOR '$separator') as Blood_Tubes",
                'Plate_Format_Type',
                'Sample_Type.Sample_Type',
                'Original_Source_Name',
                'count(*) as Count',
             ],
            "WHERE Plate.FK_Sample_Type__ID=Sample_Type_ID AND Plate.FK_Plate_Format__ID=Plate_Format_ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND External_Identifier like '$subject%' Group by Plate.FK_Plate_Format__ID,Plate.FK_Sample_Type__ID ORDER BY Status, Plate_ID,Plate_Format_Type,Sample_Type",
            -title            => "Subject $subject",
            -return_html      => 1,
            -total_columns    => 'Count',
            -border => 1,
            -highlight_string => 'Active',
            -border=>1,
        );

        $page .= '<BR>';
        $page .= "Original Onyx Barcodes:\n<BR>";
        $page .= "<B>";
        my $acd  = ${subject} . 'T02N1';
        my $edta = "${subject}T03N1${subject}T03N2${subject}T03N3";
        my $sst  = "${subject}T01N1${subject}T01N2";
        my $ucup = "${subject}T04N1";

        $page .= "* ACD: \t$acd<BR>";
        $page .= "* SST: \t$sst<BR>";
        $page .= "* EDTA: \t$edta<BR>";
        $page .= "* Urine: \t$ucup<BR>";
        push @acds,  $acd;
        push @edtas, $edta;
        push @ssts,  $sst;
        push @ucups, $ucup;

        $page .= "</B>";

        my @cryos = $dbc->Table_find( 'Plate,Plate_Sample,Sample,Source',
            'Plate_ID', "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID = Source_ID AND External_Identifier like '$subject%' AND Plate.FK_Plate_Format__ID = 5" );
        $page .= "<p ></p><B>Cryovials Generated</B>:<BR>";
        $page .= 'BCG' . join ' BCG', @cryos;
        push @all_cryos, @cryos;

        $page .= "<p ></p><B>All Container_IDs</B>:<BR>";
        my @plates = $dbc->Table_find( 'Plate,Plate_Sample,Sample,Source',
            'Plate_ID', "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID = Source_ID AND External_Identifier like '$subject%'" );
        $page .= join ',', @plates;
        push @all_plates, @plates;
        $page .= '<hr>';
    }

    if ( $count > 1 ) {
        $page .= "<p ></p>";
        $page .= "ACDs: " . join ' ', @acds;
        $page .= "<p ></p>";
        $page .= "EDTAs: " . join ' ', @edtas;
        $page .= "<p ></p>";
        $page .= "SSTs: " . join ' ', @ssts;
        $page .= "<p ></p>";
        $page .= "Ucups: " . join ' ', @ucups;
        $page .= "<p ></p>";
        $page .= "All Cryovial Containers:<BR>";
        $page .= join ', ', @all_cryos;
        $page .= "<p ></p>";
        $page .= "All Container_IDs:<BR>";
        $page .= join ', ', @all_plates;
    }

    my $all_ids = join ',', @all_plates;

    if ( !$all_ids ) { $page .= "<p ></p>No records found..."; return $page }

    #$page .= '<p ></p>';
    #foreach my $type (1..4) {
    #	my @ids = $dbc->Table_find('Plate','Plate_ID',"WHERE Plate_ID IN ($all_ids) AND FK_Plate_Format__ID = $type");
    #	$page .= alDente::Tools::alDente_ref('Plate_Format',$type,-dbc=>$dbc);
    #	$page .= ' ( ' . int(@ids) . ")<BR>";
    #	$page .= 'BCG';
    #	$page .= join ' BCG', @ids;
    #	$page .= '<p ></p>';
    #}

    $page .= '<p ></p>';
    $page .= '<h2>By Sample Type...</h2>';
    foreach my $type ( 1 .. 10 ) {
        my @ids = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE FK_Plate_Format__ID = 5 AND Plate_Status = 'Active' AND Plate_ID IN ($all_ids) AND FK_Sample_Type__ID = $type" );
        if (@ids) {
            $page .= alDente::Tools::alDente_ref( 'Sample_Type', $type, -dbc => $dbc );
            $page .= ' Samples ( ' . int(@ids) . ")<BR>";
            my $list = 'BCG';
            $list .= join ' BCG', @ids;
            $page .= Link_To( $dbc->homelink(), $list, "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=$list", -tooltip => 'Click here to go to home page for these containers' );
            $page .= '<p ></p>';
        }
    }
    return $page;
}

#
# Fix improperly stored samples (temporary method until this is fixed... )
#
########################################
sub _temporary_fix {
########################################
    my $self = shift;

    Message("This has now been disabled");
    return;
}

################################
sub link_shipment_to_Onyx {
################################
    my $self = shift;

    my $q = $self->query();

    my $scanned    = $q->param('Onyx Barcode');                       ## onyx barcodes in shipment
    my $rack       = $q->param('Rack') || $q->param('FK_Rack__ID');
    my $comments   = $q->param('Comments');
    my $attributes = join ',', $q->param('Attribute_ID');             ## attributes selected to enter
    my $shipment   = $q->param('Shipment_ID');

    my $rack_id = alDente::Validation::get_aldente_id( $dbc, $rack, 'Rack' );
    ## ensure only one type of onyx barcode supplied at a time - to enable consistent attribute updates ##

    my $page = Message(".... Link shipment to Onyx tubes scanned (under construction) -> Rack $rack_id ($rack)");
    $page .= "chose to update attributes: $attributes";

    ## custom for Healthbank ##
    my $plate_list = $self->Model->redefine_tube( -dbc => $dbc, -barcode => $scanned, -comments => $comments, -rack => $rack_id, -receive => 1 );
    my $sources = join ',', $dbc->Table_find( 'Plate,Plate_Sample,Sample', 'FK_Source__ID', "WHERE Plate.Plate_ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Plate_ID IN ($plate_list)" );

    my $source_ids = alDente::Validation::get_aldente_id( $dbc, $sources, 'Source' );
    if ( $shipment && $source_ids ) {
        my $updated = $dbc->Table_update( 'Source', 'FK_Shipment__ID', $shipment, "WHERE Source_ID IN ($source_ids) AND FK_Shipment__ID IS NULL" );
        Message( "linked Shipment: " . alDente::Tools::alDente_ref( 'Shipment', $shipment, -dbc => $dbc ) . " to Sources: $source_ids [updated $updated records]" );
    }

    require alDente::Attribute_Views;
    my $page = alDente::Attribute_Views::set_multiple_Attribute_form( $dbc, 'Source', $source_ids, -attribute_ids => $attributes, -reset_homepage => "Plate=$plate_list" );

    return $page;

}

#####################
sub show_Onyx_page {
#####################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $page = $self->View->onyx_home_page($dbc);
    return $page;
}

#####################
sub decrypt_Onyx_Barcode {
#####################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->param('dbc');

    my $onyx_barcode = $q->param('Onyx_Barcode');

    my $BS = new Bootstrap(); 
    print $BS->message("Decrypting Onyx Barcode: $onyx_barcode");
   
    my $hash = $self->Model->decode_onyx_barcode($onyx_barcode);

    my $page;
    if (ref $hash eq 'HASH') { 
        $page = SDB::HTML::display_hash(-title=>'Decoded Contents of Onyx Barcode', -dbc=>$dbc, -hash=>$hash, -return_html=>1, -border=>1);
    }
    else {
        $dbc->error("<B>Error decoding onyx barcode</B>: $hash");
    }
    $page .= $self->View->onyx_home_page($dbc);
    
    return $page;
}

############################
sub generate_Onyx_Barcode {
############################
    my $self = shift;
    my $q = $self->query();

    my $Onyx_Code = $self->Model->onyx_formats();
    my @formats = sort keys %$Onyx_Code;
    
    my $project = $q->param('Project');
    my $subject = $q->param('Subject');
    
    my ($message, $warning, $error);

    if ($project !~/^(BC|SHE)$/) { $error .= "Invalid Projectd $project (must be BC or SHE)\n" }
    if ($subject !~/^\d\d\d\d\d\d$/) { $error .= "Subject Identifier ($subject) should be 6 digits" }
    
    if (! $error) { 
        my $barcode;
        my $contents;
        foreach my $format (@formats) {
            my $count = $q->param("$format-count");
            my $start = $q->param("$format-start") || 1;
            if ($count) {
                my $finish = $start + $count - 1;
                $contents .= " $count $format sample(s) [N$start]\n";
                if ($count > 1) { $contents =~s/\[N$start\]/\[N$start\.\.N$finish\]/ }

                foreach my $i ($start..$finish) {
                    $barcode .= $project . $subject . $format . 'N' . $i  . "\n";
                }
            }
        }

       $message = "$contents\n<u>Onyx Barcode</u>:\n\n$barcode";
    }
    
    my $dbc = $self->param('dbc');
    my $page = $self->View->onyx_home_page($dbc, -message=>$message, -error=>$error);
    return $page;
}

return 1;
