##################################################################################################################################
# alDente::Process_Deviation_Views.pm
#
# View module that handles Process Deviation related interface
#
###################################################################################################################################

package alDente::Process_Deviation_Views;
use base alDente::Object_Views;

use CGI qw( :standard );
use strict;

## Standard modules ##

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::Web_Form;
use RGTools::RGmath;

use alDente::SDB_Defaults;
use alDente::Tools;

use alDente::Process_Deviation;

## globals ##
use vars qw( %Configs );

my $q = new CGI;

############################################
#
# Home page for Process Deviation
#
# Usage:	my $page = home_page( -dbc => $dbc );
# Return:	HTML page
############################################
#################
sub home_page {
#################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'dbc' );
    my $dbc          = $args{-dbc} || $self->dbc;
    my $ids          = $args{-ids} || $args{-id};
    my $deviation_No = $args{-deviation_Nos};                 # list of deviation Nos

    my $page;
    my $condition = "Where 1 ";
    if ($ids) {
        my $list = Cast_List( -list => $ids, -to => 'string', -autoquote => 0 );
        $condition .= " and Process_Deviation_ID in ( $list ) ";
    }
    elsif ($deviation_No) {
        my $list = Cast_List( -list => $deviation_No, -to => 'string', -autoquote => 1 );
        $condition .= " and Deviation_No in ( $list ) ";
    }
    my %pds = $dbc->Table_retrieve(
        -table     => 'Process_Deviation LEFT JOIN Process_Deviation_Object ON FK_Process_Deviation__ID = Process_Deviation_ID LEFT JOIN Object_Class on FK_Object_Class__ID = Object_Class_ID',
        -fields    => [ 'Process_Deviation_Name', 'Process_Deviation_Description', 'Deviation_No', 'Object_Class', 'Object_ID AS Object_Identification', 'Process_Deviation_Object_ID' ],
        -condition => $condition,
        -order     => 'Deviation_No,Object_Class,Object_ID',
    );
    my $index = 0;
    my %data;
    while ( defined $pds{Deviation_No}[$index] ) {
        my $pd_No = $pds{Deviation_No}[$index];
        if ( !defined $data{$pd_No} ) {
            $data{$pd_No}{Name}        = $pds{Process_Deviation_Name}[$index];
            $data{$pd_No}{Description} = $pds{Process_Deviation_Description}[$index];
        }
        my $obj_class = $pds{Object_Class}[$index];
        if ($obj_class) {
            if ( !defined $data{$pd_No}{Links}{$obj_class} ) {
                $data{$pd_No}{Links}{$obj_class} = [ $pds{Object_Identification}[$index] ];
            }
            else {
                push @{ $data{$pd_No}{Links}{$obj_class} }, $pds{Object_Identification}[$index];
            }
        }
        $index++;
    }

    my %hash = ( 'Name' => [], 'Deviation_No' => [], 'Description' => [], 'Links' => [] );
    my @keys = ( 'Name', 'Deviation_No', 'Description', 'Links' );
    foreach my $pd_No ( sort keys %data ) {
        my $doc_link = &get_document_link( -deviation_no => $pd_No );
        push @{ $hash{Deviation_No} }, $doc_link;
        push @{ $hash{Name} },         $data{$pd_No}{Name};
        push @{ $hash{Description} },  $data{$pd_No}{Description};
        my $links;
        if ( defined $data{$pd_No}{Links} ) {
            foreach my $class ( sort keys %{ $data{$pd_No}{Links} } ) {
                my $object_ids = join ', ', @{ $data{$pd_No}{Links}{$class} };
                $links .= "$class:$object_ids<BR>";
            }
        }
        push @{ $hash{Links} }, $links;
    }
    $page .= SDB::HTML::display_hash( -dbc => $dbc, -hash => \%hash, -keys => \@keys, -return_html => 1 );

    $page .= '<hr>';

    $page .= create_tree( -tree => { 'New Process Deviation' => new_deviation( -dbc => $dbc ) } );
    $page .= create_tree( -tree => { 'Link Process Deviation to Objects'     => link_deviation_to_objects($dbc) } );
    $page .= create_tree( -tree => { 'Remove Process Deviation from Objects' => delete_linked_deviation($dbc) } );
    $page .= create_tree( -tree => { 'Search Process Deviation'              => search_deviation($dbc) } );
    return $page;
}

############################
# Define new process deviation
#
# Usage:	my $page = new_deviation( -dbc => $dbc );
# Return:	HTML page
############################
sub new_deviation {
############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my %grey;
    my %preset;
    my %hidden;
    my %list;

    my $navigator = 1;
    my $repeat;

    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Process_Deviation', -target => 'Database' );
    $table->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -list => \%list );

    return $table->generate( -navigator_on => $navigator, -return_html => 1, -repeat => $repeat );
}

