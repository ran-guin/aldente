#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use Getopt::Std;
use File::stat;
use Statistics::Descriptive;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

#use lib "/usr/local/ulib/prod/alDente/lib/perl/";
#use lib "/opt/alDente/versions/rguin/lib/perl/";

use RGTools::RGIO;
use SDB::CustomSettings;

use Sequencing::Sequencing_API;
use Illumina::Solexa_API;

use vars
    qw($opt_user $opt_password $opt_scope $opt_library $opt_project_id $opt_study_id $opt_run $opt_plate $opt_run $opt_well $opt_sample $opt_plate_number $opt_trace $opt_group $opt_key $opt_order $opt_limit $opt_quiet $opt_debug $opt_condition $Connection $opt_tables $opt_fields $opt_values $opt_file $opt_add_fields $opt_list_fields $opt_xml $opt_include_empty_fields $opt_dbase $opt_host $opt_attribute $opt_alias $opt_alias_type);
use vars
    qw($opt_alias_value $opt_type $opt_format $opt_plate_format $opt_include $opt_since $opt_until $opt_plate_type $opt_id $opt_barcode $opt_date_format $opt_rack $opt_flowcell $opt_solexa_run $opt_lane $opt_branch $opt_goal $opt_pipeline_id $opt_lookup $opt_equipment_category);

use Getopt::Long;
&GetOptions(
    'user=s'               => \$opt_user,
    'password=s'           => \$opt_password,
    'scope=s'              => \$opt_scope,
    'condition=s'          => \$opt_condition,
    'library=s'            => \$opt_library,
    'project_id=s'         => \$opt_project_id,
    'study_id=s'           => \$opt_study_id,
    'run=s'                => \$opt_run,
    'plate=s'              => \$opt_plate,
    'run=s'                => \$opt_run,
    'well=s'               => \$opt_well,
    'sample_id=s'          => \$opt_sample,
    'plate_number=s'       => \$opt_plate_number,
    'trace=s'              => \$opt_trace,
    'group=s'              => \$opt_group,
    'key=s'                => \$opt_key,
    'order=s'              => \$opt_order,
    'limit=s'              => \$opt_limit,
    'tables=s'             => \$opt_tables,
    'fields=s'             => \$opt_fields,
    'values=s'             => \$opt_values,
    'file=s'               => \$opt_file,
    'add_fields=s'         => \$opt_add_fields,
    'dbase=s'              => \$opt_dbase,
    'host=s'               => \$opt_host,
    'quiet'                => \$opt_quiet,
    'debug'                => \$opt_debug,
    'list_fields'          => \$opt_list_fields,
    'xml'                  => \$opt_xml,
    'include_empty_fields' => \$opt_include_empty_fields,
    'attribute=s'          => \$opt_attribute,
    'alias=s'              => \$opt_alias,
    'alias_type=s'         => \$opt_alias_type,
    'alias_value=s'        => \$opt_alias_value,
    'type=s'               => \$opt_type,
    'format=s'             => \$opt_format,
    'plate_format=s'       => \$opt_plate_format,
    'include=s'            => \$opt_include,
    'plate_type=s'         => \$opt_plate_type,
    'since=s'              => \$opt_since,
    'until=s'              => \$opt_until,
    'id=s'                 => \$opt_id,
    'barcode=s'            => \$opt_barcode,
    'date_format=s'        => \$opt_date_format,
    'rack=s'               => \$opt_rack,
    'flowcell=s'           => \$opt_flowcell,
    'solexa_run=s'         => \$opt_solexa_run,
    'lane=s'               => \$opt_lane,
    'branch=s'             => \$opt_branch,
    'pipeline_id=s'        => \$opt_pipeline_id,
    'goal=s'               => \$opt_goal,
    'lookup=s'             => \$opt_lookup,
    'equipment_category=s' => \$opt_equipment_category,
);

my $pass = 'aldente';

#$Connection = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims01',-user=>'lims_tester',-password=>$pass,-debug=>1);
#$Connection->connect();

my $user     = $opt_user     || 'Guest';
my $password = $opt_password || 'pwd';

