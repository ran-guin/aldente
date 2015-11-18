################################################################################
# BioanalyzerRun.pm
#
# This module handles Bioanalyzer(Agilent) functions
#
###############################################################################
package alDente::BioanalyzerRun;

##############################
# superclasses               #
##############################
@ISA = qw(SDB::DB_Object Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw($bioanalyzer_file_ext $bioanalyzer_img_ext);
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use CGI qw(:standard);
use RGTools::Barcode;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use alDente::Barcoding;
use alDente::Run;
use alDente::Container;
use alDente::Library_Plate_Set;
use alDente::Rack qw(Move_Racks);
use alDente::Well;
use RGTools::HTML_Table;
use SDB::HTML;
use Data::Dumper;
use RGTools::RGIO;
use RGTools::Conversion qw(convert_date);
##############################
# global_vars                #
##############################
use vars qw($project_dir $Sess);
use vars qw($testing $current_plates);
use vars qw(%Settings %User_Setting %Department_Settings %Defaults %Login $URL_path %Tool_Tips @libraries $Connection $Sess $uploads_dir $URL_temp_dir $URL_domain);
use vars qw($bioanalyzer_file_ext $bioanalyzer_img_ext);

my $q = new CGI;
##############################
# modular_vars               #
##############################

##############################
# constants                  #
##############################
my $local_dir    = "$uploads_dir/BioanalyzerRun";    # where processed files are located
my $download_dir = $URL_temp_dir;                    # temp directory to store HTML files
my ($folder_path) = $download_dir =~ /(dynamic.+)/;
my $HTML_path = $URL_domain . "/$folder_path/";      # URL for files
$bioanalyzer_file_ext = ".csv";
$bioanalyzer_img_ext  = ".bmp";
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################
sub new {
#######################
    my $this = shift;
    my %args = @_;

    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $encoded    = $args{-encoded} || 0;
    my $attributes = $args{-attributes};
    my $tables     = $args{-tables} || 'BioanalyzerRun';

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables, -encoded => $encoded );
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->add_tables('Plate,Run');
    $self->{dbc} = $dbc;
    if ($id) {
        $self->{id} = $id;    ## list of current plate_ids
        $self->primary_value( -table => 'BioanalyzerRun', -value => $id );    ## same thing as above..
        $self->load_Object();
        $self->{run_id}   = $self->value('BioanalyzerRun.FK_Run__ID');
        $self->{plate_id} = $self->value('Run.FK_Plate__ID');
    }
    elsif ($attributes) {
        $self->add_Record( -attributes => $attributes );
    }

    return $self;
}

#######################
sub load_Object {
#######################
    #
    # Load Plate information into attributes from Database
    #
    my $self = shift;
    my %args = @_;

    my $scope    = $args{-scope}    || '';
    my $plate_id = $args{-plate_id} || $self->{plate_id};

    unless ( $self->primary_value( -table => 'BioanalyzerRun' ) ) { Message("Warning:GP not defined") }
    $self->SUPER::load_Object();

    $self->{plate_id} = $self->value('Run.FK_Plate__ID');

    return 1;
}

