###############################################################################
#
# Solution.pm
#
# This module handles Solutions in the database.
#
################################################################################
################################################################################
# $Id: Solution.pm,v 1.26 2004/12/03 18:56:14 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.26 $
#     CVS Date: $Date: 2004/12/03 18:56:14 $
################################################################################
#
# Uses Chemistry(Chemistry_calculate), RGIO(Message),
#
#
package alDente::Solution;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Solution.pm - This module handles Solutions in the database.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Solutions in the database.<BR>Uses Chemistry(Chemistry_calculate), RGIO(Message) <BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    solution_main
    original_solution
    save_original_solution
    home_solution
    solution_footer
    identify_mixture
    mix_solution
    save_mixture
    mixture_options
    make_Solution
    save_standard_mixture
    apply_solution
    dispense_solution
    empty
    open_bottle
    unopen
    store_solution
    new_primer
    save_original_primer
    update_primer
    more_solution_info
    order_check
    solution_status
    solution_details
    get_original_reagents
    get_downstream_solutions
    show_applications
    get_reagent_amounts
    expiring_solutions
    get_expiry
);
@EXPORT_OK = qw(
    solution_main
    original_solution
    save_original_solution
    home_solution
    solution_footer
    identify_mixture
    mix_solution
    save_mixture
    mixture_options
    make_Solution
    save_standard_mixture
    apply_solution
    dispense_solution
    empty
    open_bottle
    unopen
    store_solution
    new_primer
    save_original_primer
    update_primer
    more_solution_info
    order_check
    solution_status
    solution_details
    get_original_reagents
    get_downstream_solutions
    show_applications
    get_reagent_amounts
    expiring_solutions
    get_expiry
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::HTML_Table;
use RGTools::Views;

use SDB::DBIO;
use SDB::DB_Form_Viewer;
use SDB::CustomSettings;
use SDB::DB_Form;
use SDB::Session;

use alDente::Validation;
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Security;
use alDente::Tools;
use alDente::Grp;
use alDente::QA;
use alDente::QA_Views;
use alDente::Stock_Views;
use alDente::Solution_Views;

#use alDente::Stock;
##############################
# global_vars                #
##############################
our ( $scanner_mode, $testing, $development, $URL_temp_dir, $html_header, $homefile );
our ( $style, $dbase, $barcode, $user );
our ( $plate_id,  $current_plates, $plate_set );
our ( $equipment, $equipment_id,   $solution_id );
our ( $sol_mix,   $expiry,         $oldest );

#
# $sol_mix is a global used to format reagent/solution mixures...
#  Solutions used appear as eg: '1:100mL:(notes),2:150mg:(notes)'
#  indicating 100mL of Sol1 + 150mg of Sol2 (notes are optional comments for Mixture)
#
our ( $sets, $procedure, $protocol );
our ( $last_page, $errmsg );
our ( $br,        $lf );
our ( @users,     @suppliers, @plate_sizes, @plate_info, @plate_formats );
our ( @locations, @libraries );
our ( $nowday, $nowtime, $nowDT );
our ( $size, $quadrant, $rack, $format, $button_style );
our ( $MenuSearch, $padding );
use vars qw(%Std_Parameters %Settings $Security $Sess $Connection);

use vars qw(%Configs);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################
##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args     = @_;
    my $id       = $args{-id};
    my $stock_id = $args{-stock_id};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $Stock    = $args{-Stock};

    my $retrieve = $args{-retrieve};    ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    my $self;
    my $type;
    if ($Stock) {
        $self = $Stock;
        $type = $self->value('Stock_Type');
    }
    else {
        $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => [ 'Solution', 'Stock', 'Stock_Catalog' ] );

        if ($id) {
            $self->{id} = $id;
            $self->primary_value( -table => 'Solution', -value => $id );
            ($type) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Type', "WHERE FK_Stock_Catalog__ID=Stock_Catalog_ID AND FK_Stock__ID=Stock_ID AND Solution_ID IN ($id)", -distinct => 1 );
        }
        elsif ($stock_id) {
            $self->{stock_id} = $id;
            $self->primary_value( -table => 'Stock', -value => $stock_id );
            ($type) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Type', "WHERE FK_Stock_Catalog__ID=Stock_Catalog_ID AND FK_Stock__ID=Stock_ID AND Stock_ID = $stock_id", -distinct => 1 );
        }
    }
    my $reload;
    if ( $type =~ /Primer/ ) {
        $self->add_tables( 'Primer', 'Primer.Primer_Name = Stock_Catalog.Stock_Catalog_Name' );
        $reload = 1;
    }
    $self->load_Object( -force => $reload );    ## force reload if extra table information included

    $self->{id} = $self->get_data('Solution_ID');

    if ( $type =~ /Primer/ && $self->value('Solution_ID') ) {
        my $sol_id = $self->value('Solution_ID');
        ( my $found ) = $dbc->Table_find( 'Primer,Stock_Catalog,Stock,Solution', 'Primer_ID', "WHERE FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_Catalog_Name = Primer_Name AND Solution_ID IN ($sol_id)" );
        unless ($found) {
            $dbc -> warning ("There is no Primer record for SOL" . $sol_id . ".  Please ask your LAB Admin to add this record"); 
		}
    }
    $self->{dbc}     = $dbc;
    $self->{records} = 0;      ## number of records currently loaded

    bless $self, $class;
    return $self;
}

###############################################
# public_methods             #
##############################
################################
sub solution_QC_trigger {
################################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};
    my $ok;

    my ($status) = $dbc->Table_find( 'Solution', 'QC_Status', "WHERE Solution_ID = $id" );
    my @solutions = get_downstream_solutions( $dbc, $id );

    my $sols = join ',', @solutions;
    if ( $status eq 'Failed' ) {
        my $link = &Link_To( $dbc->config('homelink'), " Details", "&cgi_application=alDente::Solution_App&ID=$sols", 'red', ['newwin'] );
        $dbc->message("Setting QC status to Failed for the following solutions: $sols $link");
        if ($sols) {
            $ok = $dbc->Table_update_array( 'Solution', ['QC_Status'], ['Failed'], "WHERE Solution_ID IN ($sols)", -no_triggers => 1, -autoquote => 1 );
        }
        my ($preps) = $dbc->Table_find( 'Plate_Prep', 'Plate_Prep_ID', "WHERE FK_Solution__ID IN( $sols)" );
        if ($preps) {
            my $html
                = $dbc->Table_retrieve_display( 'Plate_Prep', [ 'FK_Prep__ID', 'FK_Plate__ID', 'FK_Plate_Set__Number', 'FK_Solution__ID', ], "WHERE FK_Solution__ID IN ($sols)", -distinct => 1, -title => 'Faield Solutions Used In', -return_html => 1 );
            print $html;
        }
        return $ok;
    }
    else {

        #remove original solution
        if ( int @solutions == 1 ) { return 1; }
        else {
            $sols =~ s/$id\,//;
            my $count = int( split ',', $sols );
            my $link = &Link_To( $dbc->config('homelink'), " $count solutions", "&cgi_application=alDente::Solution_App&ID=$sols", 'red', ['newwin'] );
            $dbc->warning("The QC Status for these daughter solutions remains unchanged: $link");
            return 1;
        }
    }
}

###################################
sub export_Solutions {
###################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $self->{dbc} || $args{-dbc};
    my $ids      = $args{-ids};
    my $dest     = $args{-destination};
    my $comments = $args{-comments};
    my $user_id     = $dbc->get_local('user_id');

    my ($exprack_id) = $dbc->Table_find( 'Location,Equipment,Rack', 'Rack_ID', "WHERE FK_Location__ID = Location_ID AND FK_Equipment__ID = Equipment_ID AND Location_Name='$dest' " );
    &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Solution', -ids => $ids, -rack => $exprack_id, -force => 1, -confirmed => 1 );

    my $message = "Exported to '$dest' by " . $dbc->get_FK_info( 'FK_Employee__ID', $user_id ) . ", on " . &date_time() . '.';
    $message .= " - Comments: $comments ." if $comments;
    $message = $dbc->dbh()->quote($message);
    my $status = 'Exported';
    $status = $dbc->dbh()->quote($status);

    my $ok = $dbc->Table_update_array( 'Solution', [ 'Solution_Notes', 'Solution_Status' ], [ "CASE WHEN Solution_Notes IS NULL THEN $message ELSE CONCAT(Solution_Notes,' ',$message) END", "$status" ], "WHERE Solution_ID in ($ids)" );

    if ($ok) {
        Message "Exported $ok Solutions";
        return 1;
    }

    else {
        Message "Failed at exporting solutions";
        return;
    }

    #131047,131048,131049,131050,131051
}

##############################
sub delete_Solution {
##############################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my ( $ref_tables, $details, $ref_fields ) = $dbc->get_references(
        -table    => 'Solution',
        -field    => 'Solution_ID',
        -value    => $id,
        -indirect => 1
    );

    my ($info) = $dbc->Table_find( 'Solution, Stock', "Stock_Number_in_Batch, Stock_ID", " WHERE FK_Stock__ID = Stock_ID AND Solution_ID = $id" );
    my ( $num_in_batch, $stock_id ) = split ',', $info;

    my @cascade;
    my %fields = %$ref_fields if $ref_fields;

    for my $field ( keys %fields ) {
        if ( $field =~ /(.+)\..+/ ) {
            push @cascade, $1;
        }
    }

    my $ok = $dbc->delete_records(
        -table   => 'Solution',
        -dfield  => 'Solution_ID',
        -id_list => $id,
        -confirm => 1,
        -cascade => \@cascade
    );
    unless ($ok) {return}

    if ( $num_in_batch > 1 ) {
        $num_in_batch--;
        my $ok = $dbc->Table_update( 'Stock', 'Stock_Number_in_Batch', $num_in_batch, "where Stock_ID = $stock_id" );
    }
    else {
        my $ok = $dbc->delete_records(
            -table   => 'Stock',
            -dfield  => 'Stock_ID',
            -id_list => $stock_id,
            -confirm => 1
        );
    }
    return 1;
}

##############################
# public_functions           #
##############################

##########################                                  Should be obsolete
sub _init_table {
##########################
    my $title = shift;
    my $width = shift || "100%";

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width($width);
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour( '#eeeeff', '#eeeeff' );
    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' );

    return $table;
}