my $debug              = $opt_debug;
my $quiet              = $opt_quiet;                            ## operate in quiet mode
my $list_fields        = $opt_list_fields;                      ## just list output fields
my $xml                = $opt_xml;
my $plate              = $opt_plate;
my $lib                = $opt_library;
my $project_id         = $opt_project_id;
my $study_id           = $opt_study_id;
my $run                = $opt_run;                              ## optional list of run ids
my $sample             = $opt_sample;
my $well               = $opt_well;
my $limit              = defined $opt_limit ? $opt_limit : 2;
my $number             = $opt_plate_number;
my $trace              = $opt_trace;
my $key                = $opt_group || $opt_key;
my $order              = $opt_order;
my $condition          = $opt_condition;                        # "Sequencing_Library_Type = 'SAGE' AND Run_Status = 'Analyzed'";
my $tables             = $opt_tables;
my $fields             = $opt_fields;
my $values             = $opt_values;
my $add_fields         = $opt_add_fields;
my $file               = $opt_file;
my $attribute          = $opt_attribute;
my $alias              = $opt_alias;
my $alias_type         = $opt_alias_type;
my $alias_value        = $opt_alias_value;
my $type               = $opt_type;
my $format             = $opt_format;
my $plate_format       = $opt_plate_format;
my $plate_type         = $opt_plate_type;
my $include            = $opt_include;
my $since              = $opt_since;
my $until              = $opt_until;
my $date_format        = $opt_date_format;
my $id                 = $opt_id;
my $barcode            = $opt_barcode;
my $scope              = $opt_scope;
my $rack               = $opt_rack;
my $flowcell           = $opt_flowcell;
my $solexa_run         = $opt_solexa_run;
my $lane               = $opt_lane;
my $branch             = $opt_branch;
my $pipeline_id        = $opt_pipeline_id;
my $goal               = $opt_goal;
my $lookup             = $opt_lookup;
my $equipment_category = $opt_equipment_category;

print "***********\n Connect to Database \n**************\n" if $debug;

## adjust scope for primer, buffer, matrix etc...
if ( $scope =~ /^(stock|equipment|solution|reagent|primer|buffer|matrix|box|kit|misc)/i ) {
    $type = $1 unless ( $scope =~ /stock/i );
    $scope = 'stock';
}
## include production, approved runs by default (if applicable)
$include = 'production,approved' unless ( $include || ( $scope =~ /(library|sage|project|stock)/ ) );

my $dbase = $opt_dbase || $Configs{BACKUP_DATABASE};
my $host  = $opt_host  || $Configs{BACKUP_HOST};

my $include_empty_fields = $opt_include_empty_fields;

my $db_user = 'viewer';
my $db_pwd  = 'viewer';

my $API        = Sequencing_API->new( -dbase => $dbase, -host => $host, -LIMS_user => $user, -LIMS_password => $password, -DB_user => $db_user, -DB_password => $db_pwd, -debug => 1 );
my $Solexa_API = Solexa_API->new( -dbase     => $dbase, -host => $host, -LIMS_user => $user, -LIMS_password => $password, -DB_user => $db_user, -DB_password => $db_pwd, -debug => 1 );
my $dbc        = $API->connect_to_DB();
my $example    = q{my $data = $API->};
$example .= "get_$scope" . "_data(";

my @options = ();
push( @options, "-plate_number=>$number" )         if $number;
push( @options, "-traces=>$trace" )                if $trace;
push( @options, "-library=>$lib" )                 if $lib;
push( @options, "-study_id=>$study_id" )           if $study_id;
push( @options, "-project_id=>$project_id" )       if $project_id;
push( @options, "-run_id=>$run" )                  if $run;
push( @options, "-well=>$well" )                   if $well;
push( @options, "-key=>$key" )                     if $key;
push( @options, "-order=>'$order'" )               if $order;
push( @options, "-plate_id=>$plate" )              if $plate;
push( @options, "-sample_id=>$sample" )            if $sample;
push( @options, "-condition=>\"$condition\"" )     if $condition;
push( @options, "-fields=>\"$fields\"" )           if $fields;
push( @options, "-values=>\"$values\"" )           if $values;
push( @options, "-attribute=>\"$attribute\"" )     if $attribute;
push( @options, "-alias=>\"$alias\"" )             if $alias;
push( @options, "-alias_type=>\"$alias_type\"" )   if $alias_type;
push( @options, "-alias_value=>\"$alias_value\"" ) if $alias_value;
push( @options, "-include=>\"$include\"" )         if $include;
push( @options, "-limit=>$limit" )                 if $limit;
push( @options, "-list_fields=>1" )                if $list_fields;
push( @options, "-type=>$type" )                   if $type;
push( @options, "-format=>$format" )               if $format;
push( @options, "-plate_format=>'$plate_format'" ) if $plate_format;
push( @options, "-plate_type=>'$plate_type'" )     if $plate_type;
push( @options, "-since=>'$since'" )               if $since;
push( @options, "-until=>'$until'" )               if $until;
push( @options, "-id=>$id" )                       if $id;
push( @options, "-barcode=>'$barcode'" )           if $barcode;
push( @options, "-date_format=>'$date_format'" )   if $date_format;
push( @options, "-rack=>$rack" )                   if $rack;
push( @options, "-flowcell=>$flowcell" )           if $flowcell;
push( @options, "-solexa_run=>$solexa_run" )       if $solexa_run;
push( @options, "-lane=>$lane" )                   if $lane;
push( @options, "-branch=>$branch" )               if $branch;
push( @options, "-pipeline_id=>$pipeline_id" )     if $pipeline_id;
push @options, "-lookup=>$lookup" if $lookup;
push @options, "-equipment_category=>$equipment_category" if $equipment_category;

