##############################################################################################
# alDente::Shipment_Views.pm
#
# Interface generating methods for the Shipment MVC  (assoc with Shipment.pm, Shipment_App.pm)
#
##############################################################################################
package alDente::Shipment_Views;

use base alDente::Object_Views;

use strict;

## Standard modules ##
use LampLite::CGI;
use LampLite::Bootstrap;

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Import;

use RGTools::RGIO;
use RGTools::Views;

use alDente::Form;
use alDente::Tools;
use alDente::Attribute_Views;
use alDente::Organization;

use LampLite::Bootstrap;

## globals ##

my $q  = new CGI;
my $BS = new Bootstrap;
my $BS = new Bootstrap;

###################
sub object_label {
###################
    my $self = shift;
    my %args = filter_input(\@_);

    my $dbc = $args{-dbc} || $self->dbc();
    my $id  = $args{-id}  || $self->{id};

    my $Shipment = new alDente::Shipment(-dbc=>$dbc, -id=>$id); ## $args{-Shipment} || $model->{Shipment} || $self->{Shipment};
 
    my $type           = $Shipment->value('Shipment.Shipment_Type');
    my $current_status = $Shipment->value('Shipment_Status');
    my $rack_id        = $Shipment->value('FKTransport_Rack__ID');
    my $addressee    = $Shipment->value('Addressee');
    my $target_site    = $Shipment->value('FKTarget_Site__ID');
    my $target_grp    = $Shipment->value('FKTarget_Grp__ID');
    my $sent_date  = $Shipment->value('Shipment_Sent');
    my $received_date  = $Shipment->value('Shipment_Received');
    
    my $label = "<B>$type</B> [$current_status]<P></P>Sent: $sent_date<P>-> $addressee [" 
        . $dbc->display_value('Grp', $target_grp)
        . ' : '
        . $dbc->display_value('Site', $target_site)
        . ']';
    
    if ($received_date) { $label .= " <P>Received: $received_date<P>" }
    if ($rack_id) { $label .= '<P>Transport Container: ' . $dbc->display_value('Rack', $rack_id) }

    return $label;
}

###########################
sub display_record_page {
###########################
    my $self = shift;
    my %args = filter_input(\@_);

    my $dbc = $args{-dbc} || $self->dbc();
    my $id  = $args{-id}  || $self->{id};
 
    my $class = ref $self;
    
    my $Shipment = $args{-Shipment} || $self->Model(-id=>$id);

    my ( $manifest, $contents, $update, $roundtrip, $attachments );
    my $type           = $Shipment->value('Shipment.Shipment_Type');
    my $current_status = $Shipment->value('Shipment_Status');
    my $rack_id        = $Shipment->value('FKTransport_Rack__ID');
    my $target_site    = $Shipment->value('FKTarget_Site__ID');
    my $received_date  = $Shipment->value('Shipment_Received');

    $target_site = $dbc->get_FK_info( -field => 'FKTarget_Site__ID', -id => $target_site );

    my $middle;
        
    if ( $type eq 'Import' ) {
        $manifest = $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
         $manifest .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $id );
         $contents .= $self->import_Shipment( -id => $id, -dbc => $dbc );
    }
    elsif ( $type eq 'Export' || $type eq 'Internal' || $type eq 'Virtual' ) {
        $manifest = $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
        $contents .= $self->display_indirect_Shipment_links( -dbc => $dbc, -id => $id );
        if ( $type eq 'Export' ) {
            # option to allow 'Export' shipment to be changed to 'Roundtrip' shipment
            $update
            .= alDente::Form::start_alDente_form( $dbc, 'Convert_to_Roundtrip' )
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
            . $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 )
            . $q->submit( -name => 'rm', -value => 'Convert To Roundtrip Shipment', -class => 'Action', -force => 1 )
            . $q->hidden( -name => 'Shipment_Type', -value => 'Roundtrip', -force => 1 )
            . $q->end_form('Convert_to_Roundtrip')
            . '<hr>';
        }
    }
    elsif ( $type eq 'Roundtrip' ) {
        my $original = $Shipment->value('FKOriginal_Shipment__ID');
        if ($original) {
            my $Original_Shipment = new alDente::Shipment( -id => $original, -dbc => $dbc );
            return $self->home_page( -Shipment => $Original_Shipment, -dbc => $dbc, -id => $original );
        }

        my @children = $dbc->Table_find( 'Shipment', 'Shipment_ID', "WHERE FKOriginal_Shipment__ID = $id" );
        my $status = $Shipment->value('Shipment_Status');

        if ( int(@children) == 0 ) {    # if no children, allow 'Roundtrip' shipment to be converted to 'Export' shipment
            $update
            .= alDente::Form::start_alDente_form( $dbc, 'Convert_to_Export' )
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
            . $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 )
            . $q->submit( -name => 'rm', -value => 'Convert To Export Shipment', -class => 'Action', -force => 1 )
            . $q->hidden( -name => 'Shipment_Type', -value => 'Export', -force => 1 )
            . $q->end_form('Convert_to_Export');
        }

        $manifest .= $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
        $manifest .= $self->display_indirect_Shipment_links( -dbc => $dbc, -id => $id );
        
        $roundtrip = $self->side_Roundtrip_view( -dbc => $dbc, -id => $id, -Shipment => $Shipment );

        if ( $status =~ /Received/i ) {
            for my $child (@children) {
                $manifest .= '<HR>' . $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $child );
                $manifest .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $child );
                $roundtrip .= create_tree( -tree => { "Shipment $child Options " => $self->import_Shipment( -id => $child, -dbc => $dbc ) }, -default_open => 0 );
            }
        }
        elsif ( $status =~ /Sent/i && $children[0] ) {
            for my $child (@children) {
                $manifest .= '<HR>' . $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $child );
                $manifest .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $child );
                $contents .= create_tree( -tree => { "Shipment $child Options " => $self->import_Shipment( -id => $child, -dbc => $dbc ) }, -default_open => 0 );
            }
            $middle .= $self->roundtrip_Shipment( -id => $id, -dbc => $dbc, -Shipment => $Shipment );
        }
        elsif ( $status =~ /(Sent|Exported)/i ) {            
            $middle .= $self->roundtrip_Shipment( -id => $id, -dbc => $dbc, -Shipment => $Shipment );
        }
    }
    else {
        return $dbc->warning("Undefined Shipment_Type: $type");
    }

    # Display Attachements if any
    my ($sid) = $dbc->Table_find( 'Shipment', 'FK_Submission__ID', "WHERE Shipment_ID=$id" );

    if ($sid) {
        my $submission_view = $self->submission_attachment_view( -sid => $sid, -dbc => $dbc, -shipment_id => $id );
        if ($submission_view) { $attachments .= $submission_view }
    }

    if ( ( $current_status =~ /Sent/i || !$received_date || $received_date eq '0000-00-00 00:00:00' ) && $type =~ /Export/i ) {
        $middle .= '<P>' . $self->_mark_Received_Shipment( -dbc => $dbc, -id => $id, -target_site => $target_site );
     }
    
    my @layers = (
        { label => 'Contents', content => $contents }
    );

    if ($roundtrip) {
        push @layers, { label => 'Roundtrip', content => $roundtrip };
    }
    
    if ($attachments) {
        push @layers, { label => 'Attachments', content => $attachments };
    }

    my $page = $self->SUPER::display_record_page(
        -centre => $manifest,
        -middle => $middle,
        -layers     => \@layers,
        -open_layer => 'Contents',
    );

    return $page;
}