############################
# Interface for linking process deviation to multiple objects e.g. samples, libraries, plates, runs, etc
#
# Usage:	my $page = link_deviation_to_objects( -dbc => $dbc );
# Return:	HTML page
############################
sub link_deviation_to_objects {
############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $table = new HTML_Table( -width => 800, -border => 1, -sortable => 0 );
    my $table_title = "Link Process Deviation to Objects";
    $table->Set_Title( $table_title, fsize => '-1' );
    my $header = [ Show_Tool_Tip( "Deviation No", 'Choose a process deviation' ), Show_Tool_Tip( "Object Class", 'The object type that the process deviation will be applied to' ), Show_Tool_Tip( "Object ID", 'The object IDs' ) ];
    $table->Set_Headers($header);

    my $deviation_no_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -name => 'Process_Deviation.Deviation_No', -default => '', -search => 1, -filter => 1, -force => 1 ), 'Specify a deviation No' );
    my @object_classes = alDente::Process_Deviation::get_valid_deviation_object_classes( -dbc => $dbc );
    my $object_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -field => 'Object_Class.Object_Class', -options => \@object_classes, -default => '', -search => 1, -filter => 1, -force => 1 ), 'Select a object class' );
    my $object_id_spec = Show_Tool_Tip(
        textfield( -name => 'Object_ID', -size => 20, -force => 1 ),
        "Enter object id(s). Multiple ids can be entered in the comma separated list format (e.g. 620658,620670). \nAll digit IDs can be entered in range (e.g. 620658-620700). \nTo enter libraries in range, enclose the digits in range in square brackets (e.g. A25[382-471]). \nTips: If the object class is 'Plate', 'traxxxx' can be accepted and will be converted to plate ids automatically (e.g. tra30654,tra30656 or tra30666-tra30668)."
    );
    $table->Set_Row( [ $deviation_no_spec, $object_spec, $object_id_spec ], -repeat => 1 );

    my $output = alDente::Form::start_alDente_form( $dbc, 'Link_Deviation_to_Objects' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Process_Deviation_App', -force => 1 );
    $output .= $table->Printout(0);
    $output .= set_validator( -name => 'Process_Deviation.Deviation_No', -mandatory => 1 );
    $output .= set_validator( -name => 'FK_Object_Class__ID', -mandatory => 1 );
    $output .= set_validator( -name => 'Object_ID', -mandatory => 1 );
    $output .= '<BR>' . submit( -name => 'rm', -value => 'Link Deviation to Objects', -class => 'Std', -onClick => "return validateForm(this.form)", -force => 1 );
    $output .= end_form();
    return $output;
}

############################
# Interface for removing process deviation already linked to objects e.g. samples, libraries, plates, runs, etc
#
# Usage:	my $page = delete_linked_deviation( -dbc => $dbc );
# Return:	HTML page
############################
sub delete_linked_deviation {
############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $table = new HTML_Table( -width => 800, -border => 1, -sortable => 0 );
    my $table_title = "Remove Process Deviation from Objects";
    $table->Set_Title( $table_title, fsize => '-1' );
    my $header = [ Show_Tool_Tip( "Deviation No", 'Choose a process deviation' ), Show_Tool_Tip( "Object Class", 'The object type that the process deviation will be applied to' ), Show_Tool_Tip( "Object ID", 'The object IDs' ) ];
    $table->Set_Headers($header);

    my $deviation_no_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -name => 'Process_Deviation.Deviation_No', -default => '', -search => 1, -filter => 1, -force => 1 ), 'Specify a deviation No' );
    my @object_classes = alDente::Process_Deviation::get_valid_deviation_object_classes( -dbc => $dbc );
    my $object_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -name => 'Object_Class.Object_Class', -options => \@object_classes, -default => '', -search => 1, -filter => 1, -force => 1 ), 'Select a object class' );
    my $object_id_spec = Show_Tool_Tip(
        textfield( -name => 'Object_ID', -size => 20, -force => 1 ),
        "Enter object id(s). Multiple ids can be entered in the comma separated list format (e.g. 620658,620670). \nAll digit IDs can be entered in range (e.g. 620658-620700). \nTo enter libraries in range, enclose the digits in range in square brackets (e.g. A25[382-471]). \nTips: If the object class is 'Plate', 'traxxxx' can be accepted and will be converted to plate ids automatically (e.g. tra30654,tra30656 or tra30666-tra30668)."
    );
    $table->Set_Row( [ $deviation_no_spec, $object_spec, $object_id_spec ], -repeat => 0 );

    my $output = alDente::Form::start_alDente_form( $dbc, 'Link_Deviation_to_Objects' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Process_Deviation_App', -force => 1 );
    $output .= $table->Printout(0);
    $output .= set_validator( -name => 'Process_Deviation.Deviation_No', -mandatory => 1 );
    $output .= set_validator( -name => 'FK_Object_Class__ID', -mandatory => 1 );
    $output .= set_validator( -name => 'Object_ID', -mandatory => 1 );
    $output .= '<BR>' . submit( -name => 'rm', -value => 'Remove Deviation from Objects', -class => 'Std', -onClick => "return validateForm(this.form)", -force => 1 );
    $output .= end_form();
    return $output;
}