if (@options) {
    print "Options set:\n";
    print join "\n", @options;
    print "\n\n";
}
else {    ## default options...
    Message("*** Using default options to illustrate usage ****");
    $lib ||= 'WS027';
    if ( $scope =~ /read/ ) { $number ||= '4,5'; }
    push( @options, "-library=>$lib" )           if $lib;
    push( @options, "-plate_number=>'$number'" ) if $number;
}

$example .= join ',', @options;
$example .= ");";

print "Eg:\n$example\n\n";

my $data;

my %args = (
    -library            => $lib,
    -project_id         => $project_id,
    -study_id           => $study_id,
    -plate_number       => $number,
    -traces             => $trace,
    -plate_id           => $plate,
    -well               => $well,
    -run_id             => $run,
    -sample_id          => $sample,
    -condition          => $condition,
    -add_fields         => $add_fields,
    -fields             => $fields,
    -values             => $values,
    -include            => $include,
    -quiet              => $quiet,
    -debug              => $debug,
    -limit              => $limit,
    -key                => $key,
    -order              => $order,
    -format             => $format,
    -plate_format       => $plate_format,
    -plate_type         => $plate_type,
    -list_fields        => $list_fields,
    -since              => $since,
    -until              => $until,
    -save               => 1,
    -id                 => $id,
    -barcode            => $barcode,
    -type               => $type,
    -date_format        => $date_format,
    -rack               => $rack,
    -flowcell           => $flowcell,
    -solexa_run         => $solexa_run,
    -lane               => $lane,
    -branch             => $branch,
    -pipeline_id        => $pipeline_id,
    -goal               => $goal,
    -lookup             => $lookup,
    -equipment_category => $equipment_category,
);

### Generate list of aliases (optionally supply a type / table) ###
if ( $scope =~ /alias/ ) { $API->list_Aliases($tables); }
elsif ( $scope =~ /stock/ ) {
    print "\n********* get $type Stock Data ****************\n";
    $data = $API->get_stock_data( %args, -attribute => $attribute, -alias_type => $alias_type, -alias_value => $alias_value );
}
## get sample ids only ##
elsif ( $scope =~ /(samples)/i ) {
    unless (@options) {
        $lib ||= 'LL005';
        $number ||= [ 250, 251 ];
    }
    print "\n********* Clone / Sample Data ****************\n";
    $data = $API->get_sample_ids( %args, -attribute => $attribute, -alias_type => $alias_type, -alias_value => $alias_value );
}
### get Sample/Clone data ###
elsif ( $scope =~ /(clone|sample)/i ) {
    ## default options ##
    unless (@options) {
        $lib ||= 'LL005';
        $number ||= [ 250, 251 ];
    }
    print "\n********* Clone / Sample Data ****************\n";
    $data = $API->get_sample_data( %args, -attribute => $attribute, -alias_type => $alias_type, -alias_value => $alias_value );
}