#############################################
#
# Standard view for single Shipment record
#
# Return: html page
###################
sub home_page {
###################
    my $self     = shift;
    my %args     = filter_input( \@_, 'id' );
    my $model    = $args{-model};
    my $Shipment = $args{-Shipment} || $model->{Shipment} || $self->{Shipment};
    my $dbc      = $args{-dbc} || $Shipment->dbc();
    my $id       = $args{-id} || $Shipment->{id};

    $id = Cast_List( -list => $id, -to => 'string' );
    if ( $id =~ /,/ ) { return $self->list_page( %args, -ids => $id ) }
    my ( $top, $right, $left );

    my $type           = $Shipment->value('Shipment_Type');
    my $current_status = $Shipment->value('Shipment_Status');
    my $rack_id        = $Shipment->value('FKTransport_Rack__ID');
    my $target_site    = $Shipment->value('FKTarget_Site__ID');
    my $received_date  = $Shipment->value('Shipment_Received');

    $target_site = $dbc->get_FK_info( -field => 'FKTarget_Site__ID', -id => $target_site );
    $dbc->message("$type Shipment") unless ( $type =~ /roundtrip/i );

    my $homepage;

    if ( $type eq 'Import' ) {
        $top = $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
        $top .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $id );
        $left .= $self->import_Shipment( -id => $id, -dbc => $dbc );
        $right = $Shipment->display_Record( -truncate => 40 );
    }
    elsif ( $type eq 'Export' || $type eq 'Internal' || $type eq 'Virtual' ) {
        $top = $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
        $left .= $self->display_indirect_Shipment_links( -dbc => $dbc, -id => $id );
        $right = $Shipment->display_Record( -truncate => 40 );
        if ( $type eq 'Export' ) {

            # option to allow 'Export' shipment to be changed to 'Roundtrip' shipment
            $left
                .= alDente::Form::start_alDente_form( $dbc, 'Convert_to_Roundtrip' )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
                . $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 )
                . $q->submit( -name => 'rm', -value => 'Convert To Roundtrip Shipment', -class => 'Action', -force => 1 )
                . $q->hidden( -name => 'Shipment_Type', -value => 'Roundtrip', -force => 1 )
                . $q->end_form('Convert_to_Roundtrip');
        }
    }
    elsif ( $type eq 'Roundtrip' ) {
        my $original = $Shipment->value('FKOriginal_Shipment__ID');
        if ($original) {
            my $Original_Shipment = new alDente::Shipment( -id => $original, -dbc => $dbc );
            return $self->home_page( -Shipment => $Original_Shipment, -dbc => $dbc, -id => $original );
        }

        Message("$type Shipment");

        my @children = $dbc->Table_find( 'Shipment', 'Shipment_ID', "WHERE FKOriginal_Shipment__ID = $id" );
        my $status = $Shipment->value('Shipment_Status');

        if ( int(@children) == 0 ) {    # if no children, allow 'Roundtrip' shipment to be converted to 'Export' shipment
            $left
                .= alDente::Form::start_alDente_form( $dbc, 'Convert_to_Export' )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
                . $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 )
                . $q->submit( -name => 'rm', -value => 'Convert To Export Shipment', -class => 'Action', -force => 1 )
                . $q->hidden( -name => 'Shipment_Type', -value => 'Export', -force => 1 )
                . $q->end_form('Convert_to_Export');
        }

        $top .= $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $id );
        $top .= $self->display_indirect_Shipment_links( -dbc => $dbc, -id => $id );
        $right = $self->side_Roundtrip_view( -dbc => $dbc, -id => $id, -Shipment => $Shipment );

        if ( $status =~ /Received/i ) {
            for my $child (@children) {
                $top .= '<HR>' . $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $child );
                $top .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $child );
                $left .= create_tree( -tree => { "Shipment $child Options " => $self->import_Shipment( -id => $child, -dbc => $dbc ) }, -default_open => 0 );
            }
        }
        elsif ( $status =~ /Sent/i && $children[0] ) {
            for my $child (@children) {
                $top .= '<HR>' . $self->get_shipment_logs( -dbc => $dbc, -shipment_id => $child );
                $top .= $self->display_direct_Shipment_links( -dbc => $dbc, -id => $child );
                $left .= create_tree( -tree => { "Shipment $child Options " => $self->import_Shipment( -id => $child, -dbc => $dbc ) }, -default_open => 0 );
            }
            $left .= '<HR>' . $self->roundtrip_Shipment( -id => $id, -dbc => $dbc, -Shipment => $Shipment );
        }
        elsif ( $status =~ /Sent/i ) {
            $left .= $self->roundtrip_Shipment( -id => $id, -dbc => $dbc, -Shipment => $Shipment );
        }

    }
    else {
        return $dbc->warning("Undefined Shipment_Type: $type");
    }

    # Display Attachements if any
    my ($sid) = $dbc->Table_find( 'Shipment', 'FK_Submission__ID', "WHERE Shipment_ID=$id" );

    if ($sid) {
        my $submission_view = $self->submission_attachment_view( -sid => $sid, -dbc => $dbc, -shipment_id => $id );
        if ($submission_view) { $right .= $submission_view }
    }

    if ( ( $current_status =~ /Sent/i || !$received_date || $received_date eq '0000-00-00 00:00:00' ) && $type =~ /Export/i ) {
        $left .= '<P>' . $self->_mark_Received_Shipment( -dbc => $dbc, -id => $id, -target_site => $target_site );
    }

    $homepage .= '<hr>' . Views::Table_Print( content => [ [ $top . '<HR>' . $left, $right ] ], print => 0 );
    return $homepage;
}

##############################
sub _mark_Received_Shipment {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'id' );
    my $id          = $args{-id};
    my $target_site = $args{-target_site};
    my $dbc         = $args{-dbc} || $self->{dbc};

    my $element_id = int( rand(1000) );
    my @options = ( 'Received', 'Lost' );

    my $block = alDente::Form::start_alDente_form( $dbc, 'Update_Shipment_Status' ) 
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 ) 
        . $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 )

        . &Views::Table_Print(
        title   => "Mark Shipment as Received",
        content => [
            [ 'Received: ', Show_Tool_Tip( textfield( -name => 'Receive_Date', -size => 20, -id => "Shipment_$element_id", -onclick => $BS->calendar( -id => "Shipment_$element_id" ) ), 'Enter the date that the shipment was received' ) ],
            [ 'at Site: ',  alDente::Tools::search_list( -dbc => $dbc,       -name => 'FKTarget_Site__ID', -default => $target_site, -force => 1 ) ],
            [ 'Comments: ', textfield( -name                  => 'Comments', -size => 30,                  -force   => 1 ) ],
            [   submit( -name => 'rm', -value => 'Update Shipment Status', -onClick => 'return validateForm(this.form)', -class => 'Action', -force => 1 ),
                Show_Tool_Tip( popup_menu( -name => 'Status', -values => \@options, -force => 1 ), "Update shipment status" )
            ]
        ],
        print => 0,
        width => 100
        )
        . vspace(10)
        . $q->end_form('Update_Shipment_Status');

    return $block;
}

