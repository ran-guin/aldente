################################################################################
#
# Process.pm
#
# This facilitates protocol processing
# and process preparation procedures
#
################################################################################
################################################################################
# $Id: Process.pm,v 1.14 2004/10/05 00:29:55 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.14 $
#     CVS Date: $Date: 2004/10/05 00:29:55 $
################################################################################
package alDente::Process;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Process.pm - This facilitates protocol processing

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This facilitates protocol processing<BR>and process preparation procedures<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw(
    Mix_Solutions
);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
our ($class_size);
our ( $current_plates, $Track );
our ( $plate_set,      $solution_id );
our ( $homefile       );
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
#
# Begin object-oriented part of the package
#
sub new {
    my $this = shift;
    my $dbc  = $Connection;    #change to shift

    my ($class) = ref($this) || $this;
    my ($self) = {};
    bless $self, $class;
    return $self;
}

##############################
# public_methods             #
##############################

sub Set_Plates {
    my $self   = shift;
    my $plates = shift;

    $self->{plates} = $plates;
    my @all_plates = split ',', $plates;

    $self->{plates_entered} = scalar(@all_plates);
    return 1;
}

#######################
#
# Ensure inputs meet format requirements...
#
sub Check_Formats {
    my $self = shift;
    my $dbc  = shift || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $step = shift;

    ########## Check Equipment #############

    my @machines = param('Machine');
    my @MFormats = param('MFormat');

    my $number = scalar(@machines);
    my $index  = 0;
    foreach ( 1 .. $number ) {
        my $id = get_aldente_id( $dbc, $machines[ $number - 1 ], 'Equipment' );    ##### get Equipment ID
        my $format = $MFormats[ $number - 1 ];                                     ##### get specified format
        unless ( $id =~ /\d+/ ) { next; }                                          ##### ignore if no equipment ID

        ( my $type ) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Category', "where Equipment_ID in ($id) AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

        unless ( ( $type =~ /$format/i ) || !$format ) {
            main::Message("Equ$id ($type) should be $format");
            return 0;
        }
    }

################ Check Solution Formats ##################

    my @sols     = param('Solution Added');
    my @SFormats = param('SFormat');
    $number = scalar(@sols);
    my $solutions_used = '';
    foreach ( 1 .. $number ) {
        my $id = get_aldente_id( $dbc, $sols[ $number - 1 ], 'Solution' );    ##### get Solution ID
        my $format = $SFormats[ $number - 1 ];                                ##### get specified format
        unless ( $id =~ /\d+/ ) { next; }                                     ##### ignore if no Solution ID
        ( my $name ) = $dbc->Table_find( 'Stock_Catalog, Solution left join Stock on FK_Stock__ID=Stock_ID', 'Stock_Catalog_Name', "where Solution_ID in ($id) AND FK_Stock_Catalog__ID = Stock_Catalog_ID " );
        $solutions_used .= "$name,";                                          ### keep track of solution_name list..
        unless ( ( $name =~ /$format/i ) || !$format ) {
            main::Message("Sol$id ($name) should be like '*$format*'");
            return 0;
        }
    }

################ Check Antibiotic Marker ################

    my $AB_test = $main::Track->{Antibiotic};
    if ( $AB_test && $step =~ /$AB_test/i ) {                                 ######### check for proper antibiotic
        my $current_plates = param('Current Plates');
        my @antibiotics;
        my $trans = '';
        if ( $step =~ /poson/i ) {                                            #### if Xposon or Transposon in step name ####
            @antibiotics = $dbc->Table_find( 'Library,Plate,Pool,Transposon', 'Antibiotic_Marker', "where FK_Library__Name=Library_Name and FKPool_Library__Name=Library_Name and FK_Transposon__ID=Transposon_ID and Plate_ID in ($current_plates)" );
            $trans = 'Transposon';                                            #### just to include in message below
        }
        my $ok = 0;
        foreach my $antiB (@antibiotics) {
            if ( !( $antiB =~ /\S/ ) ) { $ok = 1; }
            elsif ( $solutions_used =~ /$antiB/ ) { $ok = 1; }                ### antibiotic in list of sols
        }
        unless ($ok) {
            main::Message( "$solutions_used not in valid $trans Antibiotics list:", "(@antibiotics)" );
            return 0;
        }
    }

################ Check Primer ################

    if ( $step =~ /Primer/i ) {                                               ######### check for proper primer

        my $current_plates = param('Current Plates');
        my @primers;
        my $trans = '';
        @primers = $dbc->Table_find( 'LibraryApplication,Plate,Primer,Object_Class',
            'Primer_Name,Primer_Type', "where Object_ID=Primer_ID and Plate.FK_Library__Name=LibraryApplication.FK_Library__Name and FK_Object_Class__ID = Object_Class_ID and Object_Class='Primer' and Plate_ID in ($current_plates)" );

        my $ok = 0;
        foreach my $primer (@primers) {
            if ( !( $primer =~ /Standard/ ) ) { $ok = 1; }                    ### Custom primer or Oligo...
            elsif ( $solutions_used =~ /$primer/ ) { $ok = 1; }               ### primer in list of sols
        }
        unless ($ok) {
            main::Message( "$solutions_used not in valid Primer list:", "(@primers)" );
            return 0;
        }
    }

    return 1;
}

