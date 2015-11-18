#!/usr/local/bin/perl

##############################################################################################
# Quick program written to generate Trace file submissions based upon NCBI standard protocol.
#
#  This should be scalable eventually to handle various submission types.
##############################################################################################

## standard perl modules ##
use CGI qw(:standard fatalsToBrowser);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);
use Storable;
use Statistics::Descriptive;
use Data::Dumper;
use Digest::MD5;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Net::FTP;

use strict;

## Local perl modules ##

# (generic modules)
use RGTools::RGIO;
use RGTools::Conversion;

# (SQL database modules)

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

# (alDente modules)
use alDente::Run;
use alDente::Container;
use alDente::Clone;
use alDente::SDB_Defaults;

# (Sequencing specific modules)
use Sequencing::Sequencing_API;

# (locally imported modules)
use Imported::XML::Dumper;

##############################
# global_vars                #
##############################
use vars qw($testing $Connection $ftp);

#use vars qw($opt_t $opt_g $opt_l $opt_p $opt_r $opt_x $opt_f $opt_L $opt_X $opt_a $opt_R $opt_P $opt_v $opt_u $opt_O $opt_d $opt_c);
use vars
    qw($opt_limit $opt_include $opt_library $opt_plate $opt_run $opt_group $opt_append $opt_compress $opt_remove $opt_include_poor $opt_force $opt_xml $opt_quiet $opt_verbose $opt_update $opt_target $opt_date $opt_comment $opt_path $opt_name $opt_user $opt_password $opt_min_length $opt_submission_type $opt_trace_list_file $opt_F $opt_R $opt_upload $opt_monitor $opt_project $opt_volumes $opt_volume $opt_sample $opt_type $opt_measure $opt_measure_by $opt_copy_traces);

#require "getopts.pl";
use Getopt::Long;
&GetOptions(
    'limit=s'           => \$opt_limit,
    'library=s'         => \$opt_library,
    'plate=s'           => \$opt_plate,
    'run=s'             => \$opt_run,
    'group=s'           => \$opt_group,
    'remove=s'          => \$opt_limit,
    'update=s'          => \$opt_update,
    'target=s'          => \$opt_target,
    'date=s'            => \$opt_date,
    'comment=s'         => \$opt_comment,
    'path=s'            => \$opt_path,
    'name=s'            => \$opt_name,
    'user=s'            => \$opt_user,
    'password=s'        => \$opt_password,
    'min_length=s'      => \$opt_min_length,
    'F=s'               => \$opt_F,
    'R=s'               => \$opt_R,
    'submission_type=s' => \$opt_submission_type,
    'trace_list_file=s' => \$opt_trace_list_file,
    'upload=s'          => \$opt_upload,
    'volume=s'          => \$opt_volume,
    'volumes=s'         => \$opt_volumes,
    'project=s'         => \$opt_project,
    'sample=s'          => \$opt_sample,
    'type=s'            => \$opt_type,
    'include=s'         => \$opt_include,
    ## booleans ##
    'monitor'      => \$opt_monitor,
    'compress'     => \$opt_compress,
    'quiet'        => \$opt_quiet,
    'verbose'      => \$opt_verbose,
    'remove'       => \$opt_remove,
    'append'       => \$opt_append,
    'xml'          => \$opt_xml,
    'force'        => \$opt_force,
    'include_poor' => \$opt_include_poor,
    'measure'      => \$opt_measure,
    'measure_by'   => \$opt_measure_by,
    'copy_traces'  => \$opt_copy_traces,
);

## parse input options ##
my $type         = $opt_type;
my $include      = $opt_include || 'production,approved';                 ## indicate runs to be included (defaults to production, approved.
my $run_limit    = $opt_limit || 5000;                                    ## limit of number of traces to group in one tarred file
my $library      = $opt_library;                                          ## provide Library
my $plate_number = $opt_plate;                                            ## provide plate number (or list / range) (optional with library)
my $run_id       = $opt_run;                                              ## ... or provide run id (or list)
my $sample       = Cast_List( -list => $opt_sample, -to => 'string' );    ## ... or provide sample ids
my $group_by     = $opt_group;                                            ## group volumes
my $append       = $opt_append;                                           ## append current volume
my $compress     = $opt_compress;
my $remove       = '--remove_files' if $opt_remove;                       ##
my $group;

my $include_poor = $opt_include_poor || 0;                                ## include poor quality (no quality length) reads
my $min_length   = $opt_min_length   || 0;
my $force        = $opt_force        || 0;                                ## force execution without feedback check.
my $xml          = $opt_xml;
my $verbose      = $opt_verbose;
my $update_volume       = $opt_update;                                    ## indicate current volume if this for updating or appending
my $target_organization = $opt_target;
my $submission_date     = $opt_date || &date_time();
my $comments            = $opt_comment || '';
my $path                = $opt_path || '.';
my $basename            = $opt_name || $opt_library || 'trace_files';     ## default to library name if entire library submitted (default)
my $user                = $opt_user || 'viewer';
my $password            = $opt_password || 'viewer';
my $submission_type     = $opt_submission_type || 'new';
my $trace_list_file     = $opt_trace_list_file;
my $upload              = $opt_upload;
my $monitor             = $opt_monitor;
my $project             = $opt_project;
my $volumes             = $opt_volumes || 1;
my $volume              = $opt_volume || '';
my $quiet               = $opt_quiet || 1;                                ## always quiet !! (?)
my $measure             = $opt_measure;                                   # || 'quality_length';
my $measure_by          = $opt_measure_by || 'CLONE_ID';
my $copy_traces         = $opt_copy_traces || 1;

#my $key_field = 'PRIMER_CODE';
my $key_field = 'TRACE_END';
## Check if measure is valid?

## Default file extension for TraceInfo
my $ext = 'txt';
if ($xml) { $ext = 'xml' }                                                ## adapt file extension if xml format specified

my $dbase = $Configs{PRODUCTION_DATABASE};
my $host  = $Configs{PRODUCTION_HOST};

## initialize variables ##
my $target = "$path/$basename";
my $log    = "$target.log";

## option to just upload files in the upload directory (eg  -upload BE000_test.tar.gz)
if ( defined $upload ) {
    my $uploaded = _ftp_upload( -site => 'ftp.ncbi.nlm.nih.gov', -file => $upload );
    print "\nFinished upload attempt (uploaded $uploaded files)\n";
    exit;
}
elsif ($monitor) {
    _ftp_monitor( -site => 'ftp.ncbi.nlm.nih.gov' );
    exit;
}

### Initialize variables ###
my $md5              = 1;
my $skip_on_warnings = 1;
my @errors;
my @warnings;
my @notes;
my $total_found = 0;
my $added       = 0;
my $total_added = 0;
my $skipped     = 0;
my $aborted     = 0;
my $poor        = 0;
my ($date) = split ' ', &date_time();
my $volume_name = $basename;
my $user_id     = 4;           ## auto-submitted by Ran..

if ( $append && ( $user eq 'viewer' ) ) {
## check user / password if not already reset ...
    print "Updating Database as:\n\nusername >";
    $user = Prompt_Input( -type => 'string' );
    print "\npassword >";
    $password = Prompt_Input( -type => 'password' );
}

## connect to Sequencing_API ##
my $API = Sequencing_API->new( -dbase => $dbase, -host => $host, -DB_user => $user, -DB_password => $password );
my $dbc = $API->connect_to_DB();
unless ( $dbc && $dbc->ping() ) { Message("sorry Cannot connect as $user to alDente with specified password"); &leave(); }

print "*** Connected as $user\n";

my $fixed            = 0;
my $compressed       = 0;
my $total_compressed = 0;
### This loop will only be run when user specifies -compress option (aborts after this block) ###

### <CUSTOM> ###
my $max_volume = $volume + $volumes - 1;
my @volumes    = ( $volume .. $max_volume );    ## (1..$volumes);

if ($compress) {
    unless ( -e "tar_files/upload/" ) { Message("tar_files/upload/ directory not found. (create or move to project directory)"); exit; }
    foreach my $vol (@volumes) {
        ###### Intentions #######
        my $vol_name = $volume_name . "_" . $vol;
        if ( $volumes == 1 ) { $vol_name = $volume_name }    ## Don't worry about a suffix if only one volume..

        print "Found Volume $vol ($vol_name)\n";
    }

    foreach my $vol (@volumes) {
        my $vol_name = $volume_name . "_" . $vol;

        ###### COMPRESS #######
        print "Compressing Volume $vol ($vol_name)";

        `tar -zcvf tar_files/upload/$vol_name.tar.gz $vol_name/`;
        print "(compressed $vol_name)\n";
        $total_compressed += $compressed;
    }
    print "Compressed $total_compressed Files into tar_files/upload directory\n\n";
    exit;
}

## Parse Input Arguments ##

my $plate_number_list;
if ($plate_number) { $plate_number_list = extract_range($plate_number); }
if ( $group_by =~ /plate_id/i ) {
    $group = 'Plate_ID';
}
elsif ( $group_by =~ /run/ ) {
    $group = 'Run_ID';

    #} elsif ($group_by =~/plate_number/i) {            ## need to group by Library AND Plate_Number ##
    #    $group = 'Plate_Number';
}
elsif ( $group_by =~ /library/i ) {
    $group = 'Library_Name';
}
else {    ## default grouping by run ##
    $group = 'RUN_GROUP_ID';
}

################## INPUT SPECIFICATIONS #######################################

### Indicate which fields MUST be included ###

my @Mandatory_Fields = (
    'CLONE_ID',

    #			'ACCESSION'
);

my @Mandatory_Fields;
## Order of Standard Output Fields ##

