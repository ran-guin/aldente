##################################################################################################################################
# Control_Plate.pm
#
# <concise_description>
#
###################################################################################################################################
package alDente::Control_Plate;

use CGI qw(:standard);
use Carp;
use strict;

use RGTools::RGIO;
use SDB::HTML;
use alDente::Tools qw(alDente_ref);
use alDente::Container qw(get_Children);
##############################
# global_vars                #
##############################

use vars qw($Connection);
############
sub new {
############
    my $this  = shift;
    my %args  = @_;
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $class = ref $this || $this;

    my $self = {};
    $self->{dbc} = $dbc;
    bless $self, $class;
    return $self;
}

##################
sub home_page {
##################
    my %args = filter_input( \@_, -args => 'dbc,plate_id' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $plate_id = $args{-plate_id};

    my $output = show_Control_Attributes( $dbc, $plate_id );

    $output .= hr;

    my $parent_plates = alDente::Container::get_Parents( $dbc, $plate_id, -format => 'list' );

    $output .= show_Prep_mates( $dbc, $plate_id );

    return $output;
}

#################################
sub show_Control_Attributes {
#################################
    my $dbc = shift || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $plate_id = shift;

    my ( @row1, @row2, @row3 );
    my ( @avg1, @avg2, @avg3 );

    my @control_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Class = 'Plate' AND Attribute_Name like '%_Control'" );

    #    foreach my $protocol (@protocols) {
    #	my @associated_plates = @{ alDente::Container::get_Prep_mates($dbc,-plate_id=>$plate,-protocol=>$protocol)};
    #	my $list = join "\n<LI>", @associated_plates;
    #	push @row1, "<UL>\n<LI>$list</UL>\n";
    #	push @avg1, '(q20 avg)';
    #    }
    #

    my @get_table;
    my @get_attr;
    my $found_q20 = 0;    ## flag to see if we find any q20 values (sequencing data only at this stage)

    my $parent_plates = alDente::Container::get_Parents( $dbc, $plate_id, -format => 'list', -simple => 1 );
    foreach my $attribute (@control_attributes) {
        my @associated_plates = @{ get_Plates_with_Attribute( $dbc, -plate => $parent_plates, -attribute => $attribute ) };
        my @link_list         = @associated_plates;
        my $list              = join "\n<LI>", map { alDente_ref( -dbc => $dbc, -table => 'Plate', -id => $_ ) } @link_list;
        push @row2, "<UL>\n<LI>$list</UL>\n" if $list;

        my $q20 = _link_to_q20( $dbc, \@associated_plates );
        push @avg2, "Q20 Avg: $q20";    ## generate q20 averages for given plates...

        ## put together Attributes into extended LEFT JOIN query for extracting Control plates for given plate (normal ?) ##
        my ($control_plate) = $dbc->Table_find( 'Attribute,Plate_Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID=Attribute_ID AND FK_Plate__ID IN ($plate_id) AND Attribute_Name = '$attribute' AND Attribute_Class = 'Plate'" );
        if ( $control_plate =~ /PLA(\d+)/ ) {
            my $cp_id = $1;
            my $q20 = _link_to_q20( $dbc, $cp_id );
            push @row1, &alDente_ref( -dbc => $dbc, -table => 'Plate', -id => $cp_id );
            push @avg1, "Q20 Avg: " . $q20;
            $found_q20 = 1 unless ( $q20 =~ /undef/ );
        }
        elsif ($control_plate) {
            push @row1, $control_plate;
            push @avg1, 'Q20 Avg: (undef)';
        }

        #	push @get_attr, "$attribute.Attribute_Value AS $attribute";
        #	push @get_table, "LEFT JOIN Plate_Attribute as $attribute ON $attribute.FK_Plate__ID=Plate_ID AND $attribute.FK_Attribute__ID = $attr_id";
        #	}
    }

    my $tables = join ' ', @get_table;
    my $output = "<h2>Plates associated with PLA $plate_id<h2>";
    $output .= alDente_ref( -dbc => $dbc, -table => 'Plate', -id => $plate_id ) . '<p ></p>';

    my $T1 = HTML_Table->new( -title => "Associated Control Plates" );
    $T1->Set_Headers( \@control_attributes );
    $T1->Set_Row( \@row1 );
    $T1->Set_Row( \@avg1, 'bgcolor=#FF9999' ) if $found_q20;

    $output .= hr . $T1->Printout(0) if @row1;

    my $T2 = HTML_Table->new( -title => "Plates Referencing Given Plate (or Parents) as a Control Plate", -border => 1, -valign => 'top' );
    $T2->Set_VAlignment('top');
    $T2->Set_Alignment('left');
    $T2->Set_Headers( \@control_attributes );
    $T2->Set_Row( \@row2 );
    $T2->Set_Row( \@avg2, 'bgcolor=#FF9999' );    ## Q20 Avg
    $output .= hr . $T2->Printout(0) if @row2;

    my $T3 = HTML_Table->new( -title => "Protocol Plates" );
    $T3->Set_Headers( \@control_attributes );
    $T3->Set_Row( \@row3 );
    $T3->Set_Row( \@avg3, 'bgcolor=#FF9999' );    ## Q20 Avg
    $output .= hr . $T3->Printout(0) if @row3;

    return $output;
}

#########################
sub show_Prep_mates {
#########################
    my $dbc = shift || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $plate_id = shift;

    #    my $plate = alDente::Container->new(-dbc=>$dbc,-id=>$plate_id);
    #    my $parent_plates = alDente::Container::get_Parents($dbc,$plate_id,-format=>'list');

    my %preps = %{ alDente::Container::get_Prep_mates( $dbc, $plate_id, -fields => [ 'Lab_Protocol_Name', 'FK_Plate__ID' ] ) };

    my @protocols;
    my %Prep;
    my $i = 0;
    while ( defined $preps{FK_Plate__ID}[$i] ) {
        my $protocol = $preps{Lab_Protocol_Name}[$i];
        if ( $protocol eq 'Standard' ) { $i++; next; }    ## exclude actions outside of protocols (eg throw away together)
        push @protocols, $protocol unless ( grep /^$protocol$/, @protocols );
        $protocol =~ s /^Standard$/Handled Outside Protocol/;

        my $plate = $preps{FK_Plate__ID}[$i];
        push @{ $Prep{$protocol} }, $plate unless grep /^$plate$/, @{ $Prep{$protocol} };
        $i++;
    }

    #    unshift @protocols, 'Handled Outside Protocol' if defined $Prep{'Handled Outside Protocol'};   ## put this one at the front

    my $Table = HTML_Table->new( -title => "Plates handled simultaneously with Plate(s) $plate_id" );
    $Table->Set_Headers( \@protocols );
    my ( @row, @avg );
    my $found_q20 = 0;
    foreach my $protocol (@protocols) {
        my @plates = @{ $Prep{$protocol} };

        my $list  = join "\n<LI>", map { alDente_ref( -dbc => $dbc, -table => 'Plate', -id => $_ ) } @plates;
        my $count = int(@plates);
        my $tree  = create_tree( -tree => { "$count Plates" => "<UL>\n<LI>$list</UL>\n" } );
        push @row, $tree;

        my $q20 = _link_to_q20( $dbc, \@plates );
        push @avg, "Q20 Avg: $q20";    ## generate q20 averages for given plates...
        $found_q20 = 1 unless ( $q20 =~ /undef/i );

    }
    $Table->Set_Row( \@row );
    $Table->Set_Row( \@avg, 'bgcolor=#FF9999' ) if $found_q20;

    return $Table->Printout(0);
}

#####################
sub _link_to_q20 {
#####################
    my $dbc = shift || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $plate_ref = shift;

    my @associated_plates = Cast_List( -list => $plate_ref, -to => 'array' );
    my $q20 = '(undef)';
    if (@associated_plates) {
        my $associated_list = join ',', @associated_plates;
        my $daughter_list = alDente::Container::get_Children( $dbc, $associated_list, -format => 'list', -include_self => 1 );
        $daughter_list ||= 0;
        my ($q20_data) = $dbc->Table_find_array( 'Run,SequenceRun,SequenceAnalysis', [ 'Sum(Q20total)/Sum(Wells) as Q20_Avg', 'count(*) as Count' ], "WHERE FK_Run__ID=Run_ID AND FK_SequenceRun__ID=SequenceRun_ID AND FK_Plate__ID IN ($daughter_list)" );
        ( $q20, my $count ) = split ',', $q20_data;
        $q20 = &Link_To( $dbc->config('homelink'), "$q20 [$count runs]", "&Last 24 Hours=1&Any+Date=1&Plate_ID=$daughter_list", -tooltip => "Link to Last 24 Hour page for these $count runs" ) if $q20;
    }

    return $q20 || '(undef)';
}

####################################
sub get_Plates_with_Attribute {
####################################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'value|plate,attribute' );    ## input arguments: ##
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $value     = $args{-value};                                                             # actual value
    my $plate     = $args{-plate};                                                             # id of REFERENCED PLATE (eg control plate)
    my $attribute = $args{-attribute};
    my $debug     = $args{-debug};

    my $condition;
    if ($value) {
        if ( $value =~ /^([><]=?)\s*(\d+)$/ ) {
            my $op = $1;
            $value = $2;
            $condition .= " AND Attribute_Value $op $value";
        }
        elsif ( $value =~ /^(\d+)\s*-\s*(\d+)$/ ) {
            $condition .= " AND Attribute_Value BETWEEN $1 AND $2";
        }
        elsif ( $value =~ /.+\|.+/ ) {
            $value =~ s /\|/\',\'/g;
            while ( $value =~ s /[\'\"]?(\w+)[\'\"]?\s?\|\s?[\'\"]?(\w+)[\'\"]?/$1 OR $2/ ) { }
            $condition .= " AND Attribute_Value IN ('$value')";
        }
        else {
            $condition .= " AND Attribute_Value LIKE '$value'";
        }
    }

    if ($plate) {
        my @plates = split /[\|\,]/, $plate;
        $condition .= " AND (";
        foreach my $plate (@plates) {
            $condition .= " OR " unless ( $plate == $plates[0] );    ## not for the first pass
            $condition .= " Attribute_Value REGEXP \"Pla0*$plate(P|\$)\"";
        }
        $condition .= ")";
    }

    my @plates = $dbc->Table_find(
        'Plate,Plate_Attribute,Attribute',
        'Plate_ID',
        "WHERE FK_Plate__ID=Plate_ID AND FK_Attribute__ID=Attribute_ID AND Attribute_Name =  '$attribute' $condition",
        -distinct => 1,
        -debug    => $debug,
    );

    return \@plates;
}
return 1;

__END__;
##############################
# perldoc_header             #
##############################
=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>

Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    Ran Guin, Andy Chan and J.R. Santos at the Michael Smith Genome Sciences Centre, Vancouver, BC
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
