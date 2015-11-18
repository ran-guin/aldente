################################################################################
# Sequencing_API.pm
#
# This module handles custom data access functions for the sequencing plug-in
#
###############################################################################
package Sequencing_API;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Sequencing_API.pm - This module handles custom data access functions for the sequencing plug-in

=head1 SYNOPSIS <UPLINK>
 
 #### Example of Usage ####
    
 ## Connect to the database (you may define the parameters early on and only connect later if necessary) ##
 my $API = Sequencing_API->new(-dbase=>'sequence',-host=>'athena',-user=>'viewer',-password=>$pass);
 $API->connect();
 
 ## get library direction for this library and a '-21*' primer.
 my $data = $API->get_direction(-primer=>'-21',-library=>'MGC01');

 ## get various information on sequence reads (summary information by month) ##
 my @fields = ('run_id','library','Q20','Avg_Q20','Max_Q20'); 
 my $data = $API->get_read_data(-library=>['MGC01'],-since=>'Jan 1/2002',-fields=>\@fields,
			   -include=>'production,approved',-group_by=>'month');

 ## get raw sequence data (nucleotide sequence and phred scores for each base pair ##
 my @fields = ('run_id','Well','trimmed_sequence','trimmed_scores','warning','error');
 my $data = $API->get_read_data(-library=>['MGC01'],-fields=>\@fields,-include=>'production,approved');

 my $ref= $API->get_read_data(-library=>['GAP06','GAP07','GAP08'],-since=>'2003-01-01',-until=>'Nov 23/03',
			-fields=>\@fields,-group_by=>'library',-limit=>10);

 ### Alternative retrieval method in 'array' format (each element of array is a reference to a hash of scalars)
 my @info = @{ $API->get_read_data(-library=>['GAP06','GAP07','GAP08'],-since=>'2003-01-01',-until=>'Nov 23/03',
			     -fields=>\@fields,-group_by=>'library',-limit=>10,-format=>'array')};
 foreach my $ref (@info) {
     print "run id = " . %{$ref}->{run_id};
 }

 #### Checking for possible fields that can be used ####

 ## get a list of the fields recoverable from the 'get_Read_data' method 
 my %info = %{ $API->get_read_data(-list_fields=>1) };  

 #######################################################################
 # Note: for more options and details see alDente::alDente_API module ##
 #######################################################################


 ###############################
 Using the API as a web service:
 ###############################

    Authentication:  LDAP
    Username: LDAP username
    Password: LDAP password
        (ie same password for JIRA)

        PERL Example:
        
        use XMLRPC::Lite;

        my $web_service_client =  XMLRPC::Lite ->proxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl");


        ## Creating a login object 

        my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;


        ## Calling an API method:

        my $return_data = $web_service_client->call('lims_web_service.<API_method_name>',<login_object>, <api arguments as HASHREF>);

        my $solexa_data = $web_service_client->call('lims_web_service.get_run_data',$valid_login,
                                                         {
                                                        'library' => 'mylib',
                                                         }) -> result;
        print Dumper $data;



        Python Example:
        
        #!/usr/local/bin/python

        from xmlrpclib import ServerProxy

        limsy = ServerProxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl")

        login = limsy.lims_web_service.login( {'username':'testlims','password':'testlims'} )

        data = limsy.lims_web_service.get_run_data(login,{'library':'mylib' })

        print data


NOTE:  The api arguments passed into the web service are equivalent to those passed directly to the API


=head1 DESCRIPTION <UPLINK>

=for html
This module handles custom data access functions for the sequencing plug-in<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::alDente_API);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
#use AutoLoader;
use Carp;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::HTML;

use SDB::CustomSettings;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;

use alDente::alDente_API;
use alDente::SDB_Defaults qw($project_dir $archive_dir);
use Sequencing::Tools qw(SQL_phred);
use Sequencing::Sequencing_Library;
use alDente::Library;
use alDente::Container;
use alDente::Well;
use alDente::Clone_Sample;
use alDente::Employee;
use Sequencing::ReArray;

##############################
# global_vars                #
##############################
##############################
# custom_modules_ref #
##############################
##############################
# global_vars #
##############################
use vars qw($AUTOLOAD $testing $Security $project_dir $Web_log_directory $Connection %Aliases);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $LOGPATH = "$Data_log_directory/Sequencing_API";   ## Log file base name (should be globally accessible location)
my $Q20 = SQL_phred(20);
my $Q30 = SQL_phred(30);
my $Q40 = SQL_phred(40);

## add Sequencing specific aliases to Aliases hash (originally defined in alDente_API) ##
$Aliases{Run}{sequenced_plate} = "Run.FK_Plate__ID";
$Aliases{Run}{run_name} = "Run.Run_Directory";
$Aliases{Run}{subdirectory} = "Run_Directory";
$Aliases{Run}{latest_run} = "Max(Run.Run_DateTime)";
$Aliases{Run}{run_status} = "Run.Run_Test_Status";
$Aliases{Run}{validation} = "Run.Run_Validation";
$Aliases{Run}{Q20_Array} = "Q20array";
$Aliases{Run}{Average_Q20} = "Sum(SequenceAnalysis.Q20total)/Sum(Wells)";
$Aliases{Run}{Total_Q20} = "Sum(SequenceAnalysis.Q20total)";
$Aliases{Run}{Average_QL} = "Sum(SequenceAnalysis.QLtotal)/Sum(Wells)";
$Aliases{Run}{Total_QL} = "Sum(SequenceAnalysis.QLtotal)";
$Aliases{Run}{Average_SL} = "Sum(SequenceAnalysis.SLtotal)/Sum(Wells)";
$Aliases{Run}{Total_SL} = "Sum(SequenceAnalysis.SLtotal)";
$Aliases{Run}{Total_QV} = "Sum(SequenceAnalysis.QVTotal)";
$Aliases{Run}{Average_Length} = "Sum(SequenceAnalysis.SLtotal)/Sum(Wells)";
$Aliases{Run}{Total_Length} = "Sum(SequenceAnalysis.SLtotal)";
$Aliases{Run}{Maximum_Q20} = "Q20max";
$Aliases{Run}{Average_Trimmed_Length} = "Sum(SequenceAnalysis.QLTotal - QVtotal)/Sum(Wells)";
$Aliases{Run}{Total_Trimmed_Length} = "Sum(SequenceAnalysis.QLTotal - QVtotal)";
$Aliases{Run}{run_id} = "Run.Run_ID";

#$Aliases{Run}{run_initiated_by} = "RunBatch.FK_Employee_N";   ## connected via RunBatch table... 
$Aliases{Run}{sequencer} = "RunBatch.FK_Equipment__ID";
$Aliases{Run}{run_time} = "Run_DateTime";
$Aliases{Run}{analysis_time} = "SequenceAnalysis_DateTime";
$Aliases{Run}{month} = "Left(Run_DateTime,10)";
$Aliases{Run}{year} = "Left(Run_DateTime,4)";
$Aliases{Run}{run_comments} = "CASE WHEN Length(RunBatch.RunBatch_Comments) > 0 THEN concat(RunBatch.RunBatch_Comments,'; ',Run.Run_Comments) ELSE Run.Run_Comments END";
# aliases below use SequenceAnalysis
$Aliases{Run}{reads} = "Sum(SequenceAnalysis.AllReads)";
$Aliases{Run}{good_reads} = "Sum(SequenceAnalysis.Wells)";
$Aliases{Run}{no_grows} = "Sum(SequenceAnalysis.NGs)";
#$Aliases{Run}{chemistry_code} = "Run.FK_Chemistry_Code__Name"; #corrected and moved to alDente_API
$Aliases{Run}{unique_samples} = "count(DISTINCT Clone_Sequence.FK_Sample__ID)"; 
#$Aliases{Run}{unique_sample_reads} = "count(DISTINCT concat(Clone_Sequence.FK_Sample__ID,FK_Chemistry_Code__Name))"; #corrected and moved to alDente_API
$Aliases{Run}{unique_wells} = "count(DISTINCT concat(Library_Name,Plate_Number,Parent_Quadrant,Clone_Sequence.Well))";                      
#$Aliases{Run}{unique_reads} = "count(DISTINCT concat(Library_Name,Plate_Number,Parent_Quadrant,Clone_Sequence.Well,FK_Chemistry_Code__Name))"; ## unique clones + chemistry #corrected and moved to alDente_API
$Aliases{Run}{successful_reads} = "Sum(SequenceAnalysis.successful_reads)";                             ## QL > 100
$Aliases{Run}{trimmed_successful_reads} = "Sum(SequenceAnalysis.trimmed_successful_reads)";             ## QL - VQ > 100
$Aliases{Run}{success_rate} = "Sum(SequenceAnalysis.successful_reads)/Sum(Wells)*100";                  ## % with QL > 100 (excluding No grows, unused wells)
$Aliases{Run}{trimmed_success_rate} = "Sum(SequenceAnalysis.trimmed_successful_reads)/Sum(Wells)*100";  ## % with QL > 100 (excluding No grows, unused wells)


$Aliases{Project}{project} = "Project.Project_Name";
$Aliases{Project}{project_path} = "Project.Project_Path";
$Aliases{Study}{study} = "Study.Study_Name";
$Aliases{Study}{study_id} = "Study.Study_ID";
$Aliases{Library}{library} = "Library.Library_Name";
$Aliases{Library}{library_started} = "Library.Library_Obtained_Date";
$Aliases{Library}{library_source}  = "Library.Library_Source";
$Aliases{Library}{library_source_name} = "Library.External_Library_Name";
$Aliases{Library}{library_format}  = "Vector_Based_Library_Format";
$Aliases{Library}{direction} = "LibraryPrimer.Direction";
#$Aliases{Library}{primer} = "LibraryPrimer.FK_Primer__Name";
$Aliases{Library}{description} = "Library.Library_Description";
$Aliases{Library}{library_format}  = "Vector_Based_Library_Format";
$Aliases{Library}{organism} = "Taxonomy.Taxonomy_Name";
$Aliases{Library}{stage} = "Stage.Stage_Name";
$Aliases{Library}{starting_amount_ng} = "SAGE_Library.Starting_RNA_DNA_Amnt_ng";
#$Aliases{Library}{starting_amount_units} = "Source.Amount_Units";

my %Vector_Alias;   ## Library Alias ##
$Aliases{Vector}{vector_file} = "Vector_Type.Vector_Sequence_File";
## Primer Alias ##

my %Primer_Alias;   
$Aliases{Primer}{primer_sequence} = "Primer.Primer_Sequence";
$Aliases{Primer}{primer} = "Primer.Primer_Name";
$Aliases{Primer}{primer_type} = "Primer.Primer_Type";
$Aliases{Primer}{oligo_primer} = "Primer_Plate_Well.FK_Primer__Name";
$Aliases{Primer}{oligo_sequence} = "Primer.Primer_Sequence";
$Aliases{Primer}{oligo_direction} = "Primer_Customization.Direction";
$Aliases{Primer}{working_tm} = "Primer_Customization.Tm_Working";
## Primer Aliases (related to Primer_Plate)
$Aliases{Primer}{primer_plate_name} = "Primer_Plate.Primer_Plate_Name";
$Aliases{Primer}{primer_plate_status} = "Primer_Plate.Primer_Plate_Status";
$Aliases{Primer}{primer_plate_id} = "Primer_Plate.Primer_Plate_ID";
$Aliases{Primer}{primer_plate_well} = "Primer_Plate_Well.Well";

$Aliases{Primer}{primer_well} = "Primer_Plate_Well.Well";
$Aliases{Primer}{notes} = "Primer_Plate.Notes";
$Aliases{Primer}{order_date} = "Primer_Plate.Order_DateTime";
$Aliases{Primer}{arrival_date} = "Primer_Plate.Arrival_DateTime";
$Aliases{Primer}{primer_plate_solution} = "Primer_Plate.FK_Solution__ID";
$Aliases{Primer}{amplicon_length} = "Primer_Customization.Amplicon_Length";
$Aliases{Primer}{stock_source} = "Stock_Catalog.Stock_Source";

$Aliases{Pool}{pool_gel_id} = "Transposon_Pool.FK_GelRun__ID";
$Aliases{Pool}{OD_id} = "Transposon_Pool.FK_Optical_Density__ID";
$Aliases{Pool}{pool_pipeline} = "Transposon_Pool.Pipeline"; 
$Aliases{Pool}{pool_reads_required} = "Transposon_Pool.Reads_Required";
$Aliases{Pool}{pool_transposon_id} = "Transposon_Pool.FK_Transposon__ID";
$Aliases{Pool}{pool_transposon} = "Transposon.Transposon_Name";

my %ReArray_Alias;
$Aliases{ReArray}{rearray_type} = 'ReArray_Request.ReArray_Type';
$Aliases{ReArray}{rearray_target} = 'ReArray_Request.FKTarget_Plate__ID';
$Aliases{ReArray}{rearray_target_well} = 'ReArray.Target_Well';
$Aliases{ReArray}{rearray_source} = 'ReArray.FKSource_Plate__ID';
$Aliases{ReArray}{rearray_source_well} = 'ReArray.Source_Well';
$Aliases{ReArray}{rearray_datetime} = 'ReArray_Request.Request_DateTime';

my %Read_Alias;
$Aliases{Read}{unique_samples} = "count(DISTINCT Clone_Sequence.FK_Sample__ID)";
$Aliases{Read}{sequenced_well} = "Clone_Sequence.Well";
$Aliases{Read}{Q20} = SQL_phred(20);
$Aliases{Read}{Q30} = SQL_phred(30);
$Aliases{Read}{Q40} = SQL_phred(40);

$Aliases{Read}{'Max_Q20'} = "Max(" . SQL_phred(20) . ")";
$Aliases{Read}{'Max_Q30'} = "Max(" . SQL_phred(30) . ")";
$Aliases{Read}{'Max_Q40'} = "Max(" . SQL_phred(40) . ")";
$Aliases{Read}{'Avg_Q20'} = "Sum(" . SQL_phred(20) . ") / count(*)";
$Aliases{Read}{'Avg_Q30'} = "Sum(" . SQL_phred(30) . ") / count(*)";
$Aliases{Read}{'Avg_Q40'} = "Sum(" . SQL_phred(40) . ") / count(*)";
$Aliases{Read}{'Sum_Q20'} = "Sum(" . SQL_phred(20) . ")";
$Aliases{Read}{'Sum_Q30'} = "Sum(" . SQL_phred(30) . ")";
$Aliases{Read}{'Sum_Q40'} = "Sum(" . SQL_phred(40) . ")";
$Aliases{Read}{warning} = "Clone_Sequence.Read_Warning";
$Aliases{Read}{error} = "Clone_Sequence.Read_Error";
$Aliases{Read}{read_comments} = "Clone_Sequence.Clone_Sequence_Comments";
###### Run trimmed for both quality and vector ##########
$Aliases{Read}{'trimmed_sequence'} = "MID(Clone_Sequence.Sequence,GREATEST(Quality_Left+1,Vector_Left+2,0),CASE WHEN (Vector_Right>0 OR Vector_Left>0) THEN (Quality_Length-Vector_Quality) ELSE Clone_Sequence.Quality_Length END)";
$Aliases{Read}{'trimmed_length'} = "Clone_Sequence.Quality_Length - Clone_Sequence.Vector_Quality";
$Aliases{Read}{'trimmed_scores'} = "MID(Sequence_Scores,GREATEST(Quality_Left+1,Vector_Left+2,0),CASE WHEN (Vector_Right>0 OR Vector_Left>0) THEN (Quality_Length-Vector_Quality) ELSE Clone_Sequence.Quality_Length END)";
###### Run trimmed for quality alone (based on phred contiguous quality region) ######
$Aliases{Read}{'quality_sequence'} = "MID(Clone_Sequence.Sequence,GREATEST(Quality_Left+1,0),GREATEST(Quality_Length,0))";
$Aliases{Read}{'quality_length'} = "Clone_Sequence.Quality_Length";
$Aliases{Read}{'quality_vector'} = "Clone_Sequence.Vector_Quality";
$Aliases{Read}{'quality_scores'} = "MID(Clone_Sequence.Sequence_Scores,GREATEST(Quality_Left+1,0),GREATEST(Quality_Length,0))";

$Aliases{Read}{'sequence'} = 'Clone_Sequence.Sequence';
$Aliases{Read}{'sequence_length'} = 'Clone_Sequence.Sequence_Length';
$Aliases{Read}{'sequence_scores'} = 'Clone_Sequence.Sequence_Scores';

$Aliases{Read}{'sample_id'} = "Clone_Sequence.FK_Sample__ID";
$Aliases{Read}{'phred_version'} = "SequenceAnalysis.Phred_Version";
## my %Sample_Alias;

$Aliases{Clone}{mgc_number} = "Sample_Alias.Alias";

$Aliases{Rearray}{source_plate_id} = 'Source_Plate.Plate_ID';
$Aliases{Rearray}{source_library} = 'Source_Plate.FK_Library__Name';
$Aliases{Rearray}{source_plate_number} = 'Source_Plate.Plate_Number';
$Aliases{Rearray}{source_plate_quadrant} = 'Source_Plate.Parent_Quadrant';
$Aliases{Rearray}{target_plate_id} = 'Target_Plate.Plate_ID';
$Aliases{Rearray}{target_library} = 'Target_Plate.FK_Library__Name';
$Aliases{Rearray}{target_plate_number} = 'Target_Plate.Plate_Number';
$Aliases{Rearray}{primer_name} = 'Primer.Primer_Name';
$Aliases{Rearray}{source_well} = 'ReArray.Source_Well';
$Aliases{Rearray}{target_well} = 'ReArray.Target_Well';
$Aliases{Rearray}{oligo_direction} = 'Primer_Customization.Oligo_Direction';
$Aliases{Rearray}{rearray_request_id} = "ReArray_Request.ReArray_Request_ID";
$Aliases{Rearray}{tm} = 'Primer_Customization.Tm_Working';
$Aliases{Rearray}{primer_sequence} = 'Primer.Primer_Sequence';
$Aliases{Rearray}{rearray_type} = 'ReArray_Request.ReArray_Type';
$Aliases{Rearray}{rearray_status} = 'ReArray_Request.ReArray_Status';
$Aliases{Rearray}{primer_well} = 'Primer_Plate_Well.Well';
$Aliases{Rearray}{solution_id} = 'Primer_Plate.FK_Solution__ID';
$Aliases{Rearray}{primer_plate_name} = "Primer_Plate.Primer_Plate_Name";
$Aliases{Rearray}{primer_order_date} = "Primer_Plate.Order_DateTime";
$Aliases{Rearray}{primer_arrival_date} = "Primer_Plate.Arrival_DateTime";
$Aliases{Rearray}{sample_id} = "Plate_Sample.FK_Sample__ID";
$Aliases{Rearray}{sample_name} = "Sample.Sample_Name";
$Aliases{Rearray}{rearray_date} = "ReArray_Request.Request_DateTime";
$Aliases{Rearray}{employee_name} = "Employee.Employee_Name";
$Aliases{Rearray}{employee_id} = "ReArray_Request.FK_Employee__ID";
# alternate aliases for rearrays (if going through an applied primer instead of an oligo rearray)
# note that these are more limited than the above
## alt_Rearray aliases;
$Aliases{alt_Rearray}{target_plate_id} = 'Plate.Plate_ID';
$Aliases{alt_Rearray}{target_library} = 'Plate.FK_Library__Name';
$Aliases{alt_Rearray}{target_plate_number} = 'Plate.Plate_Number';
$Aliases{alt_Rearray}{primer_name} = 'Primer.Primer_Name';
$Aliases{alt_Rearray}{target_well} = 'Primer_Plate_Well.Well';
$Aliases{alt_Rearray}{tm} = 'Primer_Customization.Tm_Working';
$Aliases{alt_Rearray}{primer_sequence} = 'Primer.Primer_Sequence';
$Aliases{alt_Rearray}{primer_well} = 'Primer_Plate_Well.Well';
$Aliases{alt_Rearray}{solution_id} = 'Primer_Plate.FK_Solution__ID';
$Aliases{alt_Rearray}{primer_plate_name} = "Primer_Plate.Primer_Plate_Name";
$Aliases{alt_Rearray}{primer_order_date} = "Primer_Plate.Order_DateTime";
$Aliases{alt_Rearray}{primer_arrival_date} = "Primer_Plate.Arrival_DateTime";
$Aliases{alt_Rearray}{sample_id} = "Plate_Sample.FK_Sample__ID";
$Aliases{alt_Rearray}{sample_name} = "Sample.Sample_Name";

$Aliases{SolexaRun}{flowcell_code   } = "Flowcell.Flowcell_Code";
$Aliases{SolexaRun}{grafted_datetime} = "Flowcell.Grafted_Datetime";
$Aliases{SolexaRun}{lot_number      } = "Flowcell.Lot_Number";
$Aliases{SolexaRun}{lane            } = "SolexaRun.Lane";
$Aliases{SolexaRun}{sample_name     } = "Sample.Sample_Name";
$Aliases{SolexaRun}{plate_id        } = "Plate.Plate_ID";
$Aliases{SolexaRun}{flowcell_id     } = "Flowcell.Flowcell_ID";

$Aliases{Read}{trace_name} = "CONCAT(Run_Directory,'_',Clone_Sequence.Well)";  ## only use when extracting specific read data
#$Aliases{Read}{trace_name} = "CONCAT(Library_Name,'-',Plate_Number,Parent_Quadrant,'.',FK_Branch__Code,'_',Clone_Sequence.Well)";  ## only use when extracting specific read data
##############################
# constructor                #
##############################

