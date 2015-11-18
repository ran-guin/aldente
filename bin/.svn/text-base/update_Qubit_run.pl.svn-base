#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use Getopt::Long;
use Encode;

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use Qubit::Run_Analysis;

### Global variables
use vars qw($Connection $aldente_upload_dir $aldente_runmap_dir $project_dir $mirror_dir $archive_dir);
###################################

# if script itself is running elsewhere, quit
my $command           = "ps axw | grep 'update_Qubit_run.pl' | grep  -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v 'emacs'";
my $current_processes = `$command`;
if ($current_processes) {
    print "** already in process **\n";
    print "-> $current_processes\n";
    exit;
}

my ( $opt_user, $opt_dbase, $opt_host, $opt_password );
my $default_qubit_output_dir = $Configs{QUBIT_HOME_DIR};

#my $default_qubit_output_dir = "/home/tomz/home";

&GetOptions(
    'user=s'     => \$opt_user,
    'dbase=s'    => \$opt_dbase,
    'host=s'     => \$opt_host,
    'password=s' => \$opt_password,
);

&help_menu() if ( !( $opt_dbase && $opt_user && $opt_host ) );

my $condition = "where Run_Status = 'In Process' and Run_Type = 'Qubit_Run'";

my $dbc = SDB::DBIO->new(
    -dbase => $opt_dbase,
    -user  => $opt_user,
    -host  => $opt_host
);
$dbc->connect();

# search all pending runs
my %runs = $dbc->Table_retrieve(
    -table     => "Run",
    -fields    => [ 'Run_ID', 'Run_Type', 'Run_Directory' ],
    -condition => "$condition",
    -key       => 'Run_ID'
);

foreach my $run_id ( sort { $a <=> $b } keys %runs ) {
    my $run_type      = $runs{$run_id}->{'Run_Type'};
    my $run_directory = $runs{$run_id}->{'Run_Directory'};
    print "Processing Run (Run ID $run_id)...\n";

    ## Double check if the run is still in process
    my ($run_in_process) = $dbc->Table_find( 'Run', 'Run_ID', "WHERE Run_ID = $run_id AND Run_Status = 'In Process'" );

    if ($run_in_process) {
        my ($file) = $dbc->Table_find( 'Qubit_Run', 'Qubit_File_Name', "WHERE FK_Run__ID = $run_id" );

        if ($file) {
            my $find_command = "find  $default_qubit_output_dir/ -name $file";
            my @results = split "\n", try_system_command($find_command);

            if ( scalar(@results) < 1 ) {
                print "\t$file file does not exist for Qubit run $run_id. Skipping...\n";
            }
            elsif ( scalar(@results) == 1 ) {
                my $data = &parse_qubit_output( -dbc => $dbc, -file => "$results[0]" );
                if ($data) {
                    my $status = &save_qubit_output( -dbc => $dbc, -data => $data );

                    ## calculate and insert plate attribute Concentration_nM
                    &set_concentration( -dbc => $dbc, -data => $data );

                    if ( !$status ) {
                        Message("Error: problem inserting into database.");
                    }
                }
                else {
                    Message("Invalid Qubit output file $file");
                }
            }
            else {
                print "\tThere are more than one file for Qubit run $run_id. Skipping...\n";
            }
        }
        else {
            print "\tFile not specified for Qubit run $run_id. Skipping...\n";
        }
    }
    else {
        print "\tQubit run $run_id has been processed. Skipping...\n";
    }
}