######################
#
# Associate specific machines with specific plates
#
sub Get_Machine_old {

    my $self           = shift;
    my $plate_fields   = shift;
    my $machine_fields = shift;

    my @plates;
    my @machines;
    if ($plate_fields)   { @plates   = @$plate_fields; }
    if ($machine_fields) { @machines = @$machine_fields; }

    $self->{plates_entered}    = 0;
    $self->{equipment_entered} = 0;
    $self->{solutions_entered} = 0;

    if ( param('Machine1') ) {
        $self->{per_plate} = 1;

        ######### associate plates with equipment ############

        foreach my $index ( 1 .. $self->{number_of_plates} ) {
            my @plate_field     = split ',', $plates[ $index - 1 ];
            my @equipment_field = split ',', $machines[ $index - 1 ];
            unless ( $plate_field[0] && $equipment_field[0] ) { next; }

            ### ensure only one field has more than one entry at most ###########
            if ( scalar(@plate_field) > 1 && scalar( @equipment_field > 1 ) ) {
                my $msg = "Cannot have multiple machines applied to multiple plates";
                return ( 0, $msg );
            }
            ### if multiple plates entered for one piece of equipment ###
            elsif ( scalar( @plate_field > 1 ) ) {
                my $machine = $equipment_field[0];
                foreach my $plate (@plate_field) {
                    $self->{plate}[ $self->{plates_entered} ]     = $plate;
                    $self->{equipment}[ $self->{plates_entered} ] = $machine;
                    $self->{plates_entered}++;
                    $self->{equipment_entered}++;
                }
            }
            ### if multiple equipment entered for one plate
            elsif ( scalar(@equipment_field) > 1 ) {
                my $plate = $plate_field[0];
                foreach my $machine (@equipment_field) {
                    $self->{equipment}[ $self->{equipment_entered} ] = $machine;
                    $self->{plate}[ $self->{equipment_entered} ]     = $plate;
                    $self->{equipment_entered}++;
                    $self->{plates_entered}++;
                }
            }
            else {
                $self->{equipment}[ $self->{equipment_entered}++ ] = $equipment_field[0];
                $self->{plate}[ $self->{plates_entered}++ ]        = $plate_field[0];
            }
        }

        #### ensure all plates are used - and only once each ########
        foreach my $plate ( split ',', $self->{plates} ) {
            foreach my $index ( 1 .. $self->{plates_entered} ) {
                if ( $plate == $self->{plate}[ $index - 1 ] ) {
                    $self->{$plate}++;
                }
            }
            if ( $self->{$plate} > 1 ) {
                my $msg = "Plate $plate used more than once";
                return ( 0, $msg );
            }
            elsif ( !( $self->{$plate} ) ) {
                my $msg = "Plate $plate missed";
                return ( 0, $msg );
            }
        }
    }

    ########## Standard Single Machine Field ############

    elsif ( param('Machine') ) {
        my @machine_id = split ',', $machines[0];
        ######################## Account for more than one machine needed ############
        foreach my $machine (@machine_id) {
            $self->{equipment}[ $self->{equipment_entered} ] = $machine;
            $self->{equipment_entered}++;
        }
    }

    return (1);
}