########
sub new {
########
    my $this  = shift;
    my $class  = ref($this) || $this;

    my %args = &filter_input(\@_);
    if ($args{ERROR}) { Message($args{ERROR}); return ; }
    
    ### Connection parameters ### 
    ### Mandatory ###
    my $dbase = $args{-dbase} || '';
    my $host =  $args{-host} || $Defaults{SQL_HOST};                # Name of host on which database resides [String]
    my $LIMS_user     = $args{-LIMS_user};                          # LIMS user name (NOT same as Database connection user name) [String]
    my $LIMS_password = $args{-LIMS_password};                      # LIMS password (NOT same as Database connection password) [String]
    my $DB_user     = $args{-DB_user} || 'guest';                   # Database connection username (NOT same as LIMS user)
    ### Common Options ###
    my $connect = $args{-connect};                                      # Flag to indicate that connection should be made immediately
    my $quiet = $args{-quiet} || 0;                                   # suppress printed feedback (defaults to 0) [Int]
    my $DB_password = $args{-DB_password} || '';                           ## may supply Database password directly if known       
    
    ### Advanced optional parameters ###
    my $driver = $args{-driver} || $Defaults{SQL_DRIVER} || 'mysql'; # SQL driver  [String]
    my $dsn = $args{-dsn};                                           # Connection string [String]
    my $trace = $args{-trace_level} || 0;                            # set trace level on database connection (defaults to 0) [Int]
    my $trace_file = $args{-trace_file} || 'Trace.log';              # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $alias_file = $args{-alias_file} || "$config_dir/db_alias.conf"; # Location of DB alias file (optional) [String]
    my $alias_ref = $args{-alias};                                      # Reference to DB alias hash (optional). If passed in then overrides alias file [HashRef]
    my $sessionless = $args{-sessionless} || 1; 
    my $debug = $args{-debug};

    if (!$dsn && $driver && $dbase && $host) {          # If DSN is not specified but all other info are provided, then we build a DSN.
	$dsn = "DBI:$driver:database=$dbase:$host";
    }
    
    ## Define connection attributes
    my $self = $this->alDente::alDente_API::new(%args);
    # -dbase=>$dbase,-host=>$host,-user=>$DB_user,-password=>$DB_password,-debug=>$debug,-connect=>$connect
    bless $self,$class;
    ###  Connection attributes ###
    $self->{sth} = '';                                                 # Current statement handle [Object]
    $self->{dbase} = $dbase;                                           # Database name [String]
    $self->{host} = $host;                                             # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver} = $driver;                                              # SQL driver [String]
    $self->{dsn} = $dsn;                                                 # Connection string [String]
    
    $self->{DB_user} = $DB_user;
    $self->{DB_password} = $DB_password;
    $self->{LIMS_user} = $LIMS_user;                                          # Login user name [String]
    $self->{LIMS_password} = $LIMS_password;                                  # (MANDATORY unless login_file used) specification of password [String]

    $self->{trace} = $trace;                                                # set trace level on database connection (defaults to 0) [Int]
    $self->{trace_file} = $trace_file;                                          # optional trace_file where trace info to be written. (required if trace_level set) [String]
    $self->{quiet} = $quiet;                                                # suppress printed feedback (defaults to 0) [Int]
    
 #   if ($connect) {
#	$self->connect_to_DB();
#	$self->{isConnected} = 1;
#    } else { 
#	$self->{isConnected} = 0; 
#    }
    					  
    return $self;
}

##############################
# public_methods             #
##############################

##########################
sub DESTROY {
##########################
  my $self = shift;
  $self->SUPER::DESTROY;
  my $dbc = $self->dbc();
  $dbc->disconnect();
}

###############################################################
# gets information about primers.
# <snip>
# Example: 
#  my $result = $API->get_Primer_data(-primer=>'T7');
#
#   ## see if a given sequence has already been used for any primers (including custom primers) ###
#  my $data = $API->get_Primer_data(-condition=>"replace(primer_sequence,' ','')='$sequence'",-custom=>1);
#
# </snip>
#
# -fields - the field names needed, as a comma-delimited list. 
# -conditions - the search condition, as a comma-delimited list of field name=value pairs.
#
# LIST OF VALID FIELD NAMES for fields and conditions:
#
# 
# RETURN: a hash of arrayrefs, with each field name as a key in the hash, and all the values for it in the array
###############################################################
sub get_Primer_data { 
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    return $self->get_primer_data(%args);

}

###############################################################
# gets information about primers.
# <snip>
# Example: 
#  my $result = $API->get_Primer_data(-primer=>'T7');
#
#   ## see if a given sequence has already been used for any primers (including custom primers) ###
#  my $data = $API->get_Primer_data(-condition=>"replace(primer_sequence,' ','')='$sequence'",-custom=>1);
#
# </snip>
#
# -fields - the field names needed, as a comma-delimited list. 
# -conditions - the search condition, as a comma-delimited list of field name=value pairs.
#
# LIST OF VALID FIELD NAMES for fields and conditions:
#
# 
# RETURN: a hash of arrayrefs, with each field name as a key in the hash, and all the values for it in the array
########################
sub get_primer_data {
########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    
    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention
    
    ## Specify conditions for data retrieval
    my $input_conditions   = $args{-condition} || '1';             ### extra condition (vulnerable to structure change)
    my $primer             = $args{-primer};
    my $primer_plate_id    = $args{-primer_plate_id};
    my $primer_plate_name  = $args{-primer_plate_name};
    my $solution_id        = $args{-solution_id};
    my $source             = $args{-source};                     ## source of item (ie box, order, or made)

    my $custom             = $args{-custom};                     ## flag to search for custom primers
    my $oligo              = $args{-oligo};                      ## flag to search for oligo primers
    my $primer_type        = $args{-primer_type}; 
    my $input_joins      = $args{-input_joins};
    my $input_left_joins      = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since       = $args{-since};                              ### specify date to begin search (context dependent)
    my $until       = $args{-until};                               ### specify date to stop search (context dependent)

    ## Output options 
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       =  $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key} || $group;
    my $limit       = $args{-limit} || '';                        ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                              ### suppress feedback by setting quiet option
    my $save        = $args{-save};
    my $list_fields = $args{-list_fields};                        ### just generate a list of output fields

    ### Re-Cast arguments as required ###
    my $primers ; $primers = Cast_List(-list=>$primer,-to=>'string',-autoquote=>1) if $primer;
    my $primer_plate_ids ; $primer_plate_ids = Cast_List(-list=>$primer_plate_id,-to=>'string',-autoquote=>1) if $primer_plate_id;
    my $primer_plate_names ; $primer_plate_names = Cast_List(-list=>$primer_plate_name,-to=>'string',-autoquote=>1) if $primer_plate_name;
    my $solution_ids ; $solution_ids = Cast_List(-list=>$solution_id,-to=>'string',-autoquote=>1) if $solution_id;
    my $primer_types; $primer_types = Cast_List(-list=>$primer_type,-to=>'String',-autoquote=>1) if $primer_type;
    my $dbc = $self->dbc();

    ## Define Tables / Conditions ##    
    my @extra_conditions ; 
    @extra_conditions = Cast_List(-list=>$input_conditions,-to=>'array',-no_split=>1) if $input_conditions;
    push @extra_conditions, "Primer_Name IN ($primers)" if $primers;
    push @extra_conditions, "Primer_Plate_Name IN ($primer_plate_names)" if $primer_plate_names;
    push @extra_conditions, "Primer_Plate_ID IN ($primer_plate_ids)" if $primer_plate_ids;
    push @extra_conditions, "Stock_Catalog.Stock_Source = '$source'" if $source;

    
    if ($primer_types) {
        push @extra_conditions, "Primer_Type IN ($primer_types)";
    } elsif (!$custom) {
        push @extra_conditions, "Primer_Type = 'Standard'" ;
    }

    ## Initial Framework for query ##
    my $tables = 'Primer';           ## <- Supply list of Tables to retrieve data from ##
    my $join_condition = 'WHERE 1';   ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = ''; ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {
	    'Primer_Customization' => 'Primer_Customization.FK_Primer__Name=Primer_Name',
	    'Primer_Info'          => 'Primer_Info.FK_Solution__ID=Solution.Solution_ID',
    };  ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
	'Solution'             => 'Solution.FK_Stock__ID=Stock_ID',
        'Stock_Catalog'        => 'Stock_Catalog.Stock_Catalog_Name=Primer.Primer_Name',
        'Stock'                => 'Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID'
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## custom adjustments ..
    if ($solution_ids) {
	#check for solution type
	my ($custom_oligo_plate) = $self->Table_find("Solution,Stock,Stock_Catalog,Primer_Plate","Solution_ID","WHERE Solution_ID IN ($solution_ids) and Primer_Plate.FK_Solution__ID = Solution_ID and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID");
	if ($custom_oligo_plate) { $oligo = 1 }
    }
    if ($oligo) {
        
	    $join_conditions->{'Primer_Plate_Well'} = 'Primer_Plate_Well.FK_Primer__Name = Primer.Primer_Name';
	    $join_conditions->{'Primer_Plate'}      = 'Primer_Plate_ID=Primer_Plate_Well.FK_Primer_Plate__ID';
	## overwrite existing left join conditions... ##
	    $left_join_conditions->{Solution} = 'Primer_Plate.FK_Solution__ID=Solution_ID';
	    $left_join_conditions->{Stock} = 'Solution.FK_Stock__ID=Stock_ID';
	    $left_join_conditions->{Stock_Catalog} = 'Stock_Catalog.Stock_Catalog_ID=Stock.FK_Stock_Catalog__ID';
	    if (!$add_fields) { my @add = qw(primer_well); $add_fields = \@add;}
	    else { my @add_list = Cast_List(-list=>$add_fields,-to=>'array'); push @add_list, 'primer_well'; $add_fields = \@add_list; }
    } 
   else {
	#$left_join_conditions->{Solution} = 'Solution.FK_Stock__ID=Stock_ID';      ## 'Primer_Plate.FK_Solution__ID=Solution_ID';
	#$left_join_conditions->{Stock_Catalog} = 'Stock_Catalog.Stock_Catalog_Name=Primer.Primer_Name';
	#$left_join_conditions->{Stock} = 'Stock.FK_Stock_Catalog__ID=Stock_Catalog_ID',
    }

    ## adapt conditions using appropriate aliases as required ##
    &alDente::alDente_API::customize_join_conditions($join_conditions,$left_join_conditions,-input_joins=>$input_joins,-tables=>$tables,-input_left_joins=>$input_left_joins);
    
    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};
    
    my @field_list = qw(primer_name primer_sequence);      ## <- Default list of fields to retrieve     

    ## IF fields specified, over-ride default list ##
    if ($fields) {
	@field_list = Cast_List(-list=>$fields,-to=>'array');
    } elsif ($add_fields) {
	my @add_list = Cast_List(-list=>$add_fields,-to=>'array');
	push(@field_list,@add_list);
    }
    
    #<Construction> This nees to be clean up
    my ($solution_or_stock) = grep ($_ =~ /Solution|Stock/i && $_ !~ /primer_plate_solution/i, @field_list);
    if ($solution_or_stock && !$oligo) {
	#order required, so do straight join
	$tables .= ',Stock_Catalog,Stock,Solution';
	$join_condition .= ' AND Primer.Primer_Name = Stock_Catalog.Stock_Catalog_Name AND Stock_Catalog.Stock_Catalog_ID = Stock.FK_Stock_Catalog__ID AND Stock.Stock_ID = Solution.FK_Stock__ID';
	push @extra_conditions, "Solution_ID IN ($solution_ids)" if $solution_ids;
    }
    else { push @extra_conditions, "FK_Solution__ID IN ($solution_ids)" if $solution_ids; }

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    return $self->generate_data(
				-input=>\%args,
				-field_list=>\@field_list,
				-group=>$group,
				-key=>$KEY,
				-order=>$order,
				-tables=>$tables,
				-join_condition => $join_condition,
				-conditions=>$conditions,
				-left_join_tables => $left_join_tables,
				-left_join_conditions => $left_join_conditions,
				-join_conditions => $join_conditions,
				-limit => $limit,
				-dbc => $dbc,
				-quiet => $quiet
				);
}

###############################################################
# get location information for a rearray's source plates
# <snip>
# Example: 
# my $result = $API->get_Rearray_locations(
#	     -rearray_ids=>[291,292]
#	);
# </snip>
#
# -rearray_ids => an array reference of rearray ids 
# 
# RETURN: a hashref of locations, keyed by plate id
###############################################################
sub get_Rearray_locations {
######################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input(\@_,-args=>"rearray_ids");
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return {}; }

    my $rearray_ids = $args{-rearray_ids};
    my $dbc = $self->{dbc};

    if (scalar(@$rearray_ids) == 0) {
	print "ERROR: Invalid parameter: Must have one or more rearray ids\n";
	return {};
    }
    my $start = timestamp();

    my @field_list = ("Plate_ID","Equipment_Name","Rack_Alias as Rack_Name");

    my $ids = join(',',@$rearray_ids);
    my %loc_info = &Table_retrieve($dbc,"ReArray,Plate,Rack,Equipment",\@field_list,"WHERE FKSource_Plate__ID=Plate_ID AND FK_Rack__ID=Rack_ID AND FK_Equipment__ID=Equipment_ID AND FK_ReArray_Request__ID in ($ids)");
    my %retval;
    my $counter = 1;
    foreach my $plate_id (@{$loc_info{'Plate_ID'}}) {
	if (defined $retval{$plate_id}) {
	    next;
	}
	else {
	    $retval{$plate_id} = "$loc_info{'Equipment_Name'}[$counter] - $loc_info{'Rack_Name'}[$counter]"; 
	}
	$counter++;
    }
    return $self->api_output(-data=>\%retval,-start=>$start,-log=>1,-customized_output=>1);
}

###############################################################
# gets information about rearrays.
# <snip>
# Example: 
# my $result = $API->get_Rearray_data(
#	     -fields=>"primer_name,target_well,oligo_direction",
#	     -conditions=>"target_library=LL005,target_plate_number=260"
#	);
# </snip>
#
# -fields - the field names needed, as a comma-delimited list. 
# -conditions - the search condition, as a comma-delimited list of field name=value pairs.
#
# LIST OF VALID FIELD NAMES for fields and conditions:
#
# source_plate_id,
# source_library,source_plate_number,target_plate_id,target_library,target_plate_number
# primer_name,source_well,target_well,oligo_direction,rearray_request_id,tm,primer_sequence
# rearray_type, rearray_status, primer_well, solution_id, primer_plate_name, sample_id, sample_name
# 
# RETURN: a hash of arrayrefs, with each field name as a key in the hash, and all the values for it in the array
###############################################################
sub get_Rearray_data {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my $start = timestamp();

    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $fields = $args{-fields};         # (Scalar) Comma-delimited list of fields to include in the result set
    my $conditions = $args{-conditions}; # (Scalar) Comma-delimited list of pairs <field name>=<value> that is the condition of the query
    my $hash_key = $args{-hash_key};     # (Scalar) (Optional) A key field to return on. The return hashref will have this field as keys, and the value is a hashref, with keys as the other field names, and the values as the result values. 
    my $scope = $args{-scope} || 'Extended'; # (Scalar) (Optional) One of Extended or Standard. Standard scope only checks rearrays for primers, not including primers that have been applied as a solution
    
    $self->connect_if_necessary();

    my $dbc = $self->dbc();

    # flag that keeps track of whether or not the joins were reset because of the Solution_ID join
    my $reset_join = 0;
    # split the fields and substitute the aliases
    my @temp_field_array = split ',',$fields; 
    my @field_array;
    foreach my $field (@temp_field_array) {
	if (defined $Aliases{Rearray}{$field}) {
	    push (@field_array,"$Aliases{Rearray}{$field} as $field");
	}
	else {
	    print "ERROR: field $field not defined\n";
	    return undef;
	}
    }

    # build the search condition dynamically
    my @condition_array = split ',',$conditions; 
    #my @condition_array = $conditions =~ /(\w+=[\(\']?[\w,\.]+[\)\']?),?/gi;


    my $condition_string = "";
    my $additional_joins = "";
    foreach my $condition (@condition_array) {
	$condition =~ /(.+)(<|<=|=|>=|>)(.+)/;
	my $condition_field = $1;
	my $condition_value = $3;
	my $comparator = $2;
	if (defined $Aliases{Rearray}{$condition_field}) {
	    if ($condition_value =~ /,/) {
		if ($comparator eq '=') {
		    my @condition_items = split ',',$condition_value;
		    foreach (@condition_items) {
			$_ =~ s/[\(\)]//g;
			$_ = "'$_'";
		    }
		    $condition_value = join ',',@condition_items;
		    $condition_string .= " $Aliases{Rearray}{$condition_field} in ($condition_value) AND ";
		}
		else {
		    print "ERROR: Invalid comparison: Set of values but not using = comparator";
		    return undef;
		}
	    }
	    else {
		$condition_string .= " $Aliases{Rearray}{$condition_field} $comparator '$condition_value' AND ";
	    }
	}
	else {
	    print "ERROR: field $condition_field not defined\n";
	    return undef;
	}
    }
    if ($hash_key) {
	unless (defined($Aliases{Rearray}{$hash_key})) {
	    print "ERROR: field $hash_key not defined\n";
	    return undef;
	}
    }

    ### build the joins depending on what the user is searching for 
    # if querying target_plate, add in Target_Plate
    # if querying source_plate, add in Source_Plate
    # if querying sample_id, add in Target_Plate AND Plate_Sample
    # if querying sample_name, add in Target_Plate, Plate_Sample, AND Sample
    # if querying primer, add in Plate_PrimerPlateWell,Primer_Plate_Well, Primer_Plate, Primer, and Primer_Customization
    if ( (scalar(grep(/Source_Plate/i,@field_array)) > 0) || ($condition_string =~ /Source_Plate/i) ) {
	$additional_joins .= " inner join Plate as Source_Plate on FKSource_Plate__ID=Source_Plate.Plate_ID "; 
    }
    if ( (scalar(grep(/Employee/i,@field_array)) > 0) || ($condition_string =~ /Employee/i) ) {
	$additional_joins .= " inner join Employee on ReArray_Request.FK_Employee__ID=Employee_ID "; 
    }
    if ( (scalar(grep(/Sample/i,@field_array)) > 0) || ($condition_string =~ /Sample/i) ) {
	$additional_joins .= " inner join Plate as Target_Plate on FKTarget_Plate__ID=Target_Plate.Plate_ID join Plate_Sample on Plate_Sample.FKOriginal_Plate__ID=FKTarget_Plate__ID join Sample on Plate_Sample.FK_Sample__ID=Sample_ID ";
	$condition_string .= " Plate_Sample.Well=Target_Well AND ";
    }
    elsif ( (scalar(grep(/Plate_Sample/i,@field_array)) > 0) || ($condition_string =~ /Plate_Sample/i) ) {
	$additional_joins .= " join Plate as Target_Plate on FKTarget_Plate__ID=Target_Plate.Plate_ID join Plate_Sample on FKOriginal_Plate__ID=FKTarget_Plate__ID ";
	$condition_string .= " Plate_Sample.Well=Target_Well AND ";
    }
    elsif ( (scalar(grep(/Target_Plate/i,@field_array)) > 0) || ($condition_string =~ /Target_Plate/i) ) {
	$additional_joins .= " join Plate as Target_Plate on Target_Plate.Plate_ID=FKTarget_Plate__ID ";
    }
    if ( (scalar(grep(/Primer/i,@field_array)) > 0) || ($condition_string =~ /Primer/i) ) {
	# check to see if plate has an oligo rearray associated with it
	my $check_condition_string = "";
	foreach my $condition (@condition_array) {
	    $condition =~ /(.+)(<|<=|=|>=|>)(.+)/;
	    my $condition_field = $1;
	    my $condition_value = $3;
	    my $comparator = $2;
	    if ( (defined $Aliases{Rearray}{$condition_field}) && ($Aliases{Rearray}{$condition_field} =~ /Target_Plate/) ) {
		$check_condition_string .= " $Aliases{Rearray}{$condition_field} $comparator '$condition_value' AND ";
	    }
	}

	my $sth = $self->query(-query=>"SELECT DISTINCT Plate_ID FROM ReArray_Request inner join ReArray on FK_ReArray_Request__ID=ReArray_Request_ID $additional_joins WHERE (ReArray_Type='Oligo' OR ReArray_Type='Resequence ESTs' OR ReArray_Type='Standard') AND $check_condition_string 1",-finish=>0);
	my $retval = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'HofA');
	

	if ( ($scope =~  /Standard/i) || $retval) {
	    # if yes, continue with normal query
	    $additional_joins .= " left join Plate_PrimerPlateWell on (Plate_Well=Target_Well AND FKTarget_Plate__ID=Plate_PrimerPlateWell.FK_Plate__ID) left join Primer_Plate_Well on FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID left join Primer_Plate on FK_Primer_Plate__ID=Primer_Plate_ID left join Primer on Primer_Plate_Well.FK_Primer__Name=Primer_Name left join Primer_Customization on Primer_Customization.FK_Primer__Name=Primer_Name ";
	    # if the condition string has primers associated with it, assume that a straight join is ok
	    if ($condition_string =~ /Primer/i) {
		$additional_joins =~ s/ left join / join /gi;
	    }
	}
	else {
	    # if no, then grab the plate id/s, find all solutions associated with it/them (error out if multiple primer reagents or multiple non-equal sized plates found), get the Custom Oligo Plate solution id, and join on that to get the primer information
	    my $plate_condition = "";

	    foreach my $condition (@condition_array) {
		my ($condition_field,$condition_value) = split '=',$condition;
		if ($Aliases{Rearray}{$condition_field} eq "Target_Plate.Plate_ID") {
		    $plate_condition .= " Plate_ID = $condition_value AND ";
		}
		if ($Aliases{Rearray}{$condition_field} eq "Target_Plate.FK_Library__Name") {
		    $plate_condition .= " FK_Library__Name = '$condition_value' AND ";
		}
		if ($Aliases{Rearray}{$condition_field} eq "Target_Plate.Plate_Number") {
		    $plate_condition .= " Plate_Number = '$condition_value' AND ";
		}
	    }
	
	    # cannot resolve plate id, error out
	    if ($plate_condition eq "") {
		print "ERROR: Cannot resolve plate id from given arguments\n";
		return undef;
	    }
	    $plate_condition .= "1";

	    my @plate_ids = $self->Table_find("Plate","Plate_ID","WHERE $plate_condition");
	    unless (@plate_ids && (scalar(@plate_ids) > 0)) {
		print "ERROR: Cannot resolve plate id from given arguments\n";
		return undef;		
	    }
	    my $container = new alDente::Container(-dbc=>$dbc);
	    my $solution_list = $container->get_Solutions(-ids=>join(',',@plate_ids),-reagents=>1);
	    my @custom_sol_ids = $self->Table_find("Stock,Solution,Stock_Catalog","Solution_ID","WHERE FK_Stock_Catalog__ID = Stock_catalog_ID AND FK_Stock__ID=Stock_ID AND Solution_ID in (".join(',',@{$solution_list}).") AND Stock_Catalog_Name='Custom Oligo Plate'");
	    unless (@custom_sol_ids && (scalar(@custom_sol_ids) == 1)) {
		print "ERROR: ".scalar(@custom_sol_ids)." solution ids found for custom oligo plate\n";
		return undef;
	    }
	    my ($sol_id) = @custom_sol_ids;
	    ### rebuild join and condition string
	    ## since this does not depend on a rearray, there is a limit on what can be queried
	    ## can only query primer, target_plate, or sample information - no rearray information
	    my @alt_temp_field_array = split ',',$fields;
	    @field_array = ();
	    foreach my $field (@alt_temp_field_array) {
		if (defined $Aliases{alt_Rearray}{$field}) {
		    push (@field_array,"$Aliases{alt_Rearray}{$field} as $field");
		}
		else {
		    print "ERROR: field $field not defined\n";
		    return undef;
		}
	    }
	    # build the search condition dynamically
	    my @alt_condition_array = split ',',$conditions;
	    $condition_string = "";
	    $additional_joins = "";
	    foreach my $condition (@alt_condition_array) {
		$condition =~ /(.+)(<|=|>)(.+)/;
		my $condition_field = $1;
		my $condition_value = $3;
		my $comparator = $2;
		if (defined $Aliases{alt_Rearray}{$condition_field}) {
		    $condition_string .= " $Aliases{alt_Rearray}{$condition_field} $comparator '$condition_value' AND ";
		}
		else {
		    print "ERROR: field $condition_field not defined\n";
		    return undef;
		}
	    }
	    if ($hash_key) {
		unless (defined($Aliases{alt_Rearray}{$hash_key})) {
		    print "ERROR: field $hash_key not defined\n";
		    return undef;
		}
	    }
	    $additional_joins .= " Plate ";
	    if ( (scalar(grep(/Sample/i,@field_array)) > 0) || ($condition_string =~ /Sample/i) ) {
		$additional_joins .= " left join Plate_Sample on Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID left join Sample on Plate_Sample.FK_Sample__ID=Sample_ID ";
		$condition_string .= " Plate_Sample.Well=Primer_Plate_Well.Well AND ";
	    }
	    elsif ( (scalar(grep(/Plate_Sample/i,@field_array)) > 0) || ($condition_string =~ /Plate_Sample/i) ) {
		$additional_joins .= " left join Plate_Sample on Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID ";
		$condition_string .= " Plate_Sample.Well=Primer_Plate_Well.Well AND ";
	    }
	    $additional_joins .= " ,Primer_Plate inner join Primer_Plate_Well on FK_Primer_Plate__ID=Primer_Plate_ID left join Primer on Primer_Plate_Well.FK_Primer__Name=Primer_Name left join Primer_Customization on Primer_Customization.FK_Primer__Name=Primer_Name ";
	    $condition_string .= " Primer_Plate.FK_Solution__ID=$sol_id AND ";
	    $reset_join = 1;
	}

    }

    $condition_string .= " 1";
    my $format = "";
    if ($hash_key) {
	$format = "HofH";
    }
    else {
	$format = "HofA";
    }

    my $basic_join = " ReArray_Request inner join ReArray on FK_ReArray_Request__ID=ReArray_Request_ID ";
    if ($reset_join) {
	$basic_join = "";
    }

