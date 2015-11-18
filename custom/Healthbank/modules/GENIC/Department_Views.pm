package Healthbank::GENIC::Department_Views;

use base Healthbank::Department_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;
use alDente::Tools;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs $Connection);

use Healthbank::Model;
use Healthbank::Views;

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc}        || $self->dbc();
    my $open_layer = $args{-open_layer} || 'Incoming Samples';

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Lab
    if ( !( $Access{'GENIC'} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links($dbc);

    #my ($search_ref,$creates_ref) = Healthbank::GENIC::Department::get_searches_and_creates(-access=>\%Access);
    #my @searches = @$search_ref;
    #my @creates = @$creates_ref;

    #my ($greys_ref,$omits_ref) = Healthbank::GENIC::Department::get_greys_and_omits();
    #my @grey_fields= @$greys_ref;
    #my @omit_fields = @$omits_ref;

    #my $grey = join '&Grey=',@grey_fields;
    #my $omit = join '&Omit=',@omit_fields;

    use alDente::Source_App;

    my %layers;

    my $now = date_time();
    my $options = { '1' => 1, '2' => 2, '3' => 3, '4' => 1 };    ## custom numbers of blood/urine collection tubes to print out by default

    if (0) {
## not an option currently ##
        $layers{'Blood Collection'} = alDente::Source_Views::receive_Samples(
            -dbc         => $dbc,
            -options     => $options,
            -preset      => { 'Collection_DateTime' => '$now' },
            -rack        => 2,
            -origin      => 1,
            -sample_type => 'Whole Blood',
        );
    }

    my $HV = $self->Model(-class=>'Healthbank::Views');

    $layers{'Sample Preparation'} = $HV->sample_prep_page($dbc);

    $layers{'Export'}     = $HV->_export_page($dbc);
    $layers{'Search'}     = $HV->_search_page( -dbc => $dbc, -url_condition => 'FK_Project__ID=2' );
    $layers{'In Transit'} = alDente::Rack_Views::in_transit($dbc);

    my @order = ( 'Blood Collection', 'Sample Preparation', 'Search', 'Export', 'In Transit' );
    if ( grep /Admin/, @{ $Access{'GENIC'} } ) {
        $layers{'Administration'} = $HV->_admin_page($dbc, -condition=>"Patient_Identifier LIKE 'SHE%'");
        push @order, 'Administration';
    }

    my $page = define_Layers(
        -layers    => \%layers,
        -order     => \@order,
        -tab_width => 100,
        -default   => 'Sample Preparation',
    );

    #print $page;
    return $page;

}

####################
sub overview {
####################
    my %args             = filter_input( \@_, -args=>'dbc,condition' );
    my $dbc  = $args{-dbc};
    my $condition = $args{-condition};
    my $include_times    = $args{-include_times};
    my $source_condition = $args{-source_condition};
    my $plate_condition  = $args{-plate_condition};
    my $prefix           = $args{-prefix};
    my $debug            = $args{-debug} || 0;

    if ($prefix) { 
        $plate_condition = "Plate_Label LIKE '$prefix%'"; 
        $source_condition = "Patient_Identifier LIKE '$prefix%'";
    }
    
    my $layer = $args{-layer};    # ('Layer');

    my $page = "<h2>Overview of samples collected</H2>";
    if ($include_times) {
        $page .= compare_samples(
             $dbc,
            -having           => "having count(DISTINCT Source_ID) = 7",
            -title            => 'Subjects Completed',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug,
            -auto_update      => 1
        );    ## auto-update data first time through... #
        $page .= compare_samples(
             $dbc,
            -having           => "having count(DISTINCT Source_ID) > 7",
            -title            => 'Extra collected Samples',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug
        );
        $page .= compare_samples(
             $dbc,
            -having           => "having count(DISTINCT Source_ID) < 7",
            -title            => 'Partially collected Samples',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug
        );
    }
    else {
        $page .= compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) = 7", -title => 'Subjects completed',          -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
        $page .= compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) > 7", -title => 'Extra collected Samples',     -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
        $page .= compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) < 7", -title => 'Partially collected Samples', -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
    }

    return $page;
}