#######################
# Method to parse output file from Qubit
#
# will be run by Cron job
# file name will be in the format of Run_ID.extension (e.g. 92341.xls)
#######################
sub parse_qubit_output {
#######################
    my %arg  = @_;
    my $file = $arg{-file};
    my %data;
    $data{file} = $file;
    Message("Error: File $file does not exist.") if ( !-e $file );
    require Spreadsheet::ParseExcel;
    my $book            = Spreadsheet::ParseExcel::Workbook->Parse($file);
    my @worksheet_array = @{ $book->{Worksheet} };
    my $sheet           = $worksheet_array[0];

    # determine the 1st row where the data table starts
    my %positions;
    my $data_row;

    for ( my $row = $sheet->{MinRow}; $row <= $sheet->{MaxRow}; $row++ ) {
        next unless ( $sheet->{Cells}[$row][ $sheet->{MinCol} ]->Value eq 'Run ID' );
        for ( my $col = $sheet->{MinCol}; $col <= $sheet->{MinCol} + 9; $col++ ) {
            if ( $sheet->{Cells}[$row][$col] ) {

                # find the column number for each field

                my $header = $sheet->{Cells}[$row][$col]->Value;
                if ( $header =~ /^Run ID$/i ) {
                    $positions{Run_ID} = $col;
                }
                elsif ( $header =~ /^Plate Number$/i ) {
                    $positions{Plate_Number} = $col;
                }
                elsif ( $header =~ /^Library Name$/i ) {
                    $positions{Library_Name} = $col;
                }
                elsif ( $header =~ /^Sample_ID$/i ) {
                    $positions{FK_Sample__ID} = $col;
                }
                elsif ( $header =~ /^Concentration in the Qubit/i ) {
                    $positions{Qubit_Concentration} = $col;
                }
                elsif ( $header =~ /^Concentration Units/i ) {
                    $positions{Qubit_Concentration_Units} = $col;
                }
                elsif ( $header =~ /ul used/i ) {
                    $positions{Quantity_Used} = $col;
                }
                elsif ( $header =~ /Dilution/i ) {
                    $positions{Dilution} = $col;
                }
                elsif ( $header =~ /Sample Concentration$/i ) {
                    $positions{Sample_Concentration} = $col;
                }
                elsif ( $header =~ /Sample Concentration Units/i ) {
                    $positions{Sample_Concentration_Units} = $col;
                }
            }
        }
        $data_row = $row;
        last;
    }

    # copy data to an array and handle empty cells
    my @cells;
    for ( my $row = $data_row + 1; $row <= $sheet->{MaxRow}; $row++ ) {
        for ( my $col = $sheet->{MinCol}; $col <= $sheet->{MinCol} + 9; $col++ ) {
            my $cell = $sheet->{Cells}[$row][$col];
            if ( defined $cell && defined $cell->Value ) {
                $cells[$row][$col] = $cell->Value;
                if ( $cells[$row][$col] =~ /^General$/i ) {
                    $cells[$row][$col] = $cell->{Val};
                }
                if ( $cells[$row][$col] =~ /Out of Range/i ) {
                    Message("Data not ready");
                    return;
                }
                ## TODO: will be changed to use the normalize string method
                $cells[$row][$col] = decode_utf8( $cells[$row][$col] );
                $cells[$row][$col] =~ s/\x{fffd}/u/;
            }
            else {
                Message("Empty data fields");
                return;
            }
        }
    }

    # read cell data
    my $i = 1;
    for ( my $row = $data_row + 1; $row <= $sheet->{MaxRow}; $row++ ) {
        if ( $cells[$row][ $positions{Run_ID} ] =~ /^Std/i ) {
            $i--;
            next;
        }
        $data{data}->{$i}->{Run_ID}                     = $cells[$row][ $positions{Run_ID} ];
        $data{data}->{$i}->{Plate_Number}               = $cells[$row][ $positions{Plate_Number} ];
        $data{data}->{$i}->{Library_Name}               = $cells[$row][ $positions{Library_Name} ];
        $data{data}->{$i}->{FK_Sample__ID}              = $cells[$row][ $positions{FK_Sample__ID} ];
        $data{data}->{$i}->{Qubit_Concentration}        = $cells[$row][ $positions{Qubit_Concentration} ];
        $data{data}->{$i}->{Qubit_Concentration_Units}  = $cells[$row][ $positions{Qubit_Concentration_Units} ];
        $data{data}->{$i}->{Quantity_Used}              = $cells[$row][ $positions{Quantity_Used} ];
        $data{data}->{$i}->{Quantity_Used_Units}        = 'ul';
        $data{data}->{$i}->{Dilution}                   = $cells[$row][ $positions{Dilution} ];
        $data{data}->{$i}->{Sample_Concentration}       = $cells[$row][ $positions{Sample_Concentration} ];
        $data{data}->{$i}->{Sample_Concentration_Units} = $cells[$row][ $positions{Sample_Concentration_Units} ];
        $i++;
    }

    return \%data;
}

