###################################################################################################################################
# alDente::Barcode_Views.pm
#
# Interface generating methods for the Barcode MVC  (associated with Barcode.pm, Barcode_App.pm)
#
###################################################################################################################################
package alDente::Barcode_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);
use Time::localtime;

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use alDente::SDB_Defaults;

use vars qw( %Configs );

use LampLite::CGI;

my $q = new LampLite::CGI;

#
# Generates table showing printer group settings with locations
#
# Also generates print link if required so that the login page can provide a link for users to view the generated html page.
#
##############################
sub show_printer_groups {
##############################
    my %args       = filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc};
    my $print_link = $args{-print_link};
    my $timestamp  = $args{-timestamp};

    my $printer_groups = $dbc->Table_retrieve_display(
        'Printer_Group,Printer,Printer_Assignment,Label_Format LEFT JOIN Equipment ON Equipment_ID=Printer.FK_Equipment__ID LEFT JOIN Location ON Equipment.FK_Location__ID=Location_ID',
        [ 'Printer_Group_Name', 'Label_Format_Name', 'Printer_Name', 'FK_Equipment__ID as Equip', 'Location_Name as Location', 'Location.FK_Site__ID as Site', "CASE WHEN Printer_Output = 'OFF' THEN 'OFF' ELSE 'ON' END AS Printer_Status" ],
        "WHERE Printer_Group_Status = 'Active' AND Printer_Assignment.FK_Label_Format__ID=Label_Format_ID AND  FK_Printer__ID=Printer_ID AND FK_Printer_Group__ID=Printer_Group_ID",
        -order_by         => 'Printer_Group_Name,Label_Format_Name',
        -title            => 'Active Printer Groups',
        -return_html      => 1,
        -toggle_on_column => 'Printer_Group_Name',
        -print_link       => $print_link,
        -timestamp        => $timestamp,
        -layer => 'Printer_Group_Name',
    );

    return $printer_groups;
}

#############################################################################
#
# generate print button for existing barcode.
#
# This freezes the current barcode object and pass as 'Frozen Barcode' parameter
#
#
######################
sub _print_button {
######################
    my %args    = filter_input( \@_, -args => 'dbc' );
    my $barcode = shift;
    my $dbc     = $args{-dbc};

    my $output .= alDente::Form::start_alDente_form( $dbc, '' );

    my @printers = $dbc->get_FK_info( 'FK_Printer__ID', -list => 1, -condition => "" );    #'Printer_Name',"WHERE Printer_Type = '$label_format'",-distinct=>1);

    $output .= "Printer"
        . RGTools::Web_Form::Popup_Menu(
        name    => 'Printer',
        values  => [ "", @printers ],
        force   => 1,
        width   => 200,
        default => ''
        ) . set_validator( 'Printer', -mandatory => 1 );

    $output .= "<P>";
    $output .= submit( -name => 'Barcode_Event', -value => 'Print Customized Barcode', -class => 'Action', -onClick => 'return validateForm(this.form)' );

    my $frozen = Safe_Freeze( -name => "Frozen Barcode", -value => $barcode, -format => 'hidden', -encode => 1 );
    $output .= $frozen;
    $output .= end_form();

    return $output;
}

####################################
sub prompt_to_reset_Printer_Group {
####################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $page = alDente::Form::start_alDente_form( $dbc, 'reset_printers' );

    $page .= $q->hidden( -name => 'cgi_application', value => 'alDente::Barcode_App', -force => 1 );
    $page .= $q->submit( -name => 'rm', value => 'Reset Printer Group', -class => 'Action', -onClick => 'return validateForm(this.form)', -force => 1 );
    $page .= ' to: ';
    $page .= alDente::Tools::search_list( -dbc => $dbc, -field => 'Printer_Assignment.FK_Printer_Group__ID' );
    $page .= '<BR>';

    my $default = 'Save for this Session';
    $page .= '<BR>' . $q->radio_group( -name => 'Scope', -value => 'Save for this Session Only',    -default => $default, -force => 1 );
    $page .= '<BR>' . $q->radio_group( -name => 'Scope', -value => 'Save as Employee Default', -default => $default, -force => 1 );

    if ( $dbc->admin_access( ) ) {
        my $dept = $dbc->config('Target_Department');
        $page .= '<BR>' . $q->radio_group( -name => 'Scope', -value => "Save as $dept Department Default", -default => $default, -force => 1 );
    }

    $page .= set_validator( -name => 'FK_Printer_Group__ID', -mandatory => 1, -prompt => 'Please select Printer Group for this session' );
    $page .= $q->end_form();

    return $page;
}

###########################
sub reset_Printer_button {
###########################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $warning = $args{-warning};
    my $change  = $args{-prompt} || 'Set';

    if ( param('rm') eq 'Set Printer Group' )    {return}    ## set printer group action already submitted ....
    if ( param('rm') eq 'Reset Printer Group' )  {return}    ## set printer group action already submitted ....
    if ( param('rm') eq 'Change Printer Group' ) {return}    ## set printer group action already submitted ....

    ## show warning if no printer groups defined at this stage ##
    if ($warning) { $dbc->warning($warning) }

    my $button = alDente::Form::start_alDente_form( $dbc, 'reset_Printers' );
    $button .= hidden( -name => 'cgi_application', -value => 'alDente::Barcode_App', -force => 1 );
    $button .= submit( -name => 'rm', -value => "$change Printer Group", -class => 'Action', -force => 1 );
    $button .= end_form();

    return $button;
}

sub excel_download_upload {
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $type         = $args{-type};
    my $fields       = $args{-fields};
    my $xls_settings = $args{-xls_settings};
    my $excel_link   = $args{-excel_link};

    my $page;
    $page .= SDB::HTML->display_hash(
        -dbc               => $dbc,
        -hash              => $fields,
        -title             => $type,
        -return_html       => 1,
        -excel_name        => $type,
        -return_excel_link => 1,
        -xls_settings      => $xls_settings,
    );

    if ($excel_link) {
        return $page;
    }

    $page .= vspace();
    $page .= submit( -name => 'rm', -value => 'Update Excel Customization', -force => 1, -class => 'Std' );

    require SDB::Import_Views;
    my $Import_View = new SDB::Import_Views( -dbc => $dbc );

    $page .= $Import_View->upload_file_box(
        -dbc             => $dbc,
        -cgi_application => 'alDente::Barcode_App',
        -button          => submit( -name => 'rm', -value => 'Upload Excel', -force => 1, -class => 'Std', -onclick => "return validateForm(this.form,0,'','input_file_name')" ),
        -type            => "Simple",
    );

    return $page;
}

1;
