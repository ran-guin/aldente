################################################################################
#
# Box.pm
#
# This module handle Box Items.
#
################################################################################
################################################################################
# $Id: Box.pm,v 1.22 2004/11/11 00:53:55 echuah Exp $
################################################################################
# CVS Revision: $Revision: 1.22 $
#     CVS Date: $Date: 2004/11/11 00:53:55 $
################################################################################
package alDente::Box;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Box.pm - This module handle Box Items.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handle Box Items.<BR>

=cut

##############################
# superclasses               #
##############################
@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use strict;

use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Benchmark;
use Carp;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use alDente::Form;
use alDente::Tools;
use alDente::Barcoding;
use alDente::Box_Views;
use SDB::DB_Object;
##############################
# global_vars                #
##############################

our ( $scanner_mode, $testing, $development, $homefile );
our ( $style,        $dbase,   $barcode,     $user );
our ( $plate_id,  $current_plates, $plate_set );
our ( $equipment, $equipment_id,   $solution_id );
our ( $last_page, $errmsg );
our ( @users, @plate_sizes, @plate_info, @plate_formats );
our ( @suppliers, @e_suppliers, @locations, @rack_info, @libraries );
our ( $nowday, $nowtime, $nowDT );
our ( $size, $quadrant, $rack, $format, $button_style );
our ( $MenuSearch, $br );
our ($Connection);
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this = shift;

    my %args     = @_;
    my $id       = $args{-id};
    my $stock_id = $args{-stock_id};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $retrieve = $args{-retrieve};                                                                 ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => [ 'Box', 'Stock', 'Stock_Catalog' ] );
    my $class = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Box', -value => $id );
        $self->load_Object();

        #	($self->{name}) = $Connection->Table_find('Box,Stock','Stock _Name',"WHERE FK_Stock__ID=Stock_ID AND Box_ID = $id");
    }
    elsif ($stock_id) {
        $self->{stock_id} = $stock_id;
        $self->primary_value( -table => 'Stock', -value => $stock_id );
        $self->load_Object();
    }

    $self->{dbc} = $dbc;

    $self->{records} = 0;    ## number of records currently loaded

    return $self;
}

##################
sub home_page {
##################
    my $self = shift;
    my $dbc  = $self->{dbc};

    return alDente::Box_Views->home_page( -dbc => $dbc, -Box => $self );
}

################
sub open_box {
################

    my %args = &filter_input( \@_, -args => 'box_id,type', -mandatory => 'box_id' );
    if ( $args{ERRORS} ) { Message( $args{ERRORS} ); return 0; }
    my $box_id = $args{-box_id} || 0;
    my $type   = $args{-type};
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $now = &date_time();

    my $opened = join ',', $dbc->Table_find( 'Box', 'Box_ID', "where Box_ID IN ($box_id)" );
    if ( $opened =~ /[1-9]/ ) { &Message("Box(es) $box_id already opened ($opened)"); }

    my $ok = $dbc->Table_update_array( 'Box', [ 'Box_Opened', 'Box_Status' ], [ $now, 'Open' ], "where Box_ID IN ($box_id) AND Box_Opened IS NULL", -autoquote => 1 );
    if ($ok) {
        &Message("Opened $ok Box(es)");
    }

    #    else {&Message("Nothing Updated (could already be open ?)");}

    return 1;
}

#########################
# throws away a box
#########################
sub throw_away {
#########################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $box_ids   = $args{-ids};
    my $confirmed = $args{-confirmed};
    my $page;
    my $dbc = $self->{dbc};

    my @boxes = split ',', $box_ids;

    if ($confirmed) {
        ### Garbage Location
        my ($trash) = $dbc->Table_find( "Rack", "Rack_ID", "WHERE Rack_Name='Garbage'" );

        ### Move to garbage
        my $ok = $dbc->Table_update_array( 'Box', [ 'FK_Rack__ID', 'Box_Status' ], [ $trash, 'Inactive' ], "where Box_ID in ($box_ids)", -autoquote => 1 );

        Message("Thrown away box id/s ($box_ids)");

        return 0;
    }
    else {
        my $box_count = int(@boxes);
        Message("Warning: Throwing away $box_count box(es)");

        $page .= alDente::Form::start_alDente_form( $dbc, 'ThrowAwayBoxes' );
        $page .= submit( -name => 'rm', -value => "Throw Away Box", -class => 'Action' );
        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Box_App', -force => 1 );
        for my $box (@boxes) {
            $page .= hidden( -name => "Box_ID", -value => $box );
        }
        $page .= hidden( -name => 'Confirmed', -value => 1, -force => 1 );
        $page .= end_form();
        return $page;
    }
}