#    print "SELECT DISTINCT ".join(',',@field_array)." FROM $basic_join $additional_joins WHERE $condition_string";
    my $sth = $self->query(-query=>"SELECT DISTINCT ".join(',',@field_array)." FROM $basic_join $additional_joins WHERE $condition_string",-finish=>0);
    my $data = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>$format,-keyfield=>$hash_key);

    return $self->api_output(-data=>$data,-start=>$start,-log=>1,-customized_output=>1);
}

###############################################################
# Function to order a custom oligo plate (wrapper)
# Expanded mode is for Amplicon primer ordering.
# Standard mode is for normal custom primer orders.
# Refer to order_primer_plate for format details.
#
# Provided for backward compatibility. Use order_primer_plate instead.
#
# <snip>
# Example: 
# Standard:
# my $result = $API->order_custom_oligo_plate(
#	     -emp_name=>'rmorin',
#             -notify_list=>'mhirst@bcgsc.ca',
#             -format=>'Standard',
#             -files=>"order1.csv,order2.csv,
#             -notes=>"for mgc liver oligos"
#	);
# Expanded:
# my $result = $API->order_custom_oligo_plate(
#	     -emp_name=>'rmorin',
#             -notify_list=>'mhirst@bcgsc.ca',
#             -format=>'Expanded',
#             -amplicon_files=>"order1.csv,order2.csv,
#             -notes=>"for mgc liver amplicons",
#             -allow_wobbles=>1
#	);
#
# </snip>
#
# Return: 1 on success, 0 on failure.
##############################################################
sub order_custom_oligo_plate {
##########################
    my $self = shift;
    my %args = @_;
    my $format = $args{-format} || 'Standard';

    if ($format =~ /^Standard$/i) {
	$args{-format} = 'Standard';
	return $self->order_primer_plate(%args);
    }
    else {
	# get arguments for expanded primer plates
	my $amplicon_files = $args{-amplicon_files};
	my $emp_name = $args{-emp_name};
	my $notify_list = $args{-notify_list};
	my $format = $args{-format};
	my $notes = $args{-notes};
	my $allow_wobbles = $args{-allow_wobbles};
	my $group = $args{-group};
	# order primer plate
	return $self->order_primer_plate(-format=>"Expanded",-allow_wobbles=>$allow_wobbles,-files=>$amplicon_files,-notify_list=>$notify_list,-emp_name=>$emp_name,-notes=>$notes,-group=>$group);	
    }
}

###############################################################
# Function to order a custom oligo plate
#
# Expanded mode is for Amplicon primer ordering.
# Expanded format: <WELL>,<PRIMERNAME>,<SEQUENCE>,[A]mplicon or [S]tandard,[F]orward or [R]everse,<MELTINGTM>,[<AMPLICON LENGTH>]
# Standard mode is for normal custom primer orders.
# Standard format: <WELL>,<PRIMERNAME>,<SEQUENCE>,[<MELTINGTM>]
#
# <snip>
# Example: 
# Standard:
# my $result = $API->order_primer_plate(
#	     -emp_name=>'rmorin',
#             -notify_list=>'mhirst@bcgsc.ca',
#             -format=>'Standard',
#             -files=>"order1.csv,order2.csv,
#             -notes=>"for mgc liver oligos"
#	);
# Expanded:
# my $result = $API->order_primer_plate(
#	     -emp_name=>'rmorin',
#             -notify_list=>'mhirst@bcgsc.ca',
#             -format=>'Expanded',
#             -files=>"order1.csv,order2.csv,
#             -notes=>"for mgc liver amplicons",
#             -allow_wobbles=>1
#	);
#
# </snip>
#
# RETURN: 1 if successful, 0 otherwise
##############################################################
sub order_primer_plate {
####################
    my $self = shift;
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc           = $args{-dbc} || $self->dbc();     
    my $emp_name      = $args{-emp_name};                # (Scalar) The unix username of the user
    my $group         = $args{-group};                   # (Scalar) Group that is interested in the primers
    my $notify_list   = $args{-notify_list};             # (Scalar) Optional: A comma-delimited list of emails to be informed of status changes
    my $format        = $args{-format} || 'Standard';    # (Scalar) Optional: File format type. One of Standard or Expanded
    my $files         = $args{-files};                   # (Scalar) file name of the primer order, in the format <Well>,<Primer_Name>,<Primer_Sequence>
    my $notes         = $args{-notes};                   # (Scalar) notes to be annotated to all plates
    my $allow_wobbles = $args{-allow_wobbles};           # (Scalar) Allow wildcard primer names.
    my $no_message	 = $args{-no_message};

    unless ($emp_name) {
       print "ERROR: Missing parameter: -emp_name needs to be defined\n";
       return 0;
    }
    unless ($group) {
       print "ERROR: Missing parameter: -group needs to be defined\n";
       return 0;
    }
    # declare array of arrays for primer info
    my @well_array = ();
    my @name_array = ();
    my @sequence_array = ();
    my @tm_array = ();
    my @direction_array = ();
    my @amplicon_length_array = ();
    my @calculate_flag_array = ();
    my @primer_type_array = ();
    my @position_array = ();
    my @adapter_index_sequence_array = ();
    my @ppw_notes_array = ();  # Notes for primer plate wells
    my @alternate_primer_identifiers_array = ();

    # split the file list
    my @file_array = split ',',$files;
    my $primer_obj = new alDente::Primer(-dbc=>$self);
    foreach my $file (@file_array) {
       unless ($file) {
          print "ERROR: Missing parameter: -file needs to be defined\n";
          return 0;
       }
       if (!(-e $file)) {
          print "ERROR: Invalid parameter: $file does not exist\n";
          return 0;
       }
       if (!(-r $file)) {
          print "ERROR: Invalid parameter: $file is not readable\n";
          return 0;
       }

       my $INF;
       open($INF,$file);
       my $linecount = 1;
       my $type = 'Oligo'; # assume this is an oligo order plate unless otherwise
       # declare arrays for wells, primer names, primer sequences, and temperatures
       my @wells = ();
       my @primer_names = ();
       my @primer_sequences = ();
       my @primer_tms = ();
       my @direction = ();
       my @types = ();
       my @amplicon_lengths = ();
       my @position = ();
       my @adapter_index_sequences = ();
       my $calculate_tms = 0;
       my @ppw_notes = (); 
       my @alternate_primer_identifiers = ();

       while (<$INF>) {
          $_ = chomp_edge_whitespace($_);
          my $line = $_;
          my @elements = split ',',$_;
          # parse files differently if $format is Expanded
          if ($format eq "Expanded") {
             if ( (scalar(@elements) != 6) && (scalar(@elements) != 7) && (scalar(@elements) != 8) && (scalar(@elements) != 9) && (scalar(@elements) != 10)){
                print "ERROR: Invalid element count at line $linecount ($file): $_\n";
                return 0;
             }
             # different regexes if allow_wobbles is on
             if (!($allow_wobbles)) {
                unless ($line =~ /^\s*\w{1}\d{2}\s*,\s*\S+\s*,\s*[NATCGnatcg:]+\s*,\s*[ASDP]\s*,\s*[FRfrUuOoNn]\s*,\s*[\d\-.]+\s*(?:,\s*\d+\s*)?(?:,\s*[NATCG]+\s*)?.+$/) {
                   print "ERROR: Invalid line at line $linecount ($file): $_ (Allow wobbles off)\n";
                   return 0;
                }
             }
             else {
                unless ($line =~ /^\s*\w{1}\d{2}\s*,\s*\S+\s*,\s*[RYWSMKHBVDrywsmkhbvdNATCGnatcg]+\s*,\s*[ASas]\s*,\s*[FRfrUuOoNn]\s*,\s*[\d\-.]+\s*(?:,\s*\d+\s*)?.+$/) {
                   print "ERROR: Invalid line at line $linecount ($file): $_ (Allow wobbles ON)\n";
                   return 0;
                }
             }

             foreach (@elements) {
                $_ = &chomp_edge_whitespace($_);
             }

             # everything is correct, put in array
             $elements[0] = &format_well($elements[0]);
             push (@wells, $elements[0]);
             # do a primer check
             $primer_obj->value('Primer_Name',$elements[1]);    
             my $name_count = $primer_obj->exist();	    
             if ( $name_count > 0 ) {
                print "ERROR: Integrity problem: Primer Name $elements[1] already exists in database";
                return 0;
             }

             push (@primer_names, $elements[1]);
             push (@primer_sequences, $elements[2]);
             push (@types, $elements[3]);

             if ($elements[4] =~ /[Ff5]/) {
                push (@direction, 'Forward');
             }
             elsif ($elements[4] =~ /[Rr3]/) {
                push (@direction, 'Reverse');
             }
             else {
                push (@direction, 'Unknown');
                if ($elements[4] =~ /^[Nn]/) {
                   push (@position, 'Nested');
                }
                elsif ($elements[4] =~ /^[Oo]/) {
                   push (@position, 'Outer');
                }
                else {
                   push (@position, 'NULL');
                }
             }
             if ( (defined $elements[5]) && ($elements[5] =~ /[\d\-.]/) ) {
                push (@primer_tms, $elements[5]);   
             }
             else {
                $calculate_tms = 1;
                push (@primer_tms, '');
             }
             if (defined($elements[6])) {
                push (@amplicon_lengths,$elements[6]);
             }
             else {
                push (@amplicon_lengths,0);
             }
             if (defined($elements[7])) {
                push (@adapter_index_sequences,$elements[7]);
             }
             else {
                push (@adapter_index_sequences,'');
             }
             
             if (defined($elements[8])) {
                push (@ppw_notes,$elements[8]);
             }
             else {
                push (@ppw_notes,'');
             }

             if (defined($elements[9])) {
                push (@alternate_primer_identifiers,$elements[9]);
             }
             else {
                push (@alternate_primer_identifiers,'');
             }
             
          }
          else {
             if ( (scalar(@elements) != 3) && (scalar(@elements) != 4)) {
                print "ERROR: Invalid line at line $linecount ($file): $_\n";
                return 0;
             }
             unless (/^\w{1}\d{2},\s*\S+\s*,[ATCGatcg]+(?:,[\d\-.]+)?$/) {
                print "ERROR: Invalid line at line $linecount ($file): $_\n";
                return 0;
             }

             # everything is correct, put in array
             $elements[0] = &format_well($elements[0]);
             push (@wells, $elements[0]);
             # do a primer check
             $primer_obj->value('Primer_Name',$elements[1]);    
             my $name_count = $primer_obj->exist();	    
             if ( $name_count > 0 ) {
                print "ERROR: Integrity problem: Primer Name $elements[1] already exists in database\n";
                return 0;
             }

             push (@primer_names, $elements[1]);
             push (@primer_sequences, $elements[2]);
             if (scalar(@elements) == 4) {
                push (@primer_tms, $elements[3]);
             }
             else {
                $calculate_tms = 1;
                push (@primer_tms, '');
             }
             push (@amplicon_lengths,0);
             push (@position, 'NULL');
             push (@types, 'S');
             push (@direction, 'Unknown');
          }

          $linecount++;
       }
       close($INF);
       # check to see if there are 96 or less primers, otherwise fail
       if (scalar(@primer_tms) > 96) {
          #print "ERROR: Too many primers - can only order 96 at a time\n";
          #return 0;
       }

       foreach (@types) {
          # expand the type name
          if ($_ eq 'A') {
             $_ = 'Amplicon';
          }
          if ($_ eq 'S') {
             $_ = 'Oligo';
          }
          if ($_ eq 'D') {
             $_ = 'Adapter';
          }
          if ($_ eq 'P') {
             $_ = 'Spike-In';
          }

       }

       push (@well_array,\@wells);
       push (@name_array,\@primer_names);
       push (@sequence_array,\@primer_sequences);
       push (@tm_array,\@primer_tms);
       push (@calculate_flag_array,$calculate_tms);
       push (@primer_type_array, \@types);
       push (@direction_array,\@direction);
       push (@amplicon_length_array,\@amplicon_lengths);
       push (@position_array, \@position);
       push (@adapter_index_sequence_array, \@adapter_index_sequences);
       push (@ppw_notes_array, \@ppw_notes);
       push (@alternate_primer_identifiers_array, \@alternate_primer_identifiers);
    }
    #print Dumper "well", \@well_array, "name", \@name_array, "seq", \@sequence_array, "tm", \@tm_array, "cf", \@calculate_flag_array, "type", \@primer_type_array, "dir", \@direction_array, "AL", \@amplicon_length_array, "pos", \@position_array, "AIS", \@adapter_index_sequence_array;
    my @primer_plate_ids = ();
    #my $rearray_object = new Sequencing::ReArray(-dbc=>$dbc);
    require alDente::Primer_Plate;
    my $rearray_object = new alDente::Primer_Plate(-dbc=>$self);
    # call ordering function, once for each file
    foreach (1..scalar(@well_array)) {
       my @wells = @{$well_array[$_-1]};
       my @primer_names = @{$name_array[$_-1]};
       my @primer_sequences = @{$sequence_array[$_-1]};
       my @primer_tms = @{$tm_array[$_-1]};
       my @direction = @{$direction_array[$_-1]};
       my @position = @{$position_array[$_-1]};	
       my $calculate_tms = $calculate_flag_array[$_-1];
       my @type = @{$primer_type_array[$_-1]};
       my $amplicon_lengths = $amplicon_length_array[$_-1];
       my @adapter_index_sequences = @{$adapter_index_sequence_array[$_-1]};
       my @well_notes = @{$ppw_notes_array[$_-1]};
       my @alternate_primer_identifiers = @{$alternate_primer_identifiers_array[$_-1]};

       my $rethash = undef;
       if ($calculate_tms) {
          $rethash = $rearray_object->order_primers(-emp_name=>$emp_name,-wells=>\@wells,-name=>\@primer_names,-sequence=>\@primer_sequences,-tm_calc=>'MGC Standard' ,-primer_type=>\@type,-direction=>\@direction,-position=>\@position,-amplicon_lengths=>$amplicon_lengths,-notes=>$notes,-notify_list=>$notify_list,-adapter_index_seq=>\@adapter_index_sequences,-well_notes =>  \@well_notes, -alternate_primer_identifiers => \@alternate_primer_identifiers);
       }
       else {
          $rethash = $rearray_object->order_primers(-emp_name=>$emp_name,-wells=>\@wells,-name=>\@primer_names,-sequence=>\@primer_sequences,-tm_working=>\@primer_tms,-primer_type=>\@type,-direction=>\@direction,-position=>\@position,-amplicon_lengths=>$amplicon_lengths,-notes=>$notes,-notify_list=>$notify_list,-adapter_index_seq=>\@adapter_index_sequences,-well_notes =>  \@well_notes, -alternate_primer_identifiers => \@alternate_primer_identifiers);
       }
       if (defined $rethash) {
          push (@primer_plate_ids,$rethash->{'primer_plate_id'});
       }
    }

    unless ($rearray_object->success()) {
       return 0;
    }

    if( !$no_message ) {
       # get the group associated with this order
       my @group_ids = $self->Table_find("Grp","Grp_ID","WHERE Grp_Name like '%$group%'");
       $rearray_object->send_primer_order(-group=>join(',',@group_ids),-emp_name=>$emp_name,-notify_list=>$notify_list,-primer_plate_range=>join(',',@primer_plate_ids));
    }

    return $rearray_object->success();
}

###############################################################
# Function to create a remapped primer plate from received 
# primer plates
#
# file format: <primer plate id>,<source well>,<target_well>
# 
# <snip>
#
# my $result = $API->create_remapped_primer_plate(
#                   -emp_name=>'jsantos',
#                   -files=>'remap.1.txt,remap.2.txt',
#                   -notes=>'remap for liver_2'
#                   );
#
# </snip>
# RETURN: an arrayref to the solution IDs of the remapped plate, or undef if error found
###############################################################
sub create_remapped_primer_plate {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc = $args{-dbc} || $self->dbc();
    
    my $notes = $args{-notes}; # (Scalar) A short note identifying the remapped primer plate
    my $emp_name = $args{-emp_name}; # (Scalar) The name of the user creating the remapped plate
    my $files = $args{-files}; # (Scalar) Comma-delimited list of data files
    my $start = timestamp();

    # check if the files exist and are readable
    my @file_array = split(',',$files);
    foreach my $file (@file_array) {
	unless ( (-e $file) && (-r $file) ) {
	    print "ERROR: Invalid Parameter: $file does not exist or cannot be read";
	    return undef;
	}  
    }

    my @new_sol_ids = ();
    foreach my $file (@file_array) {
	# parse each file in turn
	my $INF;
	open($INF,$file);
	my @lines = <$INF>;
	close($INF);
	my @source_plates = ();
	my @source_wells = ();
	my @target_wells = ();
	my $linecount = 1;
	foreach my $line (@lines) {
	    $line = chomp_edge_whitespace($line);
	    my @elements = split ',',$line;
	    if ( scalar(@elements) != 3 ){
		print "ERROR: Invalid element count at line $linecount ($file): $line\n";
		return undef;
	    }
	    # error check each line 
	    unless ($line =~ /^\s*\d+\s*,\s*\w{1}\d{2}\s*,\s*\w{1}\d{2}\s*$/) {
		print "ERROR: Invalid line at line $linecount ($file): [$line] \n";
		return undef;
	    }	    
	    push (@source_plates,&chomp_edge_whitespace($elements[0]));
	    push (@source_wells,&chomp_edge_whitespace($elements[1]));
	    push (@target_wells,&chomp_edge_whitespace($elements[2]));
	}
    print Dumper \@source_plates, \@source_wells, \@target_wells; 
	my $po = new alDente::Primer(-dbc=>$dbc);
	my $retval = $po->remap_primer_plate(-emp_name=>$emp_name,-notes=>$notes,-source_plates=>\@source_plates,-source_wells=>\@source_wells,-target_wells=>\@target_wells);
    print Dumper $po;	
unless ($po->success()) {
	    return undef;
	}
	push (@new_sol_ids, $retval);
    }
    return $self->api_output(-data=>\@new_sol_ids,-start=>$start,-log=>1,-customized_output=>1);
}

