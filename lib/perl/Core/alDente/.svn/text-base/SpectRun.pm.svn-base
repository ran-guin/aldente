################################################################################
# SpectRun.pm
#
# This module handles Spectrophotometer functions
#
###############################################################################
package alDente::SpectRun;

##############################
# superclasses               #
##############################
@ISA = qw(SDB::DB_Object Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw($spect_file_ext);
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use CGI qw(:standard);
use RGTools::Barcode;
use lib $FindBin::RealBin . "/../lib/perl/Imported/Excel/";

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::HTML;
use alDente::Barcoding;
use alDente::Run;
use alDente::ReArray;
use alDente::Container;
use alDente::Library_Plate qw(select_wells_on_plate);
use alDente::Library_Plate_Set;
use alDente::Rack qw(Move_Racks);
use alDente::Well;
use RGTools::HTML_Table;
use RGTools::RGIO qw(Cast_List Message date_time Link_To filter_input Call_Stack Show_Tool_Tip);
##############################
# global_vars                #
##############################
use vars qw($project_dir $Sess);
use vars qw($testing $current_plates);
use vars qw(%Settings %User_Setting %Department_Settings %Defaults %Login $URL_path %Tool_Tips @libraries $Connection $Sess);
use vars qw($spect_file_ext);

my $q = new CGI;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
my $local_dir    = "$uploads_dir/SpectRun";    # where processed files are located
my $download_dir = $URL_temp_dir;              # temp directory to store HTML files
my ($folder_path) = $download_dir =~ /(dynamic.+)/;
my $HTML_path = $URL_domain . "/$folder_path/";    # URL for files
$spect_file_ext = ".xls";
my $water_need = 2;                                # number of water blank wells needed
my $ssDNA_need = 2;                                # number of salmon sperm DNA wells needed
my $hgDNA_need = 1;                                # number of human gDNA wells needed
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
    my $tables     = $args{-tables} || 'SpectRun';

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables, -encoded => $encoded );
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->add_tables('Plate,Run');
    $self->{dbc} = $dbc;
    if ($id) {
        $self->{id} = $id;    ## list of current plate_ids
        $self->primary_value( -table => 'SpectRun', -value => $id );    ## same thing as above..
        $self->load_Object();
        $self->{run_id}   = $self->value('SpectRun.FK_Run__ID');
        $self->{plate_id} = $self->value('Run.FK_Plate__ID');
    }
    elsif ($attributes) {
        $self->add_Record( -attributes => $attributes );
    }

    $self->{dbc} = $dbc;
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
    my $dbc      = $args{-dbc}      || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = $args{-plate_id} || $self->{plate_id};

    unless ( $self->primary_value( -table => 'SpectRun' ) ) { $dbc->warning("GP not defined") }
    $self->SUPER::load_Object();

    #$self->{name} = $self->{fields}->{FK_Library__Name}->{value} . '-' .
    #$self->{fields}->{Plate_Number}->{value};

    $self->{plate_id} = $self->value('Run.FK_Plate__ID');

    return 1;
}

#######################
# Method to parse out the CGI Params. (Execution will reach here if GeneExpression_SpectRun is one of the params)
#
##################
sub request_broker {
##################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    if ( param('Request_Spect_Runs') ) {
        my $spect_plate   = param('FK_Plate__ID');
        my $spect_scanner = param('FKScanner_Equipment__ID');
        spect_request_form( -plate => $spect_plate, -scanner => $spect_scanner );
    }
    elsif ( param('Create_Spect_Runs') ) {
        my @wells         = param('selection');
        my @source_plates = param('scan');
        my @target_plates = ( param('Plate') );
        my @initial_wells = ( param('initial_wells') );

        my @plate_dimension = &alDente::Well::get_Plate_dimension( -plate => $target_plates[0] );
        my $plate_size = $plate_dimension[$#plate_dimension];
        ($plate_size) = $plate_size =~ /(\d+)/;

        ######## rearray water blanks and standards to the spect plate
        ######## Also, determine unused wells by getting the list of wells with stuff in it excluding the list of used wells (indicated by user)

        ### samples
        my @sample_wells         = alDente::Well::Format_Wells( -wells => $wells[0],         -input_format => $plate_size );
        my @prevous_sample_wells = alDente::Well::Format_Wells( -wells => $initial_wells[0], -input_format => $plate_size );
        my %previous_sample_wells;
        foreach (@prevous_sample_wells) {
            $previous_sample_wells{$_} = 1;
        }
        my %unused_sample_wells = %previous_sample_wells;
        foreach (@sample_wells) {
            delete $unused_sample_wells{$_} if ( exists $unused_sample_wells{$_} );
        }
        delete $unused_sample_wells{''};

        ### water
        my @water_wells          = alDente::Well::Format_Wells( -wells => $wells[1],         -input_format => $plate_size );
        my @previous_water_wells = alDente::Well::Format_Wells( -wells => $initial_wells[1], -input_format => $plate_size );
        my %previous_water_wells;
        foreach (@previous_water_wells) {
            $previous_water_wells{$_} = 1;
        }
        my @added_water_wells;
        foreach (@water_wells) {
            if ( !exists $previous_water_wells{$_} ) {
                push( @added_water_wells, $_ );
            }
        }
        my ($water_source_plate) = $source_plates[0] =~ /pla(\d+)/i;
        my @water_source_plates = ($water_source_plate) x scalar(@added_water_wells);

        my %unused_water_wells = %previous_water_wells;
        foreach (@water_wells) {
            delete $unused_water_wells{$_} if ( exists $unused_water_wells{$_} );
        }
        delete $unused_water_wells{''};

        ### ssDNA
        my @ssDNA_wells          = alDente::Well::Format_Wells( -wells => $wells[2],         -input_format => $plate_size );
        my @previous_ssDNA_wells = alDente::Well::Format_Wells( -wells => $initial_wells[2], -input_format => $plate_size );
        my %previous_ssDNA_wells;
        foreach (@previous_ssDNA_wells) {
            $previous_ssDNA_wells{$_} = 1;
        }
        my @added_ssDNA_wells;
        foreach (@ssDNA_wells) {
            if ( !exists $previous_ssDNA_wells{$_} ) {
                push( @added_ssDNA_wells, $_ );
            }
        }
        my ($ssDNA_source_plate) = $source_plates[1] =~ /pla(\d+)/i;
        my @ssDNA_source_plates = ($ssDNA_source_plate) x scalar(@added_ssDNA_wells);

        my %unused_ssDNA_wells = %previous_ssDNA_wells;
        foreach (@ssDNA_wells) {
            delete $unused_ssDNA_wells{$_} if ( exists $unused_ssDNA_wells{$_} );
        }
        delete $unused_ssDNA_wells{''};

        ### hgDNA
        my @hgDNA_wells          = alDente::Well::Format_Wells( -wells => $wells[3],         -input_format => $plate_size );
        my @previous_hgDNA_wells = alDente::Well::Format_Wells( -wells => $initial_wells[3], -input_format => $plate_size );
        my %previous_hgDNA_wells;
        foreach (@previous_hgDNA_wells) {
            $previous_hgDNA_wells{$_} = 1;
        }
        my @added_hgDNA_wells;
        foreach (@hgDNA_wells) {
            if ( !exists $previous_hgDNA_wells{$_} ) {
                push( @added_hgDNA_wells, $_ );
            }
        }
        my ($hgDNA_source_plate) = $source_plates[2] =~ /pla(\d+)/i;
        my @hgDNA_source_plates = ($hgDNA_source_plate) x scalar(@added_hgDNA_wells);

        my %unused_hgDNA_wells = %previous_hgDNA_wells;
        foreach (@hgDNA_wells) {
            delete $unused_hgDNA_wells{$_} if ( exists $unused_hgDNA_wells{$_} );
        }
        delete $unused_hgDNA_wells{''};

        my @unused_wells = ( ( keys %unused_sample_wells ), ( keys %unused_water_wells ), ( keys %unused_ssDNA_wells ), ( keys %unused_hgDNA_wells ) );

        ### rearraying
        my @added_wells = ( @added_water_wells, @added_ssDNA_wells, @added_hgDNA_wells );
        @source_plates = ( @water_source_plates, @ssDNA_source_plates, @hgDNA_source_plates );
        my @source_well = ('N/A') x scalar(@source_plates);

        my $rearray = alDente::ReArray->new( -dbc => $dbc );
        my ( $plate, $id ) = $rearray->create_rearray(
            -source_plates       => \@source_plates,
            -source_wells        => \@source_well,
            -target_wells        => \@added_wells,
            -target_plate        => $target_plates[0],
            -emp                 => $user_id,
            -type                => 'Manual Rearray',
            -target_size         => $plate_size,
            -status              => 'Completed',
            -plate_status        => 'Active',
            -skip_plate_creation => 1,
            -rearray_comments    => 'Rearray water and standards for SpectRun'
        );
        unless ($id) {
            $dbc->error( "create rearray for source plates "
                    . Cast_List( -list => \@source_plates, -to => 'string' )
                    . ", source wells "
                    . Cast_List( -list => \@source_well, -to => 'string' )
                    . ", target wells "
                    . Cast_List( -list => \@added_wells, -to => 'string' )
                    . ", target plate "
                    . $target_plates[0]
                    . " failed.<BR>" );
        }
        my $success = $rearray->update_plate_sample_from_rearray( -request_id => $id );
        unless ($success) {
            $dbc->error("Update plate sample from rearray for id $id failed.<BR>");
        }
        print "Rearrayed samples to plate: $plate, ReArray_Request ID: $id<BR>";

        my %spect_run_info;
        $spect_run_info{1}->{Unused} = \@unused_wells;
        my $run_id = alDente::SpectRun::create_spectrun( -spect_run_info => \%spect_run_info );
        &alDente::SpectRun::start_spectrun( -plates => [ $target_plates[0] ], -runs => $run_id );
        &alDente::SpectRun::associate_scanner( -run_id => $run_id, -scanner_id => param('Scanner') );
        &alDente::SpectRun::display_used_wells( -run_id => $$run_id[0] );
        my $message = "<br>Run_ID is $$run_id[0]<br><br>Paste table data into Excel spreadsheet and save file as $$run_id[0].xls<br>";
        $dbc->message($message);
    }
    elsif ( param('spect_home_page') ) {
        require Lib_Construction::Spect_Summary;
        my $summary = Lib_Construction::Spect_Summary->new();
        $summary->configure();
        print $summary->home_page();
    }
    else {
        $dbc->message("No Params found :(");
    }

}