my %Common_Field;
$Common_Field{CENTER_NAME}     = 'BCCAGSC';           ## this CANNOT be changed as it is our official centre_name (like user_id)
$Common_Field{CHEMISTRY_TYPE}  = 't';                 ## terminator (vs primer)
$Common_Field{TRACE_FORMAT}    = 'abi';               ## format of trace files
$Common_Field{SUBMISSION_TYPE} = $submission_type;    ## eg. new or update

## Start off with standard fields to be included with all submission types ##
my @Order
    = ( 'CLONE_ID', 'TRACE_NAME', 'TEMPLATE_ID', 'CENTER_PROJECT', 'PLATE_ID', 'WELL_ID', 'PRIMER', 'PRIMER_CODE', 'PROGRAM_ID', 'RUN_GROUP_ID', 'RUN_DATE', 'RUN_MACHINE_ID', 'RUN_MACHINE_TYPE', 'LIBRARY_ID', 'SPECIES_CODE', 'TRACE_FILE', 'TRACE_END' );

## generate Alias from standard XML Tag names for NCBI repository -> LIMS alias names
my %Alias;
$Alias{PLATE_ID}        = 'Plate_ID';
$Alias{WELL_ID}         = 'Clone_Sequence.Well';
$Alias{sample_id}       = 'Clone_Sequence.FK_Sample__ID';
$Alias{run_id}          = 'Run_ID';
$Alias{library}         = 'Library_Name';
$Alias{sequence_length} = 'sequence_length';
$Alias{trimmed_length}  = 'trimmed_length';
$Alias{well}            = 'Clone_Sequence.Well';
$Alias{quality_length}  = "Quality_Length";
$Alias{PRIMER}          = "primer_sequence";

#$Alias{PRIMER}   = "Replace(Primer_Sequence,' ','')";
$Alias{PRIMER_CODE}        = 'Primer.Primer_Name';
$Alias{PROGRAM_ID}         = "Concat('phred-',SequenceAnalysis.Phred_Version)";
$Alias{RUN_DATE}           = 'Left(Run_DateTime,10)';
$Alias{RUN_GROUP_ID}       = 'Run_ID';
$Alias{RUN_MACHINE_ID}     = 'FK_Equipment__ID';
$Alias{RUN_MACHINE_TYPE}   = "Stock_Catalog.Model";
$Alias{SOURCE_TYPE}        = "CASE WHEN Vector_Based_Library.Vector_Based_Library_Type like 'Mapping%' THEN 'G' ELSE 'N' END";
$Alias{SPECIES_CODE}       = 'Taxonomy.Taxonomy_Name';                                                                           #'Original_Source.Organism';               ### temporary ###
$Alias{CENTER_PROJECT}     = 'Project.Project_Name';                                                                             ##
$Alias{CLIP_QUALITY_LEFT}  = "CASE WHEN Quality_Left >=0 THEN Quality_Left ELSE NULL END";
$Alias{CLIP_QUALITY_RIGHT} = "CASE WHEN Quality_Length >= 0 THEN Quality_Left + Quality_Length - 1 ELSE NULL END";
$Alias{CLIP_VECTOR_LEFT}   = "Vector_Left";
$Alias{CLIP_VECTOR_RIGHT}  = "Vector_Right";

## Fields required - generate warning when missing, replace with 'undef' ##
my @Required = ( 'TEMPLATE_ID', 'PLATE_ID', 'WELL_ID', 'PRIMER', 'PRIMER_CODE', 'PROGRAM_ID', 'RUN_GROUP_ID', 'RUN_DATE', 'RUN_MACHINE_ID', 'RUN_MACHINE_TYPE', 'SOURCE_TYPE', 'SPECIES_CODE' );
my $Required_default = 'undef';

## Fields required as above and NOT allowed to be NULL (specify default below) ##
my @Not_null = ( 'RUN_GROUP_ID', 'PLATE_ID', 'quality_length' );
my $Not_null_default = 0;

## Fields which may be NULL - set to NULL if undefined (OR LESS THAN 0) , but no warnings generated ##
my @Nullable = ( 'CLIP_QUALITY_LEFT', 'CLIP_QUALITY_RIGHT', 'CLIP_VECTOR_LEFT', 'CLIP_VECTOR_RIGHT' );
my $Nullable_default = 'NULL';

my @key_values = ();

### Submission Aliases to be retrieved (After other info is extracted - based upon Run_Id, Well) ###
#
# When information from an earlier submission is required, then the Submission_Alias should be specified.
# (submitted length is also verified to ensure that it is the same)

### Sample Aliases to be retrieved (After other info is extracted - based upon Sample_Id) ###
#
# When Information is required that exists in the current database as a sample_alias,
#  that data may be extracted from the alias table given the alias type.
#  eg. if the CLONE_ID attribute is retrieved for a given sample by finding its 'NCBI_Clone_ID'
#  (defined in the Sample_Alias table)
#  -> then set : $Sample_Aliases{CLONE_ID} =  'NCBI_Clone_ID'
#

my %Sample_Aliases;
##$Sample_Aliases{CLONE_ID} =  'NCBI_Clone_ID';

my %Submission_Aliases;

#    $Submission_Aliases{GENBANK_ID} =  'Genbank_ID';
#    $Submission_Aliases{ACCESSION} =  'Accession_ID';

my %Sample_Attributes;

#####################
# Submission Types ##
#####################

if ( $submission_type =~ /update/ ) {
    $submission_type = 'update info';
    $md5             = 0;               ## turn off md5 inclusion ## <CUSTOM> - depends upon update ...
    ### Use only a subset of fields if updating <CUSTOMIZE>... ###
    @Order = ( 'TRACE_NAME', 'SUBMISSION_TYPE', 'CENTER_NAME', 'CLONE_ID' );
}

### Special case for BAC submissions ###
elsif ( $type eq 'BAC' ) {
    push( @Order, ( 'ACCESSION', 'INSERT_SIZE', 'INSERT_STDEV', 'CLIP_QUALITY_LEFT', 'CLIP_QUALITY_RIGHT', 'CLIP_VECTOR_LEFT', 'CLIP_VECTOR_RIGHT', ) );

    $Common_Field{STRATEGY}        = 'CLONEEND';    ##
    $Common_Field{TRACE_TYPE_CODE} = 'CLONEEND';    ## eg. shotgun, finishing, CLONEEND (for BAC END reads)
    $Common_Field{SOURCE_TYPE}     = 'G';           ## Genomic (vs Non-Genomic : EST, cDNA, screened libraries)

    $Alias{LIBRARY_ID}               = 'Library.External_Library_Name';    ### source name ###
    $Alias{TEMPLATE_ID}              = 'Clone_Sequence.FK_Sample__ID';     ## For backs, use the sample_ID for the template_id.
    $Sample_Attributes{INSERT_SIZE}  = 'Sample_Size_Estimate';
    $Sample_Attributes{INSERT_STDEV} = 'Sample_Size_StdDev';

    $Sample_Aliases{CLONE_ID} = 'NCBI_Clone_ID';

    #$Alias{CLONE_ID} ="Sample.Sample_Name";
    push( @Mandatory_Fields, 'INSERT_SIZE', 'INSERT_STDEV', 'LIBRARY_ID', 'CLONE_ID', 'TEMPLATE_ID' );

### Special case for EST submissions ###
}
elsif ( $type eq 'MGC' ) {
    push( @Order, ( 'AMPLIFICATION_FORWARD', 'AMPLIFICATION_REVERSE', 'AMPLIFICATION_SIZE', ) );
    $Sample_Aliases{CLONE_ID}      = 'NCBI_Clone_ID';
    $Common_Field{STRATEGY}        = 'RT-PCR';          ## 'cDNA' would be better, but this combo (cDNA / RT-PCR) is not allowed
    $Common_Field{TRACE_TYPE_CODE} = 'RT-PCR';          ## eg. shotgun, finishing, CLONEEND (for BAC END reads)
    $Common_Field{SOURCE_TYPE}     = 'N';               ## Genomic (vs Non-Genomic : EST, cDNA, screened libraries)

    ## adapt fields for this type of submissio$n ...
    $Alias{PRIMER_CODE}            = 'primer';
    $Sample_Attributes{LIBRARY_ID} = 'Library_ID';

    #    $Sample_Attributes{CLONE_ID}              =  'NCBI_Clone_ID';
    $Sample_Attributes{SPECIES_CODE} = 'Species_Code';
    $Sample_Attributes{TEMPLATE_ID}  = 'IMAGE_ID';       ## <CONSTRUCTION> - Standardize this to Attribute or Alias.. !!
    $Sample_Attributes{ORIENTATION}  = 'Orientation';    ## Required Field for standard primers.

    ## New Fields ##
    $Sample_Attributes{AMPLIFICATION_FORWARD} = 'Amplification_Forward';
    $Sample_Attributes{AMPLIFICATION_REVERSE} = 'Amplification_Reverse';
    $Sample_Attributes{AMPLIFICATION_SIZE}    = 'Amplification_Size';

    push( @Mandatory_Fields, 'LIBRARY_ID', 'CLONE_ID', 'SPECIES_CODE', 'TEMPLATE_ID' );
    push( @Mandatory_Fields, 'AMPLIFICATION_FORWARD', 'AMPLIFICATION_REVERSE', 'AMPLIFICATION_SIZE' );

}
else {
    Message("You must specify a submission type ('MGC' or 'BAC')");
    &leave();
}

### finish off INPUT specifications... ###

