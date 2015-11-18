package Healthbank::BC_Generations::Statistics_Views;

use base Healthbank::Statistics_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Healthbank::Model;
use LampLite::Bootstrap;

my $BS = new Bootstrap;
my $q = new CGI;

my ( $session, $account_name );

#############
sub stats {
#############
    my $self = shift;
    my $condition = shift || 1;
    
    my $dbc = $self->dbc();

    return $self->SUPER::stats("Plate.FK_Library__Name = 'Hbank'");
}


#########################
sub view_discrepencies {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $output;
    
    my $tables    = 'Plate,Plate_Sample,Sample,Source,Original_Source';
    my $condition = "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID";

    my $Format   = { 'ACD' => 1, 'SST'  => 2, 'EDTA' => 3, 'Urine' => 4,  'Saliva' => 13 };
    my $Expected = { 'ACD' => 1, 'EDTA' => 3, 'SST'  => 2, 'Urine' => 1, 'Saliva' => 1 };

    my %C_layers;
    foreach my $type ( keys %{$Format} ) {
        my $collection_differences = $dbc->Table_retrieve_display(
            $tables . " LEFT JOIN Source AS $type ON $type.FK_Original_Source__ID = Source.FK_Original_Source__ID AND $type.FK_Plate_Format__ID=$Format->{$type}",
            [ 'Left(Source.External_Identifier,8) as Subject', "count(distinct $type.Source_ID) as $type" ],
            "$condition Group by Source.FK_Original_Source__ID"
                . " Having Count(distinct $type.Source_ID)/$Expected->{$type} < 1",
            -title       => 'Missing Blood Collection',
            -return_html => 1
        );

        $C_layers{$type} = $collection_differences;
    }
    my $layered_C_differences = define_Layers( -layers => \%C_layers );
    $output .= '<h2>Blood Collection Discrepencies</h2>' . $layered_C_differences;

    my $Sample = { 'WBC' => 7, 'RBC' => 6, 'Serum' => 5, 'Plasma' => 10, 'Urine' => 8 ,  'Saliva' => 9 };
    $Expected = { 'WBC' => 3, 'RBC' => 3, 'Serum' => 3, 'Plasma' => 3, 'Urine' => 1,  'Saliva' => 1 };

    my %layers;
    foreach my $type ( keys %{$Sample} ) {
        my $type_differences = $dbc->Table_retrieve_display(
            $tables . " LEFT JOIN Plate AS $type ON $type.FKOriginal_Plate__ID=Plate.Plate_ID AND $type.FK_Sample_Type__ID=$Sample->{$type} AND $type.Plate_Status = 'Active'",
            [ 'Left(External_Identifier,8) as Subject', "count(distinct $type.Plate_ID) as $type" ],
            "$condition Group by Left(External_Identifier,8) "
                . " Having Count(distinct $type.Plate_ID)/$Expected->{$type} < 1",
            -title       => "Missing $type Samples",
            -return_html => 1
        );

        $layers{$type} = $type_differences;
    }
    my $layered_B_differences = define_Layers( -layers => \%layers );
    $output .= '<h2>Sample Type Discrepencies</h2>' . $layered_B_differences;

    return $output;
}
###########################
sub bcg_overview {
##########################
    my $self = shift;
    my %args             = filter_input( \@_, -args=>'dbc,condition' );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $condition = $args{-condition};
    my $include_times    = $args{-include_times};
    my $source_condition = $args{-source_condition} || 1;
    my $plate_condition  = $args{-plate_condition} || 1;
    my $prefix           = $args{-prefix};
    my $debug            = $args{-debug} || 0;

    if ($prefix) { 
        $plate_condition .= " AND Plate.Plate_Label LIKE '$prefix%'"; 
        $source_condition .= " AND Patient_Identifier LIKE '$prefix%'";
    }
    
    my $layer = $args{-layer};    # ('Layer');
    
    my $page = section_heading('Breakdown Summary by Subject');
    
   if ($include_times) {
        $page .= $self->_compare_samples(
            -having           => "having count(DISTINCT Source_ID) = 7",
            -title            => 'Subjects Completed',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug,
            -auto_update      => 1
        );    ## auto-update data first time through... #
        $page .= $self->_compare_samples(
            -having           => "having count(DISTINCT Source_ID) > 7",
            -title            => 'Extra collected Samples (number in brackets indicates number converted to BCG tubes)',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug
        );
        $page .= $self->_compare_samples(
            -having           => "having count(DISTINCT Source_ID) < 7",
            -title            => 'Partially collected Samples',
            -include_times    => $include_times,
            -source_condition => $source_condition,
            -plate_condition  => $plate_condition,
            -debug            => $debug
        );
    }
    else {
        $page .= $self->_compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) = 7", -title => 'Subjects completed',          -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
        $page .= $self->_compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) > 7", -title => 'Extra collected Samples',     -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
        $page .= $self->_compare_numbers( $dbc, -having => "having count(DISTINCT Source_ID) < 7", -title => 'Partially collected Samples', -include_times => $include_times, -source_condition => $source_condition, -debug => $debug );
    }
    
    $page .= $self->SUPER::stats_overview(%args);
    return $page;
}