### get Read data ###
elsif ( $scope =~ /^read/i ) {
    ## default options ##
    unless (@options) {
        $lib ||= 'LL005';
        $number ||= [ 250, 251 ];
    }
    print "\n********* Read Data Example *******\n";
    $data = $API->get_read_data(%args);
}
### get Submission data ###
elsif ( $scope =~ /submission/ ) {
    print "\n************ Submission Data **************\n";
    $data = $API->get_submission_data(%args);
}
elsif ( $scope =~ /^run/i ) {
    ## default options ##
    unless (@options) {
        $lib ||= 'LL005';
        $number ||= [ 250, 251 ];
    }
    print "\n********* Run by Run Data Example ********\n";
    $data = $API->get_run_data(%args);
}
elsif ( $scope =~ /set_run/i ) {

    $args{-fields} = [ Cast_List( -list => $args{-fields}, -to => 'array' ) ];
    $args{ -values } = [ Cast_List( -list => $args{ -values }, -to => 'array' ) ];
    $data = $API->set_run_data(%args);
}
elsif ( $scope =~ /set_solexa/i ) {
    $args{-fields} = [ Cast_List( -list => $args{-fields}, -to => 'array' ) ];
    $args{ -values } = [ Cast_List( -list => $args{ -values }, -to => 'array' ) ];
    my $solexa_dbc = $Solexa_API->connect_to_DB();
    $data = $Solexa_API->set_solexa_data(%args);
    $solexa_dbc->disconnect();
}
elsif ( $scope =~ /event/i ) {

    print "\n********* Event Data extraction Example ********\n";    ## this is used to extract 'Prep' records
    $data = $API->get_event_data(%args);
}
elsif ( $scope =~ /application/i ) {
    print "\n********* Get Applied Reagents Example ********\n";
    $data = $API->get_application_data(%args);
}
### get MEDIANS fields ###
elsif ( $scope =~ /median/ ) {
    ## default options ##
    unless (@options) {
        $lib ||= 'WS027';
    }

    my $group      = "Left(Run_DateTime,10) as Month";
    my $group_name = 'library';
    $args{-fields}  = ( $group, 'Run_ID', 'Q20array', 'Average_Q20', 'run_id', 'run_name', 'library' );
    $args{-include} = 'approved,production';
    $data           = $API->get_run_data(%args);

    #-condition=>$condition,-fields=>\@fields,-save=>1,-include=>'Production');
    my $record_num = 0;
    my %Group;
    my $record_num = $API->next_record;
    while ( defined $record_num ) {
        my %record = %{ $API->get_record() };
        my @q20    = unpack "S*", $record{Q20array};
        my $count  = int(@q20);
        my $group  = $record{$group_name};

        #print Dumper($API->get_record());
        push( @{ $Group{$group} }, @q20 );    ## tally up the Q20 values...
        my @sorted = sort { $a <=> $b } @q20;
        my $total = 0;
        map { $total += $_ } @q20;
        my $avg = $total / $count if $count;
        print "$record_num: $group : $record{Average_Q20} \n" unless $quiet;
        $record_num = $API->next_record;

        #	$record_num++;
    }
    foreach my $group ( sort keys %Group ) {
        my @array = @{ $Group{$group} };
        my $stat  = Statistics::Descriptive::Full->new();
        $stat->add_data(@array);
        my $median = $stat->median();
        my $count  = $stat->count();
        print "Median $group: $median (of $count reads)\n";
    }
    leave();
}
elsif ( $scope =~ /^quality/ ) {
    $limit = 1;
    print "\n********* Read Quality Data Example *******\n";
    $args{-fields} = [ 'Clone_Sequence.Sequence_Scores', 'SequenceAnalysis.Wells', 'Phred_Histogram', 'Clone_Sequence.Quality_Histogram', 'Sequence_Length', 'Quality_Length' ];
    $API->get_read_data(%args);

    my $data  = $API->get_record();
    my @array = unpack "C*", $data->{Sequence_Scores};
    my @phist = unpack "S*", $data->{Phred_Histogram};
    my @qhist = unpack "S*", $data->{Quality_Histogram};
    foreach my $index ( 10, 20, 30, 40 ) {
        print "\nQ$index:\t" . $qhist[$index] . "\n";
    }
    print "SL: " . $data->{Sequence_Length} . "\n";
    print "QL: " . $data->{Quality_Length} . "\n";

    print "Phred Quality Array:\n@phist";
    my @keys = keys %$data;
    &leave();
}
### get Oligo data ###
elsif ( $scope =~ /oligo/i ) {
    print "\n********* Read Data including Oligo info Example ********\n";
    ## default options ##
    unless (@options) {
        $lib ||= 'LL005';
        $number ||= [ 250, 251 ];
    }
    my $alias = [ 6180739, 6179927 ];
    my $alias_type = 'MGC';
    $data = $API->get_oligo_data(%args);

}
elsif ( $scope =~ /plate_read/ ) {
    print "***** Plate Read Information ******\n";
    $data = $API->get_plate_reads(%args);    ## -plate_id=>$plate,-well=>$well,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
}
elsif ( $scope =~ /plate_count/i ) {
    print "***** Plate Information ******\n";
    $data = $API->get_plate_count(%args);
}
elsif ( $scope =~ /plate\b/i ) {
    print "***** Plate Information ******\n";
    $data = $API->get_plate_data(%args);
}
elsif ( $scope =~ /rearray/i ) {
    print "***** ReArray Information ******\n";
    $data = $API->get_rearray_data(%args);
}
elsif ( $scope =~ /lib/i ) {
    print "\n********* Group Library Data Example ($study_id $limit) ************\n";
    $data = $API->get_library_data(%args);
}
elsif ( $scope =~ /sage/i ) {
    print "\n********* SAGE Data Example ($study_id $limit) ************\n";
    $data = $API->get_SAGE_data(%args);
}
elsif ( $scope =~ /concentration/i ) {
    print "\n********* Group Concentration Data Example ************\n";
    $data = $API->get_concentration_data(%args);
}
elsif ( $scope =~ /primer/i ) {
    print "\n********* get Primer Data Example ************\n";
    $data = $API->get_primer_data(%args);
}
elsif ( $scope =~ /pipeline/i ) {
    print "\n********* get Pipeline Data Example ************\n";
    $data = $API->get_pipeline_data(%args);
}
## <CONSTRUCTION> - tested to here.... ##
## library
## concentration data (for rearrayed clones ?) ...
## gel
## array ?
# pool ?
#
## sample data (concentration.. rearray ?)
##
#elsif ($scope =~/gel/i) {
#    print "\n********* Group Library Data Example ************\n";
#    $data = $API->get_gel_data(-library=>$lib,-project=>$project_id,-study_id=>$study_id,-condition=>$condition,
#			       -quiet=>$quiet,-debug=>$debug,-limit=>$limit,-key=>$key,-format=>$format,-list_fields=>$list_fields,-save=>1,-verbose=>1);
#}
#elsif ($scope =~/array/i) {
#    print "\n********* Group Library Data Example ************\n";
#    $data = $API->get_library_data(-library=>$lib,-project=>$project_id,-study_id=>$study_id,-condition=>$condition,
#				   -quiet=>$quiet,-debug=>$debug,-limit=>$limit,-key=>$key,-format=>$format,-list_fields=>$list_fields,-save=>1,-verbose=>1);
#}