################################
sub save_original_solution {
################################
    #
    # Add record to database based on original_solution input...
    #
#########################

    Message('saving original solution');
    my $ok;

    my $dbc = $Connection;    #change to $args{dbc} or $dbc = shift
    my $user_id     = $dbc->get_local('user_id');

    my $s_name     = param('Name');
    my $s_type     = param('Type');
    my $s_qty      = param('Quantity');
    my $units      = param('Units');
    my $s_made     = param('Created');
    my $s_received = param('Received');
    my $open       = param('Opened');

    my $s_cost  = param('Cost')      || 'NULL';
    my $s_order = param('Orders_ID') || 'NULL';

    my $status = "Open";
    if    ( $open eq 'unopened' )      { $s_made     = "0000-00-00"; $status = "Unopened"; }
    elsif ( $open eq 'made in house' ) { $s_received = "0000-00-00"; $status = "Open"; }

    my $s_exp         = param('Expiry')   || '0000-00-00';
    my $soln_supplier = param('Supplier') || param('FK_Organization__ID');
    my $s_cat          = param('Catalog_Number');
    my $s_lot          = param('Lot_Number');
    my $s_instructions = param('Instructions');
    my $s_location     = param('Location') || param('Location Choice') || param('FK_Rack__ID') || param('FK_Rack__ID Choice');
    my $bottles        = param('Bottles');
    my $size           = param('Quantity') || 0;

    ( $size, $units ) = &convert_to_mils( $size, $units );

    my @extra_fields  = ();
    my @extra_values  = ();
    my @Sextra_fields = ();    ## for Solution_Info..
    my @Sextra_values = ();

    my $ODs        = Extract_Values( [ param('ODs'),        'NULL' ] );
    my $nMoles     = Extract_Values( [ param('nMoles'),     'NULL' ] );
    my $micrograms = Extract_Values( [ param('micrograms'), 'NULL' ] );

    my $Box_id = param('Box ID') || 'NULL';

    $s_name ||= param('Stock_Catalog_Name Choice');
    $s_type ||= param('Stock_Type Choice');

    ######## add extra fields for Primers or Kit Part/Lot Numbers ##################

    if ( $s_type =~ /primer/i ) {
        $ok = $dbc->Table_find( 'Primer', 'Primer_Name', "where Primer_Name = \"$s_name\"" );
        if ( $ok != 1 ) {
            Message("Error:  you must set up Primer in Database first (see Database administrator)");
            return 0;
        }
        else {
            push( @Sextra_fields, ( 'nMoles', 'ODs', 'micrograms' ) );
            push( @Sextra_values, ( $nMoles, $ODs, $micrograms ) );
        }
    }

    if ($Box_id) {
        push( @extra_fields, 'FK_Box__ID' );
        push( @extra_values, $Box_id );
    }

    #
    # Calibrate to mils...
    #

    my $qty = param('Quantity');
    ( $s_qty, $units ) = &normalize_units( $qty, $units );
    if ( !$units ) { $dbc->warning("Unrecognized units"); }

    if ($soln_supplier) {
        my $found = join ',', $dbc->Table_find( 'Organization', 'Organization_Name', "where Organization_Name=\"$soln_supplier\"" );
        if ( ( $found =~ /\w/ ) && ( $found ne 'NULL' ) ) {

            #	        print "$found already in database\n<BR>";
        }
        else {
            $ok = $dbc->Table_append_array( 'Organization', ['Organization_Name,Organization_Type'], [ $soln_supplier, 'Lab Supplier' ], -autoquote => 1 );
            if ($ok) {
                my $supp_link = &Link_To( $dbc->config('homelink'), ' (Check Info on Organization)', "&Info=1&Table=Organization&Field=Organization_ID&Like=$ok", 'blue', ['newwin'] );
                print "<B>Added $soln_supplier to supplier list </B>$supp_link<BR>";
            }
            else { Message("Error adding $soln_supplier to supplier list"); }
        }
    }
    else {
        $soln_supplier ||= param('Supplier Choice');
    }

    my $supplier_id = join ',', $dbc->Table_find( 'Organization', 'Organization_ID', "where Organization_Name=\"$soln_supplier\"" );

    $s_location = &get_FK_ID( $dbc, 'FK_Rack__ID', $s_location );

    #   user
    #   date created
    #
    #    if ($s_location=~/Rac(\d+)/i) {#
    #	$s_location=$1;
    #    }
    #    else {#
    #	Message("Invalid rack location ($s_location)");
    #	return 0;
    #    }

    if ( !$bottles =~ /^\d+$/ ) {
        Message("Error: Number of Bottles invalid ($bottles ?)");
        &original_solution();
        return 0;
    }

    $units ||= "mL";    ###### adjust units if necessary ########
    my $max_id = join ',', $dbc->Table_find( 'Solution', 'Max(Solution_ID)' );

    ######## save Solution_Info information ...
    #    my @Sol_fields = ('Stock_Expiry','Solution_Instructions');
    #    push(@Sol_fields,@Sextra_fields);
    #    my @Sol_values = ($s_exp,$s_instructions);
    #    push(@Sol_values,@Sextra_values);

    my $sol_info;

    #    if ($s_exp || $s_instructions) {#
    #	$sol_info = $Connection->Table_append_array('Solution_Info',\@Sol_fields,\@Sol_values,-autoquote=>1);
    #	print "Updated Solution information ($sol_info) for Reagent/Solution".br();
    #    }

    ######## save Stock Info information ...
    ( my $stock_catalog_ID ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_ID', "Where Stock_Catalog_Name = '$s_name'" );

    my @Batch_fields = ( 'FK_Stock_Catalog__ID', 'Stock_Received', 'Stock_Lot_Number', 'FK_Employee__ID', 'Stock_Cost', 'FK_Orders__ID', 'Stock_Number_in_Batch' );
    push( @Batch_fields, @extra_fields );
    my $type ||= 'Reagent';    ### unless saved as mixture (Solution) label them as reagents..

    my @Batch_values = ( $stock_catalog_ID, $s_received, $s_lot, $user_id, $s_cost, $s_order, $bottles );
    push( @Batch_values, @extra_values );
    my $batch;

    my $Batch_added = $dbc->Table_append_array( 'Stock', \@Batch_fields, \@Batch_values, -autoquote => 1 );
    if ( $Batch_added > 0 ) {
        $batch = $Batch_added;
        print "<B>Created Stock Batch: $batch</B>";
        my $batch_link = &Link_To( $dbc->config('homelink'), ' (Check Info on Stock Batch)', "&Info=1&Table=Stock&Field=Stock_ID&Like=$batch", 'blue', ['newwin'] );
        print '<BR>' . $batch_link . &vspace(5);
    }
    else { Message("Error appending Batch information"); return 0; }

    ### only per bottle: Quantity,Units,Quantity_Used,Rack,Bottle,Status.
    @extra_fields = ();
    @extra_values = ();
    if ( $s_type =~ /Primer/i ) {
        my $ods        = param('ODs')        || 0;
        my $nmoles     = param('nMoles')     || 0;
        my $micrograms = param('micrograms') || 0;
        my $new_info_id = $dbc->Table_append_array( 'Solution_Info', [ 'ODs', 'nMoles', 'micrograms' ], [ $ods, $nmoles, $micrograms ] );
        if ($new_info_id) {
            push( @extra_fields, 'FK_Solution__Info' );
            push( @extra_values, $new_info_id );
            print "INFO: $new_info_id.";
        }
    }
    for my $bottle ( 1 .. $bottles ) {
        ### Temporary - get rid of redundant fields once complete..
        my @fields = ( 'FK_Solution_Info__ID', 'FK_Stock__ID', 'Solution_Type', 'Solution_Started', 'Solution_Expiry', 'Quantity_Used', 'FK_Rack__ID', 'Solution_Status', 'Solution_Number', 'Solution_Number_in_Batch', @extra_fields );
        my @values = ( $sol_info, $batch, $s_type, $s_made, $s_exp, 0, $s_location, $status, $bottle, $bottles, @extra_values );

        $ok = $dbc->Table_append_array( 'Solution', \@fields, \@values, -autoquote => 1 );
        unless ($ok) {
            Message("Error: Reagent/Solution not added to Database: $DBI::errstr");
            return 0;
        }
    }
    my $new_sol_id = join ',', $dbc->Table_find( 'Solution', 'Solution_ID', "where Solution_ID > $max_id" );

    &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', "$new_sol_id" );

    ############ update number of items received in orders database... #################
    if ( $s_order =~ /\d/ ) {
        ( my $found ) = $dbc->Table_find( 'Solution,Stock', 'count(*)', "where FK_Stock__ID=Stock_ID and Stock.FK_Orders__ID=$s_order" );
        if ( $found =~ /\d+/ && ( $s_order =~ /\d/ ) ) {
            my $ok = $dbc->Table_update( 'Orders', 'Orders_Received', $found, "where Orders_ID = $s_order" );
            if   ($ok) { Message("Set number received to $found"); }
            else       { Message("problem setting $s_order to $found"); }
        }
    }

    print h3("New Solutions Added:  SOL $new_sol_id");
    my $sol_link = &Link_To( $dbc->config('homelink'), ' (Check Info on New Solution(s))', "&HomePage=Solution&ID=$new_sol_id", 'blue', ['newwin'] );
    print &vspace(10) . $sol_link . '<BR>';

    if ($s_cat) {
        unless ( &order_check($s_cat) ) {
            return 1;
        }
    }

    &original_solution();
    return 1;
}

##########################
sub identify_mixture {
##########################
    #
    #  Track mixture of solutions/reagents...
    #
##########################
    my $sol_mix = shift;    ####### formatted mixture list...

    my $dbc = $Connection;  # change to dbc = shift

    my $location = param('Location') || param('Location Choice') || param('FK_Rack__ID') || param('FK_Rack__ID Choice');
    my $oldest = param('Oldest');
    $barcode = param('Applied To');

    print "\n<BR><B>Mixing:</B>\n<BR>";
    my @solutions_used = split /,/, $sol_mix;
    foreach my $solution (@solutions_used) {
        ( my $sol, my $qty ) = split ':', $solution;
        my $sol_name = join ',', $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID=Stock_ID and Solution_ID=$sol" );
        if ( $qty > 0 ) { print "$qty of $sol_name\n<BR>"; }
    }

    print alDente::Form::start_alDente_form( $dbc );
    print hidden( -name => 'Barcode', -force => 1, -value => $barcode ), hidden( -name => 'Sol Mix', -value => "$sol_mix" ),

        #    submit(-name=>'Apply Mixture',-value=>'Apply Temporary Solution'), " to ",
        #    textfield(-name=>'Barcode',-size=>10),&vspace(),
        submit( -name => 'Save Mixture', -style => "background-color:red" ), &vspace(), "Names:     ", textfield( -name => 'Name', -size => 20, -default => '', -force => 1 ), &vspace(), "Expiry:   ",
        textfield( -name => 'Expiry', -size => 10, -force => 1, -default => "$oldest" ), &vspace(), "Instructions: ", textfield( -name => 'Instructions', -size => 30, -default => '', -force => 1 ), hidden( -name => 'FK_Rack__ID', -value => "$location" ),
        "\n<BR>";

    if ( param('Dispense') ) {
        my $bottles = param('Containers');
        my $sizes = Extract_Values( [ param('Total'), param('Dispense Qty') ] );
        if ( param('Dispense Units') ) {
            my $units = param('Dispense Units');
            ($sizes) = normalize_units( $sizes, $units );
        }
        if ($bottles) { $sizes = $sizes / $bottles; }
        print "# of Bottles:", textfield( -name => 'Bottles', -size => 5, -default => $bottles, -force => 1 ), '<BR>', "of: ", textfield( -name => 'Bottle Sizes', -size => 5, -default => $sizes, -force => 1 ), " mL";
    }
    else {
        my $bottles = Extract_Values( [ param('Containers'), param('Bottles'), 1 ] );
        print "# of Bottles:", textfield( -name => 'Bottles', -size => 5, -default => $bottles, -force => 1 ), '<BR>';
    }

    print "\n</FORM>";

    return;
}

#####################
sub mix_solution {
#####################
    #
    # add current solution to mixture...
    #
    # (This was used originally to track solutions continuously being added to...
    #
    my $solution_id = shift;
    my $quantity    = shift;
    my $units       = shift;
    my $comments    = shift;
    my $dbc         = $Connection;    # change to dbc = shift

    $solution_id =~ s/,$//;           ### get rid of possible trailing commas..

    my $intToday = &date_time();
    $intToday =~ s/[:\s-]//g;         ### convert to integer...

    my $ok;

    my $expiry ||= join ',', $dbc->Table_find( 'Solution', 'min(Solution_Expiry)', "where Solution_ID in ($solution_id) and Solution_Expiry > '0'" );
    $units ||= "mL";

    my $intExpiry = $expiry;
    $intExpiry =~ s /[:\s-]//g;
    if ( $intExpiry < $intToday ) { $dbc->warning("Expired Reagent found!"); }

    #
    # Calibrate to mils...
    #
    my $qty;
    ## <CONSTRUCTION> - replace below with convert_to_mils (?)...
    if    ( $units =~ /^mL/i ) { $qty = $quantity;           $units = "mL"; }
    elsif ( $units =~ /^L/i )  { $qty = $quantity * 1000;    $units = "mL"; }
    elsif ( $units =~ /^uL/i ) { $qty = $quantity / 1000;    $units = "mL"; }
    elsif ( $units =~ /^mg/i ) { $qty = $quantity;           $units = "mg"; }
    elsif ( $units =~ /^g/i )  { $qty = $quantity * 1000;    $units = "mg"; }
    elsif ( $units =~ /^kg/i ) { $qty = $quantity * 1000000; $units = "mg"; }
    else                       { $dbc->warning("Unrecognized units"); $qty = $quantity; }

    $barcode = "Sol" . $solution_id;

    $sol_mix ||= param('Sol Mix');    ###### parameter encoding solution mixtures:quantity:comments ###########

    if ( ( $sol_mix =~ /\d/ ) && ( $sol_mix ne 'NULL' ) ) {
        $sol_mix .= ",";
    }
    elsif ( param('Quantity') ) {
        ( my $first_sol ) = split ',', &get_aldente_id( $dbc, param('Solution Added'), 'Solution', -validate => 1, -qc_check => 1 );    ### only first
        $first_sol ||= get_aldente_id( $dbc, param('Solution_ID'), 'Solution', -validate => 1, -qc_check => 1 );                        ### if only ID, Quantity...
        ( my $first_q, my $first_units ) = &convert_to_mils( param('Quantity'), 'mL' );
        $sol_mix = "$first_sol:$first_q$first_units:";
        $sol_mix .= param('Mixture Comments');                                                                                          ######## comments ?????? ##
        $sol_mix .= ",";
        $oldest = join ',', $dbc->Table_find( 'Solution', 'Solution_Expiry', "where Solution_ID=$first_sol" );

######## update Quantity Used in First Solution #################
        $ok = $dbc->Table_update( 'Solution', 'Quantity_Used', "Quantity_Used + $first_q", "where Solution_ID=$first_sol" );
        if ($ok) {
            Test_Message( "updating Sol $first_sol Quantity used to + $first_q.", $testing );
        }
        else { Message("Quantity Used not updated ($first_sol used $first_q"); }
    }
    else {
        $sol_mix = "";
    }

    $sol_mix .= $solution_id;
    $sol_mix .= ":" . $qty . $units;
    $sol_mix .= ":" . $comments;

    #    print '<BR>',"sol_mix SET to $sol_mix.";

    Test_Message( "Sol: $sol_mix ($oldest .. $expiry)", $testing );

    if ( $expiry < $oldest ) { $oldest = $expiry; }

######## update Quantity Used in second Solution #################

    $ok = $dbc->Table_update( 'Solution', 'Quantity_Used', "Quantity_Used + $qty", "where Solution_ID=$solution_id" );
    if ($ok) {
        Test_Message( "updating $solution_id Quantity used to + $qty. ($quantity)", $testing );
    }
    else { Message("Quantity Used not updated"); }

    open_bottle($solution_id);

    if ( $ok > 0 ) {
        Test_Message( "(updated quantity of Sol $solution_id used)", $testing );
    }
    else { print "Error updating quantity (for sol$solution_id): $DBI::errstr\n<BR>"; }

    #    &home_solution($solution_id);
    return 1;
}

################################        ok for next release but very bad and should be redone
sub save_mixture {
#######################
    #
    # Save mixture to database...
    #
    # (Requires formatted list of ingredients in $sol_mix or param('Sol Mix')...
    #  eg.  '1:10,2:20' indicates 10 mils of Sol1 and 20 mils of Sol2.
    #
    #
#######################
    my %args = @_;

    #    my $name            = $args{-name};
    my $expiry           = $args{-expiry};
    my $location         = $args{-location};
    my $instructions     = $args{-instructions};
    my $type             = $args{-type} || param('Solution_Type') || 'Solution';
    my $group            = $args{-group} || param('FK_Grp__ID');
    my $source           = $args{-source} || param('Stock_Source') || 'Order';
    my $barcode_label_id = $args{-barcode_label_id};
    my $dbc              = $args{-dbc} || param('dbc') || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # will change to dbc = shift
    my $sol_mix          = $args{-sol_mix} || param('Sol Mix');
    my $cat_id           = $args{-catalog_id};
    my $bottles          = $args{-num_in_batch};
    my $units            = param('Units');
    $units ||= "mL";
    my $quantity;

    if ( $sol_mix =~ /,$/ ) { chop $sol_mix; }

    #### check for proper info... ###
    my $ok;
    $location = &get_FK_ID( $dbc, 'FK_Rack__ID', $location );
    unless ( $group =~ /[1-9]/ ) {
        $group = &get_FK_ID( $dbc, 'FK_Grp__ID', $group );
    }
    $nowDT = date_time();
    my @solutions_used = split /,/, $sol_mix;
    my @sol_list;
    foreach my $solution (@solutions_used) {
        ( my $sol, my $qty ) = split ':', $solution;
        unless ( $qty =~ /ml/i ) {
            my ($amount, $unit) = split ' ', $qty;
            my ($converted_qty, $converted_units) = convert_to_mils( $amount, $unit);
            $qty = $converted_qty .  ' ' . $converted_units;
        }
        unless ( $qty =~ /g/i ) {
            $quantity += $qty;    ### only add to quantity if volume units
        }
        push( @sol_list, $sol );
    }
    unless (@sol_list) { Message("No Reagents Listed"); return 0; }
    unless ($expiry) { $expiry = &get_expiry( join ',', @sol_list ); }
    my $bottle = 1;

    ####### update: check if multiple bottles ...
    $bottles ||= Extract_Values( [ param('Bottles'), 1 ] );
    my $localID = 'GSC';
    ( my $supplier_id ) = $Configs{local_organization_id} || $dbc->Table_find( 'Organization', 'Organization_ID', "where Organization_Name=\"$localID\"" );

    ######### Save information for Batch of solutions... (in case of multiple bottles) ###########

    my $user_id      = $dbc->config('user_id');
    my @Batch_fields = ( 'FK_Employee__ID', 'Stock_Number_in_Batch', 'Stock_Received', 'FK_Grp__ID', 'FK_Barcode_Label__ID', 'FK_Stock_Catalog__ID' );
    my @Batch_values = ( $user_id, $bottles, $nowDT, $group, $barcode_label_id, $cat_id );

    my $batch;
    my $Batch_added = $dbc->Table_append_array( 'Stock', \@Batch_fields, \@Batch_values, -autoquote => 1 );
    if ( $Batch_added > 0 ) {
        $batch = $Batch_added;
        my $batch_link = &Link_To( $dbc->config('homelink'), ' (Check Info)', "&Info=1&Table=Stock&Field=Stock_ID&Like=$batch", 'blue', ['newwin'] );
        print "<B>Created Stock Batch: $batch</B> $batch_link<BR>";
    }
    else { Message("Error appending Batch information"); }

    ####### temporary use of name ###
    my @fields = ( 'Solution_Started', 'Solution_Number', 'Solution_Number_in_Batch', 'Quantity_Used', 'Solution_Status', 'FK_Stock__ID', 'Solution_Type', 'Solution_Expiry', 'Solution_Quantity' );
    if ($location) { push @fields, 'FK_Rack__ID' }
    my @new_sol_ids = ();
    my $new_sol_id;

    #  my $qty = $quantity/$bottles;
    for my $bottle ( 1 .. $bottles ) {
        my @values = ( $nowDT, $bottle, $bottles, 0, 'Unopened', $batch, $type, $expiry, $quantity );
        if ($location) { push @values, $location }

        $new_sol_id = $dbc->Table_append_array( 'Solution', \@fields, \@values, -autoquote => 1 );
        if ( $new_sol_id > 0 ) { Test_Message( "Solutions) added to Database", $testing ); }
        else                   { print "Error: Reagent/Solution not added to Database: $DBI::errstr"; return 0; }

        #### use only the first solution to mark the mixtures...

        my $total_value  = 0;
        my $undetermined = 0;    ####### set to 1 if any of reagents are undetermined...
        foreach my $solution (@solutions_used) {
            ( my $sol_id, my $solution_qty, my $sol_comments ) = split ':', $solution;
            $sol_comments = '' if ( !defined $sol_comments );
            
            my ($sol_qty, $sol_units) = split ' ', $solution_qty;
            ( $sol_qty, my $added_units ) = &convert_to_mils( $sol_qty, $sol_units );

            if ($sol_id) {
                my @sol_info = $dbc->Table_find( 'Stock,Solution,Stock_Catalog', 'Stock_Catalog_Name,Stock_Cost,Solution_Quantity', "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID=Stock_ID and Solution_ID=$sol_id" );
                my ( $sol_name, $sol_cost, $sol_volume ) = split ',', $sol_info[0];
                ####### if no volume, set to quantity used, and send warning... #####
                if ( !$sol_volume ) {

                    #$dbc->warning("no volume set for $sol_name");
                    $sol_volume   = $sol_qty;
                    $undetermined = 1;          ######### leave cost undetermined...
                }
                ####### Calculate cost of this portion of the solution ##########
                unless ( $sol_cost =~ /\d+/ ) { $undetermined = 1; }    #### leave cost undetermined
                my $value = $sol_cost * $sol_qty / $sol_volume;
                $total_value += $value;
                $value = sprintf '%0.2f', $value;
                ######### Note that reagents added in mg are not added to volume... ####
                my $mg = '';
                if ( $added_units =~ /g/ ) { $mg = '(not added to volume)'; }

                ######## ADD VALUE/cost to label below
                $dbc->message("<span class=small><B>Added $sol_qty $added_units $mg of Sol$sol_id ($sol_name)</B></Span>");

                ## <CONSTRUCTION> ##
                if ( $sol_name =~ /Custom Oligo Plate/ ) {
                    my ($primer_plate_name) = $dbc->Table_find( "Primer_Plate", "Primer_Plate_Name", "WHERE FK_Solution__ID=$sol_id" );

                    # call remap
                    require alDente::Primer;
                    my $po = new alDente::Primer( -dbc => $dbc );
                    my $solution_id = $po->copy_primer_plate( -solution_id => $sol_id, -new_name => "$primer_plate_name Diluted", -stock_name => $sol_name, -target_solution_id => $new_sol_id );
                }
                my $ok = $dbc->Table_append_array( 'Mixture', [ 'FKUsed_Solution__ID', 'FKMade_Solution__ID', 'Quantity_Used', 'Mixture_Comments', 'Units_Used' ], [ $sol_id, $new_sol_id, $sol_qty, $sol_comments, $added_units ], -autoquote => 1 );
                unless ($ok) { Message( "Error: ", $DBI::errstr ); return 0; }

                ######## open Solution if not already done... #############
                open_bottle($sol_id);

                ######### update Quantities used #################
                ### temporarily save name ###
                $ok = $dbc->Table_update_array( 'Solution', ['Quantity_Used'], ["Quantity_Used + $sol_qty"], "where Solution_ID=$sol_id" );    ### do NOT use auto-quote since field is referenced...
                if ($ok) {
                    Test_Message( "updating $sol_id Quantity used to + $sol_qty. ($quantity)", $testing );
                }

                #	    else {Message("could not update Solution with $sol_qty used");}
            }
        }
        $sol_mix = "";                                                                                                                         # clear solution mixture
        ########### Update Cost of Solution Mixed ####################
        if ( ( $total_value =~ /\d+/ ) && !$undetermined ) {
            $total_value = sprintf "%0.2f", $total_value;
            $dbc->Table_update( 'Stock', 'Stock_Cost', $total_value, "where Stock_ID = $batch" );
        }
        else { $total_value = 'Unknown'; }
        ######## ADD VALUE/cost to label below
        push( @new_sol_ids, $new_sol_id );

        $dbc->message( "Created new Solution: " . alDente::Tools::alDente_ref( 'Solution', $new_sol_id, -dbc => $dbc ), -type => 'success' );

        &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', $new_sol_id );

        $dbc->session->reset_homepage( { 'Solution' => $new_sol_id } );    ##  if ( !$scanner_mode && $Sess && $Sess->{session_id} );
    }

    if ( int(@new_sol_ids) > 0 ) {
        return join( ',', @new_sol_ids );
    }
    else {
        return $new_sol_id;                                                ### just return last one made ...
    }
}

################################
sub combine_solutions {
#######################
    # Function to combine/mix solutions
    # This is a straight function call (instead of depending on form parameters)
    # Return: an array reference of new solution ids
################################

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,name,expiry,rack_id,instructions,type,group_id,label_id,source_sol_ids,source_quantities,source_units,bottles,print',
        -mandatory => 'dbc,name,rack_id,type,group_id,label_id,source_sol_ids,source_quantities,source_units'
    );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $name             = $args{-name};                                                                    # (Scalar) Name of the new solution
    my $expiry           = $args{-expiry};                                                                  # (Scalar) Expiry date of the new solution
    my $rack_id          = $args{-rack_id};                                                                 # (Scalar) Location of the new solution
    my $instructions     = $args{-instructions};
    my $type             = $args{-type} || 'Solution';                                                      # (Scalar) Type of the new solution. One of Buffer, Matrix, Primer, or Solution
    my $group_id         = $args{-group_id};                                                                # (Scalar) Group that is making the new solution
    my $barcode_label_id = $args{-label_id};                                                                # (Scalar) The barcode label ID of the new solution
    my $source_sol_id    = $args{-source_sol_ids};                                                          # (ArrayRef) The source solution IDs
    my $source_quantity  = $args{-source_quantities};                                                       # (ArrayRef) The source solution quantities
    my $source_unit      = $args{-source_units};                                                            # (ArrayRef) The source solution quantity units
    my $bottles          = $args{-bottles};                                                                 # (Scalar) Number of bottles to be created
    my $print_barcodes   = $args{ -print };                                                                 # (Scalar) Flag to print barcodes
    my $catalog_id       = $args{-catalog_id};
    my $source           = 'Made in House';

    ## ERROR CHECK ##
    # check if the source_sol_ids, source quantities, and source units are all of the same size
    if ( int( @{$source_sol_id} ) == 0 ) {
        Message("ERROR: Invalid argument: No source solutions defined");
        return 0;
    }
    if ( int( @{$source_quantity} ) == 0 ) {
        Message("ERROR: Invalid argument: No source quantities defined");
        return 0;
    }
    unless ( int( @{$source_sol_id} ) == int( @{$source_quantity} ) ) {
        Message("ERROR: Inconsistent arguments: Solution list is not the same size as quantity list");
        return 0;
    }
    unless ( int( @{$source_sol_id} ) == int( @{$source_unit} ) ) {
        Message("ERROR: Inconsistent arguments: Solution list is not the same size as quantity unit list");
        return 0;
    }

    my $ok;
    my @new_sol_ids;
    my $total_value  = 0;
    my $undetermined = 0;    # set to 1 if any of reagent costing is undetermined
    ### Start Transaction ###
    my $trans = new SDB::Transaction( -dbc => $dbc );
    $trans->start();

    ### STOCK TABLE INSERTS ###
    # get current time
    my $currtime = &date_time();

    # figure out expiry date (the latest solution expiry date)
    unless ($expiry) {
        $expiry = &get_expiry( join ',', @{$source_sol_id} );
    }

    # default bottles to 1 if not set
    $bottles ||= 1;
    my $bottle = 1;

    # sum quantities
    my $quantity = 0;
    my $count    = 0;
    foreach my $qty ( @{$source_quantity} ) {

        # normalize to mL
        my ($this_qty) = normalize_units( $qty, $source_unit->[$count] );
        $quantity += $this_qty;
        $count++;
    }

    # figure out best target unit
    my ( $stock_quantity, $target_unit ) = Get_Best_Units( -amount => $quantity, -units => 'mL' );

    my $localID = 'GSC';
    my ($supplier_id) = $Configs{local_organization_id} || $dbc->Table_find( 'Organization', 'Organization_ID', "where Organization_Name=\"$localID\"" );

    eval {

        # Save info for Stock entry
        #  my $stock_catalog_ID = alDente::Stock::get_standard_solution_id($dbc);
        my $user_id      = $dbc->config('user_id');
        my @Batch_fields = ( 'FK_Stock_Catalog__ID', 'FK_Employee__ID', 'Stock_Number_in_Batch', 'Stock_Received', 'FK_Grp__ID', 'FK_Barcode_Label__ID' );
        my @Batch_values = ( $catalog_id, $user_id, $bottles, $currtime, $group_id, $barcode_label_id );
        my $stock_id = $dbc->Table_append_array( 'Stock', \@Batch_fields, \@Batch_values, -autoquote => 1, -trans => $trans );
        unless ($stock_id) {
            Message("ERROR: Cannot insert Stock information");
            return 0;
        }

        ### SOLUTION AND MIXTURE TABLE INSERTS ###

        # determine quantity per bottle
        my $qty_per_bottle = $quantity / $bottles;

        # define solution fields to be filled in
        my @solution_fields = ( 'Solution_Quantity', 'Solution_Started', 'FK_Rack__ID', 'Solution_Number', 'Solution_Number_in_Batch', 'Quantity_Used', 'Solution_Status', 'FK_Stock__ID', 'Solution_Type', 'Solution_Expiry' );

        # insert a solution for each bottle to be made
        for my $bottle ( 1 .. $bottles ) {

            # divide quantity by the number of bottles
            my @values = ( $stock_quantity, $currtime, $rack_id, $bottle, $bottles, 0, 'Open', $stock_id, $type, $expiry );

            # insert into solution table
            my $new_sol_id = $dbc->Table_append_array( 'Solution', \@solution_fields, \@values, -autoquote => 1, -trans => $trans );
            if ($new_sol_id) {
                push( @new_sol_ids, $new_sol_id );
            }
            else {
                Message("ERROR: Cannot add solution to database");
                return 0;
            }

            # save a mixture entry for each source solution
            my $sol_count = 0;
            foreach my $solution ( @{$source_sol_id} ) {
                my $sol_id  = $solution;
                my $sol_qty = $source_quantity->[$sol_count];
                $sol_count++;

                # figure out best target unit
                ( $sol_qty, my $added_units ) = Get_Best_Units( -amount => $sol_qty, -units => 'mL' );

                if ($sol_id) {
                    my ($sol_info) = $dbc->Table_find(
                        'Stock,Solution,Stock_Catalog',
                        'Stock_Catalog_Name,Stock_Cost,Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units',
                        "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID=Stock_ID and Solution_ID=$sol_id"
                    );
                    my ( $sol_name, $sol_cost, $sol_volume, $units ) = split ',', $sol_info;

                    # if the source solution has no volume set, send a warning and do not calculate value
                    if ( !$sol_volume ) {
                        $sol_volume   = $sol_qty;
                        $undetermined = 1;
                    }
                    elsif ( $sol_cost !~ /\d+/ ) {

                        # Calculate cost of this portion of the solution
                        $undetermined = 1;
                    }
                    else {
                        my $value = $sol_cost * $sol_qty / $sol_volume;
                        $total_value += $value;
                        $value = sprintf "%0.2f", $value;
                    }

                    # append to mixture table
                    my $ok = $dbc->Table_append_array( 'Mixture', [ 'FKUsed_Solution__ID', 'FKMade_Solution__ID', 'Quantity_Used', 'Units_Used' ], [ $sol_id, $new_sol_id, $sol_qty, $added_units ], -autoquote => 1, -trans => $trans );
                    unless ($ok) {
                        Message( "ERROR: Database Error: ", $DBI::errstr );
                        return 0;
                    }

                    # open source olution if it is not already open
                    open_bottle($sol_id);

                    ## update quantities used
                    $ok = $dbc->Table_update_array( 'Solution', ['Quantity_Used'], ["Quantity_Used + $sol_qty"], "where Solution_ID=$sol_id", -trans => $trans );
                }
            }
        }

        ## Update target stock cost if possible (there is a total value and the cost is not undetermined)
        if ( ( $total_value =~ /\d+/ ) && !$undetermined ) {
            $total_value = sprintf "%0.2f", $total_value;
            $dbc->Table_update( 'Stock', 'Stock_Cost', $total_value, "where Stock_ID = $stock_id", -trans => $trans );
        }
        else {
            $total_value = 'Unknown';
        }
    };
    $trans->finish($@);
    if ($print_barcodes) {
        for (@new_sol_ids) {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', $_ );
        }
    }

    return \@new_sol_ids;

}