#
# Overview at sample level
#
#
########################
sub _compare_samples {
########################
    my $self = shift;
    my %args             = filter_input( \@_, -args => 'dbc,condition,title' );
    my $dbc              = $args{-dbc} || $self->{dbc};
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
        'Urine'             => 3,
        'Saliva'            => 1,
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

#
# Overview at subject level
#
#
#########################
sub _compare_numbers {
#########################
    my $self = shift;
    my %args             = filter_input( \@_, -args => 'dbc,condition,title' );
    my $dbc              = $args{-dbc} || $self->{dbc};
    my $source_condition = $args{-source_condition} || 1;
    my $title            = $args{-title};
    my $having           = $args{-having};
    my $debug            = $args{-debug};

    my $Expected = {
        'ACD Blood Vacuum Tube'  => 1,
        'SST Blood Vacuum Tube'  => 2,
        'EDTA Blood Vacuum Tube' => 3,
        'Urine Cup'              => 1,
        'Saliva' => 1,
    };

    my @expected = sort keys %$Expected;

    my @urine_only;

    use alDente::Stats_Table;

    my $Partial = alDente::Stats_Table->new( -title => $title );
    my @headers = ('Subject');

    my $group = 'GROUP BY Patient_Identifier';
    my @fields = ( 'Patient_Identifier as Subject', 'Received_Date', 'GROUP_CONCAT(Plate_Format_Type) as Formats', 'Group_CONCAT(Distinct Attribute_Value) as Collected', 'Group_Concat(Sample_ID) as Aliquoted');

    push @headers, 'Collected', 'Activated', @expected;

    $Partial->Set_Headers( \@headers );
    
    my ($collected_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' and Attribute_Name = 'collection_time'" );
    my %Subject_Data = $dbc->Table_retrieve(
        "Source, Plate_Format, Original_Source, Patient LEFT JOIN Sample ON Sample.FK_Source__ID=Source_ID LEFT JOIN Source_Attribute ON Source_Attribute.FK_Source__ID=Source_ID AND FK_Attribute__ID=$collected_attribute",
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
        
        my @aliquoted = split ',', $Subject_Data{Aliquoted}[$row];

        $row++;
        my $col = 3;    ## point to current column (prior to Format columns)

        my $count = int(@data);
        
        my (%Found, %Plated);
        foreach my $i (1..$count) {
            my $type = $data[$i-1];
            $Found{$type}++;
            if ( $aliquoted[$i-1] ) { $Plated{$type}++; }
        }

        my @row = ($subject);

        push @row, $collected, $time;
        foreach my $type (@expected) {
            $col++;
            my $found = $Found{$type} || '0';
            my $plated = $Plated{$type} || '0';
            
            if ($found != $plated) { $found = "$found [$plated]" }
            
            push @row, $found;

            my $expected = $Expected->{$type};
                
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

return 1;
