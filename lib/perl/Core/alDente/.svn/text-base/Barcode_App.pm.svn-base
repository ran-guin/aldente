##################
# Barcode_App.pm #
##################
#
# This module is used to monitor Barcodes for Library and Project objects.
#
package alDente::Barcode_App;

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
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

#use CGI qw(:standard);
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Barcode;
use alDente::Barcode_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs $URL_temp_dir $html_header);    # $current_plates $testing $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('show_Progress');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Set Printer Group'            => 'set_Printer_Group',
        'Change Printer Group'         => 'set_Printer_Group',
        'Reset Printer Group'          => 'reset_Printer_Group',
        'Print Custom Barcodes'        => 'print_custom_Barcodes',
        'Preview Customized Barcode'   => 'print_custom_Barcodes',
        'Print Customized Barcode'     => 'print_custom_Barcodes',
        'Print Label'                  => 'print_custom_Barcodes',
        'Regenerate Custom Label Form' => 'home_page',
        'Upload Excel'                 => 'upload_excel',
        'Update Excel Customization'   => 'update_excel_customization',
        'Print Barcode'                => 'print_Barcode',
    );

    my $dbc = $self->param('dbc');
    my $Barcode = new alDente::Barcode( -dbc => $dbc );

    $self->param( 'Barcode_Model' => $Barcode, );

    return $self;
}

################
sub home_page {
################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $type    = $q->param('Barcode_Type');
    my $l_count = $q->param('Lcount');
    my $r_count = $q->param('Rcount');
    my $rows    = $q->param('Label_Count');

    if ($type) {
        return alDente::Barcoding::print_custom_barcodes( -dbc => $dbc, -type => $type, -l_count => $l_count, -r_count => $r_count, -rows => $rows );
    }

    return alDente::Barcoding::Barcode_Home( -dbc => $dbc );
}

################
sub upload_excel {
################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $type = $q->param('Barcode_Type');
    my $fh   = $q->param('input_file_name');

    my $parser;

    my $outfile_name;
    if ( $fh =~ /\.xls$/ ) {
        eval { require Spreadsheet::ParseExcel; };
	    if ($@) {
	        $dbc->error( "Missing required modules: $@");
	        return ;
	    }
        $outfile_name = timestamp() . ".temp.xls";
        $parser       = Spreadsheet::ParseExcel->new;
    }
    elsif ( $fh =~ /\.xlsx$/ ) {
        eval { require Spreadsheet::ParseXLSX; };
	    if ($@) {
	        $dbc->error( "Missing required modules: $@");
	        return ;
	    }
        $outfile_name = timestamp() . ".temp.xlsx";
        $parser       = Spreadsheet::ParseXLSX->new;
    }
    else {
        $dbc->error('Incorrect file format');
        return;
    }

    $dbc->message("Loading excel data");

    my $buffer = '';
    my $file   = "$Configs{URL_temp_dir}/$outfile_name";
    my $outfile;
    open( $outfile, ">$file" );
    binmode($outfile);    # change to binary mode
    while ( read( $fh, $buffer, 1024 ) ) {
        print $outfile $buffer;
    }
    close($outfile);

    # close original filestream
    close($fh);


    # open the Excel file
    my $oBook           = $parser->parse("$file");
    my @worksheet_array = @{ $oBook->{Worksheet} };
    my $sheet           = $worksheet_array[0];
    my $config          = $worksheet_array[1] if ( int(@worksheet_array) > 1 );

    # get barcode config info
    my $type           = $config->{Cells}[2][1]->Value if $config;
    my $frozen_barcode = $config->{Cells}[1][1]->Value if $config;

    # grab the barcode texts
    my %col_header;
    for ( my $col = 0; $col <= $sheet->{MaxCol}; $col++ ) {
        if ( !$sheet->{Cells}[0][$col] ) {next}
        my $cell_value = $sheet->{Cells}[0][$col]->Value;
        $col_header{$col} = $cell_value;
    }

    my %data;
    my $rows = $sheet->{MaxRow};
    for my $col ( keys %col_header ) {
        for ( my $row = 1; $row <= $sheet->{MaxRow}; $row++ ) {
            if ( !$sheet->{Cells}[$row][$col] ) {
                push @{ $data{ $col_header{$col} } }, '';
            }
            else {
                push @{ $data{ $col_header{$col} } }, $sheet->{Cells}[$row][$col]->Value;
            }
        }
    }

    return alDente::Barcoding::print_custom_barcodes( -dbc => $dbc, -type => $type, -rows => $rows, -data => \%data, -frozen => $frozen_barcode, -open => 1 );
}