#elsif ($scope =~/pool/i) {
#    $lib = 'TL110';  ## this one works ...
#	print "\n********* Pool Data Example *************\n";
#	print "\n*** Clone specific data ***\n";
##	  print "my \$clone_data = $API->get_Clone_data(-connection=>\$Connection,-pool=>$lib,-limit=>2,-format=>'array');}\n\n";
##	  my $clone_data = $API->get_Clone_data(-connection=>$Connection,-pool=>$lib,-limit=>2,-format=>'array',-quiet=>$quiet,-debug=>$debug);
##	  print "\n\n" . Dumper($clone_data);
##
##	  print "\n*** Run specific data (Note different default keys if 'group_by' or 'key' option specified) ***\n";
##	  print "\n** No grouping: ..\n";
##	  print "my \$run_data1 = $API->get_Run_data(-connection=>\$Connection,-pool=>$lib,-limit=>2,-format=>'array');}\n\n";
##	  my $run_data1 = $API->get_Run_data(-connection=>$Connection,-pool=>$lib,-limit=>2,-format=>'array',-quiet=>$quiet,-debug=>$debug);
##	  print Dumper($run_data1);
##
##	  print "\n** WITH grouping: ..\n";
##	  print "my \$run_data2 = $API->get_Run_data(-connection=>\$Connection,-pool=>$lib,-limit=>2,-key=>'library');}\n\n";
##	  my $run_data2 = $API->get_Run_data(-connection=>$Connection,-pool=>$lib,-limit=>2,-key=>'library',-quiet=>$quiet,-debug=>$debug);
##	  print Dumper($run_data2);
##} elsif ($scope =~/array/) {
##    print "\n******** ReArray information ************\n";
##    print q{my \@fields = ('rearray_type','rearray_datetime','concentration_datetime','sample_id','rack');} . "\n";
##	  print q{my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,concentration_well",-fields=>\@fields,-rearray=>0,-quiet=>$quiet,-debug=>$debug);} . "\n\n";
##
##	  my @fields = ('concentration_datetime','concentration','plate_created','sample_id','rack');
##	  my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,concentration_well",-fields=>\@fields,-rearray=>0,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##	  print Dumper($data) unless $debug;
##
##	  print "\n*** Similar query but with rearray option turned ON (with different fields extracted) ***\n\n";
##	  print q{my @fields = ('rearray_type','rearray_datetime','concentration_datetime','sample_id','rack');} . "\n";
##	  print q{my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,concentration_well",-fields=>\@fields,-rearray=>0,-quiet=>$quiet,-debug=>$debug);} . "\n\n";
##	  my @fields = ('rearray_type','rearray_datetime','concentration_datetime','sample_id','rack');
##	  $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,concentration_well",-fields=>\@fields,-rearray=>1,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##	  print Dumper($data) unless $debug;
##
##	  print "\n*** Get Plate information for plates that were NOT rearrayed - to compare phred scores: ***\n\n";
##	  print "my \$data = $API->get_plate_reads(-connection=>\$Connection,-plate_id=>$plate,-well=>$well);\n\n"; ##
##	  $data = $API->get_plate_reads(-connection=>$Connection,-plate_id=>$plate,-well=>$well,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##	  print Dumper($data) unless $debug;
##} elsif ($scope =~/conc/) {
##    print "*** Three steps to extracting Concentration Data (given sample_ids) : **\n*";
##    print "** 1 - Get general clone data (optional) - no fields specified **\n";
##    my $list_fields_fields = 0;
##    print q{my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>'763388,763394',-format=>'array');} . "\n\n";
##    my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-format=>'array',-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##    print Dumper($data) unless $debug;
##
##    print "** 2 - Get only concentration info keyed on plate,well (for concentration run) **\n";
##    print q{my @fields = ('concentration_datetime','concentration','plate_test_status','rack','sample_id');} . "\n\n";
##    print q{my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,'-',concentration_well",-fields=>\@fields,-quiet=>$quiet,-debug=>$debug);} . "\n\n";
##
##    my @fields = ('concentration_datetime','concentration','plate_test_status','rack','sample_id');
##    my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,'-',concentration_well",-fields=>\@fields,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##    print Dumper($data) unless $debug;
##
##    print "** 3 - Get concentration for rearrayed clones (add -rearray=>1 switch) **\n";
##    print q{my @fields = ('rearray_type','rearray_datetime','concentration_datetime','concentration','plate_test_status','rack','sample_id');} . "\n\n";
##    print q{my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>'763388,763394',-key=>"concentration_plate,'-',concentration_well",-fields=>\@fields,-rearray=>1,-quiet=>$quiet,-debug=>$debug);} . "\n\n";
##
##    my @fields = ('rearray_type','rearray_datetime','concentration_datetime','concentration','plate_test_status','rack','sample_id');
##    my $data =  $API->get_Clone_data(-connection=>$Connection,-sample_id=>$sample,-key=>"concentration_plate,'-',concentration_well",-fields=>\@fields,-rearray=>1,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##    print Dumper($data) unless $debug;
##
##    print "** 4 - Get plate read information for specified plates **\n";
##    print q{  my $data = $API->get_plate_reads(-connection=>$Connection,-plate_id=>'29483,29484,29485,29486',-well=>'E02',-quiet=>$quiet,-debug=>$debug); } . "\n\n";
##    my $data = $API->get_plate_reads(-connection=>$Connection,-plate_id=>$plate,-well=>'E02',-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
##    print Dumper($data) unless $debug;
#}