## check whether Sample_Aliases or Attributes are required and set flag ##
my $sample_alias_required     = int( keys %Sample_Aliases );
my $sample_attribute_required = int( keys %Sample_Attributes );
my $submission_alias_required = int( keys %Submission_Aliases );

#######################################################################################
if ( $sample =~ /\./ && -e $sample ) {
    open( FILE, "$sample" ) or die "Cannot find file '$sample'\n";
    my @samples;
    while (<FILE>) {
        if (/(\d+)/) {
            push( @samples, $1 );
        }
    }
    print "Extracted " . int(@samples) . " sample_ids from file: $sample\n\n";
    $sample = join ',', @samples;
}

unless ( $library || $run_id || $sample ) {    ## man page generated unless library or run_id specified ##
    print <<HELP;
    
    You must specify either a library, run id or sample id list to bundle the traces for (eg -l AVF01)
	Mandatory Fields (at least ONE of):
	**********************************
	    -library (library) [-plate (plate_number)]  Library (and optionally plate number)
	    -run (run_id)                       Run ID
	    -target (organization)              Target organization
	    -user (user id)                     User ID for employee         

	Options:
	*******
	    -group (plate_id/run/library)         Grouping of traces - (Default grouping by Run_ID)
	    -force                                Force execution (skips confirmation steps)
	    -include_poor                         Include poor quality runs (quality length = 0)
	    -min_length (trimmed length)          Minimum trimmed length for read to include in submission.   
	    -name (volume_name)                   Target volume name (defaults to 'trace_files') - format <LIB>_<INDEX> (eg. BE000_1)
	    -append                               Append to current volume (in database)
	    -update                               Update current volume (in database)
	    -date (date)                          Date for submission (defaults to current date unless set)
	    -comment (comment)                    Include comment for submission volume (only for database)

	      Eg: trace_bundle.pl -l AVF01 -type BAC                                                 << try this to make sure it works first.
		  trace_bundle.pl -library AVF01 -type BAC -append -xml -comment "Avian Flu"         << run it for real.

	Fields Retrieved:
	*****************
HELP
    print join "\n", @Order;
    print "\n\n";
    exit;
}

## Error checking ##

if ( -e $target ) {
    if ($append) {
        ## do not run if this script is already running ##
        my $running = `ps -aux | grep trace_bundle | grep -v ' 0:00 ' | grep -v ' 0:01 '`;
        if ($running) {
            print "** already running **\n";
            print "-> $running\n";
            exit;
        }
    }
    else {
        ## make sure target path does not currently exist ##
        print "Target directory: $target should NOT exist prior to execution.  Full target path will be generated dynamically\n";
        exit;
    }
}
print "Target Directory: $target\n*******************************************\n";

## CUSTOM: ##

## feedback to user / log file ##
my $header = "Options:\n*******\n";
$header .= " - GROUPING by $group\n";
if   ($include_poor) { $header .= " - INCLUDING reads with zero quality length\n"; }
else                 { $header .= " - EXCLUDING reads with zero quality length (min length = $min_length)\n"; }
$header .= "\nFields Included: \n***************\n";
$header .= join "\n", @Order;
$header .= "\n\n";

$header .= "Settings for this submission:\n****************************\n";
foreach my $key ( keys %Common_Field ) {
    unless ($force) {

        #	my $ans = '';
        #	while (!$ans) {
        #	    print "$key = ($Common_Field{$key}) ?  (Enter value or just press <ENTER> to leave as indicated)\n";
        #	    $ans = Prompt_Input(-type=>'string') || $Common_Field{$key};
        while ( $Common_Field{$key} !~ /^\w/ ) {    ## MANDATORY field NOT filled in
            print "$key = ($Common_Field{$key}) ?\n";
            print "** this field MUST be filled in..**\n";
            my $ans = Prompt_Input( -type => 'string' );
            $Common_Field{$key} = $ans;
        }
    }
    $header .= sprintf " %-20s => %s\n", $key, $Common_Field{$key};
}

### Get direction sense ###
my %Primer;

my @f_primer = &Table_find( $dbc, 'LibraryApplication,Primer,Object_Class',
    'Primer_Name', "WHERE Object_ID=Primer_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='Primer' AND FK_Library__Name = '$library' AND (Direction like '5%' OR Direction like 'F%')" );
my @r_primer = &Table_find( $dbc, 'LibraryApplication,Primer,Object_Class',
    'Primer_Name', "WHERE Object_ID=Primer_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='Primer' AND FK_Library__Name = '$library' AND (Direction like '3%' OR Direction like 'R%')" );
my @n_primer
    = &Table_find( $dbc, 'LibraryApplication,Primer,Object_Class', 'Primer_Name', "WHERE Object_ID=Primer_ID AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='Primer' AND FK_Library__Name = '$library' AND Direction IN ('Unknown','N/A')" );

$Primer{F} = Cast_List( -list => \@f_primer, -to => 'String' );
$Primer{R} = Cast_List( -list => \@r_primer, -to => 'String' );
$Primer{N} = Cast_List( -list => \@n_primer, -to => 'String' );

unless (@f_primer) {

    #    print "\n** Required **\n";
    if ($opt_F) { $Primer{F} = $opt_F }
    else {
        print "Enter primers to be used for FORWARD direction (may include comma-separated list if more than one)\n";
        my $fwd = Prompt_Input( -type => 'string', -default => $Primer{F} );
        $Primer{F} = $fwd;
    }

    #push (@f_primer,$Primer{F});
    @f_primer = split( ",", $Primer{F} );
}
unless (@r_primer) {
    if ($opt_R) { $Primer{R} = $opt_R }
    else {
        print "Enter primers to be used for REVERSE direction (may include comma-separated list if more than one)\n";
        my $rev = Prompt_Input( -type => 'string', -default => $Primer{R} );
        $Primer{R} = $rev;
    }

    #push (@r_primer,$Primer{R});
    @r_primer = split( ",", $Primer{R} );
}
unless (@n_primer) {
    print "Enter primers to be used with Unknown direction (may include comma-separated list if more than one)\n";
    my $unknown = Prompt_Input( -type => 'string', -default => $Primer{N} );
    $Primer{N} = $unknown;

    #push (@n_primer,$Primer{N});
    @n_primer = split( ",", $Primer{N} );
}

$header .= "\nPrimers:\n***********\n";
$header .= "Fwd Primer(s): " . $Primer{F} . "\n";
$header .= "Rev Primer(s): " . $Primer{R} . "\n";
$header .= "Unknown primer(s): " . $Primer{N} . "\n\n";

## get some information quickly to allow confirmation of data to be retrieved ##
my @read_fields;
foreach my $key ( keys %Alias ) {
    if   ( $key eq $Alias{$key} ) { push( @read_fields, $key ); }                     ## allow use of aliases (get converted in API)
    else                          { push( @read_fields, "$Alias{$key} AS $key" ); }
}

unless ($force) {
    print "Extracting read data sample to estimate data available...\n";

    #    print Dumper \@read_fields;
    my %directories = %{ $API->get_read_data( -fields => \@read_fields, -library => $library, -sample_id => $sample, -run_id => $run_id, -plate_number => $plate_number, -quiet => 1, -include => $include, -key => 'run_id,sequenced_well' ) };

    unless ( int( keys %directories ) > 0 ) { print "no data ? " . Dumper( \%directories ); &leave(); }
    my $records        = int( keys %directories );
    my $size_per_trace = 0.3;
    $header .= "(Found $records reads)\n";
    $header .= "SIZE estimate (for uncompressed submission volume): " . int( $records * $size_per_trace ) . "M\n";
}

print $header;

## prompt to confirm execution ##
unless ($force) {
    print "\n\n ... proceed with trace volume generation ? (y/n) ";
    my $ans = Prompt_Input( -type => 'char' );
    unless ( $ans =~ /y|Y/ ) { print "Aborted manually \n"; exit; }
}

my @trace_list;    ## optional list of traces to include ...
my $trace_list_ref;
if ($trace_list_file) {
    open( LIST, "$trace_list_file" ) or die "Cannot find trace list file: $trace_list_file";
    while (<LIST>) {
        my $trace = $_;
        chomp $trace;
        push( @trace_list, $trace );

        #	print "$trace\n";
    }
    print "\nFound list of traces ($#trace_list + 1 records): \n$trace_list[0]\n$trace_list[1]\n...$trace_list[-1]\n\n($#trace_list + 1 records)\n\n";
    $trace_list_ref = \@trace_list;
}

&create_bundle( -target_organization => $target_organization, -date => $submission_date, -volume_name => $basename, -volume => $update_volume, -trace_list => $trace_list_ref );
&leave();