################################
sub update_excel_customization {
################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query();
    my $type          = $q->param('Barcode_Type');
    my $frozen_config = $q->param('Frozen Config');

    #Get frozen config
    my $Class;
    my @labels;
    my $barcode_config = RGTools::RGIO::Safe_Thaw( -encoded => 1, -value => $frozen_config );
    for my $key ( sort keys %{$barcode_config} ) {
        if ( ref $barcode_config->{$key} eq 'HASH' ) {
            push @labels, $key;
        }
    }
    $Class->{$type} = $barcode_config;

    #update config with new params
    my @possible_params = qw(format opts posx posy sample size style);
    for my $label (@labels) {
        for my $param (@possible_params) {
            my $new_value = $q->param("$label.$param");
            if ($new_value) {
                $Class->{$type}{$label}{$param} = $new_value;
            }
        }
    }

    #freeze new config and pass it to print custom barcode page
    my $new_frozen_config = Safe_Freeze( -value => $Class->{$type}, -format => 'array', -encode => 1 );
    return alDente::Barcoding::print_custom_barcodes( -dbc => $dbc, -type => $type, -frozen => $new_frozen_config->[0], -open => 1 );
}

########################
sub set_Printer_Group {
########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $options = alDente::Barcode_Views::show_printer_groups( -dbc => $dbc );

    my $page = $options . '<hr>';
    $page .= $self->View->prompt_to_reset_Printer_Group();

    return $page;
}

###############################
sub reset_Printer_Group {
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $scope = $q->param('Scope');

    if    ( $scope =~ /Employee/ )   { $scope = 'Employee' }
    elsif ( $scope =~ /Department/ ) { $scope = 'Department' }
    else                             { $scope = 'Session' }

    my $printer_group_id = SDB::HTML::get_Table_Param( -dbc => $dbc, -field => 'Printer_Assignment.FK_Printer_Group__ID', -convert_fk=>1);

    my $User = new alDente::Employee( -id => $dbc->get_local('user_id'), -dbc => $dbc );   ## should probably be part of $dbc, but pass in for now to reduce potential legacy problems
    require LampLite::Barcode;
    LampLite::Barcode->reset_Printer_Group( -dbc => $dbc, -id => $printer_group_id, -scope => $scope, -User=>$User);

    return;
}

