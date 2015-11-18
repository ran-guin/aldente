###################################################################################################################################
# alDente::Department_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Department_Views;

use CGI qw(:standard);
use base alDente::Object_Views;

use strict;
## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

my $q = new CGI;
########################
sub search_record_box {
########################
    my %args           = filter_input( \@_ );
    my $search_options = $args{-search};
    my $dbc            = $args{-dbc};
    my $admin          = $args{-admin};

    if ( !$search_options || int(@$search_options) == 0 ) { return '' }

    my $edit_option = checkbox( -name => 'Multi-Record', -label => 'Multi-Record Editing', -checked => 0 ) . '<BR>' if $admin;
    my ( $labels, $values ) = _get_Labels( -dbc => $dbc, -tables => $search_options );

    my $radio = &SDB::HTML::tidy_tags( radio_group( -name => 'Table', -values => $values, -labels => $labels, -columns => 1, -force => 1 ) );
    
    my $LV = new alDente::Login_Views(-dbc=>$dbc);
    my @search_records
        = (   $LV->icons( 'Search', -dbc => $dbc )
            . alDente::Form::start_alDente_form( $dbc, 'SearchCreate' ) . "\n"
            . $radio . "\n"
            . hr()
            . $edit_option . "\n"
            . hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 )
            . hidden( -name => 'Start Search', -value => 1 )
            . submit( -name => 'rm', -value => "Search Records", -class => 'search', -force => 1 ) . "\n"
            . end_form()
            . "\n" );

    my $search = HTML_Table->new( -title => 'Search Database', -align => 'top', -border => 1, -colour => "#eeeee8" );
    $search->Set_Headers( ['(Select item to search for below)'] );
    $search->Set_Row( \@search_records );

    my $search_box = $search->Printout(0);

    return $search_box;
}

#####################
sub display_TechD {
#####################
    my %args       = filter_input( \@_ );
    my $admin      = $args{'-admin'};
    my $department = $args{'-department'};
    my $dbc        = $args{-dbc};
    my $reduced    = $args{-reduced} || 0;

    my $define_config = alDente::Admin::_init_table('Define/Configure');
    &display_protocol_chemistry( -dbc => $dbc, -type => 'Lab_Protocol',      -html_table => $define_config, -department => $department );
    &display_protocol_chemistry( -dbc => $dbc, -type => 'Standard_Solution', -html_table => $define_config, -department => $department );

    my $output = &Views::Table_Print(
        content => [ [ $define_config->Printout(0) ] ],
        padding => 0,
        spacing => 4,
        print   => 0
    );

    return $output;
}

########################
sub _get_Labels {
########################
    my %args   = filter_input( \@_ );
    my $tables = $args{-tables};
    my $dbc    = $args{-dbc};
    my %labels;
    my @values;
    my $list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );
    my %results = $dbc->Table_retrieve( 'DBTable', [ 'DBTable_Name', 'DBTable_Title' ], "WHERE DBTable_Name IN ($list) ORDER BY DBTable_Title" ) if $list;
    my @names   = @{ $results{DBTable_Name} }                                                                                                    if $results{DBTable_Name};
    my @titles  = @{ $results{DBTable_Title} }                                                                                                   if $results{DBTable_Title};
    my $size    = @names;

    for my $index ( 0 .. $size - 1 ) {
        $labels{ $names[$index] } = $titles[$index];
        push @values, $names[$index];
    }

    return ( \%labels, \@values );
}

#####################
sub add_record_box {
#####################
    my %args        = filter_input( \@_ );
    my $admin       = $args{'-admin'} || 1;
    my $new_options = $args{'-new'};
    my $dbc         = $args{-dbc};

    my @add_records;
    my $add_records_table;
    my ( $labels, $values ) = _get_Labels( -dbc => $dbc, -tables => $new_options );

    my $add = HTML_Table->new( -title => 'Add New Records', -align => 'top', -border => 1, -colour => "#eeeee8" );
    $add->Set_Headers( ['(go to Library home page to add Libraries or Original Sources)'] );

    if ( $admin && $new_options && @$new_options ) {
        my $LV = new alDente::Login_Views(-dbc=>$dbc);
        
        my $radio = &SDB::HTML::tidy_tags( radio_group( -name => 'Table', -values => $values, -columns => 1, -force => 1, -labels => $labels ) );
        @add_records
            = (   $LV->icons( 'Changes', -dbc => $dbc )
                . alDente::Form::start_alDente_form( $dbc, 'AddRecords' ) . "\n"
                . $radio . "\n"
                . hr()
                . hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 )
                . submit( -name => 'rm', -value => 'Add Record', -class => 'Std', -force => 1 ) . "\n"
                . end_form()
                . "\n" );

        $add->Set_Row( \@add_records );
        $add_records_table = $add->Printout(0);
    }
    else {
        $add_records_table = '';
    }

    return $add_records_table;
}