#######################
# Method to parse out the CGI Params. (Execution will reach here if GeneExpression_BioanalyzerRun is one of the params)
#
##################
sub request_broker {
##################

    my %args = @_;
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    if ( param('Request_Bioanalyzer_Runs') ) {
        my $bioanalyzer_plate   = param('FK_Plate__ID');
        my $bioanalyzer_scanner = param('FKScanner_Equipment__ID');
        alDente::BioanalyzerRun::bioanalyzer_request_form( -dbc => $dbc, -plate => $bioanalyzer_plate, -scanner => $bioanalyzer_scanner );
    }
    elsif ( param('Create_Bioanalyzer_Runs') ) {
        my $index = 0;
        my %bioanalyzer_request;
        my @dilutions = param("Dilution");

        my @plates;
        while ( defined param( "Pla" . ++$index ) ) {
            push( @plates, param("Pla$index") );
            $bioanalyzer_request{$index}{Dilution} = $dilutions[ $index - 1 ];
            $bioanalyzer_request{$index}{Comments} = param("Comments$index");
        }
        my $run_ids = alDente::BioanalyzerRun::create_bioanalyzerrun( -dbc => $dbc, -bioanalyzer_run_info => \%bioanalyzer_request );
        &alDente::BioanalyzerRun::start_bioanalyzerruns( -dbc => $dbc, -plates => \@plates, -runs => $run_ids );
        &alDente::BioanalyzerRun::associate_scanner( -dbc => $dbc, -run_id => $run_ids, -scanner_id => param('Scanner') );
        my $message = "<br>Master Run_ID is $$run_ids[0]<br><br>Please save data as $$run_ids[0]$bioanalyzer_file_ext<br>Save electropherograms as $$run_ids[0]" . "_well$bioanalyzer_img_ext (";
        for ( my $i = 1; $i <= @$run_ids; $i++ ) {
            $message .= "$$run_ids[0]" . "_$i$bioanalyzer_img_ext,";
        }
        $message .= ")<br>";
        Message($message);
    }
    elsif ( param('bioanalyzer_home_page') ) {

        require alDente::View;
        alDente::View::request_broker( -title => 'Bioanalyzer Summary' );
    }
    else {
        Message("No Params found :(");
    }
}

######################
# Method to prompt the user for entering BioanalyzerRun initiation parameters
#
# User can enter comments for each sample / run
#
######################
sub bioanalyzer_request_form {
######################
    my %args    = @_;
    my @scanner = $args{-scanner} =~ /\d+/g;
    my @plates  = $args{-plate} =~ /\d+/g;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $field_size          = 12;
    my $chip_max_sample_num = 12;

    # input error checking
    my @words = $args{-scanner} =~ /\D+/g;
    foreach (@words) {
        $dbc->error("Unknown barcode type $_ for scanner.  Only \'equ\' allowed") if ( $_ !~ /^equ$/i && $_ ne ',' );
    }
    @words = $args{-plate} =~ /\D+/g;
    foreach (@words) {
        $dbc->error("Unknown barcode type $_ for plates.  Only \'pla\' allowed") if ( $_ !~ /^pla$/i && $_ ne ',' );
    }
    $dbc->error("User must define one and only one scanner") if ( scalar(@scanner) != 1 );
    $dbc->error("Number of plates must be between 1 and $chip_max_sample_num") if ( scalar(@plates) < 1 || scalar(@plates) > $chip_max_sample_num );

    my $req = HTML_Table->new( -title => 'Bioanalyzer Run Request' );
    $req->Set_Headers( [ 'Well', 'Tube', 'Dilution', 'Comments' ] );

    for ( my $i = 1; $i <= scalar(@plates); $i++ ) {
        my @row;
        push( @row, $i );
        push( @row, $dbc->get_FK_info( 'FK_Plate__ID', $plates[ $i - 1 ] ) );
        push(
            @row,
            Show_Tool_Tip(
                textfield(
                    -name  => "Dilution",
                    -size  => $field_size,
                    -force => 1,
                    -value => '1',
                    onBlur => "
var index = parseInt('$i') - 1;
var diln = this.form.Dilution[index].value;
if(! diln.match(/^\\d+[\/\.]\\d+\$/) && ! diln.match(/^\\d+\$/)){
  alert('You have entered an unrecognizable ratio or number');
}
else if(diln.match(/^[\\d\.]+\$/)){
  var number=parseFloat(diln);
  if(number > 1.0){
    alert('Dilution must be smaller or equal to 1');
  }
}
else if(diln.match(/^\\d+[\/]\\d+\$/)){
  diln = /^\(\\d+\)[\/]\(\\d+\)\$/();
  var number1=parseInt(diln[1]);
  var number2=parseInt(diln[2]);
  if(number1 > number2){
    alert('Dilution must be smaller or equal to 1');
  }
  if(number2 <= 0){
    alert('Illegal denominator');
  }
}
"
                ),
                'Enter dilution ratio (e.g. 1/3, 0.5)'
            )
        );
        push( @row, Show_Tool_Tip( textfield( -name => "Comments$i", -size => $field_size, -force => 1 ), 'Enter comments (optional)' ) );
        push( @row, hidden( -name => "Pla$i", -value => $plates[ $i - 1 ], -force => 1 ) );
        $req->Set_Row( \@row );
    }

    $req->Set_Row( [ reset( -class => 'Std' ), submit( -name => 'Create_Bioanalyzer_Runs', -value => 'Create', -class => 'Action' ) ] );

    print alDente::Form::start_alDente_form( $dbc, 'bioanalyzer_run_form', $dbc->homelink() ) . hidden( -name => 'Lib_Construction_BioanalyzerRun' ) . hidden( -name => 'Scanner', -value => $scanner[0] ) . $req->Printout(0) . "</form>";
}

