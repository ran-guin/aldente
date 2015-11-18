###################################################################################################################################
# alDente::Tray_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Tray_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
## alDente modules
use alDente::Well;
use alDente::Library_Plate;
use alDente::Container_Views;
use alDente::Validation;

use vars qw( %Configs );

my $q = new CGI;
#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};

    $self->{dbc} = $dbc;
    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

#################################
sub prompt_to_confirm_Contents {
#################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $tray_id = $args{-tray_id};

    my $page = alDente::Form::start_alDente_form( $dbc, 'verify' );

    $page .= set_validator( -name => 'Scanned_File', -mandatory => 1 );

    $page .= vspace() . hidden( -name => 'Tray_ID', -value => $tray_id, -force => 1 );
    $page .= 'Scanned CSV File: ' . filefield( -name => 'Scanned_File', -size => 30 );
    $page .= hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );
    $page .= &hspace(5)
        . Show_Tool_Tip(
        submit( -name => 'rm', -value => 'Validate Contents', -force => 1, -onclick => 'return validateForm(this.form)', -class => 'Action' ),
        "Validate Contents of micro-Barcoded Plate (correlate with scanner-generated CSV file containing positions of barcoded tubes173) "
        );
    $page .= vspace() . end_form();
    return $page;
}

####################
sub tray_header {
####################
    my %args      = filter_input( \@_, -args => 'dbc,tray_id' );
    my $dbc       = $args{-dbc};
    my @tray_list = Cast_List( -list => $args{-tray_id}, -to => 'array' );

    my $header = $q->h4( 'Trays: ' . join ', ', map { $dbc->get_FK_info( 'FK_Tray__ID', $_ ) } @tray_list );

    my $trays = join ',', @tray_list;

    my @daughter_trays = $dbc->Table_find(
        'Plate_Tray,Plate,Plate as Daughter, Plate_Tray as Daughter_Tray',
        'Daughter_Tray.FK_Tray__ID',
        "WHERE Plate.Plate_ID=Daughter.FKParent_Plate__ID AND Daughter_Tray.FK_Plate__ID=Daughter.Plate_ID AND Plate_Tray.FK_Plate__ID=Plate.Plate_ID AND Plate_Tray.FK_Tray__ID IN ($trays)",
        -distinct => 1
    );

    my @parent_trays = $dbc->Table_find(
        'Plate_Tray,Plate,Plate as Parent, Plate_Tray as Parent_Tray',
        'Parent_Tray.FK_Tray__ID',
        "WHERE Parent.Plate_ID=Plate.FKParent_Plate__ID AND Parent_Tray.FK_Plate__ID=Parent.Plate_ID AND Plate_Tray.FK_Plate__ID=Plate.Plate_ID AND Plate_Tray.FK_Tray__ID IN ($trays)",
        -distinct => 1
    );

    if (@parent_trays) {
        $header .= &hspace(10) . "Parent Trays: ";
        foreach my $tray (@parent_trays) {
            $header .= alDente::Tools::alDente_ref( 'Tray', $tray, -dbc => $dbc ) . '; ';
        }
    }

    if (@daughter_trays) {
        $header .= &hspace(10) . "Daughter Trays: ";
        foreach my $tray (@daughter_trays) {
            $header .= alDente::Tools::alDente_ref( 'Tray', $tray, -dbc => $dbc ) . '; ';
        }
    }
    $header .= '<hr>';

    return $header;
}