################################### NEW
sub get_possible_target_solution {
################################### AND NOT VERY GOOD eitehr!!
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $ids  = $args{-ids};
    my @ids  = split ',', $ids;
    require RGTools::RGmath;
    my @result;
    my @matrix;
    my $counter;

    for my $used_sol_id (@ids) {
        ( my $used_cat_id ) = $dbc->Table_find( 'Solution,Stock', 'FK_Stock_Catalog__ID', "WHERE Stock_ID = FK_Stock__ID AND Solution_ID = $used_sol_id" );
        my @all_used_sol_ids = $dbc->Table_find( 'Solution,Stock', 'Solution_ID', "WHERE Stock_ID = FK_Stock__ID AND FK_Stock_Catalog__ID = $used_cat_id", 'distinct' );
        my $all_used_sol_ids = join ',', @all_used_sol_ids;
        my @made_sol_ids = $dbc->Table_find( 'Mixture', 'FKMade_Solution__ID', "WHERE FKUsed_Solution__ID IN ($all_used_sol_ids)", 'distinct' );
        my $made_sol_ids = join ',', @made_sol_ids;
        unless ($made_sol_ids) { $made_sol_ids = 0 }
        my @made_cat_ids = $dbc->Table_find( 'Stock,Solution', 'FK_Stock_Catalog__ID', "WHERE FK_stock__ID = Stock_ID and Solution_ID IN ($made_sol_ids)", 'distinct' );
        $matrix[$counter] = \@made_cat_ids;
        $counter++;
    }

    my $intersection = $matrix[0];

    for my $each_list (@matrix) {
        ( $intersection, my $aonly, my $bonly ) = RGmath::intersection( $each_list, $intersection );
    }

    my @catalog_target_ids = @$intersection if $intersection;
    my $size = @catalog_target_ids;

    if ( $size == 1 ) {
        my $catalog_name = $dbc->get_FK_info( 'FK_Stock_Catalog__ID', $catalog_target_ids[0] );
        return $catalog_name;
    }
    else {
        return;
    }

}