###############################################################
# Low-level function that creates a rearray. 
# This function is used to create rearrays that cannot be done with create_oligo_rearray()
# or create_clone_rearray().
#
# <snip>
#
# my $result = $API->create_rearray(
#                  -source_plates=>[3999,3999,3999,3999,4000],
#                  -source_wells=>['A01','A02','A03','A04','A01'],
#                  -target_wells=>['A01','A02','A03','A04','A05'],
#                  -create_plate=>1,
#                  -target_size=>384,
#                  -emp_name=>'rwarren',
#                  -type=>'Clone',   
#                  -rearray_comments=>'sample hardstop rearray'
#             );             
#
# </snip>
# RETURN: the ids (as a comma-delimited list) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub create_rearray {
##################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $dbc = $args{-dbc} || $self->dbc();   

    my $source_plates_list = $args{-source_plates_list}; if ($source_plates_list) { my @tmp = split(",", $source_plates_list); $args{-source_plates} = \@tmp; }
    my $source_wells_list = $args{-source_wells_list}; if ($source_wells_list) { my @tmp = split(",", $source_wells_list); $args{-source_wells} = \@tmp; }
    my $target_wells_list = $args{-target_wells_list}; if ($target_wells_list) { my @tmp = split(",", $target_wells_list); $args{-target_wells} = \@tmp; }
    my $source_plates_ref = $args{-source_plates}; # (ArrayRef) (source plates for source wells in format (1,2,1,1,1,1,2.....). This must correspond to source wells. Not required if -status is "Pre-Rearray"
    my $source_wells_ref = $args{-source_wells};   # (ArrayRef) source wells for ReArray in format (A01,B01,B02,B03.....). This must correspond to target wells and source plates.
    my $target_wells_ref = $args{-target_wells};   # (ArrayRef) target wells for ReArray in format (A01,B02,B01,E03.....). This must correspond to source wells.
    my $target_plate = $args{-target_plate};       # (Scalar) the target plate of the rearray   
    $args{-target_plate_id} = $target_plate;
    my $primer_names_ref = $args{-primer_names}; # (ArrayRef) primer names associated with the target wells. 
    my $emp_name = $args{-emp_name};               # (Scalar) employee ID of new ReArray creator.
    my $type = $args{-type}; 
    $args{-request_type} = $type;
    # (Scalar) Rearray type, whether it is a Clone Rearray or Reaction Rearray rearray.
    my $status = $args{-status};                   # (Scalar) Status of the rearray, one of 'Waiting for Primers','Waiting for Preps','Ready for Application','Barcoded','Completed'
    my $target_format_size = $args{-target_size};       # (Scalar) format size of target plate. Should be 96 or 384.
    my $notify_list = $args{-notify_list};         # (Scalar) Comma-delimited list of emails to be notified of events other than the owner of the rearray.
    my $create_plate = $args{-create_plate};       # (Scalar) flag that tells the subroutine to create target plates (by calling those functions in create_rearray)
    my $plate_comments = $args{-rearray_comments};   # (Scalar) Required: comments for the target plate
    my $no_lab_request = $args{-no_lab_request};   # A flag to not create Lab_Request
    my $update_sample  = $args{-update_sample};
    

    # if -file was defined, read and input file
    my $file = $args{-file};
    if ($file) {
	unless ( (-e $file) && (-r $file) ) {

	}
    }
    my $rearray_object = new Sequencing::ReArray(-dbc=>$self);
    # check if primer details are defined if the type is a Reaction Rearray
    if ($type =~ /Reaction Rearray/) {
	unless ($primer_names_ref) { $rearray_object->error("ERROR: Missing Parameter: Primer Names not specified"); }
	unless (scalar(@{$source_wells_ref}) == scalar(@{$primer_names_ref})) {
	    $rearray_object->error("ERROR: Size Mismatch: -source_wells array does not match -primer_names array");
	}
	foreach my $id (@{$primer_names_ref}) {
	    my @retval = $self->Table_find("Primer","count(*)","WHERE Primer_Name='$id'");
	    if (scalar(@retval) == 0) {
		$rearray_object->error("ERROR: Integrity problem: Primer $id does not exist in the database");	
	    }
	}
    }
    my ($rearray_id,$plate_id) = $rearray_object->create_sequencing_rearray(%args);
    if (!($rearray_object->success())) {
        return 0;
    }
    else {
	if (!$no_lab_request) {
	    #print "\n******* SUCCESS ******\n";
	    #print "$rearray_id\n";
	    ## add to a Lab_Request
	    # create a Lab_Request entry
	    my ($emp_id) = $self->Table_find("Employee","Employee_ID","WHERE Email_Address='$emp_name'");
	    my $insert_id = $self->Table_append_array("Lab_Request",['FK_Employee__ID','Request_Date'],[$emp_id,&date_time()],-autoquote=>1);
	    $self->Table_update_array("ReArray_Request",['FK_Lab_Request__ID'],["$insert_id"],"WHERE ReArray_Request_ID in ($rearray_id)");
	}
	if ($update_sample) {
	    $rearray_object->update_plate_sample_from_rearray( -request_id => $rearray_id, -auto_check=>1 );
            &alDente::ReArray::auto_assign(-dbc=>$dbc,-plate=>$plate_id,-requested=>$rearray_id);
	}
    }

    return $self->api_output(-data=>$rearray_id,-start=>$start,-log=>1,-customized_output=>1);

}

###############################################################
# Creates reprep rearrays from files or a data string
#
# This creates a rearray for reprepping.
#
# Format: <SOURCEPLATE>,<SOURCEWELL>,<TARGETWELL>
#
# <snip>
#
# my $rearray_ids = $API->create_reprep_rearray(
#			-target_library=>'LX888',
#			-emp_name=>'echang',
#			-file=>"ReClone.561",
#			-target_size=>384
#			);
#
# </snip>
# 
# RETURN: the ids (as a comma-delimited list) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub create_reprep_rearray {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc = $args{-dbc} || $self->dbc();
    my $start = timestamp();

    my $emp_name = $args{-emp_name};   # (Scalar) Unix userid of the person doing the rearray
    my $data = $args{-data};           # (Scalar) data for the reprep rearray. Contains the same information as the reprep file. Takes priority over -file.
    my $file = $args{-file};      # (Scalar) filename of the reprep file. The path should be fully qualified (eg /home/jsantos/csv). Superseded by -data.
    my $target_library = $args{-target_library}; # (Scalar) identifies the library that the new plates will be part of
    my $plate_application = $args{-plate_application} || "Sequencing"; # (Scalar) identifies the application that the new plates will be used for. 
    my $plate_size = $args{-target_size}; # (Scalar) the size of the target plate. Can be 96-well or 384-well.
    my $notify_list = $args{-notify_list}; # (Scalar) Comma-delimited list of emails that need to be notified of events on this rearray
    my $suppress_email = $args{-suppress_email}; # (Scalar) Suppress the emails sent when ordering (for testing)
    my $plate_comments = $args{-plate_comments}; # (Scalar) comments to be added to the target plate
    my $rearray_comments = $args{-rearray_comments}; # (Scalar) comments regarding the rearray

    my $rearray_object = new Sequencing::ReArray(-dbc=>$dbc);
    my $rearray_ids = $rearray_object->create_reprep_rearray(%args);
    
    if ($rearray_object->error()) {
	return 0;
    }
    else {
        return $self->api_output(-data=>$rearray_ids,-start=>$start,-log=>1,-customized_output=>1);
    }

}

###############################################################
# Creates oligo rearrays from files or a data string, and orders primers for these rearrays
# 
# RETURN: the ids (as a comma-delimited list) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub create_oligo_rearray {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my $start = timestamp();

    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
#    my %args = @_;
#    my $dbc = $args{-dbc};
    my $emp_name = $args{-emp_name}; # (Scalar) The unix userid of the employee making the rearray
    my $file_list = $args{-files}; # (Scalar) The fully-qualified filenames of the source files
    my $oligo_direction = $args{-direction}; # (Scalar) The direction of the primers. One of 5 or 3.
    my $target_library = $args{-target_library}; # (Scalar) The library of the plate to be created
    my $omit_primers = $args{-omit_primer_order}; # (Scalar) Flag that tells the function not to write primers to the primer table. This will assume that the Order Numbers are already in the database, so the Rearray will be set to "Reserved" instead of "On Order"
    ## OPTIONAL FIELDS
    my $notify_list = $args{-notify_list} || ''; # (Scalar) a comma-delimited string of emails who will be informed when the primer plate has been provided with an external order number. 
    my $data = $args{-data}; # (Scalar) An input string with information formatted exactly like the input file. Overrides the -files tag.
    my $plate_comments = $args{-rearray_comments};   # (Scalar) Optional: comments for the target plate

    my $dbc = $self->dbc();

#    if (my $errors = &check_input_errors(\%args,-log=>$self->{log_file})) { Message("Input Errors Found: $errors"); return; }

    my $rearray_object = new Sequencing::ReArray(-dbc=>$dbc);
    

    my $rearray_ids = $rearray_object->order_oligo_rearray_from_file(%args);
    
    if ($rearray_object->error()) {
        print $rearray_object->error();
        print "\n";
        return $self->api_output(-data=>0,-start=>$start,-log=>1,-customized_output=>1);
    }
    else {
        return $self->api_output(-data=>"$rearray_ids",-start=>$start,-log=>1,-customized_output=>1);
    }
    
}

###############################################################
# Creates a 384-well clone rearray (and optionally primer rearrays from that rearray) from the clones defined
# 
# This function can create 4 96-well or 1 384-well transfer rearrays per 384-well clone rearray
# Format: <CLONENAME>,[<SEQUENCE>,<MELTINGTM>]
# 
# <snip>
#
# my $rearray_ids = $API->create_clone_rearray
#    (  
#     -target_library=>'CZ000',
#     -emp_name=>'gtaylor',
#     -plate_application=>'Sequencing',
#     -clonefile=>"clone_chosenHard-StopB.txt",
#     -create_384_transfer=>1,
#     -original=>1,
#     -oligo_direction=>5,
#     -supplies_tag=>\%supplies_tag
#     );
#
# </snip>
# 
# RETURN: the ids (comma_delimited) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub create_clone_rearray {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $start = timestamp();
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $emp_name = $args{-emp_name};   # (Scalar) Required: Unix userid of the person doing the rearray
    my $data = $args{-data};           # (Scalar) Required: data for the qpix rearray. Contains the same information as the clone file. Takes priority over -clonefile.
    my $clonefile = $args{-clonefile}; # (Scalar) Required: filename of the clone file. The path should be fully qualified (eg /home/jsantos/csv). Superseded by -data.
    my $target_library = $args{-target_library}; # (Scalar) Required: identifies the library that the new plates will be part of
    my $target_oligo_library = $args{-target_oligo_library}; # (Scalar) Required if has transfer: identifies the library that the new oligo plates will be part of (if applicable).
    my $plate_application = $args{-plate_application}; # (Scalar) Required: identifies the application that the new plates will be used for. 
    my $clone_rearray_comments = $args{-clone_rearray_comments}; # (Scalar) Required: comments for the clone rearray
    my $oligo_rearray_comments = $args{-oligo_rearray_comments}; # (Scalar) Required: comments for the 4 oligo rearray

    my $prerearray = $args{-create_96_transfer}; # (Scalar) flag that determines whether or not to create 4 96-well oligo rearrays for each qpix rearray (in the form of Reserved rearray plates). Primers will also be assigned to the oligo rearrays
    my $prerearray_384 = $args{-create_384_transfer}; # (Scalar) flag that determines whether or not to create 1 384-well oligo rearrays for each qpix rearray (in the form of Reserved rearray plates). Primers will also be assigned to the oligo rearrays
    my $omit_primer_order = 0;
    my $oligo_direction = $args{-oligo_direction}; # (Scalar) the oligo direction

    my $format = $args{-format};     # (Scalar) determines which plate format to search for, and picks the latest plate with that format. For example, -format=>'Glycerol' will grab the latest glycerol plate with that Library_Name.Plate_Number combination.
    my $original = $args{-original}; # (Scalar) flag that determines whether or not to grab the earliest ORIGINAL plates. This should be the typical behaviour.
    my $notify_list_primer_order = $args{-notify_list_primer_order} || ''; # (Scalar) a comma-delimited string of emails who will be informed when the primer plate (the second step) has been provided with an external order number. 
    my $force_invalid_plates = $args{-force_invalid_plates}; # (Scalar) flag that determines whether or not to allow plates that have been exported, garbaged, or are not active
    my $duplicate_wells = $args{-duplicate_wells} || 0; # (Scalar) determines if wells can be double-dipped

    my $dbc = $self->dbc();

    my $rearray_object = new Sequencing::ReArray(-dbc=>$dbc);

    my $rearray_ids = $rearray_object->create_clone_rearray(%args);
    
    if ($rearray_object->error()) {
	return 0;
    }
    else {
    return $self->api_output(-data=>"$rearray_ids",-start=>$start,-log=>1,-customized_output=>1);
    }
}

###############################################################
# Searches for the plate ids associated with a clone file
#
# <snip>
#
# my $plates = $API->search_clone_plates(
#                   -emp_name=>'dianap',
#                   -clonefile=>'clones1.csv'
#                    );
#
# </snip>
#
# Return: an arrayref of the plate ids
###############################################################
sub search_clone_plates {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $start = timestamp();

    ### MANDATORY FIELDS ###
    my $emp_name = $args{-emp_name};   # (Scalar) Unix userid of the person doing the rearray
    my $data = $args{-data};           # (Scalar) data for the qpix rearray. Contains the same information as the clone file. Takes priority over -clonefile.
    my $clonefile = $args{-clonefile}; # (Scalar) filename of the clone file. The path should be fully qualified (eg /home/jsantos/csv). Superseded by -data.

    
    my $format = $args{-format};     # (Scalar) determines which plate format to search for, and picks the latest plate with that format. For example, -format=>'Glycerol' will grab the latest glycerol plate with that Library_Name.Plate_Number combination.
    my $original = $args{-original}; # (Scalar) flag that determines whether or not to grab the earliest ORIGINAL plates. This should be the typical behaviour.
    my $force_invalid_plates = $args{-force_invalid_plates}; # (Scalar) flag that determines whether or not to allow plates that have been exported, garbaged, or are not active

    my $dbc = $self->dbc();

    my $rearray_object = new Sequencing::ReArray(-dbc=>$dbc);
    my $plate_ids = $rearray_object->search_clone_plates(%args);
    
    if ($rearray_object->error()) {
	print $rearray_object->error();
	print "\n";
	return undef;
    }
    else {
    return $self->api_output(-data=>$plate_ids,-start=>$start,-log=>1,-customized_output=>1);
    }
}



####################
#
# New method to simplify run data extraction (avoids complexity of _generate_query method) 
# (this style should replace all of the other API methods as well to simplify maintenance / debugging.
#
# Return: hash of data 
#########################################################################
#
# Extract Read information by run/library/project/study
#
# To see list of possible fields, run using the -list_fields option
#  (returns hash of Field_Name,Table,Description for each field  as well as a list of Aliases that may be used).
#
# Numerous aliases exist to enable data mining without knowing actual database field names.
#
# <snip>
# Example: 
#   my @fields = ('trimmed_sequence','trimmed_scores','warning','run_id','Plate_ID','Well')
#   my %info = %{ $API->get_read_data(-fields=>\@fields,-library=>'MGC01',-include=>'production,approved') };
#   
#   ## or simply return all default information... (if field list omitted)..
#   my %info = %{ $API->get_read_data(-study=>5,-include=>'production,approved') }; 
# </snip>
#
# Return a hash containing values (keys = fields; values = array of values returned);
#######################
sub get_read_data {
#######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    ## read specific input ##
    my $fields = $args{-fields};
    my $add_fields = $args{-add_fields};
    my $group = $args{-group} || $args{-group_by} || $args{-key} || ['run_name','sequenced_well'];
    my $KEY   = $args{-key};# || ['run_name','sequenced_well'];
    my $well         = $args{-well};
    my $alias_name        = $args{-alias};
    my $alias_type   = $args{-alias_type};
    my $mgc_number   = $args{-mgc_number};
    my $input_conditions = $args{-condition};
    my $input_joins      = $args{-input_joins} || {};   ## specific join table conditions ... 
    my $debug            = $args{-debug};               ## just show SQL statement generated... 
    ## arguments passed on to get_run_data including: ##
    my $traces         = $args{-traces};
    
    ## Specify conditions for data retrieval
    my $study_id       = $args{-study_id};                        ### a study id (a defined set of libraries/projects)
    my $project_id     = $args{-project_id};                      ### specify project_id
    my $library        = $args{-library};                           ### specify library
    ## run specification options
    my $run_id       = $args{-run_id};                            ### specify run id
    my $run_name       = $args{-run_name};                        ### specify run name (must be exact format)
    my $exclude_run_id = $args{-exclude_run_id};                  ### specify run id to EXCLUDE (for Run or Read scope)
    ## plate specification options
    my $plate_id     = $args{-plate_id};                          ### specify plate_id
    my $plate_number = $args{-plate_number};                      ### specify plate number 
    my $plate_type = $args{-plate_type} || '';                    ### specify type of plate (tube or Library_Plate)
    my $plate_class = $args{-plate_class} || '';                  ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';      ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};            ### specify original plate id 
    my $original_well     = $args{-original_well};                ### specify original well
    my $applied_plate_id  = $args{-applied_plate_id};             ### specify original plate id (including ReArrays)
    my $quadrant     = $args{-quadrant};                          ### specify quadrant from original plate
    my $sample_id    = $args{-sample_id};                         ### specify sample_id 
    my $pipeline     = $args{-pipeline};                          ### exact name of pipeline to which plate (undergoing run) belongs
    my $branch       = $args{-branch};                            ### branch on which plate (undergoing run) belongs
    ## advanced options
    my $input_conditions = $args{-condition};                     ### optional specification of additional SQL condition
    my $library_type     = $args{-library_type};                  
    my $input_joins      = $args{-input_joins};                   
    my $input_left_joins = $args{-input_left_joins};
    ## Inclusion / Exclusion options
    my $since       = $args{-since};                              ### specify date to begin search (context dependent)
    my $until       = $args{-until};                              ### specify date to stop search (context dependent)
    my $date_field  = $args{-date_field} || 'Run_DateTime';       ### field to test based upon the since and until parameters

    my $include    = $args{-include} || 0;       ### data to include (production,approved,billable,pending,analyzed) - 'AND' joined.
    my $exclude    = $args{-exclude} || 0;                        ### OR specify data to exclude (eg. failed)    

    my $quiet = $args{-quiet};             ## suppress feedback    

    my $wells = Cast_List(-list=>$well,-to=>'string',-autoquote=>1) if $well;
    my $trace_names = Cast_List(-list=>$traces,-to=>'string',-autoquote=>0) if $traces;

    my @extra_conditions; @extra_conditions = Cast_List(-list=>$input_conditions,-to=>'array') if $input_conditions;

    ## default field list 
    my @field_list = ('machine','run_initiated_by','library','plate_number','Average_Q20','Average_Length','Total_Length','chemistry_code','vector','library_format','direction','sample_id','phred_version');  

    if ($wells) { push(@extra_conditions,"Clone_Sequence.Well IN ($wells)") }      
    if ($trace_names) { 
        ## separate this logic as it may slow down bulk query too much ##
        my @trace_conditions;
        foreach my $trace (split ',', $trace_names) {
            my ($rd,$well) = split '_', $trace;
            push @trace_conditions, "(Run_Directory = '$rd' AND Clone_Sequence.Well = '$well')" if ($rd && $well);
        }
        my $trace_condition = join ' OR ', @trace_conditions;
        my $reads = join ',', $self->Table_find('Clone_Sequence,Run','Clone_Sequence_ID',"WHERE FK_Run__ID=Run_ID AND ($trace_condition)");

        push(@extra_conditions,"Clone_Sequence.Clone_Sequence_ID IN ($reads)") if $reads;
        $args{-traces} = undef;  ## clear this argument 
        
        #    push(@extra_conditions,"$Aliases{Read}{trace_name} IN ($trace_names)");
    }

    if (($group || $KEY) && ($group !~/^(run_name|run_id)$/) && ($KEY !~/^(run_name|run_id)$/)) {    
        ## IF grouping runs by anything EXCEPT run ##
        push(@field_list,'primer','earliest_run','latest_run','first_plate_created','last_plate_created');
    } 
    else { 
        ## IF returning one record per run ##
        push(@field_list,('Plate_ID','sequencer','vector','primer','run_time','run_id','run_name','unused_wells','direction','plate_created','plate_class','library_format','parent_quadrant','plate_position','run_status','validation','sequenced_well','quality_length','sequence_length'));
    }

    if (($group =~/\b(sample_name|sample_id)\b/) || ($KEY =~/\b(sample_name|sample_id)\b/)) {   ## if grouped by sample with anything else...  
        ## IF grouping runs by anything EXCEPT sample ##
        push(@field_list,'sample_id','sample_name');
    } 
    else { 
    }

    if ($group || $KEY) { push(@field_list, 'Count(*) as count'); }
    foreach my $key (split ',', $KEY) {
        push(@field_list, $key) unless (grep /\b$key\b/, @field_list);   ## add to fields if not already... 
    }

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List(-list=>$fields,-to=>'array');
    } 
    elsif ($add_fields) {
        my @add_list = Cast_List(-list=>$add_fields,-to=>'array');
        push(@field_list,@add_list);
    }

    ## Special case for mgc_number ##    
    if ($mgc_number || ($KEY =~ /mgc_number/)) {
        #	my $list = Cast_List(-list=>$mgc_number,-to=>'string',-autoquote=>1);
        #	push(@$input_conditions,"Sample_Alias.Alias IN ($list)"); 
        $alias_name = $mgc_number if $mgc_number;
        $alias_type = "MGC";
        push(@field_list,'mgc_number');
        Message("ADD MGC_number..");
    } 

    if ($alias_name || $alias_type) {
        if ($alias_name) {
            my $alias = Cast_List(-list=>$alias_name,-to=>'string',-autoquote=>1);
            $input_joins->{Sample_Alias} = "Sample.Sample_ID=Sample_Alias.FK_Sample__ID AND Sample_Alias.Alias IN ($alias)";
        } 
        elsif ($alias_type) {
            $input_joins->{Sample_Alias} = "Sample.Sample_ID=Sample_Alias.FK_Sample__ID AND Sample_Alias.Alias_Type = '$alias_type'";
        }
        push(@field_list,'alias','alias_type');
    }

    $args{-fields} = \@field_list;
    $args{-group}  = $group;
    $args{-key}    = $KEY;
    $args{-condition}  = \@extra_conditions;
    $input_joins->{'Sample'} = 'Clone_Sequence.FK_Sample__ID = Sample.Sample_ID';
    $input_joins->{'Source'} = 'Sample.FK_Source__ID=Source_ID';
    $input_joins->{'Original_Source'} = 'Source.FK_Original_Source__ID=Original_Source_ID';
    $input_joins->{'Clone_Sample'} = 'Sample.Sample_ID = Clone_Sample.FK_Sample__ID',
    $input_joins->{'Clone_Source'} = "Clone_Source.FK_Clone_Sample__ID = Clone_Sample.Clone_Sample_ID",

    $args{-input_joins} = $input_joins;
    
    return $self->get_run_data(%args);
} 

