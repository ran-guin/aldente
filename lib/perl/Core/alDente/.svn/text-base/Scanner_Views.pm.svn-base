package alDente::Scanner_Views;

use CGI;

use strict;
use RGTools::RGIO;

#use RGTools::Conversion;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;

#use alDente::Validation;
use alDente::Tools;
use alDente::Form;
use alDente::Scanner;
use alDente::SDB_Defaults;
use alDente::Validation;

use vars qw(%Configs $Security %Settings);

##################################################################
#
##################################################################

###########################
sub prompt_Selection {
###########################
    #
    # alDente::Scanner_Views::prompt_Selection(-dbc=> $dbc, -barcode => $barcode, -objects => \%objects);
    # alDente::Scanner_Views::prompt_Selection(-dbc=> $dbc, -runmodes => $run_modes_ref);
###########################
    my %args          = @_;
    my $dbc           = $args{-dbc};
    my $barcode       = $args{-barcode};
    my $objects_ref   = $args{-objects};
    my $run_modes_ref = $args{-runmodes};
    my $dbc           = $args{-dbc};
    my @run_modes     = @$run_modes_ref if $run_modes_ref;
    my %objects       = %$objects_ref if $objects_ref;

    my $q = new CGI;

    my $page = alDente::Form::start_alDente_form( $dbc, 'Prompt Selection' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Scanner_App', -force => 1 ) . $q->hidden( -name => 'Barcode', -value => $barcode, -force => 1 ) . vspace();

    if (@run_modes) {
        Message 'Please select action';
        for my $mode (@run_modes) {
            $page .= $q->submit( -name => 'rm', -value => $mode, -class => "Std", -force => 1 ) . vspace();
        }
    }

    my @objects = keys %objects;
    if (@objects) {
        Message "You have entered '$barcode', is this a library ? ";
        $page
            .= $q->hidden( -name => 'Not Library', -value => 'Confirmed', -force => 1 )
            . $q->submit( -name => 'rm', -value => 'Display library Home-page', -class => "Std", -force => 1 )
            . vspace()
            . $q->submit( -name => 'rm', -value => 'This is not a library', -class => "Std", -force => 1 )
            . vspace();
    }

    $page .= $q->end_form();
    return $page;
}

#########################
# Note: This has been reworked to work with all solutions
############################
sub Validate_Solution {
###########################
    my $dbc     = shift;
    my $barcode = shift;

    my $q = new CGI;

    my $plates   = &get_aldente_id( $dbc, $barcode, 'Plate',    -validate => 1 );
    my $solution = &get_aldente_id( $dbc, $barcode, 'Solution', -validate => 1 );

    foreach my $plate ( split ',', $plates ) {
        my $info = get_FK_info( $dbc, 'FK_Plate__ID', $plate );
        print "<B>$info</B><BR>";
    }
    print "<HR>";

    unless ($plates) { Message("No Valid Plates entered"); return 0; }
    unless ($solution) {
        Message("No Valid Reagents/Solutions entered");
        return 0;
    }

    require alDente::Solution;
    my @primer_list = &alDente::Solution::get_original_reagents( $dbc, $solution, -type => 'Primer' );

    # check if the solution is a primer. If it is, then check if the solution is valid
    if ( int(@primer_list) > 0 ) {
        my $primer = join( ',', @primer_list );
        my @valid_primers = $dbc->Table_find(
            'Vector_TypePrimer,Vector,Primer,LibraryVector,Plate',
            'Primer_Name',
            "where Vector_TypePrimer.FK_Vector_Type__ID = Vector.FK_Vector_Type__ID and Vector.Vector_ID = LibraryVector.FK_Vector__ID AND Vector_TypePrimer.FK_Primer__ID = Primer_ID AND LibraryVector.FK_Library__Name = Plate.FK_Library__Name AND Plate_ID in ($plates)",
            'Distinct'
        );

        my @suggested_primers = $dbc->Table_find(
            'LibraryApplication,Object_Class,Plate,Primer',                                                                                                                                                            'Primer_Name',
            "where Object_Class.Object_Class_ID = FK_Object_Class__ID and Object_ID=Primer_ID AND Object_Class = 'Primer' and LibraryApplication.FK_Library__Name = Plate.FK_Library__Name AND Plate_ID in ($plates)", 'Distinct'
        );
        my @input_primers = $dbc->Table_find( 'Primer,Solution,Stock,Stock_Catalog', 'Primer_Name',
            "where Primer_Name = Stock_Catalog_Name AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID AND Solution_ID in ($primer) AND Solution_Type = 'Primer'" );

        my $entered_primers = join ',', @input_primers;

        my ($vector) = $dbc->Table_find(
            'Library,LibraryVector, Vector, Plate,Vector_Type',                                                                                                               'Vector_Type_Name',
            "where Plate.FK_Library__Name = LibraryVector.FK_Library__Name and FK_Vector__ID  = Vector_ID and FK_Vector_Type__ID = Vector_Type_ID and Plate_ID in ($plates)", 'Distinct'
        );
        my ($lib) = $dbc->Table_find( 'Plate', 'FK_Library__Name', "where Plate_ID in ($plates)", 'Distinct' );

        my $vector_link = &Link_To( $dbc->config('homelink'), $vector,          "&Info=1&Table=Vector&Field=Vector_Type_Name&Like=$vector",     'blue', ['newwin'] );
        my $lib_link    = &Link_To( $dbc->config('homelink'), $lib,             "&Info=1&Table=Library&Field=Library_Name&Like=$lib",           'blue', ['newwin'] );
        my $primer_link = &Link_To( $dbc->config('homelink'), $entered_primers, "&Info=1&Table=Primer&Field=Primer_Name&Like=$entered_primers", 'blue', ['newwin'] );

        $valid_primers[0]     ||= '(None) ' . '<BR>' . &Link_To( $dbc->config('homelink'), 'Add Valid Primer',     "&New+Entry=New+Vector_TypePrimer&Vector_Type_Name=$vector",    'blue', ['newwin'] );
        $suggested_primers[0] ||= '(None) ' . '<BR>' . &Link_To( $dbc->config('homelink'), 'Add Suggested Primer', "&New+Valid+Primers=1&Standard+Page=Library&Library_Name=$lib", 'blue', ['newwin'] );

        print "<B>Valid Primers for $vector_link</B>:<LI>" . join '<LI>', @valid_primers;
        print '<hr>';
        print "<B>Suggested Primers for $lib_link</B>:<LI>" . join '<LI>', @suggested_primers;
        print '<hr>';

        my $ok = 0;
        if ( int(@input_primers) ) {
            print "Primer(s) Entered: Sol$primer: <B>$primer_link</B>" . &vspace();
            $ok++;
        }
        else {
            Message("No valid Primer scanned with plate");
        }

        foreach my $entered_primer (@input_primers) {
            if ( grep /^$entered_primer$/, @valid_primers ) {
                print "<B>$entered_primer valid</B>" . &vspace();
                $ok++;
            }
            else {
                print "<B><Font color=red>$entered_primer INVALID</Font></B>" . &vspace();
                $ok = 0;
            }

            if ( grep /^$entered_primer$/, @suggested_primers ) {
                print "<B>$entered_primer suggested</B>" . &vspace();
                $ok++;
            }
            else {
                print "<B><Font color=red>$entered_primer NOT SUGGESTED</Font></B>" . &vspace();
                $ok = 0;
            }
        }
        unless ($ok) {
            &main::leave();
        }
    }

    require alDente::Solution_Views;
    my $page = alDente::Solution_Views::display_Solution_to_Plate( -dbc => $dbc, -plates => $plates, -solutions => $solution );
    print $page;
    return;
}

1;