### Old methods still supported ###

#     my $data = &update_Clone(-dbc=>$dbc,-sample_id=>$sample,-score=>$score,-vector=>$vector,-row=>$row,-col=>$col,-library_id=>$lib_id,-comments=>$comments,-source_name=>'LLNL',-alias=>{'IMAGE'=>12345,'MGC'=>'666'});
#     print Dumper($data) unless $debug;
elsif ( $scope =~ /primer/ ) {
    print "***** Primer Information ******\n";
    my $data = $API->get_Primer_data(
        -condition   => $condition,
        -add_fields  => $add_fields,
        -fields      => $fields,
        -custom      => 1,
        -oligo       => 1,
        -primer      => 'MGC_27',
        -quiet       => $quiet,
        -debug       => $debug,
        -limit       => $limit,
        -key         => $key,
        -format      => $format,
        -list_fields => $list_fields,
        -save        => 1,
        -verbose     => 1
    );
    print Dumper($data) unless $debug;
}
elsif ( $scope =~ /source/ ) {    ## not sure what needs to be done here
    $data = $API->get_source_data(%args);
}
elsif ( $scope =~ /clone_source/ ) {
    ## specific functionality for dealing with Clone_Source information:

    print "** Example 1: Clone Source Checking (get list of plates with missing Source info - must supply collection name) **\n";
    print q{my $data = &update_Clone(-dbc=>$dbc,-source_collection=>$lib);} . "\n\n";
    my $data = &update_Clone( -dbc => $dbc, -source_collection => $lib, -quiet => $quiet, -debug => $debug, -limit => $limit );
    print Dumper($data) unless $debug;

    print "** Example 2: Clone Source Checking (get sample_ids/well/source_row/source_col given collection/plate **\n";
    print q{my $data = &update_Clone(-dbc=>$dbc,-source_collection=>$lib,-source_plate=>$plate);} . "\n\n";
    my $data = &update_Clone( -dbc => $dbc, -source_collection => $lib, -source_plate => $plate, -quiet => $quiet, -debug => $debug, -limit => $limit );
    print Dumper($data) unless $debug;

    print "** Example 3: Clone Source Updating (specifying sample_id) **\n\n";
    my ( $sample, $well, $row, $col, $score, $vector, $lib_id, $image, $mgc, $comments ) = ( '756578', 'A01', 'a', 1, 257, 'pOTB7', 1408, 2820595, 78588, '' );
    print q{my $data = &update_Clone(-dbc=>$dbc,-sample_id=>$sample,-score=>$score,-vector=>$vector,-row=>$row,-col=>$col,-library_id=>$lib_id,-comments=>$comments,-source_org_id=>38,-source_name=>'12345',-alias=>{'IMAGE'=>12345,'MGC'=>'666'});} . "\n\n";
    print "\n\n(This is not executed in this case since it would update the database !)...\n\n";
}
elsif ( $scope =~ /lineage/ ) {
    print "***** Plate Lineage Information ******\n";
    print "** Example 1: Retrieve Plate lineage information for a particular generation **\n";
    print "**  (Absolute generation specified (ie 2 => '2nd generation')  **\n";
    print q{$data = $API->get_plate_lineage(-dbc=>$dbc,-plate_id=>$plate,-generation=>2)} . "\n\n";
    $data = $API->get_plate_lineage( -dbc => $dbc, -plate_id => $plate, -generation => 3, -quiet => $quiet, -debug => $debug, -limit => $limit );
    print Dumper($data) unless $debug;

    print "**  (Relative generation specified (ie +1 => 1 generation ahead - children; -1 => parent )  **\n";
    print q{$data = $API->get_plate_lineage(-dbc=>$dbc,-plate_id=>$plate,-generation=>-1)} . "\n\n";
    $data = $API->get_plate_lineage( -dbc => $dbc, -plate_id => $plate, -generation => '-1', -quiet => $quiet, -debug => $debug, -limit => $limit );
    print Dumper($data) unless $debug;

    print "** Example 2: Retrieve Plate lineage information for all generations **\n";
    print q{$data = $API->get_plate_lineage(-dbc=>$dbc,-plate_id=>$plate)} . "\n\n";
    $data = $API->get_plate_lineage( -dbc => $dbc, -plate_id => $plate, -quiet => $quiet, -debug => $debug, -limit => $limit );
}
elsif ( $scope =~ /transposon/ ) {
    print "** Example showing definition of a new Transposon Pool **\n\n";
    print
        q{my $data = define_Pool(-dbc=>$dbc,-full_name=>'Test Pool #1',-transposon_id=>1,-plate_id=>'50635',-wells=>['A01','A02','B01','B02','H12'],-date=>'1999-01-01',-name=>'TESTA',-pipeline=>'Standard',-gel_id=>22,-reads_required=>100,-status=>'Ready for Pooling',-goals=>'goals.');}
        . "\n\n";
    print "\n(similar example using multiple plates - note number of plates must match number of wells in this case)\n\n";
    print
        q{my $data = define_Pool(-dbc=>$dbc,-full_name=>'Test Pool #1',-transposon_id=>1,-plate_id=>['50635','50635','50635','50635','50635'],-wells=>['A01','A02','B01','B02','H12'],-date=>'1999-01-01',-name=>'TESTA',-pipeline=>'Standard',-gel_id=>22,-reads_required=>100,-status=>'Ready for Pooling',-goals=>'goals.');}
        . "\n\n";
}
elsif ( $scope =~ /lookup/ ) {
    $data = $API->get_lookup_data(%args);
}
elsif ( $scope =~ /solexa/ ) {
    my $solexa_dbc = $Solexa_API->connect_to_DB();
    $data = $Solexa_API->get_solexa_run_data(%args);
    $solexa_dbc->disconnect();
}
elsif ( $scope =~ /gel/ ) {
    print "***** Sizing Gel Information ******\n";
    $args{-fields} ||= [ 'run_id', 'run_status', 'Poured', 'PouredDate', 'poured_equipment', 'agarose_solution', 'Comb', 'GelTray', 'run_comments' ];
    $data = $API->get_gelrun_data( %args, -add_fields => $add_fields, -run_status => '' );
}
else {

    print <<HELP;
Usage:
*********

    shell_API.pl -scope <scope> [options]

	Scope indicates the scope of data retrieval. Options include:
               
           sample, read, oligo (subset of read), run, library, SAGE (subset of library), plate, rearray (subset of plate data), concentration

Record filtering options:
**************************     
    -study <study_id>        - specify a particular study
    -project <project_id>>   - specify a particular project
    -library <library>       - use (library) as the library (or collection) in the example
    -run_id <run_id>         -
    -plate_number <number>   - use (number) as the plate number in the example
    -plate   <plate_id>        - use (plate) for the plate_id in the example
    -well    <well>             - use (well) as the well in the example
    -sample  <sample_id>        - use (sample) as the sample_id in the example
    -include                 - allows for specific inclusion of test / development runs (defaults to 'Approved' AND 'Production' runs only)
    -condition <condition>   - add the indicated condition to the query
    -plate_format <format>     - indicate the format of plate (eg. Beckman) you are looking for (only for get_plate_data)
    -plate_type <type>         - indicate the type of plate (eg Tube / Library_Plate) you are looking for (only for get_plate_data)
    -rack <rack_id>            - indicate the rack of interest (eg to find all plates on a given rack)

Output format options:
**********************
    -add_fields <fields>     - adds indicated fields to the current default field list
    -fields <fields>         - overrides the default field list
    -group <group field>     -
    -key <key>               - indicate a key that should be used to group and organize the return hash.
    -format <format>         - allows user to specify a hash or array output (if key is used, then output is forced to a hash)
    -file <file> [-xml]      - output is redirected to <file> (use '-xml' switch for xml output - defaults to tab-delimited).
    -date_format <format>  (SQL or Simple) - defaults to 'Simple' (more readable eg: 'Jan-01, 2005')

Other options:
******************
    -quiet                   - suppress most feedback
    -limit <limit>           - limit output data example to only 'limit' records (defaults to 2) - use 0 for no limit.

Special cases for running script without executing actual query  
*******************************************************************
    -debug                   - generates the SQL statement, but stops before executing it.
    -list_fields             - just generate a list of applicable output fields


At the beginning of the output is a dynamically generated string indicating the usage of this call within perl.


eg. if you call this script with the scope = sample; sample = 200603, the output generates the perl syntax:

my \$data = \$API->get_sample_data(-sample=>200603);


Examples:
***********

shell_API -scope read -library MGC01 -plate_number 1

HELP

}

