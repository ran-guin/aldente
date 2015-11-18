################################################################################
#
# Department.pm
#
# This module display the home pages for various deparments
#
################################################################################
# $Id: Department.pm,v 1.114 2004/12/08 19:43:48 jsantos Exp $
################################################################################
package alDente::Department;

use base SDB::DB_Object;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Department.pm - This module display the home pages for various deparments

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module display the home pages for various deparments<BR>

=cut

##############################
# superclasses               #
##############################

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;
######## Standard Database Modules #######################
use SDB::DB_Form_Viewer;    #### General Form handluse SDB::DBIO;use alDente::Validation;
use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
# use SDB::DBIO;
# use SDB::DB_Record;
use SDB::CustomSettings;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::HTML_Table;
use RGTools::Views;
use RGTools::Web_Form;

#use alDente::Validation;
use alDente::SDB_Defaults;
#use alDente::Form;
#use Sequencing::SDB_Status;
#use alDente::Admin;
#use alDente::Security;
#use alDente::ReArray;
#use alDente::Form;

use alDente::Department_Views;
#use alDente::Solution_Views;
#use alDente::Stock_Views;

##############################
# global_vars                #
##############################
use vars qw($Security $Connection %Login %Std_Parameters %Department_Name %Department_ID %Form_Searches %department_aliases $SDB_submit_image);

my $q = new CGI;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $ssimg;
my $solutionimg;
my $equipimg;
my $plateimg;
my $barcodeimg;
my $last24hoursimg;
my $reportsimg;

## Define the labes for tables (alphabetical order please!)
my %Labels;
%Labels = ( '-' => '--Select--' );
$Labels{Agilent_Assay}     = 'Agilent Assay';
$Labels{Clone_Source}      = 'Clone Source';
$Labels{Plate}             = 'Plate';
$Labels{LibraryPrimer}     = 'Library/Primer';
$Labels{Plate_Format}      = 'Plate Format';
$Labels{Primer_Type}       = 'Primer Type';
$Labels{Original_Source}   = 'Original Source';
$Labels{Source}            = 'Source';
$Labels{Run}               = 'Run Info';
$Labels{Vector_TypePrimer} = 'Vector/Primer Direction';

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
my @icons_list = qw(Views Plates Solutions_App Equipment_App Libraries Sources Pipeline Export Subscription Contacts);

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################
    return \@icons_list;
}

########################################
#
#  General Homepage if department homepage module does not exist
#
####################
sub home_page {
####################
    my $self       = shift;
    my %args       = @_;
    
    my $main_table = HTML_Table->new(
        -title  => "Home Page",
        -width  => '100%',
        -border => 2
    );
    $main_table->Toggle_Colour('off');
    $main_table->Set_Column_Widths( ['50%'] );
    return h1("Home page not defined. This is the default homepage. Please add the alDente/$args{-dept}_Department.pm module");
}

###############################
sub get_searches_and_creates {
##############################

    my %args   = @_;
    my %Access;
    
    if ( $args{-access} ) { %Access = %{ $args{-access} } }

    my @creates = sort qw(Original_Source Employee Project Contact Organization Project Plate_Format Source Location Site);

    my @searches = sort qw(Original_Source Employee Project Contact Organization Project Plate_Format Source Location Site);

    my @converts = sort qw(Source.External_Identifier Original_Source.Original_Source_Name);

    return ( \@searches, \@creates, \@converts );
}

sub get_greys_and_omits {
    
    return ([], []);
}

########################################
#
#  Scan barcode, search, search/edit, and create tables
#
########################
sub search_create_box {
########################
    my %args = filter_input( \@_, -args => 'dbc,search,create,custom_search' );

    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $search_ref    = $args{-search};
    my $create_ref    = $args{-create};
    my $custom_search = $args{-custom_search};
    my $convert_ref   = $args{-convert};

    my $admin = 0;

    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {
        $admin = 1;
    }

    my $top_table = HTML_Table->new( -width => '100%', -align => 'top', -colour => "#ddddda" );

    my $custom;
    if ($custom_search) {
        my @searches = keys %$custom_search;
        foreach my $search (@searches) {
            my $search_link = $custom_search->{$search};
            $custom .= '<LI>' . Link_To( $dbc->config('homelink'), $search, "&cgi_application=SDB::DB_Object_App&rm=Search+Records&$search_link" );
        }
        if ($custom) { $custom = "<H2>Custom Cross-Referencing Searches:</H2><UL>$custom</UL>\n" }
    }

    my $search_box  = alDente::Department_Views::search_record_box( -admin  => $admin, -search  => $search_ref,  -dbc => $dbc );
    my $add_box     = alDente::Department_Views::add_record_box( -admin     => $admin, -new     => $create_ref,  -dbc => $dbc );
    my $convert_box = alDente::Department_Views::convert_record_box( -admin => $admin, -convert => $convert_ref, -dbc => $dbc );

    $top_table->Set_Row( [ $search_box, $add_box, $convert_box, $custom ] );
    $top_table->Set_VAlignment('top');
    $top_table->Toggle_Colour('off');

    return $top_table->Printout(0);
}