######################
#
# Associate specific machines with specific plates
#
# Returns: (ok_flag, Error message(optional))
#
sub Get_Machine {

    my $self           = shift;
    my $machine_fields = shift;
    my $plate_fields   = shift;
    my @machines       = split ',', $machine_fields;

    my @plates;
    if ($plate_fields) {
        @plates = split ',', $plate_fields;
        $self->{plates_entered} = scalar(@plates);
    }
    else {
        @plates = ();
        $self->{plates_entered} = 0;
    }

    #    if ($plate_fields) {@plates = @$plate_fields;}
    #    if ($machine_fields) {@machines = @$machine_fields;}

    $self->{equipment_entered} = scalar(@machines);
    unless ( $machine_fields =~ /\d+/ ) {

        #	$self->{plates_entered} = 0;
        $self->{equipment_entered} = 0;
        return (1);
    }
######## if more than one piece of equipment is entered... #####
    if ( $machine_fields =~ /\d+\,/ ) {
        my $per_equip = $self->{plates_entered} / $self->{equipment_entered};
        if ( $per_equip == int($per_equip) ) {
            $self->{per_equip} = Extract_Values( [ $per_equip, 1 ] );
        }
        else {
            return ( 0, "Plates must be multiple of equipment" );
        }

        my $index       = 0;
        my $machine_num = 0;
        while ( ( $index < $self->{plates_entered} ) || ( $index < $self->{equipment_entered} ) ) {
            foreach ( 1 .. $self->{per_equip} ) {
                $self->{equipment}[$index] = $machines[$machine_num];
                if ( $index < $self->{plates_entered} ) {
                    $self->{plate}[$index] = $plates[$index];
                }
                $index++;
            }
            $machine_num++;
        }
    }
    ############## if no plates entered - assume ALL plates... ############
    else {

        #	$self->{plates_entered} = 1;
        foreach my $index ( 1 .. $self->{equipment_entered} ) {
            $self->{equipment}[ $index - 1 ] = $machines[ $index - 1 ];
        }
    }
    return (1);

}

######################
#
# extract solution used from preparation procedure.
#
sub Get_Solution {
    my $self      = shift;
    my $solution  = shift;
    my $dbc       = $Connection;
    my @solutions = @$solution;

    my $sol_last;
    my $sol_name;
    $self->{solutions_entered} = 0;
    foreach my $sol (@solutions) {
        $self->{solution}[ $self->{solutions_entered}++ ] = $sol;
        ($sol_name) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where Stock_ID=FK_Stock__ID and Solution_ID = $sol AND FK_Stock_Catalog__ID = Stock_Catalog_ID" );
        if ( $sol_last && ( $sol_name ne $sol_last ) ) {    ### fail if diff solutions
            return ( 0, "Solutions must be the same ($sol_last != $sol_name)" );
        }
        $sol_last = $sol_name;
    }

    my $qtyX    = param('QuantityX');
    my $platesX = 1;                                        ###Always dealing with 1 plate only.

    my $qty       = param('Quantity');
    my $qty_units = param('Quantity_Units');
    if ( $qty_units eq 'uL' ) {                             #Conversion
        $qty = $qty / 1000;
    }
    ($qty) = &main::convert_to_mils($qty);

    #    my $total_qty = 0;
    #    my $total_plates = 0;
    #    my $index = 0;
    #    $self->{quantities_entered}=0;
    #    $self->{platesX_entered}=0;
    #
    #    $self->{qtyX}[0] = $qtyX;
    #    $self->{platesX}[0] = $platesX;
#### if multiple 'plates X' or quantities entered ##########
    #    if (($platesX=~/,/) || ($qtyX=~/,/)) {
    #
    #	my $index = 0;
    #	#### check for multiple quantities entered ####
    #	while ($qtyX=~/(.*?),\s?(\d+)(.*)/) {
    #	    $self->{ratio}[$index]=$2;
    #	    $qtyX = $2.$3;
    #	    $total_qty += $self->{qty_ratio}[$index];
    #	    $self->{quantities_entered}++;
    #	    $index++;
    #	}
    #	#### check for multiple plate numbers entered ####
    #	while ($platesX=~/(.*?),\s?(\d+)(.$)/) {
    #	    $self->{ratio}[$index]=$2;
    #	    $platesX = $2.$3;
    #	    $total_plates += $self->{plates_ratio}[$index];
    #	    $self->{platesX_entered}++;
    #	    $index++;
    #	}
    #	   }
    #

    foreach my $index ( 1 .. $self->{solutions_entered} ) {
        if ($qtyX) {
            $self->{qty}[ $index - 1 ] = $platesX * $qtyX * $qty / $self->{solutions_entered};
        }
        else {
            $self->{qty}[ $index - 1 ] = $qty / $self->{solutions_entered};
        }
    }
    return 1;
}