################################
sub submission_attachment_view {
################################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $sid         = $args{-sid};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $shipment_id = $args{-shipment_id};
    my $view;

    my $preset = $self->get_Shipment_Presets( -shipment_id => $shipment_id, -dbc => $dbc );
    my $attach_ref = &SDB::Submission::get_attachment_list( -dbc => $dbc->dbc(), -sid => $sid );
    my $sow;
    my $contact_id;
    my $status;

    my @submission_info = $dbc->Table_find_array( 'Submission', [ 'Reference_Code', 'FK_Contact__ID', 'Submission_Status' ], "WHERE Submission_ID=$sid" );

    if ( scalar(@submission_info) > 0 ) {
        my @array = Cast_List( -list => $submission_info[0], -to => 'array', -delimiter => ',' );
        $sow        = $array[0];
        $contact_id = $array[1];
        $status     = $array[2];
    }

    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $path .= $sub_dir;

    if ($attach_ref) {
        my @links;
        foreach my $file (@$attach_ref) {
            my $output = ' ';
            my $link = &SDB::Submission::get_attachment_link( -dbc => $dbc->dbc(), -sid => $sid, -file => $file );
            $output .= $file . "&nbsp" . "<a href=$link>View</a>";

            if ( $file =~ /\.xls$/ ||  $file =~ /\.xlsx$/) {
                $output
                    .= alDente::Form::start_alDente_form( -dbc => $dbc )
                    . $q->hidden( -name => 'cgi_application', -value => 'SDB::Import_App',                                   -force => 1 )
                    . $q->hidden( -name => 'template_file',   -value => '--- Select Template (optional) ---',                -force => 1 )
                    . $q->hidden( -name => 'input_file_name', -value => "$path/$status/submission_${sid}/attachments/$file", -force => 1 )
                    . Safe_Freeze( -name => "Preset", -value => $preset, -format => 'hidden', -encode => 1 )
                    . $q->submit( -name => 'rm', -value => 'Upload', -onClick => 'return validateForm(this.form)', -class => 'Action' )
                    . $q->end_form();
            }
            else {
                $output .= "<br>";
            }
            push @links, $output;
        }
        $view = "<BR><BR>" . create_tree( -tree => { "Submission Attachments ($sow)" => \@links }, -default_open => 1 );
    }

    return $view;
}

#########################
sub side_Roundtrip_view {
#########################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $id       = $args{-id};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $Shipment = $args{-Shipment};

    my @children = $dbc->Table_find( 'Shipment', 'Shipment_ID', "WHERE FKOriginal_Shipment__ID = $id" );
    my $side; ## = $Shipment->display_Record( -truncate => 40 );

    for my $child (@children) {
        my $child_Shipment = new alDente::Shipment( -id => $child, -dbc => $dbc );
        $side .= vspace . $child_Shipment->display_Record( -truncate => 40 );
    }
    return $side;
}