#
# Wrapper to enable printing multiple barcodes at one time.
#
# Assumption: just supplying label & barcode values for each label.
# (may specify other options for all labels)
#
# Return: printouts
###########################
sub print_custom_Barcodes {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my @strings       = $q->param('text');
    my @barcodes      = $q->param('barcode');
    my $printer       = $q->param('Printer');
    my $type          = $args{-type} || $q->param('Barcode_Class') || $q->param('Label Name') || 'large';    ## allow for various standard types
    my $l_count       = $q->param('Lcount') || 4;
    my $r_count       = defined $q->param('Rcount') ? $q->param('Rcount') : 4;
    my $no_return     = $q->param('No_Return');
    my $frozen_config = $q->param('Frozen Config');

    my @all_barcodes;

    my $repeat       = 1;
    my $preview      = ( $q->param('rm') =~ /Preview/i );
    my $frozen_label = $q->param('All_Labels');
    ## store text & barcode classes for various types ... may get this from database or other place ...

    ## custom ##

    ### uses default values from label if supplied ###
    my $Class;
    my @labels;

    if ( !$frozen_config ) {
        $Class = alDente::Barcode::load_standard_classes( $l_count, $r_count );
        @labels = ('barcode');
        foreach my $key ( sort keys %{ $Class->{large} } ) {
            if ( $key =~ /^(l|r)_text\d$/ ) { push @labels, $key }
        }
    }
    else {
        my $barcode_config = RGTools::RGIO::Safe_Thaw( -encoded => 1, -value => $frozen_config );
        for my $key ( sort keys %{$barcode_config} ) {
            if ( ref $barcode_config->{$key} eq 'HASH' ) {
                push @labels, $key;
            }
        }
        $Class->{$type} = $barcode_config;
    }

    my $height      = $Class->{$type}{height};
    my $width       = $Class->{$type}{width};
    my $zero_x      = $Class->{$type}{zero_x};
    my $zero_y      = $Class->{$type}{zero_y};
    my $top         = $Class->{$type}{top};
    my $dpi         = $Class->{$type}{dpi};
    my $printer_dpi = $Class->{$type}{printer_dpi};

    my $string  = $Class->{$type}{text};       ## name of class for text
    my $barcode = $Class->{$type}{barcode};    ## name of class for barcode

    my @keys   = qw(name value format posx posy size opts sample style);
    my $count  = int(@strings) || int(@barcodes) || $q->param('rows') || 1;
    my $output = alDente::Form::start_alDente_form( $dbc, 'custom_labels_app' );

    Message("Generate $count labels...");
    ## assume labels for: name, barcode, style,

    if ($frozen_label) {
        my $thawed = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'All_Labels' );
        my @barcodes = @$thawed if $thawed;
        my $index;
        for my $barcode (@barcodes) {
            alDente::Barcoding::_print( $barcode, -printer => $printer, -filename => 'custom.' . timestamp() . ".$index" );
        }
    }
    else {
        foreach my $i ( 0 .. $count - 1 ) {
            my $Labels;
            my %hash;

            foreach my $label (@labels) {
                ## for each simple label define the parts of the label ##
                foreach my $key (@keys) {
                    my $value;

                    if ( $key eq 'value' ) {
                        my @values = $q->param($label);
                        $value = $values[$i];
                    }
                    else {
                        ## individual parameters for label parts.. ##
                        $value = $q->param("$label.$key");
                        if ( !$value && $Class->{$type} && $Class->{$type}{$label}{$key} ) { $value = $Class->{$type}{$label}{$key} }
                    }
                    $hash{$label}{"-$key"} = $value;
                }
            }

            foreach my $key ( keys %hash ) {
                push @{$Labels}, $hash{$key};
            }
            my $barcode = alDente::Barcode->new(
                -type   => $type,
                -labels => $Labels,
                -height => $height,
                -width  => $width,
                -zero_x => $zero_x,
                -zero_y => $zero_y,
                -top    => $top,
                -dpi    => $dpi,
                -id     => @barcodes[$i]
            );
            push @all_barcodes, $barcode;

            if ($preview) {
                ## print to screen ##
                $barcode->makepng( '', "/opt/alDente/www/dynamic/tmp/test_barcode.$i.png" );

                $barcode->printpng();

                if ( -e "/opt/alDente/www/dynamic/tmp/test_barcode.$i.png" ) {
                    $output .= "Barcode Sample: <BR>" . "<Img src='/dynamic/tmp/test_barcode.$i.png'>.<BR>";
                }
                else {
                    Message("Sorry - the current installed version of perl does not support png image generation");
                }
                $output .= create_tree( -tree => { "configuration_settings $i" => HTML_Dump($barcode) } );
            }
            else {

                #	Message("Print Barcode");
                $barcode->makepng( '', "/opt/alDente/www/dynamic/tmp/test_barcode.$i.png" );
                for ( my $j = 0; $j < $repeat; $j++ ) {
                    alDente::Barcoding::_print( $barcode, -printer => $printer, -filename => 'custom.' . timestamp() . ".$i" );
                }
            }
        }
        if ($preview) {

            #  print HTML_Dump \@all_barcodes;
            my $label_format = $Class->{$type}{label_format_id} || 1;
            my $printers = alDente::Tools::search_list( -name => "FK_Printer__ID", -element_name => 'Printer', -condition => "FK_Label_Format__ID=$label_format", -force => 1 );
            my $frozen = Safe_Freeze( -name => "All_Labels", -value => \@all_barcodes, -format => 'hidden', -encode => 1 );
            $output
                .= "Printer: "
                . $printers
                . $frozen
                . set_validator( 'Printer', -mandatory => 1 )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Barcode_App', -force => 1 )
                . $q->hidden( -name => 'Label Name', -value => $type, -force => 1 )
                . vspace()
                . $q->submit( -name => 'rm', -value => 'Print Customized Barcode', -class => 'action', -onClick => 'return validateForm(this.form)', -force => 1 )
                . vspace();
        }
    }
    $output .= $q->end_form();

    if ($no_return) {
        return;
    }
    else {
        return $output . alDente::Barcoding::Barcode_Home( -dbc => $dbc );

    }
}
##############################
#
# Generate barcode label
#
# Input:
#   -labels => [\%label1,\%label2...] (where %label1 = {-name=>'L1',-posx=>5,-posy=>5,-size=>20,-value=>'label1'}  (-barcode => 'code128' if barcode type).
#
#
#
#
##############################
sub print_custom_barcode {
##############################
    #
    #  customized barcode maker that allows the user to create barcodes that encode different information than the label
    #
    #    my $barcode_value = $args{-barcode_value};             # the value being encoded by the barcode
    #    my $barcode_type = $args{-barcode_type} || 'code128';  # type of the barcode. Can do code128,code39,datamatrix,micropdf417,and qrcodebar

    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query();

    my $labels     = $args{-labels};
    my $label_name = $args{-label_name} || param('Label Name');    ## indication of standard label type (if supplied, only text required for labels)
    my $height     = $args{-height} || $q->param('height');
    my $width      = $args{-width} || $q->param('width');
    my $top        = $args{-top} || $q->param('top');
    my $zero_x     = $args{-zero_x} || $q->param('zero_x');
    my $zero_y     = $args{-zero_y} || $q->param('zero_y');
    my $dpi        = $args{-dpi} || $q->param('scale_DPI');
    my $image_name = $args{-image_name};

    my $preview = $args{-preview};
    my $frozen  = $args{-frozen};

    my $use_sample = $q->param('Use Sample Labels') || 0;
    my $printer    = $q->param('Printer');
    my $repeat     = $args{-repeat} || param('RepeatX') || 1;

    my @keys = qw(name format posx posy size opts value sample style);
    if ($labels) {
        ##
    }
    elsif ( param('label.size') ) {
        my @sizes       = param('label.size');
        my $label_count = int(@sizes);
        my %hash;
        foreach my $key (@keys) {
            my @values  = param("label.$key");
            my @samples = param("label.sample");
            foreach my $i ( 1 .. $label_count ) {
                my $value = $values[ $i - 1 ];
                $value ||= $samples[ $i - 1 ] if ( $key eq 'value' && $use_sample );    ## use sample (except in the case of barcode parameter)
                if ( $key eq 'name' ) { $value = "label.$i" }
                $hash{$i}{"-$key"} = $value;
            }
        }
        foreach my $key ( keys %hash ) {
            push @{$labels}, $hash{$key};
        }
    }

    my $barcode;
    if ($frozen) {
        $barcode = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'Frozen Barcode' );
    }
    elsif ($labels) {
        $barcode = alDente::Barcode->new(
            -type   => $label_name,
            -labels => $labels,
            -height => $height,
            -width  => $width,
            -zero_x => $zero_x,
            -zero_y => $zero_y,
            -top    => $top,
            -dpi    => $dpi,
        );
    }
    else {
        Message("NO defined labels found");
    }

    my $output = '';

    if ($preview) {
        $barcode->makepng( '', "/opt/alDente/www/dynamic/tmp/$image_name.png" );

        #	$barcode->printpng();
        if ( -e "/opt/alDente/www/dynamic/tmp/test_barcode.png" ) {
            $output .= "Barcode Sample: <BR>" . "<Img src='/dynamic/tmp/$image_name.png'>.<BR>";
        }
        else {
            Message("Sorry - the current installed version of perl does not support png image generation");
        }
        $output .= create_tree( -tree => { "configuration Settings $image_name" => HTML_Dump($barcode) } );
    }
    else {

        #	Message("Print Barcode");
        $barcode->makepng;
        for ( my $i = 0; $i < $repeat; $i++ ) {
            $output .= alDente::Barcoding::_print( $barcode, -printer => $printer );
        }
    }

    return $output;
}

####################
sub print_Barcode {
####################
    my $self = shift;
    my $q    = $self->query();

    my $dbc   = $self->param('dbc');
    my $class = $q->param('Class');
    my $id    = $q->param('ID');

    if ( $class && $id ) { return &alDente::Barcoding::PrintBarcode( $dbc, $class, $id ) }
    else                 {return}
}

return 1;