sub Equip_distribution {
    my $self = shift;

    print "$self->{plates_entered} Plates assigned to $self->{equipment_entered} Machines";

    foreach my $index ( 1 .. $self->{plates_entered} ) {
        if ( $self->{plate}[ $index - 1 ] ) {
            print "<BR>Plate " . $self->{plate}[ $index - 1 ] . " assigned to EQU" . $self->{equipment}[ $index - 1 ];
        }
    }
    return 1;
}

##############################
# public_functions           #
##############################

##########
#
# Mix solutions together. Perhaps should be part of the Solutions package?
#
sub Mix_Solutions {

    #
### <CONSTRUCTION> - This is very old and should probably be tossed - but need to make sure it is not being used..
    #
    my $mixed_ok;
    my $step_name;
    my $more_fields;
    my $more_values;
    my $dbc = $Connection;    # change to args or shift

    if ( param('Solution1 Added') ) {
        my @starting_solution = split ',', &get_aldente_id( $dbc, param('Solution Added'), 'Solution' );
        my $total_quantity = param('Quantity');

        #	$sol_mix = $starting_solution.":".$total_quantity;
        #	mix_solution($starting_solution,$total_quantity,"mL");

        foreach my $name ( param() ) {
            print "trying to add $name " . param($name) . ".";
            if ( $name =~ /Solution(\d+) Added/ ) {
                my $num  = $1;
                my @sols = param($name);
                my @qtys = param("Quantity$num");
                foreach my $sol_num ( 1 .. scalar(@sols) ) {
                    my $sol = &get_aldente_id( $dbc, $sols[ $sol_num - 1 ], 'Solution' );
                    my $qty = $qtys[ $sol_num - 1 ];
                    print "mix $sol ($qty)";
                    $mixed_ok = mix_solution( $sol, $qty, "mL" );
                    $total_quantity += param("Quantity$num");
                }
            }
        }
        my $new_sol = save_mixture( $step_name, "", 'Rac1' );
        if ( !$new_sol ) {
            print "Error Saving the Mixture";
            &plate_next_step( $current_plates, $plate_set );
            return 0;
        }

        $more_fields .= ", FK_Solution__ID,Solution_Quantity";
        $more_values .= ", $new_sol,$total_quantity";

        if ($mixed_ok) {
            my $ok = $dbc->Table_update( 'Solution', 'Quantity_Used,Solution_Status', "$total_quantity,\"Temporary\"", "where Solution_ID=$new_sol" );
            if   ( $ok > 0 ) { print "(updated quantity of Sol $solution_id used)<BR>"; }
            else             { print "Error updating quantity: " . Get_DBI_Error() . "<BR>"; }
        }
    }
    return 1;
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

$Id: Process.pm,v 1.14 2004/10/05 00:29:55 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