#######################################
sub display_indirect_Shipment_links {
#######################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id};

    my $page;
    ## internal or exported (tracked vi,a shipped_object)
    my @objects = ( 'Source', 'Equipment', 'Rack' );
    $page .= $self->plate_Records( -id => $id, -dbc => $dbc );

    foreach my $object (@objects) {
        my $ids = join ',', $dbc->Table_find( 'Shipped_Object,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = '$object' AND FK_Shipment__ID IN ($id)" );
        if ( $ids =~ /\d/ ) {
            ## cannot currently use Table_retrieve + display_hash (as above) with auto-linking fields if prompts replace field names ##
            my $current = $dbc->Table_retrieve_display(
                $object,
                ['*'],
                "WHERE ${object}_ID IN ($ids)",
                -title              => "Current $object linked to this Shipment",
                -return_html        => 1,
                -alt_message        => "[No $object records linked to this Shipment]",
                -include_attributes => 1,
                -print_link         => 1,
                -excel_link         => 1,
                -table_class => 'dataTable',
            );
            $page .= create_tree( -tree => { "Current $object records tied to this shipment" => $current } );
        }
        else {
            $page .= "[No $object records linked to this Shipment]<BR><BR>";
        }
    }

    return $page;
}

#######################################
sub plate_Records {
#######################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id};
    my $page;
    my $ids = join ',', $dbc->Table_find( 'Shipped_Object,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Plate' AND FK_Shipment__ID IN ($id) " );
    if ( $ids =~ /\d/ ) {

        my $tables = 'Plate LEFT JOIN Plate_Tray ON FK_Plate__ID = Plate_ID';
        my @fields = (
            'Plate_ID as ID',              'FK_Library__Name AS Library', 'CONCAT("PLA",Plate_ID) AS Barcode', 'FK_Tray__ID AS Tray',                 'Plate_Position',                      'Plate_Number',
            'FK_Pipeline__ID as Pipeline', 'Plate_Created',               'Plate.FK_Employee__ID as Employee', 'FK_Plate_Format__ID as Plate_Format', 'Plate_Size',                          'FKParent_Plate__ID',
            'Plate_Status',                'FK_Rack__ID as Rack_ID',      'FK_Rack__ID as Rack',               'Current_Volume',                      'Current_Volume_Units',                'Plate_Test_Status',
            'Parent_Quadrant',             'Plate_Parent_Well',           'QC_Status',                         'Plate_Type',                          'FKOriginal_Plate__ID',                'FK_Branch__Code',
            'Plate_Label',                 'Plate_Comments',              'FKLast_Prep__ID',                   'FK_Sample_Type__ID AS Sample_Type',   'FK_Work_Request__ID AS Work_Request', 'Plate_Class'
        );

        my %attributes = $dbc->Table_retrieve( 'Plate_Attribute, Attribute', [ 'Attribute_ID', 'Attribute_Name' ], "WHERE FK_Attribute__ID = Attribute_ID AND FK_Plate__ID IN ($ids) GROUP BY Attribute_ID" );
        my $count = int @{ $attributes{Attribute_ID} } if $attributes{Attribute_ID};

        for my $index ( 0 .. $count - 1 ) {
            my $temp_name  = $attributes{Attribute_Name}[$index];
            my $temp_id    = $attributes{Attribute_ID}[$index];
            my $temp_table = "ATT" . $temp_id;
            $tables .= " LEFT JOIN Plate_Attribute AS $temp_table ON $temp_table\.FK_Attribute__ID = $temp_id  AND $temp_table\.FK_Plate__ID = Plate_ID ";    #
            push @fields, "$temp_table\.Attribute_Value AS $temp_name";
        }

        my $current = $dbc->Table_retrieve_display(
            $tables, \@fields,
            "WHERE Plate_ID IN ($ids) ",
            -title              => "Current Plates linked to this Shipment",
            -return_html        => 1,
            -alt_message        => "[No Plate records linked to this Shipment]",
            -include_attributes => 1,
            -print_link         => 1,
            -excel_link         => 1,
            -table_class => 'dataTable',
        );
        $page .= create_tree( -tree => { "Current Plate records tied to this shipment" => $current } );
    }
    else {
        $page .= "[No Plate records linked to this Shipment]<BR><BR>";
    }

    return $page;
}

#########################
sub display_direct_Shipment_links {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id};
    my $page;
    my ( $current_sources, $hash ) = $dbc->Table_retrieve_display(
        'Shipment, Source, Original_Source',
        [ 'FK_Original_Source__ID as Original_Source', 'Source_ID as Source', 'External_Identifier', 'Received_Date', 'FKReceived_Employee__ID as Received_Employee', 'FK_Rack__ID as Location', 'Notes' ],
        "WHERE FK_Original_Source__ID=Original_Source_ID AND FK_Shipment__ID=Shipment_ID AND Shipment_ID IN ($id)",
        -title       => 'Current Sources linked to this Shipment',
        -alt_message => 'No sources tied to this shipment so far',
        -return_html => 1,
        -return_data => 1,
        -width       => '100%',
        -table_class => 'dataTable',

    );

    my $records = 0;
    if ( defined $hash->{Notes} ) { $records = int( @{ $hash->{Notes} } ) }

    if ( $records > 0 ) {
        $page .= create_tree( -tree => { "Current Sources [$records] linked to this Shipment" => $current_sources }, -default_open => 1 ) . '<p ></p>';
    }
    else { $page .= '[No Sources currently originated from this Shipment]<p ></p>'; }
    return $page;

}

#########################
sub display_Shipments {
#########################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $dept   = $args{-limit};                 # limits it to shipments sent from and to this department
    my $layers = $args{-layers};                # allow override offsetndard layer generated

    my $grp_ids;
    my $page = page_heading("Summary of Recent and Outstanding Shipments");

    if ($dept) {
        $grp_ids = join ',', $dbc->Table_find( 'Grp,Department', 'Grp_ID', "WHERE FK_Department__ID = Department_ID and Department_Name LIKE '$dept' and Grp_Name <> 'public'", -distinct => 1 );
    }

    my $last_month = substr( date_time( -offset => '-30d' ), 0, 10 );

    if ($grp_ids) {
        $layers->{"Last 30 Days"} = $self->recent_shipments( -dbc => $dbc ) if ( !$layers->{"Last 30 Days"} );
        $layers->{"Internal Incoming"} = $self->display_export_Shipments( -dbc => $dbc, -type => 'Internal', -to     => $grp_ids, -status => 'Sent' )          if ( !$layers->{"Internal Incoming"} );
        $layers->{"Internal Outgoing"} = $self->display_export_Shipments( -dbc => $dbc, -type => 'Internal', -from   => $grp_ids, -status => 'Sent' )          if ( !$layers->{"Internal Outgoing"} );
        $layers->{"External Exported"} = $self->display_export_Shipments( -dbc => $dbc, -type => 'Export',   -groups => $grp_ids, -status => 'Sent,Exported' ) if ( !$layers->{"External Exported"} );
        $layers->{"External Import"} = $self->display_export_Shipments( -dbc => $dbc, -groups => $grp_ids, -condition => "Shipment_Received >= '$last_month'" ) if ( !$layers->{"External Import"} );
        $layers->{"Roundtrip"} = $self->display_Roundtrip_Shipments( -dbc => $dbc, -groups => $grp_ids, -condition => "(Incoming.Shipment_Status IS NULL OR Incoming.Shipment_Status NOT IN ('Received'))" ) if ( !$layers->{"Roundtrip"} );
        $layers->{"Search"} = $self->shipment_search_box( -dbc => $dbc ) if ( !$layers->{"Search"} );
        $page .= define_Layers( -layers => $layers, -return_html => 1, -order => [ "Last 30 Days", 'Internal Incoming', 'Internal Outgoing', 'External Exported', 'External Import', 'Roundtrip', 'Search' ] );
    }
    else {
        $layers->{"Import"} = $self->display_import_Shipments( -dbc => $dbc, -status => 'Sent' ) if ( !$layers->{"Import"} );
        $layers->{"Internal"} = $self->display_export_Shipments( -dbc => $dbc, -type => 'Internal', -status => 'Sent' ) if ( !$layers->{"Internal"} );
        $layers->{"Export"}   = $self->display_export_Shipments( -dbc => $dbc, -type => 'Export',   -status => 'Sent' ) if ( !$layers->{"Export"} );
        $layers->{"Search"} = $self->shipment_search_box( -dbc => $dbc ) if ( !$layers->{"Search"} );
        $page = define_Layers( -layers => $layers, -return_html => 1, -order => [ 'Import', 'Internal', 'Export', 'Search' ] );
    }

    return $page;
}

#####################
sub recent_shipments {
#####################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $last_month = substr( date_time( -offset => '-30d' ), 0, 10 );

    my $table = $dbc->Table_retrieve_display(
        "Shipment LEFT JOIN Source ON FK_Shipment__ID = Shipment_ID LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
                LEFT JOIN Anatomic_Site ON FK_Anatomic_Site__ID=Anatomic_Site_ID ",
        [   'Shipment_ID as Shipment',
            'Shipment_Type',
            'Shipment.FKSupplier_Organization__ID as Supplier',
            'Shipment_Sent',
            'Shipment_Received',
            'FKFrom_Grp__ID as From_Group',
            'FKTarget_Grp__ID as To_Group',
            'FK_Sample_Type__ID',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
            'GROUP_CONCAT(DISTINCT Anatomic_Site_Alias) as Tissues'
        ],
        "WHERE 1 AND Shipment_Sent > '$last_month'
					GROUP BY Shipment_ID  
					ORDER BY Shipment_ID DESC",
        -return_html   => 1,
        -title         => 'Shipments for the last 30 days',
        -total_columns => 'Samples,Sources,Specimens',
        -print_link    => 'recent_shipments',
        -table_class => 'dataTable',
    );

    return $table;
}

###############################
sub display_import_Shipments {
###############################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $grp_ids = $args{-groups};                # limits it to shipments sent from and to this groups [list of ids comma seperated]
    my $from    = $args{-from};                  # limits it to shipments to sent from this groups [list of ids comma seperated]
    my $to      = $args{-to};                    # limits it to shipments tp sent to and to this groups [list of ids comma seperated]
    my $status  = $args{-status};

    my $condition = "WHERE Shipment_Type = 'Import'";
    if ($grp_ids) {
        $condition .= " AND (FKFrom_Grp__ID  IN ($grp_ids) OR FKTarget_Grp__ID IN ($grp_ids) )";
    }
    elsif ($from) {
        $condition .= " AND FKFrom_Grp__ID  IN ($from) ";
    }
    elsif ($to) {
        $condition .= " AND FKTarget_Grp__ID IN ($to) ";
    }

    if ($status) { $condition .= " AND Shipment_Status = '$status'" }

    my $table = $dbc->Table_retrieve_display(
        "Shipment LEFT JOIN Source ON FK_Shipment__ID = Shipment_ID LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
                LEFT JOIN Sample_Type ON FK_Sample_Type__ID=Sample_Type_ID 
                LEFT JOIN Project ON FKReference_Project__ID = Project_ID
                ",
        [   'Shipment_ID as Shipment',
            'Shipment_Status',
            'GROUP_CONCAT(DISTINCT Project_Name) as Project',
            'Shipment.FKSupplier_Organization__ID as Supplier',
            'Shipment_Sent',
            'Shipment_Received',
            'FK_Submission__ID as Submission',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
        ],
        "  $condition
        GROUP BY Shipment_ID  
        ORDER BY Shipment_ID DESC",
        -return_html     => 1,
        -title           => 'Current Samples',
        -total_columns   => 'Samples,Sources,Specimens',
        -style           => 'font-size:80%',
        -list_in_folders => ['Plates'],
        -print_link      => 'import_shipments',
        -table_class => 'dataTable',
        
    );
    return $table;
}

################################
sub display_export_Shipments {
################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $type      = $args{-type};
    my $grp_ids   = $args{-groups};                # limits it to shipments sent from and to this groups [list of ids comma seperated]
    my $from      = $args{-from};                  # limits it to shipments to sent from this groups [list of ids comma seperated]
    my $to        = $args{-to};                    # limits it to shipments tp sent to and to this groups [list of ids comma seperated]
    my $status    = $args{-status};
    my $condition = $args{-condition} || 1;
    my $debug     = $args{-debug};

    if ($type) { $condition .= " AND Shipment_Type = '$type' " }

    if ($grp_ids) {
        $condition .= " AND (FKFrom_Grp__ID  IN ($grp_ids) OR FKTarget_Grp__ID IN ($grp_ids) )";
    }
    elsif ($from) {
        $condition .= " AND FKFrom_Grp__ID  IN ($from) ";
    }
    elsif ($to) {
        $condition .= " AND FKTarget_Grp__ID IN ($to) ";
    }

    if ($status) {
        $status = Cast_List( -list => $status, -to => 'string', -autoquote => 1 );
        $condition .= " AND Shipment_Status IN ($status)";
    }

    my ($src_object_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = 'Source'");
    my ($pla_object_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = 'Plate'");

    my $table = $dbc->Table_retrieve_display(
        "Shipment 
            LEFT JOIN Shipped_Object as Source_Shipped ON Source_Shipped.FK_Shipment__ID = Shipment_ID AND Source_Shipped.FK_Object_Class__ID = $src_object_id
            LEFT JOIN Source ON Source_Shipped.Object_ID = Source_ID
            LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
            LEFT JOIN Project as Source_Project ON FKReference_Project__ID = Source_Project.Project_ID
            LEFT JOIN Shipped_Object as Plate_Shipped ON Plate_Shipped.FK_Shipment__ID = Shipment_ID AND Plate_Shipped.FK_Object_Class__ID = $pla_object_id
            LEFT JOIN Plate ON Plate_Shipped.Object_ID = Plate_ID
            LEFT JOIN Library ON FK_Library__Name = Library_Name
            LEFT JOIN Project as Plate_Project on FK_Project__ID = Plate_Project.Project_ID
            ",

        [   'Shipment_ID as Shipment',
            'Shipment_Status',
            'GROUP_CONCAT(DISTINCT Source_Project.Project_Name) as Source_Project',
            'GROUP_CONCAT(DISTINCT Plate_Project.Project_Name) as Plate_Project',
            'Count(Distinct Source_ID) as Source_Count',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Count(Distinct Plate_ID) as Plates_Count',
            'FKSender_Employee__ID as Sender',
            'FKRecipient_Employee__ID as Receiver',
            'FKFrom_Grp__ID as From_Group',
            'FKTarget_Grp__ID as To_Group',
            'Shipment_Sent',
            'Shipment_Received',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
        ],
        "WHERE $condition
        GROUP BY Shipment_ID  
        ORDER BY Shipment_ID DESC",
        -return_html   => 1,
        -title         => 'Current Samples',
        -total_columns => 'Samples,Sources,Specimens',
        -style         => 'font-size:80%',
        -print_link    => 'export_shipments',
        -debug         => $debug,
        -table_class => 'dataTable',
        
    );
    return $table;
}

#########################
sub roundtrip_Shipment {
#########################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $id       = $args{-id};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $Shipment = $args{-Shipment};

    my $from   = $Shipment->value('FKFrom_Grp__ID');
    my $target = $Shipment->value('FKTarget_Grp__ID');
    my $select;

    my $rack_list = join ',', $dbc->Table_find( 'Shipped_Object,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Rack' AND FK_Shipment__ID IN ($id)" );
    my @racks = $dbc->Table_find( 'Rack,Equipment,Location', 'Rack_ID', "WHERE FK_Equipment__ID=Equipment_ID AND FK_Location__ID = Location_ID AND Location_Name = 'In Transit' AND Rack_ID IN ($rack_list) " ) if $rack_list;

    if (@racks) {
        for my $r_id (@racks) {
            $select .= checkbox( -name => 'Rack_List', -value => $r_id, -label => "RAC" . $r_id, -checked => 1 ) . vspace();
        }
    }

    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . set_validator( -name => 'FK_Site__ID', -mandatory => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
        . $q->hidden( -name => 'shipment_id', -value => $id, -force => 1 )
        . $select
        . $q->submit( -name => 'rm', -value => 'Receive Roundtrip Shipment', -onClick => 'return validateForm(this.form)', -class => 'Action' );

    if ( my $site_id = $dbc->session->{site_id} ) {
        $page .= $q->hidden( -name => 'FK_Site__ID', -value => $site_id, -force => 1 );
        $page .= ' at ' . alDente_ref( 'Site', $site_id, -dbc => $dbc );
    }
    else {
        $page .= ' at: ' . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Site__ID' );
    }
    $page .= $q->end_form();
    
    return $page;

}

#########################
sub import_Shipment {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $dbc  = $args{-dbc} || $self->{dbc};

    my ($layers, $order, $default) = $self->import_Layers(%args);

    my $page = define_Layers(-layers=>$layers, -order=>$order, -default=>$default, -return_html=>1);

    return $page;
}

####################
sub import_Layers {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $dbc  = $args{-dbc} || $self->{dbc};

    ## Generate interface view for single Shipment object ##
    my @types = $dbc->get_enum_list( -table => 'Source', -field => 'FK_Sample_Type__ID' );
    my $include = $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 ) . '<P>Define New Source Material Records: <BR>';

    #		    . radio_group(-name=>'Source_Type', -values=>\@types);
    my $new_include = SDB::HTML::query_form( -name => 'shipment_link', -fields => [ 'Source.FK_Sample_Type__ID', 'Source.FK_Original_Source__ID' ], -submit => 0, -dbc => $dbc );
    $new_include .= '<BR> Repeat X ' . $q->textfield( -name => 'Sample_Type Count', -size => 10 );
    my $existing_include = $q->textfield( -name => 'Source_ID', -size => 50 );

    my %layers;
    my $new_layer = alDente::Attribute_Views::choose_Attributes( -dbc => $dbc, -class => 'Source', -include => $include . $new_include, -cgi_application => 'alDente::Shipment_App', -rm => 'Define New Sample Sources linked to Shipment' );
    $layers{'Define New Sources'} = $new_layer;

    ## generate layer for uploading sources from a template file ##
    my $std_template_upload = $self->upload_new_sources_view( -dbc => $dbc, -shipment_id => $id );
    my $reserved_source_upload = $self->reserved_Source_Upload( -dbc  => $dbc, -shipment_id => $id );    
    my $library_upload = $self->library_Upload( -dbc          => $dbc, -shipment_id => $id );
 
    $layers{'Upload'} = 
        '<P>'
        . $BS->modal( -body => $std_template_upload, -label=> 'Standard Template Upload', -style=>'width:100%;', -class=>'btn Std')
        . '<P>'
        . $BS->modal( -body => $reserved_source_upload, -label=> 'Upload Data for Reserved Source Records', -class=>'btn Std')
        . '<P>'        
        . $BS->modal( -body => $library_upload, -label=> 'Upload Library Data for Existing Source Records', -class=>'btn Std');
    
 
    $layers{'Link to Pre-defined Sources'} = $self->link_Source_Shipment( -dbc    => $dbc, -shipment_id => $id );
    
    if ($dbc->table_populated('Goal')) { $layers{'Add Goals'} = $self->add_Goals( -dbc => $dbc, -shipment_id => $id ) }
    
    my @order = ( 'Define New Sources', 'Link to Pre-defined Sources', 'Upload', 'Add Goals' );
    my $default = 'Upload';

    return (\%layers, \@order, $default);
}

##############################
sub add_Goals {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, 'ids' );
    my $dbc         = $args{-dbc};
    my $shipment_id = $args{-shipment_id};
    my $q           = new CGI;
    require alDente::Work_Request_Views;

    my @srcs = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FK_Shipment__ID = $shipment_id" );
    unless ( $srcs[0] ) { return "No sources attached to this shipment" }

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -form => 'add_goals' ) . $q->hidden( -name => 'Mark', -value => \@srcs, -force => 1 ) . alDente::Work_Request_Views::add_goal_btn( -dbc => $dbc, -object => 'Source' ) . $q->end_form();

    return $page;
}

########################
sub receive_Samples {
########################

    #
    # Generic home page for receiving samples
    #
    #
    #
    #
########################
    my %args = &filter_input( \@_, -self => 'alDente::Shipment_Views' );

    my $self = $args{-self};
    my $dbc = $args{-dbc} || $self->{dbc};

    my %layers;

    my $new_Shipment = new SDB::DB_Form( -table => 'Shipment', -dbc => $dbc );

    my ($external)      = $dbc->Table_find( 'Grp',  'Grp_ID',  "WHERE Grp_Name = 'External'" );     ## standard external group
    my ($external_site) = $dbc->Table_find( 'Site', 'Site_ID', "WHERE Site_Name = 'External'" );    ## Standard external site (internal sites should be internally shipped)

    $new_Shipment->configure(
        -grey => {
            'Shipment_Type'   => 'Import',
            'FKFrom_Grp__ID'  => $external,
            'Shipment_Status' => 'Received',
            'FKRecipient_Employee__ID' => $dbc->config('user_id'),
        },
        -omit    => { 'FKSender_Employee__ID' => '', 'FKTransport_Rack__ID'     => '', 'Addressee' => '' },
        -require => { 'Waybill_Number'        => 1,  'FK_Package_Condition__ID' => 1 },
        -preset  => { 'FKFrom_Site__ID'       => $external_site },    );

    my $import = $new_Shipment->generate( -return_html => 1, -navigator_on => 0, -mode=>'Finish');

    my $internal = alDente::Form::start_alDente_form( $dbc, 'Internal_Shipment' ) 
        . '<h2>Receiving Internally Shipped Samples</h2>' 
        . "Scan shipping container in the scan box and continue from rack homepage to receive the box.";

    $layers{'Imported Shipment from Collaborator'} = $import;
    $layers{'Internal Shipment'}                   = $internal;

    $layers{'Pending Shipments'} = $dbc->Table_retrieve_display( 'Shipment', ['*'], "WHERE Shipment_Received like '0%'", -return_html => 1, -title => 'Shipments Pending Receipt', -table_class => 'dataTable');

    return define_Layers( -layers => \%layers, -return_html => 1 );

}

##################################
sub get_shipment_logs {
##################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $id   = $args{-shipment_id};
    my $dbc  = $args{-dbc} || $self->dbc;
    
    my $manifest_files = $self->Model->manifest_file( -scope => 'Shipment', -id => $id );
    my @log_files = alDente::Shipment::log_files( -id => $id, -dbc => $dbc);

    my $page;

    if ($manifest_files) {
        my @links = split "\n", `ls $manifest_files`;
        if ( @links && $links[0] !~ /No such file/ ) {
            $page .= "Shipment Logs for $id:<UL>";
            foreach my $log (@links) {
                my $name = $log;
                if ( $log =~ /(dynamic\/logs\/)(.+)$/ ) { $name = $2 }
                $page .= '<LI>' . Link_To( "../dynamic/logs/$name", "$name" );
            }
            $page .= '</UL>';
        }
        else { $page .= "(no manifests found for Shipment $id)</P>($manifest_files ?)<P>" }
    }
    else { $page .= "(No manifests found for Shipment $id)</P>" }

    if (@log_files) {
        $page .= "Shipment Logs for $id:<UL>";
        for my $log (@log_files) {
            my $name = $log;
            if ( $log =~ /(dynamic\/logs\/)(.+)$/ ) { $name = $2 }
            $page .= '<LI>' . Link_To( "../dynamic/logs/$name", "$name" );
        }
        $page .= '</UL>';
    }

    return $page;
}

#################
sub list_page {
#############################################################
    # Standard view for multiple Shipment records if applicable
    #
    # Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $ids  = $args{-ids};

    my $Shipment = $self->{Shipment};
    my $dbc      = $Shipment->{dbc};

    my $page = $dbc->Table_retrieve_display( 'Shipment', ['*'], "WHERE Shipment_ID IN ($ids)", -return_html => 1, -table_class => 'dataTable');

    return $page;
}

##############################
sub link_Source_Shipment {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, 'ids' );
    my $dbc         = $args{-dbc};
    my $shipment_id = $args{-shipment_id};
    my $q           = new CGI;
    my $page        = alDente::Form::start_alDente_form( -dbc => $dbc, -form => 'confirm_redistribution' );
    $page .= 'Linking Pre-Defined Sources to External Shipment:<P>';
    $page .= $q->textfield( -name => 'Sources', -size => 50 ) . vspace();
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 );
    $page .= $q->hidden( -name => 'Shipment_ID', -value => $shipment_id, -force => 1 );
    $page .= Show_Tool_Tip(
        $q->submit(
            -name  => 'rm',
            -value => 'Link Shipment and Sources',
            -class => 'Action',
            -force => 1
        ),
        'Scan one or more Source IDs (e.g. src12345) to link to this shipment'
    );
    $page .= $q->end_form();

    return $page;
}