###################
# Was this ever used... ?
# (this should be generic for experiment data, but add extra fields specific to GelRun information...
#
#########################
sub get_Gel_data {
#########################

## <CONSTRUCTION> - UNDER CONSTRUCTION 
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

#    $tables = "Clone_Gel";
#    if ((grep /GelRun/i, @fields)){
#	$tables .= " LEFT JOIN GelRun ON (GelRun_ID=FK_GelRun__ID)";
#    }
##
    my  $input_joins;
    $input_joins->{'GelRun'} = 'GelRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Lane'} = 'Lane.FK_GelRun__ID = GelRun.GelRun_ID';
    $input_joins->{'Band'} = 'Lane.Lane_ID = Band.FK_Lane__ID';

    $args{-input_joins} = $input_joins;

    return $self->get_run_data(%args);      ## access method in general
}

####################
#
# Extract read information specific to oligos
#
#
#################
sub get_oligo_data {
#################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields = $args{-fields};
    my $key = $args{-key};
    
    my @field_list = Cast_List(-list=>$fields,-to=>'array');
    push(@field_list,'oligo_primer','oligo_sequence','oligo_direction','primer_plate_well');
    
#    my $key = "concat(sample_id,'-',run_id) as SampleRun";
    
    $args{-add_fields} = \@field_list;
    
    ## Customize join, and left join specifications for oligos ##
    my $input_joins = {
	'Primer_Plate'   => "Run.FKPrimer_Solution__ID=Primer_Plate.FK_Solution__ID",
#	'Primer_Plate_Well' => "FK_Primer_Plate__ID=Primer_Plate.Primer_Plate_ID AND Primer_Plate_Well.Well=Clone_Sequence.Well",
#	'Primer'            => "Primer_Plate_Well.FK_Primer__Name=Primer.Primer_Name",	
#	'Primer_Plate_Well' => "Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID",
	'Primer' => "Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name",
	'Primer_Plate_Well' => "Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID AND Clone_Sequence.Well = Plate_PrimerPlateWell.Plate_Well",
	'Plate_PrimerPlateWell' => "Plate_PrimerPlateWell.FK_Plate__ID=Plate.FKOriginal_Plate__ID",
    };
    
    my $input_left_joins = {
	'Primer_Customization' => 'Primer_Customization.FK_Primer__Name=Primer.Primer_Name',
    };	
    
    $args{-input_joins} = $input_joins;
    $args{-input_left_joins} = $input_left_joins;
    $args{-key} = $key;

    return $self->get_read_data(%args);
}
    
#############################
sub get_concentration_data {
#############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields = $args{-fields};
    my $key = $args{-key};
    
    my @field_list = Cast_List(-list=>$fields,-to=>'array');
    push(@field_list,'concentration','concentration_datetime','concentration_plate','concentration_well','concentration_run','concentration_runs');
    
    $key ||= "Concentrations.Concentration_ID";
    
    $args{-add_fields} = \@field_list;
    
    ## Customize join, and left join specifications for oligos ##
    my $input_joins = {
    };
    
    my $input_left_joins = {
#	'Primer_Customization' => 'Primer_Customization.FK_Primer__Name=Primer_Name',
    };	
    
    $args{-input_joins} = $input_joins;
    $args{-input_left_joins} = $input_left_joins;
    $args{-key} = $key;

    return $self->get_sample_data(%args);
}

#########################################################################
# Deprecated method:  please use get_run_data()
# Extract Run information by run/library/project/study
#
# Numerous aliases exist to enable data mining without knowing actual database field names.
# (Scope of information contains Run info, Run summary info, Plate info, Library info)
#
# To see list of possible fields, run using the -list_fields option
#  (returns hash of Field_Name,Table,Description for each field  as well as a list of Aliases that may be used).
#
# <snip>
# Example: 
#   my @fields = ('trimmed_sequence','trimmed_scores','warning','run_id','Plate_ID','Well')
#   my %info = %{ $API->get_Run_data(-fields=>\@fields,-study=>5,-include=>'production,approved') };
#   
#   ## or simply return all default information... (if field list omitted)..
#   my %info = %{ $API->get_Run_data(-study=>5,-include=>'production,approved') }; 
# </snip>
#
# Return: hash containing values (keys = fields; values = array of values returned) or output display if -view chosen;
################
sub get_Run_data {
################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'run_id');
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $quiet = $args{-quiet};             ## suppress feedback

    return $self->get_run_data(%args);      ## access method in general alDente_API method.
}

################
sub get_SAGE_data {
################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $input_joins      = $args{-input_joins} || {};   ## specific join table conditions ...
    my $input_left_joins      = $args{-input_left_joins} || {};   ## specific join table conditions ...
    my $fields                = $args{-fields};
    my $add_fields                = $args{-add_fields};

    my $quiet = $args{-quiet};             ## suppress feedback

    my @field_list = ('project','library','host','anatomic_site','cell_line_name','original_source_type','stage','sex','strain','organism','original_source_name','contact','contact_organization','RNA_DNA_Extraction','SAGE_type','tags_requested','anchoring_enzyme','tagging_enzyme','library_format','library_started','original_contact', 'original_contact_position', 'original_contact_phone','original_contact_email','original_contact_organization','starting_amount_ng', 'original_source_id');  
   
    #push(@field_list,('Source.Original_Amount','Source.Amount_Units'));
    if ($fields) {
	@field_list = Cast_List(-list=>$fields,-to=>'array');
    } elsif ($add_fields) {
	my @add_list = Cast_List(-list=>$add_fields,-to=>'array');
	push(@field_list,@add_list);
    }

    $input_joins->{'SAGE_Library'} = "SAGE_Library.FK_Vector_Based_Library__ID=Vector_Based_Library.Vector_Based_Library_ID";
	
    $input_left_joins->{'Enzyme as Anchoring_Enzyme'} = "Anchoring_Enzyme.Enzyme_ID=SAGE_Library.FKAnchoring_Enzyme__ID";
    $input_left_joins->{'Enzyme as Tagging_Enzyme'} = "Tagging_Enzyme.Enzyme_ID=SAGE_Library.FKTagging_Enzyme__ID";

    $args{-fields} = \@field_list;
#    $args{-input_joins} = $input_joins;

    ## override tables that are always included in get_library_data
    $args{-tables} = "SAGE_Library,Vector_Based_Library,Library,Original_Source";
    $args{-join_condition} = "WHERE Vector_Based_Library.FK_Library__Name=Library_Name AND SAGE_Library.FK_Vector_Based_Library__ID=Vector_Based_Library.Vector_Based_Library_ID AND Library.FK_Original_Source__ID=Original_Source_ID";
    $args{-input_left_joins} = $input_left_joins;

    return $self->get_library_data(%args);      ## access method in general alDente_API method.
}

##############################
#
# <snip>
#
# Examples:
#
# # to return all runs/lanes for a specific flowcell
# my $flowcell = "FC1033";
# my $data     = $API->get_solexa_run_data(-flowcell=>$flowcell);
#
# # to return all lane 2 runs for the same flowcell:
# my $data = $API->get_solexa_run_data(-flowcell=>$flowcell,-lane=>2);
#
# </snip>
#
##############################
sub get_solexa_run_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);

    my $fields         = $args{-fields        };     # over-ride default fields (defaults include flowcell, graft time, lot_number, lane   
    my $add_fields     = $args{-add_fields    };     # add your own fields to default list
    my $flowcell       = $args{-flowcell      };     # Flowcell Code (aka: ID) (ie: FC1033)
    my $lane           = $args{-lane          };     # Flowcell Lane

    my @field_list = ( 'flowcell_code', 'grafted_datetime', 'lot_number', 'lane' );

    my @input_conditions = ();

    if ($flowcell) {
        push @input_conditions, "Flowcell.Flowcell_Code in ('$flowcell')";
    }

    if ($lane) {
        push @input_conditions, "SolexaRun.Lane in ($lane)";
    }

    if (@input_conditions) {
        $args{-condition} = \@input_conditions;
    }

    if (@input_conditions) {
	$args{-condition} = \@input_conditions;
    }

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push @field_list, @add_list;
    }

    

    $args{-fields} = \@field_list;

    my $input_joins;
    $input_joins->{'SolexaRun'      } = 'SolexaRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Flowcell'       } = "Flowcell.Flowcell_ID = SolexaRun.FK_Flowcell__ID";
    
    my $input_left_joins;
    $input_left_joins->{'Solexa_Read'       } = "Run.Run_ID = Solexa_Read.FK_Run__ID";

    $args{-input_joins     } = $input_joins;
    $args{-input_left_joins} = $input_left_joins;

    return $self->get_run_data(%args);
}
# Deprecated method:  please use get_read_data()
#
#
#
#################
sub get_Read_data {
#################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    return $self->get_read_data(%args);      ## access method in general
}

#######################
sub get_read_summary {
#######################
  my $self = shift;
  $self->log_parameters(@_);
  my %args = &filter_input(\@_);
  return $self->convert_parameters_for_summary(-scope=>'read', %args);
}
# Deprecated method:  please use get_library_data()
#
#
#
###################
sub get_Library_info {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    return $self->get_library_data(%args);      ## access method in general
}


#########################
sub get_Concentration_data {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    return $self->get_concentration_data(%args);      ## access method in general
}

################################
# Must specify ONE of the following keys (logically tested in this order):
#
# - mgc_number (.. ELSE ..)
# - original_plate_id (.. ELSE ..)
# - source_collection (and source_plate , source_quadrant if desired)  (.. ELSE ..)
# - sample_name (.. ELSE ..)
# - library (and plate_number if desired)  (.. ELSE ..)
# - project_id (may include comma-delimited list as a string)
#
# AND include (optional) extra conditions such as: 
# - sample_id(s)  (comma-delimited list) - may include with above to indicate domain of samples to search from 
# - source_quadrant (quadrant from original sourced plate) 
#
# May also specify:
# -  condition : (extra SQL condition applied ONLY to Clone / Source information)
# -  limit : to the number of unique clone records retrieved.
# -  a specified list of fields to retrieve (defaults to a fairly complete list of info)
#
# <snip>
# Example: 
#   my $data = $API->get_Clone_data(
#          -source_collection=>'IRAL',-source_plate=>49,-source_quadrant=>'b',
#          -key=>'mgc_number');  ## set key of hash to mgc_number
# </snip>
#
# Returns: hash (eg %data->{field1}=[val1,val2,val3..] etc.) or a hash for each record (format=>'array' or key=>'$key')
###################
sub get_clone_data {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'source_collection,source_plate,source_quadrant');

    return $self->get_sample_data(%args,-sample_type=>'clone');
}
################################
# Must specify ONE of the following keys (logically tested in this order):
#
#
# 
# - sample_id(s)  (comma-delimited list) - may include with above to indicate domain of samples to search from 
#
#
# May also specify:
# -  condition : (extra SQL condition applied ONLY to Clone / Source information)
# -  limit : to the number of unique clone records retrieved.
# -  a specified list of fields to retrieve (defaults to a fairly complete list of info)
#
# <snip>
# Example: 
#   my $data = $API->get_extraction_data(-sample_id=>4394962);
#  
# </snip>
#
# Returns: hash (eg %data->{field1}=[val1,val2,val3..] etc.) or a hash for each record (format=>'array' or key=>'$key')
###################
sub get_extraction_data {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'sample_id');

    return $self->get_sample_data(%args,-sample_type=>'extraction');
}

################################
# Must specify ONE of the following keys (logically tested in this order):
#
# - mgc_number (.. ELSE ..)
# - original_plate_id (.. ELSE ..)
# - source_collection (and source_plate , source_quadrant if desired)  (.. ELSE ..)
# - sample_name (.. ELSE ..)
# - library (and plate_number if desired)  (.. ELSE ..)
# - project_id (may include comma-delimited list as a string)
#
# AND include (optional) extra conditions such as: 
# - sample_id(s)  (comma-delimited list) - may include with above to indicate domain of samples to search from 
# - source_quadrant (quadrant from original sourced plate) 
#
# May also specify:
# -  condition : (extra SQL condition applied ONLY to Clone / Source information)
# -  limit : to the number of unique clone records retrieved.
# -  a specified list of fields to retrieve (defaults to a fairly complete list of info)
#
# <snip>
# Example: 
#   my $data = $API->get_Clone_data(
#          -source_collection=>'IRAL',-source_plate=>49,-source_quadrant=>'b',
#          -key=>'mgc_number');  ## set key of hash to mgc_number
# </snip>
#
# Returns: hash (eg %data->{field1}=[val1,val2,val3..] etc.) or a hash for each record (format=>'array' or key=>'$key')
###################
sub get_Clone_data {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'source_collection,source_plate,source_quadrant');
    return $self->get_sample_data(%args,-sample_type=>'clone');
}


########################################################################
# Extract read information from all samples from a given plate_id, well
#
# <snip>
# Example: 
#  my $data = $API->get_plate_reads(-plate_id=>$plate_id,-well=>$well);
# </snip>
#
# Return: Information on reads completed on all downstream samples given a plate_id, well
######################
sub get_plate_reads { 
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'plate_id,well');
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $start = timestamp();

    my $plate_ids  = $args{-plate_id};                     
    my $wells      = $args{-well};                        #### Well in ORIGINAL plate
    my $quadrant   = $args{-quadrant};                    #### get all wells from this quadrant
    my $group_by   = $args{-group} || $args{-group_by};                    #### group by (ONLY grouping by run is an option)
    my $quiet      = $args{-quiet};
    my $include    = $args{-include};                     #### used to filter out production / approved / billable runs.. 
    my $exclude    = $args{-exclude};                     #### used to filter out production / approved / billable runs.. 

    my $condition =  $args{-condition} || 1;                   ###  used to apply extra run condition(s)

    ### include only test / production runs if specified ###
    if ( ($include =~/production/i) && ($include !~/test/i)) { 
	$condition .= " AND Run_Test_Status = 'Production'";
    } elsif (($include !~/production/i) && ($include =~/test/i)) { 
	$condition .= " AND Run_Test_Status = 'Test'";
    }
    if ($include =~/billable/i) { $condition .= " AND Billable = 'Yes'" }
    if ($include =~/approved/i) { $condition .= " AND Run_Validation='Approved'" }
    
    if ($exclude =~/billable/i) { $condition .= " AND Billable != 'Yes'" }
    if ($exclude =~/approved/i) { $condition .= " AND Run_Validation != 'Approved'" }
    if ($exclude =~/pending/i) { $condition .= " AND Run_Validation != 'Pending'" }
    if ($exclude =~/rejected/i) { $condition .= " AND Run_Validation != 'Rejected'" }
    if ($exclude =~/production/i) { $condition .= " AND Run_Test_Status != 'Production'" }
    if ($exclude =~/test/i) { $condition .= " AND Run_Validation != 'Test'" }
    
    my $dbc = $self->dbc();

    ### Map 384 < > 96 wells 
    my %Map;
    my @mapping = $self->Table_find('Well_Lookup','Plate_96,Plate_384,Quadrant');
    foreach my $mapped (@mapping) {
	my ($well_96,$well_384,$quadrant) = split ',', $mapped;
	my ($converted_384,$converted_96) = (format_well($well_384),format_well($well_96));
#	map { if (/^(.)(\d)$/) { $_ = uc($1)."0".$2 } }  ($converted_384,$converted_96);
	$Map{$quadrant}{$converted_96} = $converted_384;
	$Map{$converted_384}{quadrant} = $quadrant;
	$Map{$converted_384}{well} = $converted_96;
    }
    
    $plate_ids = Cast_List(-list=>$plate_ids,-to=>'string');
    $wells = Cast_List(-list=>$wells,-to=>'string');
    
    if ($quadrant) {
	$wells = join ',', $self->Table_find('Well_Lookup','Well_384',"WHERE Quadrant in ('$quadrant')");
    }

    my @fields = ('Run_ID as run_id', 'Run_Validation as validation','Plate_Test_Status','Rack_Alias','Run_Directory as run_name','Run_Test_Status as run_status','Run_DateTime as run_time','Run_Status','Run.FK_Plate__ID as sequenced_plate','Plate_Size as plate_size','LibraryPrimer.Direction as direction','FK_Primer__Name as primer','FKParent_Plate__ID as parent_plate_id');

    if ($group_by) { $group_by = "GROUP BY Run_ID"; }
    else { $group_by ||= " GROUP BY Run_ID,Well";}       ## force grouping of read results to plate_id,well
    if ($wells || $group_by=~/Well/) {
	push(@fields,'sequenced_well','Q20','quality_length'); 
    } else {
	push(@fields,'Average_Q20','Average_QL');
    }

    my @aliases = ('Run','Read');
    map {                                 ## substitute aliases in extra fields
	if ($Aliases{Run}{$_}) { $_ = "$Aliases{Run}{$_} AS $_"; }
	elsif ($Aliases{Read}{$_}) { $_ = "$Aliases{Read}{$_} AS $_"; }
    } @fields;

    my $printed = 0;
    my %data;

    foreach my $plate (split ',', $plate_ids) {
	my ($original_size) = $self->Table_find('Plate','Plate_Size',"WHERE Plate_ID = $plate");
	if ($original_size =~/96/ && $quadrant) { 
	    Message("Error: Cannot specify quadrant for 96-well plate");
        return $self->api_output(-data=>\%data,-start=>$start,-log=>1,-customized_output=>1);
	}

	my $plate_list = $plate;
	my $children = &alDente::Container::get_Children(-dbc=>$dbc,-id=>$plate,-format=>'list',-include_self=>1);
	if ($children =~/\d/) { $plate_list .= ",$children"; }
	
	### check for Plates of the same size ##
	my $base_tables = 'Run,SequenceRun,Plate,Library_Plate,Rack LEFT JOIN SequenceAnalysis ON SequenceAnalysis.FK_SequenceRun__ID=Run_ID';
	my $base_condition = "WHERE SequenceRun.FK_Run__ID=Run_ID AND Run.FK_Plate__ID=Plate_ID AND Plate.FK_Rack__ID=Rack_ID AND Library_Plate.FK_Plate__ID=Plate_ID AND $condition AND Run.FK_Plate__ID in ($plate_list)";
	if (grep /direction/i, @fields) {
	    $base_tables .= ",Library,Solution,Stock_Catalog,Stock LEFT JOIN LibraryPrimer ON LibraryPrimer.FK_Library__Name=Library_Name AND FK_Primer__Name=Stock_Catalog_Name";
	    $base_condition .= " AND Plate.FK_Library__Name=Library_Name AND FKPrimer_Solution__ID=Solution_ID AND FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID";
	}
	
	if (!$wells && $group_by!~/Well/) {   ## group only by Plate 
	    my @read_data = $self->Table_find_array($base_tables,\@fields,"$base_condition $group_by");
	    foreach my $read (@read_data) {
		my @info = split ',', $read;
	 	my $run_id = $info[0];
		unless ($run_id =~/[1-9]/) { next }
		$data{$plate}{$run_id}{run_id} = $run_id;
		foreach my $field (@fields) { 
		    my $label = $field;
		    my $value = shift @info;
		    $label=~s/(.+) as //i;
		    $data{$plate}{$run_id}{$label} = $value;
		}
	    }
	    next;
	}
	elsif (!$wells && $group_by=~/Well/) { ## group by wells, but wells not specified (generate well list)	
	    if ($original_size =~/96/) { $wells = join ',', $self->Table_find('Well_Lookup','Plate_96',"WHERE Quadrant = 'a'"); }
	    else { 
		my @keys = keys %Map;
		my @well_list;
		map { if (/[A-Za-z]\d{2}/) { push(@well_list,$_); } } @keys;
		$wells = join ',', @well_list;
	    }
	} 
	$base_tables .= ",Clone_Sequence";
	$base_condition .= " AND Clone_Sequence.FK_Run__ID=Run_ID";
	foreach my $well (split ',', $wells) {
	    my $sequenced_well = $well;       ## convert if necessary..
	    my $extra_condition .= " AND Plate_Size='$original_size' AND Clone_Sequence.Well = '$sequenced_well'";
	    
	    my @read_data = $self->Table_find_array($base_tables,\@fields,"$base_condition $extra_condition $group_by");
	    foreach my $read (@read_data) {
		my @info = split ',', $read;
	 	my $run_id = $info[0];
		unless ($run_id =~/[1-9]/) { next }
		$data{$plate}{$run_id}{$sequenced_well}{run_id} = $run_id;
		foreach my $field (@fields) { 
		    my $label = $field;
		    my $value = shift @info;
		    $label=~s/(.+) as //i;
		    $data{$plate}{$run_id}{$sequenced_well}{$label} = $value;
		}
	    }
	    if ($original_size =~/384/) {
		### ALSO check for Plates that have been mapped to 96-well ###
		my $sequenced_well = $Map{$well}{well};       ## convert if necessary..
		my $sequenced_quadrant = $Map{$well}{quadrant};       ## convert if necessary..
		unless (grep /Plate_Position/, @fields) { push(@fields,'Library_Plate.Plate_Position'); }
		
		my $extra_condition .= " AND Plate_Size like '96%' AND Clone_Sequence.Well = '$sequenced_well' AND Parent_Quadrant='$sequenced_quadrant'";

		my @read_data = $self->Table_find_array($base_tables,\@fields,"$base_condition $extra_condition $group_by");
		foreach my $read (@read_data) {
		    my @info = split ',', $read;
		    my $run_id = $info[0];
		    unless ($run_id =~/[1-9]/) { next }
		    $data{$plate}{$run_id}{"$sequenced_quadrant-$sequenced_well"}{run_id} = $run_id;
		    foreach my $field (@fields) {
			my $label = $field;
			my $value = shift @info;
			$label=~s/(.+) as //i;
			$data{$plate}{$run_id}{"$sequenced_quadrant-$sequenced_well"}{$label} = $value;
		    }
		}
	    }
	}
    }
    return $self->api_output(-data=>\%data,-start=>$start,-log=>1,-customized_output=>1);
}