###################################
sub display_solution_options {
###################################
    # Display the possible solution options when more than one solution is scanned in
    #
    # Possible Options:
    # Empty
    # Print Barcodes
    #
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'dbc' );
    my $dbc          = $args{-dbc};
    my $solution_ids = $args{-solution_ids};                  # this parameter is used to pass in multiple solution ids scanned since $self->{id} can only get the first solution id scanned.
    my $output;

    ## Find if the QC is set
    ## Check the QA module

    my $qc_table = HTML_Table->new( -title => "QC Options" );
    my $qc_status = &alDente::QA::check_for_qc( -dbc => $dbc, -ids => $self->{id}, -table => "Solution" );
    my $qc_prompt = &alDente::QA_Views::get_qc_prompt( -dbc => $dbc, -qc_status => $qc_status );
    my $edit_link = alDente::Stock_Views::edit_Records_Link( -ids => $solution_ids, -dbc => $dbc, -object => "Solution" );

    $qc_table->Set_Row( [$qc_prompt] );

    my $solutions;
    if ($solution_ids) {
        $solutions = Cast_List( -list => $solution_ids, -to => 'ArrayRef' );
    }
    else {
        $solutions = Cast_List( -list => $self->{id}, -to => 'ArrayRef' );
    }

    $output .= alDente::Solution_Views::display_Solution_Options( -dbc => $dbc, -solution_ids => $solution_ids );
    $output .= $edit_link;

    $output .= alDente::Form::start_alDente_form( $dbc, 'Display_QC_Options' ); 
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::CGI' );
    $output .= $qc_table->Printout(0);
    $output .= hidden( -name => 'Solutions', -value => $solutions );
    $output .= end_form();

    # &alDente::Solution::make_Solution('',0,$sols,$solution_id);
    return $output;
}

##########################
sub batch_dilute {
##########################
    # Subroutine: Record a batch dilution in the database
##########################
    my %args = &filter_input( \@_ );

    my $sol_ids         = $args{-sol_ids};
    my $water_id        = $args{-water_id};
    my $rack_id         = $args{-rack_id};
    my $type            = $args{-type};
    my $group_id        = $args{-group_id};
    my $label_id        = $args{-label_id};
    my $solution_volume = $args{-solution_volume};
    my $water_volume    = $args{-water_volume};
    my $solution_unit   = $args{-solution_unit};
    my $water_unit      = $args{-water_unit};
    my $expiry          = $args{-expiry};
    my $catalog_info    = $args{-catalog_id};
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $catalog_id = $dbc->get_FK_ID( 'FK_Stock_Catalog__ID', $catalog_info );

    my @names = $dbc->Table_find( 'Stock_Catalog', 'Stock_Catalog_Name', "Where Stock_Catalog_ID IN ($catalog_id)", -distinct => 1 );
    if ( @names > 1 ) { return $dbc->error("Batch Dilution cannot currently be performed on items of different type at the same time") }

    my $name = $names[0];

    foreach my $sol_id ( @{$sol_ids} ) {
        if ( $name =~ /Custom Oligo Plate/ ) {
            my ($primer_plate_name) = $dbc->Table_find( "Primer_Plate", "Primer_Plate_Name", "WHERE FK_Solution__ID=$sol_id" );

            # call remap
            require alDente::Primer;
            my $po = new alDente::Primer( -dbc => $dbc );
            my $solution_id = $po->copy_primer_plate( -solution_id => $sol_id, -new_name => "$primer_plate_name Diluted", -stock_name => $name );

            # add entry in mixture table
            $dbc->Table_append_array( 'Mixture', [ 'FKUsed_Solution__ID', 'FKMade_Solution__ID', 'Quantity_Used', 'Units_Used' ], [ $sol_id,   $solution_id, $solution_volume, $solution_unit ], -autoquote => 1 );
            $dbc->Table_append_array( 'Mixture', [ 'FKUsed_Solution__ID', 'FKMade_Solution__ID', 'Quantity_Used', 'Units_Used' ], [ $water_id, $solution_id, $water_volume,    $water_unit ],    -autoquote => 1 );
        }
        else {
            &combine_solutions(
                -dbc               => $dbc,
                -name              => $name,
                -expiry            => $expiry,
                -rack_id           => $rack_id,
                -type              => $type,
                -group_id          => $group_id,
                -label_id          => $label_id,
                -catalog_id        => $catalog_id,
                -source_sol_ids    => [ $sol_id, $water_id->[0] ],
                -source_quantities => [ $solution_volume, $water_volume ],
                -source_units      => [ $solution_unit, $water_unit ],
                -bottles           => 1,
                -print             => 1
            );
        }
    }
}

##########################
sub mixture_options {
##########################
    my $solution = shift;

    home_solution($solution);

    return 1;
}

####################################
sub get_made_solution_catalog_ids {
####################################
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};
    my $used_sols = $args{-used_solution};                                                                                                       ## this is Solution_ID
    my $condition = "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Stock_Status = 'Active' and Solution_ID IN 
                        ( Select Distinct (FKMade_Solution__ID) from Mixture WHERE FKUsed_Solution__ID IN 
                        ( Select Distinct(Solution_ID) from Solution,Stock WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID IN 
                        ( Select Distinct(FK_Stock_Catalog__ID) from Solution,Stock WHERE FK_Stock__ID = Stock_ID and Solution_ID IN ($used_sols))))";
    my @made_catalog_ids = $dbc->Table_find( 'Stock,Solution,Stock_Catalog', 'FK_Stock_Catalog__ID', $condition, 'distinct' );
    my @info;

    for my $id (@made_catalog_ids) {
        my $info = $dbc->get_FK_info( 'FK_Stock_Catalog__ID', $id );
        push @info, $info;
    }

    #  my $ids_list = join ',', @made_catalog_ids;
    return \@info;

}