# show a plate box for a tray
#
# Usage:
#   my $view = $self->tray_of_tube_box(-tray_id=>"tra$tray_id"); # note, the tra prefix must be there
#
# Returns: a plate box for a tray that you can select wells
###########################
sub tray_of_tube_box {
###########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'tray_id' );
    my $tray_id       = $args{-tray_id};
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $resolve       = $args{-resolve};                           # for each well, resolve to it's plate id
    my $preset_colour = $args{-preset_colour};
    my $default       = $args{-default_checked};

    my %preset_colour = %{$preset_colour} if $preset_colour;
    my $source_plates = &get_aldente_id( $dbc, $tray_id, 'Plate' );

    #using the first plate of tray to get plate_format
    my @source_plate = split( ",", $source_plates );
    my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -dbc => $dbc, -plate => $source_plate[0] );
    my %availability;

    #set tray poistions that doesn't have plate to be unavailable
    my ($plate_size) = $dbc->Table_find( "Plate,Plate_Format", "Concat(Wells,'-',Capacity_Units)", "WHERE Plate_ID = $source_plate[0] and FK_Plate_Format__ID = Plate_Format_ID" );

    my $t_id = $tray_id;
    print Dumper $Prefix{Tray};
    $t_id =~ s/$Prefix{Tray}//i;
    my ($used_wells) = $dbc->Table_find( "Plate_Tray", "Group_Concat(Plate_Position)", "WHERE FK_Tray__ID = $t_id" );
    my $list = $used_wells if ($default);
    my @wells_unused = &alDente::Library_Plate::not_wells( $used_wells, $plate_size );
    for my $well (@wells_unused) {
        $well = &format_well( $well, 'nopad' );
        $availability{$well} = 0;
    }

    my %tray_to_resolve;
    if ($resolve) {
        $tray_id = '';
        my @tray_info = $dbc->Table_find( "Plate_Tray", "FK_Plate__ID, Plate_Position", "WHERE FK_Tray__ID = $t_id" );
        for my $tray (@tray_info) {
            my ( $pid, $pos ) = split( ",", $tray );
            $pos = &format_well( $pos, 'nopad' );

            #print HTML_Dump $pos;
            $tray_to_resolve{$pos} = $pid;
        }
    }

    #print HTML_Dump %tray_to_resolve;
    my $plate_box = &alDente::Container_Views::select_wells_on_plate(
        -dbc             => $dbc,
        -table_id        => 'Select_Wells',
        -max_row         => $max_row,
        -max_col         => $max_col,
        -input_type      => 'checkbox',
        -availability    => \%availability,
        -plate_id        => $tray_id,
        -tray_to_resolve => \%tray_to_resolve,
        -preset_colour   => \%preset_colour,
        -list            => $list
    );

    return $plate_box;
}

sub tray_of_tube_plate_set_page {
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'tray_id' );
    my $tray_ref = $args{-tray_ref};
    my $dbc      = $self->{dbc};
    my $output;
    my @trays = @$tray_ref;
    $output .= alDente::Form::start_alDente_form( $dbc, 'Plate', -type => 'Plate' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );

    for my $tray_id (@trays) {
        $tray_id = alDente::Tray::add_prefix( -id => $tray_id );
        my $tray_table = HTML_Table->new( -title => "Select wells from $tray_id to save plate set" );
        my $box = $self->tray_of_tube_box( -tray_id => $tray_id, -resolve => 1 );
        $tray_table->Set_Row( [$box] );
        $output .= $tray_table->Printout(0);
    }
    $output .= hr . submit( -name => 'rm', -value => 'Save Tube Set', -class => 'Action' );

    $output .= end_form();

    return $output;
}