######################
# Method to prompt the user for entering SpectRun initiation parameters
#
#
# We have 2 methods of entry:
#       1: From request_broker()          -> User enters the number of Gels and an Agarose Solution from Homepage
#       2: From Equipment::HomeInfo()   -> User has scanned a series of Combs and Agarose and potentially Gel Trays (Racks)
#         In this form, if there are no attributes available and GelTrays are provided, the system automatically creates the GelRuns
#
#
######################
sub spect_request_form {
######################
    my %args    = @_;
    my @scanner = $args{-scanner} =~ /\d+/g;
    my @plates  = $args{-plate} =~ /\d+/g;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    # input error checking
    my @words = $args{-scanner} =~ /\D+/g;
    foreach (@words) {
        $dbc->error("Unknown barcode type $_ for scanner.  Only \'equ\' allowed") if ( $_ !~ /^equ$/i && $_ ne ',' );
    }
    @words = $args{-plate} =~ /\D+/g;
    foreach (@words) {
        $dbc->error("Unknown barcode type $_ for plates.  Only \'pla\' allowed") if ( $_ !~ /^pla$/i && $_ ne ',' );
    }
    $dbc->error("User must define one and only one scanner")                 if ( scalar(@scanner) != 1 );
    $dbc->error("User must define one and only one spectrophotometer plate") if ( scalar(@plates) != 1 );

    ### print a plate table for user to select unused wells (wells not empty and not considered during post-run analysis)
    my $req = HTML_Table->new( -title => 'Spectrophotometer Run Request (Plate ID ' . $plates[0] . ')' );
    my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -plate => $plates[0] );

    # find wells with samples
    my @filled_wells = $dbc->Table_find( 'ReArray,ReArray_Request,Sample', 'Target_Well,Sample_Name', "WHERE ReArray_Request_ID = FK_ReArray_Request__ID and FKTarget_Plate__ID = $plates[0] and FK_Sample__ID = Sample_ID" );

    my %well_tooltip;
    my $well_tooltip = \%well_tooltip;
    my @water_wells;
    my @ssDNA_wells;
    my @hgDNA_wells;
    my @sample_wells;
    for ( my $i = 0; $i <= $#filled_wells; $i++ ) {
        my ( $row, $col, $sample ) = $filled_wells[$i] =~ /(\D+)(\d+),(.+)/;
        ($col) = $col =~ /0+(\d+)/;    # remove well '0'
        $well_tooltip->{"$row$col"} = $sample;

        # sort occupied wells into different categories
        if ( $sample =~ /water/i ) {
            push( @water_wells, "$row$col" );
        }
        elsif ( $sample =~ /SS DNA/i ) {
            push( @ssDNA_wells, "$row$col" );
        }
        elsif ( $sample =~ /human gDNA/i ) {
            push( @hgDNA_wells, "$row$col" );
        }
        else {
            push( @sample_wells, "$row$col" );
        }
    }

    $req->Set_Headers( ["Select Used Wells, Water Blanks, and Standards"] );

    my %headerbox;
    $headerbox{1}->{name}           = "Sample Wells";
    $headerbox{1}->{select_display} = "Wells";
    $headerbox{1}->{well}           = Cast_List( -list => \@sample_wells, -to => 'string' );

    $headerbox{2}->{name}           = "Water Blank";
    $headerbox{2}->{scan}           = 1;
    $headerbox{2}->{select_display} = "Wells";
    $headerbox{2}->{tooltip}        = "scan in water tube";
    $headerbox{2}->{well}           = Cast_List( -list => \@water_wells, -to => 'string' );

    $headerbox{3}->{name}           = "SS DNA";
    $headerbox{3}->{scan}           = 1;
    $headerbox{3}->{select_display} = "Wells";
    $headerbox{3}->{tooltip}        = "scan in SS DNA tube";
    $headerbox{3}->{well}           = Cast_List( -list => \@ssDNA_wells, -to => 'string' );

    $headerbox{4}->{name}           = "human gDNA";
    $headerbox{4}->{scan}           = 1;
    $headerbox{4}->{select_display} = "Wells";
    $headerbox{4}->{tooltip}        = "scan in human gDNA tube";
    $headerbox{4}->{well}           = Cast_List( -list => \@hgDNA_wells, -to => 'string' );

    $req->Set_Row(
        [   alDente::Container_Views::select_wells_on_plate(
                -table_id            => 'Select_Wells',
                -max_row             => $max_row,
                -max_col             => $max_col,
                -input_type          => 'checkbox',
                -well_tooltip        => $well_tooltip,
                -textbox             => \%headerbox,
                -show_sample_tooltip => 1
            )
        ]
    );
    $req->Set_Row( ["<BR><b><font color='red'><blink>Clear any wells (samples,standards,blanks) not used for analysis.<BR>Every colored well will be used for analysis.<BR></blink></b></font>"] );
    $req->Set_Row(
        [   submit(
                -name       => 'Create_Spect_Runs',
                -value      => 'Create',
                -class      => 'Action',
                onMouseOver => "
/************************************
*********** ERROR CHECKINGS *********
************************************/
var check_status=1;
// find the new wells for water blank and standards
var new_wells=new Array();
for(var i=1;i<this.form.selection.length;i++){
  new_wells[i]=new Array();
  var old_wells=this.form.initial_wells[i].value.split(\",\");
  var wells=this.form.selection[i].value.split(\",\");
  var old_wellsHash=new Array();
  for(var j=0;j<old_wells.length;j++){
    old_wellsHash[old_wells[j]]=1;
  }
  for(var j=0;j<wells.length;j++){
    if(! old_wellsHash[wells[j]]){
      new_wells[i].push(wells[j]);
    }
  }
  // splitting empty string puts an empty string in array, which needs to be removed
  if(new_wells[i][0] == ''){
    new_wells[i].pop();
  }

  // make sure tubes are scanned in
  if(new_wells[i].length != 0 && this.form.scan[i-1].value == ''){
    alert('You must scan in the tube for '+this.form.scan[i-1].id);
    check_status = check_status && 0;
  }
  // make sure scanned plate number has correct format
  else if(this.form.scan[i-1].value && (! this.form.scan[i-1].value.match(/^pla\\d+\$/))){
    alert('tube ID '+this.form.scan[i-1].value+' for '+this.form.scan[i-1].id+' has incorrect format');
    check_status = check_status && 0;
  }  
}
// make sure no water or standard samples are being rearrayed to previously occupied sample wells
if(check_status){
  var samples=this.form.initial_wells[0].value.split(\",\");
  var sampleHash=new Array();
  for(var i=0;i<samples.length;i++){
    sampleHash[samples[i]]=1;
  }
  for(var i=1;i<new_wells.length;i++){
    if(new_wells[i].length){
      var illegal=new Array();
      for(var j=0;j<new_wells[i].length;j++){
        if(sampleHash[new_wells[i][j]]){
          illegal.push(new_wells[i][j]);
        }
      }
      if(illegal.length>0){
        alert('Error: cannot aliquote '+this.form.scan[i-1].id+' to occupied wells: '+illegal.join(\",\"));
        check_status = check_status && 0;
      }
    }
  }
}
// make sure there are exactly 2 water blanks, 2 SS DNA standards, and 1 human gDNA standards (new)
var water_need='$water_need';
var ssDNA_need='$ssDNA_need';
var hgDNA_need='$hgDNA_need';
if(check_status){
  var water=new_wells[1];
  if(water.length != water_need){
    alert('You must pick '+water_need+' new water blanks.  Currently there are '+water.length);
    check_status = check_status && 0;
  }
  var ssDNA=new_wells[2];
  if(ssDNA.length != ssDNA_need){
    alert('You must pick '+ssDNA_need+' new SS DNA wells.  Currently there are '+ssDNA.length);
    check_status = check_status && 0;
  }
  var hgDNA=new_wells[3];
  if(hgDNA.length != hgDNA_need){
    alert('You must pick '+hgDNA_need+' new human gDNA wells.  Currently there are '+hgDNA.length);
    check_status = check_status && 0;
  }
}
"
            )
        ]
    );

    print alDente::Form::start_alDente_form( $dbc, 'spect_run_form', $dbc->homelink() )
        . hidden( -name => 'Lib_Construction_SpectRun' )
        . hidden( -name => 'Plate',   -value => $plates[0] )
        . hidden( -name => 'Scanner', -value => $scanner[0] )
        . $req->Printout(0)
        . "</form>";

    ### initialize table
    print "<script>
// find the form containing the wells
var f=document.getElementById('Wells');
while(f.name != 'spect_run_form'){
  f=f.parentNode;
}
// do update
update_well_information(f,'Wells','selection','','');
</script>";
}

##########################################
# Create single or multiple spectrophotometer runs
#
# Method to instantiate "empty" spect Runs (ie do not have any plates associated with them)
#
# request_list is a hash, with keys starting from 1.
# it could also contain an an Attributes key that contains the attribute_id,value pairs in it
#
# An example for an input parameter:
#
# <snip>
# Example:
# my %spect_run_info = (
#  '1' => {
#                'Comments' => 'comment1'
#              },
#  '2' => {
#                'Comments' => 'comment2'
#              }
#);
#
#     my $gel = alDente::GelRun->new(-dbc=>$dbc);
#     $gel->create_gelrun(-gel_run_info=>\%gel_run_info);
# </snip>
#
######################
sub create_spectrun {
######################
    my %args           = @_;
    my %spect_run_info = %{ $args{-spect_run_info} };
    my %spect_run;
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

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
        $dbc->error("Problem creating RunBatch");
        print HTML_Dump( \@runbatch_fields, \%runbatch );
        Call_Stack();
        return 0;
    }

    # create new run and spect run
    my @run_fields      = qw(FK_RunBatch__ID Run_Type Run_Test_Status Run_Status Run_Directory Excluded_Wells);
    my @spectrun_fields = qw();
    my @fields          = ( @run_fields, @spectrun_fields );
    foreach my $key ( sort { $a <=> $b } keys %spect_run_info ) {
        my $test_status = $spect_run_info{$key}->{Test_Status} || 'NULL';
        my @unused_wells = alDente::Well::Format_Wells( -wells => $spect_run_info{$key}->{Unused} );
        my $unused_wells = Cast_List( -list => \@unused_wells, -to => 'string' );
        $spect_run{$key} = [ $runbatch_id[0], 'SpectRun', $test_status, 'Not Applicable', 'NULL', $unused_wells ];
    }

    my $spectrun_ids = $dbc->smart_append(
        -tables    => 'Run,SpectRun',
        -fields    => \@fields,
        -values    => \%spect_run,
        -autoquote => 1
    );

    my @spectrun_ids = @{ $spectrun_ids->{SpectRun}->{newids} };
    my @run_ids      = @{ $spectrun_ids->{Run}->{newids} };

    if (@spectrun_ids) {
        my $new_runs = join( ',', @run_ids );
        $dbc->message( "Created Run: " . &Link_To( $dbc->config('homelink'), $new_runs, "&Info=1&TableName=Run&Field=Run_ID&Like=$new_runs" ) . '<BR>' );
    }
    else {
        $dbc->error("Problems appending");
        print HTML_Dump( \@fields, \%spect_run );
        Call_Stack();
        return 0;
    }

    # print barcodes
    foreach my $run (@run_ids) {
        &alDente::Barcoding::PrintBarcode( $dbc->dbh(), 'Run', $run );
    }

    return \@run_ids;
}

########################################################
#
# Method to Start the Spect Runs (ie creation & association with Runs)
#
# Creates a RunBatch of 2 Runs, and associates the already existing GelRuns with these Runs
#
# <snip>
#     alDente::SpectRun::start_spectrun(-plates=>\@plate_ids, -runs=>\@run_ids);
# </snip>
#
###################
sub start_spectrun {
###################
    my %args = &filter_input( \@_, -args => 'plates,runs' );
    my $plates = Cast_List( -list => $args{-plates}, -to => 'string' );
    my @runs   = Cast_List( -list => $args{-runs},   -to => 'array' );
    my $quiet  = $args{-quiet};
    my @plates  = @{ $args{-plates} };
    my $runs    = join( ',', @runs );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');
    if ( $args{ERRORS} ) { $dbc->error("$args{ERRORS}") }

    if ( scalar(@runs) != scalar(@plates) ) {
        print HTML_Dump( \@runs, $plates );
        $dbc->error("Invalid parameters");
        return 0;
    }

    if ( _run_started( -runs => \@runs ) ) {
        $dbc->error("Some of the runs have already been started");
        return 0;
    }

    ### Retrieve table information
    my %spect_hash = $dbc->Table_retrieve( "Run,SpectRun,RunBatch", [ 'Run_ID', 'RunBatch_ID' ], "WHERE RunBatch_ID = FK_RunBatch__ID and Run_ID=FK_Run__ID AND Run_ID IN ($runs)" );
    my ( @run_ids, @run_batches );

    if ( $spect_hash{Run_ID} ) {
        @run_ids     = @{ $spect_hash{Run_ID} };
        @run_batches = @{ $spect_hash{RunBatch_ID} };
    }
    else {
        $dbc->error("Invalid Runs ($runs)");
        return 0;
    }

    ### Plate Format Check
    my @plate_formats = $dbc->Table_find( 'Plate', 'Plate_ID,Plate_Size,FK_Library__Name,Plate_Number', "WHERE Plate_ID IN ($plates) AND Plate_Size='384-well'" );
    if ( int(@plate_formats) != int(@plates) ) {
        $dbc->error("All spectrophotometer plates must be in 384-well format");
        return 0;
    }

    # branch
    # get Run_Directory for Run here
    #    my ($run_dirs,$error) = &alDente::Run::_nextname(-plate_ids=>$plates,-check_branch=>1);

    #    if($error) {
    #        Message("Error: Problem starting Spect Runs");
    #        return 0;
    #    }
    # for now, generate Run_Directory here...
    # Run_Directory should be LibraryName-PlateNumber.Branch.Version

    my %run_dirs;
    foreach (@plate_formats) {
        my ( $plate_id, $plate_size, $library, $plate_num ) = split( /,/, $_ );
        my $run_dir = "$library-$plate_num.SPECT";

        # add version or increment version if run dir already exists
        my @previous_run_dir = $dbc->Table_find( "Run", "Run_Directory", "where Run_Directory like \'$run_dir%\' order by Run_ID desc" );
        if ( $previous_run_dir[0] ) {
            if ( $previous_run_dir[0] eq $run_dir ) {
                $run_dir .= ".1";
            }
            elsif ( $previous_run_dir[0] =~ /$run_dir\.(\d+)/ ) {
                $run_dir .= "." . ( $1 + 1 );
            }
            else {
                $dbc->error("Previous run directory with unknown format $previous_run_dir[0]");
            }
        }
        $run_dirs{$plate_id} = $run_dir;

        # create new directory for file upload
        my $new_dir = "$local_dir/$run_dir";
        `mkdir $new_dir`;
        `chmod ugo+rwx $new_dir`;
        $dbc->error("cannot create directory $new_dir") if ( !-e $new_dir );
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
        $dbc->warning("Not all records updated!");
    }
}

sub _run_started {
##################
    my %args = &filter_input( \@_, -args => 'runs' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $runs = Cast_List( -list => $args{-runs}, -to => 'string' );
    my @spects = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID IN ($runs) AND FK_Plate__ID IS NOT NULL" );

    if (@spects) {
        return 1;
    }
    else {
        return 0;
    }
}

######################
#
# Associate a Spect Run with a spectrophotometer
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
        -table     => 'SpectRun',
        -fields    => ['FKScanner_Equipment__ID'],
        -values    => [$scanner_id],
        -condition => "WHERE FK_Run__ID in ($run_id)",
        -autoquote => 1
    );

    if ($ok) {
        $dbc->message("Updated $ok SpectRun Records");
    }
    else {
        $dbc->message("Warning: 0 records updated. Spectrophotometer might already be set!");
        return 0;
    }
}

#######################
# Method to parse output file from spectrophotometer
#
# will be run by Cron job
# file name will be in the format of Run_ID.extension (e.g. 92341.xls)
#######################
sub parse_spect_output {
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
    my ( $well_col, $name_col, $dilution_col, $ratio_col, $conc_col, $A260m_col, $A260cor_col, $A280m_col, $A280cor_col, $A260cor_blank_col, $A280cor_blank_col, $A260_col, $A280_col, $conc_unit, $data_row );

    for ( my $row = $sheet->{MinRow}; $row <= $sheet->{MaxRow}; $row++ ) {
        next unless ( defined $sheet->{Cells}[$row][ $sheet->{MinCol} ] );
        if ( $sheet->{Cells}[$row][ $sheet->{MinCol} ]->Value =~ /well/i ) {
            for ( my $col = $sheet->{MinCol}; $col <= $sheet->{MaxCol} && defined $sheet->{Cells}[$row][$col]; $col++ ) {

                # find the column number for each field
                my $header = $sheet->{Cells}[$row][$col]->Value;
                if ( $header =~ /well/i ) {
                    $well_col = $col;
                }
                elsif ( $header =~ /sample name/i ) {
                    $name_col = $col;
                }
                elsif ( $header =~ /diln|dilution/i ) {
                    $dilution_col = $col;
                }
                elsif ( $header =~ /A260.+?\/A280.+?/i ) {
                    $ratio_col = $col;
                }
                elsif ( $header =~ /conc/i ) {
                    $conc_col = $col;
                    $header =~ /\((.+?)\)/;
                    $conc_unit = $1;
                }
                elsif ( $header =~ /^A260m$/i ) {
                    $A260m_col = $col;
                }
                elsif ( $header =~ /^A260cor$/i ) {
                    $A260cor_col = $col;
                }
                elsif ( $header =~ /^A280m$/i ) {
                    $A280m_col = $col;
                }
                elsif ( $header =~ /^A280cor$/i ) {
                    $A280cor_col = $col;
                }
                elsif ( $header =~ /(:?ave|avg) blank 260cor/i ) {
                    $A260cor_blank_col = $col;
                }
                elsif ( $header =~ /(:?ave|avg) blank 280cor/i ) {
                    $A280cor_blank_col = $col;
                }
                elsif ( $header =~ /A260cor \- A260 blank/i ) {
                    $A260_col = $col;
                }
                elsif ( $header =~ /A280cor \- A280 blank/i ) {
                    $A280_col = $col;
                }
            }
            $data_row = $row;
            last;
        }
    }

    # copy data to an array and handle empty cells
    my @cells;
    for ( my $row = $data_row + 1; $row <= $sheet->{MaxRow}; $row++ ) {
        for ( my $col = $sheet->{MinCol}; $col <= $sheet->{MaxCol}; $col++ ) {
            my $cell = $sheet->{Cells}[$row][$col];
            if ( defined $cell && defined $cell->Value ) {
                $cells[$row][$col] = $cell->Value;
            }
            else {
                $cells[$row][$col] = "";
            }
        }
    }

    # read cell data
    for ( my $row = 0; $row < scalar(@cells); $row++ ) {
        my $well = $cells[$row][$well_col];
        next if ( !defined $well || $well eq "" );
        ($well) = &alDente::Well::Format_Wells( -wells => [$well] );
        my $A260cor = $cells[$row][$A260cor_col];
        my $A280cor = $cells[$row][$A280cor_col];

        if ( $A260cor eq "" || $A280cor eq "" ) {    # find the last row of useful data
            last;
        }

        $data{data}->{$well}->{dilution}      = $cells[$row][$dilution_col];
        $data{data}->{$well}->{A260m}         = $cells[$row][$A260m_col];
        $data{data}->{$well}->{A280m}         = $cells[$row][$A280m_col];
        $data{data}->{$well}->{A260cor}       = $cells[$row][$A260cor_col];
        $data{data}->{$well}->{A280cor}       = $cells[$row][$A280cor_col];
        $data{data}->{$well}->{A260cor_blank} = $cells[$row][$A260cor_blank_col];
        $data{data}->{$well}->{A280cor_blank} = $cells[$row][$A280cor_blank_col];
        $data{data}->{$well}->{A260}          = $cells[$row][$A260_col];
        $data{data}->{$well}->{A280}          = $cells[$row][$A280_col];
        $data{data}->{$well}->{conc}          = $cells[$row][$conc_col];
        $data{data}->{$well}->{ratio}         = $cells[$row][$ratio_col];
        $data{data}->{$well}->{name}          = $cells[$row][$name_col];
        $data{data}->{$well}->{unit}          = $conc_unit;

        # determine well category
        my $name = $cells[$row][$name_col];
        if ( $name =~ /water|blank/i ) {
            $data{data}->{$well}->{type} = "Blank";
        }
        elsif ( $name =~ /SS DNA|salmon sperm DNA/i ) {
            $data{data}->{$well}->{type} = "ssDNA";
        }
        elsif ( $name =~ /human gDNA|hgDNA|human genomic DNA/i ) {
            $data{data}->{$well}->{type} = "hgDNA";
        }
        else {
            $data{data}->{$well}->{type} = "Sample";
        }
    }

    return \%data;
}

#######################
# Method to populate DB with data from spectrophotometer
#######################
sub populate_spect_output {
#######################
    my %arg     = @_;
    my $dataRef = $arg{-data};
    my $dbc     = $arg{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $file    = $dataRef->{file};
    $dbc->error("$0\tError: incorrect file name format $file") if $file !~ /\/?\d+\./;
    $file =~ /\/?(\d+)\./;
    my $run_id = $1;

    ### get plate size of spect plate and get all the wells
    my ($size) = $dbc->SDB::DBIO::Table_find( "Plate,Run", "Plate_Size", "where Plate_ID = FK_Plate__ID and Run_ID = $run_id" );
    my @wells = &alDente::Well::Get_Wells( -size => $size );
    @wells = &alDente::Well::Format_Wells( -wells => \@wells, -input_format => $size );

    my %wells;
    foreach (@wells) {
        $wells{$_} = 1;
    }

    ### find Sample_ID for each target well
    my @samples = $dbc->Table_find( "ReArray_Request,ReArray,Run", "Target_Well,FK_Sample__ID", "where FKTarget_Plate__ID = FK_Plate__ID and ReArray_Request_ID = FK_ReArray_Request__ID and Run_ID = $run_id" );
    my %samples;
    foreach (@samples) {
        $_ =~ /(.+?),(.+)/;
        $samples{$1} = $2;
    }

    ### find wells that are not empty but not used from Excluded_Well in Run
    my ($excluded_wells) = $dbc->SDB::DBIO::Table_find( "Run", "Excluded_Wells", "where Run_ID = $run_id" );
    my @excluded_wells = split( ',', $excluded_wells );
    my %excluded_wells;
    foreach (@excluded_wells) {
        $excluded_wells{$_} = 1;
    }

    ### insert SpectRead entries if target well is not one of the Excluded_Well in Run
    my %spect_read;
    my $key = 1;
    foreach my $well ( keys %{ $dataRef->{data} } ) {
        ### check if well is a proper well given the plate size
        $dbc->error("$0\tError: well $well does not exist on spect plate") if !exists $wells{$well};

        #	print "Well $well is excluded from analysis" if exists $excluded_wells{$well};
        next if exists $excluded_wells{$well};

        $spect_read{$key} = [
            $run_id,                            $samples{$well},                      $well,                                 $dataRef->{data}->{$well}->{A260m}, $dataRef->{data}->{$well}->{A260cor},
            $dataRef->{data}->{$well}->{A280m}, $dataRef->{data}->{$well}->{A280cor}, $dataRef->{data}->{$well}->{dilution}, $dataRef->{data}->{$well}->{type},  $dataRef->{data}->{$well}->{A260},
            $dataRef->{data}->{$well}->{A280},  $dataRef->{data}->{$well}->{ratio},   $dataRef->{data}->{$well}->{conc},     $dataRef->{data}->{$well}->{unit}
        ];
        $key++;
    }

    ### adding SpectRead and SpectAnalysis entries
    my @spectread_fields = qw(FK_Run__ID FK_Sample__ID Well A260m A260cor A280m A280cor Dilution_Factor Well_Category A260 A280 A260_A280_ratio Concentration Unit);

    my $spectread_ids = $dbc->SDB::DBIO::smart_append(
        -tables    => 'SpectRead',
        -fields    => \@spectread_fields,
        -values    => \%spect_read,
        -autoquote => 1
    );

    ### adding SpectAnalysis entries
    my %spect_analysis;

    my @spectanalysis_fields = qw(FK_Run__ID A260_Blank_Avg A280_Blank_Avg);
    @wells = ( keys %{ $dataRef->{data} } );
    $spect_analysis{1} = [ $run_id, $dataRef->{data}->{ $wells[0] }->{A260cor_blank}, $dataRef->{data}->{ $wells[0] }->{A280cor_blank} ];    # note: A260cor blank avg and A280cor blank avg is the same for all wells in a run

    my $spectanalysis_ids = $dbc->SDB::DBIO::smart_append(
        -tables    => 'SpectAnalysis',
        -fields    => \@spectanalysis_fields,
        -values    => \%spect_analysis,
        -autoquote => 1
    );

    if ( $$spectanalysis_ids{'SpectAnalysis'} ) {                                                                                            # DB insert successful
                                                                                                                                             # change Run_Status to Analyzed
        $dbc->SDB::DBIO::Table_update(
            -table     => 'Run',
            -fields    => 'Run_Status',
            -values    => '\'Analyzed\'',
            -condition => "where Run_ID = $run_id"
        );
        return 1;
    }
    return 0;
}

##############################
# Display Used target wells (wells not empty and not excluded on a Spect read)
# and the sample name of the sample in each target well
sub display_used_wells {
##############################
    my %args           = @_;
    my $run_id         = $args{-run_id};
    my $dbc            = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @excluded_wells = $dbc->Table_find( "Run", "Excluded_Wells", "where Run_ID = $run_id" );
    my $excluded_wells = Cast_List( -autoquote => 1, -list => \@excluded_wells, -to => 'string', -delimiter => "," );
    my %excluded_wells;
    foreach (@excluded_wells) {
        $excluded_wells{$_} = 1;
    }
    my @samples = $dbc->Table_find( "ReArray_Request,ReArray,Run,Sample", "Target_Well,Sample_Name",
        "where FKTarget_Plate__ID = FK_Plate__ID and ReArray_Request_ID = FK_ReArray_Request__ID and Run_ID = $run_id and FK_Sample__ID = Sample_ID order by Target_Well" );
    my %samples;
    foreach (@samples) {
        my ( $well, $sample ) = split( /,/, $_ );
        $samples{$well} = $sample;
    }

    # get the list of wells ordered by row and column
    my ($plate) = $dbc->Table_find( "Run", "FK_Plate__ID", "where Run_ID = $run_id" );
    my ( $min_row, $max_row, $min_col, $max_col, $size ) = alDente::Well::get_Plate_dimension( -plate => $plate );
    my @wells = alDente::Well::Get_Wells( -size => $size );
    my @row_wells = alDente::Well::Format_Wells( -wells => \@wells, -input_format => $size );
    for ( my $i = 0; $i < scalar(@row_wells); $i++ ) {
        my $sample   = $samples{ $row_wells[$i] }        || "0";
        my $excluded = $excluded_wells{ $row_wells[$i] } || "0";
        $row_wells[$i] = "$row_wells[$i],$sample,$excluded";
    }
    my @col_wells;
    my @rows = ( $min_row .. $max_row );
    for ( my $i = $min_col; $i <= $max_col; $i++ ) {
        foreach (@rows) {
            my @well = alDente::Well::Format_Wells( -wells => ["$_$i"], -input_format => $size );
            my $sample   = $samples{ $well[0] }        || 0;
            my $excluded = $excluded_wells{ $well[0] } || 0;
            push( @col_wells, "$well[0],$sample,$excluded" );
        }
    }

    my $row_wells = join( "!", @row_wells );
    my $col_wells = join( "!", @col_wells );

    print "<script>
function draw_table(d,table,wells,display,unused){
  var body = table.firstChild.nextSibling;
  var firstRow = body.removeChild(body.firstChild);
  var secondRow = body.firstChild;
  while(secondRow.tagName != 'TR'){
    secondRow = secondRow.nextSibling;
  }
  var secondRow = body.removeChild(secondRow);
  var newbody = document.createElement(\"TBODY\");
  newbody.appendChild(firstRow);
  newbody.appendChild(secondRow);

  var colors=new Array(2);
  colors[0]='#eeeee8';
  colors[1]='#ddddda';
  var colorCount=0;

  for(var i=0;i<wells.length;i++){
    var arr=wells[i].split(\",\");   // 0:well, 1:sample, 2:excluded
    //                empty and display empty           not empty and not excluded   not empty and excluded and display excluded
    if((display=='Display empty wells' && arr[1]==0) || (arr[1]!=0 && arr[2]!=1) || (arr[1]!=0 && arr[2]==1 && unused=='Display unused wells')){
      var well=arr[0];
      if(well=='0'){
        well = '';
      }
      var sample=arr[1];
      if(sample=='0'){
        sample = '';
      }
      var row=d.createElement(\"TR\");

      var cell1=d.createElement(\"TD\");
      var data1=d.createTextNode(well);
      var span1=d.createElement(\"SPAN\");
      span1.className='small';
      span1.appendChild(data1);
      cell1.appendChild(span1);
      row.appendChild(cell1);

      var cell2=d.createElement(\"TD\");
      var data2=d.createTextNode(sample);
      var span2=d.createElement(\"SPAN\");
      span2.className='small';
      span2.appendChild(data2);
      cell2.appendChild(span2);
      row.appendChild(cell2);
      
      row.bgColor=colors[colorCount];
      if(colorCount==0){
        colorCount=1;
      }
      else{
        colorCount=0;
      }
      newbody.appendChild(row);
    }
  }
  table.removeChild(body);
  table.appendChild(newbody);
}

function initialize(d,f,row_well,col_well){
  var order;
  for(var i=0;i<f.order.length;i++){
    if(f.order[i].checked){
      order=f.order[i].value;
    }
  }

  var display;
  for(var i=0;i<f.display_empty_well.length;i++){
    if(f.display_empty_well[i].checked){
      display=f.display_empty_well[i].value;
   } 
  }

  var unused; 
  for(var i=0;i<f.display_unused_well.length;i++){
    if(f.display_unused_well[i].checked){
      unused=f.display_unused_well[i].value;
    }
  }

  var wells;
  if(order=='Order by row'){
    wells=row_well.split(\"!\");
  }
  else if(order=='Order by column'){
    wells=col_well.split(\"!\");
  }

  var table=d.getElementById('used_wells_table');

  draw_table(d,table,wells,display,unused);
}
</script>";

    my $tables = "";

    my $order_options = [ 'Order by row', 'Order by column' ];
    $tables .= "<b>Well Order:</b>" . hspace(5) . radio_group(
        -name    => 'order',
        -values  => $order_options,
        -default => $$order_options[1],
        -force   => 1,
        onClick  => "
initialize(document,this.form,'$row_wells','$col_wells');
"
    ) . "<BR>";
    my $display_options = [ 'Display empty wells', 'Omit empty wells' ];
    $tables .= "<b>Display Option:</b>" . hspace(5) . radio_group(
        -name    => 'display_empty_well',
        -values  => $display_options,
        -default => $$display_options[1],
        -force   => 1,
        onClick  => "
initialize(document,this.form,'$row_wells','$col_wells');
"
    ) . "<BR>";
    my $unused_options = [ 'Display unused wells', 'Omit unused wells' ];
    $tables .= "<b>Display Option:</b>" . hspace(5) . radio_group(
        -name    => 'display_unused_well',
        -values  => $unused_options,
        -default => $$unused_options[1],
        -force   => 1,
        onClick  => "
initialize(document,this.form,'$row_wells','$col_wells');
"
    ) . "<BR><BR>";

    my $table = HTML_Table->new( -title => 'Used Wells', -id => 'used_wells_table' );
    $table->Set_Headers( [ 'Well', 'Sample Name' ] );

    foreach (@samples) {
        my ( $well, $sample ) = split( /,/, $_ );
        $table->Set_Row( [ $well, $sample ] );
    }
    $tables .= $table->Printout(0) . "<script>
var table=document.getElementById('used_wells_table');
while(table.tagName != 'FORM'){
  table = table.parentNode;
}
initialize(document,table,'$row_wells','$col_wells');
</script>";

    print alDente::Form::start_alDente_form( $dbc, 'used_wells_form', $dbc->homelink() ) . $tables . "</form>";
}

##############################
# Display data collected from a run
sub display_run_data {
##############################
    my %args         = @_;
    my $run_id       = $args{-run_id};
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $header_color = '3366FF';

    ### get plate size of spect plate and get all the wells
    my ($plate_id) = $dbc->SDB::DBIO::Table_find( "Run", "FK_Plate__ID", "where Run_ID = $run_id" );
    my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -plate => $plate_id );

    my @rows = ( $min_row .. $max_row );
    my @cols = ( $min_col .. $max_col );

    my @fields = qw(Well Sample_Name Dilution_Factor A260_A280_ratio Concentration Unit A260m A260cor A260 A280m A280cor A280);
    my $fields = join( ",", @fields );

    my $allTables = "<table cellpadding=0><TR><TD valign=top width=100%>";
    my $table = HTML_Table->new( -title => 'Run Results for Run ID ' . $run_id );
    $allTables .= $table->Printout(0);

    # file download
    my $file = $run_id . $spect_file_ext;
    my ($run_dir) = $dbc->Table_find( "Run", "Run_Directory", "where Run_ID = $run_id" );
    my $local_file    = "$local_dir/$run_dir/$file";
    my $download_file = "$download_dir/$file";
    `cp $local_file $download_file`;
    my $html_file = $HTML_path . $file;
    $allTables .= &Link_To( $html_file, "Download $spect_file_ext File", undef, 'red' ) . "<BR>";

    # data from SpectAnalysis table
    my ($blank_avg) = $dbc->SDB::DBIO::Table_find( "SpectAnalysis", "A260_Blank_Avg,A280_Blank_Avg", "where FK_Run__ID = $run_id" );
    my @blank_avg = split( ",", $blank_avg );
    $allTables .= "<BR>A260 Blank Average: $blank_avg[0]<BR>A280 Blank Average: $blank_avg[1]<BR><BR>";

    # data from SpectRead table
    foreach my $col (@cols) {
        $col = "0" . $col if ( length($col) == 1 );
        my $table = HTML_Table->new();

        my @headers;
        foreach my $row (@rows) {
            push( @headers, $row . $col );
        }
        my $headers = Cast_List( -to => 'string', -autoquote => 1, -list => \@headers, -delimiter => "," );

        my %data;
        my $data = \%data;
        %data = $dbc->Table_retrieve(
            -table     => "Run,SpectRead,Sample",
            -fields    => \@fields,
            -condition => "where FK_Run__ID = Run_ID and FK_Sample__ID = Sample_ID and Well in ($headers) and Run_ID = $run_id",
            -key       => 'Well'
        );

        my @allData;
        foreach my $well ( sort keys %data ) {
            my @data;
            foreach my $field (@fields) {
                push( @data, $data{$well}->{$field} );
            }
            push( @allData, \@data ) if ( scalar(@data) > 0 );
        }
        if ( scalar(@allData) > 0 ) {
            $table->Set_Row( [@fields] );
            foreach (@allData) {
                $table->Set_Row($_);
            }
        }
        $table->Set_Row_Colour( 1, $header_color );
        $allTables .= $table->Printout(0);
    }

    # display of Run and Plate table
    my ($spectrun_id) = $dbc->SDB::DBIO::Table_find( "SpectRun", "SpectRun_ID", "where FK_Run__ID = $run_id" );
    my $spect_run = alDente::SpectRun->new( -id => $spectrun_id );
    $allTables .= "</TD><TD valign=top width=100%>" . $spect_run->display_Record( -tables => ['Run'] ) . "<BR>";
    $allTables .= $spect_run->display_Record( -tables                                     => ['Plate'] );
    $allTables .= "</TD></TR></table>";

    print alDente::Form::start_alDente_form( $dbc, 'SpectRun_result', $dbc->homelink() ) . hidden( -name => 'Lib_Construction_SpectRun' ) . $allTables . "</form>";
    return 1;
}

############################################################################
# for the 1st release, the module will only parse data from .xls file into DB
# for future releases, module will replace calculations done by XLS spreadsheet
# most calculations can be doen with the following modules, but modifications
# are needed; some modules may no longer be needed

#######################
# Method to calculate sample volume needed base on sample concentration
# sample mass unit: ug
# sample concentration unit: ng/ul
#######################
sub _calculate_sample_volume {
#######################
    my $arg     = shift;
    my $Msample = $$arg{-sample_mass};
    my $Csample = $$arg{-sample_conc};

    return $Msample * 1000 / $Csample;
}

#######################
# Method to calculate EB buffer volume based on sample volume and total volume
# volume unit: ul
#######################
sub _calculate_buffer_volume {
#######################
    my $arg     = shift;
    my $Vtotal  = $$arg{-total_vol};
    my $Vsample = $$arg{-sample_vol};

    return $Vtotal - $Vsample;
}

#######################
# Method to calculate sample concentration
# concentration unit: ng/ul
# absorbance refers to final absorbance corrected for path length and blank absorbance
#######################
sub _calculate_concentration {
#######################
    my $arg              = shift;
    my $A260             = $$arg{-A260};
    my $dilutionFactor   = $$arg{-dilution};
    my $conversionFactor = $$arg{-conversion};

    return $A260 * $dilutionFactor * $conversionFactor;
}

#######################
# Method to
# volume unit: ul
#######################
sub _validate_conc {
#######################
    my $arg  = shift;
    my $min  = $$arg{-min};
    my $max  = $$arg{-max};
    my $conc = $$arg{-conc};

    my @warnings;
    push( @warnings, "Warning: concentration ($conc) smaller than minimum ($min)" ) if $conc < $min;
    push( @warnings, "Warning: concentration ($conc) larger than maximum ($max)" )  if $conc > $max;
    return \@warnings;
}

#######################
# Method to process a spectrophotometer plate data
#
# argument:
# -file  spectrophotometer output file
#######################
sub process_plate {
#######################
    my $self = shift;
    my %arg  = @_;

    my $plateRef        = $self->{_plate};
    my $plateSettingRef = $self->{_plateSetting};

    $self->_parse_spect_output( -file => $arg{-file} );

    # find blank standard wells
    my $A260_blank_sum = 0;
    my $A280_blank_sum = 0;
    my $blank_count    = 0;

    foreach my $row ( keys %$plateRef ) {
        foreach my $col ( keys %{ $plateRef->{$row} } ) {
            if ( $plateRef->{$row}->{$col}->{status} eq "OK" && $plateRef->{$row}->{$col}->{category} eq "Blank" ) {
                $A260_blank_sum += $plateRef->{$row}->{$col}->{A260};
                $A280_blank_sum += $plateRef->{$row}->{$col}->{A280};
                $blank_count++;
            }
        }
    }

    # calculate avg. absorbance of blanks
    my $A260_blank_avg = $A260_blank_sum / $blank_count;
    my $A280_blank_avg = $A280_blank_sum / $blank_count;

    # process wells (category = Sample, ssDNA, hgDNA)
    foreach my $row ( keys %$plateRef ) {
        foreach my $col ( keys %{ $plateRef->{$row} } ) {
            next if $plateRef->{$row}->{$col}->{status} ne "OK" || $plateRef->{$row}->{$col}->{category} eq "Blank";
            my %arg;
            $arg{-A260}           = $plateRef->{$row}->{$col}->{A260};
            $arg{-A280}           = $plateRef->{$row}->{$col}->{A280};
            $arg{-sample_mass}    = $plateRef->{$row}->{$col}->{sample_mass} || $$plateSettingRef{-sample_mass};
            $arg{-total_vol}      = $plateRef->{$row}->{$col}->{total_vol} || $$plateSettingRef{-total_vol};
            $arg{-dilution}       = $plateRef->{$row}->{$col}->{dilution};
            $arg{-A260_blank_avg} = $A260_blank_avg;
            $arg{-A280_blank_avg} = $A280_blank_avg;
            $arg{-conversion}     = $$plateSettingRef{-conversion};
            $arg{-min_ratio}      = $$plateSettingRef{-min_ratio};
            $arg{-min_abs}        = $$plateSettingRef{-min_abs};
            $arg{-category}       = $plateRef->{$row}->{$col}->{category};

            my $data = &_process_well( \%arg );
            $plateRef->{$row}->{$col}->{warnings}      = $$data{-warnings};
            $plateRef->{$row}->{$col}->{errors}        = $$data{-errors};
            $plateRef->{$row}->{$col}->{conc}          = $$data{-conc};
            $plateRef->{$row}->{$col}->{sample_vol}    = $$data{-sample_vol};
            $plateRef->{$row}->{$col}->{EB_vol}        = $$data{-EB_vol};
            $plateRef->{$row}->{$col}->{total_vol}     = $$data{-total_vol};
            $plateRef->{$row}->{$col}->{A260corrected} = $$data{-A260corrected};
            $plateRef->{$row}->{$col}->{A280corrected} = $$data{-A280corrected};
            $plateRef->{$row}->{$col}->{ratio}         = $$data{-ratio};

            # validate hgDNA standard
            if ( $plateRef->{$row}->{$col}->{category} eq "hgDNA" ) {
                my %conc_arg;
                $conc_arg{-conc} = $$data{-conc};
                $conc_arg{-min}  = $$plateSettingRef{-min_hgDNA_conc};
                $conc_arg{-max}  = $$plateSettingRef{-max_hgDNA_conc};
                $plateRef->{$row}->{$col}->{warnings} = \push( @{ $plateRef->{$row}->{$col}->{warnings} }, @{ &_validate_conc( \%conc_arg ) } );
            }

            # validate ssDNA standard
            elsif ( $plateRef->{$row}->{$col}->{category} eq "ssDNA" ) {
                my %conc_arg;
                $conc_arg{-conc} = $$data{-conc};
                $conc_arg{-min}  = $$plateSettingRef{-min_ssDNA_conc};
                $conc_arg{-max}  = $$plateSettingRef{-max_ssDNA_conc};
                $plateRef->{$row}->{$col}->{warnings} = \push( @{ $plateRef->{$row}->{$col}->{warnings} }, @{ &_validate_conc( \%conc_arg ) } );
            }
        }
    }

    #    print Dumper $self;
    $self->_print_run_result();
    $self->_print_sample_sheet();
}

#######################
# Method to display the sample aliquote sheet
#######################
sub _print_sample_sheet {
####################
    my $self  = shift;
    my $plate = $self->{_plate};

    my $column_width = "%5s";
    my $header_width = "%21s";

    print header(), start_html("Spectrophotometer"), h1("Spectrophotometer Sample Aliquote Sheet");

    foreach my $row ( keys %$plate ) {
        my $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Border(1);
        $table->Set_Column_Widths( [100], [0] );
        my @col = ( sort { $a <=> $b } keys %{ $plate->{$row} } );
        my @size = ( ('60') x scalar(@col) );
        $table->Set_Column_Widths( \@size, \@col );

        my @line = ( sprintf( "$header_width", "" ) );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            $col = "0" . $col if length($col) == 1;
            push( @line, $row . $col );
        }
        $table->Set_Headers( \@line );

        @line = ();
        push( @line, "Sample Name" );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            push( @line, $plate->{$row}->{$col}->{name} );
        }
        $table->Set_Row( \@line );

        @line = ();
        push( @line, "Conc. (ng/ul)" );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            push( @line, $plate->{$row}->{$col}->{conc} );
        }
        $table->Set_Row( \@line );

        @line = ();
        push( @line, "Vol Sample (ul)" );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            push( @line, $plate->{$row}->{$col}->{sample_vol} );
        }
        $table->Set_Row( \@line );

        @line = ();
        push( @line, "Vol EB Buffer (ul)" );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            push( @line, $plate->{$row}->{$col}->{EB_vol} );
        }
        $table->Set_Row( \@line );

        @line = ();
        push( @line, "Total Vol (ul)" );
        foreach my $col ( sort { $a <=> $b } keys %{ $plate->{$row} } ) {
            push( @line, $plate->{$row}->{$col}->{total_vol} );
        }
        $table->Set_Row( \@line );

        $table->Printout();
    }

    print end_html();
}

#######################
# Method to annotate a plate well
#
# argument:
################
# Well position:
################
# -row          row (A, B, C, ...)
# -col          column (1, 2, 3, ...)
##############
# Well status:
##############
# -used         flag to indicated well is used
# -unused       flag to indicate well is unused
# -problematic  flag to indicate well is problematic
# -ignored      flag to indicate well is ignored
################
# Well category:
################
# -sample       flag to indicate well contains sample
# -blank        flag to indicate well contains blank
# -ssDNA        flag to indicate well contains salmon sperm DNA
# -hgDNA        flag to indicate well contains human genomic DNA
#######################
sub annotate_well {
#######################
    my $self     = shift;
    my %arg      = @_;
    my $plateRef = $self->{_plate};
    my $row      = $arg{-row} || Message("$0\tError: must specify row");
    my $col      = $arg{-col} || Message("$0\tError: must specify column");

    $plateRef->{$row}->{$col}->{status} = "OK"          if $arg{-used};
    $plateRef->{$row}->{$col}->{status} = "Unused"      if $arg{-unused};
    $plateRef->{$row}->{$col}->{status} = "Problematic" if $arg{-problematic};
    $plateRef->{$row}->{$col}->{status} = "Ignored"     if $arg{-ignored};

    $plateRef->{$row}->{$col}->{category} = "Sample" if $arg{-sample};
    $plateRef->{$row}->{$col}->{category} = "Blank"  if $arg{-blank};
    $plateRef->{$row}->{$col}->{category} = "ssDNA"  if $arg{-ssDNA};
    $plateRef->{$row}->{$col}->{category} = "hgDNA"  if $arg{-hgDNA};

    $plateRef->{$row}->{$col}->{total_vol}   = $arg{-total_vol}   if $arg{-total_vol};
    $plateRef->{$row}->{$col}->{sample_mass} = $arg{-sample_mass} if $arg{-sample_mass};
}

#######################
# Method to calculate the concentration, sample volume, EB buffer volume for each sample
# volume unit: ul
# A260, A280: absorbance corrected for path length only
# $Msample: sample mass needed (ng)
# Vtotal: total sample volume needed (ul)
#######################
sub _process_well {
#######################
    my $arg = shift;

    my $A260           = $$arg{-A260};
    my $A280           = $$arg{-A280};
    my $A260_blank_avg = $$arg{-A260_blank_avg};
    my $A280_blank_avg = $$arg{-A280_blank_avg};
    my $category       = $$arg{-category};

    # concentration calculation setting
    my $dilutionFactor   = $$arg{-dilution};
    my $conversionFactor = $$arg{-conversion};

    # data validation setting
    my $min_NA_protein_ratio = $$arg{-min_ratio};
    my $min_absorbance       = $$arg{-min_abs};

    # sample volume setting
    my $Msample = $$arg{-sample_mass};
    my $Vtotal  = $$arg{-total_vol};

    # flags
    my %returnData;
    my @warnings;
    my @errors;
    $returnData{-warnings} = \@warnings;
    $returnData{-errors}   = \@errors;

    # calculate / check absorbance
    push( @warnings, "Warning: A260cor ($A260) lower than minimum ($min_absorbance)" ) if $A260 < $min_absorbance && $category ne "Blank";
    push( @warnings, "Warning: A280cor ($A280) lower than minimum ($min_absorbance)" ) if $A280 < $min_absorbance && $category ne "Blank";
    my $A260_corrected = $A260 - $A260_blank_avg;    # corrected for path length and background
    my $A280_corrected = $A280 - $A280_blank_avg;    # corrected for path length and background
    push( @errors, "Error: A260cor ($A260) lower than average blank A260cor ($A260_blank_avg)" ) if $A260_corrected < 0 && $category ne "Blank";
    push( @errors, "Error: A280cor ($A280) lower than average blank A280cor ($A280_blank_avg)" ) if $A280_corrected < 0 && $category ne "Blank";
    return \%returnData if @errors > 0;

    # calculate / check nucleic acid to protein ratio
    my $NA_protein_ratio = $A260_corrected / $A280_corrected;
    push( @warnings, "Warning: nucliec acid to protein ratio ($NA_protein_ratio) smaller than minimum ($min_NA_protein_ratio)" ) if $NA_protein_ratio < $min_NA_protein_ratio && $category ne "Blank";

    # calculate / check concentration
    my %conc_arg;
    $conc_arg{-dilution}   = $dilutionFactor;
    $conc_arg{-conversion} = $conversionFactor;
    $conc_arg{-A260}       = $A260_corrected;
    my $conc     = &_calculate_concentration( \%conc_arg );
    my $min_conc = $Msample / $Vtotal;
    push( @errors, "Error: sample concentration ($conc ng/ul) smaller than minimum ($min_conc ng/ul)" ) if ( $conc < $min_conc && $category ne "Blank" );
    return \%returnData if @errors > 0;

    # calculate sample volume needed
    my %sample_arg;
    $sample_arg{-sample_mass} = $Msample;
    $sample_arg{-sample_conc} = $conc;
    my $Vsample = &_calculate_sample_volume( \%sample_arg ) if $category eq "Sample";

    # calculate EB buffer volume needed
    my %EB_arg;
    $EB_arg{-total_vol}  = $Vtotal;
    $EB_arg{-sample_vol} = $Vsample;
    my $Veb = &_calculate_buffer_volume( \%EB_arg ) if $category eq "Sample";

    # round numbers
    my $Vtot = $Vsample + $Veb;
    $conc             = sprintf( "%.0f", $conc );
    $Vsample          = sprintf( "%.2f", $Vsample );
    $Veb              = sprintf( "%.2f", $Veb );
    $Vtot             = sprintf( "%.2f", $Vtot );
    $A260_corrected   = sprintf( "%.2f", $A260_corrected );
    $A280_corrected   = sprintf( "%.2f", $A280_corrected );
    $NA_protein_ratio = sprintf( "%.2f", $NA_protein_ratio );

    $returnData{-conc}          = $conc;
    $returnData{-sample_vol}    = $Vsample;
    $returnData{-EB_vol}        = $Veb;
    $returnData{-total_vol}     = $Vtot;
    $returnData{-ratio}         = $NA_protein_ratio;
    $returnData{-A260corrected} = $A260_corrected;
    $returnData{-A280corrected} = $A280_corrected;

    return \%returnData;
}

1;