#########################
sub save_mixture_info {
#########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $fields              = $args{-stock_fields};
    my $values              = $args{-stock_values};
    my $sol_fields          = $args{-sol_fields};
    my $sol_values          = $args{-sol_values};
    my $containers          = $args{-bottles};
    my $total_quantity      = $args{-total};
    my $quantities_ref      = $args{-quantity};
    my $solutions_ref       = $args{-solutions};
    my $solution_types_ref  = $args{-types};
    my $solution_format_ref = $args{-format};
    my @quantities          = @$quantities_ref if $quantities_ref;
    my @solutions           = @$solutions_ref if $solutions_ref;
    my @types               = @$solution_types_ref if $solution_types_ref;
    my @formats             = @$solution_format_ref if $solution_format_ref;
    my $sol_list            = join ',', @solutions;
    my $sol_formats         = join ',', @formats;
    ( my $cat_id ) = split ',', _return_value( -fields => $fields, -values => $values, -target => 'FK_Stock_Catalog__ID' );

    #    my $name         = _return_value ( -fields => $fields, -values => $values, -target => 'Stock_ Name');
    #    my $sol_type = _return_value( -fields => $sol_fields, -values => $sol_values, -target => 'Solution_Type' );
    my ($sol_type) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Type', "WHERE Stock_Catalog_ID = $cat_id" );
    my $expiry = _return_value( -fields => $sol_fields, -values => $sol_values, -target => 'Solution_Expiry' );

    ( my $grp_id )        = split ',', _return_value( -fields => $fields, -values => $values, -target => 'FK_Grp__ID' );
    ( my $barcode_label ) = split ',', _return_value( -fields => $fields, -values => $values, -target => 'FK_Barcode_Label__ID' );

    foreach (@quantities) {
        if ( $_ !~ /\d/ ) {
            Message("Unknown quantity '$_'");
            Message("Please check the quantities entered");
            return 0;
        }
    }
    unless (@solutions) {
        Message("No solutions scanned in");
        Call_Stack();
        print HTML_Dump \%args;
        return 0;
    }
    my @messages;    ### check for problems, and generate message if something is wrong...
    my @mix;
    foreach my $index ( 1 .. scalar(@solutions) ) {

        my $solution;
        ### find if there are more than one bottles for a given solution
        my @solution_bottles = split ',', get_aldente_id( $dbc, $solutions[ $index - 1 ], 'Solution', -feedback => 1 );
        unless (@solution_bottles) {
            Message("No Solution bottles entered");
            return 0;
        }
        my $bottle_count = scalar(@solution_bottles);
        my $units        = 'mL';                        ### default
        my $qty          = $quantities[ $index - 1 ];
        if ( $qty =~ /([\.\d]*)\s*([a-zA-Z]+)/ ) { $qty = $1; $units = $2; }
        unless ($qty) { Message("Reagent $index excluded from mixture"); next; }    ## skip if quantity entered is zero ##
        $qty = $qty / $bottle_count;
        $qty /= $containers;                                                        ### divide between containers if specified...

        foreach my $sol_bottle (@solution_bottles) {
            ## Validate the solution based on name, format, type

            if ( $sol_bottle =~ /[1-9]/ ) {
                my $valid_id = &get_aldente_id( $dbc, $sol_bottle, 'Solution', -validate => 1 );
                my ($info) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_Type,Stock_Catalog_Name', "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID=Stock_ID and Solution_ID = $sol_bottle" );
                my ( $type, $name ) = split ',', $info;
                my $pattern = $formats[ $index - 1 ];
                $pattern = &RGTools::Conversion::escape_regex_special_chars( -pattern => $pattern, -preserve => '|.*%' );

                unless ( $valid_id =~ /[1-9]/ ) { push( @messages, "$name appears to be invalid (may be thrown out or Expired)" ); }
                unless ( $name && $name ne 'NULL' ) { push( @messages, "Reagent Unnamed ?" ); }
                unless ( ( $formats[ $index - 1 ] !~ /\w/ ) || ( $name =~ /$pattern/i ) )         { push( @messages, "'$name' is not like '$formats[$index-1]' ($sol_bottle)" ); }
                unless ( ( $types[ $index - 1 ] !~ /\w/ )   || ( $type =~ /$types[$index-1]/i ) ) { push( @messages, "Type $types[$index-1]=($type) should be $types[$index-1] (Sol$sol_bottle)" ); }
            }
            else {
                push( @messages, "Reagent $index Missing" );
            }

            push( @mix, "$sol_bottle:$qty $units" );

            if ( $qty && !( $sol_bottle =~ /\S/ ) ) {
                Message("Quantity but no Solution entered");
                return 0;
            }
        }
    }

    if (@messages) {
        my $message = join "<BR>", @messages;
        $dbc->warning($message);
        return 0;
    }

    ####### preparing arguments to save
    $sol_mix = join ',', @mix;    #
    $sol_mix =~ s/sol//ig;        ###### remove prefix from id list...

    return save_mixture(          # -name =>$name,
        -expiry           => $expiry,            #solution
        -location         => 1,                  #rack_id
        -instructions     => '',                 #???
        -type             => $sol_type,          # solution
        -group            => $grp_id,            #stock
        -source           => 'Made in House',    # not relevant anymore
        -barcode_label_id => $barcode_label,     # stock
        -sol_mix          => $sol_mix,
        ## extra ones
        -catalog_id   => $cat_id,                #stock
        -num_in_batch => $containers,            #stock
        -dbc          => $dbc
    );

}

################################        obsolete
sub save_standard_mixture {
################################
    #
    # Save Standard mixture to database
    #
    Call_Stack();
    Message('ERROR: Depricated code new way of doing things');
    return;
    my @solutions     = param('Solution Included');
    my @formats       = param('SFormat');
    my @SolTypes      = param('SolType');
    my @quantities    = param('Std_Quantities');
    my $loc           = param('Location') || param('Location Choice') || param('FK_Rack__ID') || param('FK_Rack__ID Choice') || 1;
    my $name          = param('Stock_Catalog_Name') || param('Stock_Catalog_Name Choice') || param('Admin_Stock_Name') || param('Admin_Stock_Name Choice');
    my $group         = param('FK_Grp__ID');
    my $source        = param('Stock_Source') || 'Order';
    my $barcode_label = param("FK_Barcode_Label__ID") || param("FK_Barcode_Label__ID Choice");
    my $containers    = param('Containers') || param('Bottles') || 1;

    my $sol_list    = join ',', @solutions;
    my $sol_formats = join ',', @formats;

    my $dbc = $Connection;    # will change to args{-dbc} or dbc = shift or self->{dbc}

    foreach (@quantities) {
        if ( $_ !~ /\d/ ) {
            Message("Unknown quantity '$_'");
            Message("Please check the quantities entered");
            return 0;
        }
    }

    unless ($name) {
        Message("Solution Name must be entered");
        return 0;
    }
    if ( !$barcode_label ) {
        Message("Barcode label type must be selected");
        return 0;
    }
    unless (@solutions) {
        Message("No solutions scanned in");
        return 0;
    }

    # get barcode label id
    my ($barcode_label_id) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_ID", "WHERE Label_Descriptive_Name='$barcode_label'" );

    my @mix;
    my @messages;    ### check for problems, and generate message if something is wrong...
    foreach my $index ( 1 .. scalar(@solutions) ) {

        my $solution;
        ### find if there are more than one bottles for a given solution
        my @solution_bottles = split ',', get_aldente_id( $dbc, $solutions[ $index - 1 ], 'Solution', -feedback => 1 );
        unless (@solution_bottles) {
            Message("No Solution bottles entered");
            return 0;
        }

        my $bottle_count = scalar(@solution_bottles);

        my $units = 'mL';                        ### default
        my $qty   = $quantities[ $index - 1 ];
        if ( $qty =~ /([\.\d]*)\s*([a-zA-Z]+)/ ) { $qty = $1; $units = $2; }

        unless ($qty) { Message("Reagent $index excluded from mixture"); next; }    ## skip if quantity entered is zero ##

        $qty = $qty / $bottle_count;
        $qty /= $containers;                                                        ### divide between containers if specified...

        foreach my $sol_bottle (@solution_bottles) {
            ## Validate the solution based on name, format, type
            if ( $sol_bottle =~ /[1-9]/ ) {
                my $valid_id = &get_aldente_id( $dbc, $sol_bottle, 'Solution', -validate => 1 );
                my ($info) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_Type,Stock_Catalog_Name', "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID=Stock_ID and Solution_ID = $sol_bottle" );
                my ( $type, $name ) = split ',', $info;
                unless ( $valid_id =~ /[1-9]/ ) { push( @messages, "$name appears to be invalid (may be thrown out or Expired)" ); }
                unless ( $name && $name ne 'NULL' ) { push( @messages, "Reagent Unnamed ?" ); }
                my $pattern = $formats[ $index - 1 ];
                $pattern = &RGTools::Conversion::escape_regex_special_chars( -pattern => $pattern, -preserve => '|.*%' );
                unless ( ( $formats[ $index - 1 ] !~ /\w/ )  || ( $name =~ /$pattern/i ) )            { push( @messages, "'$name' is not like '$formats[$index-1]' ($sol_bottle)" ); }
                unless ( ( $SolTypes[ $index - 1 ] !~ /\w/ ) || ( $type =~ /$SolTypes[$index-1]/i ) ) { push( @messages, "Type $SolTypes[$index-1]=($type) should be $SolTypes[$index-1] (Sol$sol_bottle)" ); }
            }
            else {
                push( @messages, "Reagent $index Missing" );
            }

            #      print "(mixing $qty$units) of Sol$solution ($name)\n<BR>";
            ( $qty, $units ) = &convert_to_mils( $qty, $units );

            push( @mix, "$sol_bottle:$qty$units" );

            if ( $qty && !( $sol_bottle =~ /\S/ ) ) {
                Message("Quantity but no Solution entered");
                return 0;
            }
        }
    }

    if (@messages) {
        my $message = join "<BR>", @messages;
        $dbc->warning($message);
        return 0;
    }

    $sol_mix = join ',', @mix;    ###### global variable to be passed on...
    $sol_mix =~ s/sol//ig;        ###### remove prefix from id list...

    my $exp = param('Expiry');
    $name ||= param('Stock_Catalog_Name Choice');    # if from pulldown menu...
    my $type = param('Type') || param('Stock_Type Choice') || '';
    my $instructions = param('Instructions') || '';

    return save_mixture(
        -name             => $name,
        -expiry           => $exp,
        -location         => $loc,
        -instructions     => $instructions,
        -type             => $type,
        -group            => $group,
        -source           => $source,
        -barcode_label_id => $barcode_label_id,
        -sol_mix          => $sol_mix,
        -dbc              => $dbc
    );
}

########################
sub apply_solution {
########################
    #
    # Apply solution to plate_set.. (under construction ?)
    #
    my $solution   = shift;
    my $plate_set  = shift;
    my $applied_to = shift;

    print h3("Apply $solution to Plate Set $plate_set (and $applied_to)");
    return;
}