#############################
sub expiring_boxes {
#############################
    #
    # Display boxes expired in past month... and over next month.
    #
    # (Provides hyperlink via Lot number to Box database)
    #
    my %args   = &filter_input( \@_, -args => 'name,days,groups' );
    my $string = $args{-name};
    my $days   = $args{-days};
    my $grp    = $args{-groups};
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

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
    my %EXP = $dbc->Table_retrieve(
        'Box,Stock,Stock_Catalog',
        [ "Stock_Catalog_Name as Name", "Stock_Lot_Number as Lot", "Box_Expiry as Expires", "count(*) as Boxes", 'Box_Status as Status' ],
        "where FK_Stock_Catalog__ID = Stock_Catalog_ID and Box_Status not in ('Inactive') and FK_Stock__ID=Stock_ID and Box_Expiry not like '0%' and Box_Expiry <= '$today' $grp_condition AND (Box_Expiry >= '$since' OR Box_Status='Open') $extra_condition group by Stock_Catalog_Name,Stock_Lot_Number,Box_Expiry order by Box_Expiry",
        undef
    );

    my $Expiring = HTML_Table->new();
    $Expiring->Set_Title("<B>Boxes/Kits Recently Expired (in past month)</B>");
    $Expiring->Set_Headers( [ 'Name', 'Lot', 'Units', 'Expiry', 'Status' ] );

    my $index = 0;
    while ( defined $EXP{Name}[$index] ) {
        my $name = $EXP{Name}[$index] || '-';
        my $lot  = $EXP{Lot}[$index]  || '-';
        my $expires = $EXP{Expires}[$index];
        my $count   = $EXP{Boxes}[$index] || 0;
        my $status  = $EXP{Status}[$index] || 0;
        $Expiring->Set_Row( [ $name, &Href( $dbc->homelink(), $lot, 'Lot' ), $count, $expires, $status ] );

        $index++;
    }

    $Expiring->Printout();
    ################## Expired Last Month #############################

    print "<P>";
    my %EXP2 = $dbc->Table_retrieve(
        'Box,Stock,Stock_Catalog',
        [ "Stock_Catalog_Name as Name", "Stock_Lot_Number as Lot", "Box_Expiry as Expires", "count(*) as Boxes", 'Box_Status as Status' ],
        "where Stock_Catalog_ID = FK_Stock_Catalog__ID and Box_Status not in ('Inactive') and FK_Stock__ID=Stock_ID and Box_Expiry <= '$until' and Box_Expiry >= '$today' $extra_condition $grp_condition group by Stock_Catalog_Name,Stock_Lot_Number,Box_Expiry order by Box_Expiry",
        undef
    );
    my $Expiring2 = HTML_Table->new();
    $Expiring2->Set_Title("<B>Boxes/Kits Expiring in the Next $days Days</B>");
    $Expiring2->Set_Headers( [ 'Name', 'Lot', 'Units', 'Expiry', 'Status' ] );

    $index = 0;
    while ( defined $EXP2{Name}[$index] ) {
        my $name = $EXP2{Name}[$index] || '-';
        my $lot  = $EXP2{Lot}[$index]  || '-';
        my $expires = $EXP2{Expires}[$index];
        my $count   = $EXP2{Boxes}[$index] || 0;
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
    # Get the next expiring box.
    # Generate warning if before today...
    #
    #
    my $boxes = shift;
    ( my $today ) = split ' ', &date_time();

    my $dbc = $Connection;

    my $full_today = $today;
    $today =~ s/[:\-\s]//g;    ### convert to integer..

    ( my $expiry ) = $dbc->Table_find( 'Box', 'min(Box_Expiry)', "where Box_ID in ($boxes) and Box_Expiry not like '0%'" );

    my $intExpiry   = $expiry;
    my $full_expiry = $expiry;
    $intExpiry =~ s/[:\-\s]//g;    ### convert to integer..

    if ( $intExpiry =~ /[1-9]/ && ( $intExpiry < $today ) ) {
        $dbc->warning("Expired Boxes Used (Expired: $full_expiry; Today: $full_today)!");
        return $expiry;
    }
    return $expiry;
}

##############################
# private_methods            #
##############################
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

$Id: Box.pm,v 1.22 2004/11/11 00:53:55 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