##################################################
# old name.. (please refer to either:
#
# -  $API->get_plate_reads (for read specific information), or ..
# -  $API->get_plate_data (for general information about plate(s)) 
#
#################
sub get_plate_info_OLD {
#################
    my $self = shift;
    my %args = @_;
    return $self->get_plate_reads(%args);
}

#############################################
# Get simple read count given plate / run / library / project / study (or whatever)...
#
#
# <snip>
# Example: 
#   my $count = $API->get_read_count(-project_id=>5,-include=>'production,approved');
# </snip>
#
# Count number of reads in library/project/
#  (by default this EXCLUDES No Grows)
#
# Return: Integer = number of reads found OR hash if grouping requested. (%returnval->{fields}[1..$records])
##############
sub get_read_count {
##############
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $library    = $args{-library};                              ### specify library ... or ...
    my $project_id = $args{-project_id} || $args{-project};        ### specify project ... or ... 
    my $study_id   = $args{-study_id} || $args{-study};            ### specify study id 
    my $condition  = $args{-condition} || 1;                       ### optional extra condition
    my $since      = $args{-since};                               ### Optional specification of runs generated since certain date
    my $until       = $args{-until};                               ### Optional specification of runs generated until certain date
    my $group_by   =  $args{-group} || $args{-group_by};
    my $order_by   = $args{-order_by};
    my $include_test_runs = $args{-include_test} || 0;            ### include test runs flag (defaults to 0)
    my $include_NGs = $args{-include_NGs} || 0;                   ### include no grows in read count
    my $KEY        = $args{-key};                                 ### field to use as key for hash
    my $get         = $args{-get} || 'count';                        ## field to retrieve (may return Q20, avg_q20 etc)

    my $dbc = $self->dbc();

    if (ref($library) eq 'ARRAY') { $library = join "','", @$library }
 
    if (ref($project_id) eq 'ARRAY') { $project_id = join ",", @$project_id }

    my $tables = "SequenceAnalysis,SequenceRun,Run,Plate";
    $condition .= " AND SequenceAnalysis.FK_SequenceRun__ID=SequenceRun_ID AND FK_Run__ID=Run_ID AND Run.FK_Plate__ID=Plate_ID";

    # add to condition    
    my $libs; $libs = $self->get_libraries(%args) if ($library || $study_id || $project_id);
    my $libraries ; $libraries = Cast_List(-list=>$libs,-to=>'string',-autoquote=>1) if $libs;
    $condition .= " AND FK_Library__Name IN ($libraries)" if $libraries;

#    if ($library) {
#	$condition .= " AND FK_Library__Name in ('$library') ";
#    }
#    if ($project_id) {
#	$tables .= ",Library,Project";
#	$condition .= " AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND (Project_ID=$project_id OR Project_Name = '$project_id')";
#    }
#    if ($study_id) {
#	# grab all libraries 
#	my @libs = $self->Table_find('Study,LibraryStudy','FK_Library__Name',"WHERE FK_Study__ID=Study_ID AND (Study_ID = $study_id OR Study_Name = '$study_id')");
#	my @proj_libs = $self->Table_find('Study,Library,ProjectStudy','Library_Name',"WHERE FK_Study__ID=Study_ID AND ProjectStudy.FK_Project__ID=Library.FK_Project__ID AND Library.FK_Project__ID > 0 AND (Study_ID = $study_id OR Study_Name = '$study_id')");
#	my $lib_list = Cast_List(-list=>[@libs,@proj_libs],-to=>'string',-autoquote=>1);
#	$condition .= " AND FK_Library__Name in ('$lib_list') ";
#    }

    my $field = 'Wells';                          ## field containing number of reads
    unless ($include_test_runs) { $condition .= " AND Run_Test_Status = 'Production'" }  ## exclude test runs 
    unless ($include_NGs) { $field = 'AllReads' }  ## alternate field if No Grows included 
    
    if ($get =~/count/i) { 
	$field = 'Sum(Wells)';
	if ($include_NGs) { $field = 'AllReads' }  ## alternate field if No Grows included 
    }
    elsif ($get =~/q20/i) { 
	$field = 'Sum(Q20total)';
	if ($field=~/av/i) { $field .= '/Sum(Wells)' }  ## alternate field if No Grows included     
    }
    elsif ($get =~/length/i) { 
	$field = 'Sum(SLtotal)';
	if ($field=~/av/i) { $field .= '/Sum(Wells)' }  ## alternate field if No Grows included     
    } else {
	print "You must specify field to extract (eg. count, q20, avg_q20, length, avg_length)\n";
	return;
    }

    my %returnval;      ## returned if request for data grouping
    my $count;          ## return single value if no grouping requested
    if ($group_by || $KEY) {
	%returnval = &Table_retrieve($dbc,$tables,["$field as count",$group_by],"WHERE $condition $group_by $order_by");
    } else {
	($count) = $self->Table_find_array($tables,["$field as count"],"WHERE $condition");
    }    

#    my $query = "SELECT $field as count from $tables WHERE $condition $group_by $order_by";
#    print $query;    
    
    if ($group_by || $KEY) {
    return $self->api_output(-data=>\%returnval,-start=>$start,-log=>1,-customized_output=>1);
    } else {
    return $self->api_output(-data=>$count,-start=>$start,-log=>1,-customized_output=>1);
    } 
}

###########################################
# Generate data for Plate objects
#
# <snip>
# Example: 
#
# my $plate_data = $API->get_plate_data(-library=>$lib);  # get info on all plates from given library
#
# </snip>
#
#    
######################
sub get_Plate_data { 
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $quiet = $args{-quiet};             ## suppress feedback

    return $self->get_plate_data(%args);
}

#############################################################################################
# Retrieve direction information given a library and primer.
#
# <snip>
# Example: 
#   my $dir = $API->get_direction(-library=>'MGC01',-primer=>'-21 M13'); ## returns suggested primers for given lib
#   my %direction = %{ $API->get_direction(-library=>'MGC01') };  ## returns both valid (by primer) and suggested (by lib)
#   my %direction = %{ $API->get_direction(-vector=>'*topo*',-primer=>'*m13*') };  ## returns both valid (by primer) and suggested (by lib)
# </snip>
#
# Get direction specification from Library or Vector for given Primer
# Specify Vector + Pri
# Specify Library + Primer for LibraryApplication Direction
# (otherwise returns hash with values for:
#    Library_Name, Direction_In_Library, VectorPrimer, VectorPrimer_Direction
# 
# Return direction 
################
sub get_direction {
################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_,-args=>'library,primer');
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $library    = $args{-library};         ## library may use array of libraries
    my $vector     = $args{-vector};          ## specify vector name (may use wildcard *)
    my $primer     = $args{-primer};          ## specify primer name (may use wildcard *)
    my $order_by   = $args{-order_by};        ## order output by field (if multiple records expected)
    my $condition  = $args{-condition} || 1;
    my $limit      = $args{-limit} || '';

    $primer = convert_to_regexp($primer);
    $vector = convert_to_regexp($vector);

    my $dbc = $self->dbc();

    if ($limit=~/[1-9]/) { $limit = " LIMIT $limit" }
    if ($order_by) { $order_by = " ORDER BY $order_by" }

## alternative input ##
    my $vector_id     = $args{-vector_id};
    my $primer_id  = $args{-primer_id};

    if ($vector_id && !$vector) {             ## get vector_id if only vector name supplied
	$vector = $self->Table_find('Vector,Vector_Type','Vector_Type_Name',"where Vector_ID=$vector_id and FK_Vector_Type__ID = Vector_Type_ID");
    }
    
    if ($primer_id && !$primer) {              ## get primer name if only primer_id supplied
	($primer) = $self->Table_find('Primer','Primer_Name',"where Primer_ID = '$primer_id'");
    }

    if (ref($library) eq 'ARRAY') { $library = join "','", @$library }

    my @fields = ("Primer.Primer_Name as Primer_Name",'Branch_Condition.FK_Branch__Code');
    
    my $tables = "Vector_Based_Library,Vector_Type,Library,LibraryVector,Vector,LibraryApplication,Vector_TypePrimer,Primer,Branch_Condition";

    $condition .= " AND Vector_Based_Library.FK_Library__Name=Library_Name AND Library_Name = LibraryVector.FK_Library__Name and LibraryVector.FK_Vector__ID = Vector_ID AND Vector.FK_Vector_Type__ID = Vector_Type_ID and Vector.FK_Vector_Type__ID = Vector_TypePrimer.FK_Vector_Type__ID AND Vector_TypePrimer.FK_Primer__ID = Primer_ID AND LibraryApplication.FK_Library__Name=Library_Name AND LibraryApplication.Object_ID=Primer_ID AND Branch_Condition.Object_ID = Primer_ID";
    

    $condition .= " AND Primer_Name like '$primer'" if $primer;
    $condition .= " AND Vector_Type_Name like '$vector'" if $vector;
    $condition .= " AND Library_Name in ('$library')" if $library;

    if ($library) { push(@fields,'Library_Name','LibraryApplication.Direction as Direction_in_Library'); }
    if ($vector) { push(@fields,'Vector_Type_Name','Vector_TypePrimer.Direction as Direction_in_Vector'); }

    my %direction_info = &Table_retrieve($dbc,$tables,\@fields,"WHERE $condition $order_by $limit",-distinct=>1);
    return $self->api_output(-data=>\%direction_info,-start=>$start,-log=>1,-customized_output=>1);
}

#####################
# This is used to retrieve information regarding trace submissions.
# 
# Return: hash containing data requested
#####################
sub get_trace_submission_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_conditions   = $args{-condition} || '1';             ### extra condition (vulnerable to structure change)
    my $study_id       = $args{-study_id};                        ### a study id (a defined set of libraries/projects)
    my $project_id     = $args{-project_id};                      ### specify project_id
    my $library      = $args{-library};                           ### specify library
    ## plate specification options
    my $plate_id     = $args{-plate_id};                           ### specify plate_id
    my $plate_number = $args{-plate_number};                      ### specify plate number 
    my $well         = $args{-well};                      ### specify plate number 
    my $plate_type = $args{-plate_type} || '';                    ### specify type of plate (tube or Library_Plate)
    my $plate_class = $args{-plate_class} || '';                  ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';      ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};            ### specify original plate id 
    my $original_well     = $args{-original_well};                ### specify original well
    my $applied_plate_id  = $args{-applied_plate_id};             ### specify original plate id (including ReArrays)
    my $quadrant     = $args{-quadrant};                          ### specify quadrant from original plate
    my $sample_id    = $args{-sample_id};                         ### specify sample_id 
    my $run_id       = $args{-run_id};
    my $library_type = $args{-library_type};
    ## Inclusion / Exclusion options
    my $since       = $args{-since};                              ### specify date to begin search (context dependent)
    my $until       = $args{-until};                               ### specify date to stop search (context dependent)

    ## Output options 
    my $fields      = $args{-fields} || '';
    my $order       = $args{-order} || '';
    my $group       =  $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                        ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                              ### suppress feedback by setting quiet option
    my $save        = $args{-save};
    my $list_fields = $args{-list_fields};  
    
    my $dbc; ## $self->dbc();
    ## Extra Options for this method
    my $volume_id   = $args{-volume_id};
    my $volume_name = $args{-volume_name}; 

    my @extra_conditions; @extra_conditions = Cast_List(-list=>$input_conditions,-to=>'array') if $input_conditions;
    
    ### Re-Cast arguments if necessary ###

    my $libs; $libs = $self->get_libraries(%args) if ($library || $study_id || $project_id);
    my $libraries ; $libraries = Cast_List(-list=>$libs,-to=>'string',-autoquote=>1) if $libs;

    my $plates = Cast_List(-list=>$plate_id,-to=>'string') if $plate_id;
    my $plate_numbers = Cast_List(-list=>$plate_number,-to=>'string') if $plate_number;
    my $wells = Cast_List(-list=>$well,-to=>'string',-autoquote=>1) if $well;
    my $samples = Cast_List(-list=>$sample_id,-to=>'string') if $sample_id;
    my $library_types = Cast_List(-list=>$library_type,-to=>'string',-autoquote=>1) if $library_type;
    my $runs = Cast_List(-list=>$run_id,-to=>'string',-autoquote=>1) if $run_id;
    my $volumes = Cast_List(-list=>$volume_id,-to=>'string',-autoquote=>1) if $volume_id;
    my $volume_names = Cast_List(-list=>$volume_name,-to=>'string',-autoquote=>1) if $volume_name;
    
    #my $tables = 'Sample,Submission_Volume,Trace_Submission,Run,SequenceRun,Plate,Chemistry_Code';
    my $tables = 'Sample,Submission_Volume,Trace_Submission,Run,SequenceRun,Plate,Branch_Condition';
    #my $join_condition = "WHERE FK_Submission_Volume__ID=Submission_Volume_ID AND SequenceRun.FK_Run__ID=RuN_ID AND Trace_Submission.FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID AND FK_Chemistry_Code__Name = Chemistry_Code_Name AND Trace_Submission.FK_Sample__ID=Sample_ID";
    my $join_condition = "WHERE FK_Submission_Volume__ID=Submission_Volume_ID AND SequenceRun.FK_Run__ID=RuN_ID AND Trace_Submission.FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID AND Plate.FK_Branch__Code = Branch_Condition.FK_Branch__Code AND Trace_Submission.FK_Sample__ID=Sample_ID";

    #my @field_list = ('Volume_Name','Submission_Volume_ID as Volume_ID','FK_Sample__ID as Sample_ID','Sample_Name','Submission_Status as Status','Run_ID as Run_ID','Run_Validation','Run_DateTime as Run_Time','Submission_Date','Approved_Date','FK_Library__Name as Library','Plate_Number','Run_Directory as Run_Name','Well','Chemistry_Code_Name as Chemistry_Code','FK_Primer__Name as Primer');
    my @field_list = ('Volume_Name','Submission_Volume_ID as Volume_ID','FK_Sample__ID as Sample_ID','Sample_Name','Submission_Status as Status','Run_ID as Run_ID','Run_Validation','Run_DateTime as Run_Time','Submission_Date','Approved_Date','FK_Library__Name as Library','Plate_Number','Run_Directory as Run_Name','Well','Branch_Condition.FK_Branch__Code as Chemistry_Code','FK_Primer__Name as Primer');

    if ($group =~ /volume/) {
	push(@field_list,'Submission_Volume.Records as Volume_Records');
    }

    ## specify optional tables to include (with associated condition) - used in 'include_if_necessary' method ##
    my $left_join_tables = '';
    my $join_conditions = { };
  
    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = { };  

    if ($samples) { push(@extra_conditions,"Trace_Submission.FK_Sample__ID IN ($samples)") };
    if ($runs)    { push(@extra_conditions,"Trace_Submission.FK_Run__ID IN ($runs)") };
    if ($volumes) { push(@extra_conditions,"Trace_Submission.FK_Submission_Volume__ID IN ($volumes)") };
    if ($volume_names) { push(@extra_conditions,"Submission_Volume.Volume_Name IN ($volume_names)") };

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;
    
    if ($group || $KEY) { push(@field_list, 'Count(*) as count'); }   
    foreach my $key (split ',', $KEY) {
	push(@field_list, $key) unless (grep /\b$key\b/, @field_list);   ## add to fields if not already... 
    }
    
    return $self->generate_data(
				-input=>\%args,
				-field_list=>\@field_list,
				-group=>$group,
				-key=>$KEY,
				-order=>$order,
				-tables=>$tables,
				-join_condition => $join_condition,
				-conditions=>$conditions,
				-left_join_tables => $left_join_tables,
				-left_join_conditions => $left_join_conditions,
				-join_conditions => $join_conditions,
				-limit => $limit,
				-dbc => $dbc,
				-quiet => $quiet
				);
}