###########################
sub dispense_solution {
###########################
    #
    # Dispense solution into other bottles...
    #
###########################
    my %args = &filter_input( \@_, -args => 'sol_id,bottles,date,total', -mandatory => 'sol_id,bottles' );
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sol_id         = $args{-sol_id};                                                                             ## id of original solution
    my $total_quantity = $args{-total};                                                                              ## total quantity to dispense (otherwise entire volume)
    my $sub_parts      = $args{-bottles};                                                                            ## number of bottles to dispense into...
    my $nowdate        = $args{-date} || &date_time();
    my $decant         = $args{-decant};                                                                             ## decant only (no tracking of target) (eg just dispense amount down drain... )
    my $label          = $args{-barcode} || param('FK_Barcode_Label__ID') || param('FK_Barcode_Label__ID Choice');
    my $empty          = $args{-empty} || param('Transfer Solution');
    my $rack           = $args{-store} || param('FK_Rack__ID') || param('FK_Rack__ID Choice');
    my $expiry         = $args{-expiry};                                                                             ## decant only (no tracking of target) (eg just dispense amount down drain... )
    my $user_id     = $dbc->get_local('user_id');
    my $barcode_id = get_FK_ID( $dbc, 'FK_Barcode_Label__ID', $label );
    my $rack_id    = get_FK_ID( $dbc, 'FK_Rack__ID',          $rack );

    unless ($total_quantity) {
        $total_quantity = join ',', $dbc->Table_find( 'Solution', 'Solution_Quantity', "where Solution_ID = ($sol_id)" );
        unless ($total_quantity) {
            $total_quantity = join ',', $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog.Stock_Size,Stock_Catalog.Stock_Size_Units', "where Stock_ID=FK_Stock__ID and Stock_Catalog_ID = FK_Stock_Catalog__ID and Solution_ID = ($sol_id)" );
        }
    }

    my $total_units;
    if ( $total_quantity =~ /([\d\.eE\-]+)\s+([a-zA-Z]+)/ ) {
        $total_quantity = $1;
        $total_units    = $2;
    }
    else { $total_units = 'mL'; }

    $dbc->message("Dispensed $total_quantity $total_units.");

    ( $total_quantity, $total_units ) = convert_to_mils( $total_quantity, $total_units );

    my $sub_quantity;
    if ($sub_parts) { $sub_quantity = $total_quantity / $sub_parts; }

    my $max_parts = 33;    ## maximum number of solutions it will generate
    my $mixtures  = 0;

    my $updated = 0;
    ### update current bottle ###

    my $update_quantity_used = $updated = $dbc->Table_update_array( 'Solution', [ 'Quantity_Used', 'Solution_Status' ], [ "Quantity_Used+$total_quantity", "'Open'" ], "WHERE Solution_ID=$sol_id" );

    if ($empty) {
        $dbc->Table_update_array( 'Solution', ['Solution_Status'], ['Finished'], "where Solution_ID=$sol_id", -autoquote => 1 );

        #return; empty for transfer so no return, empty solution go through sub empty
    }

    if ($decant) {
        $dbc -> message("Removed $total_quantity ml from Sol$sol_id.");
        return 1;
    }    ## no need to create new bottle(s)...

    ### Add new bottles if applicable ##
    ( my $stock ) = $dbc->Table_find( 'Solution', 'FK_Stock__ID', "where Solution_ID = $sol_id" );

    my $time_stamp_field = 'Solution_Started';

    ## This part is to make sure it point to the right catalog id
    ( my $stock_name )   = $dbc->Table_find( 'Stock_Catalog,Stock,Solution', 'Stock_Catalog_Name', "WHERE Stock_ID= FK_Stock__ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Solution_ID = $sol_id" );
    ( my $stock_cat_id ) = $dbc->Table_find( 'Stock_Catalog,Organization',   'Stock_Catalog_ID',   "WHERE Stock_Source = 'Made in House' AND FK_Organization__ID = Organization_ID and Organization_Name = 'GSC' AND Stock_Catalog_Name = '$stock_name'" );
    unless ($stock_cat_id) {
        ( my $stock_type ) = $dbc->Table_find( 'Solution', 'Solution_Type', "WHERE Solution_ID = $sol_id" );
        require alDente::Tools;
        my $locat_organization_id = alDente::Tools::get_local_organization_id( -dbc => $dbc );
        my @catalog_fields        = qw (Stock_Catalog_Name    Stock_Type    Stock_Source      Stock_Status Stock_Size  Stock_Size_Units  FK_Organization__ID FKVendor_Organization__ID );
        my @catalog_values        = ( $stock_name, $stock_type, 'Made in House', 'Active', 0, 'mL', $locat_organization_id, $locat_organization_id );
        $stock_cat_id = $dbc->Table_append_array( 'Stock_Catalog', \@catalog_fields, \@catalog_values, -autoquote => 1 );
    }

    ( my $new_stock, my $copy_time ) = $dbc->Table_copy( -table => 'Stock', -condition => "where Stock_ID = $stock", -exclude => [ 'Stock_ID', 'Stock_Received' ], -replace => [ undef, $nowdate ] );

    my @change_Stock_fields = ( 'FK_Stock_Catalog__ID', 'FK_Employee__ID', 'Stock_Number_in_Batch', 'Stock_Received', 'FK_Barcode_Label__ID', 'Stock_Lot_Number' );
    my @change_Stock_values = ( $stock_cat_id, $user_id, $sub_parts, $nowdate, $barcode_id, '' );

    unless ($new_stock) { $dbc->error('Error copying stock record'); return 0; }
    my $updated_stock = $dbc->Table_update_array( 'Stock', \@change_Stock_fields, \@change_Stock_values, "where Stock_ID in ($new_stock)", -autoquote => 1 );

    my ($solution_label) = $dbc->Table_find( 'Solution', 'Solution_Label', "where Solution_ID = $sol_id" );
    ( my $solut_type ) = $dbc->Table_find( 'Stock_Catalog', 'Stock_Type', "WHERE Stock_Catalog_ID = $stock_cat_id" );
    my @change_Sol_fields = ( 'Solution_Number_in_Batch', 'Quantity_Used', 'Solution_Status', 'FK_Stock__ID', 'Solution_Quantity', 'Solution_Label', 'Solution_Type' );
    my @change_Sol_values = ( $sub_parts, 0, 'Open', $new_stock, $sub_quantity, $solution_label, $solut_type );
    if ($expiry) {
        push @change_Sol_fields, 'Solution_Expiry';
        push @change_Sol_values, $expiry;
    }

    if ( ( $sub_parts > 0 ) && ( $sub_parts < $max_parts ) ) {
        my $total_added = 0;
        my $adjusted    = 0;
        my @new_ids;
        foreach my $bottle ( 1 .. $sub_parts ) {
            ( my $id, my $copy_time ) = $dbc->Table_copy( 'Solution', "where Solution_ID = $sol_id", -exclude => [ 'Solution_ID', 'Solution_Quantity' ] );

            $adjusted += $dbc->Table_update_array( 'Solution', [ 'Solution_Number', @change_Sol_fields ], [ $bottle, @change_Sol_values ], "where Solution_ID=$id", -autoquote => 1 );

            #	    $adjusted2 += $dbc->Table_update_array('Solution',[@change_S_fields,'Solution_Started'],[0,$bottle,'Open',$nowdate],"where Solution_ID=$id",-autoquote=>1);
            if ( $id =~ /\d+/ ) {
                &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', $id );
                push( @new_ids, $id );
                $total_added++;
                my ($primer_plate_info) = $dbc->Table_find(
                    "Primer_Plate,Stock,Solution,Stock_Catalog",
                    "Primer_Plate_Name,Stock_Catalog_Name",
                    "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND  FK_Stock__ID = Stock_ID and Solution.Solution_ID = Primer_Plate.FK_Solution__ID and Primer_Plate.FK_Solution__ID=$sol_id"
                );

                # call remap
                if ($primer_plate_info) {
                    my ( $primer_plate_name, $sol_name ) = split ',', $primer_plate_info;
                    require alDente::Primer;
                    my $po = new alDente::Primer( -dbc => $dbc );
                    my $solution_id = $po->copy_primer_plate( -solution_id => $sol_id, -new_name => "$primer_plate_name", -stock_catalog_name => $sol_name, -target_solution_id => $id );
                }
                my $ok = $dbc->Table_append_array( 'Mixture', [ 'FKMade_Solution__ID', 'FKUsed_Solution__ID', 'Quantity_Used', 'Mixture_Comments' ], [ $id, $sol_id, $sub_quantity, 'Dispensed' ], -autoquote => 1 );

                if ($ok) { $mixtures++; }
            }
        }
        $dbc -> message("Added $total_added Solutions to database ($adjusted adjusted, $mixtures 'Mixtures' recorded)") if ($testing);
        $dbc -> message( "Created Solution(s): " . join( ',', @new_ids ) );
    }
    else { $dbc -> warning ("Number of dispensions should be between 0 and $max_parts"); return 0; }
    return 1;
}