#####################################
#
# Generate the bundle of traces
#
# This does the following for each read found:
#
# - update database with volume submission information (if -u or -a switch is used)
# - retrieve submission alias (eg. Genbank_ID, Accession_ID) for reads if required
# - retrieve sample_alias if required (eb. NCBI_Clone_ID)
# - checks Not_Nullable fields (sets to default if found)
# - checks Nullable_Int fields (sets to default if blank)
# - check Required fields to make sure they are set
# - ensure minimum trimmed length passes cutoff
# - ensure primer detected and valid (user specified for each direction)
#
# - copy trace files to subdirectory
# - generate md5 file (switch may be set off for testing, but this is generally set)
# - generate traceinfo file (xml if -xml switch used;  otherwise tab delimited)
#
################
sub create_bundle {
################
    my %args = &filter_input( \@_, -mandatory => 'target_organization,date,volume' );
    ## abort if any problems with input ## <CONSTRUCTION>

    my $target_organization = $args{-target_organization};
    my $submission_date     = $args{-date};
    my $volume_name         = $args{-volume_name};
    my $volume              = $args{-volume};                ## optional (if only updating)
    my $trace_list          = $args{-trace_list};            ## optional list of traces to include (array ref)

    my $volume_id = $update_volume;

    #push(@read_fields,'Sequence_Scores');                       ## need to include scores as well...

## Make target directories ##
    `mkdir -p $target`;

    if ( $Common_Field{SUBMISSION_TYPE} =~ /update/ ) {
        ## <CONSTRUCTION> ... add update record..
    }
    else {
        ## These directories should already exist for the original submission ##
        ## NOTE: You may need to replace this execution if updating with revised trace / score data ##
        unless ( -e "$target/traces" ) {`mkdir $target/traces`}

        #	unless (-e "$target/qscores") { `mkdir $target/qscores` }
    }

    ## append the files below to allow running of batch volume generation in stages... (?)
    open( LOG, ">>$log" ) if $log;

    open( TRACEINFO, ">>$target/TRACEINFO.$ext" ) or die "cannot open target : $target/TRACEINFO.$ext file\n";
    if ($md5) { open( MD5, ">$target/MD5" ) or die "cannot open target : $target/MD5 file\n"; }

    if ($xml) {
        print TRACEINFO q(<?xml version="1.0"?>);
        print TRACEINFO "\n";
        print TRACEINFO "<trace_volume>\n";
        print TRACEINFO "\t<volume_name>$volume_name</volume_name>\n";
        print TRACEINFO "\t<volume_date>$date</volume_date>\n";

        print TRACEINFO "\t<common_fields>\n";

        foreach my $common ( keys %Common_Field ) {
## <CONSTRUCTION> - use key / value pairs for ATTRIBUTES that have only 1 possible value (?) - perhaps a bit clearer...
            #	    print TRACEINFO "\t\t<key = '$common' value = '$Common_Field{$common}'>\n";  ## type2xml
            print TRACEINFO "\t\t<$common>$Common_Field{$common}</$common>\n";
        }
        print TRACEINFO "\t</common_fields>\n";
    }
    else {
        print TRACEINFO "Volume\t$volume_name\n";
        print TRACEINFO "Date\t$date\n";
        print TRACEINFO "\n";
    }

    print LOG $header if $log;

    ## CREATE / UPDATE Submission_Volume record ##
    if ($update_volume) {    ## only update if still in preparing stage ##
        my ($organization_id) = $dbc->Table_find( 'Organization', 'Organization_ID', "WHERE Organization_Name = '$target_organization' AND Organization_Type = 'Data Repository'" );

        my @fields = ( 'FK_Organization__ID', 'Volume_Name', 'Submission_Date', 'FKSubmitter_Employee__ID', 'Volume_Comments' );

        my @values = ( $organization_id, $volume_name, $submission_date, $user_id, $comments );
        my $ok = &Table_update_array( $dbc, 'Submission_Volume', \@fields, \@values, "WHERE Submission_Volume_ID = $update_volume", -autoquote => 1 );
        unless ($ok) { Message("No change noted in volume record"); }
    }
    elsif ($append) {
        my ($organization_id) = $dbc->Table_find( 'Organization', 'Organization_ID', "WHERE Organization_Name = '$target_organization' AND Organization_Type = 'Data Repository'" );
        my @fields = ( 'FK_Organization__ID', 'Volume_Name', 'Submission_Date', 'FKSubmitter_Employee__ID', 'Volume_Comments' );
        my @values = ( $organization_id, $volume_name, $submission_date, $user_id, $comments );
        $volume_id = &Table_append_array( $dbc, 'Submission_Volume', \@fields, \@values, -autoquote => 1 );
        unless ($volume_id) { Message("Error generating volume id - check with administrator"); &leave(); }
    }
    else { Message("Test Run - NOT APPENDED (use append or update switch if necessary"); }

    my @plate_lists = split ',', $plate_number_list;
    unless ($plate_number_list) { @plate_lists = (0); }    ## in case there are no plate_number specs
    my %reads;

    my %statistics;
    my %trace_info;
    foreach my $this_plate (@plate_lists) {
        my $found = 0;
        my @plates_sequenced;
        ## Submission specification options: library, plate_number, run_id, sample_id ##
        my $extra_condition = '';
        $extra_condition .= " AND Plate.FK_Library__Name = '$library'" if $library;
        $extra_condition .= " AND Plate_Number in ($this_plate)"       if $this_plate;    ## ignored if no plate list given ...
        $extra_condition .= " AND Run_ID in ($run_id)"                 if $run_id;
        $extra_condition .= " AND FK_Sample__ID IN ($sample)"          if $sample;

        ## populate discovered submission_aliases if this is required ##
        my %Submission_Alias;
        if ($submission_alias_required) {
            my @submission_aliases = &Table_find_array(
                $API->dbc(),
                'Run,Plate,Trace_Submission,Submission_Alias',
                [ 'Trace_Submission.FK_Run__ID', 'Trace_Submission.Well', 'Submission_Reference_Type', 'Submission_Reference', 'Submitted_Length' ],
                "WHERE FK_Trace_Submission__ID=Trace_Submission_ID AND FK_Plate__ID=Plate_ID AND FK_Run__ID = Run_ID $extra_condition"
            );
            foreach my $alias_info (@submission_aliases) {
                my ( $run_id, $well, $type, $alias, $length ) = split ',', $alias_info;
                $Submission_Alias{$run_id}{$well}{$type} = $alias;
                $Submission_Alias{$run_id}{$well}{length} = $length;
            }

            # $results .= "(Found " . int(@submission_aliases) . " possible submission alias names)\n";
        }
        $trace_info{$this_plate} = get_trace_reads( -plate => $this_plate, -run_id => $run_id, -trace_list => $trace_list, -submission_alias => \%Submission_Alias );
        print "(retrieved data) ..\n";
        my @keys = keys %{ $trace_info{$this_plate} };
        ### check if we want to compare quality length, Q20 etc

        if ($measure) {
            ## loop through first to for best reads
            my $found = 0;
            my $num_reads;
            while ( defined $trace_info{$this_plate}{run_id}[$found] ) {

                my $base      = $trace_info{$this_plate}{$measure_by}[$found];      ## based on what field SAMPLE_ID, CLONE_ID?
                my $direction = $trace_info{$this_plate}{TRACE_END}[$found];        ## Direction of the trace
                my $plate_id  = $trace_info{$this_plate}{PLATE_ID}[$found];
                my $key_value = $trace_info{$this_plate}{$key_field}[$found];
                my $run_id    = $trace_info{$this_plate}{run_id}[$found];
                my $well      = $trace_info{$this_plate}{sequenced_well}[$found];
                if ( $trace_info{$this_plate}{$measure}[$found] > $reads{$base}{$key_value}{$measure} ) {
                    print "TL  $base $trace_info{$this_plate}{$measure}[$found] is greater than $reads{$base}{$direction}{$measure}\n";

                    $reads{$base}{$key_value}{$measure} = $trace_info{$this_plate}{$measure}[$found];

                    $reads{$base}{$key_value}{$measure_by} = $trace_info{$this_plate}{$measure_by}[$found];
                    $reads{$base}{$key_value}{run_id}      = $run_id;
                    $reads{$base}{$key_value}{well}        = $well;
                    $num_reads++;
                }

                #push (@plates_sequenced, $plate_id) unless grep /^$plate_id$/, @plates_sequenced;
                push( @{ $statistics{$this_plate}{$key_value}{Plates_Sequenced} }, $plate_id ) unless grep /^$plate_id$/, @{ $statistics{$this_plate}{$key_value}{Plates_Sequenced} };
                $found++;

            }
        }
    }

    ## go through this process one plate number at a time to minimize memory overload
    if ($measure) {
        my %new_reads;
        print "***** trace info *****\n";
        foreach my $this_plate (@plate_lists) {
            my @keys  = keys %{ $trace_info{$this_plate} };
            my $found = 0;
            my $num_reads;
            ## Go through all the reads and only get the reads that match the best reads
            while ( defined $trace_info{$this_plate}{run_id}[$found] ) {

                my $direction = $trace_info{$this_plate}{TRACE_END}[$found];
                my $base      = $trace_info{$this_plate}{$measure_by}[$found];
                my $run_id    = $trace_info{$this_plate}{run_id}[$found];
                my $well      = $trace_info{$this_plate}{sequenced_well}[$found];
                my $plate_id  = $trace_info{$this_plate}{PLATE_ID}[$found];
                my $key_value = $trace_info{$this_plate}{$key_field}[$found];
                my $primer    = $trace_info{$this_plate}{PRIMER_CODE}[$found];
                my $ql        = $trace_info{$this_plate}{quality_length}[$found];
                if (   $ql > $min_length
                    && $run_id                                    eq $reads{$base}{$key_value}{run_id}
                    && $well                                      eq $reads{$base}{$key_value}{well}
                    && $base                                      eq $reads{$base}{$key_value}{$measure_by}
                    && $trace_info{$this_plate}{$measure}[$found] eq "$reads{$base}{$key_value}{$measure}" )
                {
                    print "DIR $direction $primer $trace_info{$this_plate}{quality_length}[$found]\n";
                    foreach my $key (@keys) {
                        push( @{ $new_reads{$this_plate}{$key} }, $trace_info{$this_plate}{$key}[$found] );
                    }
                    $num_reads++;
                }

                $found++;
            }

            print "NUMBER OF READS $num_reads Num seq $found";
        }

        %trace_info = %new_reads;
    }

    foreach my $this_plate (@plate_lists) {
        my $results = "\n**** Plate : $this_plate ****\n";
        print $results if $verbose;
        my $this_data = '';

        my @plates_submitted;

        my $found = 0;
##	my %trace_info = %{get_trace_reads(-plate=>$this_plate,-run_id=>$run_id,-trace_list=>$trace_list,-submission_alias=>\%Submission_Alias)};
##
##	print "(retrieved data) ..\n";
##	my @keys = keys %trace_info;
        ## Submission specification options: library, plate_number, run_id, sample_id ##
        my $extra_condition = '';
        $extra_condition .= " AND Plate.FK_Library__Name = '$library'" if $library;
        $extra_condition .= " AND Plate_Number in ($this_plate)"       if $this_plate;    ## ignored if no plate list given ...
        $extra_condition .= " AND Run_ID in ($run_id)"                 if $run_id;
        $extra_condition .= " AND FK_Sample__ID IN ($sample)"          if $sample;

        ## populate discovered submission_aliases if this is required ##
        my %Submission_Alias;

        if ($submission_alias_required) {
            my @submission_aliases = &Table_find_array(
                $API->dbc(),
                'Run,Plate,Trace_Submission,Submission_Alias',
                [ 'Trace_Submission.FK_Run__ID', 'Trace_Submission.Well', 'Submission_Reference_Type', 'Submission_Reference', 'Submitted_Length' ],
                "WHERE FK_Trace_Submission__ID=Trace_Submission_ID AND FK_Plate__ID=Plate_ID AND FK_Run__ID = Run_ID $extra_condition"
            );
            foreach my $alias_info (@submission_aliases) {
                my ( $run_id, $well, $type, $alias, $length ) = split ',', $alias_info;
                $Submission_Alias{$run_id}{$well}{$type} = $alias;
                $Submission_Alias{$run_id}{$well}{length} = $length;
            }
            $results .= "(Found " . int(@submission_aliases) . " possible submission alias names)\n";
        }
        my $records = int( @{ $trace_info{$this_plate}{run_id} } ) if $trace_info{$this_plate}{run_id};
        $results .= &date_time() . " (Run Prior status: added: $added; skipped: $skipped; aborted: $aborted; poor: $poor)\n";
        $results .= "\nGenerate data files for $library $this_plate... ($records records)\n";

        while ( defined $trace_info{$this_plate}{run_id}[$found] ) {
            my $library   = $trace_info{$this_plate}{library}[$found];
            my $run_id    = $trace_info{$this_plate}{run_id}[$found];
            my $sample_id = $trace_info{$this_plate}{sample_id}[$found];
            my $well      = $trace_info{$this_plate}{well}[$found];
            my $length    = $trace_info{$this_plate}{sequence_length}[$found];
            my $trimmed   = $trace_info{$this_plate}{trimmed_length}[$found];
            my $plate_id  = $trace_info{$this_plate}{PLATE_ID}[$found];
            my $direction = $trace_info{$this_plate}{TRACE_END}[$found];
            my $key_value = $trace_info{$this_plate}{$key_field}[$found];
            print "Direction $key_value\n";
            push( @plates_submitted, $plate_id ) unless grep /^$plate_id$/, @plates_submitted;
            ## copy file to traces directory ##
            my $subdir = '';

            ## copy traces to target directory unless this is just a submission update ##
            unless ( $submission_type =~ /update/ || !$copy_traces ) {
                if ($group) {    ## (normally this generates the RUN_GROUP_ID.$group directories to store the trace files in)
                    my $group_dir = "$group.$trace_info{$this_plate}{$group}[$found]";
                    $subdir = "/$group_dir";
                    unless ( -e "$target/traces/$group_dir" ) { `mkdir $target/traces/$group_dir`; }

                    #		  unless (-e "$target/qscores/$group_dir") { `mkdir $target/qscores/$group_dir`; }
                }

                `cp $trace_info{$this_plate}{file}[$found] $target/traces/$subdir/`;
                my $fullpath = "./traces$subdir/$trace_info{$this_plate}{filename}[$found]";
            }

            #$statistics{$this_plate}{$direction}{Q20} += $trace_info{$this_plate}{Q20}[$found];
            #$statistics{$this_plate}{$direction}{quality_length} += $trace_info{$this_plate}{quality_length}[$found];
            #$statistics{$this_plate}{$direction}{trimmed_length} += $trace_info{$this_plate}{trimmed_length}[$found];
            #$statistics{$this_plate}{$direction}{sequence_length} += $trace_info{$this_plate}{sequence_length}[$found];

            $statistics{$this_plate}{$key_value}{Q20}             += $trace_info{$this_plate}{Q20}[$found];
            $statistics{$this_plate}{$key_value}{quality_length}  += $trace_info{$this_plate}{quality_length}[$found];
            $statistics{$this_plate}{$key_value}{trimmed_length}  += $trace_info{$this_plate}{trimmed_length}[$found];
            $statistics{$this_plate}{$key_value}{sequence_length} += $trace_info{$this_plate}{sequence_length}[$found];
            $statistics{$this_plate}{$key_value}{found}           += 1;
            push( @key_values, $key_value ) unless grep /^$key_value$/, @key_values;
            $trace_info{$this_plate}{TRACE_FILE}[$found] = "./traces/$subdir/$trace_info{$this_plate}{filename}[$found]";
            while ( $trace_info{$this_plate}{TRACE_FILE}[$found] =~ s/\/\//\// ) { }    ## replace // with / if found in path. ##
            $trace_info{$this_plate}{TRACE_NAME}[$found] = $trace_info{$this_plate}{filename}[$found];

            ## Generate MD5 digest files ##
            if ( $md5 && defined $trace_info{$this_plate}{file}[$found] ) {
                my $file = Digest::MD5->new;
                open( TRACE, "$trace_info{$this_plate}{file}[$found]" );
                $file->addfile(*TRACE);
                close(TRACE);
                my $digest = $file->hexdigest;
                print MD5 "$digest\t$trace_info{$this_plate}{TRACE_FILE}[$found]\n";
                print "Digest $trace_info{$this_plate}{TRACE_FILE}[$found] \n" if $verbose;
            }
            my $alias_num = 0;

            ## Generate Traceinfo data (either Tab-delimited or XML data) ##
            $this_data .= "\t<trace>\n" if $xml;
            foreach my $key (@Order) {
                if ( $key eq uc($key) ) {
                    if ($xml) {

                        #		      $this_data .= "\t\t<key = '$key' value = '$fback{$key}'>\n";  ## type2xml
                        $this_data .= "\t\t<$key>$trace_info{$this_plate}{$key}[$found]</$key>\n";    ## XML format

                        #		      print "** <key = '$key' value = '$fback{$key}'> **\n" if $verbose;  ## type2xml
                        print "** <$key>$trace_info{$this_plate}{$key}[$found]</$key> **\n" if $verbose;
                    }
                    else {
                        $this_data .= "$key\t$trace_info{$this_plate}{$key}[$found]\n";               ## Tab-delimited format
                    }
                }
            }
            if ($xml) {
                $this_data .= "\t</trace>\n";
            }
            else {
                $this_data .= "\n";
            }

            my @fields = ( 'FK_Run__ID', 'Well', 'FK_Sample__ID', 'Submitted_Length', 'FK_Submission_Volume__ID' );
            my @values = ( $run_id, $well, $sample_id, $trimmed, $volume_id );

            if ($update_volume) {    ## only allow updating if still in preparing stage ##
                my $updated = &Table_update_array( $dbc, 'Trace_Submission', \@fields, \@values, "WHERE FK_Run__ID=$run_id AND Well='$well' AND FK_Submission_Volume__ID=$update_volume AND Submission_Status = 'Preparing'", -autoquote => 1 );
            }
            elsif ($append) {        ## add new submission
                push( @fields, 'Submission_Status' );
                push( @values, 'Preparing' );
                my $updated = &Table_append_array( $dbc, 'Trace_Submission', \@fields, \@values, -autoquote => 1 );
            }
            else { Message("Test Run - NOT APPENDED (use append or update switch if necessary") unless $added; }

            $added++;
            $total_added++;
            $found++;
            $results .= &date_time() . " Accumulated reads added: $added; skipped: $skipped; aborted: $aborted; poor: $poor\n";
        }
        if ($found) {

            #@key_values = ('F','R');
            foreach my $key_value (@key_values) {
                if ( $statistics{$this_plate}{$key_value}{found} > 0 ) {
                    $statistics{$this_plate}{$key_value}{Q20}             = $statistics{$this_plate}{$key_value}{Q20} / $statistics{$this_plate}{$key_value}{found};
                    $statistics{$this_plate}{$key_value}{quality_length}  = $statistics{$this_plate}{$key_value}{quality_length} / $statistics{$this_plate}{$key_value}{found};
                    $statistics{$this_plate}{$key_value}{trimmed_length}  = $statistics{$this_plate}{$key_value}{trimmed_length} / $statistics{$this_plate}{$key_value}{found};
                    $statistics{$this_plate}{$key_value}{sequence_length} = $statistics{$this_plate}{$key_value}{sequence_length} / $statistics{$this_plate}{$key_value}{found};
                    push( @{ $statistics{$this_plate}{$key_value}{Plates_Submitted} }, $plate_id ) unless grep /^$plate_id$/, @{ $statistics{$this_plate}{$key_value}{Plates_Submitted} };
                }
                else {

                }

            }
        }

        $total_found += $found;
        print TRACEINFO $this_data;
        print $results;
        print LOG $results if $log;
    }

    ## update Volume submission with number of records added ##
    if ($append) {
        my ($status) = $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Name = 'Bundled' and Status_Type = 'Submission'" );
        my $updated = &Table_update_array( $dbc, 'Submission_Volume', [ 'FK_Status__ID', 'Records' ], [ $status, $added ], "WHERE Submission_Volume_ID = $volume_id", -autoquote => 1 );
    }

    ## wrap it up... ##
    print TRACEINFO "</trace_volume>\n" if $xml;
    close(TRACEINFO);
    close(MD5) if ($md5);

    print "\nGrouped $added (total=$total_added) of $total_found records (skipped: $skipped; aborted: $aborted; poor: $poor)\n";

    ## put together standard README file ##
    open( README, ">>$target/README" ) or die "cannot open target : $target/README file\n";

    print README <<END_README;
    
File autogenerated using trace_bundle script.

British Columbia Cancer Agency Genome Sciences Centre.

    Submitted Reads: $total_added.
    Grouped by:      $group.

    Low quality cuttoff length: $min_length bp ( < $min_length = low quality)
    Low quality reads included:  $include_poor.

Files included in $volume_name :

    ./README
    ./TRACEINFO.$ext
    ./MD5 
    ./traces/RUN_GROUP_ID.<Run_ID>/<TRACE_NAME>

Note: Insert_Size values are rounded to nearest kilobyte to be more consistent with expected accuracy levels.

$comments

(For questions / problems with submission, contact lims\@bcgsc.ca)

Agency Contacts:

Steve Jones (Bioinformatics)
Ran Guin (LIMS)

END_README

    close(README);
    my $summary = "Summary\n***********\n";

    my $note_count = int(@notes);
    $summary .= "\nNotes:\n*********\n";
    if ($note_count) { $summary .= join "\n", @notes; }
    else             { $summary .= "(none)"; }
    $summary .= "\n";

    my $warning_count = int(@warnings);
    $summary .= "\nWarnings:\n*********\n";
    if ($warning_count) { $summary .= join "\n", @warnings; }
    else                { $summary .= "(none)"; }
    $summary .= "\n";

    my $error_count = int(@errors);
    $summary .= "\nErrors:\n**********\n";
    if ($error_count) { $summary .= join "\n", @errors; }
    else              { $summary .= "(none)"; }
    $summary .= "\n";

    $summary .= "\nFound $note_count notes\n";
    $summary .= "\nFound $warning_count warnings\n";
    $summary .= "\nFound $error_count errors\n";

    $summary .= "\nStatistics:\n";

    $summary .= "Lib    \tPN \tDir\tQ20\tQL \tTL \tSL\tNSQ\tNSU\tNR\n";
    my @directions = ( 'F', 'R', 'N' );
    foreach my $stat ( sort { $a <=> $b } keys %statistics ) {

        #if ($stat > 0) {
        #	$summary .= "Plate Number: $stat\n";
        #
        #    }
        foreach my $key_value (@key_values) {
            my $num_sequenced = int( @{ $statistics{$stat}{$key_value}{Plates_Sequenced} } ) if defined $statistics{$stat}{$key_value}{Plates_Sequenced};
            my $num_submitted = int( @{ $statistics{$stat}{$key_value}{Plates_Submitted} } ) if defined $statistics{$stat}{$key_value}{Plates_Submitted};

            $summary .= sprintf "%5s\t%3d\t%3s\t\%3d\t%3d\t%3d\t%3d\t%3d\t%3d\t%3d\n", $library, $stat, $key_value, $statistics{$stat}{$key_value}{Q20}, $statistics{$stat}{$key_value}{quality_length}, $statistics{$stat}{$key_value}{trimmed_length},
                $statistics{$stat}{$key_value}{sequence_length}, $num_sequenced, $num_submitted, $statistics{$stat}{$key_value}{found};

            #print Dumper $statistics{$stat}{$key_value}{Plates_Sequenced};
        }

        #    $summary .= "Average Q20: $statistics{$stat}{Q20}\n";
        #    $summary .= "Average Quality Length: $statistics{$stat}{quality_length}\n";
        #    $summary .= "***********************************************************\n";
    }
    $summary .= "\n\nLib: Library\n";
    $summary .= "PN: Plate Number\n";
    $summary .= "DIR: Direction\n";
    $summary .= "Q20: Average Q20 Score\n";
    $summary .= "QL: Average Quality Length\n";
    $summary .= "TL: Average Trimmed Length\n";
    $summary .= "SL: Average Sequence Length\n";
    $summary .= "NSQ: Number of Plates Sequenced\n";
    $summary .= "NSU: Number of Plates Submitted\n";
    $summary .= "NR: Number of Reads Submitted\n";
    $summary .= "\n\nSUBMITTED:\t$total_added.\n\n";

    print $summary;
    print LOG $summary;

    close(LOG) if ($log);
    return;
}

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

sub leave {
    $API->disconnect();
    exit;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

#########################
sub _execute_sql {
#########################
    my $sql = shift;

    print "\nExecuting '$sql'...(" . now() . ")\n";
    my $rows = $dbc->dbh()->do(qq{$sql});

    if ( !$rows ) {
        print "*** ERROR executing SQL: $DBI::err ($DBI::errstr)(" . now() . ").\n";
    }
    else {
        $rows += 0;
        print "--- Executed SQL successfully ($rows row(s) affected)(" . now() . ").\n";
    }

    #Returns the number of rows affected and also the newly created primary key ID.
    return ( $rows, $dbc->{'mysql_insertid'} );
}

########
#
# Temporary - use to fix 0 (should be NULL) vector indexes (in ENCODE) TRACEINFO file
#
################
sub _fix_file {
################
    my $file   = shift;
    my $vol    = shift;
    my $run_id = shift;
    my $well   = shift;

    my %skipped;

    open( FILE, "$file" )    or die "Cannot open $file..";
    open( TMP,  ">tmp.txt" ) or die "Cannot open tmp.txt";
    my $problem = 0;
    my $count   = 0;
    while (<FILE>) {
        my $line = $_;
        chomp $line;

        #	if ($line =~/^>(\S+)\s+(\d+)\s+(\d+)\s+(\d+)(.*)/) {
        #	    my ($Q) = &Table_find($dbc,'Clone_Sequence','Quality_Length',"WHERE FK_Run__ID=$run_id AND Well = '$well'");
        #	    print TMP ">$1\t$2\t$3\t$Q\t$5\n";
        #	} else {
        #	    print TMP $line;
        #	}
        #
        #	if (/<trace>/) { $count++; $problem = 0; }
        #	if (/CLIP_VECTOR_LEFT>0<\/CLIP_VECTOR_LEFT/) {
        #	    $problem = 1;
        #	    print TMP "\t\t\t\t<CLIP_VECTOR_LEFT>NULL</CLIP_VECTOR_LEFT>\n";
        #	} elsif ( $problem && /CLIP_VECTOR_RIGHT>0<\/CLIP_VECTOR_RIGHT/) {
        #	    print TMP "\t\t\t\t<CLIP_VECTOR_RIGHT>NULL</CLIP_VECTOR_RIGHT>\n";
        #	} else {
        #	    print TMP $line;
        #	}

    }

    close(FILE);
    close(TMP);

    #    `mv tmp.txt $file`;
    $fixed++;

    #    print "fixed $file\n";
    print "mv tmp.txt $file (found $count traces)\n\n";

    return;
}

###############
sub _fix_qscore {
###############
    my $vol = shift;

    my @dirs = `find BE000_$vol/qscores/ -type d`;
    foreach my $dir (@dirs) {
        chomp $dir;
        if ( $dir =~ /RUN_GROUP_ID\.(\d+)/ ) {
            my $run_id = $1;
            print "($run_id)..";
            my @traces = `find $dir/ -type f`;
            foreach my $trace (@traces) {
                chomp $trace;
                if ( $trace =~ /(.*?)_(\S\d\d)__/ ) {
                    my $well = $2;
                    _fix_file( $trace, $vol, $run_id, $well );
                }
                else { print "Trace ($run_id) $trace ?\n"; }
            }
        }
        else {
            print "Dir: $dir ?\n";
        }
    }

    return;
}

########
#
# Temporary - use to add qscore reference to current TRACEINFO file
#
##################
sub _edit_traceinfo {
##################
    my $file = shift;
    my $vol  = shift;

    my $tmp_file = "fixed_traceinfo_$vol.txt";
    my %skipped;

    print "(temp file = $tmp_file)\n";
    open( FILE, "$file" )      or die "Cannot open $file..\n";
    open( TMP,  ">$tmp_file" ) or die "Cannot open $tmp_file\n";
    my ( $run_id, $well, $insert, $count, $traces ) = ( 0, 0, 0, 0, 0 );
    my $trace_name = '';
    my $trace      = '';

    my $ignored = 0;
    while (<FILE>) {
        my $line = $_;
        unless ($count) {
            $line =~ s />\s*<trace_volume>/>\n\t<trace_volume>/;
            unless ( $line =~ /<trace>/i ) { print TMP $line }    ## this will be repeated below...
        }    ## print lines before first trace...

        if ( $line =~ /<trace>/i ) {

            #	    print "$count: ($run_id : $well : $insert)\n$line";
            $run_id     = 0;
            $well       = 0;
            $insert     = 0;
            $added      = 0;
            $trace_name = '';
            $count++;
            $trace = '';    # make sure it is cleared...
        }
        elsif ( $line =~ /<RUN_GROUP_ID>(\d+)</i ) {
            $run_id = $1;
        }
        elsif ( $line =~ /<WELL_ID>(\w+)</i ) {
            $well = $1;
        }
        elsif ( $line =~ /<TRACE_NAME>([\w\.]+)</i ) {
            $trace_name = $1;
        }
        elsif ( $line =~ /<INSERT_SIZE>(\w+)</i ) {    ## use \w to catch undef as well...
            $insert = $1;

            #	    my $details = '';
            #	    if ($run_id && $well) {
            #		($details) = &Table_find($dbc,'Clone_Details,Clone_Sequence,Clone_Sample','Size_Estimate,Size_StdDev',
            #					 "WHERE FK_Clone_Sample__ID=Clone_Sample_ID AND Clone_Sample.FK_Sample__ID = Clone_Sequence.FK_Sample__ID AND FK_Run__ID=$run_id AND Well = '$well'");
            #		my ($size,$stdev) = split ',', $details;
            #		$size = int( ($size + 500) / 1000) * 1000;             ### round off to represent kilobases.
            #		$stdev = int( ($stdev + 500) / 1000) * 1000;          ### round off to represent kilobases.
            #
            #		$line = "\t\t\t<INSERT_SIZE>$size</INSERT_SIZE>\n";
            #		$line .= "\t\t\t<INSERT_STDEV>$stdev</INSERT_STDEV>\n";
            #	    print "Added line:\n\t\t\t\t<INSERT_STDEV>$stdev</INSERT_STDEV>\n";
            #		$added++;
            #		unless ($size) { print "No Size info for $run_id: $well\n"; }
            #		unless ($insert == $size) { print "Changed size ($run_id:$well) from $insert -> $size.\n"; }
            #		$insert = $size;
            # 	    }
        }
        $trace .= $line unless ( $line =~ /QUAL_FILE/ );

        if ( $line =~ /<\/trace>/i ) {
            if ( $run_id && $well && $insert ) { }
            else {
                print "Something remains undefined for $trace_name ?? ($run_id : $well : $insert [$added]).\n";
            }
            if   ( $run_id && $well ) { print TMP $trace;              $traces++; }
            else                      { print "Ignored empty trace\n"; $ignored++; }
            $run_id     = 0;
            $well       = 0;
            $insert     = 0;
            $trace_name = '';
        }

        #	print TMP $line;
    }

    print TMP "</trace_volume>\n";

    close(FILE);
    close(TMP);
    print "found $count traces ($traces saved) - ignored $ignored...\n";

    #    `mv $tmp_file $file`;
    print "mv $tmp_file $file\n\n";

    return;
}

#################
sub _ftp_connect {
#################
    my %args = filter_input( \@_, -args => 'file', -mandatory => 'site' );
    my $site         = $args{-site}      || '';
    my $ftp_user     = $args{-user}      || "bccagsc_trc";
    my $ftp_password = $args{-password}  || 'BE7TTmvz';
    my $directory    = $args{-directory} || '';

    my $connected = 0;
    my $try       = 0;
    my $max       = 100;
    print "Trying to connect to $site.  (will try $max times before aborting)\n";

    while ( $try < $max ) {
        $try++;
        print "$try..";
        sleep 5 if $try;

        #    print "(logging in)..\n";
        $ftp->quit if $ftp;
        $ftp = Net::FTP->new( $site, Debug => 0 ) or next;

        $ftp->login( $ftp_user, $ftp_password ) or next;
        $ftp->binary();
        $ftp->cwd($directory)                                 if $directory;
        print "\n** changing to $directory directory **...\n" if $directory;

        $connected++;
        last;
    }

    unless ($connected) {
        print "No connection enabled..\n\nAborting\n\n";
        $ftp->quit;
        return 0;
    }
    print "Connection established.\n\n";
    return $ftp;
}

###############
sub _ftp_monitor {
###############
    my %args  = &filter_input( \@_, -args => 'site,file', -mandatory => 'site' );
    my $site  = $args{-site};
    my $tries = $args{-tries} || 2;
    my $sleep = $args{ -sleep } || 5;
    my $ftp   = $args{-ftp};

    unless ($ftp) {
        $ftp = _ftp_connect( %args, -directory => 'uploads' );
    }
    foreach my $try ( 1 .. $tries ) {
        my @ls = $ftp->dir or return;
        print &date_time . "\n****************\n";
        print "Target contents:\n";
        print join "\n", @ls;
        sleep $sleep;
    }

    $ftp->quit;
    return;
}
##############
# Upload given files to specified site.
#
###############
sub _ftp_upload {
###############
    my %args = filter_input( \@_, -args => 'site,file', -mandatory => 'site' );
    my $site         = $args{-site} || '';
    my $file         = $args{-file};
    my $ftp_user     = $args{-user};
    my $ftp_password = $args{-password};
    my $source_dir   = $args{-source_directory} || ".";         ## "tar_files/upload";
    my $extension    = $args{-extension} || 'tar.gz';
    my $target_dir   = $args{-target_directory} || 'uploads';

    my $ftp = _ftp_connect( -site => $site, -user => $ftp_user, -password => $ftp_password, -directory => $target_dir );

    my @files = ($file);
    unless ( $file =~ /[a-zA-Z]/ ) {                            ## get all files in upload directory if not specified..
        print "Getting *.tar.gz files...\n\n";
        @files = glob("$source_dir/*.$extension");
    }

    my $uploaded = 0;
    print "Source contents:\n*********************\n";
    foreach my $file (@files) {
        print try_system_command("ls $file");
        $uploaded += $ftp->put($file);
    }

    my @ls = $ftp->dir or return $uploaded;
    print "Target contents:\n*********************\n";
    print join "\n", @ls;
    $ftp->quit;
    return $uploaded;

}

#######################
sub get_trace_reads {
#######################
    my %args             = filter_input( \@_ );
    my $this_plate       = $args{-plate};
    my $run_id           = $args{-run_id};
    my $Submission_Alias = $args{-submission_alias};
    my %Submission_Alias = %{$Submission_Alias} if defined $Submission_Alias;
    my $trace_list       = $args{-trace_list};

    #    print "Running API to get trace information ...\n";

    ## Get Trace information from API ##
    #  print "\nGetting Trace info for R: $run_id; L: $library P: $this_plate.\n";
    my %traces;

    push @read_fields, 'stock_id';
    push @read_fields, 'machine';
    my $input_joins;
    $input_joins->{'Stock_Catalog'} = 'FK_Stock_Catalog__ID = Stock_Catalog_ID';
    $input_joins->{'Stock'}         = 'FK_Stock__ID=Stock_ID';

    my %fback = %{ $API->get_trace_files( -fields => \@read_fields, -run_id => $run_id, -library => $library, -plate_number => $this_plate, -sample_id => $sample, -quiet => $quiet, -include => $include, -input_joins => $input_joins ) };
    my @custom_primer_fields = ( 'run_id', 'oligo_primer', 'oligo_sequence' );

    my %custom_primers = %{ $API->get_oligo_data( -fields => \@custom_primer_fields, -run_id => $run_id, -library => $library, -plate_number => $this_plate, -sample_id => $sample, -key => 'run_id,Clone_Sequence.well' ) };

    my $found = 0;

    my @keys = keys %fback;
    while ( defined $fback{run_id}[$found] ) {

        my $run_id      = $fback{run_id}[$found];
        my $well        = $fback{well}[$found];
        my $primer_name = $fback{PRIMER_CODE}[$found];
        if ( $primer_name =~ /custom/i ) {
            my $custom_primer          = $custom_primers{"$run_id-$well"}{oligo_primer};
            my $custom_primer_sequence = $custom_primers{"$run_id-$well"}{oligo_sequence};
            $fback{PRIMER_CODE}[$found] = $custom_primer;
            $fback{PRIMER}[$found]      = $custom_primer_sequence;
        }
        $found++;
    }

    my $found = 0;

FILE: while ( defined $fback{run_id}[$found] ) {
        ## establish standard info...
        my $library   = $fback{library}[$found];
        my $run_id    = $fback{run_id}[$found];
        my $sample_id = $fback{sample_id}[$found];
        my $well      = $fback{well}[$found];
        my $length    = $fback{sequence_length}[$found];
        my $trimmed   = $fback{trimmed_length}[$found];

        print "$found: $library\t$run_id\t$well\t$sample_id\n" if $verbose;

        if ($trace_list) {    ## if sample list supplied, then skip this sample if not included ##
            unless ( grep /^$fback{filename}[$found]\b/, @$trace_list ) {
                $found++;
                next FILE;
            }
        }
        ## add submission aliases if necessary...
        if ($submission_alias_required) {
            foreach my $alias ( keys %Submission_Aliases ) {
                my $type = $Submission_Aliases{$alias};
                if ( $type && ( $Submission_Alias{$run_id}{$well}{$type} =~ /[1-9]/ ) ) {
                    $fback{$alias}[$found] = $Submission_Alias{$run_id}{$well}{$type};
                    unless ( $trimmed == $Submission_Alias{$run_id}{$well}{length} ) {
                        push( @warnings, "Trimmed length conflict $run_id $well ($trimmed <> $Submission_Alias{$run_id}{$well}{length}" );
                    }
                }
                else {
                    push( @warnings, "Submission alias $type missing for $run_id $well." );
                    $fback{$alias}[$found] = 'undef';
                    $skipped++;
                    $found++;
                    next FILE;    ## no alias found.. skipping this record.
                }
            }

        }
        my %Sample_Alias;
        ## add sample aliases if necessary...
        if ($sample_alias_required) {
            my @sample_aliases = &Table_find_array( $API->dbc(), 'Sample_Alias', [ 'Sample_Alias.FK_Sample__ID', 'Alias_Type', 'Alias' ], "WHERE FK_Sample__ID=$sample_id" );

            foreach my $alias_info (@sample_aliases) {
                my ( $sample, $type, $alias ) = split ',', $alias_info;
                $Sample_Alias{$sample}{$type} = $alias;
            }

            foreach my $alias ( keys %Sample_Aliases ) {
                my $type = $Sample_Aliases{$alias};

                if ( $Sample_Alias{$sample_id}{$type} ) {
                    $fback{$alias}[$found] = $Sample_Alias{$sample_id}{$type};
                }
                else {
                    $fback{$alias}[$found] = 'undef';
                    push( @warnings, "NO $type alias for sample $sample_id ($run_id $well)" );    ## if submitted, generate warning ##
                    print "NO $type alias for sample $sample_id ($run_id $well)\n";
                    $aborted++;
                    $found++;
                    next FILE;                                                                    ## no alias found.. skipping this record.
                }
            }
        }
        ## add sample attributes if necessary...
        if ($sample_attribute_required) {
            my %sample_attributes = &Table_retrieve( $API->dbc(), 'Sample_Attribute,Attribute', [ 'Attribute_Name', 'Attribute_Value' ], "WHERE FK_Attribute__ID=Attribute_ID AND FK_Sample__ID=$sample_id" );
            my %Sample_Attribute;
            my $index = 0;
            while ( defined $sample_attributes{Attribute_Name}[$index] ) {
                my $attribute = $sample_attributes{Attribute_Name}[$index];
                my $value     = $sample_attributes{Attribute_Value}[$index];
                $Sample_Attribute{$sample_id}{$attribute} = $value;
                $index++;
            }

            foreach my $Attribute ( keys %Sample_Attributes ) {
                my $type = $Sample_Attributes{$Attribute};

                if ( $Sample_Attribute{$sample_id}{$type} ) {
                    $fback{$Attribute}[$found] = $Sample_Attribute{$sample_id}{$type};
                }
                else {
                    ## Use Mandatory fields if this attribute is required...
                    $fback{$Attribute}[$found] = 'undef';

                    #		      push(@warnings,"NO $type Attribute for sample $sample_id ($run_id $well)");   ## if submitted, generate warning ##
                    #		      print "NO $type Attribute for sample $sample_id ($run_id $well)\n";
                    #		      $aborted++;
                    #		      $found++;
                    #		      next FILE;     ## no attribute found.. skipping this record.

                }
            }
        }
        if ( $type eq 'BAC' ) {
            my $size   = $fback{INSERT_SIZE}[$found];
            my $stddev = $fback{INSERT_STDEV}[$found];

            if ( $size > 500 && $stddev =~ /[1-9]/ ) {    ## Req'd for types: WGS, WCS, CloneEnd(cDNA, or CloneENd strategy)
                $size   = int( ( $size + 500 ) / 1000 ) * 1000;      ### round off to represent kilobases.
                $stddev = int( ( $stddev + 500 ) / 1000 ) * 1000;    ### round off to represent kilobases.
                $fback{INSERT_SIZE}[$found]  = $size;
                $fback{INSERT_STDEV}[$found] = $stddev;
            }
            else {
                print "Size info (or stdDev) info missing for Sample: $sample_id (or smaller than 500 bps?)\n" if $verbose;
                push( @warnings, "Size information missing for: Sample $sample_id ($fback{TRACE_NAME}[$found] Run $run_id $well)." );
                $fback{INSERT_SIZE}[$found] = 'undef';
                $skipped++;
                $found++;
                next FILE;
            }

        }
        ##  Check for fields defined as Nullable : set to NULL if undefined...
        foreach my $field (@Nullable) {
            ## set negative values to NULL (used for -1 defaults : Vector_Left etc)
            if ( $fback{$field}[$found] < 0 ) { $fback{$field}[$found] = $Nullable_default; }
        }

        ##  Error checking to make sure fields defined as 'non-zero' are in fact non-zero
        foreach my $field (@Not_null) {
            unless ( defined $fback{$field}[$found] ) {
                $fback{$field}[$found] = $Not_null_default;
                push( @warnings, "$field undefined for record # $found ($fback{PLATE_ID}[$found] - $fback{WELL_ID}[$found])" );
            }
        }

        ##  Error checking to make sure Required fields are defined
###	     foreach my $field (@Required) {
###		 unless ($fback{$field}[$found]) {
###		     $fback{$field}[$found] = $Required_default;
###		     push(@warnings,"$field Required for record $found ($fback{run_id}[$found] - $fback{WELL_ID}[$found]) - excluded");
###		     print "$field Required, Value:$fback{$field}[$found] for record $found ($fback{run_id}[$found] - $fback{WELL_ID}[$found]) - excluded\n";
###		     $aborted++;
###		     $found++;
###		     next FILE;
###		 }
###	     }

        ## Ensure that trimmed length is above cutoff.
        my $ql = $fback{quality_length}[$found];
        unless ( $ql >= $min_length ) {
            if ($include_poor) {
                push( @warnings, "quality_length ($ql) < minimum length ($min_length) for record $found (Run $fback{run_id}[$found] - $fback{WELL_ID}[$found]) - included" );
            }
            else {
                push( @notes, "quality_length ($ql) < minimum length ($min_length) for record $found (Run $fback{run_id}[$found] - $fback{WELL_ID}[$found]) - excluded" );
                $poor++;
                $found++;
                next FILE;
            }
        }

        ## Set TRACE_END direction based on FWD / Reverse primers ##
        my $primer = $fback{PRIMER_CODE}[$found];
        if ( $fback{PRIMER_CODE}[$found] =~ /TARBAC/ ) { $fback{PRIMER_CODE}[$found] = 'Sp6'; }    ## convert tarbac -> Sp6 ? ... No ##
        ###
        #my ($primer_type) = Table_find($dbc, 'Primer', 'Primer_Type', "WHERE Primer_Name = '$primer'");
        my @primer_info = Table_find( $dbc, 'Primer,Primer_Customization', 'Primer_Type,Direction', "WHERE Primer_Name = '$primer' and FK_Primer__Name=Primer_Name" );

        my ( $primer_type, $primer_direction ) = split ',', $primer_info[0];
        ## allow list (problem using / / when $primer = '-21 M13 Forward' ...due to '-' at beginning ?

        if ( $primer_type eq 'Custom' || $primer_type eq 'Amplicon' ) {
            if ( $primer_direction eq 'Forward' ) {
                $fback{TRACE_END}[$found] = 'F';

            }
            elsif ( $primer_direction eq 'Reverse' ) {
                $fback{TRACE_END}[$found] = 'R';
            }
            if ( $Sample_Alias{$sample_id}{Orientation} eq 'U' ) {
                $fback{TRACE_END}[$found] = 'F';
            }
            else { $fback{TRACE_END}[$found] = 'R'; }
        }
        elsif ( $primer_type eq 'Oligo' ) {

            if ( $primer_direction =~ /Forward/i ) {
                $fback{TRACE_END}[$found] = 'F';
            }
            elsif ( $primer_direction =~ /Reverse/i ) {
                $fback{TRACE_END}[$found] = 'R';
            }
            else {
                $fback{TRACE_END}[$found] = 'N';
            }
        }
        elsif ( grep /^$primer$/, @f_primer ) {
            ## CHECK for ORIENTATION MGCC
            if ( $Sample_Alias{$sample_id}{Orientation} eq 'U' ) {
                $fback{TRACE_END}[$found] = 'R';
            }
            else { $fback{TRACE_END}[$found] = 'F'; }
        }
        elsif ( grep /^$primer$/, @r_primer ) {
            if ( $Sample_Alias{$sample_id}{Orientation} eq 'U' ) {
                $fback{TRACE_END}[$found] = 'F';
            }
            else { $fback{TRACE_END}[$found] = 'R'; }
        }
        elsif ( grep /^$primer$/, @n_primer ) {    ## unknown direction
            if ( $Sample_Alias{$sample_id}{Orientation} eq 'U' ) {
                $fback{TRACE_END}[$found] = 'F';
            }
            elsif ( $Sample_Alias{$sample_id}{Orientation} eq 'C' ) {
                $fback{TRACE_END}[$found] = 'R';
            }
            else { $fback{TRACE_END}[$found] = 'N'; }
        }
        elsif ( $primer_type =~ /[^standard]/i ) { }
        elsif ( $submission_type !~ /update/ ) {
            push( @warnings, "Invalid primer ($primer?) detected.  (should be fwd primer (@f_primer) or rev primer (@r_primer) (or @n_primer)" );
            print "Invalid primer ('$primer' ?) detected.  (should be fwd primer ('$Primer{F}') or rev primer ('$Primer{R}')\n";
            $aborted++;
            $found++;
            next FILE;
        }

        #
        #  This is now included in the common_fields tag at the top to make more efficient
        #
        #	  foreach my $key (keys %Common_Field) {
        #	      $fback{$key}[$found] = $Common_Field{$key};                   ## insert static / prompted values
        #	  }

        foreach my $mandatory (@Mandatory_Fields) {
            unless ( defined $fback{$mandatory}[$found] ) {
                push( @warnings, "Mandatory field ($mandatory) missing. ($fback{filename}[$found]) Run $fback{run_id}[$found]\n" );
                print "Missing mandatory field $mandatory. ($fback{filename}[$found]) Run $fback{run_id}[$found]\n";
                $aborted++;
                $found++;
                next FILE;
            }
        }

        foreach my $key ( keys %fback ) {
            push( @{ $traces{$key} }, $fback{$key}[$found] );
        }

        $found++;

    }
    return \%traces;
}

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

2004-06-28

=head1 REVISION <UPLINK>

$Id: trace_bundle.pl,v 1.18 2004/11/19 19:09:50 rguin Exp $ (Release: $Name:  $)

=cut