##############################
sub library_Upload {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, 'ids' );
    my $dbc         = $args{-dbc} || $self->dbc;
    my $shipment_id = $args{-shipment_id};
    my $q           = new CGI;
    
    my $path        = alDente::Tools::get_directory(
        -structure => 'DATABASE',
        -root      => $dbc->config('shipment_logs'),
        -dbc       => $dbc
    );

    my @replace = ( 'Source.Source_Created', 'Source.Sample_Collection_Time', 'Source.FKReference_Project__ID', 'Source.FK_Barcode_Label__ID', 'Source.FKReceived_Employee__ID', 'Source.FK_Shipment__ID', 'Source.Received_Date', 'Source.Source_Status', );

    my @replace_html = ( Safe_Freeze( -name => "Replace", -value => \@replace, -format => 'hidden', -encode => 1 ) . $q->hidden( -name => 'shipment_id', -value => $shipment_id, -force => 1 ) );

    my $timestamp = now();
    $timestamp =~ s/\-/\_/g;
    $timestamp =~ s/ /\_\_/g;
    $timestamp =~ s/\:/\_/g;

    my $log_file = "Shipment_" . $shipment_id . '____' . $timestamp . '.html';

    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    return $Import_View->upload_file_box(
        -Link_Log_File   => $path . $log_file,
        -extra           => \@replace_html,
        -type            => 'Xref_File',
        -button          => $q->submit( -name => 'rm', -value => 'Upload Library Info', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form, 4)' ),
        -cgi_application => 'alDente::Shipment_App',
        -dbc             => $dbc,

    );
}