#######################
sub empty {
#######################
    #
    # record emptying of reagent/solution - and throwing it into garbage
    #
#######################
    my %args = &filter_input( \@_, -args => 'id,nowdate,notes' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id      = $args{-id};
    my $nowdate = $args{-nowdate};
    my $notes   = $args{-notes};

    unless ($id) {
        $dbc->error('No solution(s) specified');
        return 0;
    }
    if ( !$nowdate ) { ($nowdate) = split ' ', &date_time() }
    $notes = $dbc->dbh()->quote(" - $notes");

    if ( $id =~ /Sol(\d+)/i ) { $id = $1; }
    my ($garbage) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_Name = 'Garbage'" );
    my @fields = ( 'Solution_Status', 'Solution_Finished', 'FK_Rack__ID', 'Solution_Notes' );
    my @values = ( "'Finished'", "'$nowdate'", $garbage, "CASE WHEN Solution_Notes IS NULL THEN $notes ELSE CONCAT(Solution_Notes,$notes) END" );

    my $ok = $dbc->Table_update_array( 'Solution', \@fields, \@values, "where Solution_ID in ($id)" );
    if ($ok) { Message("$ok Solution(s) Emptied and thrown away ($id)"); }
    return 1;
}

#######################
sub open_bottle {
#######################
    #
    # record opening of reagent/solution
    #
    my $id    = shift;
    my $nowDT = shift || &date_time();
    my $dbc   = $Connection;             # will change to dbc = shift

    if ( $id =~ /Sol(\d+)/i ) { $id = $1; }
    my @fields = ( 'Solution_Started', 'Solution_Status' );
    my @values = ( "'$nowDT'",         "'Open'" );
    my $ok = $dbc->Table_update_array( 'Solution', \@fields, \@values, "where Solution_ID in ($id) and Solution_Status != 'Open'" );

    if ($ok) { Message("$ok Solution(s) Opened ($id)"); }
    return 1;
}

#######################
sub unopen {
#######################
    #
    # record unopening of reagent/solution
    #
    my $id    = shift;
    my $dbc   = $Connection;
    my $nowDT = &date_time();

    if ( $id =~ /Sol(\d+)/i ) { $id = $1; }
    my @fields = ( 'Solution_Started', 'Solution_Status' );
    my @values = ( "0000-00-00",       "Unopened" );
    my $ok = $dbc->Table_update_array( 'Solution', \@fields, \@values, "where Solution_ID in ($id)", -autoquote => 1 );

    if ($ok) { Message("$ok Solution(s) Reset to Un-Opened ($id)"); }
    return 1;
}

#######################
sub store_solution {
#######################
    my $ids      = shift;
    my $location = shift;
    my $dbc      = $Connection;    #will change to dbc = shift

    $ids = get_aldente_id( $dbc, $ids, 'Solution' );
    ## ok to move 'thrown out' solution if necessary, but Rack must be active ##
    $location = get_aldente_id( $dbc, $location, 'Rack', -validate => 1 );

    unless ( $location =~ /\d+/ ) {
        Message( "Error: ", "$location Unrecognizable location (eg. 'RAC2')" );
    }

    #    if ($ids=~/,/) {#
    #	identify_mixture($ids);
    #    }
    #    else {#
    my $ok = $dbc->Table_update( 'Solution', 'FK_Rack__ID', $location, "where Solution_ID in ($ids)" );
    if ( $ok > 0 ) { Message("Moved $ok reagents/solutions"); }
    else {
        $dbc->warning("No change noted (may already be located as specified)");
    }

    #    }
    return;
}

######################
sub new_primer {
######################
    #print h2("Setting up new Primer");
    #Message("Please specify details for the new Primer.");
    #Message("Make sure direction info is available!");
    my %preset;
    my $dbc = $Connection;    # will change to args{-dbc} or dbc = shift
    $preset{Purity}       = 'Desalted';
    $preset{Coupling_Eff} = 99;
    $preset{Primer_Type}  = 'Standard';

    my %Parameters = _alDente_URL_Parameters();
    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Primer', -target => 'Database', -parameters => \%Parameters );
    my %grey;

    #    $grey{'Chemistry_Code.Terminator:1'} = 'Big Dye';
    #    $grey{'Chemistry_Code.Terminator:2'} = 'ET';
    #    $grey{'Chemistry_Code.Dye'} = 'term';
    $form->configure( 'grey' => \%grey );
    $form->generate();

    return 1;
}

##############################
sub save_original_primer {
##############################
    my $p_name     = param('Primer_Name');
    my $p_sequence = param('Primer_Sequence');
    my $Tm1        = Extract_Values( [ param('Tm1'), 'NULL' ] );
    my $Tm50       = Extract_Values( [ param('Tm50'), 'NULL' ] );
    my $GC         = Extract_Values( [ param('GC_Percent'), 'NULL]' ] );
    my $CE         = Extract_Values( [ param('Coupling_Eff'), 'NULL' ] );
    my $Purity     = Extract_Values( [ param('Purity'), 'NULL' ] );
    my $P_type     = param('Primer_Type');

    my $dbc = $Connection;    #will change to obtain from args or shift

    my @primer_fields = ( 'Primer_Name', 'Primer_Sequence', 'Purity', 'Tm1', 'Tm50', 'GC_Percent', 'Coupling_Eff', 'Primer_Type' );

    #    my @primer_values= ("'$p_name'","'$p_sequence'","'$Purity'",$Tm1,$Tm50,$GC,$CE,"'$P_type'");
    my @primer_values = ( $p_name, $p_sequence, $Purity, $Tm1, $Tm50, $GC, $CE, $P_type );

    my $ok = $dbc->Table_append_array( 'Primer', \@primer_fields, \@primer_values, -autoquote => 1 );
    if   ($ok) { Message("Added $p_name to Primer database"); }
    else       { Message("Error: (Make sure all fields are entered) $DBI::errstr "); return -1; }

    my $Bcc    = param('Bcc');
    my $Ecc    = param('Ecc');
    my $repeat = $dbc->Table_find( 'Branch', 'Branch_Code', "where Branch_Code = '$Bcc' OR Branch_Code = '$Ecc'" );
    if ( $repeat > 0 ) {
        Message( "Error:  One of these chemistry codes is being used", "See administrator to assign valid codes before trying to Run" );
        return 0;
    }
    elsif ( $P_type =~ /Standard/ ) {
        my ($p_id)  = $dbc->Table_find( 'Primer',       'Primer_ID',       "WHERE Primer_Name = '$p_name'" );
        my ($class) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = 'Primer'" );

        my $ok1 = $dbc->Table_append_array( 'Branch', [ 'Branch_Code', 'FK_Object_Class__ID', 'Object_ID' ], [ $Bcc, $class, $p_id ], -autoquote => 1 );

        #	my $ok1 =$dbc->Table_append_array('Chemistry_Code',['Branch_Code','FK_Object_Class__ID','Object_ID'],[$Bcc,$p_name,'Big Dye','term'],-autoquote=>1);
        if ( $ok1 == 1 ) {
            my $chem_link = &Link_To( $dbc->config('homelink'), ' (Check Info)', "&Info=1&Table=Branch&Field=Branch_Code&Like=$Bcc", 'blue', ['newwin'] );
            print "<B>Created New Branch:  $Bcc </B>$chem_link<BR>";
        }

        my $ok2 = $dbc->Table_append_array( 'Branch', [ 'Branch_Code', 'FK_Object_Class__ID', 'Object_ID' ], [ $Ecc, $class, $p_id ], -autoquote => 1 );

        #	my $ok2 =$dbc->Table_append_array('Chemistry_Code',['Branch_Code','FK_Primer__Name','Terminator','Dye'],[$Ecc,$p_name,'ET','term'],-autoquote=>1);
        if ( $ok2 == 1 ) {
            my $chem_link = &Link_To( $dbc->config('homelink'), ' (Check Info)', "&Info=1&Table=Branch&Field=Branch_Code&Like=$Ecc", 'blue', ['newwin'] );
            print "Created New Chemistry Branch:  $Ecc </B>$chem_link<BR>";
        }
    }

    return 1;
}

#######################
sub update_primer {
#######################
    #    my $dbc = shift;
    my $dbc     = $Connection;    # will change to shift
    my $sol_ids = shift;

    my @added = ();
    foreach my $solution ( split ',', $sol_ids ) {
        push( @added, $dbc->Table_append_array( 'Primer_Info', ['FK_Solution__ID'], [$solution] ) );
    }
    print &Views::Heading("Please Update Special info for Primers");
    &SDB::DB_Form_Viewer::edit_records( $dbc, 'Primer_Info', 'FK_Solution__ID', $sol_ids, undef, 'hide' );    ### allow editing of Primer Info.. ###
    return 1;
}

#############################
sub more_solution_info {
#############################
    my $self = shift;
    my $id   = shift;
    my $name = shift;
    my $dbc  = $Connection;                                                                                   # will change to shift
    my $solution_info;
    print &Views::Heading("Info on Solution $id: $name");
    if ( $id =~ /Pla(\d+)/ ) { $id = $1; }

    my $catalog_ID = join ',', $dbc->Table_find( 'Solution,Stock', 'FK_Stock_Catalog__ID', "where Stock_ID=FK_Stock__ID and Solution_ID = ($id)" );

    # my $standard_ID = alDente::Stock::get_standard_solution_id($dbc);       ######  the standard ID for made in house solutions (which means size will be stored in solution table)

    $solution_info = join ',',
        $dbc->Table_find(
        'Solution,Employee,Rack,Stock,Stock_Catalog',
        'Stock_Catalog_Name,Solution_Type,Stock_Description,Solution_Started,Employee_Name,Stock_Catalog.Stock_Size,Solution_Used,Solution_Expiry,Solution_Number,Solution_Status,Stock_Catalog.Stock_Size_Units',
        " where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and Stock.FK_Employee__ID=Employee_ID and FK_Rack__ID = Rack_ID and Solution_ID = $id"
        );

    ( my $sname, my $stype, my $sd, my $sm, my $smb, my $sq, my $squ, my $sexp, my $sbottle, my $status, my $su ) = split ',', $solution_info;

    my $colour  = "cyan";
    my $colour2 = "khaki";

    my $Solution = HTML_Table->new();

    #    $Solution->Set_Alignment('right',1);
    $Solution->Set_Title("$sname<BR>$stype<BR>$sd");
    $Solution->Set_Column( [ 'Started/Created:', 'By:', 'Quantity', 'Used:', 'Expiry:', 'Bottle:' ] );
    $Solution->Set_Column( [ $sm, $smb, $sq, "$squ $su", $sexp, $sbottle ] );
    $Solution->Printout();

    print $self->solution_footer();
    return 1;
}

#####################
sub order_check {
#####################
    #
    # Set up Stock supply check variables - to see if they need to be re-ordered...
    #
#####################
    my $catalog = shift;
    my $dbc     = $Connection;    # will change to shift

    Message( "Checking In Stock Supply", "Cat: $catalog" );

    my @name = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and Stock_Catalog.Stock_Catalog_Number like \"$catalog\"", 'Distinct' );

    if ( $#name > 0 ) { $dbc->warning("These Items ($#name) have the same catalog number ! (Normalize names if necessary)"); }
    my $all_names = join ',', @name;

    print h2("$all_names");

    if ($catalog) {
        my $minimum = join ',', $dbc->Table_find( 'Order_Notice', 'Minimum_Units', "where Catalog_Number like \"$catalog\"" );

        my @found = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Solution_Status,count(*)', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID AND Stock_Catalog_Number like \"$catalog\" group by Solution_Status" );

        ##### first print out current Stock supply

        my $Order = HTML_Table->new();
        $Order->Set_Title("<B>Current $name[0] in stock</B>");
        $Order->Set_Headers( [ 'Status', "Number of Units (Min $minimum)" ], );
        foreach my $info (@found) {
            ( my $status, my $count ) = split ',', $info;
            my $colour = $Settings{'DONE_COLOUR'};
            if    ( $status =~ /Unopened/i ) { $colour = 'lightgreenbw'; }
            elsif ( $status =~ /Finished/i ) { $colour = 'lightgreybw'; }
            elsif ( $status =~ /Open/i )     { $colour = 'mediumyellowbw'; }
            $Order->Set_Row( [ $status, $count ], $colour );
        }
        $Order->Printout();
        print &vspace();

        ####### if Order Notice doesn't exist, allow input...
        my $target_list;    ##  = 'rguin,dsmailus,smesser,jstott,cjang';

        if ( ( $minimum eq 'NULL' ) || !$minimum ) {
            my @user_list = get_FK_info( $dbc, 'FK_Employee__ID', -list => 1 );

            #	    (my $notify) = array_containing(\@user_list,$user);
            ( my $notify ) = array_containing( \@user_list, 'Ice Man' );

            print alDente::Form::start_alDente_form( $dbc );
            print hidden( -name => 'Catalog_Number', -value => $catalog );

            my $Order = HTML_Table->new();
            $Order->Set_Title("<B>Notification Details for Low Supply</B>");
            $Order->Set_Row( [ 'Minimum Units<BR>(after which send notification)',                          textfield( -name => 'Minimum_Units',    -size => 5,  -default => 2,                            -force => 1 ) ] );
            $Order->Set_Row( [ 'Notify<BR>(when stock falls below Minimum Units)',                          textfield( -name => 'Target_List',      -size => 20, -default => $target_list,                 -force => 1 ) ] );
            $Order->Set_Row( [ 'Message to Send<Br>(enter text message to send)',                           textfield( -name => 'Order_Text',       -size => 40, -default => "Check Supply of $name[0] !", -force => 1 ) ] );
            $Order->Set_Row( [ 'Repeat Frequency<BR>(days before a notice is re-sent if supply still low)', textfield( -name => 'Notice_Frequency', -size => 5,  -default => 7,                            -force => 1 ) ] );
            $Order->Printout();

            print submit( -name => 'Cancel', -value => 'Do Not Notify', -class => "Std" ), " ", hidden( -name => 'TableName', -value => 'Order_Notice', -force => 1 ), hidden( -name => 'Last Page', -value => $last_page ),
                submit( -name => 'Update Table', -force => 1, -value => "Update Order_Notice Table", -style => "background-color:red" ), '<BR>', "\n</FORM>\n";
            return 0;

        }
    }

    print alDente::Form::start_alDente_form( $dbc );
    print submit( -name => 'Cancel', -value => 'Return to Home Page', -class => "Std" ), "</FORM>\n";

    return 1;
}

################################
sub get_original_reagents {
################################
    my %args = &filter_input( \@_, -args => 'dbc,solution' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $solution   = $args{-solution};
    my $type       = $args{-type};
    my $class      = $args{-class};
    my $stock_type = $args{-stock_type};
    my $order      = $args{-order};
    my $format     = $args{'-format'};
    my $condition  = $args{-condition};
    my $unique     = $args{-unique};                                                                  ## exclude duplicate solutions (based upon names)
    my $debug      = $args{-debug};

    my $order = 'Order by Made.Solution_Started desc';
    my $group;

    if ($unique) { $group = "Group by Stock_Catalog_Name" }

    my @conditions;

    my $tables = 'Stock_Catalog,Stock,Solution as Made';
    if ($class) {
        ## dynamically link to class (eg Primer or Enzyme)
        $tables .= ",$class";
        push @conditions, "Stock_Catalog_Name=${class}_Name";
    }
    if ($type)       { push( @conditions, "Made.Solution_Type in ('$type')" ); }
    if ($stock_type) { push( @conditions, "Stock_Catalog.Stock_Type in ('$stock_type')" ); }
    if ($order) { $order = "Order by $order" unless ( $order =~ /order by/i ); }
    if ($format) {
        my @options;
        foreach my $format_option ( split '\|', $format ) {
            my $this_format_option = convert_to_regexp($format_option);
            push @options, "Stock_Catalog_Name like \"$this_format_option\"";
        }
        my $format_options = join ' OR ', @options;
        push( @conditions, "($format_options)" );
    }

    if ($condition) { push( @conditions, $condition ); }

    unless ( $solution =~ /^[\d,]+$/ ) { $solution = &get_aldente_id( $dbc, $solution, 'Solution' ); }    ### convert in case they are a scanned list...
    my @all_reagents = ( split ',', $solution );                                                          ### include original list sent...
    foreach my $solution ( split ',', $solution ) {
        my $used_list = $solution;

        while ( $used_list =~ /[1-9]/ ) {
            my @used = $dbc->Table_find(
                "$tables,Mixture,Solution as Used", 'FKUsed_Solution__ID'
                , "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FKMade_Solution__ID=Made.Solution_ID AND FKUsed_Solution__ID=Used.Solution_ID AND Used.FK_Stock__ID=Stock_ID AND FKMade_Solution__ID in ($used_list) $group $order"
                ,
                -distinct => 1,
                -debug    => $debug
            );

            push( @all_reagents, @used );
            $used_list = join ',', @used;
        }
    }

    @all_reagents = adjust_list( \@all_reagents, 'unique', 'maintain order' );

    #    ######### For extracting Primers for example from a given list... ###########
    #
    # first look at primary solutions entered (from specified list)...
    #   next get the ones used to form mixtures in reverse creation date...
    #   (return list in order (by default first returned value is most direct/recent
    #
    if ( @all_reagents && @conditions ) {
        my $condition = "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID";
        my $extra_conditions = join ' AND ', @conditions;
        $condition .= " AND $extra_conditions";

        my $inclusive_list = join ',', @all_reagents;    ### get in order
        @all_reagents = $dbc->Table_find( $tables, 'Made.Solution_ID', "$condition AND Made.Solution_ID in ($inclusive_list) $order ", 'Distinct' );
    }
    else { }

    return @all_reagents;
}

#########################
sub get_downstream_solutions {
#########################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids = shift;

    my @all_reagents = ( split ',', $ids );    ### include original list sent...
    foreach my $solution ( split ',', $ids ) {
        my $used_list = $solution;

        while ( $used_list =~ /[1-9]/ ) {
            my @used = $dbc->Table_find( 'Mixture,Solution', 'FKMade_Solution__ID', "where FKUsed_Solution__ID=Solution_ID and FKUsed_Solution__ID in ($used_list)", 'Distinct' );
            push( @all_reagents, @used );
            $used_list = join ',', @used;
        }
    }

    @all_reagents = adjust_list( \@all_reagents, 'unique', 'maintain order' );
    return @all_reagents;
}

##############################################################################################
sub show_applications {
####################
    #
    # generate display showing details of reagent / solution applications involving given ids
    # <snip>
    #  Example:
    #   ## show all applications from protocol #5 in the last 30 days (include reagents used to make applied solutions) ##
    #   print &show_applications($dbc,-protocol_id=>5,-include_reagents=>1,-since=>30);
    # </snip>
    #
    # Return: scalar view of applied reagents in HTML table
####################

    my %args = &filter_input( \@_, -args => 'dbc,solution_id,protocol_id,include_reagents', mandatory => 'dbc' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database handle
    my $sol_id      = $args{-solution_id};                                                              ## list of solutions to check for use
    my $protocol_id = $args{-protocol_id};                                                              ## optional protocol(s) to include applications from
    my $long        = $args{-include_reagents} || 0;                                                    ## include reagents of solutions if applicable
    my $since       = $args{-since};
    my $title       = $args{-title} || 'Reagent Applications';

    $sol_id = &get_aldente_id( $dbc, $sol_id, 'Solution' ) if $sol_id;
    $protocol_id = &get_FK_ID( $dbc, 'FK_Lab_Protocol__ID', $protocol_id ) if $protocol_id;

    my $condition = '';
    if ($protocol_id) {
        my $protocol_list = &Cast_List( -list => $protocol_id, -to => 'string' );
        $condition .= " AND FK_Lab_Protocol__ID in ($protocol_list)";
    }
    if ($sol_id) {
        my $sol_list = &Cast_List( -list => $sol_id, -to => 'string' );
        if ($long) {
            ## if we want to show original reagents as well... ##
            my $long_list = join ',', get_downstream_solutions( $dbc, $sol_list );
            $sol_list = $long_list;
        }
        $condition .= " AND Solution_ID in ($sol_list)";
    }
    if ($since) {
        my ($day1) = split ' ', &date_time( "-$since" . 'd' );    ## $since days ago...
        $condition .= " AND Prep_DateTime >= '$day1'";
    }
    unless ( $protocol_id || $sol_id ) {
        $dbc->warning("You must specify a list of reagents or a list of protocols. ($sol_id; $protocol_id;");
        return;
    }

    $dbc->message("(extra condition: $condition)");
    my $view = &Table_retrieve_display(
        $dbc,
        'Prep,Plate_Prep,Solution,Stock,Lab_Protocol',
        [ 'Count(*) as Count', 'FK_Prep__ID as Step', 'FK_Plate__ID as Plate', 'FK_Plate_Set__Number as Plate_Set', 'Solution_ID as Applied', 'Prep_DateTime as Timestamp', 'Prep_Name', 'Lab_Protocol_Name' ],
        "WHERE Plate_Prep.FK_Solution__ID=Solution_ID AND FK_Stock__ID=Stock_ID AND FK_Prep__ID=Prep_ID AND FK_Lab_Protocol__ID=Lab_Protocol_ID $condition Group by FK_Prep__ID,Plate ORDER BY Prep_DateTime",
        -title                      => $title,
        -return_html                => 1,
        -print                      => 0,
        -alt_message                => "(No applications used as specified)",
        -selectable_field           => 'Plate',
        -selectable_field_parameter => 'Plate_ID'
    );

    return $view;
}

################################
sub get_reagent_amounts {
################################
    my $id       = shift;
    my $quantity = shift;
    my $dbc      = $Connection;    #will change to shift

    my %Used = {};

    my $original;
    my $catalog_ID = join ',', $dbc->Table_find( 'Solution,Stock', 'FK_Stock_Catalog__ID', "where Stock_ID=FK_Stock__ID and Solution_ID = ($id)" );

    #   my $standard_ID = alDente::Stock::get_standard_solution_id($dbc);       ######  the standard ID for made in house solutions (which means size will be stored in solution table)
    ($original) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog.Stock_Size', "where FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Stock__ID=Stock_ID and Solution_ID = $id" );

    unless ( $original > 0 ) { return; }

    my $percentage = $quantity / $original;

    $id = &get_aldente_id( $dbc, $id, 'Solution' );    ### convert in case they are a scanned list...

    my $used_list = $id;

    $Used{Percentage}->{$id} = $percentage;            ### constant ?
    $Used{Reagent}->{$id}    = 1;                      ### set as Reagent to begin

    #
    #  May need to adjust if the same reagent is used more than once in the history of a solution ??? ##
    #

    my $index = 0;
    while ( $used_list =~ /\d/ ) {
        my @used;
        my @used_list = $dbc->Table_find(
            'Mixture,Solution,Stock,Stock_Catalog',
            'Stock_Catalog_Name,FKMade_Solution__ID,FKUsed_Solution__ID,Mixture.Quantity_Used,Units_Used,Stock_Catalog.Stock_Size_Units,Stock_Catalog.Stock_Size',
            "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FKUsed_Solution__ID=Solution_ID and FK_Stock__ID=Stock_ID AND FKMade_Solution__ID in ($used_list)", 'Distinct'
        );
        foreach my $used_reagent (@used_list) {
            my ( $name, $made, $id, $qty, $qty_units, $units, $total ) = split ',', $used_reagent;
            unless ( $id =~ /[1-9]/ ) { next; }    ### not valid
            push( @used, $id );
            my ( $new_total, undef, $errmsg ) = convert_units( $total, $units, $qty_units, 'quiet' );    ## convert units to same units indicated in quantity used ##
            my ( $used_qty, $used_units ) = convert_to_mils( $Used{Percentage}->{$made} * $qty, $units, undef, 'quiet' );
            $Used{Quantity}->{$id} += $used_qty if ( $used_units eq 'ml' );
            $Used{Units}->{$id} = 'ml';
            if ( $new_total && !$errmsg ) {
                $Used{Percentage}->{$id} = $used_qty / $total;
            }
            else {
                Message("No Size indicated for Sol $id (ignoring).");
                $Used{Percentage}->{$id} = 0;
            }

            #	    unless ($units=~/g/) {$total += $qty;}
            $Used{Type}->{$id}   = 'Reagent';     ### set as Reagent
            $Used{Type}->{$made} = 'Solution';    ### set as Solution
            $Used{Name}->{$id}   = $name;         ### set Name
        }
        $used_list = join ',', @used;
    }

    return %Used;
}

#############################
sub expiring_solutions {
#############################
    #
    # Display solutions expired in past month... and over next month.
    #
    # (Provides hyperlink via Lot number to Solution database)
    #
#############################
    my %args = &filter_input( \@_, -args => 'name,days,groups' );

    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $string = $args{-name};
    my $days   = $args{-days};
    my $grp    = $args{-groups};

    #    my $days = Extract_Values([shift,param('Since'),'30']);

    my $date = "+" . $days . 'd';

    my $until = &date_time($date);
    my $since = &date_time('-30d');
    my $today = &date_time();

    my $extra_condition = '';
    my $regexp          = convert_to_regexp($string);
    if ( $string =~ /\S/ ) { $extra_condition = "and Stock_Catalog_Name like '$regexp'"; }

    ################## Expired Last Month #############################
    my $grp_condition = '';
    if ($grp) {
        $grp_condition .= " AND Stock.FK_Grp__ID IN ($grp)";
    }

    my %EXP = &Table_retrieve(
        $dbc,
        'Solution,Stock,Stock_Catalog',
        [ "Stock_Catalog_Name as Name", "Stock_Lot_Number as Lot", "Solution_Expiry as Expires", "count(*) as Bottles", 'Solution_Status as Status' ],
        "where FK_Stock__ID=Stock_ID"
            . " And FK_Stock_Catalog__ID = Stock_Catalog_ID "
            . " and Solution_Expiry not like '0%'"
            . " and Solution_Expiry <= '$today' $grp_condition"
            . " and FK_Stock_Catalog__ID = Stock_Catalog_ID"
            . " AND (Solution_Expiry >= '$since' OR Solution_Status='Open') $extra_condition"
            . " group by Stock_Catalog_Name,Stock_Lot_Number,Solution_Expiry"
            . " order by Solution_Expiry",
        undef
    );

    my $Expiring = HTML_Table->new();
    $Expiring->Set_Title("<B>Solutions/Reagents Recently Expired (in past month)</B>");
    $Expiring->Set_Headers( [ 'Name', 'In House Name', 'Lot', 'Units', 'Expiry', 'Status' ] );

    my $index = 0;
    while ( defined $EXP{Name}[$index] ) {
        my $name = $EXP{Name}[$index] || '-';
        my $lot  = $EXP{Lot}[$index]  || '-';
        my $expires = $EXP{Expires}[$index];
        my $count   = $EXP{Bottles}[$index] || 0;
        my $status  = $EXP{Status}[$index] || 0;

        $Expiring->Set_Row( [ $name, &Href( $dbc->homelink(), $lot, 'Lot' ), $count, $expires, $status ] );

        $index++;
    }

    $Expiring->Printout();

    ################## Expiring in Next x Days #############################
    print "<P>";
    my %EXP2 = &Table_retrieve(
        $dbc,
        'Solution,Stock,Stock_Catalog',
        [ "Stock_Catalog_Name as Name", "Stock_Lot_Number as Lot", "Solution_Expiry as Expires", "count(*) as Bottles", 'Solution_Status as Status' ],
        "where FK_Stock__ID=Stock_ID"
            . " and FK_Stock_Catalog__ID = Stock_Catalog_ID"
            . " and Solution_Expiry <= '$until'"
            . " and Solution_Expiry >= '$today' $extra_condition $grp_condition"
            . " group by Stock_Catalog_Name,Stock_Lot_Number,Solution_Expiry"
            . " order by Solution_Expiry",
        undef,
    );

    my $Expiring2 = HTML_Table->new();
    $Expiring2->Set_Title("<B>Solutions/Reagents Expiring in the Next $days Days</B>");
    $Expiring2->Set_Headers( [ 'Name', 'In House Name', 'Lot', 'Units', 'Expiry', 'Status' ] );

    $index = 0;
    while ( defined $EXP2{Name}[$index] ) {
        my $name = $EXP2{Name}[$index] || '-';
        my $lot  = $EXP2{Lot}[$index]  || '-';
        my $expires = $EXP2{Expires}[$index];
        my $count   = $EXP2{Bottles}[$index] || 0;
        my $status  = $EXP2{Status}[$index] || 0;

        $Expiring2->Set_Row( [ $name, &Href( $dbc->homelink(), $lot, 'Lot' ), $count, $expires, $status ] );

        $index++;
    }

    $Expiring2->Printout();

    return 1;
}

####################
sub get_expiry {
####################
    #
    # Get the next expiring solution.
    # Generate warning if before today...
    #
    #
    my $sols = shift;
    my $dbc  = $Connection;    #will change to shift
    ( my $today ) = split ' ', &date_time();

    my $full_today = $today;
    $today =~ s/[:\-\s]//g;    ### convert to integer..

    ( my $expiry ) = $dbc->Table_find( 'Solution', 'min(Solution_Expiry)', "where Solution_ID in ($sols) and Solution_Expiry not like '0%'" );

    my $intExpiry   = $expiry;
    my $full_expiry = $expiry;
    $intExpiry =~ s/[:\-\s]//g;    ### convert to integer..

    if ( $intExpiry =~ /[1-9]/ && ( $intExpiry < $today ) ) {
        $dbc->warning("Expired Reagent Used (Expired: $full_expiry; Today: $full_today)!");
        return $expiry;
    }
    return $expiry;
}

####################
sub set_expiry {
####################
    #
    # Set the expiry date
    #
    my %args = &filter_input( \@_, -args => 'id,expiry_date' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id          = $args{-id};
    my $expiry_date = $args{-expiry_date};

    unless ($id) {
        $dbc->error('No solution(s) specified');
        return 0;
    }

    if ( $id =~ /Sol(\d+)/i ) { $id = $1; }
    my @fields = ('Solution_Expiry');
    my @values = ("'$expiry_date'");
    my $ok     = $dbc->Table_update_array( 'Solution', \@fields, \@values, "where Solution_ID in ($id)" );
    if ($ok) { Message("$ok Solution(s) Set Expiry Date to $expiry_date ($id)"); }
    return 1;
}

################
sub activate_Solution {
################
    #
    # Export containers listed
    #
    my %args = &filter_input( \@_, -args => 'dbc,ids', -mandatory => 'ids,dbc' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids     = $args{-ids};
    my $confirm = $args{-confirm};
    my $rack_id = $args{-rack_id};

    $ids = Cast_List( -list => $ids, -to => 'string' );

    if ($confirm) {
        my $ok = $dbc->Table_update_array( 'Solution', [ 'Solution_Status', 'FK_Rack__ID' ], [ 'Open', 1 ], "where Solution_ID in ($ids)", -autoquote => 1 );
        Message("Re-open $ok solutions.");
        if ($rack_id) {
            require alDente::Rack;
            &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Solution', -ids => $ids, -rack => $rack_id, -confirmed => 1 );
        }
    }
    else {
        $dbc->Table_retrieve_display( 'Solution,Rack', [ 'Solution_ID', 'FK_Stock__ID as Stock', 'Rack_Alias as Current_Location', 'Solution_Status as Current_Status' ], "WHERE FK_Rack__ID=Rack_ID AND Solution_ID in ($ids)" );
        $page .= alDente::Form::start_alDente_form( $dbc );
        $page .= hidden( -name => 'Solution_ID', -value => $ids );
        $page .= hidden( -name => 'Rack_ID', -value => $rack_id, -force => 1 );
        $page .= submit( -name => 'Confirm Re-Open', -value => 'Re-Open Now', -class => "Action" );
        $page .= end_form();

        return $page;

        #        &main::leave();
    }

    return;
}

#####################
sub show_primer_info {
#####################
    my $solution_id = shift;
    my $dbc         = $Connection;    #will change to shift

    unless ( $solution_id =~ /[1-9]/ ) { return 0; }

    my $info_list = join ',', $dbc->Table_find( 'Solution', 'FK_Solution_Info__ID', "where Solution_ID in ($solution_id)" );

    if ( $info_list =~ /[1-9]/ ) {
        print "<P><B>Primer Info: </B>";
        &Table_retrieve_display( $dbc, 'Solution_Info', [ 'ODs', 'nMoles', 'micrograms' ], "where Solution_Info_ID in ($info_list)", -alt_message => 'No Standard Primer Information Found' );
        print &Link_To( $dbc->config('homelink'), " (Edit)", "&Edit+Table=Solution_Info&Field=Solution_Info_ID&Like=$info_list", 'red', ['newwin'] );
        return 1;
    }
    else {
        print "<B>No Primer Info</B> ";
        my $new_info_id = $dbc->Table_append_array( 'Solution_Info', [ 'ODs', 'nMoles', 'micrograms' ], [ 0, 0, 0 ] );
        if ($new_info_id) {
            $dbc->Table_update_array( 'Solution', ['FK_Solution_Info__ID'], [$new_info_id], "where Solution_ID in ($solution_id)" );
            print &Link_To( $dbc->config('homelink'), 'Add Info', "&Edit+Table=Solution_Info&Field=Solution_Info_ID&Like=$new_info_id", 'red', ['newwin'] );
            return 1;
        }
        else { print 'could not create Solution_Info record'; }
    }
}

#############################
sub get_new_solution_info {
#############################

}

return 1;

##############################
# private_methods            #
##############################
##########################
sub _return_value {
##########################
    my %args         = &filter_input( \@_ );
    my $fields_ref   = $args{-fields};
    my $values_ref   = $args{ -values };
    my $target       = $args{-target};
    my $index_return = $args{-index_return};

    my $value;
    my @fields  = @$fields_ref;
    my @values  = @$values_ref;
    my $counter = 0;

    foreach my $field_name (@fields) {
        if ( $field_name eq $target ) {
            if ($index_return) {
                return $counter;
            }
            else {
                return $values[$counter];
            }
        }
        $counter++;
    }
    return;
}
##########################

##############################
# private_functions          #
##############################
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

$Id: Solution.pm,v 1.26 2004/12/03 18:56:14 jsantos Exp $ (Release: $Name:  $)

=cut

1;