sub tray_of_tube_qc_status_page {
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tray_id' );
    my $tray_ref  = $args{-tray_ref};
    my $attribute = $args{-attribute} || 'Sample_QC_Status';
    my $dbc       = $self->{dbc};
    my $output;
    my @trays = @$tray_ref;
    $output .= alDente::Form::start_alDente_form( $dbc, 'Plate', -type => 'Plate' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );
    my %qc_colours;
    $qc_colours{'Approved'}                                   = 'green';
    $qc_colours{'Failed'}                                     = 'red';
    $qc_colours{'Approved - On Hold'}                         = 'yellow';
    $qc_colours{'Failed - Proceed with library construction'} = 'blue';
    my $legend_table = HTML_Table->new( -title => 'QC Status Legend' );
    my $index = 1;

    foreach my $value ( sort keys %qc_colours ) {
        $legend_table->Set_Row( [ $value, "|              |" ] );
        $legend_table->Set_Cell_Colour( $index, 2, $qc_colours{$value} );
        $index++;
    }
    $output .= $legend_table->Printout(0);
    for my $tray_id (@trays) {

        my @plate_wells = $dbc->Table_find(
            'Plate_Tray,Plate,Plate_Attribute,Attribute',
            'Plate_Position,Attribute_Value',
            "WHERE Plate_Tray.FK_Plate__ID = Plate_ID and 
        Plate_Attribute.FK_Plate__ID = Plate_ID and Attribute_Name = '$attribute' and Attribute_ID = Plate_Attribute.FK_Attribute__ID and FK_Tray__ID = $tray_id"
        );
        if ( $tray_id !~ /tra/i ) {
            $tray_id = alDente::Tray::add_prefix( -id => $tray_id );
        }
        my $tray_table = HTML_Table->new( -title => "Select wells from $tray_id to set the Sample QC Status" );
        my %preset_colour;
        foreach my $plate_well (@plate_wells) {
            my ( $plate_pos, $attr ) = split ',', $plate_well;
            if ( $attr && $plate_pos ) {
                $plate_pos = &format_well( $plate_pos, 'nopad' );
                push @{ $preset_colour{ $qc_colours{$attr} } }, $plate_pos;
            }
        }
        my $box = $self->tray_of_tube_box( -tray_id => $tray_id, -resolve => 1, -preset_colour => \%preset_colour );
        $tray_table->Set_Row( [$box] );
        $output .= $tray_table->Printout(0);
    }
    $output .= hr . submit( -name => 'rm', -value => 'Set Sample QC Status', -class => 'Action' );

    my @available_sample_qc_status;
    require alDente::Attribute;
    @available_sample_qc_status = alDente::Attribute::get_Attribute_enum_list( -name => "$attribute", -dbc => $dbc );
    $output .= popup_menu( -name => 'Sample_QC', -value => \@available_sample_qc_status, -default => "Approved" );
    $output .= hidden( -name => 'Attribute', -value => "$attribute", -force => 1 );
    $output .= end_form();

    return $output;
}

sub tray_of_tube_fail_well_page {
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tray_ids,plate_ids', -mandatory => 'tray_ids|plate_ids' );
    my $tray_list = $args{-tray_ids};
    my $plate_ids = $args{-plate_ids};
    my $dbc       = $args{-dbc} || $self->{dbc};

    my $output;
    my @trays;
    if ($tray_list) {
        @trays = Cast_List( -list => $tray_list, -to => 'array' );
    }
    elsif ($plate_ids) {
        my $plate_list = Cast_List( -list => $plate_ids, -to => 'string' );
        @trays = $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID in ( $plate_list )", -distinct => 1 );
    }
    my $groups = $dbc->get_local('group_list');
    my $reasons = alDente::Fail::get_reasons( -dbc => $dbc, -object => 'Plate', -grps => $groups );

    $output .= alDente::Form::start_alDente_form( $dbc, 'Plate', -type => 'Plate' );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );

    for my $tray_id (@trays) {
        $tray_id = alDente::Tray::add_prefix( -id => $tray_id );
        my $tray_table = HTML_Table->new( -title => "Select wells from $tray_id to fail" );
        my $box = $self->tray_of_tube_box( -tray_id => $tray_id, -resolve => 1 );
        $tray_table->Set_Row( [$box] );
        $output .= $tray_table->Printout(0);
    }
    $output
        .= hr
        . submit( -name => 'rm', -value => 'Confirm Fail Wells', -class => 'Action' )
        . hspace(5)
        . checkbox( -name => 'Throw_Out', -label => 'Throw Out Tubes', -value => 'Throw Out Tubes', -force => 1 ) . '<BR>'
        . ' Fail Reason: '
        . Show_Tool_Tip( popup_menu( -name => 'FK_FailReason__ID', -values => [ '', sort keys %{$reasons} ], -labels => $reasons, -force => 1 ), 'Please select a fail reason. This field is required.' ) . '<BR>'
        . 'Comments: '
        . textfield( -name => 'Comments', -size => 20, -force => 1 );
    $output .= set_validator( -name => 'FK_FailReason__ID', -mandatory => 1 );
    $output .= end_form();

    return $output;
}
1;