##########################################
# Create single or multiple bioanalyzer runs
#
# Method to instantiate "empty" Bioanalyzer Runs (ie do not have any plates associated with them)
#
# request_list is a hash, with keys starting from 1.
#
# An example for an input parameter:
#
# <snip>
# Example:
# my %bioanalyzer_run_info = (
#  '1' => {
#                'Comments' => 'comment1'
#              },
#  '2' => {
#                'Comments' => 'comment2'
#              }
#);
#
#     my $run = alDente::BioanalyzerRun->new(-dbc=>$dbc);
#     my $run_id = alDente::BioanalyzerRun::create_bioanalyzerrun(-bionaalyzer_run_info=>\%bioanalyzer_run_info);
# </snip>
#
######################
sub create_bioanalyzerrun {
######################
    my %args                 = @_;
    my $dbc                  = $args{-dbc};
    my %bioanalyzer_run_info = %{ $args{-bioanalyzer_run_info} };
    my %bioanalyzer_run;

    # create new run batch
    my @runbatch_fields = qw(FK_Employee__ID FK_Equipment__ID RunBatch_RequestDateTime);
    my ($tbd_equipment) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_name='TBD'" );
    my ($tbd_employee)  = $dbc->Table_find( 'Employee',  'Employee_ID',  "WHERE Employee_Name='TBD Employee'" );
    my $now             = &date_time();
    my %runbatch;
    $runbatch{1} = [ $tbd_employee, $tbd_equipment, $now ];

    my $runbatch_id = $dbc->smart_append(
        -tables    => 'RunBatch',
        -fields    => \@runbatch_fields,
        -values    => \%runbatch,
        -autoquote => 1
    );
    my @runbatch_id = @{ $runbatch_id->{RunBatch}->{newids} };
    if ( !@runbatch_id ) {
        Message("Error: Problem creating RunBatch");
        print HTML_Dump( \@runbatch_fields, \%runbatch );
        Call_Stack();
        return 0;
    }

    # create new runs and bioanalyzer runs
    my @run_fields            = qw(FK_RunBatch__ID Run_Type Run_Comments Run_Test_Status Run_Status Run_Directory FKPosition_Rack__ID);
    my @bioanalyzerrun_fields = qw(Dilution_Factor);
    my @fields                = ( @run_fields, @bioanalyzerrun_fields );
    foreach my $key ( sort { $a <=> $b } keys %bioanalyzer_run_info ) {
        my $test_status            = $bioanalyzer_run_info{$key}->{Test_Status} || 'NULL';
        my $bioanalyzer_comments   = $bioanalyzer_run_info{$key}->{Comments}    || 'NULL';
        my $sample_dilution_factor = $bioanalyzer_run_info{$key}->{Dilution}    || '1';
        $bioanalyzer_run{$key} = [ $runbatch_id[0], 'BioanalyzerRun', $bioanalyzer_comments, $test_status, 'Not Applicable', 'NULL', $rack, $sample_dilution_factor ];
    }

    my $bioanalyzerrun_ids = $dbc->smart_append(
        -tables    => 'Run,BioanalyzerRun',
        -fields    => \@fields,
        -values    => \%bioanalyzer_run,
        -autoquote => 1
    );

    my @bioanalyzerrun_ids = @{ $bioanalyzerrun_ids->{BioanalyzerRun}->{newids} };
    my @run_ids            = @{ $bioanalyzerrun_ids->{Run}->{newids} };

    if (@bioanalyzerrun_ids) {
        my $new_runs = join( ',', @run_ids );
        Message( "Created Run(s): " . &Link_To( $dbc->config('homelink'), $new_runs, "&Info=1&TableName=Run&Field=Run_ID&Like=$new_runs" ) . '<BR>' );
    }
    else {
        Message("Error: Problems appending");
        print HTML_Dump( \@fields, \%bioanalyzer_run );
        Call_Stack();
        return 0;
    }

    # create new MultiPlate_Run
    my @multiplate_run_fields = qw(FKMaster_Run__ID FK_Run__ID);
    my %multiplate_run;
    foreach my $key ( sort { $a <=> $b } keys %bioanalyzer_run_info ) {
        $multiplate_run{$key} = [ $run_ids[0], $run_ids[ $key - 1 ] ];
    }
    my $multiplate_run_ids = $dbc->smart_append(
        -tables    => 'MultiPlate_Run',
        -fields    => \@multiplate_run_fields,
        -values    => \%multiplate_run,
        -autoquote => 1
    );
    my @multiplate_run_ids = @{ $multiplate_run_ids->{MultiPlate_Run}->{newids} };
    if ( !@multiplate_run_ids ) {
        Message("Error: Problems creating MultiPlate_Run");
        print HTML_Dump( \@multiplate_run_ids, \%multiplate_run );
        Call_Stack();
        return 0;
    }

    # print barcodes
    foreach my $run (@run_ids) {

        #        &alDente::Barcoding::PrintBarcode($dbc,'Run',$run);
    }

    return \@run_ids;
}