#######################
# Method to populate DB with data from Qubit
#######################
sub save_qubit_output {
#######################
    my %arg     = @_;
    my $dataRef = $arg{-data};
    my $dbc     = $arg{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    ### create run analysis for eash sample in the run
    my @analysis_fields = qw(Run_Analysis_Started FK_Run__ID FK_Sample__ID);
    my %run_analysis;
    my $index   = 1;
    my $date    = date_time();
    my $run_ids = '';

    my @qubitread_fields = qw(Qubit_Run_Analysis_ID FK_Run_Analysis__ID FK_Sample__ID Qubit_Concentration Qubit_Concentration_Units  Quantity_Used Quantity_Used_Units Dilution Sample_Concentration Sample_Concentration_Units);

    foreach my $field ( keys %{ $dataRef->{data} } ) {
        my $run_id = $dataRef->{data}->{$index}->{Run_ID};
        my ($run_analysis_id) = $dbc->Table_find( "Run_Analysis", "Run_Analysis_ID", "WHERE FK_Run__ID = $run_id" );

        my $run_analysis_obj = Qubit::Run_Analysis->new( -dbc => $dbc, -run_analysis_id => $run_analysis_id );
        my $run_obj = alDente::Run->new( -dbc => $dbc, -id => $run_id );

        if ( !$run_analysis_id ) {

            #Start Run_Analysis
            my ($analysis_pipeline) = $dbc->Table_find( "Pipeline", "Pipeline_ID", "WHERE Pipeline_Name = 'Qubit Analysis'" );
            $run_analysis_id = $run_analysis_obj->start_run_analysis( -run_id => $run_id, -analysis_pipeline_id => $analysis_pipeline, -run_analysis_type => 'Primary' );
            ## set the run status to analyzing
            $run_obj->update( -fields => ['Run_Status'], -values => ['Analyzing'] );
        }
        else {

            #retrieve run_analysis_id
            my ($analyzed) = $dbc->Table_find( "Run", "Run_ID", "WHERE Run_ID = $run_id and Run_Status = 'Analyzed'" );
            if ($analyzed) {
                Message("Data for run $run_id already uploaded");
                $index++;
                next;
            }
        }

        ## Upload Qubit data for the run
        my %qubit_read;

        $qubit_read{1} = [
            '',                                                      $run_analysis_id,                            $dataRef->{data}->{$index}->{FK_Sample__ID},       $dataRef->{data}->{$index}->{Qubit_Concentration},
            $dataRef->{data}->{$index}->{Qubit_Concentration_Units}, $dataRef->{data}->{$index}->{Quantity_Used}, $dataRef->{data}->{$index}->{Quantity_Used_Units}, $dataRef->{data}->{$index}->{Dilution},
            $dataRef->{data}->{$index}->{Sample_Concentration},      $dataRef->{data}->{$index}->{Sample_Concentration_Units}
        ];

        my $qubitanalysis_ids = $dbc->SDB::DBIO::smart_append(
            -tables    => 'Qubit_Run_Analysis',
            -fields    => \@qubitread_fields,
            -values    => \%qubit_read,
            -autoquote => 1
        );

        if ( $$qubitanalysis_ids{'Qubit_Run_Analysis'} ) {    # DB insert successful
                                                              # change Run_Status to Analyzed

            #Running and finished analysis
            $run_analysis_obj->run_analysis();
            $run_analysis_obj->finish_run_analysis( -run_analysis_id => $run_analysis_id, -run_analysis_status => 'Analyzed' );
            $dbc->Table_update( "Run_Analysis", "Current_Analysis", "YES", "WHERE Run_Analysis_ID = $run_analysis_id", -autoquote => 1 );
            $dbc->Table_update( "Qubit_Run", "Qubit_Run_Finished", &date_time(), "WHERE FK_Run__ID = $run_id", -autoquote => 1 );
            $run_obj->update( -fields => ['Run_Status'], -values => ['Analyzed'] );
        }
        $index++;
    }

    return 1;
}

######################
# Calculate concentration value and set the plate attribute Concentration_nM
######################
sub set_concentration {
######################
    my %arg  = @_;
    my $dbc  = $arg{-dbc};
    my $data = $arg{-data};

    my ($attr_id_bp_size) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "Where Attribute_Name = 'Avg_DNA_bp_size' and Attribute_Class = 'Plate' " );
    return 0 if ( !$attr_id_bp_size || !$data->{data} );

    my @fields = ( 'FK_Plate__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' );
    my ($attr_id_conc_nM) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "Where Attribute_Name = 'Concentration_nM' and Attribute_Class = 'Plate' " );
    my $user_id  = 141;           # alDente admin
    my $datetime = date_time();
    my %errors;
    my %values;
    my $index       = 1;
    my $value_index = 0;
    foreach my $index ( keys %{ $data->{data} } ) {
        my $run_id   = $data->{data}{$index}{Run_ID};
        my $plate_id = $data->{data}{$index}{Plate_Number};
        my ($bp_size) = $dbc->Table_find( 'Plate_Attribute', 'Attribute_Value', "WHERE FK_Plate__ID = $plate_id and FK_Attribute__ID = $attr_id_bp_size" );
        if ($bp_size) {
            if ( $data->{data}{$index}{Qubit_Concentration_Units} =~ /^(\w+)\/(\w+)$/ ) {
                my $unit1 = $1;
                my $unit2 = $2;
                my ( $qty1, $t_unit1, $error1 ) = RGTools::Conversion::convert_units( $data->{data}{$index}{Qubit_Concentration}, $unit1, 'ng', 'quiet' );
                my ( $qty2, $t_unit2, $error2 ) = RGTools::Conversion::convert_units( 1, $unit2, 'ul', 'quiet' );
                if ( !$error1 && !$error2 ) {
                    my $conc_nM = ( $qty1 / $qty2 ) * 1000000 / ( $bp_size * 660 );
                    $values{ ++$value_index } = [ $plate_id, $attr_id_conc_nM, $conc_nM, $user_id, $datetime ];
                }
                else {
                    $errors{$run_id}{Plate_ID} = $plate_id;
                    $errors{$run_id}{message}  = "Error when converting units from $data->{data}{$index}{Qubit_Concentration_Units} to ng/ul";
                }
            }
            else {
                $errors{$run_id}{Plate_ID} = $plate_id;
                $errors{$run_id}{message}  = "Unexpected Qubit_Concentration_Units '$data->{data}{$index}{Qubit_Concentration_Units}'";
            }
        }
        else {
            $errors{$run_id}{Plate_ID} = $plate_id;
            $errors{$run_id}{message}  = "Attribute Avg_DNA_bp_size missing";
        }
    }

    my $new_ids = $dbc->SDB::DBIO::smart_append( -tables => 'Plate_Attribute', -fields => \@fields, -values => \%values, -autoquote => 1 );
    my $newids_count = int( @{ $new_ids->{Plate_Attribute}{newids} } );
    if ($newids_count) {
        print "$newids_count Plate_Attribute Concentration_nM have been inserted.\n\n";
    }
    if ( int( keys %errors ) ) {
        print int( keys %errors ), " runs had errors when setting Concentration_nM:\n";
        print "Run_ID\tPlate_ID\tMessages\n";
        foreach my $run ( keys %errors ) {
            print "$run\t$errors{$run}{Plate_ID}\t$errors{$run}{message}\n";
        }
    }
    return $newids_count;
}

sub help_menu {
    print "Run script like this:\n\n";
    print "$0\n";
    print "  \t-dbase (e.g. sequence)\n";
    print "  \t-user  (e.g. tomz)\n";
    print "  \t-password\n";
    print "  \t-host  (e.g. lims01)\n";
    exit(0);
}