#
# Overview at subject level
#
#
#########################
sub compare_numbers {
#########################
    my %args             = filter_input( \@_, -args => 'dbc,condition,title' );
    my $dbc              = $args{-dbc};
    my $source_condition = $args{-source_condition} || 1;
    my $title            = $args{-title};
    my $having           = $args{-having};
    my $debug            = $args{-debug};

    my $Expected = {
        'Saliva Cup'  => 1,
        'EDTA (4 mL) RBC+WBC Tube'  => 1,
        'EDTA (4 mL) Tube' => 1,
        'Urine Cup'              => 1
    };

    my @expected = sort keys %$Expected;

    my @urine_only;

    use alDente::Stats_Table;

    my $Partial = alDente::Stats_Table->new( -title => $title );
    my @headers = ('Subject');

    my $group = 'GROUP BY Patient_Identifier';
    my @fields = ( 'Patient_Identifier as Subject', 'Received_Date', 'GROUP_CONCAT(Plate_Format_Type) as Formats', 'Group_CONCAT(Distinct Attribute_Value) as Collected' );

    push @headers, 'Collected', 'Activated', @expected;

    $Partial->Set_Headers( \@headers );
    
    my ($collected_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' and Attribute_Name = 'collection_time'" );
    my %Subject_Data = $dbc->Table_retrieve(
        "Source, Plate_Format, Original_Source, Patient LEFT JOIN Source_Attribute ON Source_Attribute.FK_Source__ID=Source_ID AND FK_Attribute__ID=$collected_attribute",
        \@fields,
        -condition => "WHERE FK_Plate_Format__ID=Plate_Format.Plate_Format_ID AND FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $source_condition $group $having",
        -debug     => $debug
    );

    my $row = 0;
    while ( defined $Subject_Data{Subject}[$row] ) {
        my @data      = split ',', $Subject_Data{Formats}[$row];
        my $subject   = $Subject_Data{Subject}[$row];
        my $format    = $Subject_Data{Plate_Format_Type}[$row] || $Subject_Data{Formats}[$row];

        my $time      = $Subject_Data{Received_Date}[$row];
        my $collected = $Subject_Data{Collected}[$row];

        $row++;
        my $col = 3;    ## point to current column (prior to Format columns)

        my %Found;
        foreach my $type (@data) {
            $Found{$type}++;
        }
        my @row = ($subject);

        push @row, $collected, $time;
        foreach my $type (@expected) {
            $col++;
            my $found = $Found{$type} || '0';
            push @row, $found;

            my $expected = $Expected->{$type};
#            if ( $expected != $found ) {

                #		$found ||= 'No';
                my $colour;
                if ( $found >= $expected ) {
                
                    #	    Message("$subject: $found $type records ($expected expected)");
                    $colour = 'lightgreen';    ## more than enough
                }
                elsif ($found) {
                    $colour = 'yellow';    ## incomplete
                }
                else {
                    #	    Message("Warning: $subject: $found $type records ($expected expected)");
                    $colour = 'red';       ## not collected thus far
                }
                $Partial->Set_Cell_Colour( $row, $col, $colour );
            }
 
 #       }

        $Partial->Set_Row( \@row );
    }

    $Partial->add_Stats( { 4 => 'Sum,N', 5 => 'Sum,N', 6 => 'Sum,N', 7 => 'Sum,N' }, 'mediumredbw' );

    #    $Partial->Column_Stats({4=>'Sum,N', 5=>'Sum,N', 6=>'Sum,N', 7=>'Sum,N'}, 'mediumredbw');
    #    $Partial->show_Column_Stats;   ## autogenerate line at bottom of page with column totals avgs etc if requested...

    $title =~ s/\s+/\_/g;

    my $print_link = $Partial->Printout( $Configs{URL_temp_dir} . "/$title." . timestamp . '.html' );
    my $excel_link = $Partial->Printout( $Configs{URL_temp_dir} . "/$title." . timestamp . '.xls' );

    my $printout = $print_link . $excel_link . $Partial->Printout(0);

    return create_tree( -tree => { "<B>$row $title</B>" => $printout } );
}

#
# Overview at sample level
#
#
########################
sub compare_samples {
########################
    my %args             = filter_input( \@_, -args => 'dbc,condition,title' );
    my $dbc              = $args{-dbc};
    my $source_condition = $args{-source_condition} || 1;                         ## source conditions
    my $plate_condition  = $args{-plate_condition} || 1;                          ## specific to Plates
    my $title            = $args{-title};
    my $having           = $args{-having};
    my $auto_update      = $args{-auto_update};
    my $debug            = $args{-debug};

    my @urine_only;

    my $Expected = {
        'Whole Blood'       => 3,
        'Blood Plasma'      => 9,
        'White Blood Cells' => 3,
        'Red Blood Cells'   => 3,
        'Blood Serum'       => 6,
        'Urine'             => 3
    };

    my %layers;
    my %Partial;
    my $group        = 'GROUP BY Patient_Identifier';
    my @fields       = ( 'Patient_Identifier as Subject', 'Received_Date', 'GROUP_CONCAT(Plate_Format_Type) as Formats' );
    my %Subject_Data = $dbc->Table_retrieve(
        'Source, Plate_Format,Sample_Type,Original_Source,Patient', \@fields,
        -condition => "WHERE FK_Plate_Format__ID=Plate_Format.Plate_Format_ID AND FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID AND $source_condition $group $having",
        -debug     => $debug
    );

    if ($auto_update) {
        &Healthbank::Model::auto_update_time_attributes($dbc);
    }
    
    my $row = 0;
    while ( defined $Subject_Data{Subject}[$row] ) {
        my @data    = split ',', $Subject_Data{Formats}[$row];
        my $subject = $Subject_Data{Subject}[$row];
        my $format  = $Subject_Data{Plate_Format_Type}[$row] || $Subject_Data{Formats}[$row];
        my $time    = $Subject_Data{Received_Date}[$row];

        $row++;
        my $col = 3;    ## point to current column (prior to Format columns)

        my %Found;
        foreach my $type (@data) {
            $Found{$type}++;
        }

        my @row = ($subject);

        my ($collected_attribute)      = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' and Attribute_Name = 'collection_time'" );
        my ($stored_attribute)         = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'first_stored'" );
        my ($time_to_freeze_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'initial_time_to_freeze'" );

        my $loop_debug = 0;

        my $condition = "where Plate.FK_Sample_Type__ID=Sample_Type_ID AND Plate.FKParent_Plate__ID=Parent.Plate_ID AND Plate_Sample.FKOriginal_Plate__ID=Parent.Plate_ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND FK_Original_Source__ID=Original_Source_ID AND FK_Patient__ID=Patient_ID";

        my $left_joins
            = " LEFT JOIN Source_Attribute as Collected ON Collected.FK_Source__ID=Source_ID AND Collected.FK_Attribute__ID=$collected_attribute"
            . " LEFT JOIN Plate_Attribute as Time_to_Freeze ON Time_to_Freeze.FK_Plate__ID=Plate.Plate_ID and Time_to_Freeze.FK_Attribute__ID=$time_to_freeze_attribute"
            . " LEFT JOIN Plate_Attribute as Stored ON Stored.FK_Plate__ID=Plate.Plate_ID AND Stored.FK_Attribute__ID=$stored_attribute";

        my $extra_conditions = "Plate.Plate_Status = 'Active' AND $source_condition AND $plate_condition AND Plate.Plate_Label like '$subject%'";

        my %diff = $dbc->Table_retrieve(
            "Plate, Plate as Parent, Sample_Type, Plate_Sample, Sample, Source, Original_Source, Patient $left_joins",
            [   'count(Distinct Plate.Plate_ID) as cryovials',
                'Sample_Type.Sample_Type',
                'Collected.Attribute_Value as Collected',
                'Parent.Plate_Created as Activated',
                'Min(Plate.Plate_Created) as First_Aliquot',
                'Received_Date as Activated',
                'Left(Stored.Attribute_Value,16) as Stored',
                'Time_to_Freeze.Attribute_Value as TimeDiff',
                'Parent.FK_Plate_Format__ID as Blood_Tube'
            ],
            "$condition AND $extra_conditions Group by Sample_Type, Collected, Stored",
            -border=>1,
            -debug => $loop_debug,
        );

        my $subrow = 0;
        while ( defined $diff{cryovials}[$subrow] ) {
            my $samples    = $diff{cryovials}[$subrow];
            my $type       = $diff{Sample_Type}[$subrow];
            my $collected  = $diff{Collected}[$subrow];
            my $activated  = $diff{Activated}[$subrow];
            my $stored     = $diff{Stored}[$subrow];
            my $timediff   = $diff{TimeDiff}[$subrow];
            my $blood_tube = $diff{Blood_Tube}[$subrow];

            my $key = $type;    ## layer output on Sample_Type
            if ( !defined $Partial{$key} ) {
                $Partial{$key} = alDente::Stats_Table->new( -title => $title );
                $Partial{$key}->Toggle_Colour_on_Column(1);
                $Partial{$key}->Set_Headers( [ 'Subject', 'Original Blood Tube', 'Sample_Type', 'Count', 'Collected', 'Activated', 'Stored', 'Hours_to_Storage' ] );
            }

            if ( $timediff =~ /(\d+)\:(\d+):(\d+)/ ) {
                my $hours   = $1;
                my $minutes = $2;
                if ($minutes) { $timediff = int( 100 * ( $1 + $2 / 60 ) ) / 100 }    ## two decimal places
                else          { $timediff = $1 }
            }

            my $colour;
            if    ( $samples > $Expected->{$type} ) { $colour = 'lightgreenbw' }
            elsif ( $samples == 0 )                 { $colour = 'lightredbw' }
            elsif ( $samples < $Expected->{$type} ) { $colour = 'lightyellowbw' }
            $Partial{$key}->Set_Row( [ @row, alDente::Tools::alDente_ref( 'Plate_Format', $blood_tube, -dbc => $dbc ), $type, $samples, $collected, $activated, $stored, $timediff ], $colour );
            $subrow++;
        }
    }

    foreach my $key ( keys %Partial ) {

        #	$Partial->add_Stats({8=>'N,Hist,Avg'});
        #	$Partial{$key}->Column_Stats({4=>'Sum,N',8=>'Avg,N'}, 'mediumredbw');
        #	$Partial{$key}->show_Column_Stats;   ## autogenerate line at bottom of page with column totals avgs etc if requested...

        if ( $Partial{$key}->{rows} > 1 ) {
            my $message = $Partial{$key}->add_Stats( { 8 => 'Histogram,Count,Avg,Min,Max' } );
            if ($message) { $dbc->message($message) }
        }

        $title =~ s/\s+/\_/g;

        my $print_link = $Partial{$key}->Printout( $Configs{URL_temp_dir} . "/$title." . timestamp . '.html' );
        my $excel_link = $Partial{$key}->Printout( $Configs{URL_temp_dir} . "/$title." . timestamp . '.xls' );

        my $printout = $print_link . $excel_link . $Partial{$key}->Printout(0);
        my $count    = $Partial{$key}->rows - 1;
        $layers{"$key [$count]"} = $printout;
    }

    my $page = define_Layers( -layers => \%layers );

    return create_tree( -tree => { "<B>$row $title</B>" => $page } );    ## printout});
}

return 1;