###########################
#
# Select a list of objects
#
###########################
sub select_objects_view {
    my %args      = filter_input( \@_, -args => 'dbc' );
    my $dbc       = $args{-dbc};
    my $tables    = $args{-tables};
    my $fields    = $args{-fields};
    my $condition = $args{-condition};

    my $q         = CGI->new;
    my $add_html  = $q->hidden( -name => 'Override_Confirmation', -value => 1 );
    my @run_modes = ('Delete Process Deviation from Objects');

    return &SDB::DB_Form_Viewer::mark_records(
        -dbc         => $dbc,
        -tables      => $tables,
        -list        => $fields,
        -condition   => $condition,
        -application => 'alDente::Process_Deviation_App',
        -run_modes   => \@run_modes,
        -add_html    => $add_html,
        -return_html => 1
    );

}

############################
# Interface for searching process deviation
#
# Usage:	my $page = search_deviation( -dbc => $dbc );
# Return:	HTML page
############################
sub search_deviation {
############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $table = new HTML_Table( -width => 800, -border => 1, -sortable => 0 );

    #my $table_title = "Search Process Deviation";
    #$table->Set_Title( $table_title, fsize => '-1' );
    my $header = [ Show_Tool_Tip( "Deviation No", 'Search by process deviation No' ), Show_Tool_Tip( "Object Class", 'Search by object class' ), Show_Tool_Tip( "Object ID", 'Search by object ID' ) ];
    $table->Set_Headers($header);

    my $deviation_no_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -name => 'Process_Deviation.Deviation_No', -default => '', -search => 1, -filter => 1, -force => 1 ), 'Specify a deviation No' );
    my @object_classes = alDente::Process_Deviation::get_valid_deviation_object_classes( -dbc => $dbc );
    my $object_spec = Show_Tool_Tip( alDente::Tools::search_list( -dbc => $dbc, -name => 'Object_Class.Object_Class', -options => \@object_classes, -default => '', -search => 1, -filter => 1, -force => 1 ), 'Select a object class' );
    my $object_id_spec = Show_Tool_Tip( textfield( -name => 'Object_ID', -size => 20, -force => 1 ),
        'Enter one or multiple object ids. Multiple ids can be entered in the comma separated list format (e.g. 1,2,3), or in range (e.g. 100-120). \nNote: The range input is only valid for all digit IDs. It is not valid for Libraries.' );
    $table->Set_Row( [ $deviation_no_spec, $object_spec, $object_id_spec ] );

    my $output = alDente::Form::start_alDente_form( $dbc, 'Search_Deviation' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Process_Deviation_App', -force => 1 );
    $output .= $table->Printout(0);
    $output .= '<BR>' . submit( -name => 'rm', -value => 'Search Deviation', -class => 'Std', -force => 1 );
    $output .= end_form();
    return $output;
}

#######################
# Generate the link to the document on qpweb
#
# Usage:	my $link = get_document_link( -deviation_no => 'PD.476' );
# Return:	Scalar, a HTML string of the link
#######################
sub get_document_link {
#######################
    my %args = filter_input( \@_, -args => 'deviation_no' );
    my $dev_no = $args{-deviation_no};

    my $PADDED_LENGTH = 4;

    # pad the PD number to $PADDED_LENGTH
    my $padded_No;
    if ( $dev_no =~ /PD\.(\d+)/i ) {
        my $digits = $1;
        $padded_No = 'PD.';
        for ( my $i = 0; $i < $PADDED_LENGTH - length($digits); $i++ ) {
            $padded_No .= '0';
        }
        $padded_No .= $digits;
    }
    else {
        $padded_No .= $dev_no;
    }

    my $doc_link = "<A href='http://qpweb.bcgsc.ca/QA/CompletedProcessDeviationWaiverForm/$padded_No.html'>$dev_no</A>";
    return $doc_link;
}

sub deviation_label {
    my %args = filter_input( \@_, -args => 'dbc,deviation_ids' );
    my $dbc  = $args{-dbc};
    my $ids  = $args{-deviation_ids};                               # array ref of process deviation ids

    my $label;
    if ( int(@$ids) ) {
        $label = "<font color=red>Process Deviations: </font>";
        my $id_list = join ',', @$ids;
        my @deviation_nos = $dbc->Table_find( 'Process_Deviation', 'Deviation_No', "WHERE Process_Deviation_ID in ( $id_list )", -distinct => 1 );
        foreach my $dev_no (@deviation_nos) {
            my $doc_link = get_document_link( -deviation_no => $dev_no );
            $label .= "<font color=red> $doc_link </font>";
        }
    }
    return $label;
}
1;