########################################################
# User should enter either Library / (plate_number) info OR sample_id(s) (if only SOME of wells on a plate  are desired)
#
# <snip>
# 
# Examples: 
#   my @files = @{ $API->get_trace_files(-library=>'MGC01',-list=>1) }
#
#   my $zipped = $API->get_trace_files(-library=>'MGC01',-compress=>"/home/aldente/private/temp/")
#
# </snip>
#
# (may return list of names, with options to put links or copies in a specified directory)
#
#
# or directly create zipped directory with these files:
# 
# my $zipped = $API->get_trace_files(-library=>'MGC01',-copy=>1,-compress=>1)
#
# Return : Number of files found.
##################
sub get_trace_files {
##################
my $self = shift;
$self->log_parameters(@_);
my %args = &filter_input(\@_,-args=>'library,plate_number,well');
my $start = timestamp();

if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

my $alias      = $args{-alias_name};
my $alias_type = $args{-alias_type};
my $well       = $args{-well};                      ### plate number specification (eg. 1 or 2a)
my $copy       = $args{-copy} || 0;                           ### copy files to target_directory
my $link       = $args{-link} || 0;                           ### create links in target_directory
my $compress   = $args{-compress} || 0;                       ### compressed filename for final zipped up files
my $ext        = $args{-ext} || 'ab*';                        ### specify extension of files to copy / link
my $key        = $args{-key};
my $return      = $args{-return};                               ### list of values to return (run_id,run_name,filename,plate_id,sequenced_well,sequence_legth,primer)
my $field_ref  = $args{-fields};
my $quiet      = $args{-quiet};
my $format     = $args{-format} || 'hash';
my $separator  = $args{-separator} || "\t";
my $target_directory = $args{-path} || $copy || $link;

if ($compress) {
    ### target directory where copies / links should be stored. (creates automatically if it does not exist)
    unless ($target_directory) {
        if ($compress =~/^(.*)\/(.*?)$/) {
            $target_directory = $1;
            $compress = $2;
        }
        else {
            $target_directory = '.';
        }
    }
}

my $dbc = $self->dbc();

## back support use of return argument - phase to use of fields ##
$return = Cast_List(-list=>$return,-to=>'string');
if ($return && !$field_ref) {
    my @field_array = split ',', $return;
    $field_ref = \@field_array;
}

my @fields = ('Distinct Run_Directory as directory','sequencer','sequenced_well','sample_id','sample_name','parent_quadrant','unused_wells','project_path','library','run_id','run_name','plate_id','sequence_length','trimmed_length','quality_length','Q20','primer','chemistry_code','validation');
if ($field_ref) { 
    foreach my $field (@$field_ref) {
        unless (grep /\b$field\b/, @fields) {
            push(@fields, $field);
        }
    }
}

my %read_data = %{ $self->get_read_data(%args,-fields=>\@fields,-include=>'production,approved') };

my %Dir;
foreach my $sequencer ( $self->Table_find('Equipment,Stock,Stock_Catalog,Equipment_Category','Equipment_ID',"WHERE Category = 'Sequencer'  AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID") ) {
    unless ($sequencer) { next }
    my ($data_dir) = $self->Table_find('Machine_Default','Local_Data_Dir',"WHERE FK_Equipment__ID = $sequencer");
    $Dir{$sequencer} = $data_dir;
}

#my $archive_path = "/home/aldente/public/archive";
my $archive_path = $archive_dir;
my @found_files;
my @found_read_data;

if ($target_directory) { unless (-e "$target_directory") { `mkdir $target_directory` } }

my $size = 0;
my $output = '';

my $records;
if (defined $read_data{directory}) { $records = int(@{$read_data{directory}}); }
else { $records = 0; }

my $found = 0;
print "Found $records applicable reads\n" unless $quiet;
while (defined $read_data{directory}[$found]) {
    my %Info;
    foreach my $field (@fields) {
        if ($field =~ /(.*) as (.+)/i) { $field = $2; }
        $Info{$field} = $read_data{$field}[$found];
    }
    $Info{path} = $Dir{$Info{sequencer}};
    $read_data{path}[$found] = $Info{path};
    print progress_tracker($found,$records,1000) unless $quiet;
    $found++;
    while ($Info{unused_wells} =~/^(.*)(\D)(\d)(\D)(.*)/) { $Info{unused_wells} = $1.$2.'0'.$3.$4.$5; }
    $read_data{unused_wells}[$found-1] = $Info{unused_wells};	

    while ($Info{problematic_wells} =~/^(.*)(\D)(\d)(\D)(.*)/) { $Info{problematic_wells} = $1.$2.'0'.$3.$4.$5; }
    $read_data{problematic_wells}[$found-1] = $Info{problematic_wells};	

    while ($Info{empty_wells} =~/^(.*)(\D)(\d)(\D)(.*)/) { $Info{empty_wells} = $1.$2.'0'.$3.$4.$5; }
    $read_data{empty_wells}[$found-1] = $Info{empty_wells};	

    if ($Info{unused_wells} =~/$Info{sequenced_well}\b/) { print "Well $Info{sequenced_well} unused..\n"; next; }

    $Info{chromat_dir} = "$project_dir/$Info{project_path}/$Info{library}/AnalyzedData/$Info{run_name}/chromat_dir";
    push(@found_read_data, $Info{chromat_dir});
    $read_data{chromat_dir}[$found-1] = $Info{chromat_dir};

    my $command = "find $Info{chromat_dir}/* -type l";
    my $dirs = `$command`;
    my @files = split "\n", $dirs;
    foreach my $file (@files) {
        chomp $file;
        if ($Info{sequenced_well}) {
            unless ( $file =~/$Info{chromat_dir}\/.+_$Info{sequenced_well}(_|\.)+/ ) { next;}  ## continue only for chosen well
        }
        my $fback;
        if ($copy) {
            $fback = `cp $file $target_directory`;
        } 
        elsif ($link) {
            $fback = `ln -s $file $target_directory/`;
        } 
        elsif ($compress) {
            unless ($quiet) { print "tar -czvf $target_directory/$compress.tgz $file\n"; }
            $fback = `tar -czvf $target_directory/$compress.tgz $file`;
        }
        print $fback;  ## nothing normally printed except errors .. 

        push(@found_files,$file);
        $Info{file} = $file;
        $read_data{file}[$found-1] = $Info{file};

        ## get just filename (without path) ##
        my $filename =  $file;            
        if ($filename =~/chromat_dir[\/]+(.*)/) { $filename = $1; }
        $Info{filename} = $filename;
        $read_data{filename}[$found-1] = $Info{filename};
    } 
    foreach my $thisfield (@fields) {
        if ($thisfield =~/.* as (.+)/i) { $read_data{$1}[$found-1] = $Info{$1} }
        else { $read_data{$thisfield}[$found-1] = $Info{$thisfield}; }
        $output .= $Info{$thisfield};
        $output .= $separator;
    } 
    $output .= "\n";
} 

unless ($quiet) {
    print "$output\n";
    print "** Found " . int(@found_read_data) . " Read(s)\n";
    if ( int(@found_files) ) { print "** Found " . int(@found_files) . " File(s)\n" }
}

if ( $format=~/text/ ) {
    return $self->api_output(-data=>$output,-start=>$start,-log=>1,-customized_output=>1);
} elsif ($format=~/(files)/ ) { 
    return $self->api_output(-data=>\@found_files,-start=>$start,-log=>1,-customized_output=>1);
} elsif ($format =~/dir/i) { 
    return $self->api_output(-data=>\@found_read_data,-start=>$start,-log=>1,-customized_output=>1);
} else { 
    return $self->api_output(-data=>\%read_data,-start=>$start,-log=>1,-customized_output=>1);
    }
}	  

######################################
## Methods to Write TO the Database ##
######################################

#################################################
# Define new Pooling of Clones into new Library
#
# <snip>
# Example: 
#          my $new_pool_id = $API->define_Pool(-full_name=>'Test Pool #1',-transposon_id=>1,-plate_id=>'50635',-wells=>['A01','A02','B01','B02','H12'],-date=>'2004-01-01',-name=>'TESTA',-pipeline=>'Standard',-gel_id=>22,-reads_required=>100,-status=>'Ready for Pooling',-goals=>'goals.');
# </snip>
#
# Return new pool_id (or 0 on failure)
################
sub define_Pool {
################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $start = timestamp();
    my $plates = $args{-plate_id};     # single plate or array
    my $wells  = $args{-wells};        # array of wells 
    my $type   = $args{-type};         # library type
    my $obtained = $args{-date};
    my $source   = $args{-source};
    my $host     = $args{-host};
    my $name     = $args{-name};
    my $vector   = $args{-vector};     # vector for this library / pool
    my $organism = $args{-organism};
    my $project_id  = $args{-project_id};
    my $fullname = $args{-full_name};
    my $description = $args{-description};
    my $status      = $args{-status};  # initial pool status
    my $comments      = $args{-comments}; 
    my $goals         = $args{-goals}; 
    my $group_id      = $args{-group_id};
### For Transposon Pools Only ###
    my $transposon_id  = $args{-transposon_id};
    my $gel_id         = $args{-gel_id};
    my $opt_id      = $args{-optical_density_id};
    my $parent      = $args{-parent_library};
    my $reads_required = $args{-reads_required};
    my $pipeline       = $args{-pipeline};
    my $emp_name       = $args{-emp_name} || $self->{LIMS_user};   # employee name (within LIMS system)
    my $source_name = $args{-source_name};

    my $dbc =  $self->dbc();

### (Argument allocation only included for automated perldoc)

### Temporary omission of transactions ... add transaction for this stuff !! ###
    my $Library = alDente::Library->new(-dbc=>$dbc);

    $args{-connection} = $self;           ## include connection object.. ##
    my $id  = $Library->pool_Library(%args);
    return $self->api_output(-data=>$id,-start=>$start,-log=>1,-customized_output=>1);
}

####################################
# Add Plate record to the database.
#  (requires specification of ALL mandatory fields)
#
# <snip>
# 
# Examples:
#
# To make a plate with Clone Samples for Sequencing:
#
# $API->add_Plate(-plate_size=>'96-well', -library=>'ccbr01', -rack_id=>'1', -employee=>'164', -plate_format_id=>'14', -plate_status=>'Active', -plate_type=>'Library_Plate', -plate_application=>'Sequencing', -add_samples=>'clone');
#
# To make a plate with Extraction Samples for Lib_Construction:
#
# $API->add_Plate(-plate_size=>'96-well', -library=>'ccbr01', -rack_id=>'1', -employee=>'164', -plate_format_id=>'14', -plate_status=>'Active', -plate_type=>'Library_Plate', -plate_application=>'Lib_Construction', -add_samples=>'extraction');
#
# </snip>
#
# Return: 0 on failure, 1 if success
####################################
sub add_Plate {  
#############
    my $self = shift;
    $self->log_parameters(@_);
    my  %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();
    
    my $plate_size = $args{-plate_size};                                  ### size of new plate (96 or 384)
    my $created = $args{-created} || &date_time();             ### default to now..
    my $library = $args{-library};                            ### library (must be unique, 5 alpha-num characters)
    my $rack_id    = $args{-rack_id};                         ### rack_id
    my $employee_id   = $args{-employee_id};                  ### employee (id) requesting new plate
    my $employee   = $args{-employee};                        ### employee (name) requesting new plate
    my $unused_wells = $args{-Unused_Wells};                   ### (optional)
    my $sub_quadrants = $args{-quadrants_available};          ### (optional) - use if only some quadrants of 384 are used.
    my $comments      = $args{-comments};                     ### (optional)
    my $plate_status        = $args{-plate_status};                       ### (generally 'Active' or 'Reserved' (for later ReArray)
    my $test_status   = $args{-test_status} || 'Production';  ### (optional: production or test) - default to production
    my $format        = $args{-format};                       ### (format in text format)
    my $plate_format_id     = $args{-plate_format_id};                    ### (format_id if known)
    my $plate_application   = $args{-plate_application} || 'Sequencing';  ### (Sequencing, GE, Mapping, PCR) - default to Sequencing
    my $class         = $args{-class} || 'Standard';          ### Set only if Regular or Oligo Re-Array.
    my $input         = $args{-input};                        ### optional hash form of input...
    my $plate_type          = $args{-type} || 'Library_Plate';          
    my $quiet         = $args{-quiet} || 0;                   ### quiet output (generate no stdout print statements)
    my $sample_alias  = $args{-sample_alias_hash};            ### hashref that defines the sample aliases 
                                                              ### in the form { '<well>' => {'alias' => '<aliasname>', 'type' => '<aliastype>' .... } }
    my $add_samples = $args{-add_samples} || 'n';          ### optionally add clone samples, extraction samples or none (defaults to 'n')
    my $dbc = $self->dbc();

    my $lpo = new alDente::Library_Plate(-connection=>$self);
    my $newid = $lpo->add_Plate(%args);

    if ($newid) {
        return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
    }
    else {
        return $self->api_output(-data=>0,-start=>$start,-log=>1,-customized_output=>1);
    }
}

###############################################################
# Allow users to update new Clone Samples recieved by the lab #
# (ALL applicable information should be supplied here)
# 
# Input arguments 
#
# Mandatory: row,col,vector,source_name
# Optional : comments, library_id, score
#
# <snip>
#  Example: 
#  my $data = $API->update_Clone_Source( -sample_id=>$sample,
#       -score=>$score,-vector=>$vector,-row=>$row,-col=>$col,
#       -library_id=>$lib_id,-comments=>$comments,-source_name=>'LLNL',
#       -alias=>{'IMAGE'=>12345,'MGC'=>'666'});
#
# </snip>
# 
# Return 1:  array reference to list of plates received with missing source data.
# Return 2:  # of updated records (if sample_ids given) ... OR..
# Return 3:  hash of sample_id,well,source_row,source_col (if plate/collection given with search option)
#####################
sub update_Clone_Source {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $sample_id      = $args{-sample_id};
    my $source_collection = $args{-source_collection};  ## specify source_collection (input by lab)
    my $source_plate      = $args{-source_plate};       ## specify source_plate (input by lab)
    my $search            = $args{-search};             ## just search for current records (based on source collection / plate)
    ## Mandatory keys ## (included only for documention) 
    my $row = $args{-source_row};
    my $col = $args{-source_col};
    my $name = $args{-source_name};
    my $org = $args{-source_org_id};
    my $lib_id = $args{-source_library_id};
    ## Optional keys ## (included only for documention) 
    my $comments = $args{-source_comments};
    my $vector = $args{-source_vector};
    my $score = $args{-source_score};
    my $tag3 = $args{-source_3prime_tag};
    my $tag5 = $args{-source_5prime_tag};
    ##
    my $alias  = $args{-alias};                          ## hash of aliases type=>name 
    my $comment  = $args{-comment};
    my $quiet  = $args{-quiet};                       ## suppress feedback
    my $force  = $args{-force};                       ## force updates (necessary to change values)
    my $limit  = $args{-limit};

    my $dbc = $self->dbc();

    if ($limit) { $limit = " LIMIT $limit" }

    my @mandatory_input = ('source_row','source_col','source_name','source_org_id','source_library_id');
    my @optional_input = ('source_comments','source_vector','source_score','source_3prime_tag','source_5prime_tag');
    
    my $failed = 0;
    
    my %Set;
    map {       ## Set hash of values (if specified) for Clone aliases. ##
	my $key = $_;
	my $short_form = $key;
	$short_form =~s /^source_(.*)/$1/;
	if ($args{"-$key"} || $args{"-$short_form"} ) {
	    $Set{$Aliases{Clone}{$key}} = $args{"-$key"} || $args{"-$short_form"};
	}  
    } keys %{$Aliases{Clone}};
	
    my @missing;
    if ($sample_id =~/^\d+$/) {
	my $condition .= "FK_Sample__ID in ($sample_id)";
	my $Clone = alDente::Clone->new(-dbc=>$dbc);
	$Clone->add_tables(['Clone_Source']);
	$Clone->load_Object(-condition=>$condition,-multiple=>1);
	my $clone_sample_id = $Clone->value('Clone_Sample_ID');
	unless ($clone_sample_id=~/[1-9]/) { Message("*** Error: No clone_sample_id found for Sample $sample_id."); return; }
	foreach my $field (@mandatory_input) { ## Get hash input (converted above if applicable) ##
	    my $field_name = $field;
	    if ($Aliases{Clone}{$field}) { $field_name = $Aliases{Clone}{$field} }
	    my $set = $Set{$field} || $Set{$Aliases{Clone}{$field}} || $args{"-$field"};
	    if ($set) { 
		if ($set eq $Clone->value($field_name)) {
		    Message("$field remains $set (unchanged)\n") unless ($quiet);
		} elsif ($Clone->value($field_name) && !$force) {
		    Message("*** Error: $field cannot be changed from " . $Clone->value($field_name) ." to $set (unless force specified)");
		    return;
		} else {
		    my $ok = $Clone->value($field_name,$set); 
		    Message("** SET $field => $set ($ok)\n") unless ($quiet);		    
		}
	    } elsif ($Clone->value($field_name)) { 
		Message("$field => " . $Clone->value($field_name) . " (Not set) \n") unless $quiet; 
	    } else { push(@missing,$field); }
	}
	foreach my $field (@optional_input) {
	    my $field_name = $field;
	    if ($Aliases{Clone}{$field}) { $field_name = $Aliases{Clone}{$field} }
	    my $set = $Set{$field} || $Set{$Aliases{Clone}{$field}} || $args{"-$field"};
	    if ($set) { 
		if ($set eq $Clone->value($field_name)) {
		    Message("$field remains $set (unchanged)\n") unless ($quiet);
		} elsif ($Clone->value($field_name) && !$force) {
		    Message("*** Error: $field cannot be changed from $Clone->value($field_name) to $set (unless force specified)");
		    return;
		} else {
		    my $ok = $Clone->value($field_name,$set); 
		    Message("** SET $field ($field_name) => $set ($ok)\n") unless ($quiet);		    
		}
	    } elsif ($Clone->value($field_name)) { 
		Message("$field => " . $Clone->value($field_name) . " (unchanged) \n") unless $quiet; 
	    } else { Message("$field ($field_name) ignored..\n") unless ($quiet); }
	}
	if (@missing) {
	    Message("*** Error: Mandatory Fields missing:\n@missing");
	    return;
	} 
#	print Dumper($Clone);
        my $clone_update = $Clone->update(-autoquote=>1);
	my $updated = $clone_update->{Clone_Source};
	Message("Updated $updated Clone_Source Records.") unless ($quiet);	
	if ($alias) {
	    foreach my $key (keys %{$alias}) {
		my $value = $alias->{$key};
		$self->Table_append_array('Sample_Alias',['FK_Sample__ID','Alias_Type','Alias'],
			      [$sample_id,$key,$value],-autoquote=>1);
		Message("Set Alias $key = $value ($sample_id)") unless $quiet;
	    }
	}
    return $self->api_output(-data=>$updated,-start=>$start,-log=>1,-customized_output=>1);
    } 
    elsif ($search && $source_collection && $source_plate) { 
	## retrieve basic info based upon source library/plate (eg. IRAL 54) ## 
	my $condition = "Source_Collection='$source_collection' AND Source_Plate in ($source_plate)";	
	my @found = $self->Table_find_array('Clone_Source,Clone_Sample',['FK_Sample__ID as sample_id','Original_Well as well','Source_Row as source_row','Source_Col as source_col','FKSource_Organization__ID as source_org_id','Source_Name as source_name'],"WHERE FK_Clone_Sample__ID=Clone_Sample_ID AND $condition $limit");
	my %Plate;
	foreach my $clone (@found) {
	    my ($sample,$well,$row,$col,$org,$alias) = split ',', $clone;
	    $Plate{$well}{sample_id} = $sample;
	    $Plate{$well}{row}       = $row;
	    $Plate{$well}{col}       = $col;
	    $Plate{$well}{source_org_id} = $org;
	    $Plate{$well}{source_name} = $alias;
	}
    return $self->api_output(-data=>\%Plate,-start=>$start,-log=>1,-customized_output=>1);
    } elsif ($search && $source_collection) {
	my $condition = "Source_Collection='$source_collection' AND (Source_Row = '' OR Source_Col = '')";	
	my @missing = $self->Table_find_array('Clone_Source,Clone_Sample',['Source_Plate'],"WHERE FK_Clone_Sample__ID=Clone_Sample_ID AND $condition $limit",'Distinct');
    return $self->api_output(-data=>\@missing,-start=>$start,-log=>1,-customized_output=>1);
    } elsif ($sample_id) {
	Message("*** Error: Single integer expected for Sample_id ($sample_id invalid)");
    } else {
	Message("*** Error Incomplete input :  Expecting One of the following: ***");
	Message("- Sample_id AND name=>value values to update source records .. OR..");
	Message("- source_collection/plate specification (with -search=>1 option) to get sample_id list ..OR..");
	Message("- source_collection (with -search=>1 option) to get list of 'to-be-updated' source_plate_numbers.\n");
    }
    return;
}


#################################
# Allow users to update various information on a Clone
# options:
#
#  -comments =>...
#  -size_estimate => ..
#
# <snip>
#  Example:
#   $API->update_Clone_Details(-mgc_number=>75457,-comment=>'comment string');
#   
#  ## or equivalently (allowing access to any clone aliased in the database) :
#
#   $API->update_Clone_Details(-alias_type=>'MGC',-alias=>'75457',-comment=>'comment string');
#
#   $API->update_Clone_Details(-alias_type=>'Accession_ID',-alias=>'NM_00234',-size_estimate=>600);
#
# </snip>
#
#####################
sub update_Clone_Details {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $start = timestamp();

    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $alias  = $args{-alias};
    my $sample_id   = $args{-sample_id};
    my $sample_type = $args{-sample_type} || 'Clone';
    my $alias_type = $args{-source} || $args{-type} || $args{-alias_type};
    my $mgc_number = $args{-mgc_number};

    my $comment  = $args{-comment};
    my $size = $args{-size_estimate};

    if ($size) { $sample_type ||= 'Extraction'; }   ## size field is used to update extraction_samples only
    
    my ($sample_table, $fk_field, $details_table);
    if ($sample_type =~ /clone/i) { 
	$sample_type = 'Clone';
	$sample_table = 'Clone_Sample';
	$details_table = 'Clone_Details';
	$fk_field = 'FK_Clone_Sample__ID';
    } else { 
	$sample_type = 'Extraction';
	$sample_table = 'Extraction_Sample';
	$details_table = 'Extraction_Details';
	$fk_field = 'FK_Extraction_Sample__ID';
    } 
    
    $sample_id = Cast_List(-list=>$sample_id,-to=>'string');
    my $dbc = $self->dbc();
    
    ## Special case when mgc_number supplied as 'alias_type' 
    if ($mgc_number) {
	$alias_type = 'MGC';
	$alias = $mgc_number;
	if (ref($mgc_number)) { $alias = join "','", @$mgc_number }
    }
    
    my @fields;
    my @values;
    
    ## optional specification of Clone_Comments or Extraction_Comments
    if ($comment) {
	push(@fields,$sample_type . "_Comments");
	push(@values,$comment);
	Message("Comment: $comment.");
    }	
    ## optional specification of Clone_Size_Estimate or Extraction_Size_Estimate
    if ($size) {
	push(@fields,$sample_type . "_Size_Estimate");
	push(@values,$size);
	Message("Size Estimate: $size.");
    }

    my $tables = "Sample, $sample_table";
    my $condition = "WHERE $sample_table.FK_Sample__ID=Sample_ID";
    ## Indicate which samples to change ##
    if ($sample_id) {
	$condition .= " AND Sample_ID in ($sample_id)";
    } elsif ($alias && $alias_type) {
	$tables .= ",Sample_Alias";
	$condition .= " AND Sample_ID=Sample_Alias.FK_Sample__ID AND Alias_Type = '$alias_type' AND Alias in ('$alias')";
    } else {
	Message("Sorry - you must supply either a sample_ID or alias / alias_type pair");
	return 0;
    }

    my ($id) = $self->Table_find($tables,$sample_table."_ID",$condition);
    $id ||= 0;

    my ($exists) = $self->Table_find($details_table,'count(*)',"WHERE $fk_field in ($id)");
    my $updated;
    
    if ($exists) {
	$updated = $self->Table_update_array($details_table,\@fields,\@values,"WHERE $fk_field in ($id)",-autoquote=>1);
    } else {
	push(@fields,$fk_field);
	push(@values,$id);
	$updated = $self->Table_append_array($details_table,\@fields,\@values);
    } 
    
    return $self->api_output(-data=>$updated,-start=>$start,-log=>1,-customized_output=>1);
}