print "\n\n";
&leave();

############
sub leave {
############
    if ($file) {
        Message("Saving to $file");
        open( FILE, ">$file" ) or die "Cannot open $file\n";

        my $records       = $API->records();
        my @keys          = sort keys %{$data};
        my @output_fields = Cast_List( -list => $fields, -to => 'array' ) if $fields;    ## reorder them if supplied

        my $columns = 0;

        if ( $records > 1 ) { $columns = 1; }

        my $separator;

        Message("Found $records records..");
        if ($data) {
            print "\n*** $example ***\n\n";
            print "\n*** Data: ***\n\n";
            print Dumper($data);
        }
        if ($columns) {
            $separator = "\t";

        }
        else {
            $separator = "\n";
        }
        my $data_type = ref $data->{ $keys[0] };
        my $output;
        if ($xml) { $output .= "<xml>\n" }

        if ( $data_type eq 'HASH' ) {
            Message("Retrieving data from hash");
            foreach my $key (@keys) {
                unless (@output_fields) {
                    @output_fields = keys( %{ $data->{$key} } );
                }
                $output .= "<$key>\n" if $xml;
                foreach my $field (@output_fields) {
                    $data->{$key}{$field} =~ s/\s+/ /g;    ## replace spaces with ' ' (in case of linefeeds or tabs)
                    if ($xml) {
                        $output .= "\t<$field>" . $data->{$key}{$field} . "</$field>\n" if ( $data->{$key}{$field} || $include_empty_fields );
                    }
                    else {
                        my $prefix = "$field\t" unless ($columns);    ## include field name if only one record
                                                                      #print FILE $prefix . $data->{$key}{$field} . $separator;
                        $output .= $prefix . $data->{$key}{$field} . $separator if ( $data->{$key}{$field} || $include_empty_fields );
                    }
                }
                $output .= "</$key>\n" if $xml;

                #print FILE "\n";
                $output .= "\n";
            }
        }
        else {
            Message("Retrieving array of data");
            ## retrieve data from large arrays...
            foreach my $index ( 1 .. $records ) {
                unless (@output_fields) {
                    @output_fields = keys %{$data};
                }
                $output .= "<$scope>\n" if $xml;
                foreach my $key (@output_fields) {
                    $data->{$key}[ $index - 1 ] =~ s/\s+/ /g;    ## replace spaces with ' ' (in case of linefeeds or tabs)
                    if ($xml) {
                        $output .= "\t<$key>" . $data->{$key}[ $index - 1 ] . "</$key>\n" if ( $data->{$key}[ $index - 1 ] || $include_empty_fields );
                    }
                    else {
                        my $prefix = "$key\t" unless ($columns);    ## include field name if only one record
                                                                    #	print FILE $prefix . $data->{$key}[$index-1] . $separator;
                        $output .= $prefix . $data->{$key}[ $index - 1 ] . $separator if ( $data->{$key}[ $index - 1 ] || $include_empty_fields );
                    }
                }

                #print FILE "\n";
                $output .= "</$scope>\n" if $xml;
                $output .= "\n";
            }
        }
        if ($columns) {
            print FILE join $separator, @output_fields unless $xml;    ## include header if more than one record
            print FILE "\n";
        }
        if ($xml) { $output .= "</xml>" }
        print FILE $output;
    }

    if ($data) {
        print "\n*** $example ***\n\n";
        print Dumper($data) unless ( $quiet || $debug );
        print "\n*** or... while ( defined \$API->next_record ) { print Dumper(\$API->get_record() }  ***\n\n";
        my $stop = $limit;
        while ( ( defined $API->next_record() ) && $stop-- ) {
            print Dumper( $API->get_record() ) unless ( $quiet || $debug );
        }
    }
    if ($dbc) { $dbc->disconnect() }

    print $API->warnings;
    print $API->errors;

    exit();
}

## No longer supported ...##
#
# get_Plate_data
# get_Clone_data
# get_Read_data
# get_Run_data
# get_Gel_data
# get_Concentration_data
#
#
#} elsif ($scope =~/plate/) {
#    print "***** Plate Information ******\n";
#    print "my \$data = $API->get_Plate_data(-dbc=>\$dbc,-plate_id=>$plate,-well=>$well,-quiet=>$quiet,-debug=>$debug);\n\n";
#    my $data = $API->get_Plate_data(-plate_id=>$plate,-well=>$well,-quiet=>$quiet,-debug=>$debug,-limit=>$limit);
#    print Dumper($data) unless $debug;
#}