##############################
sub reserved_Source_Upload {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, 'ids' );
    my $dbc         = $args{-dbc} || $self->dbc();
    my $shipment_id = $args{-shipment_id};
    my $q           = new CGI;
    
    my $path        = alDente::Tools::get_directory(
        -structure => 'DATABASE',
        -root      => $dbc->config('shipment_logs'),
        -dbc       => $dbc
    );

    my @replace = ( 'Source.Source_Created', 'Source.Sample_Collection_Time', 'Source.FKReference_Project__ID', 'Source.FK_Barcode_Label__ID', 'Source.FKReceived_Employee__ID', 'Source.FK_Shipment__ID', 'Source.Received_Date', 'Source.Source_Status', );

    my @replace_html = ( Safe_Freeze( -name => "Replace", -value => \@replace, -format => 'hidden', -encode => 1 ) );

    my $timestamp = now();
    $timestamp =~ s/\-/\_/g;
    $timestamp =~ s/ /\_\_/g;
    $timestamp =~ s/\:/\_/g;

    my $log_file    = "Shipment_" . $shipment_id . '____' . $timestamp . '.html';
    my $preset      = $self->get_Shipment_Presets( -shipment_id => $shipment_id, -dbc => $dbc );
    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    return $Import_View->upload_file_box( -Link_Log_File => $path . $log_file, -preset => $preset, -extra => \@replace_html );
}