########################################################
#
# Method to Start the Bioanalyzer Runs (ie creation & association with Runs)
#
# <snip>
#     alDente::BioanalyzerRun::start_bioanalyzerruns(-plates=>\@plate_ids, -runs=>\@run_ids);
# </snip>
#
###################
sub start_bioanalyzerruns {
###################
    my %args = &filter_input( \@_, -args => 'plates,runs' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id     = $dbc->get_local('user_id');

    if ( $args{ERRORS} ) { Message("Error: $args{ERRORS}") }

    my $plates = Cast_List( -list => $args{-plates}, -to => 'string' );
    my @runs   = Cast_List( -list => $args{-runs},   -to => 'array' );
    my $quiet  = $args{-quiet};
    my @plates = @{ $args{-plates} };
    my $runs = join( ',', @runs );

    if ( scalar(@runs) != scalar(@plates) ) {
        print HTML_Dump( \@runs, $plates );
        Message("Error: Invalid parameters");
        return 0;
    }

    if ( _run_started( -runs => \@runs ) ) {
        Message("Error: Some of the runs have already been started");
        return 0;
    }

    ### Retrieve table information
    my %bioanalyzer_hash = $dbc->Table_retrieve( "Run,BioanalyzerRun,RunBatch", [ 'Run_ID', 'RunBatch_ID', 'Run_Directory' ], "WHERE RunBatch_ID = FK_RunBatch__ID and Run_ID=FK_Run__ID AND Run_ID IN ($runs)" );
    my ( @run_ids, @run_batches );

    if ( $bioanalyzer_hash{Run_ID} ) {
        @run_ids     = @{ $bioanalyzer_hash{Run_ID} };
        @run_batches = @{ $bioanalyzer_hash{RunBatch_ID} };
    }
    else {
        Message("Error: Invalid Runs ($runs)");
        return 0;
    }

    ### Plate Format Check
    my @plate_formats = $dbc->Table_find( 'Plate', 'Plate_ID,Plate_Size,FK_Library__Name,Plate_Number', "WHERE Plate_ID IN ($plates) AND Plate_Size='1-well'" );
    if ( int(@plate_formats) != int(@plates) ) {
        Message("Error: All the plates must be in 1-well (tube) format");
        return 0;
    }

    # branch
    # get Run_Directory for Run here
    #    my ($run_dirs,$error) = &alDente::Run::_nextname(-plate_ids=>$plates,-check_branch=>1);

    #    if($error) {
    #        Message("Error: Problem starting Bioanalyzer Runs");
    #        return 0;
    #    }
    # for now, generate Run_Directory here...
    # Run_Directory should be LibraryName-PlateNumber.Branch.Version

    my %run_dirs;
    foreach (@plate_formats) {
        my ( $plate_id, $plate_size, $library, $plate_num ) = split( /,/, $_ );

        my ( $data_subdirectorys, $error ) = &alDente::Run::_nextname( -dbc => $dbc, -plate_ids => $plate_id, -suffix => ['BIOAN'] );
        my $run_dir = $data_subdirectorys->[0];

        $run_dirs{$plate_id} = $run_dir;

    }

    # update Run table
    my $ok    = 1;
    my $now   = &date_time();
    my $index = -1;
    while ( $plates[ ++$index ] ) {
        $ok &&= $dbc->Table_update_array( 'Run', [ 'FK_Plate__ID', 'Run_DateTime', 'Run_Directory', 'Run_Status' ], [ $plates[$index], $now, $run_dirs{ $plates[$index] }, 'In Process' ], "WHERE Run_ID = $run_ids[$index]", -autoquote => 1 );
    }

    # update RunBatch table
    $ok &&= $dbc->Table_update_array( 'RunBatch', ['FK_Employee__ID'], [$user_id], "WHERE RunBatch_ID = $run_batches[0]", -autoquote => 1 );

    unless ($ok) {
        Message("Warning: Not all records updated!");
    }
}

sub _run_started {
##################
    my %args = &filter_input( \@_, -args => 'runs' );
    my $runs = Cast_List( -list => $args{-runs}, -to => 'string' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @runs = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID IN ($runs) AND FK_Plate__ID IS NOT NULL" );

    if (@runs) {
        return 1;
    }
    else {
        return 0;
    }
}

######################
#
# Associate a Bioanalyzer Run with a Bioanalyzer
#
#
######################
sub associate_scanner {
######################
    my %args = &filter_input( \@_, -args => 'run_id,scanner_id', -mandatory => 'run_id,scanner_id' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $scanner_id = $args{-scanner_id};
    my $run_id     = Cast_List( -list => $args{-run_id}, -to => 'string' );

    my $ok = $dbc->Table_update_array(
        -table     => 'BioanalyzerRun',
        -fields    => ['FKScanner_Equipment__ID'],
        -values    => [$scanner_id],
        -condition => "WHERE FK_Run__ID in ($run_id)",
        -autoquote => 1
    );

    if ($ok) {
        Message("Updated $ok BioanalyzerRun Records");
    }
    else {
        Message("Warning: 0 records updated.  Bioanalyzer might already be set!");
        return 0;
    }
}

#######################
# Parse the Bioanalyzer .csv data file
#######################
sub parse_bioanalyzer_output {
#######################
    my %arg = @_;

    my $file = $arg{-file};
    my %results;
    my %samples;
    my $samples = \%samples;
    my $run_num;
    my $run_num_count = 0;

    open( READ, "$file" ) || Message("$0\tError: cannot open file $file");
    $results{-csv_file} = $file;
    while (<READ>) {
        chomp;
        s/\r//;    # remove Windows endline character
        if ( $_ =~ /Data File Name/i ) {
            $_ =~ /Data File Name,([\w\s\d\/,\.\#-]+)/i;
            $results{-xad_file} = $1;
        }
        elsif ( $_ =~ /Assay Name/i ) {
            $_ =~ /Assay Name,(.+)/i;
            $results{-assay_name} = $1;
        }
        elsif ( $_ =~ /Assay Name/i ) {
            $_ =~ /Assay Name,(.+)/i;
            $results{-assay_name} = $1;
        }
        elsif ( $_ =~ /Assay Path/i ) {
            $_ =~ /Assay Path,(.+)/i;
            $results{-assay_path} = $1;
        }
        elsif ( $_ =~ /Assay Title/i ) {
            $_ =~ /Assay Title,(.+)/i;
            $results{-assay_title} = $1;
        }
        elsif ( $_ =~ /Date Created/i ) {
            $_ =~ /Date Created,(.+)/i;
            my $date = convert_date($1);
            $results{-date} = $date;
        }
        elsif ( $_ =~ /Number of Samples Run/i ) {
            $_ =~ /Number of Samples Run,(\d+)/i;
            $run_num = $1;
        }
        elsif ( $_ =~ /Sample Name/i ) {
            $_ =~ /Sample Name,(.+)/i;
            my $sample_name = $1;
            next if ( $sample_name =~ /Ladder/i );
            $run_num_count++;
            $samples->{$run_num_count}->{name} = $sample_name;

            while (<READ>) {
                chomp;
                if ( $_ =~ /RNA Concentration/ ) {
                    $_ =~ /RNA Concentration:.+?([\.\d]+).+?(\w+)\/([µ\w]+)/;
                    $samples->{$run_num_count}->{RNA_conc} = $1;
                    my $conc_unit1 = $2;
                    my $conc_unit2 = $3;
                    $conc_unit2 =~ s/\W/u/g;    # µ character replaced by u
                    $samples->{$run_num_count}->{conc_unit} = $conc_unit1 . "/" . $conc_unit2;
                }
                elsif ( $_ =~ /RNA Integrity Number/ ) {
                    $_ =~ /RNA Integrity Number \(RIN\):.+?([\w\.\d\/]+)/;
                    $samples->{$run_num_count}->{RIN} = $1;
                    last;
                }
            }
        }
    }
    close(READ);
    $results{-sample} = $samples;
    Message("$0\tError: inconsistent number of samples -- file: $run_num, recorded: $run_num_count") if $run_num != $run_num_count;

    return \%results;
}

#######################
# Method to populate DB with data from Bioanalyzer
#
# *** Assume that 16-well chip used by Bioanalyzer (Agilent) is NOT tracked.
# 12 samples means 12 runs with in the same run batch
#######################
sub populate_bioanalyzer_output {
#######################
    my %args    = @_;
    my $dataRef = $args{-data};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $file    = $dataRef->{-csv_file};
    Message("$0\tError: incorrect file name format $file") if $file !~ /\/?\d+\./;
    $file =~ /\/?(\d+)\./;
    my $run_id = $1;    # this is the master run id of the runs in the run batch

    ### find all run ids witht he same master run id from table MultiPlate_Run
    ### the order of the run id corresponds to the order of the well, starting from 1
    my @runs = $dbc->Table_find( "MultiPlate_Run,Run,Plate_Sample,Plate",
        "FK_Run__ID,FK_Sample__ID", "where Plate_ID = FK_Plate__ID and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID and FKMaster_Run__ID = $run_id and FK_Run__ID = Run_ID and Plate_Size = '1-well' order by Run_ID" );

    my %runs;
    my $runs = \%runs;
    my $well = 1;
    my @run_ids;
    foreach (@runs) {
        my ( $run_id, $sample_id ) = split( /,/, $_ );
        $runs->{$well}->{'run_id'}    = $run_id;
        $runs->{$well}->{'sample_id'} = $sample_id;
        push( @run_ids, $run_id );
        $well++;
    }

    my $key = 1;
    my %bioanalyzer_read;
    foreach my $well ( sort { $a <=> $b } keys %{ $dataRef->{-sample} } ) {
        $bioanalyzer_read{$key} = [
            $runs->{$well}->{'run_id'},                    $runs->{$well}->{'sample_id'},           $well, $dataRef->{'-sample'}->{$well}->{'RNA_conc'},
            $dataRef->{'-sample'}->{$well}->{'conc_unit'}, $dataRef->{'-sample'}->{$well}->{'RIN'}, $dataRef->{'-sample'}->{$well}->{'name'}
        ];
        $key++;
    }

    ### adding BioanalyzerRead entries
    my @bioanalyzerread_fields = qw(FK_Run__ID FK_Sample__ID Well RNA_DNA_Concentration RNA_DNA_Concentration_Unit RNA_DNA_Integrity_Number Sample_Comment);

    my $bioanalyzer_ids = $dbc->SDB::DBIO::smart_append(
        -tables    => 'BioanalyzerRead',
        -fields    => \@bioanalyzerread_fields,
        -values    => \%bioanalyzer_read,
        -autoquote => 1
    );

    ### adding BioanalyzerAnalysis entry
    my %bioanalyzer_analysis;

    my @bioanalyzeranalysis_fields = qw(FK_Run__ID File_Name);

    $key = 1;
    foreach (@run_ids) {
        $bioanalyzer_analysis{$key} = [ $_, $dataRef->{'-xad_file'} ];
        $key++;
    }

    my $bioanalyzeranalysis_ids = $dbc->SDB::DBIO::smart_append(
        -tables    => 'BioanalyzerAnalysis',
        -fields    => \@bioanalyzeranalysis_fields,
        -values    => \%bioanalyzer_analysis,
        -autoquote => 1
    );

    if ( $$bioanalyzeranalysis_ids{'BioanalyzerAnalysis'} ) {    # DB insert successful
                                                                 # change Run_Status to Analyzed
        my $run_ids = "(" . join( ",", @run_ids ) . ")";
        $dbc->SDB::DBIO::Table_update(
            -table     => 'Run',
            -fields    => 'Run_Status',
            -values    => '\'Analyzed\'',
            -condition => "where Run_ID in $run_ids"
        );
        return 1;
    }
    return 0;
}

##############################
# Display data collected from a run
sub display_run_data {
##############################
    my %args         = @_;
    my $run_id       = $args{-run_id};                                                                  # run id of one sample
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $header_color = '3366FF';

    # find master run id of the particular run id
    my ($master_run_id) = $dbc->Table_find( 'MultiPlate_Run', 'FKMaster_Run__ID', "where FK_Run__ID = $run_id" );

    # find the well of the particular run id's plate
    my ($well) = $dbc->Table_find( 'Run,BioanalyzerRead', 'Well', "where FK_Run__ID = Run_ID and Run_ID = $run_id" );

    # find all run ids associated with the master run id and find data for each run in the run batch
    my @display_fields = qw(Sample_Name RNA_DNA_Concentration RNA_DNA_Concentration_Unit RNA_DNA_Integrity_Number Dilution_Factor);
    my @fields         = qw(Well Run_ID Sample_Comment BioanalyzerRun_ID Run_Directory File_Name);
    @fields = ( @fields, @display_fields );
    my $fields = join( ",", @fields );
    my %data = $dbc->Table_retrieve(
        -table     => "MultiPlate_Run,Run,BioanalyzerRun left join BioanalyzerRead on BioanalyzerRead.FK_Run__ID = Run_ID left join Sample on Sample_ID = FK_Sample__ID left join BioanalyzerAnalysis on BioanalyzerAnalysis.FK_Run__ID = Run_ID ",
        -fields    => \@fields,
        -condition => "where FKMaster_Run__ID = $master_run_id and MultiPlate_Run.FK_Run__ID = Run_ID and BioanalyzerRun.FK_Run__ID = Run_ID",
        -key       => 'Well'
    );

    my $allTables = "<table cellpadding=0><TR><TD valign=top width=100%>";

    # file download
    # file for all batch runs is stored only under the run directory of the master run (well 1)
    my $file          = $master_run_id . $bioanalyzer_file_ext;
    my $local_file    = "$local_dir/$data{1}->{'Run_Directory'}/$file";
    my $download_file = "$download_dir/$file";
    `cp $local_file $download_file`;
    my $html_file = $HTML_path . $file;

    # display data for the particular sample
    my $table = HTML_Table->new( -title => 'Run Results for BioanalyzerRun Run ID ' . $run_id );
    _print_display_run_data_row( -dbc => $dbc, -self => $table, -data => \%data, -well => $well, -run_id => $master_run_id, -display_fields => \@display_fields );
    $allTables .= $table->Printout(0) . "<BR><BR><BR><BR><BR>";

    $table = HTML_Table->new( -title => 'Sample Results Information for All Samples on the Same Bioanalyzer Chip (Master Run_ID: ' . $master_run_id . ")" );
    $table->Set_Headers( [ &Link_To( $html_file, "Download $bioanalyzer_file_ext File", undef, 'red' ), "Number of samples on Bioanalyzer chip: " . scalar( keys %data ) ] );

    # data from BioanalyzerRead table
    foreach my $well ( sort { $a <=> $b } keys %data ) {
        _print_display_run_data_row( -dbc => $dbc, -self => $table, -data => \%data, -well => $well, -run_id => $master_run_id, -display_fields => \@display_fields );
    }
    $allTables .= $table->Printout(0) . "</TD></table>";

    print alDente::Form::start_alDente_form( $dbc, 'BioanalyzerRun_result', $dbc->homelink() ) . hidden( -name => 'GeneExpression_BioanalyzerRun' ) . $allTables . "</form>";
    return 1;
}

sub _print_display_run_data_row {
    my %args           = @_;
    my $table          = $args{-self};
    my %data           = %{ $args{-data} };
    my $well           = $args{-well};
    my $run_id         = $args{-run_id};
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @display_fields = @{ $args{-display_fields} };

    ### data for each well sample
    # assay data
    my $file = $data{$well}->{'File_Name'};
    $file =~ /(RNA\#\d+)_([a-zA-Z0-9\-\s]+)_/;
    @display_fields = ( 'Assay Number', 'Assay Type', @display_fields );
    $data{$well}->{'Assay Number'} = $1;
    $data{$well}->{'Assay Type'}   = $2;

    # standard data
    my $datatable = HTML_Table->new();
    $datatable->Set_Headers( [ "Well " . $well, $data{$well}->{'Sample_Comment'} ] );
    my @row;
    foreach my $field (@display_fields) {
        push( @row, $field );
        push( @row, $data{$well}->{$field} );
        $datatable->Set_Row( \@row );
        @row = ();
    }

    # calculate undiluted RNA conc.
    my $dilution_factor    = $data{$well}->{'Dilution_Factor'};
    my $RNA_conc           = $data{$well}->{'RNA_DNA_Concentration'};
    my $undiluted_RNA_conc = _calculate_undiluted_conc( -undiluted => $RNA_conc, -dilution => $dilution_factor );
    $datatable->Set_Row( [ 'Undiluted_RNA_Conc', $undiluted_RNA_conc ] );

    my $run = alDente::BioanalyzerRun->new( -id => $data{$well}->{BioanalyzerRun_ID}, -dbc => $dbc );
    my $run_table = $run->display_Record( -tables => ['Run'] );

    #if(-e $download_img){
    #$table->Set_Row([$datatable->Printout(0),"<img src=$html_img>",$run_table]);
    #}
    #else{
    #$table->Set_Row([$datatable->Printout(0),"Electropherogram not available.",$run_table]);
    #}
}

sub _calculate_undiluted_conc {
    my %args            = @_;
    my $diluted_conc    = $args{-undiluted};
    my $dilution_factor = $args{-dilution};
    my $undiluted_conc  = $diluted_conc;

    if ( $dilution_factor =~ /(\d+)\/(\d+)/ ) {
        $undiluted_conc *= ( $2 / $1 );
    }
    elsif ( $dilution_factor =~ /[\d\.]+/ ) {
        $undiluted_conc /= $dilution_factor;
    }
    return $undiluted_conc;
}

1;
