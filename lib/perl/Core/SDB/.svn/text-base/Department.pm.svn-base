################################################################################
#
# Department.pm
#
# This module display the home pages for various deparments
#
################################################################################
# $Id: Department.pm,v 1.114 2004/12/08 19:43:48 jsantos Exp $
################################################################################
package SDB::Department;

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

my $q = new LampLite::CGI;

use RGTools::RGIO;   ## include standard tools

### temporary ... phase these out ... ###
use alDente::Form;
use LampLite::Login_Views;
use RGTools::Web_Form;

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
    my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
    my $self = $args{-self};
    my $dbc = $args{-dbc} || $self->dbc();

    return \@icons_list;
}

########################################
#
#  General Homepage if department homepage module does not exist
#
####################
sub home_page {
####################
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();
    
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
###############################
    my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
    my $self = $args{-self};
    my $dbc = $args{-dbc} || $self->dbc();
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
    my %args = filter_input( \@_, -args => 'dbc,search,create,custom_search', -self=>'SDB::Department');
    my $self = $args{-self};
    my $dbc = $args{-dbc} || $self->dbc();

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

    my $search_box  = SDB::Department_Views::search_record_box( -admin  => $admin, -search  => $search_ref,  -dbc => $dbc );
    my $add_box     = SDB::Department_Views::add_record_box( -admin     => $admin, -new     => $create_ref,  -dbc => $dbc );
    my $convert_box = SDB::Department_Views::convert_record_box( -admin => $admin, -convert => $convert_ref, -dbc => $dbc );

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
    my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
    my $self = $args{-self};
    my $dbc = $args{-dbc} || $self->dbc();
    my $table = _init_table( 'Barcode' . hspace(5) . $barcodeimg );

    $table->Set_Row(
        [ RGTools::Web_Form::Submit_Button( form => 'Barcode', name => 'Scan', label => 'Scan' ) . hspace(1) . Show_Tool_Tip( $q->textfield( -name => 'Barcode', -force => 1, -size => 30, -default => "" ), "$Tool_Tips{Scan_Button_Field}" ) ] );

    return alDente::Form::start_alDente_form( $dbc, 'Barcode', $dbc->homelink() ) . $table->Printout(0) . "</form>";
}

#########################
# Search DB box
#########################
sub search_db_box {
#########################
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();

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
my %args = filter_input( \@_, -args => 'search', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();
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
##################
my %args = filter_input( \@_, -args => 'create', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();
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
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();

    my $table = _init_table( hspace(40) . 'Upload from Flat File', );

    ## prompt for delimiter options ##
    my @deltrs = ( 'Tab', 'Comma' );
    my $deltr_btns = radio_group( -name => 'deltr', -values => \@deltrs, -default => 'Tab', -force => 1 );

    $table->Set_Row( [ "Delimited input file:", filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ) ] );
    $table->Set_Row( [ "Delimeter:", $deltr_btns ] );
    $table->Set_Row( [ submit( -name => 'upload_file', -label => 'Upload', -class => 'Std' ) ] );

    return alDente::Form::start_alDente_form( $dbc, 'uploader', $dbc->homelink() ) . $table->Printout(0) . "</form>";
}


##########################
sub _init_table {
##########################
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();

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



#############################
# Get alias value given the department and the field
#
#############################
sub get_department_alias {
#############################
my %args = filter_input( \@_, -args => 'field', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();

    my $field      = $args{-field};                                          ### field to look for alias in the department alias hash
    my $department = $Current_Department;
    my $returnval  = $department_aliases{$department}->{$field} || $field;
    return $returnval;
}

# Return: default icon_class (may override in specific Department.pm module )
######################
sub get_icon_class {
#####################
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();

    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

#################
sub set_links {
#################
my %args = filter_input( \@_, -args => 'dbc', -self=>'SDB::Department');
my $self = $args{-self};
my $dbc = $args{-dbc} || $self->dbc();
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