##############################
sub upload_new_sources_view {
##############################
    my $self        = shift;
    my %args        = filter_input( \@_, 'ids' );
    my $dbc         = $args{-dbc} || $self->dbc;
    my $shipment_id = $args{-shipment_id};
    my $q           = new CGI;
    
    my $path        = alDente::Tools::get_directory(
        -structure => 'DATABASE',
        -root      => $dbc->config('shipment_logs'),
        -dbc       => $dbc
    );
    my $timestamp = now();
    $timestamp =~ s/\-/\_/g;
    $timestamp =~ s/ /\_\_/g;
    $timestamp =~ s/\:/\_/g;

    my $log_file    = "Shipment_" . $shipment_id . '____' . $timestamp . '.html';
    my $preset      = $self->get_Shipment_Presets( -shipment_id => $shipment_id, -dbc => $dbc );
    my $Import_View = new SDB::Import_Views( -dbc => $dbc );
    return $Import_View->upload_file_box( -Link_Log_File => $path . $log_file, -preset => $preset );
}

#######################
sub get_Shipment_Presets {
#######################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-shipment_id};

    my %info = $dbc->Table_retrieve( 'Shipment', ['(Shipment_Received) AS Shipped'], "WHERE Shipment_ID = $id" );
    my $received_date = $info{Shipped}[0];

    my %preset = ( 'Source.FK_Shipment__ID' => $id );
    if ($received_date) {
        $preset{'Source.Received_Date'} = $received_date;
    }
    return \%preset;

}

#######################
sub move_Rack_page {
#######################
    my $self      = shift;
    my %args      = filter_input( \@_, 'ids' );
    my $dbc       = $args{-dbc};
    my $rack      = $args{-rack};
    my $type      = $args{-type};
    my $ids       = $args{-ids};
    my $locations = $args{-locations};
    my $q         = new CGI;

    my $page = alDente::Form::start_alDente_form( $dbc, 'confirm_redistribution' );
    $page .= 'Relocating Items:<P>';

    $page .= alDente::Rack::move_Items( -ids => $ids, -rack => $rack, -type => $type, -dbc => $dbc, -locations => $locations );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );
    $page .= $q->submit(
        -name  => 'rm',
        -value => 'Confirm Re-Distribution',
        -class => 'Action',
        -force => 1
    );
    $page .= $q->end_form();
    return $page;
}