#################################
# Allow users to update information on a Sample
# (eg Comments or FKParent_Sample__ID)
#
# <snip>
#  Example:
#   $API->update_Sample(-sample_id=>'2304561',-parent_sample_id=>'2304521');
#   $API->update_Sample(-sample_id=>'2304561',-parent_sample_id=>'2304521', -comment=>'My comment');
#
# </snip>
#
#####################
sub update_Sample {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $sample_id = $args{-sample_id};
    my $comment  = $args{-comment};
    my $quiet = $args{-quiet};
    my $parent_sample_id = $args{-parent_sample_id};
    my $dbc = $self->dbc();

    my @fields = ();
    my @values = ();

    if ($parent_sample_id)
    {
	push (@fields, 'FKParent_Sample__ID');
	push (@values, $parent_sample_id);
    }
    if ($comment){
    	push (@fields, 'Sample_Comments');
	push (@values, $comment);
    }
    my $updated = 0;
    if (int(@fields)){ 
	$updated = $self->Table_update_array('Sample',\@fields,\@values,"WHERE Sample_ID = $sample_id",-autoquote=>1);
	unless ($quiet)
	{
	    print "Updated Sample fields (@fields) with values (@values)\n";
	}
    }
    else{
	print "No fields specified\n";
    }
    return $self->api_output(-data=>$updated,-start=>$start,-log=>1,-customized_output=>1);
}

#################################
# Import Concentration data from spec files into the system for a given list of paltes
# 
#
# <snip>
#  Example:
#  
#   $API->import_Concentrations(-plate_ids=>'58016');
#
#  Example:
#   my @plates = ('58016', '58017');
#   $API->import_Concentrations(-plate_ids=>@plates, -equipment_id =>'143');
#
# </snip>
#
###############################
sub import_Concentrations {
###############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $dbc = $self->dbc();
    my $plate_ids = $args{-plate_ids};
    my @plates = Cast_List(-list=>$plate_ids,-to=>'Array');
    my $start = timestamp();

    my $lib_directory = $args{-directory} || "/home/aldente/public/Projects/Human_cDNA/DNA_Quantitations";

    my $equipment = $args{-equipment} || "spec";
    my $equipment_id = $args{-equipment_id};
    my $units = $args{-units} || "ng/ul";
    my $calibration_function = $args{-calibration} || "n/a";

 
    foreach my $plate (@plates){
	if ($equipment =~ /spec/i){
	   
	    #check if concentration data already exists!!

	    my %conc_data = _read_conc_file_spec(-directory=>$lib_directory, -plate=>$plate);
	    my ($plate_exists) = $self->Table_find('ConcentrationRun,Concentrations','FK_Plate__ID', "WHERE ConcentrationRun_ID = FK_ConcentrationRun__ID and FK_Plate__ID=$plate");
	    if ($plate_exists)
	    {
		print "Concentration info for plate $plate is already in the system\n";
	    }
	    else
	    {
		$self->_import_conc(-equipment_id=>$equipment_id, -units=>$units, -plate=>$plate, -equipment=>$equipment, -calibration=>$calibration_function, -conc_data=>\%conc_data);
	    }
	}
    }
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
}

###########################################
# Add to old Clone_Gel table 
#
# Clone_Gel will be replaced by the Lane object
# <snip>
#
# Example:
# 
# my %lane_well;
#
# $lane_well{3}={Well=>'A03', Band_Sizes=>'100,200,300', Clone_Size_Estimate=>'100', Comments=>'no digest'};
# $lane_well{4}={Well=>'A04', Band_Sizes=>'10,20,30', Clone_Size_Estimate=>'10', Comments=>'partial digest'};
# my $clone_gel_added = $API->add_Clone_Gel(-plate_id=>'70001', -lane_well=>\%lane_well);
#
# </snip>
############################################
sub add_Clone_Gel {
################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    
    my $plate_id = $args{-plate_id}; 
    my $gel_id = $args{-gel_id};
    my $lane_well = $args{-lane_well}; ## hashref containing lane - well mapping 
    my $start = timestamp();
 
    if ($plate_id){
	($gel_id) = $self->Table_find('GelRun', 'GelRun_ID', "WHERE FK_Plate__ID=$plate_id");
    }
    unless ($gel_id && $lane_well){
	return 0;
    }

    my %lane_well = ();
    
    if ($lane_well) {%lane_well = %$lane_well;}
    
    my $index = 1;

    my %lane_info;
    
    foreach my $lane_no (keys %lane_well)
    {
	my $well = $lane_well{$lane_no}{'Well'};
	my $band_sizes = $lane_well{$lane_no}{'Band_Sizes'};
	my $clone_size_estimate = $lane_well{$lane_no}{'Clone_Size_Estimate'};
	my $comments = $lane_well{$lane_no}{'Comments'};

	my %ancestry = &alDente::Container::get_Parents(-dbc=>$self->{dbc},-id=>$plate_id,-well=>$well);
	my $sample_id = $ancestry{sample_id};

	$lane_info{$index} = [$gel_id,$sample_id,$well,$lane_no, $band_sizes,$clone_size_estimate,$comments];
	$index++;
    }
    # print Dumper %lane_info;
    my $ok = $Connection->smart_append(-tables=>'Clone_Gel',-fields=>['FK_GelRun__ID','FK_Sample__ID','Well','Lane_Number','Band_Sizes','Clone_Size_Estimate','Comments'],-values=>\%lane_info,-autoquote=>1);
   
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);

}

###########################################
# Add to GelRun table 
#
# 
# <snip>
# Example:
#
# my $add_gel = $API->add_Gel(-plate_id=>'70001', -employee_id =>'164', -status=>'finished', -comments=>'Test add gel');
#
# </snip>
###########################################
sub add_Gel {
###############
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $dbc = $self->{dbc} || $args{-dbc} || $Connection;
    my $start = timestamp();
    
    my $plate_id = $args{-plate_id};

    my $employee_id   = $args{-employee_id};                  ### employee (id) requesting new plate
    my $employee   = $args{-employee};     
    

    if ($employee){
	$employee_id = get_FK_ID($dbc,"Employee_ID","$employee");
    }
    
    my $gel_directory = $args{-gel_directory};
    my $status = $args{-status};
    my $comments = $args{-comments}; ## Optional 
    my $gel_date = &date_time();
    my $agarose_percent = $args{-agarose_percent};
    my $band_leader_version = $args{-bandleader};
    my @fields = ('FK_Plate__ID','Gel_Date','FK_Employee__ID');
    my @values = ($plate_id, $gel_date, $employee_id);

    if ($gel_directory)
    {
	push (@fields, 'Gel_Directory');
	push (@values, $gel_directory);
    }
    if ($comments){
    	push (@fields, 'Gel_Comments');
	push (@values, $comments);
    }
    if ($status){
    	push (@fields, 'Status');
	push (@values, $status);
    }
    if ($agarose_percent)
    {
	push (@fields, 'Agarose_Percent');
	push (@values, $agarose_percent);
    }
    if ($band_leader_version)
    {
	push (@fields, 'Bandleader_Version');
	push (@values, $band_leader_version);
    }
    my $ok = $self->Table_append_array('GelRun',\@fields,\@values,-autoquote=>1);
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
}

###########################################
# Update the Notes field of a specific Primer Plate
# Return: 1 if successful, 0 otherwise
#
# <snip>
# Example:
# 
# my $updated = $API->update_primer_plate(-primer_plate_id=>'70001', -notes=>'LB888-1');
#
# </snip>
###########################################
sub update_primer_plate_notes {
###########################################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $start = timestamp();

    my $primer_plate = $args{-primer_plate_id};   # (Scalar) ID of the primer plate to be modified
    my $notes = $args{-notes};                    # (Scalar) the new notes value

    my $dbc = $self->{dbc};

    my $po = new alDente::Primer(-dbc=>$dbc);
    $po->set_notes(-primer_plate_id=>$primer_plate,-notes=>$notes);
    if ($po->success(0)) {
        return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
    }
    else {
        return $self->api_output(-data=>0,-start=>$start,-log=>1,-customized_output=>1);
    }
}

###########################################
# Update the old GelRun table
#
# <snip>
# Example:
# 
# my $updated = $API->update_Gel(-plate_id=>'70001', -status=>'finished', -comments=>'Test add gel 1');
#
# </snip>
###########################################

sub update_Gel {
##############
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    
    my $plate_id = $args{-plate_id};
    my $gel_id = $args{-gel_id};
    
    my $gel_directory = $args{-gel_directory};
    my $status = $args{-status};
    my $comments = $args{-comments};
    my $agarose_percent = $args{-agarose_percent};
    my $band_leader_version = $args{-bandleader};
    my $start = timestamp();

    if ($plate_id){

	($gel_id) = $self->Table_find('GelRun', 'GelRun_ID', "WHERE FK_Plate__ID=$plate_id");

    }
    unless ($gel_id){
	return 0;
    }

    my $quiet = $args{-quiet} || 0;
    my @fields = ();
    my @values = ();
 

    if ($gel_directory)
    {
	push (@fields, 'Gel_Directory');
	push (@values, $gel_directory);
    }
    if ($comments){
    	push (@fields, 'Gel_Comments');
	push (@values, $comments);
    }
    if ($status){
    	push (@fields, 'Status');
	push (@values, $status);
    }
    if ($agarose_percent)
    {
	push (@fields, 'Agarose_Percent');
	push (@values, $agarose_percent);
    }
    if ($band_leader_version)
    {
	push (@fields, 'Bandleader_Version');
	push (@values, $band_leader_version);
    }

    my $condition = "WHERE GelRun_ID = $gel_id";

    if (int(@fields)){ 
	my $updated = $self->Table_update_array('GelRun',\@fields,\@values,$condition,-autoquote=>1);

	unless ($quiet)
	{
	    print "Updated GelRun $gel_id with fields (@fields) and values (@values)\n";
	}
    }
    else{
	print "No fields specified\n";
    }
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
}

###########################################
# Update the old Clone_Gel table 
#
# GelRun will be replaced by Gel_Plate object
# <snip>
# Example:
# 
# my $updated = $API->update_Clone_Gel(-plate_id=>'70001', -band_sizes=>'10,20,30', -clone_size_estimate=>'10', -comments=>'partial digest', -well=>'A01');
#
# OR
#
# my $updated = $API->update_Clone_Gel(-plate_id=>'70001', -band_sizes=>'10,20,30', -clone_size_estimate=>'10', -comments=>'partial digest', -lane_no=>'1');
# </snip>
###########################################

sub update_Clone_Gel {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    my $start = timestamp();
    
    my $plate_id = $args{-plate_id};
    my $gel_id = $args{-gel_id};
    
    my $well = $args{-well};
    my $lane_no = $args{-lane_no};
    my $comments = $args{-comments};
  
    if ($plate_id){

	($gel_id) = $self->Table_find('GelRun', 'GelRun_ID', "WHERE FK_Plate__ID=$plate_id");

    }
    unless ($gel_id){
	return 0;
    }
    
    my $clone_size_estimate = $args{-clone_size_estimate};
    my $band_sizes = $args{-band_sizes};
  
    my $quiet = $args{-quiet} || 0;
    my @fields = ();
    my @values = ();
    
    if ($band_sizes)
    {
	push (@fields, 'Band_Sizes');
	push (@values, $band_sizes);
    }
    if ($clone_size_estimate){
    	push (@fields, 'Clone_Size_Estimate');
	push (@values, $clone_size_estimate);
    }
    if ($comments){
    	push (@fields, 'Comments');
	push (@values, $comments);
    }
    my $condition = "WHERE FK_GelRun__ID=$gel_id";

    if ($well){
	$condition .= " AND Well = $well";
    }
    elsif ($lane_no){
	$condition .= " AND Lane_Number = $lane_no";
    }
    else{
	print "No wells or lanes specified\n"; 
	return 0;
    }

    if (int(@fields)){ 
	my $updated = $self->Table_update_array('Clone_Gel',\@fields,\@values,$condition,-autoquote=>1);

	unless ($quiet)
	{
	    print "Updated Clone_Gel with fields (@fields) and values (@values)\n";
	}
    }
    else{
	print "No fields specified\n";
    }
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
}

###########################################
# Update the Lane information
#
# <snip>
# Example:
# 
# my $updated = $API->update_Lane(-plate_id=>'70001',-band_size_estimate=>'100', -comments=>'partial digest', -well=>'A01');
#
# OR
#
# my $updated = $API->update_Lane(-plate_id=>'70001',-band_size_estimate=>'100', -comments=>'partial digest', -lane_no=>'1');
# </snip>
###########################################
sub update_Lane {
##############
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    
    my $plate_id = $args{-plate_id};
    my $gel_plate_id = $args{-gel_plate_id};
    
    my $well = $args{-well};
    my $lane_no = $args{-lane_no};
    my $comments = $args{-comments};
    my $start = timestamp();
  
    if ($plate_id){

	($gel_plate_id) = $self->Table_find('GelRun', 'GelRun_ID', "WHERE FK_Plate__ID=$plate_id");

    }
    unless ($gel_plate_id){
	return 0;
    }
    
    my $band_size_estimate = $args{-band_size_estimate};

  
    my $quiet = $args{-quiet} || 0;
    my @fields = ();
    my @values = ();
    
  
    if ($band_size_estimate){
    	push (@fields, 'Band_Size_Estimate');
	push (@values, $band_size_estimate);
    }
    if ($comments){
    	push (@fields, 'Comments');
	push (@values, $comments);
    }
    my $condition = "WHERE FK_GelRun__ID=$gel_plate_id";

    if ($well){
	$condition .= " AND Well = $well";
    }
    elsif ($lane_no){
	$condition .= " AND Lane_Number = $lane_no";
    }
    else{
	print "No wells or lanes specified\n"; 
	return 0;
    }

    if (int(@fields)){ 
	my $updated = $self->Table_update_array('Lane',\@fields,\@values,$condition,-autoquote=>1);

	unless ($quiet)
	{
	    print "Updated Lane with fields (@fields) and values (@values)\n";
	}
    }
    else{
	print "No fields specified\n";
    }
    return $self->api_output(-data=>1,-start=>$start,-log=>1,-customized_output=>1);
}

##############################
# public_functions           #
##############################

######################
sub progress_tracker {
######################
    my $index = shift;
    my $number = shift;
    my $min    = shift || 1000;
    my $width  = shift || 100;

    if ($number < $min) { return; }

    my $output;
    unless ($index) { $output .= "Start" . ' 'x92 . "End\n"; }
    if ( int($index/int($number/$width)) == $index/int($number/$width) ) { $output .= "."; }
    return $output;
}

###########################
# Ensures all arguments are in proper '-key => value' format
#
#
# Return: Message if there are any problems (otherwise returns 0)
####################
sub check_input_errors {
####################
    my %args = @_;
    my $log  = $args{-log};                  # log this call in the specified log file...    
    my $username = $args{-user} || '';
    my $object   = $args{-object};
    my $dbc      = $args{-dbc} || $Connection;

    my $errors;

    unless ($username) { 
	$username = `whoami`;
	chomp $username;
    }

    if ($log) { 
        &log_usage(-log=>$log,-user=>$username,-message=>"DBC:$dbc\n",-data=>\%args,-object=>$object,-include=>'source');
    }
    
    ## Ensure arguments are in proper format ##
    foreach my $key (keys %args) {
	unless ($key =~/^\-/) {
	    $errors .= "$key should be in form '-$key=>\$value'; (did you forget the '-' again ?)...";
	}
    }

    return $errors;
}

##############################
# private_methods            #
##############################

###########################################
# Import the Concentrations 
# <snip> 
# Example:
#
# $self->_import_conc(-units=>$units, -plate=>$plate, -equipment_id=>$equipment_id, -equipment=>$equipment, -calibration=>$calibration_function, -conc_data=>\%conc_data);
# </snip>
# Return: 1 on success
###########################################
sub _import_conc{
    my $self=shift;

    my %args = &filter_input(\@_);
    
    my $plate_id = $args{-plate};           #  Plate ID
   
    my $units = $args{-units};              #  Units ie. (ug/uL)
    my $equipment = $args{-equipment};      #  Equipment
    my $equipment_id = $args{-equipment_id}; #  Equipment ID
    my $calibration = $args{-calibration};  #  Calibration for the Run
    
    my $date_imported = &date_time();
    
    my $conc_data = $args{-conc_data};      #  Concentration Data (hash)
 
    my $dbc = $self->dbc();
    
    # Add Concentration Run
    my %conc_data;
    
    if ($conc_data) {%conc_data = %$conc_data;}

    my $Concentration_Run = SDB::DB_Object->new(-dbc=>$dbc,-tables=>'ConcentrationRun');
    my @run_fields = ('FK_Plate__ID', 'FK_Equipment__ID', 'DateTime', 'CalibrationFunction');
    my @run_values = ($plate_id, $equipment_id, $date_imported,$calibration);
    $Concentration_Run->values(-fields=>\@run_fields,-values=>\@run_values);

    $Concentration_Run->insert();
    my ($conc_run_id) = @{$Concentration_Run->newids('ConcentrationRun')};
    
    # Add Concentration Data

    my @conc_fields = ('FK_ConcentrationRun__ID','Well','Concentration', 'Measurement', 'Units', 'FK_Sample__ID');
	
    my ($orig_plate) = $self->Table_find('Plate','FKOriginal_Plate__ID', "WHERE Plate_ID=$plate_id");	
    my @plate_samples = $self->Table_find('Plate_Sample','FK_Sample__ID, Well', "WHERE FKOriginal_Plate__ID=$orig_plate");

 
    foreach my $location (sort{$a cmp $b} keys %$conc_data) {
	my %ancestry = &alDente::Container::get_Parents(-dbc=>$dbc,-id=>$plate_id,-well=>$location);
	my $sample_id = $ancestry{sample_id};
	my @conc_values = ($conc_run_id,$location, $conc_data{$location},'n/a', $units, $sample_id); 
     	my $OK = $self->Table_append_array('Concentrations',\@conc_fields,\@conc_values,-autoquote=>1);
    }		       

    return 1;

}


##############################
sub get_Atomic_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    return $self-> get_read_data (%args);
}

##############################
# private_functions          #
##############################

#############################
# Read concentrations from a file for the spectrophotometer
# <snip>
#  Example:
#  
# my %conc_data = _read_conc_file_spec(-directory=>$lib_directory, -plate=>$plate);
#
# </snip>
# Return: hash of concentrations with key values of wells
#############################
sub _read_conc_file_spec{

    my %args = &filter_input(\@_);

    my $lib_directory = $args{-directory};  # directory the concentration file resides
    my $plate_id = $args{-plate};           # Plate ID    
    my @files = <$lib_directory/*$plate_id*[TXTtxt]>;

    my $file_name = $files[0];

    open(FILE,$file_name) or die "Cannot open file: $file_name";
    my $concentrations = 0;
    my @column_values;
    my %filedata;
    while(<FILE>){
	# updated to deal with 50/50 dilutions and also 10/90 dilutions of the spectrophotometer.
	if ($_=~m/^\[Plate:\sug.*/ || $_=~m/^\[Plate:\s?10\/90\s?ug.*/){
	    $concentrations = 1;
	}
	if ($concentrations == 0){
	    next;
	}else{
	  if ($_=~m/^([A-H])\s+(\-*\d.*)/){ # Changed by MG to account for negatives
		chomp($_);
		my $row = $1;
		my $col = $2;
	@column_values = split(/\t/, chomp_edge_whitespace($col));
		my $z = 0;
		foreach my $conc (@column_values){
		    $z++;
		    $conc =~m/(\-*)([0-9\.]+)/;
		    if ($1 =~ /\-/){
		      $conc = 0;
		      #print " negative conc: $2, set to $conc\n";
		    }else{
		      $conc = $2;
		    }
		    my $col_count = sprintf "%.2d", $z;
		    my $location = $row.$col_count;
		    $filedata{$location}=$conc;
		}		    
	    }
	}
    }
    close FILE;
    return %filedata;
}

#############################
sub _convert_Wildcard_or_List {
###########################
    my %args = filter_input(\@_);
    my $string = $args{-string};
    my $field = $args{-field};
    my $prefix = $args{-prefix} || '';
 
    $string = Cast_List(-list=>$string,-to=>'string',-autoquote=>1);
    my $extra_condition .= '';
    if ($string =~/,/) { 
	$extra_condition .= "$prefix $field in ($string)";
	if ($string =~/\*/) { Message("Warning: cannot handle BOTH list and wildcard simultaneously (using list)"); }
    } else {
	$extra_condition .= "$prefix $field like $string";
    }
    
    return $extra_condition;
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

Ran Guin

=head1 CREATED <UPLINK>

2003-11-13

=head1 REVISION <UPLINK>

$Id: Sequencing_API.pm,v 1.341 2004/12/03 20:05:20 rguin Exp $ (Release: $Name:  $)

=cut


return 1;