#########################
# Barcode box
#########################
sub barcode_box {
#################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = _init_table( 'Barcode' . hspace(5) . $barcodeimg );

    $table->Set_Row(
        [ RGTools::Web_Form::Submit_Button( form => 'Barcode', name => 'Scan', label => 'Scan' ) . hspace(1) . Show_Tool_Tip( $q->textfield( -name => 'Barcode', -force => 1, -size => 30, -default => "" ), "$Tool_Tips{Scan_Button_Field}" ) ] );

    return alDente::Form::start_alDente_form( $dbc, 'Barcode', $dbc->homelink() ) . $table->Printout(0) . "</form>";
}

#########################
# Search DB box
#########################
sub search_db_box {
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = alDente::Form::init_HTML_table('Search the Database');

    $table->Set_Row(
        [         RGTools::Web_Form::Submit_Button( form => 'Search_db', name => 'Search Databases', label => 'Search' )
                . hspace(1)
                . Show_Tool_Tip( $q->textfield( -name => 'DB Search String', -force => 1, -size => 15, -default => "" ), "$Tool_Tips{Search_Button_Field}" )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'Search_db', $dbc->homelink()) . $table->Printout(0) . "</form>";
}

## phased out ?
#########################
# Search/Edit box
#########################
sub search_edit_box {
#########################
    my %args = filter_input( \@_, -args => 'search' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $search_ref = $args{-search};

    my $table = _init_table('Search / Edit');

    $table->Set_Row(
        [         checkbox( -name => 'Multi-Record' )
                . hspace(1)
                . RGTools::Web_Form::Popup_Menu( name => 'Object', values => $search_ref, labels => \%Labels, default => '-', force => 1, width => 200 )
                . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -name => 'Search for' )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'search_edit', $dbc->homelink() ) . $table->Printout(0) . "</form>";
}

## phased out ?
#########################
# Create box
#########################
sub create_box {
    my %args = filter_input( \@_, -args => 'create' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $create_ref = $args{-create};
	my $homelink = $dbc->homelink();
	
    my $table = _init_table('Create New...');

    $table->Set_Row(
        [         RGTools::Web_Form::Popup_Menu( name => 'Create_New', values => $create_ref, labels => \%Labels, default => '-', force => 1, width => 200 )
                . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -onClick => "goTo('$homelink',buildAddOns(document.create_new,'Create_New',getElementsByName('Create_New')[0].value),false);return false;" )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'create_new', $homelink ) . $table->Printout(0) . "</form>";

}

######################
# upload file option
#
#
#########################
sub upload_file_box {
#########################
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = _init_table( hspace(40) . 'Upload from Flat File', );

    ## prompt for delimiter options ##
    my @deltrs = ( 'Tab', 'Comma' );
    my $deltr_btns = radio_group( -name => 'deltr', -values => \@deltrs, -default => 'Tab', -force => 1 );

    $table->Set_Row( [ "Delimited input file:", filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ) ] );
    $table->Set_Row( [ "Delimeter:", $deltr_btns ] );
    $table->Set_Row( [ submit( -name => 'upload_file', -label => 'Upload', -class => 'Std' ) ] );

    return alDente::Form::start_alDente_form( $dbc, 'uploader', $dbc->homelink() ) . $table->Printout(0) . "</form>";
}

#########################
# Seq Request box
#########################
sub seq_request_box {
#######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $choices_ref = $args{-choices};
    my $labels_ref  = $args{-labels};
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my @choices = @{$choices_ref} if $choices_ref;
    my %labels  = %{$labels_ref}  if $labels_ref;

    @choices = sort(@choices);

    my $search_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Runs', '&Search+for=1&Table=Run' ) . &hspace(5) . &Link_To( $dbc->config('homelink'), 'Batch', '&Search+for=1&Table=RunBatch' );

    my $table = alDente::Form::init_HTML_table(-left => 'Sequencing Runs', -right => $search_link, -margin => 'on' );

    $table->Set_Row(
        [   LampLite::Login_Views->icons( 'Sample_Sheets', -dbc => $dbc, -no_link => 1 ),
            'Library Name: ',
            Show_Tool_Tip( textfield( -name => 'Search String', -force => 1, -size => 10, -default => "" ), "Faster if Library Specified (eg. 'TL' or 'RM0034a')" )
                . &hspace(1)
                . Show_Tool_Tip( checkbox( -name => 'All Users' ), "Include sheets generated by all users" ) . ' '
                .

                RGTools::Web_Form::Popup_Menu(
                name    => 'rm',
                values  => [ '--Select--', @choices ],
                labels  => \%labels,
                default => '--Select--',
                force   => 1,
                width   => 200,
                )
                . "&emsp;"
                . hidden( -name => 'cgi_application', -value => 'alDente::Run_App', -force => 1 )

                . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'seq_request', $dbc->homelink()) . $table->Printout(0) . "</form>";
}

#########################
# Solution box
#########################
sub solution_box {
#########################
    my %args    = &filter_input( \@_ );
    my $include = $args{-include};        ## include options (eg batch,search)

    my $batch  = ( $include =~ /batch/i );
    my $search = ( $include =~ /search/i );

    require alDente::Solution_Views;
    require alDente::Stock_Views;
    
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $output = alDente::Solution_Views::display_mix_block( -dbc => $dbc );

    if ($batch) { $output .= alDente::Solution_Views::display_batch_block( -dbc => $dbc ) }
    if ($search) { $output .= alDente::Stock_Views::search_stock_box( -dbc => $dbc, -short => 1 ) }

    return $output;
}

#########################
# Equipment box
#########################
sub equipment_box {
#########################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $choices_ref = $args{-choices};
    my $labels_ref  = $args{-labels};

	my $homelink = $dbc->homelink();
	
    my @choices = @{$choices_ref} if $choices_ref;
    my %labels  = %{$labels_ref}  if $labels_ref;

    @choices = sort(@choices);

    #    my $add_link = &Link_To($dbc->homelink(),'<span class=small>(create)</span>',"&Department=Receiving",$Settings{LINK_COLOUR});
    my $add_link = &Link_To( $dbc->config('homelink'), "<span class=small >(create)</span>", "&Target_Department=Receiving");

    my $search_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Equipment', '&Search+for=1&Table=Equipment' ) . &hspace(5) . &Link_To( $dbc->config('homelink'), 'Maintenance', '&Search+for=1&Table=Maintenance' );

    my $table = alDente::Form::init_HTML_table(-left => 'Equipment', -right => $search_link, -margin => 'on' );

    $table->Set_Row(
        [   $equipimg,
            'Enter Equipment ID: '
                . &Show_Tool_Tip( textfield( -name => 'Equipment_List', -force => 1, -size => 15, -default => "" ), 'Scan equipment for Maintenance or Maintenance History (optional)' )
                . '&nbsp to view: '
                . RGTools::Web_Form::Popup_Menu( name => 'Equipment', values => \@choices, labels => \%labels, default => '-', force => 1, width => 200 )
                . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -onClick => "goTo('$homelink',buildAddOns(document.equipment,'Equipment',getElementsByName('Equipment')[0].value),false); return false;" )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'equipment', $homelink) . $table->Printout(0) . "</form>";
}

#########################
# SpectRun Run Request Box
#########################
sub spect_run_box {
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = alDente::Form::init_HTML_table( 'Spect Run Request', -margin => 'on' );
    $table->Set_Row(
        [   '',
            'Create Spect Run for plate: '
                . &Show_Tool_Tip( textfield( -name => 'FK_Plate__ID', -width => 20, -force => 1 ), 'Scan plate' )
                . '&nbsp;using Instrument:&nbsp;'
                . &Show_Tool_Tip( textfield( -name => 'FKScanner_Equipment__ID', -width => 20, -force => 1 ), 'Scan spectrophotometer' )
                . '&nbsp;'
                . submit( -name => 'Request_Spect_Runs', -value => 'Create', -class => 'Std' )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'spect_run_form', $dbc->homelink() ) . hidden( -name => 'Lib_Construction_SpectRun' ) . $table->Printout(0) . "</form>";
}

#################################
# BioanalyzerRun Run Request Box
#################################
sub bioanalyzer_run_box {
#################################

    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = alDente::Form::init_HTML_table( 'Bioanalyzer Run Request', -margin => 'on' );
    $table->Set_Row(
        [   '',
            'Create Bioanalyzer Run for tubes: '
                . &Show_Tool_Tip( textfield( -name => 'FK_Plate__ID', -width => 20, -force => 1 ), 'Scan sample tubes' )
                . '&nbsp;using Instrument:&nbsp;'
                . &Show_Tool_Tip( textfield( -name => 'FKScanner_Equipment__ID', -width => 20, -force => 1 ), 'Scan Agilent Bioanalyzer' )
                . '&nbsp;'
                . submit( -name => 'Request_Bioanalyzer_Runs', -value => 'Create', -class => 'Std' )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'bioanalyzer_run_form', $dbc->homelink() ) . hidden( -name => 'Lib_Construction_BioanalyzerRun' ) . $table->Printout(0) . "</form>";
}

##########################
sub _init_table {
##########################
    my $title = shift;
    my $right = shift;
    my $class = shift || 'small';

    #    my $table = HTML_Table->new();

    #    $table->Set_Class('small');
    #    $table->Set_Width('100%');
    #    $table->Toggle_Colour('off');
    #    $table->Set_Line_Colour('#ddddda');

    $title = "\n<Table border=0 cellspacing=0 cellpadding=0 width='100%'>\n\t<TR>\n\t\t<TD><font size='-1'><b>$title</b></font></TD>\n\t\t<TD align=right class=$class><B>$right</B></TD>\n\t</TR>\n</Table>\n";
    my $table = alDente::Form::init_HTML_table($title);

    $table->Set_Title( $title, bgcolour => '#9999cc', fclass => 'small', fstyle => 'bold' );

    return $table;
}

#################
sub plates_box {
#################
    my %args = filter_input( \@_ );
    require alDente::Container_Views;
    return alDente::Container_Views::plates_box(%args);
}

########################
sub delete_plates_box {
########################
    my %args   = &filter_input( \@_ );
    my $width  = $args{-width} || '100%';
    my $colour = $args{-colour} || '#ddddda';
    my $title  = $args{-title} || '';
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = HTML_Table->new();

    $table->Set_Class('small');
    $table->Set_Width($width);
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour($colour);

    $table->Set_Title( $title, bgcolour => '#9999cc', fclass => 'small', fstyle => 'bold' );

    $table->Set_Row(
        [         RGTools::Web_Form::Submit_Button( form => 'plates', name => "Check Recent Plates", label => "Delete/Annotate" )
                . " &emsp; "
                . Show_Tool_Tip( $q->textfield( -name => 'Plates_List', -force => 1, -size => 15, -default => "" ), 'Scan plates or plate range (eg. 454-480)' )
                . " &emsp; Made within "
                . $q->textfield( -name => 'Plates Made Within', -force => 1, -size => 3, -default => "7" ) . 'days'
                . &hspace(1)
                . Show_Tool_Tip( checkbox( -name => 'All users' ), "Include plates made by all users" )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'plates', $dbc->homelink() ) . $table->Printout(0) . end_form();
}


#####################
# Latest Runs box
#
# This should be adapted to retrieve ALL run types.
#
# (Cap Seq run retrieval should be handled from the specific Cap_Seq plugin)
#
# Return: search form to retrieve latest runs 
######################
sub latest_runs_box {
######################
# Phase out or modify to be non-specific ...##
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    $dbc->Benchmark('log_deprecation');
 #   set_links($dbc);  # moved to latest_Cap_Seq_runs_box
    $dbc->Benchmark('set_links');

    my $views = alDente::Form::init_HTML_table( 'Run Data', -margin => 'on' );
    $dbc->Benchmark('lr_init_table');
    my $library_label = get_department_alias( -field => 'Library' );
    $library_label = "Library Name";

    #  $views->Set_Width('100%');
    $views->Set_Row( [ '', "$library_label: ", alDente::Tools::search_list( -dbc => $dbc, -name => 'Plate.FK_Library__Name', -search => 1, -filter => 1, -filter_by_dept => 1 ) . lbr ] );
#    $views->Set_Row( [ "Specify Library: ", alDente::Tools::search_list( -dbc => $dbc, -name => 'Library.Library_Name', -search => 1, -filter_by_dept => 1, -filter => 1, -breaks => 1 ) ] );
    $dbc->Benchmark('lr_gen_liblist');

    $views->Set_Row(
        [ $last24hoursimg, "Plate Number(s): ", Show_Tool_Tip( textfield( -name => 'Run Plate Number', -size => 15 ), "eg. 2a or 11-15" ) . hidden( -name => 'Include Runs', -value => 'Production|Test' ) . hidden( -name => 'Any Date', -value => 1 ) ] );
    $views->Set_Row( [ '', "Run ID(s): ", Show_Tool_Tip( textfield( -name => 'Run_ID' ), "eg. 8990-8993" ) ] );
    $views->Set_Row( [ '', '', '<HR>' . submit( -name => 'Last 24 Hours', -value => 'Search for Runs', -label => 'Get Run Summary', -class => 'Search' ) ] );

    $views->Set_Alignment( 'right', 2 );
    $views->Set_VAlignment( 'center', 2 );

    $dbc->Benchmark('runs_init_form1');
    $dbc->Benchmark('runs_init_form2');
    return alDente::Form::start_alDente_form( $dbc, 'latest_runs_box', $dbc->homelink() ) . $views->Printout(0) . "</form>";
}

########################################
# Prep summary box
########################################
sub prep_summary_box {
####################
    ###Prep Summary###
    my %args = &filter_input( \@_ );
    my $department = $args{-department} || $Current_Department;
    
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $reports = alDente::Form::init_HTML_table( 'Preparation Summaries', -margin => 'on' );

    my $libraries = $args{-libraries};    ## optional list of libraries (faster if supplied..)

    #    my @libraries = get_FK_info($dbc,'FK_Library__Name',-list=>1);
    my $library_label = get_department_alias( -field => 'Library' );

    $reports->Set_Row( [ '', "$library_label: ", &alDente::Tools::search_list( -dbc => $dbc, -name => 'Plate.FK_Library__Name', -options => $libraries, -cache => "Dept.$department", -search => 1, -filter => 1) ] );

    $reports->Set_Row( [ '', "include Plate Number(s): ", Show_Tool_Tip( textfield( -name => 'Plate Number', -size => 10 ), "eg: '1,4-6' for 1,4,5,6" ) ] );
    $reports->Set_Row( [ '', "show plates prepped in last ", textfield( -name => 'Days_Ago', -size => 5, -default => 5 ) . " Days." ] );

    #    $reports->Set_Row([alDente::Tools->search_list(-dbc=>$dbc,-form=>'Reports',-name=>'FK_Project__ID',-default=>'',-search=>1,-filter=>1)]);
    $reports->Set_Row( [ '', "Groups: ",   alDente::Tools->search_list( -dbc => $dbc, -name => 'Library.FK_Grp__ID',    -default => '', -filter_by_dept => 1, -search => 1, -filter => 1, -mode => 'scroll' ) ] );
    $reports->Set_Row( [ '', "Pipeline: ", alDente::Tools->search_list( -dbc => $dbc, -name => 'Plate.FK_Pipeline__ID', -default => '', -filter_by_dept => 1, -search => 1, -filter => 1, -mode => 'scroll' ) ] );
    $reports->Set_Row(
        [   '',
            '',
            '<HR>'
                . Show_Tool_Tip( submit( -name => 'rm', -value => 'Prep Summary', -class => 'Search' ), 'If no library/plates are provided, then plates created/prepared in the last 5 days will be returned.' )
                . hidden( -name => 'Inclusive', -value => 1 )
                . hidden( -name => 'Details',   -value => 1 )
                . hspace(15)
                . Show_Tool_Tip( submit( -name => 'rm', -value => 'Protocol Summary', -class => 'Search' ), 'If no library/plates are provided, then plates created/prepared in the last 5 days will be returned.' )
                . hidden( -name => 'Inclusive', -value => 1 )
                . hidden( -name => 'Details',   -value => 1 )
        ]
    );

    $reports->Set_Alignment( 'right', 2 );
    $reports->Set_VAlignment( 'center', 2 );

    my $form = alDente::Form::start_alDente_form( $dbc, 'Reports') 
        . $reports->Printout(0)
        . $q->hidden(-name=>'cgi_application', -value=>'alDente::Prep_App', -force=>1)
        . "</form>";
        
    return $form;
}

#
#
#
#######################
sub view_summary_box {
#######################
    my $views = alDente::Form::init_HTML_table('Summary Views');
    my %args  = &filter_input( \@_ );
    my $scope = $args{-scope};
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $application = 'alDente::View_App';
    eval "require $application";

    # construct object from default

    my $webapp = $application->new(
        PARAMS => {
            dbc         => $dbc,
            Scope       => $scope,
            'Open View' => 0
        }
    );
    my $form .= $webapp->search_page();
    return $form;

=begin

   require alDente::View;
   my $view = alDente::View->new(-scope=>$scope);
  my $view_list = $view->display_available_views();
   	#$output .= $views->Printout(0);
   return alDente::Form::start_alDente_form($dbc,'Views',$dbc->homelink()) .
	$view_list .end_form();
    ## Get list of cached views

    ## List views that have been cached previously

 return $output;
=cut

}

########################################
#Catalog Number Section
########################################
sub catalog_box {
####################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $cat_num = _init_table('Receive New Stock');
    my @choices = ( 'By_Cat_Num', 'By_Name' );
    my %labels  = (
        'By_Cat_Num' => 'By Catalog Number',
        'By_Name'    => 'By Name'
    );
    $cat_num->Set_Row(
        [         RGTools::Web_Form::Submit_Button( form => 'Catalog_box', name => 'Incoming', label => 'New Stock', validate => 'Stock_Search_String', validate_msg => 'Please enter a stock catalog number or stock name first.' )
                . hspace(1)
                . radio_group( -name => 'Stock_Search_By', -value => \@choices, -labels => \%labels, -default => 'By_Cat_Num' )
                . hspace(1)
                . Show_Tool_Tip( $q->textfield( -name => 'Stock_Search_String', -size => 15, -default => '' ), "$Tool_Tips{Catalog_Number_Field}" )
        ]
    );

    return alDente::Form::start_alDente_form( $dbc, 'Catalog_box', $dbc->homelink() ) . $cat_num->Printout(0) . "</form>";
}

##################################################################
# Notification Section
##################################################################
sub notify_box {
##################################################################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $notification = _init_table('Stock Supply Notification');

	my $homelink = $dbc->homelink();
	
    my @choices = ('-');
    my %labels = ( '-' => '--Select--' );

    #  push(@choices,'Order_Notice');
    #
    #  $labels{Order_Notice} = 'View/Edit Notification Settings';
    #  $notification->Set_Row([RGTools::Web_Form::Popup_Menu(name=>'Edit_Notification_Settings',values=>\@choices,labels=>\%labels,default=>'-',force=>1) .
    #,onClick=>"goTo('$homelink',buildAddOns(document.Notification,'Edit_Stock_Notification_Settings',this.value),getValue(document.Notification,'NewWin'))",width=>200)
    #			  RGTools::Web_Form::Submit_Image(-src=>$SDB_submit_image,-onClick=>"goTo('$homelink',buildAddOns(document.Notification,'Edit_Notification_Settings',getElementsByName('Edit_Notificaion_Settings')[0].value),false);return false;")]);

    my $output = &Link_To( $homelink, "Edit Notification Settings", "&Edit+Table=Order_Notice" );

    $output .= $dbc->Table_retrieve_display(
        'Order_Notice,Stock,Stock_Catalog',
        [ 'Order_Notice_ID', 'Order_Notice.FK_Grp__ID', 'Order_Text as Message', 'Catalog_Number', 'Target_List', 'Minimum_Units', 'Maximum_Units as Max', 'Notice_Sent as Last_Notice', 'Max(Stock_Received) as Last_Received', 'Notice_Frequency' ],
        "WHERE FK_Stock_Catalog__ID =Stock_Catalog_ID AND Order_Notice.Catalog_Number = Stock_Catalog_Number AND Notice_Frequency > 0 GROUP BY Catalog_Number ORDER BY Notice_Sent DESC",
        -print       => 0,
        -return_html => 1,
        -width       => '100%',
        -title       => "Current Active Notifications"
    );
    return $output;

    return alDente::Form::start_alDente_form( $dbc, 'Notification', $homelink) . $notification->Printout(0) . "</form>";

}

##################################################################
# Search for Stock Section
##################################################################
sub search_stock_box {
#########################
    my %args     = &filter_input( \@_, -args => 'embedded' );
    my $embedded = $args{-embedded};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $stock_search = alDente::Form::init_HTML_table('Search for Stock');
    if ($embedded) {
        $stock_search->Set_Title('');
        $stock_search->Set_Row( [ '', "<B>Searching for Reagents/Solutions</B>" ] );
    }
    my @groups = @{ $dbc->get_local('groups') };
    @groups = ( '--All--', @groups );

    my @choices = ('-');                    #drop-down menu choices
    my %labels = ( '-' => '--Select--' );
### <CONSTRUCTOR> Add Find Stock, Find Equipment,...
    push @choices, ( 'Find Solution', 'Find Box' );
    push @choices, 'Soon to Expire';
    push @choices, 'Check Recently Created Solutions';
    push @choices, 'Check Recently Received Reagents';

    $stock_search->Set_Row(
        [   'Search String: ',
            $q->textfield( -name => 'Search String', -force => 1, -size => 15, -default => "", -title => 'Use * for wildcard' )
                . hspace(1)
                . '(within: '
                . $q->textfield( -name => 'MadeWithin', -force => 1, -size => 5, -default => '30' ) . 'days)'
                . checkbox( -name => 'All users', -force => 1 )
        ]
    );
    $stock_search->Set_Row( [ 'Group: ', Show_Tool_Tip( RGTools::Web_Form::Popup_Menu( name => 'Group', values => \@groups, default => 'All' ), "Limit search to items accessible to chosen group" ) ] );
    $stock_search->Set_Row(
        [   'Find: ',
            hspace(1)
                . RGTools::Web_Form::Popup_Menu( name => 'Solution_Search', values => \@choices, labels => \%labels, default => '-', force => 1, width => 200 )
                . RGTools::Web_Form::Submit_Image( -src => $SDB_submit_image, -onClick => "form.stock_search.submit(); return false;" )
        ]
    );

    $stock_search->Set_Alignment( 'right', 1 );
    $stock_search->Set_VAlignment( 'center', 1 );

    my $output;
    if ( !$embedded ) { $output .= alDente::Form::start_alDente_form( $dbc, 'stock_search' ) }
    $output .= $stock_search->Printout(0);
    if ( !$embedded ) { $output .= "</FORM>" }

    return $output;
}
#############################
sub inventory_search_box {
#############################
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $search_link = 'Search for: ' . &Link_To( $dbc->config('homelink'), 'Bottles', '&Search+for=1&Table=Solution' ) . &hspace(5) . &Link_To( $dbc->config('homelink'), 'Stock', '&Search+for=1&Table=Stock' );

    my $inventory_search = alDente::Form::init_HTML_table(
        -left   => 'Inventory Search',
        -right  => $search_link,
        -margin => 'on'
    );
    $inventory_search->Set_Row(
        [   $solutionimg,
            Show_Tool_Tip( textfield( -name => 'String' ), "Use wildcard as required eg *alchol*" )
                . hidden( -name => 'cgi_application', -value => 'alDente::Stock_App', -force => 1 )
                . popup_menu( -name => 'rm', -value => [ '--Select--', 'Search for Catalog Number', 'Search for Stock Name' ] )
                . submit( -name => 'Go', -class => 'Std' )
        ]
    );

    my $output .= alDente::Form::start_alDente_form( $dbc, 'inventory_search' );
    $output    .= $inventory_search->Printout(0);
    $output    .= end_form();

    return $output;
}

#############################
# Get alias value given the department and the field
#
#############################
sub get_department_alias {
#############################
    my %args       = &filter_input( \@_, -args => 'field' );
    my $field      = $args{-field};                                          ### field to look for alias in the department alias hash
    my $department = $Current_Department;
    my $returnval  = $department_aliases{$department}->{$field} || $field;
    return $returnval;
}

# Return: default icon_class (may override in specific Department.pm module )
######################
sub get_icon_class {
#####################
    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

#################
sub set_links {
#################
    my $self = shift;
    return;
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Department.pm,v 1.114 2004/12/08 19:43:48 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