#####################
sub convert_record_box {
######################
    my %args            = filter_input( \@_ );
    my $admin           = $args{'-admin'};
    my $convert_options = $args{-convert};
    my $dbc             = $args{-dbc};

    my @convert_records;
    my $add_records_table;

    my $convert_table = alDente::Form::start_alDente_form( $dbc, 'AddRecords' ) . "\n";

    my $Convert = HTML_Table->new( -title => 'Retrieve LIMS IDs', -align => 'top', -border => 1, -colour => "#eeeee8" );
    $Convert->Set_Headers( ['(convert standard identifier fields to LIMS IDs)'] );

    my $default = '-- select field to convert --';
    if ($convert_options) {
        unshift @$convert_options, $default;
    }
    else { $convert_options = ['-- no conversion fields defined --'] }

    $Convert->Set_Row( [ $q->popup_menu( -name => 'Convert_Field', -values => $convert_options ) ], -default => $default );
    $Convert->Set_Row( [ Show_Tool_Tip( $q->textarea( -name => 'Convert_String', -rows => 40, -cols => 40 ), "Paste list of identifiers here for conversion to LIMS IDs:\n\nEach Identifier should be on a distinct line" ) ] );

    $Convert->Set_Row( [ '<hr>' . submit( -name => 'rm', -value => 'Convert Records', -class => 'Std', -force => 1 ) ] );

    $convert_table .= $Convert->Printout(0);
    $convert_table .= hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 ) . "\n" . end_form() . "\n";

    return $convert_table;
}

######################
sub export_layer {
######################
    my $dbc             = shift;
    my $cgi_application = 'alDente::Rack_App';

    my $form = alDente::Form::start_alDente_form( $dbc, 'manifest' ) . hidden( -name => 'cgi_application', -value => 'alDente::Rack_App', -force => 1 );

    my ($today) = split ' ', date_time;

    $form .= &SDB::HTML::query_form( -dbc => $dbc, -fields => [ 'Plate.Plate_Created', 'Rack.FK_Equipment__ID', 'Plate.FK_Rack__ID' ], -title => 'Retrieve Container List for Shipping', -action => 'search', -default => $today );

    $form .= '<P>Or scan Boxes to ship: ' . textfield( -name => 'Box_List', -size => 20 );
    $form .= '<HR>';
    $form .= 'Addressee: ' . Show_Tool_Tip( textfield( -name => 'Target_Destination', -size => 20 ), 'Optional receiver name/title' ) . ' at : ' . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Site__ID', -default => '', -force => 1 ) . '<P>';

    $form .= set_validator( -name => 'FK_Site__ID', -mandatory => 1, -prompt => 'You must indicate the target site' );
    $form .= submit( -name => 'rm', -value => 'Generate Shipping Manifest', -class => 'ACTION', -force => 1, -onClick => 'return validateForm(this.form)' );
    $form .= '<P>' . checkbox( -name => 'Include Sample List', -checked => 0, -force => 1 );

    $form .= "\n" . end_form() . "\n";

    return $form;
}

###############
sub home_page {
###############
    my $self = shift;
    my %args       = filter_input( \@_ );
    my $Department = $args{-Department} || ref $self;

    $Department =~s/::Department_Views$//;
    
    return "<h2>$Department home page not set up</h2>";

}

##################################
# display the protocol or chemistry block
##################################
sub display_protocol_chemistry {
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $type       = $args{-type};
    my $html_table = $args{-html_table};
    my $department = $args{-department};

    my $model_module, my $app_module, my $new_link, my $method_name, my $display_name;
    if ( $type eq 'Lab_Protocol' ) {
        $model_module = 'alDente::Protocol';
        $new_link     = &Link_To( $dbc->config('homelink'), "Create", "&Admin=1&cgi_application=alDente::Protocol_App&rm=Create+New+Protocol", $Settings{LINK_COLOUR} );
        $method_name  = "get_protocols";
        $display_name = 'Protocol';
    }
    elsif ( $type eq 'Standard_Solution' ) {
        $model_module = 'alDente::Chemistry';
        $new_link     = &Link_To( $dbc->config('homelink'), "Create", "&New+Entry=New+Standard_Solution", $Settings{LINK_COLOUR} );
        $method_name  = "get_standard_chemistries";
        $display_name = 'Chemistry';
    }
    else {
        $dbc->message("ERROR: Invalid type $type");
        return;
    }
    $app_module = $model_module . '_App';
    my $obj = $model_module->new( -dbc => $dbc );

    my $search_link = &Link_To( $dbc->config('homelink'), "Search", "&Search+for=1&Table=$type", $Settings{LINK_COLOUR} );

    # Active Production protocols/chemistries
    $html_table->Set_Row( [ "Active Production $display_name", $search_link ] );
    my $prod = $obj->$method_name( -dbc => $dbc, -department => $department, -grp_type => 'Lab,Production', -grp_access => 'Admin', -status => 'Active' );
    if ( int(@$prod) ) {
        my ( $choices, $labels ) = $obj->convert_to_labeled_list( -names => $prod );
        my $row = [
            '',
            '',
            alDente::Form::start_alDente_form( -dbc => $dbc, -name => "AdminOpts_Production_$type" )
                . RGTools::Web_Form::Popup_Menu( name => "$type Choice", values => $choices, labels => $labels, default => '-', force => 1 )
                . set_validator( -name => "$type Choice", -mandatory => 1, -force => 1 )
                . space(10)
                . submit( -name => 'rm', -value => "View $display_name", -class => 'std', -onClick => "return validateForm(this.form);" )
                . hidden( -name => 'cgi_application', -value => $app_module, -force => 1 )
                . end_form(),
        ];
        $html_table->Set_Row($row);
    }

    # TechD protocols/chemistries
    $html_table->Set_Row( [ "TechD $display_name", "$search_link / $new_link" ] );
    my $techd_rows = alDente::Admin::display_protocol_chemistry_dropdown( -dbc => $dbc, -type => $type, -scope => 'TechD' );
    if ( int(@$techd_rows) ) {
        foreach my $row (@$techd_rows) {
            $html_table->Set_Row($row);
        }
    }
}
1;