#########################
sub Roundtrip_prompt {
#########################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $id        = $args{-id};
    my $dbc       = $args{-dbc};
    my $Shipment  = $args{-Shipment};
    my $site_id   = $args{-site_id};
    my $rack_list = $args{-rack_list};

    my $org_obj = new alDente::Organization( -dbc => $dbc );
    my $local_org = $org_obj->get_Local_organization();
    my ($user_name)    = $dbc->get_FK_info( 'FK_Employee__ID', $dbc->get_local('user_id') );
    my ($site_name)    = $dbc->get_FK_info( 'FK_Site__ID',     $site_id );
    my ($from_name)    = $dbc->get_FK_info( 'FK_Grp__ID',      $Shipment->value('FKFrom_Grp__ID') );
    my ($target_name)  = $dbc->get_FK_info( 'FK_Grp__ID',      $Shipment->value('FKTarget_Grp__ID') );
    my ($contact_name) = $dbc->get_FK_info( 'FK_Contact__ID',  $Shipment->value('FK_Contact__ID') );
    my ($from_site)    = $dbc->get_FK_info( 'FK_Site__ID',     $Shipment->value('FKTarget_Site__ID') );

    my $shipment_form = new SDB::DB_Form( -dbc => $dbc, -table => 'Shipment', -db_action => 'append', -wrap => 0 );
    $shipment_form->configure(
        -grey => {
            'FKSupplier_Organization__ID' => $local_org,
            'Shipment_Status'             => 'Received',
            'Shipment_Type'               => 'Roundtrip',
            'FKOriginal_Shipment__ID'     => $id,
            'FKTarget_Site__ID'           => $site_name,
            'FKRecipient_Employee__ID'    => $user_name,
            'FKFrom_Site__ID'             => $from_site,
            'FK_Contact__ID'              => $contact_name,
        },
        -omit => {
            'FK_Submission__ID'     => '',
            'FKSender_Employee__ID' => ''
        },
        -preset => {
            'Shipment_Received' => date_time(),
            'FKFrom_Grp__ID'    => $target_name,
            'FKTarget_Grp__ID'  => $from_name,
        }
    );
    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . $shipment_form->generate( -return_html => 1, -wrap => 0, -submit => 0, -navigator_on => 0 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Shipment_App', -force => 1 )
        . $q->hidden( -name => 'ID',              -value => $id,                     -force => 1 )
        . $q->hidden( -name => 'confirmed',       -value => 1,                       -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Receive Roundtrip Shipment', -onClick => 'return validateForm(this.form)', -class => 'Action' );

    if ($rack_list) {
        $page .= $q->hidden( -name => 'Rack_List', -value => $rack_list, -force => 1 );
    }

    $page .= $q->end_form();
    return $page;
}

#########################
sub shipment_search_box {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    require SDB::DB_Object_Views;
    return SDB::DB_Object_Views::search_form( -dbc => $dbc, -table => 'Shipment' );

}

##################################
sub display_Roundtrip_Shipments {
##################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $id        = $args{-id};
    my $dbc       = $args{-dbc};
    my $grp_ids   = $args{-groups};           # limits it to shipments sent from and to this groups [list of ids comma seperated]
    my $status    = $args{-status};
    my $condition = $args{-condition} || 1;
    my $debug     = $args{-debug};

    $condition .= " AND Outgoing.FKOriginal_Shipment__ID IS NULL and Outgoing.Shipment_Type = 'Roundtrip'";
    if ($grp_ids) {
        $condition .= " AND (Outgoing.FKFrom_Grp__ID  IN ($grp_ids) OR Outgoing.FKTarget_Grp__ID IN ($grp_ids) OR Incoming.FKFrom_Grp__ID  IN ($grp_ids) OR Incoming.FKTarget_Grp__ID IN ($grp_ids))";
    }

    my $table = $dbc->Table_retrieve_display(
        "Shipment as Outgoing LEFT JOIN Shipment as Incoming ON Incoming.FKOriginal_Shipment__ID = Outgoing.Shipment_ID ",

        [   'Outgoing.Shipment_ID as Outgoing_Shipment',
            'Outgoing.Shipment_Status as Outgoing_Status',
            'Outgoing.FKSender_Employee__ID as Sender',
            'Outgoing.FKFrom_Grp__ID as Outgoing_From',
            'Outgoing.FKTarget_Grp__ID as Outgoing_To',
            'Outgoing.Shipment_Sent as Outgoing_Sent',
            'Outgoing.Shipment_Received as Outgoing_Received',
            'Incoming.Shipment_ID as Incoming_Shipment',
            'Incoming.Shipment_Status as Incoming_Status',
            'Incoming.FKRecipient_Employee__ID as Receiver',
            'Incoming.FKFrom_Grp__ID as Incoming_From',
            'Incoming.FKTarget_Grp__ID as Incoming_To',
            'Incoming.Shipment_Sent  as Incoming_Sent',
            'Incoming.Shipment_Received as Incoming_Received',
        ],
        "WHERE $condition
            ORDER BY Outgoing.Shipment_ID DESC",
        -return_html => 1,
        -title       => 'Rountrip Shipments',
        -print_link  => 'roundtrip_shipments',
        -table_class => 'dataTable',
        -debug       => $debug,
    );
    return $table;
}

#########################
sub Shipment_prompt {

    #
    # prompt users to Ship given manifest
    #
    # Required:
    #  * Rack object (with loaded manifest)
    #  * Shipment object (with specified source / target information)
    #
    #
    # Return: form with preset inputs
#########################
    my %args = filter_input( \@_, -mandatory => 'Rack,Shipment', -self => 'alDente::Shipment' );
    my $self = $args{-self};

    my $dbc                  = $args{-dbc};
    my $Rack                 = $args{-Rack};
    my $Shipment             = $args{-Shipment};
    my $sr_id                = $args{-sample_request_id};
    my $Manifest             = $Rack->{Manifest};
    my $org_obj              = new alDente::Organization( -dbc => $dbc );
    my $local_org            = $org_obj->get_Local_organization();
    my $shipped_container    = $Manifest->{scope};
    my $shipped_container_id = $Manifest->{transport_rack_id};
    my $user_id              = $dbc->get_local('user_id');

    my $source_site;
    if ($shipped_container_id) {
        ## determine local site from location of shipped container ##
        ($source_site) = $dbc->Table_find( 'Equipment,Rack,Location', 'FK_Site__ID', "WHERE Rack.FK_Equipment__ID=Equipment_ID AND Equipment.FK_Location__ID=Location_ID and Rack_ID = '$shipped_container_id'", -distinct => 1 );
    }

    my $form = alDente::Form::start_alDente_form( $dbc, 'Shipping list' );
    $form .= $q->hidden( -name => 'cgi_application',   -value => 'alDente::Shipment_App',  -force => 1 );
    $form .= $q->hidden( -name => 'Site_ID',           -value => $Shipment->{target_site}, -force => 1 );
    $form .= $q->hidden( -name => 'Shipped_Container', -value => $shipped_container,       -force => 1 );

    $form .= $q->hidden( -name => 'Shipped_Boxes', -value => $Manifest->{shipped_boxes}, -force => 1 );
    $form .= $q->hidden( -name => 'Plate_IDs',     -value => $Manifest->{plate_list},    -force => 1 );
    $form .= $q->hidden( -name => 'Source_IDs',    -value => $Manifest->{source_list},   -force => 1 );
    $form .= $q->hidden( -name => 'Rack_IDs',      -value => $Manifest->{rack_list},     -force => 1 );
    $form .= '<p ></p>';

    my %grey = (
        'FKSupplier_Organization__ID' => $local_org,
        'FKTransport_Rack__ID'        => $shipped_container_id,
        'FKFrom_Site__ID'             => $source_site,
        'Shipment_Status'             => 'Sent',
        'Shipment_Type'               => $Shipment->{type},
        'FKTarget_Site__ID'           => $Shipment->{target_site},
        'Addressee'                   => $Shipment->{target},
        'FKSender_Employee__ID'       => $Shipment->{shipper},
        'FKTarget_Grp__ID'            => $Shipment->{target_grp},
        'FKFrom_Grp__ID'              => $Shipment->{source_grp},
    );

    my %omit = (
        'FKRecipient_Employee__ID' => '',
        'Shipment_Received'        => '',
        'Received_at_Temp'         => '',
    );

    if ($sr_id) {
        my %info
            = $dbc->Table_retrieve( 'Sample_Request', [ 'Sample_Request_ID', 'Sample_Count', 'Sample_Request.Addressee', 'Sample_Request.FK_Contact__ID', 'Sample_Request.FK_Organization__ID', 'Request_Comments' ], "WHERE Sample_Request_ID = $sr_id" );
        $grey{'Addressee'}                   = $info{Addressee}[0];
        $grey{'FKRecipient_Employee__ID'}    = $user_id;
        $grey{'FKSupplier_Organization__ID'} = $info{FK_Organization__ID}[0];
        $grey{'FK_Sample_Request__ID'}       = $info{Sample_Request_ID}[0];
        $grey{'FK_Contact__ID'}              = $info{FK_Contact__ID}[0];
        $grey{'Shipment_Type'}               = 'Roundtrip';
        $omit{'FK_Submissoion__ID'}          = '';
    }

    ## add new shipment form ##
    use SDB::DB_Form;
    my $shipment_form = new SDB::DB_Form( -dbc => $dbc, -table => 'Shipment', -db_action => 'append', -wrap => 0 );

    $shipment_form->configure( -grey => \%grey, -omit => \%omit, -preset => { 'Shipment_Sent' => date_time() } );

    $form .= $shipment_form->generate( -return_html => 1, -wrap => 0, -submit => 0, -navigator_on => 0 );

    $form .= '<p ></p>';

    #    $form .= $q->textfield( -name=>'Shipment_Notes', -size=>'40', -force=>1);
    #    $form .= hspace(20);
    $form .= $q->submit( -name => 'rm', -value => 'Ship Samples', -onclick => 'return validateForm(this.form)', -class => 'Action', -force => 1 );

    $form .= $q->hidden( -name => 'Manifest', -value => $Manifest->{filename} );
    $form .= $q->end_form();

    return $form;
}

return 1;
