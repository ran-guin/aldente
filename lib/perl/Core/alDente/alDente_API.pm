################################################################################
# alDente_API.pm
#
# This module handles data access functions for general alDente objects
#
# More application specific API's may also be available that inherit the alDente_API object,
# but which may access data more specific to the needs of the application.
# (eg. the Sequencing/Sequencing_API module accesses information pertaining to sequence data)
#
###############################################################################
package alDente::alDente_API;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

alDente_API.pm - This module handles general access to records associated with standard alDente objects

=head1 SYNOPSIS <UPLINK>
 
 #### Example of Usage ####
    
 ## Connect to the database (you may define the parameters early on and only connect later if necessary) ##
 my $API = alDente_API->new(-dbase=>'sequence',-host=>'lims-dbm',-user=>'viewer',-password=>$pass);
 $API->connect();

 my $data    = $API->get_sample_data(-sample_id=>$sample);
 my $data    = $API->get_source_data(-source_id=>$source_id);
 my $data    = $API->get_run_data(-study=>7,-since=>'2005-10-20 00:29:00',-until=>'2005-10-20 05:00:00',-include=>'rejected');
 my $history = $API->get_library_changes(-study=>7,-quiet=>1);

 ## get number of plates generated from 'MGC01' library... 
 my $plate_count = $API->get_plate_count(-library=>'MGC01');

 ## get a variety of info for libraries in a project (return data into a hash with library names as keys).
 my $data = $API->get_library_data(-project_id=>6,-key=>'library');

 #########################
 ## other useful calls: ##
 #########################

  ## list available fields (useful if you do not know what fields are available)
  my $data = $API->get_library_data(-list_fields=>1);

  ## debug option (shows you the query used without executing it)
  my $data = $API->get_run_data(-debug=>1);



 #################################
 Using the API as a web service:
 #################################
    Authentication:  LDAP
    Username: LDAP username
    Password: LDAP password
        (ie same password for JIRA)

        <b>PERL Example:</b>
        
        use XMLRPC::Lite;

        my $web_service_client =  XMLRPC::Lite ->proxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl");


        ## Creating a login object 

        my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims'})-> result;


        ## Calling an API method:

        my $data = $web_service_client->call('lims_web_service.&lt;API_method_name&gt;', &lt;login_object&gt;, &lt;api arguments as HASHREF&gt; );

for example:

        my $data = $web_service_client->call(
            'lims_web_service.get_run_data',$valid_login
            ,{ 'library' => 'mylib' }
        ) -> result;
        
        print Dumper $data;



        <b>Python Example:</b>
        
        #!/usr/local/bin/python

        from xmlrpclib import ServerProxy

        limsy = ServerProxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl")

        login = limsy.lims_web_service.login( {'username':'testlims','password':'testlims'} )

        data = limsy.lims_web_service.get_run_data(login,{'library':'mylib' })

        print data



        <b>Java Example:</b>

        import java.net.MalformedURLException;
        import java.net.URL;
        import java.util.*;

        import org.apache.xmlrpc.XmlRpcException;
        import org.apache.xmlrpc.client.XmlRpcClient;
        import org.apache.xmlrpc.client.XmlRpcClientConfigImpl;
        import org.apache.xmlrpc.client.XmlRpcCommonsTransportFactory;

        .........
        try {
                // create a configuration
                XmlRpcClientConfigImpl config = new XmlRpcClientConfigImpl();
                config.setServerURL(new URL("http://lims02.bcgsc.ca/SDB/cgi-bin/Web_Service.pl"));
                config.setBasicUserName("testlims");
                config.setBasicPassword("testlims");
      
                // create a client and set configuration
                XmlRpcClient client = new XmlRpcClient();
                client.setTransportFactory(new XmlRpcCommonsTransportFactory(client));
                client.setConfig(config);
      
                // connect to retrieve loginResult
                Hashtable login = new Hashtable();
                login.put("username", "testlims");
                login.put("password", "testlims");
                Vector logparams = new Vector();
                logparams.add(login);
                // use HashMap so that you can pass it to the next execute call
                HashMap loginResult = new HashMap();
                loginResult =(HashMap)client.execute("lims_web_service.login",logparams);    
   
                // connect to retrieve data
                Vector params = new Vector();
                params.add(loginResult);
      
                Hashtable hashArg = new Hashtable();
                hashArg.put("-fields",  "library,plate_number");
                hashArg.put("-condition", "run_id=58663");
      
                params.add(hashArg);
      
                HashMap result = new HashMap();
                result = (HashMap)(client.execute("lims_web_service.get_run_data",params));

                // step through the result to get the value
                Set keySet = result.keySet();
                Iterator it = keySet.iterator();
                while (it.hasNext() == true){
                    String key = (String)(it.next());

                    if (result.containsKey(key) == true){
                        Object[] value = (Object[])(result.get(key));
                        for (int i = 0; i &lt; value.length; i++){
                             System.out.println(key + "[" + i + "]: " + value[i].toString());
                        }

                    }
                }
          }catch (MalformedURLException e) {
                e.printStackTrace();
          } catch (XmlRpcException e) {
                e.printStackTrace();
          }
      ............


 NOTE:  The api arguments passed into the web service are equivalent to those passed directly to the API


=head1 DESCRIPTION <UPLINK>

=for html
This module handles custom data access functions for the sequencing plug-in<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter SDB::DBIO);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    connect_to_DB
    map_to_fields
);
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use JSON;
use Benchmark;

#use AutoLoader;
use Carp;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;
use RGTools::RGmath;
use alDente::Run;
use alDente::SDB_Defaults qw($project_dir %object_aliases);
use Sequencing::Tools qw(SQL_phred);
use Sequencing::Sequencing_Library;
use alDente::Library;
use alDente::Container;
use alDente::Well;
use alDente::ReArray;
## use alDente::Clone_Sample;
use alDente::Employee;
use alDente::Validation;
use alDente::Config;

##############################
# global_vars                #
##############################
##############################
# custom_modules_ref #
##############################
##############################
# global_vars                #
##############################
use vars qw($AUTOLOAD $testing $Security $project_dir $Web_log_directory %Aliases %object_aliases $Connection %Attr_Aliases);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $Q20 = SQL_phred(20);
my $Q30 = SQL_phred(30);
my $Q40 = SQL_phred(40);

$Aliases{Run}{sequenced_plate}                    = "Run.FK_Plate__ID";
$Aliases{Run}{run_name}                           = "Run.Run_Directory";
$Aliases{Run}{run_display_name}                   = "Run.Run_Directory";
$Aliases{Run}{subdirectory}                       = "Run.Run_Directory";
$Aliases{Run}{earliest_run}                       = "Min(Run.Run_DateTime)";
$Aliases{Run}{latest_run}                         = "Max(Run.Run_DateTime)";
$Aliases{Run}{run_status}                         = "Run.Run_Status";
$Aliases{Run}{validation}                         = "Run.Run_Validation";
$Aliases{Run}{billable}                           = "Run.Billable";
$Aliases{Run}{test_status}                        = "Run.Run_Test_Status";
$Aliases{Run}{run_QC_status}                      = "Run.QC_Status";
$Aliases{Run}{run_qc_alert}                       = "Run_Alert.Alert_Reason";
$Aliases{Run}{run_qc_alert_notes}                 = "Run_Alert.Alert_Reason_Notes";
$Aliases{Run}{run_qc_alert_id}                    = "Run_Alert.Alert_Reason_ID";
$Aliases{Multiplex_Run}{multiplex_qc_alert_id}    = "Multiplex_Run_Alert.Alert_Reason_ID";
$Aliases{Multiplex_Run}{multiplex_qc_alert}       = "Multiplex_Run_Alert.Alert_Reason";
$Aliases{Multiplex_Run}{multiplex_qc_alert_notes} = "Multiplex_Run_Alert.Alert_Reason_Notes";

$Aliases{SolexaRun}{flowcell_code}                                  = "Flowcell.Flowcell_Code";
$Aliases{SolexaRun}{grafted_datetime}                               = "Flowcell.Grafted_Datetime";
$Aliases{SolexaRun}{lot_number}                                     = "Flowcell.Lot_Number";
$Aliases{SolexaRun}{run_tray_id}                                    = "Flowcell.FK_Tray__ID";
$Aliases{SolexaRun}{lane}                                           = "SolexaRun.Lane";
$Aliases{SolexaRun}{sample_name}                                    = "Sample.Sample_Name";
$Aliases{SolexaRun}{plate_id}                                       = "Plate.Plate_ID";
$Aliases{SolexaRun}{flowcell_id}                                    = "Flowcell.Flowcell_ID";
$Aliases{SolexaRun}{cycles}                                         = "SolexaRun.Cycles";
$Aliases{SolexaRun}{solexarun_type}                                 = "SolexaRun.SolexaRun_Type";
$Aliases{SolexaRun}{solexarun_mode}                                 = "SolexaRun.SolexaRun_Mode";
$Aliases{SolexaRun}{solexarun_finished}                             = "SolexaRun.SolexaRun_Finished";
$Aliases{SolexaRun}{solexa_end_read_type}                           = "Solexa_Read.End_Read_Type";
$Aliases{SolexaRun}{solexa_tiles_analyzed}                          = "Solexa_Read.Tiles_Analyzed";
$Aliases{SolexaRun}{solexa_raw_clusters}                            = "Solexa_Read.Raw_Clusters";
$Aliases{SolexaRun}{solexa_pf_clusters_percent}                     = "Solexa_Read.PF_Clusters_Percent";
$Aliases{SolexaRun}{solexa_lane_yield_kb}                           = "Solexa_Read.Lane_Yield_KB";
$Aliases{SolexaRun}{solexa_pf_clusters}                             = "Solexa_Read.PF_Clusters";
$Aliases{SolexaRun}{submission_experiment_paired_2nd_base_coord}    = "SolexaRun.Cycles + 1";
$Aliases{SolexaRun}{submission_experiment_number_of_reads_per_spot} = "CASE WHEN (SolexaRun.SolexaRun_Type ='Single') THEN ('1') WHEN (SolexaRun.SolexaRun_Type ='Paired') THEN ('2') END";
$Aliases{SolexaRun}{multiplex_run}                                  = "'View Multiplex Info'";
$Aliases{SolexaRun}{basecalls_folder}                               = "SolexaRun.Basecalls_Folder";
$Aliases{SolexaRun}{phix_spikein_solution_id}                       = "SolexaRun.FKPhix_SpikeIn_Solution__ID";
$Aliases{SolexaRun}{phix_spikein_percentage}                        = "SolexaRun.SpikeIn_Percentage";
$Aliases{Solexa_Read}{solexa_phasing}                               = "Solexa_Read.Phasing";
$Aliases{Solexa_Read}{solexa_prephasing}                            = "Solexa_Read.Prephasing";
$Aliases{Solexa_Read}{solexa_read_length}                           = "Solexa_Read.Read_Length";
$Aliases{Solexa_Read}{number_reads}                                 = "Solexa_Read.Number_Reads";
$Aliases{Solexa_Read}{bwa_analysis_dir}                             = "CONCAT('BWA_',Date(Run_Analysis_Started))";
$Aliases{Solexa_Read}{bismark_analysis_dir}                         = "CONCAT('BISMARK_',Date(Run_Analysis_Started))";
$Aliases{Solexa_Read}{illumina_pipeline}                            = "Analysis_Pipeline.Pipeline_Name";
$Aliases{Solexa_Read}{illumina_pipeline_id}                         = "Solexa_Read.FKAnalysis_Pipeline__ID";
$Aliases{Solexa_Read}{pf_q20_percent}                               = "Solexa_Read.PF_Q20_Percent";
$Aliases{Solexa_Read}{pf_q30_percent}                               = "Solexa_Read.PF_Q30_Percent";
$Aliases{Solexa_Read}{number_mismatched_reads}                      = "Solexa_Read.Number_Mismatched_Reads";
$Aliases{Genome}{reference_genome_name}                             = "Genome.Genome_Name";
$Aliases{Genome}{reference_genome_path}                             = "Genome.Genome_Path";
$Aliases{Genome}{reference_genome_id}                               = "Genome.Genome_ID";
$Aliases{Genome}{taxonomy_id}                                       = "Genome.FK_Taxonomy__ID";
$Aliases{Genome}{reference_genome_url}                              = "Genome.Genome_URL";
$Aliases{Genome}{reference_genome_alias}                            = "Genome.Genome_Alias";
$Aliases{Genome}{reference_genome_type}                             = "Genome.Genome_Type";
$Aliases{Genome}{reference_genome_status}                           = "Genome.Genome_Status";
$Aliases{Genome}{parent_reference_genome_id}                        = "Genome.FKParent_Genome__ID";
$Aliases{Genome}{reference_sort_order}                              = "Genome.Genome_Reference_Sort_Order";
$Aliases{Genome}{default_genome}                                    = "Genome.Default_Genome";
$Aliases{Assembly_Sequence}{chromosomes}                            = "group_concat(distinct(Assembly_Sequence.Reference_Label) order by Reference_Label asc)";
$Aliases{Assembly_Sequence}{assembly_accessions}                    = "group_concat(distinct(Assembly_Sequence.Unique_Identifier) order by Reference_Label asc)";
$Aliases{Run_Analysis}{run_analysis_started}                        = "Run_Analysis.Run_Analysis_Started";
$Aliases{Run_Analysis}{run_analysis_finished}                       = "Run_Analysis.Run_Analysis_Finished";
$Aliases{Run_Analysis}{run_analysis_current}                        = "Run_Analysis.Current_Analysis";
$Aliases{Run_Analysis}{run_analysis_sample_id}                      = "Run_Analysis.FK_Sample__ID";
$Aliases{Run_Analysis}{parent_run_analysis_id}                      = "Run_Analysis.FKParent_Run_Analysis__ID";
$Aliases{Run_Analysis}{run_analysis_test_mode}                      = "Run_Analysis.Run_Analysis_Test_Mode";
$Aliases{Run_Analysis}{run_analysis_type}                           = "Run_Analysis.Run_Analysis_Type";
$Aliases{Run_Analysis}{run_analysis_status}                         = "Run_Analysis.Run_Analysis_Status";
$Aliases{Run_Analysis}{run_analysis_comments}                       = "Run_Analysis.Run_Analysis_Comments";
$Aliases{Run_Analysis}{run_analysis_pipeline_id}                    = "Run_Analysis.FKAnalysis_Pipeline__ID";
$Aliases{Run_Analysis}{run_analysis_md5_checksum_1}                 = "Run_Analysis.Md5_Checksum_1";
$Aliases{Run_Analysis}{run_analysis_md5_checksum_2}                 = "Run_Analysis.Md5_Checksum_2";
$Aliases{Run_Analysis}{run_analysis_batch_id}                       = "Run_Analysis.FK_Run_Analysis_Batch__ID";
$Aliases{Solexa_Run_Analysis}{solexa_reference_genome_id}           = "Solexa_Run_Analysis.FK_Genome__ID";
$Aliases{Solexa_Run_Analysis}{solexa_read1_aligned_length}          = "Solexa_Run_Analysis.Read1_Aligned_Length";
$Aliases{Solexa_Run_Analysis}{solexa_read2_aligned_length}          = "Solexa_Run_Analysis.Read2_Aligned_Length";
$Aliases{SOLID_Run_Analysis}{solid_reference_genome_id}             = "SOLID_Run_Analysis.FK_Genome__ID";
$Aliases{SOLID_Run_Analysis}{solid_end_read_type}                   = "SOLID_Run_Analysis.End_Read_Type";
$Aliases{SOLID_Run_Analysis}{solid_number_reads}                    = "SOLID_Run_Analysis.Number_Reads";
$Aliases{SOLID_Run_Analysis}{solid_zero_missmatch}                  = "SOLID_Run_Analysis.Zero_Missmatch";
$Aliases{SOLID_Run_Analysis}{solid_megabases_of_coverage}           = "SOLID_Run_Analysis.Megabases_Of_Coverage";
$Aliases{SOLID_Run_Analysis}{solid_reads_per_start}                 = "SOLID_Run_Analysis.Reads_Per_Start";
$Aliases{SOLID_Run_Analysis}{solid_number_aligned_reads}            = "SOLID_Run_Analysis.Number_Aligned_Reads";
$Aliases{SOLID_Run_Analysis}{bioscope_analysis_dir}                 = "CONCAT('bioscope_',Date(Run_Analysis_Started))";

$Aliases{Multiplex_Run}{multiplex_adapter_index}                       = "Multiplex_Run.Adapter_Index";
$Aliases{Multiplex_Run_Analysis}{multiplex_solexa_reference_genome_id} = "Multiplex_Solexa_Run_Analysis.FK_Genome__ID";
$Aliases{Multiplex_Run_Analysis}{multiplex_solexa_number_reads}        = "Multiplex_Solexa_Run_Analysis.Number_Reads";
$Aliases{Multiplex_Run_Analysis}{multiplex_sample_id}                  = "Multiplex_Run_Analysis.FK_Sample__ID";
$Aliases{Multiplex_Run_Analysis}{multiplex_analysis_sample}            = "Multiplex_Run_Analysis.FK_Sample__ID";
$Aliases{Multiplex_Run_Analysis}{multiplex_analysis_test_mode}         = "Multiplex_Run_Analysis.Multiplex_Run_Analysis_Test_Mode";
$Aliases{Multiplex_Run_Analysis}{multiplex_analysis_md5_checksum_1}    = "Multiplex_Run_Analysis.Md5_Checksum_1";
$Aliases{Multiplex_Run_Analysis}{multiplex_analysis_md5_checksum_2}    = "Multiplex_Run_Analysis.Md5_Checksum_2";
$Aliases{Multiplex_Run_Analysis}{multiplex_analysis_adapter_index}     = "Multiplex_Run_Analysis.Adapter_Index";
$Aliases{Multiplex_Run}{multiplex_run_qc_status}                       = "Multiplex_Run.Multiplex_Run_QC_Status";
$Aliases{Multiplex_Run}{multiplex_run_id}                              = "Multiplex_Run.Multiplex_Run_ID";

$Aliases{LS_454Run}{cycles} = "LS_454Run.Cycles";

$Aliases{Analysis_Software}{analysis_software_id}      = "Analysis_Software.Analysis_Software_ID";
$Aliases{Analysis_Software}{analysis_software_name}    = "Analysis_Software.Analysis_Software_Name";
$Aliases{Analysis_Software}{analysis_software_alias}   = "Analysis_Software.Analysis_Software_Alias";
$Aliases{Analysis_Software}{analysis_software_version} = "Analysis_Software.Analysis_Software_Version";

$Aliases{SequenceRun}{Average_Q20}              = "Sum(SequenceAnalysis.Q20total)/Sum(Wells)";
$Aliases{SequenceRun}{Total_Q20}                = "Sum(SequenceAnalysis.Q20total)";
$Aliases{SequenceRun}{Average_QL}               = "Sum(SequenceAnalysis.QLtotal)/Sum(Wells)";
$Aliases{SequenceRun}{Total_QL}                 = "Sum(SequenceAnalysis.QLtotal)";
$Aliases{SequenceRun}{Average_SL}               = "Sum(SequenceAnalysis.SLtotal)/Sum(Wells)";
$Aliases{SequenceRun}{Total_SL}                 = "Sum(SequenceAnalysis.SLtotal)";
$Aliases{SequenceRun}{Average_V}                = "Sum(SequenceAnalysis.Vtotal)/Sum(Wells)";
$Aliases{SequenceRun}{Total_V}                  = "Sum(SequenceAnalysis.Vtotal)";
$Aliases{SequenceRun}{Total_QV}                 = "Sum(SequenceAnalysis.QVTotal)";
$Aliases{SequenceRun}{Average_Length}           = "Sum(SequenceAnalysis.SLtotal)/Sum(Wells)";
$Aliases{SequenceRun}{Total_Length}             = "Sum(SequenceAnalysis.SLtotal)";
$Aliases{SequenceRun}{Maximum_Q20}              = "Max(SequenceAnalysis.Q20max)";
$Aliases{SequenceRun}{Average_Trimmed_Length}   = "Sum(SequenceAnalysis.QLTotal - QVtotal)/Sum(Wells)";
$Aliases{SequenceRun}{Total_Trimmed_Length}     = "Sum(SequenceAnalysis.QLTotal - QVtotal)";
$Aliases{SequenceRun}{successful_reads}         = "Sum(SequenceAnalysis.successful_reads)";                           ## QL > 100
$Aliases{SequenceRun}{trimmed_successful_reads} = "Sum(SequenceAnalysis.trimmed_successful_reads)";                   ## QL - VQ > 100
$Aliases{SequenceRun}{success_rate}             = "Sum(SequenceAnalysis.successful_reads)/Sum(Wells)*100";            ## % with QL > 100 (excluding No grows, unused wells)
$Aliases{SequenceRun}{trimmed_success_rate}     = "Sum(SequenceAnalysis.trimmed_successful_reads)/Sum(Wells)*100";    ## % with QL > 100 (excluding No grows, unused wells)
$Aliases{SequenceRun}{reads}                    = "Sum(SequenceAnalysis.AllReads)";
$Aliases{SequenceRun}{good_reads}               = "Sum(SequenceAnalysis.Wells)";
$Aliases{SequenceRun}{no_grows}                 = "Sum(SequenceAnalysis.NGs)";
$Aliases{SequenceRun}{primer}                   = "Primer.Primer_Name";
$Aliases{SequenceRun}{mask_restriction_site}    = "SequenceAnalysis.mask_restriction_site";
$Aliases{SequenceRun}{analysis_time}            = "SequenceAnalysis_DateTime";

$Aliases{Run}{run_id}                        = "Run.Run_ID";
$Aliases{Run}{run_type}                      = "Run.Run_Type";
$Aliases{Run}{sequencer}                     = "RunBatch.FK_Equipment__ID";
$Aliases{Run}{run_time}                      = "Run_DateTime";
$Aliases{Run}{month}                         = "MONTHNAME(Run.Run_DateTime)";
$Aliases{Run}{year}                          = "Year(Run_DateTime)";
$Aliases{Run}{run_comments}                  = "CASE WHEN Length(RunBatch.RunBatch_Comments) > 0 " . "THEN concat(RunBatch.RunBatch_Comments,'; ',Run.Run_Comments) " . "ELSE Run.Run_Comments END";
$Aliases{Run}{full_run_path}                 = "concat('$Configs{project_dir}','/',Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData/',Run.Run_Directory)";
$Aliases{Run}{run_time_xml_datetime_format}  = "DATE_FORMAT(CONVERT_TZ(Run_DateTime,'SYSTEM','+00:00'), '%Y-%m-%dT%TZ')";
$Aliases{Run}{BAC_trace_submission_run_date} = "Left(Run_DateTime,10)";

# aliases below use SequenceAnalysis
$Aliases{Run}{runs}                  = "count(DISTINCT Run_ID)";
$Aliases{Run}{chemistry_code}        = "Plate.FK_Branch__Code";
$Aliases{Run}{unique_samples}        = "count(DISTINCT Clone_Sequence.FK_Sample__ID)";
$Aliases{Run}{unique_sample_reads}   = "count(DISTINCT concat(Clone_Sequence.FK_Sample__ID,Plate.FK_Branch__Code))";
$Aliases{SequenceRun}{unique_wells}  = "count(DISTINCT concat(Library_Name,Plate_Number,Parent_Quadrant,Clone_Sequence.Well))";
$Aliases{SequenceRun}{unique_reads}  = "count(DISTINCT concat(Library_Name,Plate_Number,Parent_Quadrant,Clone_Sequence.Well,Plate.FK_Branch__Code))";    ## unique clones + chemistry
$Aliases{Plate}{history}             = "'View Plate History'";
$Aliases{Plate}{scheduled_pipelines} = "'Scheduled Pipelines'";
$Aliases{Plate}{work_request}        = "Plate.FK_Work_Request__ID";
$Aliases{Project}{project}           = "Project.Project_Name";
$Aliases{Project}{project_id}        = "Project.Project_ID";
$Aliases{Project}{project_path}      = "Project.Project_Path";
$Aliases{Project}{project_started}   = "Project.Project_Initiated";
$Aliases{Project}{project_completed} = "Project.Project_Completed";
$Aliases{Project}{project_status}    = "Project.Project_Status";

$Aliases{Library}{data_path} = "concat('$Configs{project_dir}','/',Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData')";

$Aliases{Study}{study}             = "Study.Study_Name";
$Aliases{Study}{study_id}          = "Study.Study_ID";
$Aliases{Study}{study_description} = "Study.Study_Description";

$Aliases{Source}{original_contact}              = "Original_Contact.Contact_Name";
$Aliases{Source}{src_library} = "Library.Library_Name";
$Aliases{Source}{original_contact_organization} = "Original_Organization.Organization_Name";

$Aliases{Contact}{original_contact_position} = "Original_Contact.Position";
$Aliases{Contact}{original_contact_phone}    = "Original_Contact.Contact_Phone";
$Aliases{Contact}{original_contact_email}    = "Original_Contact.Contact_Email";
$Aliases{Contact}{contact}                   = "Contact.Contact_Name";
$Aliases{Contact}{contact_position}          = "Contact.Position";
$Aliases{Contact}{contact_phone}             = "Contact.Contact_Phone";
$Aliases{Contact}{contact_email}             = "Contact.Contact_Email";

$Aliases{Organization}{organization}         = "Organization.Organization_Name";
$Aliases{Organization}{contact_organization} = "Organization.Organization_Name";
$Aliases{Organization}{organization_phone}   = "Organization.Phone";

$Aliases{Library}{description}             = "Library.Library_Description";
$Aliases{Library}{library}                 = "Library.Library_Name";
$Aliases{Library}{library_source}          = "Library.Library_Source";
$Aliases{Library}{library_started}         = "Library.Library_Obtained_Date";
$Aliases{Library}{library_completed}       = "Library.Library_Completion_Date";
$Aliases{Library}{library_type}            = "Library.Library_Type";
$Aliases{Library}{library_source_name}     = "Library.External_Library_Name";
$Aliases{Library}{external_library_name}   = "Library.External_Library_Name";
$Aliases{Library}{library_format}          = "Vector_Based_Library.Vector_Based_Library_Format";
$Aliases{Library}{vector}                  = "Vector_Type.Vector_Type_Name";
$Aliases{Library}{sequencing_library_type} = "Vector_Based_Library.Vector_Based_Library_Type";
$Aliases{Library}{group_name}              = "Grp.Grp_Name";

## SAGE Stuff
$Aliases{Library}{SAGE_library_type} = "SAGE_Library.SAGE_Library_Type";
$Aliases{Library}{anchoring_enzyme}  = "Anchoring_Enzyme.Enzyme_Name";
$Aliases{Library}{tagging_enzyme}    = "Tagging_Enzyme.Enzyme_Name";
$Aliases{Library}{tags_requested}    = "SAGE_Library.Tags_Requested";
$Aliases{Library}{SAGE_type}         = "SAGE_Library.SAGE_Library_Type";
$Aliases{Library}{primer}            = "Primer.Primer_Name";

#$Aliases{Library}{direction} = "LibraryApplication.Direction";
$Aliases{Library}{direction}           = "SequenceRun.Run_Direction";
$Aliases{Library}{library_format}      = "Vector_Based_Library.Vector_Based_Library_Format";
$Aliases{Library}{library_status}      = "Library.Library_Status";
$Aliases{Library}{library_description} = "Library.Library_Description";
$Aliases{Library}{starting_amount_ng}  = "SAGE_Library.Starting_RNA_DNA_Amnt_ng";

$Aliases{Library}{library_goal}            = "GROUP_CONCAT(Library_Goal.Goal_Name)";
$Aliases{Library}{library_goal_target}     = "GROUP_CONCAT(Library_Work_Request.Goal_Target)";
$Aliases{Library}{library_goal_target_sum} = "SUM(Library_Work_Request.Goal_Target)";
$Aliases{Funding}{project_funding_source}  = "GROUP_CONCAT(Library_Funding.Funding_Source)";
$Aliases{Library}{library_funding}         = "GROUP_CONCAT(Library_Funding.Funding_Code)";
$Aliases{Project}{project_funding}         = "GROUP_CONCAT(Library_Funding.Funding_Code)";

$Aliases{Library}{distinct_library_goal}           = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Library_Goal.Goal_Name)))";
$Aliases{Library}{distinct_library_goal_target}    = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Library_Work_Request.Goal_Target)))";
$Aliases{Funding}{distinct_project_funding_source} = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Library_Funding.Funding_Source)))";
$Aliases{Library}{distinct_library_funding}        = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Library_Funding.Funding_Code)))";
$Aliases{Project}{distinct_project_funding}        = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Library_Funding.Funding_Code)))";

$Aliases{Funding}{funding_source} = "Library_Funding.Funding_Source";
$Aliases{Funding}{funding_code}   = "Library_Funding.Funding_Code";

$Aliases{Plate}{plate_funding}     = 'GROUP_CONCAT(Plate_Funding.Funding_Code)';
$Aliases{Plate}{plate_goal}        = 'GROUP_CONCAT(Plate_Goal.Goal_Name)';
$Aliases{Plate}{plate_goal_target} = 'GROUP_CONCAT(Plate_Work_Request.Goal_Target)';

$Aliases{Plate}{distinct_plate_funding}     = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Plate_Funding.Funding_Code)))";
$Aliases{Plate}{distinct_plate_goal}        = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Plate_Goal.Goal_Name)))";
$Aliases{Plate}{distinct_plate_goal_target} = "GROUP_CONCAT(DISTINCT(CONCAT(Work_Request_ID, ': ', Plate_Work_Request.Goal_Target)))";

$Aliases{Original_Source}{original_source_name} = "Original_Source.Original_Source_Name";
$Aliases{Original_Source}{original_source_id}   = 'Original_Source.Original_Source_ID';

# $Aliases{Original_Source}{organism            } = "Organism.Organism_Name";
$Aliases{Original_Source}{organism}      = "Taxonomy.Taxonomy_Name";
$Aliases{Original_Source}{taxonomy_id}   = "Taxonomy.Taxonomy_ID";
$Aliases{Original_Source}{common_name}   = "Taxonomy.Common_Name";
$Aliases{Original_Source}{taxonomy_name} = "Taxonomy.Taxonomy_Name";
$Aliases{Original_Source}{species}       = "Taxonomy.Taxonomy_Name";
$Aliases{Original_Source}{sub_species}   = "''";

$Aliases{Original_Source}{original_source_description} = "Original_Source.Description";
$Aliases{Original_Source}{pathology_alias}             = "Field_Reference(Pathology_ID)";
$Aliases{Original_Source}{anatomic_site}               = "Anatomic_Site.Anatomic_Site_Alias";
$Aliases{Original_Source}{cell_line_name}              = "Cell_Line.Cell_Line_Name";
$Aliases{Original_Source}{original_source_type}        = "Original_Source.Original_Source_Type";
$Aliases{Original_Source}{disease_status}              = "Original_Source.Disease_Status";
$Aliases{Original_Source}{pathology_type}              = "Original_Source.Pathology_Type";
$Aliases{Original_Source}{pathology_stage}             = "Original_Source.Pathology_Stage";
$Aliases{Original_Source}{pathology_grade}             = "Original_Source.Pathology_Grade";
$Aliases{Original_Source}{pathology_occurrence}        = "Original_Source.Pathology_Occurrence";

$Aliases{Pathology}{path_alias}             = "Pathology.Pathology_Alias";
$Aliases{Anatomic_Site}{anatomic_site_name} = "Anatomic_Site.Anatomic_Site_Name";

# $Aliases{Original_Source}{species            } = "Organism.Species";
# $Aliases{Original_Source}{sub_species}         = "Organism.Sub_species";

$Aliases{Source}{stage}                                 = "Stage.Stage_Name";
$Aliases{Source}{strain}                                = "Strain.Strain_Name";
$Aliases{Source}{sex}                                   = "Original_Source.Sex";
$Aliases{Source}{host}                                  = "Original_Source.Host";
$Aliases{Source}{parent_source}                         = "PoolSrc.Source_ID";
$Aliases{Source}{external_id}                           = "Source.External_Identifier";
$Aliases{Source}{source_received_date}                  = "Source.Received_Date";
$Aliases{Source}{xenografted}                           = "Source.Xenograft";
$Aliases{Source}{xenograft_engraftment_time_weeks}      = "Xenograft.Engraftment_Time_in_Weeks";
$Aliases{Source}{xenograft_harvest_date}                = "Xenograft.Harvest_Date";
$Aliases{Source}{xenograft_transplant_anatomic_site_id} = "FKTransplant_Anatomic_Site__ID";
$Aliases{Source}{xenograft_harvest_anatomic_site_id}    = "FKHarvest_Anatomic_Site__ID";
$Aliases{Source}{xenograft_transplant_method}           = "Transplant_Method.Transplant_Method_Name";
$Aliases{Source}{xenograft_host_patient_identifier}     = "Host_Patient.Patient_Identifier";
$Aliases{Source}{xenograft_host_patient_taxonomy}       = "Host_Patient.FK_Taxonomy__ID";
$Aliases{Source}{xenograft_patient_birthdate}           = "Host_Patient.Patient_Birthdate";
$Aliases{Source}{xenograft_patient_sex}                 = "Host_Patient.Patient_Sex";
$Aliases{Source}{current_amount}                        = "Source.Current_Amount";
$Aliases{Source}{amount_units}                          = "Source.Amount_Units";
$Aliases{Source}{source_rack_alias}                     = "Rack.Rack_Alias";
$Aliases{Source}{source_rack_id}                        = "Rack.Rack_ID";
$Aliases{Source}{sample_collection_date}                = "Left(Source.Sample_Collection_Time,10)";
$Aliases{Source}{sample_collection_time}                = "Source.Sample_Collection_Time";
$Aliases{Source}{pathology_primary_anatomic_site_id}    = "Pathology.FKPrimary_Anatomic_Site__ID";
$Aliases{Source}{histology_alias}                       = "Histology.Histology_Alias";
$Aliases{Source}{source_label}                          = "Source.Source_Label";
$Aliases{Source}{Sample_Alert}                          = "Source_Alert.Alert_Type";
$Aliases{Source}{Sample_Alert_Reason}                   = "Alert_Reason.Alert_Reason";
$Aliases{Source}{source_number}                         = "Source.Source_Number";
$Aliases{Source}{storage_medium}                        = "Storage_Medium.Storage_Medium_Name";
$Attr_Aliases{source_submitted_concentration}           = "Source.Submitted_Concentration";
$Attr_Aliases{source_submitted_concentration_units}     = "Source.Submitted_Concentration_Units";

$Aliases{Anatomic_Site}{anatomic_site_id}    = "Anatomic_Site.Anatomic_Site_ID";
$Aliases{Anatomic_Site}{anatomic_site_alias} = "Anatomic_Site.Anatomic_Site_Alias";
$Aliases{Anatomic_Site}{anatomic_site_type}  = "Anatomic_Site_Type";
$Aliases{Shipment}{shipment_received}        = "Shipment.Shipment_Received";
$Aliases{Shipment}{shipment_sent}            = "Shipment.Shipment_Sent";
$Aliases{Shipment}{supplier_organization}    = "Shipment_Org.Organization_Name";
$Aliases{Source_Pool}{pooled_sources}        = "Source_Pool.FKParent_Source__ID";

# Equipment aliases
$Aliases{Equipment}{machine}            = "Equipment.Equipment_Name";
$Aliases{Equipment}{machine_id}         = "Equipment.Equipment_ID";
$Aliases{Equipment}{equipment_location} = "Location.Location_Name";
$Aliases{Equipment}{rack_location}      = "Location.Location_Name";
$Aliases{Equipment}{equipment_status}   = "Equipment.Equipment_Status";
$Aliases{Equipment}{equipment_category} = "Concat(Equipment_Category.Category,' ',Sub_Category)";
$Aliases{Equipment}{equipment_type}     = "Concat(Equipment_Category.Category,' ',Sub_Category)";

my %Vector_Alias;    ## Library Alias ##
$Aliases{Vector}{vector_file} = "Vector_Type.Vector_Sequence_File";
$Aliases{Vector}{vector}      = "Vector_Type.Vector_Type_Name";

## Primer Alias ##
my %Primer_Alias;
$Aliases{Primer}{custom_primer_sequence}      = "Custom_Primer.Primer_Sequence";
$Aliases{Primer}{custom_primer}               = "Custom_Primer.Primer_Name";
$Aliases{Primer}{primer_sequence}             = "Primer.Primer_Sequence";
$Aliases{Primer}{primer}                      = "Primer.Primer_Name";
$Aliases{Primer}{primer_type}                 = "Primer.Primer_Type";
$Aliases{Primer}{alternate_primer_identifier} = "Primer.Alternate_Primer_Identifier";

#$Aliases{Primer}{primer_type} = "CASE WHEN Primer.Primer_Name='Custom' THEN Custom_Primer.Primer_Name ELSE Primer.Primer_Name END";
$Aliases{Primer}{oligo_primer}           = "Primer_Plate_Well.FK_Primer__Name";
$Aliases{Primer}{oligo_sequence}         = "Custom_Primer.Primer_Sequence";
$Aliases{Primer}{oligo_direction}        = "Primer_Customization.Direction";
$Aliases{Primer}{oligo_type}             = "Custom_Primer.Primer_Type";
$Aliases{Primer}{working_tm}             = "Primer_Customization.Tm_Working";
$Aliases{Primer}{adapter_index_sequence} = "Primer_Customization.Adapter_Index_Sequence";

## Primer Aliases (related to Primer_Plate)
$Aliases{Primer}{primer_plate_name}        = "Primer_Plate.Primer_Plate_Name";
$Aliases{Primer}{primer_plate_notes}       = "Primer_Plate.Notes";
$Aliases{Primer}{primer_plate_status}      = "Primer_Plate.Primer_Plate_Status";
$Aliases{Primer}{primer_plate_id}          = "Primer_Plate.Primer_Plate_ID";
$Aliases{Primer}{primer_plate_well}        = "Primer_Plate_Well.Well";
$Aliases{Primer}{primer_well}              = "Primer_Plate_Well.Well";
$Aliases{Primer}{primer_plate_well_status} = 'Primer_Plate_Well.Primer_Plate_Well_Check';
$Aliases{Primer}{order_date}               = "Primer_Plate.Order_DateTime";
$Aliases{Primer}{arrival_date}             = "Primer_Plate.Arrival_DateTime";
$Aliases{Primer}{primer_plate_solution}    = "Primer_Plate.FK_Solution__ID";
$Aliases{Primer}{amplicon_length}          = "Primer_Customization.Amplicon_Length";
$Aliases{Primer}{stock_source}             = "Stock_Catalog.Stock_Source";
$Aliases{Primer}{nt_index}                 = "Primer_Customization.nt_index";
$Aliases{Primer}{nt_index_sequence}        = "RIGHT(Primer.Primer_Sequence,Primer_Customization.nt_index)";

my %Pool_Alias;    ## Pool Alias ##
$Aliases{Pool}{pool_id}          = "Pool_ID";
$Aliases{Pool}{pool_type}        = "Pool_Type";
$Aliases{Pool}{pool_name}        = "Pool.FK_Library__Name";
$Aliases{Pool}{pool_status}      = "Transposon_Pool.Status";
$Aliases{Pool}{pooled_by}        = "Pool.FK_Employee__ID";
$Aliases{Pool}{pool_description} = "Pool_Description";

#$Aliases{Pool}{pool_target_plate} = "Pool.FK_Plate__ID";
$Aliases{Pool}{pool_date}           = "Pool_Date";
$Aliases{Pool}{pool_comments}       = "Pool_Comments";
$Aliases{Pool}{pool_gel_id}         = "Transposon_Pool.FK_GelRun__ID";
$Aliases{Pool}{OD_id}               = "Transposon_Pool.FK_Optical_Density__ID";
$Aliases{Pool}{pool_pipeline}       = "Transposon_Pool.Pipeline";
$Aliases{Pool}{pool_reads_required} = "Transposon_Pool.Reads_Required";
$Aliases{Pool}{pool_transposon_id}  = "Transposon_Pool.FK_Transposon__ID";
$Aliases{Pool}{pool_transposon}     = "Transposon.Transposon_Name";

my %PoolSample_Alias;
$Aliases{PoolSample}{pooled_source_well}  = "PoolSample.Well";
$Aliases{PoolSample}{pooled_source_plate} = "PoolSample.FK_Plate__ID";
$Aliases{PoolSample}{pooled_wells}        = "Count(DISTINCT PoolSample.Well,PoolSample.FK_Plate__ID)";

my %ReArray_Alias;
$Aliases{ReArray}{rearray_request_id}  = 'ReArray_Request.ReArray_Request_ID';
$Aliases{ReArray}{rearray_type}        = 'ReArray_Request.ReArray_Type';
$Aliases{ReArray}{rearray_target_well} = 'ReArray.Target_Well';
$Aliases{ReArray}{rearray_target}      = 'ReArray_Request.FKTarget_Plate__ID';
$Aliases{ReArray}{rearray_source}      = 'ReArray.FKSource_Plate__ID';
$Aliases{ReArray}{rearray_source_well} = 'ReArray.Source_Well';
$Aliases{ReArray}{rearray_datetime}    = 'ReArray_Request.Request_DateTime';
$Aliases{ReArray}{rearray_sample_id}   = 'ReArray.FK_Sample__ID';

my %Read_Alias;
$Aliases{Read}{unique_samples}  = "count(DISTINCT Clone_Sequence.FK_Sample__ID)";
$Aliases{Read}{sequenced_well}  = "Clone_Sequence.Well";
$Aliases{Read}{Q20}             = SQL_phred(20);
$Aliases{Read}{Q30}             = SQL_phred(30);
$Aliases{Read}{Q40}             = SQL_phred(40);
$Aliases{Run}{run_initiated_by} = 'Sequenced_by.Employee_Name';

$Aliases{Read}{'Max_Q20'}      = "Max(" . SQL_phred(20) . ")";
$Aliases{Read}{'Max_Q30'}      = "Max(" . SQL_phred(30) . ")";
$Aliases{Read}{'Max_Q40'}      = "Max(" . SQL_phred(40) . ")";
$Aliases{Read}{'Avg_Q20'}      = "Sum(" . SQL_phred(20) . ") / count(*)";
$Aliases{Read}{'Avg_Q30'}      = "Sum(" . SQL_phred(30) . ") / count(*)";
$Aliases{Read}{'Avg_Q40'}      = "Sum(" . SQL_phred(40) . ") / count(*)";
$Aliases{Read}{'Sum_Q20'}      = "Sum(" . SQL_phred(20) . ")";
$Aliases{Read}{'Sum_Q30'}      = "Sum(" . SQL_phred(30) . ")";
$Aliases{Read}{'Sum_Q40'}      = "Sum(" . SQL_phred(40) . ")";
$Aliases{Read}{warning}        = "Clone_Sequence.Read_Warning";
$Aliases{Read}{error}          = "Clone_Sequence.Read_Error";
$Aliases{Read}{read_comments}  = "Clone_Sequence.Clone_Sequence_Comments";
$Aliases{Read}{read_sample_id} = "Clone_Sequence.FK_Sample__ID";
###### Run trimmed for both quality and vector ##########

$Aliases{Read}{'trimmed_sequence'} = "MID(Clone_Sequence.Sequence,GREATEST(Quality_Left+1,Vector_Left+2,0)," . "CASE WHEN (Vector_Right>0 OR Vector_Left>0) " . "THEN (Quality_Length-Vector_Quality) ELSE Clone_Sequence.Quality_Length END)";
$Aliases{Read}{'trimmed_length'}   = "Clone_Sequence.Quality_Length - Clone_Sequence.Vector_Quality";
$Aliases{Read}{'trimmed_scores'}   = "MID(Sequence_Scores,GREATEST(Quality_Left+1,Vector_Left+2,0)," . "CASE WHEN (Vector_Right>0 OR Vector_Left>0) " . "THEN (Quality_Length-Vector_Quality) ELSE Clone_Sequence.Quality_Length END)";
###### Run trimmed for quality alone (based on phred contiguous quality region) ######
$Aliases{Read}{'quality_sequence'}                        = "MID(Clone_Sequence.Sequence,GREATEST(Quality_Left+1,0),GREATEST(Quality_Length,0))";
$Aliases{Read}{'quality_length'}                          = "Clone_Sequence.Quality_Length";
$Aliases{Read}{'quality_vector'}                          = "Clone_Sequence.Vector_Quality";
$Aliases{Read}{'quality_scores'}                          = "MID(Clone_Sequence.Sequence_Scores,GREATEST(Quality_Left+1,0),GREATEST(Quality_Length,0))";
$Aliases{Read}{'sequence'}                                = 'Clone_Sequence.Sequence';
$Aliases{Read}{'sequence_length'}                         = 'Clone_Sequence.Sequence_Length';
$Aliases{Read}{'sequence_scores'}                         = 'Clone_Sequence.Sequence_Scores';
$Aliases{Read}{'vector_left'}                             = 'Clone_Sequence.Vector_Left';
$Aliases{Read}{'vector_right'}                            = 'Clone_Sequence.Vector_Right';
$Aliases{Read}{'quality_left'}                            = 'Clone_Sequence.Quality_Left';
$Aliases{Read}{read_sample}                               = "Clone_Sequence.FK_Sample__ID";
$Aliases{Read}{'phred_version'}                           = "SequenceAnalysis.Phred_Version";
$Aliases{Read}{'BAC_trace_submission_phred_version'}      = "Concat('phred-',SequenceAnalysis.Phred_Version)";
$Aliases{Read}{'BAC_trace_submission_CLIP_QUALITY_LEFT'}  = "CASE WHEN Quality_Left >=0 THEN Quality_Left ELSE NULL END";
$Aliases{Read}{'BAC_trace_submission_CLIP_QUALITY_RIGHT'} = "CASE WHEN Quality_Length >= 0 THEN Quality_Left + Quality_Length - 1 ELSE NULL END";

## my %Sample_Alias;
$Aliases{Sample}{sample_name}    = "Sample.Sample_Name";
$Aliases{Sample}{name_of_sample} = "Sample.Sample_Name";                        ### Previous entry conflicts with SolexaRun
$Aliases{Sample}{samples}        = "count(DISTINCT Sample_Name)";
$Aliases{Sample}{sample_plate}   = "Left(Sample_Name,LENGTH(Sample_Name)-4)";
$Aliases{Sample}{sample_id}      = "Sample.Sample_ID";

## my %Clone_Alias;
$Aliases{Clone}{clone_id}         = "Clone_Sample.Clone_Sample_ID";
$Aliases{Clone}{clone_name}       = "Sample.Sample_Name";
$Aliases{Clone}{original_library} = "Clone_Sample.FK_Library__Name";
$Aliases{Clone}{original_libraries}
    = "CASE WHEN (COUNT(DISTINCT Clone_Sample.FK_Library__Name) > 1) "
    . "THEN ('(hybrid)') "
    . "WHEN (COUNT(DISTINCT Clone_Sample.FK_Library__Name,Clone_Sample.Library_Plate_Number) > 1) "
    . "THEN (Clone_Sample.FK_Library__Name) "
    . "WHEN (COUNT(DISTINCT Clone_Sample.FK_Library__Name,Clone_Sample.Library_Plate_Number,Clone_Sample.Original_Quadrant) > 1) "
    . "THEN (CONCAT(Clone_Sample.FK_Library__Name,'-',Clone_Sample.Library_Plate_Number)) "
    . "ELSE (CONCAT(Clone_Sample.FK_Library__Name,'-',Clone_Sample.Library_Plate_Number,Clone_Sample.Original_Quadrant) ) END";
$Aliases{Clone}{original_plate_id} = "Clone_Sample.FKOriginal_Plate__ID";    ##

$Aliases{Sample}{original_extraction_plate_id} = "Extraction_Sample.FKOriginal_Plate__ID";
$Aliases{Sample}{original_extraction_well}     = "Extraction_Sample.Original_Well";

$Aliases{Sample_Type}{sample_type} = 'Sample_Type.Sample_Type';

$Aliases{Clone}{original_well}         = "Clone_Sample.Original_Well";           ##
$Aliases{Clone}{applied_plate_id}      = "Plate_Sample.FKOriginal_Plate__ID";    ## original plate_id (of value for ReArrays)...
$Aliases{Clone}{applied_well}          = "Plate_Sample.Well";                    ## Well as applied to original (of value for ReArrays)...
$Aliases{Clone}{original_plate_number} = "Clone_Sample.Library_Plate_Number";
$Aliases{Clone}{original_quadrant}     = "Clone_Sample.Original_Quadrant";
$Aliases{Clone}{original_quadrants} = "CASE WHEN (COUNT(DISTINCT Clone_Sample.Original_Quadrant) > 1) " . "THEN (COUNT(DISTINCT Clone_Sample.Original_Quadrant)) " . "ELSE (Clone_Sample.Original_Quadrant) END";
$Aliases{Sample}{alias_name}        = "Sample_Alias.Alias";
$Aliases{Sample}{sample_alias}      = "Sample_Alias.Alias";
$Aliases{Sample}{clone_alias}       = "Sample_Alias.Alias";
$Aliases{Sample}{mgc_number}        = "Sample_Alias.Alias";
$Aliases{Sample}{alias_type} = "Sample_Alias.Alias_Type";                        ## Change name to Clone_Alias.Alias_Type (Source is reserved word) ##

#my %Source_Alias;
$Aliases{Source}{parent_group}            = "Parent_Group.Grp_Name";
$Aliases{Source}{parent_library}          = "Parent_Library.Library_Name";
$Aliases{Source}{required_parent_group}   = "R_Parent_Group.Grp_Name";
$Aliases{Source}{required_parent_library} = "R_Parent_Library.Library_Name";

#$Aliases{Clone}{source_clone_id} = "Clone_Source.FK_Clone__ID";
$Aliases{Clone}{source_name}   = "Clone_Source.Source_Name";
$Aliases{Clone}{source_org_id} = "Clone_Source.FKSource_Organization__ID";

#$Aliases{Clone}{source_id} = "Clone_Source.Source_Name";
#$Aliases{Clone}{source_library} = "Clone_Source.Source_Library_Name";
$Aliases{Clone}{source_collection} = "Clone_Source.Source_Collection";
$Aliases{Clone}{source_3prime_tag} = "Clone_Source.3prime_tag";
$Aliases{Clone}{source_5prime_tag} = "Clone_Source.5prime_tag";
$Aliases{Clone}{source_vector}     = "Clone_Source.Source_Vector";
$Aliases{Clone}{source_library_id} = "Clone_Source.Source_Library_ID";
$Aliases{Clone}{source_plate}      = "Clone_Source.Source_Plate";
$Aliases{Clone}{source_plates}
    = "CASE WHEN (COUNT(DISTINCT Clone_Source.Source_Collection) > 1) THEN ('(hybrid)') WHEN (COUNT(DISTINCT Clone_Source.Source_Collection,Clone_Source.Source_Plate) > 1) THEN (Clone_Source.Source_Collection) ELSE (CONCAT(Clone_Source.Source_Collection,'-',Clone_Source.Source_Plate) ) END";
$Aliases{Clone}{source_row}             = "Clone_Source.Source_Row";
$Aliases{Clone}{source_col}             = "Clone_Source.Source_Col";
$Aliases{Clone}{source_comments}        = "Clone_Source.Source_Comments";
$Aliases{Clone}{source_description}     = "Clone_Source.Source_Description";
$Aliases{Clone}{source_quadrant}        = "Clone_Sample.Original_Quadrant";                       ## same as original_quadrant (?)...
$Aliases{Clone}{source_score}           = "Clone_Source.Source_Score";
$Aliases{Clone}{clone_comments}         = "Clone_Details.Clone_Comments";
$Aliases{Clone}{clone_chimerism}        = "Clone_Details.Chimerism_check_with_ESTs";
$Aliases{Clone}{clone_gel_id}           = "Clone_Gel.Clone_Gel_ID";
$Aliases{Clone}{clone_band_sizes}       = "Clone_Gel.Band_Sizes";
$Aliases{Clone}{clone_size_estimate}    = "Clone_Gel.Clone_Size_Estimate";
$Aliases{Clone}{clone_gel_comments}     = "Clone_Gel.Comments";
$Aliases{Clone}{gel_id}                 = "GelRun.GelRun_ID";
$Aliases{Clone}{gel_datetime}           = "GelRun.Gel_Date";
$Aliases{Clone}{gel_plate}              = "GelRun.FK_Plate__ID";
$Aliases{Clone}{gel_well}               = "GelRun.Well";
$Aliases{Clone}{gel_lane}               = "GelRun.Lane";
$Aliases{Clone}{clone_gels}             = "COUNT(DISTINCT Clone_Gel_ID)";
$Aliases{Clone}{OD_density}             = "Optical_Density.Density";
$Aliases{Clone}{OD_plate}               = "Optical_Density.FK_Plate__ID";
$Aliases{Clone}{OD_well}                = "Optical_Density.Well";
$Aliases{Clone}{OD_concentration}       = "Optical_Density.Concentration";
$Aliases{Clone}{OD_runs}                = "COUNT(DISTINCT Optical_Density.Optical_Density_ID)";
$Aliases{Clone}{concentration}          = "Concentrations.Concentration";
$Aliases{Clone}{concentration_datetime} = "ConcentrationRun.DateTime";
$Aliases{Clone}{concentration_plate}    = "ConcentrationRun.FK_Plate__ID";
$Aliases{Clone}{concentration_well}     = "Concentrations.Well";
$Aliases{Clone}{concentration_run}      = "Concentrations.FK_ConcentrationRun__ID";
$Aliases{Clone}{concentration_runs}     = "COUNT(DISTINCT ConcentrationRun_ID)";

$Aliases{GelRun}{analysis_start_time} = 'GelAnalysis.GelAnalysis_DateTime';
$Aliases{GelRun}{Bandleader_Version}  = 'GelAnalysis.Bandleader_Version';

## my %Plate_Alias;
$Aliases{Plate}{plate_id}                 = 'Plate.Plate_ID';
$Aliases{Plate}{original_parent_plate_id} = 'Plate.FKOriginal_Plate__ID';
$Aliases{Plate}{parent_plate_id}          = 'Plate.FKParent_Plate__ID';
$Aliases{Plate}{plate_made_by}            = 'Plater.Employee_Name';
$Aliases{Plate}{plate_number}             = 'Plate.Plate_Number';

#$Aliases{Plate}{library}                  = 'Plate.FK_Library__Name';
$Aliases{Plate}{plate_location_id}   = 'Plate.FK_Rack__ID';
$Aliases{Plate}{plate_format_id}     = 'Plate.FK_Plate_Format__ID';
$Aliases{Plate}{plate_status}        = 'Plate.Plate_Status';
$Aliases{Plate}{plate_size}          = 'Plate.Plate_Size';
$Aliases{Plate}{plate_application}   = 'Plate.Plate_Application';
$Aliases{Plate}{plate_type}          = 'Plate.Plate_Type';
$Aliases{Plate}{plate_test_status}   = 'Plate.Plate_Test_Status';
$Aliases{Plate}{parent_quadrant}     = 'Plate.Parent_Quadrant';
$Aliases{Plate}{plate_position}      = 'Library_Plate.Plate_Position';
$Aliases{Plate}{plate_class}         = 'Plate.Plate_Class';
$Aliases{Plate}{unused_wells}        = 'Library_Plate.Unused_Wells';
$Aliases{Plate}{plate_comments}      = 'Plate.Plate_Comments';
$Aliases{Plate}{problematic_wells}   = 'Library_Plate.Problematic_Wells';
$Aliases{Plate}{empty_wells}         = 'Library_Plate.Empty_Wells';
$Aliases{Plate}{NGs}                 = 'Library_Plate.No_Grows';
$Aliases{Plate}{SGs}                 = 'Library_Plate.Slow_Grows';
$Aliases{Plate}{plate_created}       = 'Plate.Plate_Created';
$Aliases{Plate}{first_plate_created} = 'Min(Plate.Plate_Created)';
$Aliases{Plate}{last_plate_created}  = 'Max(Plate.Plate_Created)';
$Aliases{Plate}{branch_code}         = 'Plate.FK_Branch__Code';
$Aliases{Plate}{plate_contents}      = 'Sample_Type.Sample_Type';
$Aliases{Plate}{pipeline}            = 'Plate.FK_Pipeline__ID';
$Aliases{Plate}{pipeline_code}       = 'Pipeline.Pipeline_Code';
$Aliases{Plate}{tray_id}             = 'Plate_Tray.FK_Tray__ID';
$Aliases{Plate}{plate_volume}        = 'Plate.Current_Volume';
$Aliases{Plate}{plate_volume_units}  = 'Plate.Current_Volume_Units';

$Aliases{Run}{plate_QC_status} = "Plate.QC_Status";

$Aliases{Branch}{branch_description} = 'Branch.Branch_Description';
$Aliases{Rack}{location}             = 'Rack.Rack_Alias';
## delete those below at next release (verify with users) ##
$Aliases{Plate}{rack} = 'Rack.Rack_Alias';

$Aliases{Plate}{rack_id}                = 'Plate.FK_Rack__ID';         ## <CONSTRUCTION> - remove - not a Plate attribute
$Aliases{Equipment}{equipment_location} = 'Location.Location_Name';    ## <CONSTRUCTION> - remove - confuse with location

## my %Plate_Format_Alias;
$Aliases{Plate}{plate_format} = 'Plate_Format.Plate_Format_Type';

$Aliases{Prep}{event}             = "Prep.Prep_Name";
$Aliases{Prep}{event_time}        = "Prep.Prep_DateTime";
$Aliases{Prep}{event_comments}    = "Prep.Prep_Comments";
$Aliases{Prep}{application_time}  = "Prep.Prep_DateTime";
$Aliases{Prep}{applied_solution}  = "Plate_Prep.FK_Solution__ID";
$Aliases{Prep}{prep_plate_id}     = "Plate_Prep.FK_Plate__ID";
$Aliases{Prep}{applied_by}        = "Prepper.Employee_Name";
$Aliases{Prep}{applied_qty}       = "Plate_Prep.Solution_Quantity";
$Aliases{Prep}{plate_set_number}  = "Plate_Prep.FK_Plate_Set__Number";
$Aliases{Prep}{applied_equipment} = "Plate_Prep.FK_Equipment__ID";
$Aliases{Prep}{lab_protocol_name} = "Lab_Protocol.Lab_Protocol_Name";

$Aliases{Employee}{employee}    = "Employee.Employee_Name";
$Aliases{Employee}{employee_id} = "Employee.Employee_ID";

## Rearray Aliases;
$Aliases{Rearray}{source_plate_id}       = 'Source_Plate.Plate_ID';
$Aliases{Rearray}{source_library}        = 'Source_Plate.FK_Library__Name';
$Aliases{Rearray}{source_plate_number}   = 'Source_Plate.Plate_Number';
$Aliases{Rearray}{source_plate_quadrant} = 'Source_Plate.Parent_Quadrant';
$Aliases{Rearray}{target_plate_id}       = 'Plate.Plate_ID';
$Aliases{Rearray}{target_library}        = 'Plate.FK_Library__Name';
$Aliases{Rearray}{target_plate_number}   = 'Plate.Plate_Number';
$Aliases{Rearray}{primer_name}           = 'Primer.Primer_Name';
$Aliases{Rearray}{source_well}           = 'ReArray.Source_Well';
$Aliases{Rearray}{target_well}           = 'ReArray.Target_Well';
$Aliases{Rearray}{oligo_direction}       = 'Primer_Customization.Oligo_Direction';
$Aliases{Rearray}{rearray_request_id}    = "ReArray_Request.ReArray_Request_ID";
$Aliases{Rearray}{tm}                    = 'Primer_Customization.Tm_Working';
$Aliases{Rearray}{primer_sequence}       = 'Primer.Primer_Sequence';
$Aliases{Rearray}{rearray_type}          = 'ReArray_Request.ReArray_Type';
$Aliases{Rearray}{rearray_status}        = 'Status.Status_Name';
$Aliases{Rearray}{primer_well}           = 'Primer_Plate_Well.Well';
$Aliases{Rearray}{solution_id}           = 'Primer_Plate.FK_Solution__ID';
$Aliases{Rearray}{primer_plate_name}     = "Primer_Plate.Primer_Plate_Name";
$Aliases{Rearray}{primer_order_date}     = "Primer_Plate.Order_DateTime";
$Aliases{Rearray}{primer_arrival_date}   = "Primer_Plate.Arrival_DateTime";
$Aliases{Rearray}{sample_id}             = "Plate_Sample.FK_Sample__ID";
$Aliases{Rearray}{sample_name}           = "Sample.Sample_Name";
$Aliases{Rearray}{rearray_date}          = "ReArray_Request.Request_DateTime";
$Aliases{Rearray}{employee_name}         = "Employee.Employee_Name";
$Aliases{Rearray}{employee_id}           = "ReArray_Request.FK_Employee__ID";

# alternate aliases for rearrays (if going through an applied primer instead of an oligo rearray)
# note that these are more limited than the above
## alt_Rearray aliases;
$Aliases{alt_Rearray}{target_plate_id}     = 'Plate.Plate_ID';
$Aliases{alt_Rearray}{target_library}      = 'Plate.FK_Library__Name';
$Aliases{alt_Rearray}{target_plate_number} = 'Plate.Plate_Number';
$Aliases{alt_Rearray}{primer_name}         = 'Primer.Primer_Name';
$Aliases{alt_Rearray}{target_well}         = 'Primer_Plate_Well.Well';
$Aliases{alt_Rearray}{tm}                  = 'Primer_Customization.Tm_Working';
$Aliases{alt_Rearray}{primer_sequence}     = 'Primer.Primer_Sequence';
$Aliases{alt_Rearray}{primer_well}         = 'Primer_Plate_Well.Well';
$Aliases{alt_Rearray}{solution_id}         = 'Primer_Plate.FK_Solution__ID';
$Aliases{alt_Rearray}{primer_plate_name}   = "Primer_Plate.Primer_Plate_Name";
$Aliases{alt_Rearray}{primer_order_date}   = "Primer_Plate.Order_DateTime";
$Aliases{alt_Rearray}{primer_arrival_date} = "Primer_Plate.Arrival_DateTime";
$Aliases{alt_Rearray}{sample_id}           = "Plate_Sample.FK_Sample__ID";
$Aliases{alt_Rearray}{sample_name}         = "Sample.Sample_Name";

$Aliases{Stock}{vendor}       = 'Vendor.Organization_Name';
$Aliases{Stock}{manufacturer} = 'Manufacturer.Organization_Name';
$Aliases{Stock}{stock_name}   = "Stock_Catalog.Stock_Catalog_Name";
$Aliases{Stock}{Stock_Name}   = "Stock_Catalog.Stock_Catalog_Name";
$Aliases{Stock}{stock_size}   = "Stock_Catalog.Stock_Size";
$Aliases{Stock}{stock_units}  = "Stock_Catalog.Stock_Size_Units";
$Aliases{Stock}{stock_id}     = "Stock.Stock_ID";
$Aliases{Stock}{stock_model}  = "CASE WHEN (Stock_Catalog.Model ='Solexa') THEN ('Illumina Genome Analyzer IIx') WHEN (Stock_Catalog.Model ='2000') THEN ('Illumina HiSeq 2000') WHEN (Stock_Catalog_Name = 'MiSeq') THEN ('Illumina MiSeq') END";

$Aliases{Solution}{solution_id}            = "Solution.Solution_ID";
$Aliases{Solution}{solution_name}          = "Stock_Catalog.Stock_Catalog_Name";
$Aliases{Solution}{solution_quantity_used} = "Solution.Quantity_Used";
$Aliases{Solution}{solution_quantity}      = "Solution.Solution_Quantity";
$Aliases{Solution}{solution_status}        = "Solution.Solution_Status";
$Aliases{Solution}{solution_rack_id}       = "Solution.FK_Rack__ID";
$Aliases{Solution}{solution_expiry}        = "Solution.Solution_Expiry";

### Gel Run
$Aliases{GelRun}{analysis_status}     = 'Gel_Analysis_Status.Status_Name';
$Aliases{GelRun}{Gel_Name}            = 'GelAnalysis.Gel_Name';
$Aliases{GelRun}{Swap_Check}          = 'GelAnalysis.Swap_Check';
$Aliases{GelRun}{Self_Check}          = 'GelAnalysis.Self_Check';
$Aliases{GelRun}{Cross_Check}         = 'GelAnalysis.Cross_Check';
$Aliases{GelRun}{Validation_Override} = 'GelAnalysis.Validation_Override';

$Aliases{GelRun}{billable}         = 'Run.Billable';
$Aliases{GelRun}{Analysis_Status}  = 'Gel_Analysis_Status.Status_Name';
$Aliases{GelRun}{gel_type}         = "GelRun.GelRun_Type";
$Aliases{GelRun}{Comb}             = "CombEquipment.Equipment_Name";
$Aliases{GelRun}{poured_equipment} = "PouredEquipment.Equipment_Name";
$Aliases{GelRun}{agarose_solution} = "GelRun.FKAgarose_Solution__ID";
$Aliases{GelRun}{agarose_percent}  = "GelRun.Agarose_Percentage";
$Aliases{GelRun}{Poured}           = "PouredEmployee.Employee_Name";
$Aliases{GelRun}{GelTray}          = "CONCAT(GelRack.FKParent_Rack__ID,':',GelRack.Rack_Name)";
$Aliases{GelRun}{PouredDate}       = "RunBatch.RunBatch_RequestDateTime";
$Aliases{GelRun}{Loaded}           = "LoadedEmployee.Employee_Name";
$Aliases{GelRun}{LoadDate}         = "Run.Run_DateTime";
$Aliases{GelRun}{GelBox}           = "BoxEquipment.Equipment_Name";
$Aliases{GelRun}{Scanner}          = "ScannerEquipment.Equipment_Name";
$Aliases{GelRun}{thumbnail}        = "CONCAT(Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData/',Run.Run_Directory,'/annotated.jpg')";
$Aliases{GelRun}{TIF}              = "CONCAT(Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData/',Run.Run_Directory,'/image.tif')";
$Aliases{GelRun}{lab_comments}     = '1';

$Aliases{GelRun}{autopass} = '1';    ### Attribute

#$Aliases{GelRun}{Temperature} = '1'; ### Attribute
$Aliases{GelRun}{gelrun_purpose} = "GelRun_Purpose.GelRun_Purpose_Name";

$Aliases{Lane}{lane_sample}   = 'Lane.FK_Sample__ID';
$Aliases{Lane}{lane_number}   = 'Lane.Lane_Number';
$Aliases{Lane}{lane_status}   = 'Lane.Lane_Status';
$Aliases{Lane}{well}          = 'Lane.Well';
$Aliases{Lane}{size_estimate} = 'Lane.Band_Size_Estimate';

$Aliases{Band}{band_id}        = 'Band.Band_ID';
$Aliases{Band}{band_size}      = 'Band.Band_Size';
$Aliases{Band}{band_mobility}  = 'Band.Band_Mobility';
$Aliases{Band}{band_number}    = 'Band.Band_Number';
$Aliases{Band}{band_intensity} = 'Band.Band_Intensity';
$Aliases{Band}{band_type}      = 'Band.Band_Type';

$Aliases{Fail}{failed_by}     = 'Fail.FK_Employee__ID';
$Aliases{Fail}{fail_datetime} = 'Fail.DateTime';

$Aliases{FailReason}{fail_reason}      = 'FailReason.FailReason_Name';
$Aliases{FailReason}{fail_description} = 'FailReason.FailReason_Description';

$Aliases{Submission}{submission_date}           = "Submission.Submission_DateTime";
$Aliases{Submission}{submission_source}         = "Submission.Submission_Source";
$Aliases{Submission}{submission_status}         = "Submission.Submission_Status";
$Aliases{Submission}{submitted_by}              = "Submitter.Employee_Name";
$Aliases{Submission}{submission_comments}       = "Submission.Submission_Comments";
$Aliases{Submission}{approved_by}               = "Approver.Employee_Name";
$Aliases{Submission}{approved_date}             = "Submission.Approved_DateTime";
$Aliases{Submission}{work_request_type}         = "Work_Request_Type.Work_Request_Type_Name";
$Aliases{Submission}{work_num_plates_submitted} = "Work_Request.Num_Plates_Submitted";
$Aliases{Submission}{work_goal_target}          = "Work_Request.Goal_Target";
$Aliases{Submission}{work_goal_target_sum}      = "Sum(Work_Request.Goal_Target)";
$Aliases{Submission}{work_request_comments}     = "Work_Request.Comments";

$Aliases{SpectRun}{A260_blank_avg}    = "SpectAnalysis.A260_Blank_Avg";
$Aliases{SpectRun}{A280_blank_avg}    = "SpectAnalysis.A280_Blank_Avg";
$Aliases{SpectRun}{scanner_equipment} = "SpectRun.FKScanner_Equipment__ID";

$Aliases{SpectRead}{well}               = "SpectRead.Well";
$Aliases{SpectRead}{well_status}        = "SpectRead.Well_Status";
$Aliases{SpectRead}{well_category}      = "SpectRead.Well_Category";
$Aliases{SpectRead}{A260m}              = "SpectRead.A260m";
$Aliases{SpectRead}{A260cor}            = "SpectRead.A260cor";
$Aliases{SpectRead}{A280m}              = "SpectRead.A280m";
$Aliases{SpectRead}{A280cor}            = "SpectRead.A280cor";
$Aliases{SpectRead}{A260}               = "SpectRead.A260";
$Aliases{SpectRead}{A280}               = "SpectRead.A280";
$Aliases{SpectRead}{A260_A280_ratio}    = "SpectRead.A260_A280_ratio";
$Aliases{SpectRead}{dilution_factor}    = "SpectRead.Dilution_Factor";
$Aliases{SpectRead}{spec_concentration} = "SpectRead.Concentration";
$Aliases{SpectRead}{unit}               = "SpectRead.Unit";
$Aliases{SpectRead}{read_error}         = "SpectRead.Read_Error";
$Aliases{SpectRead}{read_warning}       = "SpectRead.Read_Warning";

$Aliases{BioanalyzerRun}{scanner_equipment}       = "BioanalyzerRun.FKScanner_Equipment__ID";
$Aliases{BioanalyzerRun}{dilution_factor}         = "BioanalyzerRun.Dilution_Factor";
$Aliases{BioanalyzerRun}{bioanalyzerrun_invoiced} = "BioanalyzerRun.Invoiced";

$Aliases{BioanalyzerRead}{well}                       = "BioanalyzerRead.Well";
$Aliases{BioanalyzerRead}{well_status}                = "BioanalyzerRead.Well_Status";
$Aliases{BioanalyzerRead}{well_category}              = "BioanalyzerRead.Well_Category";
$Aliases{BioanalyzerRead}{RNA_DNA_concentration}      = "BioanalyzerRead.RNA_DNA_Concentration";
$Aliases{BioanalyzerRead}{RNA_DNA_concentration_unit} = "BioanalyzerRead.RNA_DNA_Concentration_Unit";
$Aliases{BioanalyzerRead}{RNA_DNA_integrity_number}   = "BioanalyzerRead.RNA_DNA_Integrity_Number";
$Aliases{BioanalyzerRead}{read_error}                 = "BioanalyzerRead.Read_Error";
$Aliases{BioanalyzerRead}{read_warning}               = "BioanalyzerRead.Read_Warning";
$Aliases{BioanalyzerRead}{sample_comments}            = "BioanalyzerRead.Sample_Comment";
$Aliases{BioanalyzerAnalysis}{file_name}              = "BioanalyzerAnalysis.File_Name";

#$Aliases{GenechipRun}{cel_file} = "GenechipRun.CEL_file";
#$Aliases{GenechipRun}{dat_file} = "GenechipRun.DAT_file";
#$Aliases{GenechipRun}{chp_file} = "GenechipRun.CHP_file";

$Aliases{GenechipRun}{genechiprun_invoiced} = "GenechipRun.Invoiced";
$Aliases{GenechipRun}{sample}               = "GenechipAnalysis.FK_Sample__ID";
$Aliases{GenechipRun}{analysis_type}        = "GenechipAnalysis.Analysis_Type";
$Aliases{GenechipRun}{analysis_datetime}    = "GenechipAnalysis.GenechipAnalysis_DateTime";
$Aliases{GenechipRun}{artifact}             = "GenechipAnalysis.Artifact";
$Aliases{GenechipRun}{total_snp}            = "GenechipMapAnalysis.Total_SNP";
$Aliases{GenechipRun}{qc_mcr_percent}       = "GenechipMapAnalysis.QC_MCR_Percent";
$Aliases{GenechipRun}{qc_mdr_percent}       = "GenechipMapAnalysis.QC_MDR_Percent";
$Aliases{GenechipRun}{snp_call_percent}     = "GenechipMapAnalysis.SNP_Call_Percent";
$Aliases{GenechipRun}{aa_call_percent}      = "GenechipMapAnalysis.AA_Call_Percent";
$Aliases{GenechipRun}{ab_call_percent}      = "GenechipMapAnalysis.AB_Call_Percent";
$Aliases{GenechipRun}{bb_call_percent}      = "GenechipMapAnalysis.BB_Call_Percent";

$Aliases{GenechipRun}{alpha1}                = "GenechipExpAnalysis.Alpha1";
$Aliases{GenechipRun}{alpha2}                = "GenechipExpAnalysis.Alpha2";
$Aliases{GenechipRun}{tau}                   = "GenechipExpAnalysis.Tau";
$Aliases{GenechipRun}{noise_rawq}            = "GenechipExpAnalysis.Noise_RawQ";
$Aliases{GenechipRun}{scale_factor}          = "GenechipExpAnalysis.Scale_Factor";
$Aliases{GenechipRun}{norm_factor}           = "GenechipExpAnalysis.Norm_Factor";
$Aliases{GenechipRun}{avg_a_signal}          = "GenechipExpAnalysis.Avg_A_Signal";
$Aliases{GenechipRun}{avg_p_signal}          = "GenechipExpAnalysis.Avg_P_Signal";
$Aliases{GenechipRun}{avg_m_signal}          = "GenechipExpAnalysis.Avg_M_Signal";
$Aliases{GenechipRun}{tgt}                   = "GenechipExpAnalysis.TGT";
$Aliases{Source}{source_id}                  = 'Source.Source_ID';
$Aliases{Source}{patient_id}                 = "Source.External_Identifier";
$Aliases{Source}{gender}                     = "Original_Source.Sex";
$Aliases{GenechipRun}{chip_external_barcode} = "Genechip.External_Barcode";
$Aliases{GenechipRun}{chip_name}             = "Genechip_Type.Genechip_Type_Name";
$Aliases{GenechipRun}{QC_plot}               = "CONCAT(Run.Run_Directory,': N/A')";
$Aliases{GenechipRun}{'re_scan'}             = "CONCAT(Run.Run_Directory,': N/A')";

$Aliases{Source}{nature}                   = "Sample_Type.Sample_Type_Alias";
$Aliases{Source}{RNA_DNA_isolation_method} = "Nucleic_Acid.RNA_DNA_Isolation_Method";
$Aliases{GenechipRun}{thumbnail}
    = "CONCAT('<a href=$URL_domain/$URL_dir_name/dynamic/data_home/private/Projects/',Project_Path,'/',Library_Name,'/AnalyzedData/',Run.Run_Directory,'.JPG><img src=$URL_domain/$URL_dir_name/dynamic/data_home/private/Projects/',Project_Path,'/',Library_Name,'/AnalyzedData/',Run.Run_Directory,'_small.JPG></a>')";

$Aliases{Nucleic_Acid}{nucleic_acid_description} = "Nucleic_Acid.Description";

$Aliases{Pipeline}{pipeline_id}          = "Pipeline.Pipeline_ID";
$Aliases{Pipeline}{pipeline_code}        = "Pipeline.Pipeline_Code";
$Aliases{Pipeline}{pipeline_type}        = "Pipeline.Pipeline_Type";
$Aliases{Pipeline}{pipeline_name}        = "Pipeline.Pipeline_Name";
$Aliases{Pipeline}{pipeline_description} = "Pipeline.Pipeline_Description";
$Aliases{Pipeline}{group_name}           = "Grp.Grp_Name";
$Aliases{Pipeline}{pipeline_group}       = "Pipeline_Group.Pipeline_Group_Name";
$Aliases{Pipeline}{plate_format}         = "Plate_Format.Plate_Format_Type";

$Aliases{Goal}{goal_id}          = "Goal.Goal_ID";
$Aliases{Goal}{goal_name}        = "Goal.Goal_Name";
$Aliases{Goal}{goal_type}        = "Goal.Goal_Type";
$Aliases{Goal}{goal_scope}       = "Goal.Goal_Scope";
$Aliases{Goal}{goal_description} = "Goal.Goal_Description";

$Aliases{Submission_Volume}{submission_volume_name}         = "Submission_Volume.Volume_Name";
$Aliases{Submission_Volume}{submission_volume_date}         = "Submission_Volume.Submission_Date";
$Aliases{Submission_Volume}{submission_volume_organization} = "Organization.Organization_Name";

$Aliases{Analysis_Submission}{analysis_submission_id}                     = "Analysis_Submission.Analysis_Submission_ID";
$Aliases{Analysis_Submission}{analysis_metadata_object_type}              = "Analysis_Metadata_Object.Object_Type";
$Aliases{Analysis_Submission}{analysis_metadata_object_external_defined}  = "Analysis_Metadata_Object.Externally_Defined";
$Aliases{Analysis_Submission}{analysis_metadata_object_alias}             = "Analysis_Metadata_Object.Alias";
$Aliases{Analysis_Submission}{analysis_metadata_object_unique_identifier} = "Analysis_Metadata_Object.Unique_Identifier";
$Aliases{Analysis_Submission}{analysis_file_path}                         = "Analysis_File.Analysis_File_Path";
$Aliases{Analysis_Submission}{analysis_file_checksum}                     = "Analysis_File.Checksum";
$Aliases{Analysis_Submission}{analysis_file_type}                         = "Analysis_File.Analysis_Type";
$Aliases{Analysis_Submission}{external_analysis_field_type}               = "Analysis_File.External_Analysis_Field_Type";
$Aliases{Analysis_Submission}{external_analysis_field_value}              = "Analysis_File.External_Analysis_Field_Value";

$Aliases{Analysis_Submission}{sample_metadata_object_external_defined}       = "Sample_Metadata_Object.Externally_Defined";
$Aliases{Analysis_Submission}{sample_metadata_object_alias}                  = "Sample_Metadata_Object.Alias";
$Aliases{Analysis_Submission}{sample_metadata_object_unique_identifier}      = "Sample_Metadata_Object.Unique_Identifier";
$Aliases{Analysis_Submission}{analysis_submission_run_analysis_id}           = "Analysis_Submission.FK_Run_Analysis__ID";
$Aliases{Analysis_Submission}{analysis_submission_multiplex_run_analysis_id} = "Analysis_Submission.FK_Multiplex_Run_Analysis__ID";
$Aliases{Analysis_Submission}{analysis_submission_started}                   = "Analysis_Submission.Analysis_Submission_Started";
$Aliases{Analysis_Submission}{analysis_submission_finished}                  = "Analysis_Submission.Analysis_Submission_Finished";
$Aliases{Analysis_Submission}{multiplex_run_analysis_index}                  = "Multiplex_Run_Analysis.Adapter_Index";
$Aliases{Analysis_Submission}{run_analysis_sample}                           = "Run_Analysis.FK_Sample__ID";
$Aliases{Analysis_Submission}{analysis_submission_status}                    = "Analysis_Submission_Status.Status_Name";
$Aliases{Analysis_Submission}{analysis_metadata_status}                      = "Analysis_Metadata_Status.Status_Name";
$Aliases{Analysis_Submission}{analysis_dataset_alias}                        = "Analysis_Dataset.Alias";
$Aliases{Analysis_Submission}{analysis_dataset_unique_identifier}            = "Analysis_Dataset.Unique_Identifier";
$Aliases{Analysis_Submission}{trace_submission_status}                       = "Analysis_Submission_Status.Status_Name";

$Aliases{Trace_Submission}{trace_submission_id}        = "Trace_Submission.Trace_Submission_ID";
$Aliases{Trace_Submission}{trace_submission_run_id}    = "Trace_Submission.FK_Run__ID";
$Aliases{Trace_Submission}{trace_submission_sample_id} = "Trace_Submission.FK_Sample__ID";
$Aliases{Trace_Submission}{trace_submission_well}      = "Trace_Submission.Well";
$Aliases{Trace_Submission}{trace_submission_status}    = "Trace_Submission_Status.Status_Name";

$Aliases{Patient}{patient_id}            = "Patient.Patient_ID";
$Aliases{Patient}{patient_identifier}    = "Patient.Patient_Identifier";
$Aliases{Patient}{patient_birthdate}     = "Patient.Patient_Birthdate";
$Aliases{Patient}{patient_date_of_death} = "Patient.Date_of_death";
$Aliases{Patient}{patient_sex}           = "Patient.Patient_Sex";

$Aliases{Work_Request}{work_request}                  = "Work_Request.Work_Request_ID";
$Aliases{Work_Request}{work_request_library}          = "Work_Request.FK_Library__Name";
$Aliases{Work_Request}{work_request_funding_sow}      = "Funding.Funding_Code";
$Aliases{Work_Request}{work_request_goal}             = "Goal.Goal_Name";
$Aliases{Work_Request}{work_request_percent_complete} = "Work_Request.Percent_Complete";

$Aliases{Trace_Submission}{sample_name}               = "Sample.Sample_Name";
$Aliases{Trace_Submission}{library}                   = "Sample.FK_Library__Name";
$Aliases{Trace_Submission}{study_alias}               = "Study_MO.Alias";
$Aliases{Trace_Submission}{study_unique_id}           = "Study_MO.Unique_Identifier";
$Aliases{Trace_Submission}{metadata_sample_alias}     = "Sample_MO.Alias";
$Aliases{Trace_Submission}{metadata_sample_unique_id} = "Sample_MO.Unique_Identifier";
$Aliases{Trace_Submission}{experiment_alias}          = "Experiment_MO.Alias";
$Aliases{Trace_Submission}{experiment_unique_id}      = "Experiment_MO.Unique_Identifier";
$Aliases{Trace_Submission}{run_alias}                 = "Run_MO.Alias";
$Aliases{Trace_Submission}{run_unique_id}             = "Run_MO.Unique_Identifier";
$Aliases{Trace_Submission}{analysis_alias}            = "Analysis_MO.Alias";
$Aliases{Trace_Submission}{analysis_unique_id}        = "Analysis_MO.Unique_Identifier";

##############################
# constructor                #
##############################

##########
sub new {
##########
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = &filter_input( \@_ );
    if ( $args{ERROR} ) { $this->error( $args{ERROR} ); return; }

    ### Connection parameters ###
    my $dbc = $args{-dbc} || $args{-connection};
    ### Mandatory ###
    my $dbase = $args{-dbase} || '';
    my $host  = $args{-host}  || $Defaults{SQL_HOST};    # Name of host on which database resides [String]
    my $LIMS_user        = $args{-LIMS_user};            # LIMS user name (NOT same as Database connection user name) [String]
    my $LIMS_password    = $args{-LIMS_password};        # LIMS password (NOT same as Database connection password) [String]
    my $DB_user          = $args{-DB_user} || 'guest';   # Database connection username (NOT same as LIMS user)
    my $web_service_user = $args{-web_service_user};     # The login name used to connect to web service
    ### Common Options ###
    my $connect = $args{ -connect };                     # Flag to indicate that connection should be made immediately
    my $quiet = $args{-quiet} || 0;                      # suppress printed feedback (defaults to 0) [Int]
    my $DB_password;
    $DB_password = $args{-DB_password} || '';            ## may supply Database password directly if known
    ### Advanced optional parameters ###
    my $driver = $args{-driver} || $Defaults{SQL_DRIVER} || 'mysql';    # SQL driver  [String]
    my $dsn    = $args{-dsn};                                           # Connection string [String]
    my $trace  = $args{-trace_level} || 0;                              # set trace level on database connection (defaults to 0) [Int]
    my $trace_file;
    $trace_file = $args{-trace_file} || 'Trace.log';                    # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $alias_file = $args{-alias_file} || "$config_dir/db_alias.conf"; # Location of DB alias file (optional) [String]
    my $alias_ref;
    $alias_ref = $args{-alias};                                         # Reference to DB alias hash (optional). if passed in then overrides alias file [HashRef]

    my $log_call = defined $args{-log_call} ? $args{-log_call} : 1;

    if ( !$dsn && $driver && $dbase && $host ) {                        # If DSN is not specified but all other info are provided, then we build a DSN.
        $dsn = "DBI:$driver:database=$dbase:$host";
    }

    ## Define connection attributes
    my $self;
    if ($dbc) {
        $self = $dbc;
    }
    else {

        # To get the path of the current module
        ( my $filename = __PACKAGE__ ) =~ s#::#/#g;
        $filename .= '.pm';
        ( my $path = $INC{$filename} ) =~ s#/\Q$filename\E$##g;    # strip / and filename

        # Set up dbc with config
        my $Setup = new alDente::Config( -initialize => 1, -root => $path . '/../../../' );
        my $configs = $Setup->{configs};
        $self = new SDB::DBIO( -dbase => $dbase, -host => $host, -user => $DB_user, -password => $DB_password, -connect => 1, -config => $configs, -sessionless => 1 );
    }
    bless $self, $class;

    ###  Connection attributes ###
    $self->{sth}    = '';                                          # Current statement handle [Object]
    $self->{dbase}  = $dbase;                                      # Database name [String]
    $self->{host}   = $host;                                       # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver} = $driver;                                     # SQL driver [String]
    $self->{dsn}    = $dsn;                                        # Connection string [String]

    $self->{DB_user}          = $DB_user;
    $self->{DB_password}      = $DB_password;
    $self->{LIMS_user}        = $LIMS_user;                        # Login user name [String]
    $self->{LIMS_password}    = $LIMS_password;                    # (MANDATORY unless login_file used) specification of password [String]
    $self->{web_service_user} = $web_service_user;

    $self->{log_call} = $log_call;
    ### query attributes ###
    $self->{field_list}           = ();
    $self->{join_conditions}      = {};
    $self->{tables}               = '';
    $self->{join_tables}          = '';
    $self->{left_join_tables}     = '';
    $self->{left_join_conditions} = {};
    $self->{order}                = '';
    $self->{key}                  = '';

    $self->{trace}      = $trace;         # set trace level on database connection (defaults to 0) [Int]
    $self->{trace_file} = $trace_file;    # optional trace_file where trace info to be written. (required if trace_level set) [String]
    $self->{quiet}      = $quiet;         # suppress printed feedback (defaults to 0) [Int]

    if ($connect) {
        $self->connect_to_DB();
        $self->{isConnected} = 1;
    }
    else {
        $self->{isConnected} = 0;
    }

    $self->{warnings} = [];
    $self->{errors}   = [];

    return $self;
}

##############################
# public_methods             #
##############################

##########################
sub DESTROY {
##########################
    my $self = shift;

    $self->dbh()->disconnect();
}

##############
sub warning {
##############
    my $self    = shift;
    my $warning = shift;

    push @{ $self->{warnings} }, $warning;
    Message($warning) unless $self->{quiet};
    return;
}

#################
sub warnings {
#################
    my $self    = shift;
    my $message = '';
    if ( @{ $self->{warnings} } ) {
        $message .= "\n*****************\n** Warnings: \n*****************\n";
        $message .= join "\n", @{ $self->{warnings} };
        $message .= "\n\n";
    }
    return $message;
}
##############
sub error {
##############
    my $self  = shift;
    my $error = shift;

    push @{ $self->{errors} }, $error;
    return;
}
#################
sub errors {
#################
    my $self    = shift;
    my $message = '';
    if ( @{ $self->{errors} } ) {
        $message .= "\n*****************\n** Errors: \n*****************\n";
        $message .= join "\n", @{ $self->{errors} };
        $message .= "\n\n";
    }
    return $message;
}
###########################
# Connect to database using either LIMS password or direct DB password
#
# <snip>
# Example:  $LIMS->connect_to_DB();  # LIMS_user, LIMS_password or DB_user, DB_password should have been sent to constructor
# </snip>
#
######################
sub connect_to_DB {
######################
    my $self = shift;

    ## required to use DIFFERENT password from login password to access database ##

    my $LIMS_user     = $self->{LIMS_user}     || '';
    my $LIMS_password = $self->{LIMS_password} || '';
    my $DB_user       = $self->{DB_user}       || '';
    my $DB_password   = $self->{DB_password}   || '';    ## normally this should not be passed in (retrieved automatically from login_file during connect process)

    if ( $self->{LIMS_user} ) {
        my $validated = $self->_password_check( -LIMS_user => $LIMS_user, -LIMS_password => $self->{LIMS_password}, -DB_user => $DB_user );

        unless ($validated) {
            print "$LIMS_user failed to connect as $DB_user.\n";
            return;
        }
    }
    $self->connect( -password => $DB_password );

    if ( $self->dbh() && $self->dbh()->ping() ) {
        $self->{isConnected} = $self->dbh();
        if ( $self->{log_call} ) {
            $self->set_log_file();
        }
        else {
            Message("NO Log call") if ( !$self->{quiet} );
        }
    }
    else {
        $self->{isConnected} = 0;
        die "Connection to database failed : Aborting...\n";
    }

    # set permissions if user set

    $LIMS_user ||= 'API client';    ## default user for API - enables tracking of Change History tied to Employee_ID
    if ($LIMS_user) {
        my ($emp_id) = $self->Table_find( "Employee", "Employee_ID", "WHERE Email_Address='$LIMS_user' OR Employee_Name = '$LIMS_user'" );
        unless ($emp_id) {
            $self->error("** Invalid user ($LIMS_user) - cannot set permissions **");
            return;
        }
        $self->set_local( 'user_id', $emp_id );
        my $eo = new alDente::Employee( -dbc => $self, -id => $emp_id );
        $eo->define_User();
    }

    # Update Aliases with Field_Reference by using the database connection
    for my $table ( keys %Aliases ) {
        for my $key ( keys %{ $Aliases{$table} } ) {
            if ( $Aliases{$table}{$key} =~ /Field_Reference\((.+)\)/ ) {
                my $field = $1;
                ( $Aliases{$table}{$key} ) = $self->Table_find( "DBField", "Field_Reference", "WHERE Field_Name = '$field'" );
            }
        }
    }

    return $self;

}

#
#
# Establish path to logging file
#
##################
sub set_log_file {
##################
    my $self             = shift;
    my $LIMS_user        = shift || $self->{LIMS_user} || '';
    my $DB_user          = shift || $self->{DB_user} || '';
    my $web_service_user = shift || $self->{web_service_user} || '';
    if ($web_service_user) { $web_service_user = "-$web_service_user" }

    my $LOGBASE    = $Configs{Home_public} . '/logs/API_logs';                                    ## Log file base name (should be globally accessible location)
    my $LOGPATH    = create_dir( $LOGBASE, convert_date( &date_time(), 'YYYY/MM/DD' ), '777' );
    my $url_domain = try_system_command('hostname');
    chomp $url_domain;
    $url_domain =~ s/\..*//;

    if ( !-e $LOGPATH ) {
        print "Error: couldn't create $LOGPATH\n";
    }
    if ($LIMS_user) {
        $self->{log_file} = "$LOGPATH/API_usage.$url_domain.$DB_user-$LIMS_user$web_service_user.log";
    }
    else {
        my $user = try_system_command('whoami');
        chomp $user;
        $self->{log_file} = "$LOGPATH/API_usage.$url_domain.$DB_user.$user$web_service_user.log";
    }

    return 1;
}

################################################
# return: hash containing number of records retrieved
##############
sub records {
##############
    my $self = shift;
    return $self->{records};
}

###########################################################################
#
# <CONSTRUCTION> All of the get_record and associated functionality should be inhereted from the DBIO / GSDB level.
#
###########################################
# To be used when retrieved data is saved
#  (use -save option in data extraction method to enable)
#
# Retrieves the current record
#
# <snip>
# Example:
#   my $data = get_Plate_data(-library=>'LIB01',-save=>1);
#
#   my $plate1 = $data->get_record();
#   ...
#   my $plate20 = $data->get_record(20);
#
#   ## (example of data format for first record retrieved ($plate1))
#   $plate1 = {plate_id => 2000,
#              library  => 'LIB01',
#              plate_number => 1,
#              ....
# </snip>
#
# return: hash containing next record values
##############
sub get_record {
##############
    my $self  = shift;
    my $index = shift;

    if ( defined $index ) {
        $self->{record_index} = $index;
        $self->{more_records} = $self->{records} - $index;
    }

    unless ( $self->{data} ) { print "No Data retrieved (did you use the -save option ?)"; return {}; }
    unless ( $self->{records} ) { print "No more records returned"; }
    unless ( defined $self->{record_index} ) { $self->{record_index} = 0 }
    my @keys = keys %{ $self->{data} };
    my %hash;
    foreach my $key (@keys) {
        $hash{$key} = $self->{data}{$key}[ $self->{record_index} ];
    }
    return \%hash;
}

############################################
# To be used when retrieved data is saved
#  (use -save option in data extraction method to enable)
#
# Retrieves the next record
# <snip>
# Example:
#   my $data = get_Plate_data(-library=>'LIB01',-save=>1);
#   foreach my $plate (1 .. $data->record_count()) {
#     my $plate = $data->get_next_record();
#     ...
#
#     ## each subsequent call retrieves a new record ##
#     $plate1 = {plate_id => 2000,
#              library  => 'LIB01',
#              plate_number => 1,
#              ....
#   }
# </snip>
#
# return: hash containing next record values
##################
sub get_next_record {
##################
    my $self = shift;

    unless ( defined $self->next_record() ) {
        $self->warning("No more records");
        return;
    }
    return $self->get_record();
}

###############################################
# To be used when retrieved data is saved
#  (use -save option in data extraction method to enable)
#
# increments index (useful when calling get_data('attribute')
#
# <snip>
# Example:
#   my $data = get_Plate_data(-library=>'LIB01',-save=>1);
#   foreach my $plate (1 .. $data->record_count()) {
#     my $plate = $data->get_record();
#     $data->next_record();
#   }
#  ## note these two lines (get_record... next_record) are equivalent to simply : get_next_record.
# </snip>
#
# return: index counter
##############
sub next_record {
##############
    my $self = shift;

    if ( $self->{records} ) {
        if ( !defined $self->{record_index} ) { $self->{record_index} = 0 }
        elsif ( $self->{record_index} >= $self->{records} - 1 ) {
            print "No more records\n";
            $self->{more_records} = 0;
            $self->{record_index} = $self->{records} - 1;
            return;
        }
        else {
            $self->{record_index}++;
        }

        $self->{more_records} = $self->{records} - $self->{record_index} - 1;
    }
    elsif ( $self->{data} ) {
        print "No records retrieved\n";
        return;
    }
    else {
        print "No Data saved\n";
        return;
    }
    return $self->{record_index};
}

#############################################
# To be used when retrieved data is saved
#  (use -save option in data extraction method to enable)
#
# resets index when using 'get_attribute' or 'get_next_attribute'
#
#
# return: total records in saved data set
#######################
sub reset_record_index {
######################
    my $self  = shift;
    my $index = shift;

    if ( defined $index ) {
        $self->{record_index} = $index;
        $self->{more_records} = $self->{records} - $index - 1;
    }
    elsif ( $self->{records} ) {
        $self->{record_index} = undef;
        $self->{more_records} = $self->{records};
    }
    elsif ( $self->{data} ) {
        print "No records retrieved";
    }
    else {
        print "No Data saved";
    }
    return $self->{records};
}

######################
sub get_lookup_data {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -args => 'lookup', -mandatory => 'lookup' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $table = $args{-lookup};
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key} || $group;
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

    ### Re-Cast arguments as required ###

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = $table;                                        ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE 1';                                     ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                            ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {};                                             ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {};                                        ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = $self->get_fields( -table => $table );               ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
    );
}

#############################
## Data extraction methods ##
#############################
# sample
# source
# plate
# library
# run
#############################
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
# (see _generate_query method for more details on input parameter options)
#
# Returns: hash (eg %data->{field1}=[val1,val2,val3..] etc.) or a hash for each record (format=>'array' or key=>'$key')
###################
sub get_Clone_data {    # (same as get_sample_data)
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    return $self->get_sample_data(%args);
}

#####################
# Retrieve field type for field or alias.
#
# In case of aliases which do not map directly to a single field, the method will return a literal translation of the field.
#
# eg.
# get_field_type("Max(Plate_ID)") returns 'LITERAL: Max(Plate_ID)'.
# get_field_type('unique_samples') = "LITERAL: count(DISTINCT Clone_Sequence.FK_Sample__ID)"
#
# Return: field type or "LITERAL: <literal translation>"
#####################
sub get_field_type {
#####################
    my $self  = shift;
    my $field = shift;

    ## check if using alias first ##
    foreach my $key ( keys %Aliases ) {
        if ( defined $Aliases{$key}{$field} ) {
            $field = $Aliases{$key}{$field};
            last;
        }
    }

    my $extra_condition;
    if ( $field =~ /^(\w+)\.(\w+)$/ ) {
        ## field fully qualified with table name ##
        $field           = $2;
        $extra_condition = " AND DBTable_Name = '$1'";
    }

    my ($field_type) = $self->Table_find( 'DBField,DBTable', 'Field_Type', "WHERE FK_DBTable__ID=DBTable_ID AND Field_Name = '$field' $extra_condition" );

    unless ($field_type) {
        return "LITERAL: $field";    ## return literal string if no single field identified.
    }

    return $field_type;
}

#

# Template for creating a new database object api
# Fill in the necessary options, conditions and tables
#
############################
sub get_template_data {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id         = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id       = $args{-project_id};          ### specify project_id
    my $library          = $args{-library};             ### specify library
    ## plate specification options
    my $plate_id          = $args{-plate_id};                   ### specify plate_id
    my $plate_number      = $args{-plate_number};               ### specify plate number
    my $well              = $args{-well};                       ### specify plate number
    my $plate_type        = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class       = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};          ### specify original plate id
    my $original_well     = $args{-original_well};              ### specify original well
    my $applied_plate_id  = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant          = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id         = $args{-sample_id};                  ### specify sample_id
    my $run_id            = $args{-run_id};
    my $library_type      = $args{-library_type};

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                                  ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || '';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $wells;
    $wells = Cast_List( -list => $well, -to => 'string', -autoquote => 1 ) if $well;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = '';    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = '';    ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';    ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {};     ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {};    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw();            ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
    );
}

#########################################################
# Retrieve data about Stock Items
# (Use to retrieve information about Solutions, Equipment, Boxes etc
#
# <SNIP>
# Example:
#   $API->get_stock_data(-barcode=>'sol19883',-fields=>'primer_sequence');
#
#   $API->get_stock_data(-type=>'solution',-id=>'19883', -add_fields=>['Solution.FK_Rack__ID']);
#</SNIP>
#
#####################
sub get_stock_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -mandatory => 'type|barcode' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention
    my $barcode            = $args{-barcode};
    my $id                 = $args{-id};
    my $type               = $args{-type};
    my $name               = $args{-name};
    my $cat                = $args{-catalog_number};
    my $vendor             = $args{-vendor};
    my $manufacturer       = $args{-manufacturer};
    my $equipment_category = $args{-equipment_category};

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    ## plate specification options
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                          ### specify Received date to begin search (context dependent)
    my $until = $args{ -until };                        ### specify Received date to stop search (context dependent)

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            my @field_list = qw(Stock_Catalog_Name Stock_Received Stock_Catalog.Stock_Catalog_Number vendor manufacturer);    ## <- Default list of fields to retrieve

            ## Set type if barcode supplied directly ##
            if ( $barcode =~ /^(sol|equ|box)(\d+)/ ) {
        my $prefix = $1;
        my $table;
        if    ( $prefix =~ /sol/ ) { $table = 'Solution' }
        elsif ( $prefix =~ /equ/ ) { $table = 'Equipment' }
        elsif ( $prefix =~ /box/ ) { $table = 'Box' }

        if ($table) {
            $id = $self->get_FK_ID( "FK_" . $table . "__ID", $barcode );
        }
        else {
            $self->error("Item prefix: $prefix not recognized");
            return;
        }

        $type ||= $table;
    }

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = 'Stock,Stock_Catalog';                                    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE Stock.FK_Stock_Catalog__ID = Stock_Catalog_ID';    ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                                       ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####

    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {
        ## standards ##

        ## special cases included dynamically if required ##
        "Primer" => "Primer.Primer_Name=Stock_Catalog_Name",
    };                                                                               ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ### Re-Cast arguments as required ###
    my $ids;
    $ids = Cast_List( -list => $id, -to => 'string' ) if $id;
    ## adjust type ##
    if ( $type =~ /(primer)/i ) {
        push @field_list, 'Primer.Primer_Sequence', 'solution_status';
        $join_conditions->{'Solution'} = "Solution.FK_Stock__ID = Stock_ID";
    }

    if ( $type =~ /(solution|reagent|primer|matrix|buffer)/i ) {
        $type = 'Solution';
        push @field_list, 'solution_type', 'solution_status';

    }
    elsif ( $type =~ /(box|kit)/i ) {
        $type = 'Box';
        push( @field_list, 'Box.Box_Type' );
    }
    elsif ( $type =~ /equipment/i ) {
        $type                                    = 'Equipment';
        $join_conditions->{$type}                = "$type.FK_Stock__ID = Stock_ID";
        $join_conditions->{'Equipment_Category'} = "Stock_Catalog.FK_Equipment_Category__ID=Equipment_Category.Equipment_Category_ID";
        $join_conditions->{Location}             = 'Equipment.FK_Location__ID=Location.Location_ID';
        push @field_list, 'equipment_status', 'equipment_category', 'equipment_location', 'equipment_id';

    }
    elsif ( $type =~ /misc/i ) {
        $type = 'Misc_Item';
        push @field_list, 'Misc_Item.Misc_Item_Type';
    }

    if ( $type && $type !~ /equipment/i ) {
        ## add location fields ##
        $join_conditions->{$type} = "$type.FK_Stock__ID = Stock_ID";

        if ( $type !~ /equipment/ ) {
            $join_conditions->{Rack}                   = "$type.FK_Rack__ID = Rack.Rack_ID";
            $join_conditions->{'Equipment as Storage'} = "Rack.FK_Equipment__ID=Storage.Equipment_ID";
            $join_conditions->{Location}               = 'Storage.FK_Location__ID=Location.Location_ID';
        }
    }

    if ( $ids && $type ) { push( @extra_conditions, "$type.$type" . "_ID IN ($ids)" ); }
    elsif ($ids) { push( @extra_conditions, "Stock.Stock_ID IN ($ids)" ); }

    if ($name) { push @extra_conditions, "Stock_Catalog.Stock_Catalog_Name LIKE '$name'" }
    if ($cat)  { push @extra_conditions, "Stock_Catalog.Stock_Catalog_Number LIKE '$name'" }
    if ($vendor) {
        push @extra_conditions, "vendor like '$vendor'";
    }
    if ($manufacturer) {
        push @extra_conditions, "manufacturer like '$manufacturer'";
    }
    if ($equipment_category) {
        push @extra_conditions, "equipment_category like '$equipment_category%'";
    }

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Organization as Vendor'       => 'Stock_Catalog.FKVendor_Organization__ID=Vendor.Organization_ID',
        'Organization as Manufacturer' => 'Stock_Catalog.FK_Organization__ID=Manufacturer.Organization_ID',
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
        -date_field           => "Stock.Stock_Received",
    );
}

##############################################
# API to retrieve a list of sample origin types
# <snip>
#   Example:
#   my $original_source_types = $API->get_sample_origin_type_data();
#
# </snip>
# Return: array ref of data
#######################
sub get_sample_origin_type_data {
#######################
    my $self = shift;

    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $table               = 'Original_Source';
    my $field               = 'Original_Source_Type';
    my @sample_origin_types = $self->get_enum_list( $table, $field );

    return \@sample_origin_types;
}

##############################################
# API to retrieve library information
# <snip>
#   Example:
#   my $library = "HGL01";
#   my $libary_data = $API->get_library_data(-library=>$library);
#
# </snip>
# Return: hash of data
#######################
sub get_library_data {
#######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';                ### extra condition (vulnerable to structure change)
    my $study_id         = $args{-study_id}  || $args{ -study };    ### a study id (a defined set of libraries/projects)
    my $project_id       = $args{-project_id};                      ### specify project_id
    my $library          = $args{-library};                         ### specify library
    my $library_type     = $args{-library_type};                    ### specify the library type to filter on
    my $debug            = $args{-debug};
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    my $goal = $args{-goal};                                        ### Retrieve information for libraries with specified goal.

    my $goal_type               = $args{-goal_type};                ### specify the type of goal to filter on (ie 'Lab Work','Data Analysis','Custom Data Analysis')
    my $library_analysis_status = $args{-library_analysis_status};  ### specify the library_analysis_status (ie 'N/A', 'In production','Complete')
    ## Inclusion / Exclusion options
    my $since = $args{-since};                                      ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                    ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Library.Library_Obtained_Date';

            ## Output options
            my $fields     = $args{-fields} || '';
            my $add_fields = $args{-add_fields};
            my $order      = $args{-order} || '';                   ### ORDER BY
                                                                    #my $group       = $args{-group} || $args{-group_by} || $args{-key} || 'library';    ### GROUP BY
            my $KEY        = $args{-key};                           # || $group;                               ### KEY on

            my $group;
            if ( defined( $args{-group} ) ) {
        $group = $args{-group};
        $KEY = $group if !$KEY;
    }
    elsif ( defined( $args{-group_by} ) ) {
        $group = $args{-group_by};
        $KEY = $group if !$KEY;
    }
    elsif ( defined $args{-key} ) {
        $group = $args{-key};
    }
    else {
        $group = 'library';
    }

    my $limit       = $args{-limit} || '';    ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};          ### suppress feedback by setting quiet option
    my $save        = $args{-save};
    my $list_fields = $args{-list_fields};    ### just generate a list of output fields

    ### Re-Cast arguments if necessary ###
    my $study_ids;
    $study_ids = Cast_List( -list => $study_id, -to => 'string' ) if $study_id;
    my $project_ids;
    $project_ids = Cast_List( -list => $project_id, -to => 'string' ) if $project_id;
    my $libraries;
    $libraries = Cast_List( -list => $library, -to => 'string', -autoquote => 1 ) if $library;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;
    my $goals = Cast_List( -list => $goal, -to => 'string', -autoquote => 1 ) if $goal;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    my $tables           = 'Library,Original_Source';                                    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE Library.FK_Original_Source__ID=Original_Source_ID';    ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                                           ## <- Supply additional tables to left_join (includes condition)

    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {
        'Project'      => 'Library.FK_Project__ID=Project.Project_ID',
        'Contact'      => 'Library.FK_Contact__ID=Contact.Contact_ID',
        'Organization' => 'Contact.FK_Organization__ID=Organization.Organization_ID',

        #	'Vector_Based_Library'                    =>'Vector_Based_Library.FK_Library__Name = Library.Library_Name',
        'RNA_DNA_Collection'                    => 'RNA_DNA_Collection.FK_Library__Name = Library.Library_Name',
        'LibraryApplication'                    => 'LibraryApplication.FK_Library__Name = Library.Library_Name',                   ## only relevant if primer specified as condition/field
        'Contact as Original_Contact'           => 'Original_Source.FK_Contact__ID = Original_Contact.Contact_ID',
        'Organization as Original_Organization' => 'Original_Contact.FK_Organization__ID=Original_Organization.Organization_ID',
        'Primer'                                => 'LibraryApplication.Object_ID = Primer.Primer_ID',
        'Source'                                => 'Library_Source.FK_Source__ID = Source.Source_ID',
        'Library_Source'                        => 'Library_Source.FK_Library__Name=Library.Library_Name',

        # 'Organism'                              =>'Original_Source.FK_Organism__ID = Organism.Organism_ID',
        'Taxonomy' => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
        'Grp'      => 'Library.FK_Grp__ID = Grp_ID',
    };

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Vector_Based_Library'                 => 'Vector_Based_Library.FK_Library__Name = Library.Library_Name',
        'SAGE_Library'                         => 'SAGE_Library.FK_Vector_Based_Library__ID = Vector_Based_Library.Vector_Based_Library_ID',
        'Mapping_Library'                      => 'Mapping_Library.FK_Vector_Based_Library__ID = Vector_Based_Library.Vector_Based_Library_ID',
        'Stage'                                => 'Original_Source.FK_Stage__ID = Stage.Stage_ID',
        'Work_Request as Library_Work_Request' => 'Library.Library_Name = Library_Work_Request.FK_Library__Name',
        'Goal as Library_Goal'                 => 'Library_Work_Request.FK_Goal__ID = Library_Goal.Goal_ID',
        'Funding as Library_Funding'           => 'Library_Work_Request.FK_Funding__ID = Library_Funding.Funding_ID',
        'Cell_Line'                            => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
        'Pathology'                            => 'Pathology.Pathology_ID = Original_Source.FK_Pathology__ID',
        'Anatomic_Site'                        => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
        'Histology'                            => 'Pathology.FK_Histology__ID = Histology.Histology_ID',
        'Patient'                              => 'Patient.Patient_ID = Original_Source.FK_Patient__ID',
        'Strain'                               => 'Original_Source.FK_Strain__ID = Strain.Strain_ID',
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    if ($study_ids) {
        my @libs = $self->Table_find( 'Study,LibraryStudy', 'FK_Library__Name', "WHERE FK_Study__ID=Study_ID AND (Study_ID = $study_id OR Study_Name = '$study_id')" );
        my @proj_libs
            = $self->Table_find( 'Study,Library,ProjectStudy', 'Library_Name', "WHERE FK_Study__ID=Study_ID AND ProjectStudy.FK_Project__ID=Library.FK_Project__ID AND Library.FK_Project__ID > 0 AND (Study_ID = $study_id OR Study_Name = '$study_id')" );
        $libraries = Cast_List( -list => [ @libs, @proj_libs ], -to => 'string', -autoquote => 1 );
    }

    my @field_list
        = qw(library original_source_id library_status organism anatomic_site cell_line_name original_source_type strain host library_started library_source library_source_name contact contact_position contact_phone contact_email contact_organization original_contact original_contact_position original_contact_phone original_contact_email original_contact_organization project library_description)
        ;    ## <- Default list of fields to retrieve

    if ($project_ids) {
        if ( $project_ids =~ /[a-z]+/i ) {
            push( @extra_conditions, "Project.Project_Name = '$project_ids'" );
        }
        else {
            push( @extra_conditions, "Library.FK_Project__ID IN ($project_ids)" );
        }
    }
    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($library_types)       { push( @extra_conditions, "Library.Library_Type IN ($library_types)" ) }
    if ($goal_type) {
        $goal_type = RGTools::Conversion::wildcard_to_SQL($goal_type);
        push( @extra_conditions, "Library_Goal.Goal_Type LIKE '$goal_type'" );

    }

    if ($goals) {
        push( @field_list, 'library_goal', 'library_goal_target' );
        push( @extra_conditions, "Library_Goal.Goal_Name IN ($goals)" );
    }
    if ($library_analysis_status) {
        $library_analysis_status = Cast_List( -list => $library_analysis_status, -to => 'String' );
        push @extra_conditions, "Library_Analysis_Status IN ($library_analysis_status)";
    }

    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    #if ( $library_type =~ /Sequencing/ ) {
    if ( $library_type =~ /Vector_Based/ ) {
        push( @field_list, 'vector', 'direction', 'library_format' );
    }
    elsif ( $library_type =~ /RNA_DNA_Collection/ ) {

    }

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,

        #        -attribute_link       => "Original_Source.original_source_id",
        -date_field => "Library.Library_Obtained_Date",
    );
}

############################
# API to retrieve pipeline information
# <snip>
#   Example:
#   my $pipeline = "IPE";
#   my $pipeline_data = $API->get_pipeline_data(-pipeline_code => $pipeline);
#
# </snip>
# Return: hash of data
############################
sub get_pipeline_data {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval

    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $pipeline_id      = $args{-pipeline_id};
    my $pipeline_name    = $args{-pipeline_name};
    my $pipeline_code    = $args{-pipeline_code};
    my $pipeline_type    = $args{-pipeline_type};
    my $pipeline_group   = $args{-pipeline_group};
    my $plate_format     = $args{-plate_format};
    my $group_name       = $args{-group_name};
    my $pipeline_status  = $args{-pipeline_status};
    ## plate specification options

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};      ### specify date to begin search (context dependent)
    my $until = $args{ -until };    ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || '';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $pipeline_ids;
            $pipeline_ids = Cast_List( -list => $pipeline_id, -to => 'string' ) if $pipeline_id;
    my $pipeline_codes;
    $pipeline_codes = Cast_List( -list => $pipeline_code, -to => 'string', -autoquote => 1 ) if $pipeline_code;
    my $pipeline_types;
    $pipeline_types = Cast_List( -list => $pipeline_type, -to => 'string', -autoquote => 1 ) if $pipeline_type;
    my $pipeline_groups;
    $pipeline_groups = Cast_List( -list => $pipeline_group, -to => 'string', -autoquote => 1 ) if $pipeline_group;
    my $plate_formats;
    $plate_formats = Cast_List( -list => $plate_format, -to => 'string', -autoquote => 1 ) if $plate_format;
    my $group_names;
    $group_names = Cast_List( -list => $group_name, -to => 'string', -autoquote => 1 ) if $group_name;
    my $pipeline_statuses;
    $pipeline_statuses = Cast_List( -list => $pipeline_status, -to => 'string', -autoquote => 1 ) if $pipeline_status;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = 'Pipeline';    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE 1';     ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';            ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = { 'Grp' => 'Pipeline.FK_Grp__ID = Grp.Grp_ID' };

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Plate_Format'       => 'Pipeline.FKApplicable_Plate_Format__ID = Plate_Format.Plate_Format_ID',
        'Pipeline_Group'     => 'Pipeline.FK_Pipeline_Group__ID = Pipeline_Group.Pipeline_Group_ID',
        'Pipeline as Parent' => 'Pipeline.FKParent_Pipeline__ID = Parent.Pipeline_ID',
    };                                    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    if ($pipeline_ids)      { push( @extra_conditions, "Pipeline.Pipeline_ID IN ($pipeline_ids)" ) }
    if ($pipeline_name)     { push( @extra_conditions, "Pipeline.Pipeline_Name LIKE '%$pipeline_name%'" ) }
    if ($pipeline_codes)    { push( @extra_conditions, "Pipeline.Pipeline_Code IN ($pipeline_codes)" ) }
    if ($pipeline_types)    { push( @extra_conditions, "Pipeline.Pipeline_Type IN ($pipeline_types)" ) }
    if ($pipeline_groups)   { push( @extra_conditions, "Pipeline_Group.Pipeline_Group_Name IN ($pipeline_groups)" ) }
    if ($plate_formats)     { push( @extra_conditions, "Plate_Format.Plate_Format_Type IN ($plate_formats)" ) }
    if ($group_names)       { push( @extra_conditions, "Grp.Grp_Name IN ($group_names)" ) }
    if ($pipeline_statuses) { push( @extra_conditions, "Pipeline_Status IN ($pipeline_statuses)" ) }

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw( pipeline_id pipeline_name pipeline_code pipeline_type pipeline_description pipeline_group plate_format group_name );    ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet
    );
}

############################
#
############################
sub get_trace_submission_data {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval

    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $library          = $args{-library};
    my $analysis_id      = $args{-analysis_id};
    my $sample_id        = $args{-sample_id};
    my $run_id           = $args{-run_id};
    my $sample_alias     = $args{-sample_alias};
    ## plate specification options

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                          ### specify date to begin search (context dependent)
    my $until = $args{ -until };                        ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || '';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $libraries;
            $libraries = Cast_List( -list => $library, -to => 'string', -autoquote => 1 ) if $library;
    my $analysis_ids;
    $analysis_ids = Cast_List( -list => $analysis_id, -to => 'string', -autoquote => 1 ) if $analysis_id;
    my $sample_ids;
    $sample_ids = Cast_List( -list => $sample_id, -to => 'string', -autoquote => 1 ) if $sample_id;
    my $run_ids;
    $run_ids = Cast_List( -list => $run_id, -to => 'string', -autoquote => 1 ) if $run_id;
    my $sample_aliases;
    $sample_aliases = Cast_List( -list => $sample_alias, -to => 'string', -autoquote => 1 ) if $sample_alias;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = 'Trace_Submission, Submission_Volume,Sample';                                                                                                 ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE Trace_Submission.FK_Submission_Volume__ID = Submission_Volume.Submission_Volume_ID and Trace_Submission.FK_Sample__ID = Sample_ID';    ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                                                                                                                           ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {};

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Run_Link'                         => 'Run_Link.FK_Trace_Submission__ID = Trace_Submission.Trace_Submission_ID',
        'Metadata_Object as Run_MO'        => "Run_MO.Metadata_Object_ID = Run_Link.FKRun_Metadata_Object__ID and Run_MO.Object_Type = 'Run'",
        'Metadata_Object as Experiment_MO' => "Experiment_MO.Metadata_Object_ID = Run_Link.FKExperiment_Metadata_Object__ID and Experiment_MO.Object_Type = 'Experiment'",
        'Experiment_Link'                  => 'Experiment_Link.FKExperiment_Metadata_Object__ID = Experiment_MO.Metadata_Object_ID',
        'Metadata_Object as Sample_MO'     => "Sample_MO.Metadata_Object_ID = Experiment_Link.FKSample_Metadata_Object__ID and Sample_MO.Object_Type = 'Sample'",
        'Metadata_Object as Study_MO'      => "Study_MO.Metadata_Object_ID = Experiment_Link.FKStudy_Metadata_Object__ID and Study_MO.Object_Type = 'Study'",
        'Analysis_Link'                    => 'Analysis_Link.FKStudy_Metadata_Object__ID = Study_MO.Metadata_Object_ID and Analysis_Link.FKSample_Metadata_Object__ID = Sample_MO.Metadata_Object_ID',
        'Metadata_Object as Analysis_MO'   => "Analysis_MO.Metadata_Object_ID = Analysis_Link.FKAnalysis_Metadata_Object__ID and Analysis_MO.Object_Type = 'Analysis'",
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    if ($libraries)      { push( @extra_conditions, "Sample.FK_Library__Name IN ($libraries)" ) }
    if ($analysis_ids)   { push( @extra_conditions, "Analysis_MO.Unique_Identifier IN ($analysis_ids)" ) }
    if ($sample_ids)     { push( @extra_conditions, "Sample_MO.Unique_Identifier IN ($sample_ids)" ) }
    if ($run_ids)        { push( @extra_conditions, "Run_MO.Unique_Identifier IN ($run_ids)" ) }
    if ($sample_aliases) { push( @extra_conditions, "Sample_MO.Alias IN ($sample_aliases)" ) }

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw( trace_submission_id library analysis_unique_id study_unique_id sample_unique_id run_unique_id );    ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
    );
}

####################
#
# New method to simplify run data extraction (avoids complexity of _generate_query method)
# (this style should replace all of the other API methods as well to simplify maintenance / debugging.
#
# Return: hash of data
#########################
sub get_sample_data {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_,
        -mandatory =>
            "condition|study_id|project_id|library|plate_id|plate_number|well|plate_type|plate_class|plate_application|original_plate_id|original_well|applied_plate_id|sample_id|parent_sample_id|library_type|since|until|original_source_id|source_id|original_source_name"
    );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id         = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id       = $args{-project_id};          ### specify project_id
    my $library          = $args{-library};             ### specify library
    ## plate specification options
    my $plate_id             = $args{-plate_id};                   ### specify plate_id
    my $plate_number         = $args{-plate_number};               ### specify plate number
    my $well                 = $args{-well};                       ### specify plate number
    my $plate_type           = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class          = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application    = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id    = $args{-original_plate_id};          ### specify original plate id
    my $original_well        = $args{-original_well};              ### specify original well
    my $applied_plate_id     = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant             = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id            = $args{-sample_id};                  ### specify sample_id
    my $parent_sample_id     = $args{-parent_sample_id};           ### specify FKParent_Sample__ID
    my $library_type         = $args{-library_type};
    my $original_source_id   = $args{-original_source_id};
    my $original_source_name = $args{-original_source_name};
    my $source_id            = $args{-source_id};

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                                     ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                   ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Plate_Created';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key};
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
            ## Special Conditions ##
            my $attribute   = $args{-attribute};                                  ### specify an attribute to extract (only one allowed for now)
            my $alias_type  = $args{-alias_type};                                 ### specify an attribute to extract (only one allowed for now)
            my $alias_value = $args{-alias_value};
            $alias_value = Cast_List( -list => $alias_value, -to => 'String', -autoquote => 1 );
    my $sample_type = $args{-sample_type} || 'extraction';

    ### Re-Cast arguments if necessary ###
    my $libs;
    $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $wells;
    $wells = Cast_List( -list => $well, -to => 'string', -autoquote => 1 ) if $well;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $parent_samples;
    $parent_samples = Cast_List( -list => $parent_sample_id, -to => 'string' ) if $parent_sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;

    my $original_source_ids;
    $original_source_ids = Cast_List( -list => $original_source_id, -to => 'string', -autoquote => 1 ) if $original_source_id;
    my $original_source_names;
    $original_source_names = Cast_List( -list => $original_source_name, -to => 'string', -autoquote => 1 ) if $original_source_name;
    my $source_ids;
    $source_ids = Cast_List( -list => $source_id, -to => 'string', -autoquote => 1 ) if $source_id;

    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

##########################################
    # Retrieve Record Data from the Database #
##########################################

    ## Generate Condition ##
    my $tables = 'Sample,Plate_Sample,Plate,Source,Original_Source,Library';

    my $join_condition = "WHERE Plate_Sample.FK_Sample__ID=Sample_ID AND Plate_Sample.FKOriginal_Plate__ID=Plate_ID";
    $join_condition .= " AND Sample.FK_Source__ID=Source.Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID";
    $join_condition .= " AND Plate.FK_Library__Name=Library_Name";

    my $left_join_tables = '';    ## always included ... Clone_Sample' ;

    ## specify optional tables to include (with associated condition) - used in 'include_if_necessary' method ##
    my $join_conditions = {
        'Project'          => "Project.Project_ID=Library.FK_Project__ID",
        'Library_Plate'    => "Library_Plate.FK_Plate__ID=Plate.Plate_ID",
        'ConcentrationRun' => "Concentrations.FK_ConcentrationRun__ID=ConcentrationRun_ID",
        'Concentrations'   => "Concentrations.FK_Sample__ID=Sample_ID",
        'Clone_Source'     => "Clone_Source.FK_Clone_Sample__ID = Clone_Sample.Clone_Sample_ID",

        #	'Clone_Sample'   => "Clone_Sample.FK_Sample__ID=Sample.Sample_ID",
        'Sample_Attribute' => 'Sample_Attribute.FK_Sample__ID=Sample_ID',
        'Attribute'        => 'Sample_Attribute.FK_Attribute__ID=Attribute.Attribute_ID',
        'Sample_Alias'     => "Sample_Alias.FK_Sample__ID=Sample_ID",
        'Source_Pool'      => "FKChild_Source__ID = FK_Source__ID",

        # 'Organism'               => 'Original_Source.FK_Organism__ID = Organism.Organism_ID',
        'Taxonomy' => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
    };

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Clone_Sample'       => "Clone_Sample.FK_Sample__ID=Sample.Sample_ID",
        'Extraction_Sample'  => "Extraction_Sample.FK_Sample__ID=Sample.Sample_ID",
        'LibraryApplication' => "Library.Library_Name=LibraryApplication.FK_Library__Name",
        'Primer'             => "Primer.Primer_ID=LibraryApplication.Object_ID",
        'Source as PoolSrc'  => "Source_Pool.FKParent_Source__ID = PoolSrc.Source_ID",
        'Anatomic_Site'      => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
        'Cell_Line'          => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
        'Pathology'          => 'Pathology.Pathology_ID = Original_Source.FK_Pathology__ID',
        'Shipment'           => 'Source.FK_Shipment__ID = Shipment.Shipment_ID',
        'Histology'          => 'Pathology.FK_Histology__ID = Histology.Histology_ID',
        'Patient'            => 'Patient.Patient_ID = Original_Source.FK_Patient__ID',
        'Strain'             => 'Original_Source.FK_Strain__ID = Strain.Strain_ID',
    };

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($plates)              { push( @extra_conditions, "Plate.Plate_ID IN ($plates)" ) }
    if ($plate_numbers)       { push( @extra_conditions, "Plate.Plate_Number IN ($plate_numbers)" ) }
    if ($wells)               { push( @extra_conditions, "Plate_Sample.Well IN ($wells)" ) }                                                                              ## <CONSTRUCTION> -should be more flexible (ie well for donwstream plate)
    if ($samples)             { push( @extra_conditions, "Sample_ID IN ($samples)" ) }
    if ($parent_samples)      { push( @extra_conditions, "FKParent_Sample__ID IN ($parent_samples)" ) }
    if ($library_types)       { push( @extra_conditions, "(Vector_Based_Library.Vector_Based_Library_Type IN ($library_types) OR Library_Type IN ($library_types))" ) }

    if ($source_ids)            { push @extra_conditions, "Source_ID IN ($source_ids)" }
    if ($original_source_ids)   { push @extra_conditions, "Original_Source_ID IN ($original_source_ids)" }
    if ($original_source_names) { push @extra_conditions, "Original_Source_Name IN ($original_source_names)" }

    if ($attribute)   { push( @extra_conditions, "Attribute.Attribute_Name = '$attribute'" ) }
    if ($alias_type)  { push( @extra_conditions, "Sample_Alias.Alias_Type = '$alias_type'" ) }
    if ($alias_value) { push( @extra_conditions, "Sample_Alias.Alias IN ($alias_value)" ) }
    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## Special inclusion / exclusion options ##
    #    if ($since) { push(@extra_conditions,"Plate_Created >= '$since'") }
    #    if ($until)  { push(@extra_conditions,"Plate_Created <= '$until'") }

    ## actually this is the same logic as get_read_data, but looking at slightly different info ...
    my @field_list = qw(library Source_Number Source_ID Original_Source_Name organism anatomic_site cell_line_name original_source_type strain sample_id sample_name library_source library_source_name);

    if ( $sample_type =~ /clone/ ) {
        push( @field_list, 'original_plate_id' );
    }
    elsif ( $sample_type =~ /extraction/ ) {
        push( @field_list, 'original_extraction_plate_id' );
        push( @field_list, 'original_extraction_well' );
    }

    ## add fields if grouping samples ##
    if ($group) { push( @field_list, 'Count(*) as count', 'first_plate_created', 'last_plate_created' ); }
    else        { push( @field_list, 'plate_created' ) }

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    push( @field_list, "Sample_Alias.Alias AS $alias_type" ) unless ( !$alias_type || ( grep /\b$alias_type\b/, @field_list ) );               ## add to fields if not already...
    push( @field_list, "Sample_Attribute.Attribute_Value AS $attribute" ) unless ( !$attribute || ( grep /\b$attribute\b/, @field_list ) );    ## add to fields if not already...

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,

        #        -attribute_link       => "Sample.sample_id",
        -date_field => "Plate.Plate_Created",
    );

}

# API To retrieve Source information
#
#
######################
sub get_source_data {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $source_id = $args{-source_id};
    ## Source specific
    my $original_source_id   = $args{-original_source_id};
    my $original_source_name = $args{-original_source_name};
    my $input_joins          = $args{-input_joins};
    my $input_left_joins     = $args{-input_left_joins};
    ## allow specification of library , project or study ##
    my $library        = $args{-library};
    my $study_id       = $args{-study_id};
    my $project_id     = $args{-project_id};
    my $ref_project_id = $args{-reference_project_id};    #project id associated to the sources
## Output options
    my $fields              = $args{-fields} || '';
    my $add_fields          = $args{-add_fields};
    my $order               = $args{-order} || '';
    my $group               = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY                 = $args{-key} || $group;
    my $limit               = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet               = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save                = $args{-save};
    my $list_fields         = $args{-list_fields};
    my $tables              = $args{-tables};
    my $external_identifier = $args{-external_identifier};
    my $sample_id           = $args{-sample_id};
    my $patient_identifier  = $args{-patient_identifier};
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

##########################################
    # Retrieve Record Data from the Database #
##########################################

    ## Generate Condition ##
    $tables = 'Source,Original_Source' if !$tables;

    my $join_condition = "WHERE Source.FK_Original_Source__ID = Original_Source_ID";

    my $libs;
    $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $patient_identifiers;
    $patient_identifiers = Cast_List( -list => $patient_identifier, -to => 'string', -autoquote => 1 ) if $patient_identifier;
    my $original_source_ids;
    $original_source_ids = Cast_List( -list => $original_source_id, -to => 'string', -autoquote => 1 ) if $original_source_id;
    my $original_source_names;
    $original_source_names = Cast_List( -list => $original_source_name, -to => 'string', -autoquote => 1 ) if $original_source_name;
    my $ref_projects;
    $ref_projects = Cast_List( -list => $ref_project_id, -to => 'string' ) if $ref_project_id;

    my $left_join_tables = '';    ## always included ... Clone_Sample' ;

    ## specify optional tables to include (with associated condition) - used in 'include_if_necessary' method ##
    my $join_conditions = {
        'Library as R_Parent_Library' => 'Source_Plate.FK_Library__Name = R_Parent_Library.Library_Name',
        'Plate as R_Source_Plate'     => 'Source.FKSource_Plate__ID = Source_Plate.Plate_ID',
        'Grp as R_Parent_Group'       => 'R_Parent_Library.FK_Grp__ID = R_Parent_Group.Grp_ID',

        # 'Organism'               => 'Original_Source.FK_Organism__ID = Organism.Organism_ID',
        'Taxonomy'                              => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
        'Nucleic_Acid'                          => 'Nucleic_Acid.FK_Source__ID=Source_ID',                                         ## only one of the following should be included in any query.  (DO NOT include any fields in these tables as default)
        'Ligation'                              => 'Ligation.FK_Source__ID=Source_ID',
        'Xformed_Cells'                         => 'Xformed_Cells.FK_Source__ID=Source_ID',
        'Microtiter'                            => 'Microtiter.FK_Source__ID=Source_ID',
        'ReArray_Plate'                         => 'ReArray_Plate.FK_Source__ID=Source_ID',
        'Contact as Original_Contact'           => 'Original_Source.FK_Contact__ID = Original_Contact.Contact_ID',
        'Organization as Original_Organization' => 'Original_Contact.FK_Organization__ID=Original_Organization.Organization_ID',
    };

    my $left_join_conditions = {
        'Library'                      => 'Library_Source.FK_Library__Name = Library.Library_Name',
        'Library_Source'               => 'Library_Source.FK_Source__ID = Source_ID',
        'Library as Parent_Library'    => 'Source_Plate.FK_Library__Name = Parent_Library.Library_Name',
        'Plate as Source_Plate'        => 'Source.FKSource_Plate__ID = Source_Plate.Plate_ID',
        'Grp as Parent_Group'          => 'Parent_Library.FK_Grp__ID = Parent_Group.Grp_ID',
        'Rack'                         => 'Source.FK_Rack__ID = Rack_ID',
        'Equipment'                    => 'Rack.FK_Equipment__ID=Equipment_ID',
        'Location'                     => 'Equipment.FK_Location__ID=Location_ID',
        'Cell_Line'                    => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
        'Pathology'                    => 'Pathology.Pathology_ID = Original_Source.FK_Pathology__ID',
        'Anatomic_Site'                => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
        'Shipment'                     => 'Source.FK_Shipment__ID = Shipment.Shipment_ID',
        'Histology'                    => 'Pathology.FK_Histology__ID = Histology.Histology_ID',
        'Xenograft'                    => 'Xenograft.FK_Source__ID = Source.Source_ID',
        'Transplant_Method'            => 'Transplant_Method.Transplant_Method_ID = Xenograft.FK_Transplant_Method__ID',
        'Patient as Host_Patient'      => 'Host_Patient.Patient_ID = Xenograft.FKHost_Patient__ID',
        'Organization as Shipment_Org' => 'Shipment.FKSupplier_Organization__ID = Shipment_Org.Organization_ID',
        'Sample'                       => 'Sample.FK_Source__ID = Source.Source_ID',
        'Sample_Type',                 => 'Sample_Type.Sample_Type_ID = Source.FK_Sample_Type__ID',
        'Strain'                       => 'Original_Source.FK_Strain__ID = Strain.Strain_ID',
        'Patient',                     => 'Original_Source.FK_Patient__ID = Patient.Patient_ID',
        'Source_Alert'                 => 'Source.Source_ID = Source_Alert.FK_Source__ID',
        'Alert_Reason'                 => 'Alert_Reason.Alert_Reason_ID = Source_Alert.FK_Alert_Reason__ID',
        'Source_Pool'                  => 'Source_Pool.FKChild_Source__ID = Source.Source_ID',                             # it's a child source
        'Storage_Medium'               => 'Storage_Medium_ID = Source.FK_Storage_Medium__ID'
    };

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    if ($source_id)           { push( @extra_conditions, "Source_ID IN ($source_id)" ); }
    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($external_identifier) {
        $external_identifier = Cast_List( -list => $external_identifier, -to => 'string', -autoquote => 1 ) if $external_identifier;
        push @extra_conditions, "Source.External_Identifier IN ($external_identifier)";
    }
    if ($patient_identifiers) {
        push @extra_conditions, "Patient.Patient_Identifier IN ($patient_identifiers)";
    }

    if ($original_source_ids)   { push @extra_conditions, "Original_Source_ID IN ($original_source_ids)" }
    if ($original_source_names) { push @extra_conditions, "Original_Source_Name IN ($original_source_names)" }

    if ($samples) { push( @extra_conditions, "Sample.Sample_ID IN ($samples)" ) }
    if ($ref_projects) {
        push @extra_conditions, "Source.FKReference_Project__ID IN ($ref_projects)";
    }
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw(Source_Number Source_ID Original_Source_Name organism anatomic_site cell_line_name original_source_type strain Source_Status sample_type);

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
    );

}

# API to retrieve plate information
#
#
########################
sub get_plate_data {
########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -mandatory => 'study_id|project_id|library|plate_id|plate_number|original_plate_id|applied_plate_id|sample_id|run_id|tray_id|rack|since|condition|limit' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id         = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id       = $args{-project_id};          ### specify project_id
    my $library          = $args{-library};             ### specify library
    ## plate specification options
    my $plate_id             = $args{-plate_id};                   ### specify plate_id
    my $plate_number         = $args{-plate_number};               ### specify plate number
    my $well                 = $args{-well};                       ### specify plate number
    my $plate_type           = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class          = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_status         = $args{-plate_status} || '';
    my $plate_application    = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $plate_format         = $args{-plate_format};               ### specify plate format (eg 'Glycerol') -only 1..
    my $original_plate_id    = $args{-original_plate_id};          ### specify original plate id
    my $original_well        = $args{-original_well};              ### specify original well
    my $applied_plate_id     = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant             = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id            = $args{-sample_id};                  ### specify sample_id
    my $run_id               = $args{-run_id};
    my $library_type         = $args{-library_type};
    my $tray_id              = $args{-tray_id};
    my $rack                 = $args{-rack};
    my $original_source_id   = $args{-original_source_id};
    my $original_source_name = $args{-original_source_name};
    my $source_id            = $args{-source_id};

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};      ### specify date to begin search (context dependent)
    my $until = $args{ -until };    ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Plate_Created';
            ## Output options
            my $fields     = $args{-fields}     || '';
            my $add_fields = $args{-add_fields} || '';
            my $order      = $args{-order}      || '';

            #my $group      = $args{-group}      || $args{-group_by} || $args{-key} || 'plate_id';
            my $group       = defined $args{-group} ? $args{-group} : defined $args{-group_by} ? $args{-group_by} : defined $args{-key} ? $args{-key} : 'plate_id';
            my $KEY         = $args{-key};
            my $limit       = $args{-limit} || '';                                                                                                                    ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                                                                                                          ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                                                                                                    ### just generate a list of output fields

            ### Re-Cast arguments if necessary ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $racks;
    $racks = extract_range( -list => $rack ) if $rack;
    my $wells;
    $wells = Cast_List( -list => $well, -to => 'string', -autoquote => 1 ) if $well;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;
    my $plate_classes;
    $plate_classes = Cast_List( -list => $plate_class, -to => 'string', -autoquote => 1 ) if $plate_class;
    my $quadrants;
    $quadrants = Cast_List( -list => $quadrant, -to => 'string', -autoquote => 1 ) if $quadrant;
    my $tray_ids;
    $tray_ids = Cast_List( -list => $tray_id, -to => 'string' ) if $tray_id;
    my $plate_statuses;
    $plate_statuses = Cast_List( -list => $plate_status, -to => 'string', -autoquote => 1 ) if $plate_status;
    my $run_ids;
    $run_ids = Cast_List( -list => $run_id, -to => 'string', -autoquote => 1 ) if $run_id;

    my $original_source_ids;
    $original_source_ids = Cast_List( -list => $original_source_id, -to => 'string', -autoquote => 1 ) if $original_source_id;
    my $original_source_names;
    $original_source_names = Cast_List( -list => $original_source_name, -to => 'string', -autoquote => 1 ) if $original_source_name;
    my $source_ids;
    $source_ids = Cast_List( -list => $source_id, -to => 'string', -autoquote => 1 ) if $source_id;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    my $tables         = 'Plate,Plate_Format,Library';                                                                         ## <- Supply list of Tables to retrieve data from ##
    my $join_condition = "WHERE Plate.FK_Plate_Format__ID=Plate_Format_ID AND Plate.FK_Library__Name=Library.Library_Name";    ## <- Supply join condition for Tables retrieved (if > 1) ##

    my @field_list
        = qw(library plate_id plate_number rack parent_quadrant parent_plate_id original_parent_plate_id project plate_size plate_format plate_created library organism library_started strain anatomic_site cell_line_name original_source_type plate_made_by plate_status sample_type);
    ## <- Default list of fields to retrieve

    my $left_join_tables;                                                                                                      ## <- Supply additional tables to left_join (includes condition)
    ## add Tables as necessary based with specified join conditions ##
    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,
    my $join_conditions = {
        'Library'            => "Plate.FK_Library__Name=Library.Library_Name",
        'Project'            => 'Library.FK_Project__ID=Project.Project_ID',
        'Primer'             => 'LibraryApplication.Object_ID=Primer.Primer_ID',
        'LibraryApplication' => 'LibraryApplication.FK_Library__Name=Library.Library_Name',

        #	'Vector_Based_Library'     => 'Vector_Based_Library.FK_Library__Name = Library.Library_Name',
        'Vector'             => 'LibraryVector.FK_Vector__ID = Vector.Vector_ID',
        'Original_Source'    => 'Library.FK_Original_Source__ID=Original_Source_ID',
        'Source'             => 'Sample.FK_Source__ID=Source_ID',                                                              ## link back through source (nned to group !)
        'Sample'             => 'Plate_Sample.FK_Sample__ID=Sample.Sample_ID',
        'Plate_Sample'       => 'Plate_Sample.FKOriginal_Plate__ID=Plate.Plate_ID',
        'Clone_Sample'       => 'Clone_Sample.FK_Sample__ID=Sample.Sample_ID',
        'Employee as Plater' => 'Plater.Employee_ID = Plate.FK_Employee__ID',
        'Rack'               => 'Plate.FK_Rack__ID = Rack.Rack_ID',
        'Vector_Type'        => 'Vector.FK_Vector_Type__ID = Vector_Type.Vector_Type_ID',

        # 'Organism'               => 'Original_Source.FK_Organism__ID = Organism.Organism_ID',
        'Taxonomy'   => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
        'Fail'       => 'Fail.Object_ID = Plate.Plate_ID',
        'FailReason' => 'FailReason.FailReason_ID = Fail.FK_FailReason__ID',
        'Pipeline'   => 'Plate.FK_Pipeline__ID=Pipeline.Pipeline_ID',
        'Equipment'  => 'Rack.FK_Equipment__ID = Equipment.Equipment_ID',
        'Location'   => 'Location.Location_ID=Equipment.FK_Location__ID',

        # Original contact information #
        'Contact as Original_Contact'           => 'Original_Source.FK_Contact__ID = Original_Contact.Contact_ID',
        'Organization as Original_Organization' => 'Original_Contact.FK_Organization__ID=Original_Organization.Organization_ID',
    };
    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        'Run'                                  => 'Run.FK_Plate__ID=Plate_ID',
        'SequenceRun'                          => 'SequenceRun.FK_Run __ID=Run.Run_ID',
        'SequenceAnalysis'                     => 'SequenceAnalysis.FK_SequenceRun__ID=SequenceRun.SequenceRun_ID',
        'Stage'                                => 'Original_Source.FK_Stage__ID = Stage.Stage_ID',
        'Branch'                               => 'Branch.Branch_Code = Plate.FK_Branch__Code',
        'Sample_Type'                          => 'Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID',
        'Vector_Based_Library'                 => 'Vector_Based_Library.FK_Library__Name = Library.Library_Name',
        'Work_Request as Library_Work_Request' => 'Library.Library_Name = Library_Work_Request.FK_Library__Name',
        'Goal as Library_Goal'                 => 'Library_Work_Request.FK_Goal__ID = Library_Goal.Goal_ID',
        'Funding as Library_Funding'           => 'Library_Work_Request.FK_Funding__ID = Library_Funding.Funding_ID',
        'Work_Request as Plate_Work_Request'   => 'Plate.FK_Work_Request__ID = Plate_Work_Request.Work_Request_ID',
        'Goal as Plate_Goal'                   => 'Plate_Work_Request.FK_Goal__ID = Plate_Goal.Goal_ID',
        'Funding as Plate_Funding'             => 'Plate_Work_Request.FK_Funding__ID = Plate_Funding.Funding_ID',
        'Anatomic_Site'                        => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
        'Cell_Line'                            => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
        'Plate_Tray'                           => 'Plate_Tray.FK_Plate__ID = Plate.Plate_ID',
        'Strain'                               => 'Original_Source.FK_Strain__ID = Strain.Strain_ID',
    };

    if ( $plate_type =~ /(library|96|384)/i ) {
        $join_conditions->{'Library_Plate'} = "Library_Plate.FK_Plate__ID=Plate_ID";
        push( @field_list, 'plate_position' );
    }
    elsif ( $plate_type =~ /(tube|1)/i ) {
        $join_conditions->{'Tube'} = "Tube.FK_Plate__ID=Plate_ID";
    }
    else {
        ## no type supplied - left join ALL plate types - MUCH MORE EFFICIENT to include the plate_type - perhaps it should be mandatory (?)
        $left_join_conditions->{'Library_Plate'} = "Library_Plate.FK_Plate__ID=Plate_ID";
        $left_join_conditions->{'Tube'}          = "Tube.FK_Plate__ID=Plate_ID";
        $left_join_conditions->{'Array'}         = "Array.FK_Plate__ID=Plate_ID";
    }

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($plates)              { push( @extra_conditions, "Plate.Plate_ID IN ($plates)" ) }
    if ($plate_classes)       { push( @extra_conditions, "Plate.Plate_Class IN ($plate_classes)" ) }
    if ($plate_format)        { push( @extra_conditions, "Plate_Format.Plate_Format_Type LIKE '%$plate_format%'" ) }    ## flexible
    if ($plate_numbers)       { push( @extra_conditions, "Plate.Plate_Number IN ($plate_numbers)" ) }
    if ($racks)               { push( @extra_conditions, "Plate.FK_Rack__ID IN ($racks)" ) }
    if ($library_types)       { push( @extra_conditions, "Library.Library_Type IN ($library_types)" ) }
    if ($wells)               { push( @extra_conditions, "Plate_Sample.Well IN ($wells)" ) }                            ## <CONSTRUCTION> -should be more flexible (ie well for donwstream plate)
    if ($samples)             { push( @extra_conditions, "Sample.Sample_ID IN ($samples)" ) }
    if ($quadrants)           { push( @extra_conditions, "Plate.Parent_Quadrant IN ($quadrants)" ) }
    if ($tray_ids)            { push( @extra_conditions, "Plate_Tray.FK_Tray__ID IN ($tray_ids)" ) }
    if ($plate_statuses) { push @extra_conditions, "Plate.Plate_Status IN ($plate_statuses)" }
    if ($run_ids)        { push @extra_conditions, "Run.Run_ID IN ($run_ids)" }

    if ($original_source_ids)   { push @extra_conditions, "Original_Source.Original_Source_ID IN ($original_source_ids)" }
    if ($source_ids)            { push @extra_conditions, "Source.Source_ID IN ($source_ids)" }
    if ($original_source_names) { push @extra_conditions, "Original_Source.Original_Source_Name IN ($original_source_names)" }

    my $conditions;
    $conditions = join ' AND ', @extra_conditions if @extra_conditions;
    $conditions ||= '1';
    ## Special inclusion / exclusion options ##

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,

        #        -attribute_link       => ["Plate.plate_id","Library.library"],
        -date_field => "Plate.Plate_Created",
    );
}

######################################################
#
# Wrapper for get_plate_data specific to rearrays
#
#
#
##########################
sub get_rearray_data {
##########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args                = filter_input( \@_ );
    my $source_plate_id     = $args{-source_plate_id};
    my $source_library      = $args{-source_library};
    my $source_plate_number = $args{-source_plate_number};
    my $target_plate_id     = $args{-target_plate_id};
    my $target_library      = $args{-target_library};
    my $target_plate_number = $args{-target_plate_number};
    my $source_well         = $args{-source_well};
    my $target_well         = $args{-target_well};
    my $rearray_request_id  = $args{-rearray_request_id};
    my $rearray_status      = $args{-rearray_status};
    my $solution_id         = $args{-solution_id};
    my $primer_plate_name   = $args{-primer_plate_name};
    my $sample_id           = $args{-sample_id};
    my $sample_name         = $args{-sample_name};
    my $rearray_type        = $args{-rearray_type};
    my $primer_name         = $args{-primer_name};
    my $condition           = $args{-condition};

    my @add_fields;
    @add_fields = Cast_List( -list => $args{-add_fields}, -to => 'array' ) if $args{-add_fields};

    # build argument list and queries for get_plate_data
    if ($target_plate_id) {
        $args{-plate_id} = $target_plate_id;
    }
    if ($target_library) {
        $args{-library} = $target_library;
    }
    if ($target_plate_number) {
        $args{-plate_number} = $target_plate_number;
    }

    my @conditions;
    if ($condition) {
        push @conditions, $condition;
    }
    if ($rearray_request_id) {
        push @conditions, "ReArray_Request.ReArray_Request_ID = $rearray_request_id ";
    }
    if ($rearray_status) {
        push @conditions, "Status.Status_Name = '$rearray_status' ";
    }
    if ($source_plate_id) {
        push @conditions, "ReArray.FKSource_Plate__ID = $source_plate_id ";
    }
    if ($source_library) {
        push @conditions, "Source_Plate.FK_Library__Name = '$source_library' ";
    }
    if ($source_plate_number) {
        push @conditions, "Source_Plate.Plate_Number in ($source_plate_number) ";
    }
    if ($source_well) {
        push @conditions, "ReArray.Source_Well in (" . &autoquote_string($source_well) . ") ";
    }
    if ($target_well) {
        push @conditions, "ReArray.Target_Well in (" . &autoquote_string($target_well) . ") ";
    }
    if ($rearray_type) {
        push @conditions, "ReArray_Request.ReArray_Type = '$rearray_type' ";
    }
    if ($primer_name) {
        push @conditions, "Primer.Primer_Name LIKE '$primer_name' ";
    }
    if ($solution_id) {
        push @conditions, "Primer_Plate.FK_Solution__ID = $solution_id ";
    }
    if ($primer_plate_name) {
        push @conditions, "Primer_Plate.Primer_Plate_Name = '$primer_plate_name' ";
    }
    if ($sample_id) {
        my @samples = split( ',', $sample_id );
        push @conditions, "Sample.Sample_ID in (@samples)";
    }
    if ($sample_name) {
        push @conditions, "Sample.Sample_Name in (" . &autoquote_string($sample_name) . ") ";
    }

    my $input_joins = {
        'ReArray_Request'       => 'ReArray_Request.FKTarget_Plate__ID=Plate.Plate_ID',
        'Plate as Source_Plate' => 'ReArray.FKSource_Plate__ID=Source_Plate.Plate_ID',
        'ReArray'               => 'ReArray.FK_ReArray_Request__ID=ReArray_Request.ReArray_Request_ID',
        'Sample'                => 'ReArray.FK_Sample__ID=Sample.Sample_ID',
        'Plate_Sample'          => 'Plate_Sample.FKOriginal_Plate__ID=Plate.Plate_ID AND Plate_Sample.Well=ReArray.Target_Well',
        'Plate_PrimerPlateWell' => 'Plate_PrimerPlateWell.FK_Plate__ID=ReArray_Request.FKTarget_Plate__ID AND ReArray.Target_Well=Plate_PrimerPlateWell.Plate_Well',
        'Primer_Plate_Well'     => 'Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID',
        'Primer_Plate'          => 'Primer_Plate.Primer_Plate_ID=Primer_Plate_Well.FK_Primer_Plate__ID',
        'Primer'                => 'Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name',
        'Status'                => 'ReArray_Request.FK_Status__ID=Status.Status_ID'
    };

    push( @add_fields, 'rearray_request_id', 'rearray_date', 'target_well' );
    if (@conditions) { $args{-condition} = join ' AND ', @conditions }

    $args{-input_joins} = $input_joins;
    $args{-add_fields}  = \@add_fields;

    #    $args{-plate_type} = 'library';  ## <CONSTRUCTION> - is this always the case ?
    my $group = defined $args{-group} ? $args{-group} : defined $args{-group_by} ? $args{-group_by} : defined $args{-key} ? $args{-key} : '';
    return $self->get_plate_data( %args, -group => $group );
}

####################
#
# New method to simplify run data extraction (avoids complexity of _generate_query method)
# (this style should replace all of the other API methods as well to simplify maintenance / debugging.
#
# Return: hash of data
#####################
sub get_run_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -mandatory => "study_id|project_id|library|run_id|run_name|plate_id|sample_id|pipeline|since|limit|include" );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $study_id   = $args{-study_id};      ### a study id (a defined set of libraries/projects)
    my $project_id = $args{-project_id};    ### specify project_id
    my $library    = $args{-library};       ### specify library
    ## run specification options
    my $run_id         = $args{-run_id};            ### specify run id
    my $run_name       = $args{-run_name};          ### specify run name (must be exact format)
    my $exclude_run_id = $args{-exclude_run_id};    ### specify run id to EXCLUDE (for Run or Read scope)
    my $equipment      = $args{-equipment};
    ## plate specification options
    my $plate_id                = $args{-plate_id};                   ### specify plate_id
    my $plate_number            = $args{-plate_number};               ### specify plate number
    my $plate_type              = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class             = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application       = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id       = $args{-original_plate_id};          ### specify original plate id
    my $original_well           = $args{-original_well};              ### specify original well
    my $applied_plate_id        = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant                = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id               = $args{-sample_id};                  ### specify sample_id
    my $pipeline                = $args{-pipeline};
    my $branch                  = $args{-branch};
    my $run_validation          = $args{-run_validation};
    my $run_qc_status           = $args{-run_qc_status};
    my $run_status              = $args{-run_status};
    my $multiplex_adapter_index = $args{-multiplex_adapter_index};

    ## advanced options
    my $tables           = $args{-tables};
    my $input_conditions = $args{-condition};
    my $library_type     = $args{-library_type};
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};
    ## Inclusion / Exclusion options
    my $since = $args{-since};      ### specify date to begin search (context dependent)
    my $until = $args{ -until };    ### specify date to stop search (context dependent)

            my $date_field = $args{-date_field} || 'Run_DateTime';

            my $include = $args{-include} || 0;    ### data to include (production,approved,billable,pending,analyzed) - 'AND' joined.
            my $exclude = $args{-exclude} || 0;    ### OR specify data to exclude (eg. failed)

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key} || 'run_id';
            my $KEY         = $args{-key};                                                    # || $group;
            my $limit       = $args{-limit} || '';                                            ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                                  ### suppress feedback by setting quiet option
            my $save        = $args{-save};                                                   ### save query results in hash for easy retrieval
            my $list_fields = $args{-list_fields};                                            ### just generate a list of output fields
            my $debug       = $args{-debug};
            my $key_hash    = $args{-key_hash};
            ### Re-Cast arguments if necessary ###
            #    my $study_ids ; $study_ids = Cast_List(-list=>$study_id,-to=>'string') if $study_id;
            #    my $project_ids ; $project_ids = Cast_List(-list=>$project_id,-to=>'string') if $project_id;

            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );

    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;

    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $runs;
    $runs = Cast_List( -list => $run_id, -to => 'string' ) if $run_id;
    my $run_names;
    $run_names = Cast_List( -list => $run_name, -to => 'string', -autoquote => 1 ) if $run_name;
    my $equipments;
    $equipments = Cast_List( -list => $equipment, -to => 'string', -autoquote => 1 );
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;
    my $pipelines;
    $pipelines = Cast_List( -list => $pipeline, -to => 'string', -autoquote => 1 ) if $pipeline;
    my $branches;
    $branches = Cast_List( -list => $branch, -to => 'string', -autoquote => 1 ) if $branch;
    my $quadrants;
    $quadrants = Cast_List( -list => $quadrant, -to => 'string', -autoquote => 1 ) if $branch;
    my $run_validations;
    $run_validations = Cast_List( -list => $run_validation, -to => 'string', -autoquote => 1 ) if $run_validation;
    my $run_qc_statuses;
    $run_qc_statuses = Cast_List( -list => $run_qc_status, -to => 'string', -autoquote => 1 ) if $run_qc_status;
    my $run_statuses;
    $run_statuses = Cast_List( -list => $run_status, -to => 'string', -autoquote => 1 ) if $run_status;
    my $multiplex_adapter_indices;
    $multiplex_adapter_indices = Cast_List( -list => $multiplex_adapter_index, -to => 'string', -autoquote => 1 ) if $multiplex_adapter_index;
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;
##########################################
    # Retrieve Record Data from the Database #
##########################################

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    if ( !$tables ) {
        ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
        $tables = 'Run,RunBatch,Plate,Library';
        $join_condition .= " AND Run.FK_Plate__ID = Plate.Plate_ID";
        $join_condition .= " AND Plate.FK_Library__Name = Library.Library_Name";
        $join_condition .= " AND Run.FK_RunBatch__ID = RunBatch.RunBatch_ID";
    }

    my $left_join_tables = '';

    my $join_conditions = {
        'RunBatch'           => "Run.FK_RunBatch__ID = RunBatch.RunBatch_ID",
        'Equipment'          => "RunBatch.FK_Equipment__ID = Equipment.Equipment_ID",
        'Equipment_Category' => 'Stock_Catalog.FK_Equipment_Category__ID=Equipment_Category.Equipment_Category_ID',
        'Stock'              => 'Equipment.FK_Stock__ID=Stock.Stock_ID',
        'Stock_Catalog'      => 'Stock.FK_Stock_Catalog__ID=Stock_Catalog.Stock_Catalog_ID',

        #	'Vector_Based_Library' => "Vector_Based_Library.FK_Library__Name=Library.Library_Name",
        'Library_Plate'    => "Library_Plate.FK_Plate__ID=Plate.Plate_ID",
        'Branch'           => "Plate.FK_Branch__Code = Branch.Branch_Code",
        'Branch_Condition' => "Branch.Branch_Code = Branch_Condition.FK_Branch__Code",
        'Object_Class'     => "Object_Class.Object_Class_ID = Branch_Condition.FK_Object_Class__ID",

        #'Primer'             => "Chemistry_Code.FK_Primer__Name=Primer.Primer_Name",
        'Clone_Sequence'   => "Clone_Sequence.FK_Run__ID=Run.Run_ID",
        'SequenceAnalysis' => "SequenceAnalysis.FK_SequenceRun__ID=SequenceRun.SequenceRun_ID",
        'Project'          => "Library.FK_Project__ID=Project.Project_ID",
        'Original_Source'  => "Library.FK_Original_Source__ID=Original_Source_ID",

        # 'Organism'           => "Original_Source.FK_Organism__ID=Organism_ID",
        'Taxonomy'                 => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
        'Employee as Sequenced_by' => "RunBatch.FK_Employee__ID = Sequenced_by.Employee_ID",
        ## the following should be standard joins even though they may not be required (faster)...
   #	'Primer' => "Primer.Primer_Name=Chemistry_Code.FK_Primer__Name",  ## ALSO should link via LibraryPrimer tables, but problem if logic moved here.. (?) - Custom Primer details should be handled below (add custom_primer, custom_primer_sequence if req'd)
        'Primer' => "Primer.Primer_ID = Branch_Condition.Object_ID AND Object_Class.Object_Class='Primer'"
        ,    ## ALSO should link via LibraryPrimer tables, but problem if logic moved here.. (?) - Custom Primer details should be handled below (add custom_primer, custom_primer_sequence if req'd)

        #	'Primer as Custom_Primer' => "Custom_Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name",
        'Primer as Custom_Primer' => "Custom_Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name",
        'Primer_Plate_Well'       => "Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID AND Clone_Sequence.Well = Plate_PrimerPlateWell.Plate_Well",
        'Plate_PrimerPlateWell'   => "Plate_PrimerPlateWell.FK_Plate__ID=Plate.FKOriginal_Plate__ID",
        'SequenceRun'             => 'SequenceRun.FK_Run__ID=Run_ID',
        'Pipeline'                => 'Pipeline.Pipeline_ID = Plate.FK_Pipeline__ID',
        'Plate_Format'            => 'Plate_Format_ID=Plate.FK_Plate_Format__ID',
    };

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {

        #	'Primer as Custom_Primer' => "Custom_Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name",
        'LibraryApplication' => "Library.Library_Name=LibraryApplication.FK_Library__Name AND Primer.Primer_ID=LibraryApplication.Object_ID",

        #	'Primer_Plate_Well' => "Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID",
        #	'Plate_PrimerPlateWell' => "Plate_PrimerPlateWell.FK_Plate__ID=Plate.FKOriginal_Plate__ID",
        'Branch'               => 'Plate.FK_Branch__Code = Branch.Branch_Code',
        'Vector_Based_Library' => "Vector_Based_Library.FK_Library__Name=Library.Library_Name",
        'Anatomic_Site'        => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
        'Cell_Line'            => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
        'Pathology'            => 'Pathology.Pathology_ID = Original_Source.FK_Pathology__ID',
        'Genome'               => 'FK_Genome__ID=Genome_ID',

        #	'Histology'          => 'Pathology.FK_Histology__ID = Histology.Histology_ID',
        'Run_Analysis'                        => 'Run_Analysis.FK_Run__ID=Run.Run_ID',
        'Run_QC_Alert'                        => 'Run_QC_Alert.FK_Run__ID = Run.Run_ID',
        'Multiplex_Run_Analysis'              => 'Multiplex_Run_Analysis.FK_Run_Analysis__ID=Run_Analysis.Run_Analysis_ID',
        'Multiplex_Run'                       => 'Multiplex_Run.FK_Run__ID = Run.Run_ID',
        'Multiplex_Run_QC_Alert'              => 'Multiplex_Run_QC_Alert.FK_Multiplex_Run__ID = Multiplex_Run_ID',
        'Alert_Reason as Multiplex_Run_Alert' => 'Multiplex_Run_Alert.Alert_Reason_ID = Multiplex_Run_QC_Alert.FK_Alert_Reason__ID',
        'Alert_Reason as Run_Alert'           => 'Run_Alert.Alert_Reason_ID = Run_QC_Alert.FK_Alert_Reason__ID',
        'Sample'                              => 'Multiplex_Run_Analysis.FK_Sample__ID=Sample.Sample_ID',
        'Source'                              => 'Source.Source_ID=Sample.FK_Source__ID',
        'Work_Request as Plate_Work_Request'  => 'Plate_Work_Request.Work_Request_ID = Plate.FK_Work_Request__ID',
        'Funding as Plate_Funding'            => 'Plate_Work_Request.FK_Funding__ID = Plate_Funding.Funding_ID',
        'LibraryVector'                       => 'LibraryVector.FK_Library__Name = Library.Library_Name',
        'Vector'                              => 'LibraryVector.FK_Vector__ID = Vector.Vector_ID',
        'Vector_Type'                         => 'Vector.FK_Vector_Type__ID = Vector_Type.Vector_Type_ID',
    };

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($plates)              { push( @extra_conditions, "Plate.Plate_ID IN ($plates)" ) }
    if ($plate_numbers)       { push( @extra_conditions, "Plate.Plate_Number IN ($plate_numbers)" ) }
    if ($runs)                { push( @extra_conditions, "Run.Run_ID IN ($runs)" ) }
    if ($equipments)          { push( @extra_conditions, "Equipment.Equipment_ID IN ($equipments)" ) }
    if ($samples)             { push( @extra_conditions, "Clone_Sequence.FK_Sample__ID IN ($samples)" ) }
    if ($library_types)       { push( @extra_conditions, "(Vector_Based_Library.Vector_Based_Library_Type IN ($library_types) OR Library_Type IN ($library_types))" ) }
    if ($exclude_run_id)      { push( @extra_conditions, "Run.Run_ID NOT IN ($exclude_run_id)" ) }
    if ($branches)                  { push @extra_conditions, "Plate.FK_Branch__Code IN ($branches)" }
    if ($pipelines)                 { push @extra_conditions, "Plate.FK_Pipeline__ID IN ($pipelines)" }
    if ($quadrants)                 { push @extra_conditions, "Plate.Parent_Quadrant IN ($quadrants)" }
    if ($run_validations)           { push @extra_conditions, "Run.Run_Validation IN ($run_validations)" }
    if ($run_qc_statuses)           { push @extra_conditions, "Run.QC_Status IN ($run_qc_statuses)" }
    if ($run_statuses)              { push @extra_conditions, "Run.Run_Status IN ($run_statuses)" }
    if ($multiplex_adapter_indices) { push @extra_conditions, "Multiplex_Run.Adapter_Index IN ($multiplex_adapter_indices)" }
    ## Include runs (ie Approved / Production / Billable ##
    my $run_test_status_condition = include_condition( -field => 'Run_Test_Status', -available_values => "Production|Test", -include => $include );
    if ($run_test_status_condition) { push @extra_conditions, $run_test_status_condition }
    if ( $include =~ /\bApproved\b/i ) { push( @extra_conditions, "Run_Validation = 'Approved'" ) }

    #if ( $include =~ /\bProduction\b/i ) { push( @extra_conditions, "Run_Test_Status = 'Production'" ) }
    #if ( $include =~ /\bTest\b/i )       { push( @extra_conditions, "Run_Test_Status = 'Test'" ) }
    if ( $include =~ /\bBillable\b/i ) { push( @extra_conditions, "Billable = 'Yes'" ) }
    if ( $include =~ /\bPending\b/i )  { push @extra_conditions, "Run_Status IN ('Initiated','Data Acquired','In Process')" }
    if ( $include =~ /\bAnalyzed\b/i ) { push @extra_conditions, "Run_Status = 'Analyzed'" }

    ## <CONSTRUCTION> - is this to be a standard or custom specification ?
    if    ( $include =~ /\bExternal\b/i ) { push @extra_conditions, "Plate.FK_Branch__Code LIKE 'EXT'" }
    elsif ( $include =~ /\bInternal\b/i ) { push @extra_conditions, "Plate.FK_Branch__Code NOT LIKE 'EXT'" }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;
    ## Special inclusion / exclusion options ##

    ## <CONSTRUCTION>  Separate out Sequence Run fields and put in Sequencing_API with different default fields
    ## actually this is the same logic as get_read_data, but looking at slightly different info ...
    my @field_list = ( 'library', 'data_path', 'plate_number', 'Average_Q20', 'Average_Length', 'Total_Length' );
    if ($key_hash) { $KEY = ''; $group = ''; }
    elsif ( ( $group || $KEY ) && ( $group !~ /^(run_name|run_id)$/ ) && ( $KEY !~ /^(run_name|run_id)$/ ) ) {    ## only valid if grouped
        push( @field_list, "Count(Run.Run_ID) as runs", 'earliest_run', 'latest_run', 'first_plate_created', 'last_plate_created' );
    }
    elsif ( !$group ) {                                                                                           ## only valid if NOT grouped
        $group .= "run_name";                                                                                     ## group by run_name to allow Average values to be calculated ##
        push( @field_list,
            'Plate_ID', 'sequencer', 'vector', 'primer', 'run_time', 'run_id', 'run_name', 'Run_Directory', 'unused_wells', 'direction', 'plate_created', 'plate_class', 'library_format', 'parent_quadrant', 'plate_position', 'run_status', 'validation' );

        #
        push( @field_list, "Count(Run.Run_ID) as runs", 'earliest_run', 'latest_run', 'first_plate_created', 'last_plate_created' );
    }
    else {
        $group .= ",run_name";
        push( @field_list,
            'Plate_ID', 'sequencer', 'vector', 'primer', 'run_time', 'run_id', 'run_name', 'Run_Directory', 'unused_wells', 'direction', 'plate_created', 'plate_class', 'library_format', 'parent_quadrant', 'plate_position', 'run_status', 'validation' );
        push( @field_list, "Count(Run.Run_ID) as runs", 'earliest_run', 'latest_run', 'first_plate_created', 'last_plate_created' );
    }

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    ### get_run_data();
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
        -date_field           => "Run.Run_DateTime",
        -debug                => $debug
    );

}

# get alert reasons in the system, can input reason or alert_type as a filter
#
#
###########################
sub get_alert_reason_data {
###########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval

    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    ## plate specification options

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $alert_type   = $args{-alert_type};              ## one or more alert types arrayref, example 'QC Notification'
    my $alert_reason = $args{-alert_reason};            ## scalar one alert reason, will do pattern match, example 'QC_1'
    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key} || $group;
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

    ### Re-Cast arguments as required ###
    my $alert_types;
    $alert_types = Cast_List( -list => $alert_type, -to => 'string', -autoquote => 1 ) if $alert_type;
    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

    ## Initial Framework for query ##
    my $tables           = 'Alert_Reason';                                ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE 1';                                     ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                            ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {};

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {};                                        ##    eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    if ($alert_reason) { push( @extra_conditions, "Alert_Reason LIKE '%$alert_reason%'" ) }
    if ($alert_types)  { push( @extra_conditions, "Alert_Reason.Alert_Type IN ($alert_types)" ) }

    # Ignore inactive pipelines

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw(Alert_Reason Alert_Type Alert_Reason_Notes);    ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet
    );

}

# Add an alert reason to an object (supported objects are Run_QC_Alert and Multiplex_QC_Alert for now)
#
#
######################
sub add_alert_reason {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args            = &filter_input( \@_, -mandatory => 'object,key_id,alert_reason_id' );
    my $object          = $args{-object};                                                        ## object to add ie Run_QC_Alert or Multiplex_QC_Alert
    my $key_id          = $args{-key_id};                                                        ## array ref of key_id(s) for the object, ie Run_ID or Multiplex_Run_ID
    my $alert_reason_id = $args{-alert_reason_id};                                               # array ref  alert reason id for respective key_id(s)
    my $alert_type      = $args{-alert_type};                                                    # alert type. It's used for validating alert reason id
    my $comments        = $args{-comments};                                                      ## additional comments

    my @supported_tables = ( 'Run_QC_Alert', 'Multiplex_Run_QC_Alert' );
    ## check to make sure that the object is supported
    unless ( grep /^$object$/, @supported_tables ) {
        return 0;
    }

    my $added;
    my $dbc             = $self;
    my @key_id          = Cast_List( -list => $key_id, -to => 'Array' );
    my @alert_reason_id = Cast_List( -list => $alert_reason_id, -to => 'Array' );
    my @comments_arr    = Cast_List( -list => $comments, -to => 'Array' );
    my %alert_reason_values;
    my $si = 1;
    my %fk_field;
    $fk_field{'Run_QC_Alert'}{field}           = 'FK_Run__ID';
    $fk_field{'Run_QC_Alert'}{table}           = 'Run';
    $fk_field{'Multiplex_Run_QC_Alert'}{field} = 'FK_Multiplex_Run__ID';
    $fk_field{'Multiplex_Run_QC_Alert'}{table} = 'Multiplex_Run';

    ## validate key_id
    my $valid_key_ids_list = $dbc->valid_ids( -ids => $key_id, -table => $fk_field{$object}{table} );
    my @valid_key_ids = split ',', $valid_key_ids_list;
    if ( int(@valid_key_ids) < int(@key_id) ) { return 0 }

    ## validate alert_reason_id
    my $valid_alert_reason_list = $dbc->valid_ids( -ids => $alert_reason_id, -table => 'Alert_Reason' );
    my @valid_alert_reason_ids = split ',', $valid_alert_reason_list;
    if ( int(@valid_alert_reason_ids) < int(@alert_reason_id) ) { return 0 }

    # validate against Alert_Type
    if ($alert_type) {
        my $alert_reason_id_list = join ',', @alert_reason_id;
        my @invalid = $dbc->Table_find( 'Alert_Reason', 'Alert_Reason_ID', "Where Alert_Reason_ID in ($alert_reason_id_list) AND Alert_Type <> '$alert_type'" );
        if ( int(@invalid) ) { return 0 }
    }

    my @fields  = ( $fk_field{$object}{field}, 'Alert_Type', 'FK_Alert_Reason__ID', 'FK_Employee__ID', 'Alert_Notification_Date', 'Alert_Comments' );
    my $i       = 0;
    my $user_id = $self->get_local('user_id');
    ## build the hash for adding the values
    foreach my $key (@key_id) {
        my ($alert_type) = $dbc->Table_find( 'Alert_Reason', 'Alert_Type', "WHERE Alert_Reason_ID = $alert_reason_id[$i]" );
        my @values = ( $key, $alert_type, $alert_reason_id[$i], $user_id, &date_time(), $comments_arr[$i] );
        $alert_reason_values{$si} = \@values;
        $i++;
        $si++;
    }
    $added = $dbc->smart_append( -tables => "$object", -fields => \@fields, -values => \%alert_reason_values, -autoquote => 1 );
    return $added;
}

sub include_condition {
    my %args             = &filter_input( \@_ );
    my $field            = $args{-field};
    my $available_values = $args{-available_values};
    my $include          = $args{-include};

    if ( my @test_options = grep /($available_values)/i, Cast_List( -list => $include, -to => 'array' ) ) {
        my $list = Cast_List( -list => \@test_options, -to => 'string', -autoquote => 1 );
        return "$field IN ($list)";
    }

    return '';
}

####################
#
# New method to get run analysis data extraction
#
# Return: hash of data
#####################
sub get_run_analysis_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -mandatory => "run_id|since" );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options
    my $run_id = $args{-run_id};    ### specify run id
    my $tables = $args{-tables};
    ## Output options
    my $fields                  = $args{-fields} || '';
    my $add_fields              = $args{-add_fields};
    my $order                   = $args{-order} || '';
    my $group                   = $args{-group} || $args{-group_by} || $args{-key} || '';
    my $KEY                     = $args{-key};
    my $limit                   = $args{-limit} || '';                                      ### limit number of unique samples to retrieve data for
    my $quiet                   = $args{-quiet};                                            ### suppress feedback by setting quiet option
    my $save                    = $args{-save};                                             ### save query results in hash for easy retrieval
    my $list_fields             = $args{-list_fields};                                      ### just generate a list of output fields
    my $debug                   = $args{-debug};
    my $analysis_software       = $args{-analysis_software};
    my $current_analysis        = $args{-current_analysis};
    my $multiplex_adapter_index = $args{-multiplex_adapter_index};
    my $input_conditions        = $args{-condition};
    my $since                   = $args{-since};                                            ### specify date to begin search (context dependent)
    my $until                   = $args{ -until };                                          ### specify date to stop search (context dependent)
            my $run_analysis_type = $args{-run_analysis_type} || "Secondary";
            my $input_left_joins  = $args{-input_left_joins};
            my $simple            = $args{-simple};

            ## Generate Condition ##
            my $join_condition = 'WHERE 1';
            if ($current_analysis) { $join_condition .= ' AND Current_Analysis = "Yes"'; }

    my $run_analysis_types;
    $run_analysis_types = Cast_List( -list => $run_analysis_type, -to => 'string', -autoquote => 1 ) if $run_analysis_type;
    if ($run_analysis_types) { $join_condition .= " AND Run_Analysis_Type IN ($run_analysis_types)"; }

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    if ( !$tables ) {
        if ($simple) {
            $tables = 'Run,Run_Analysis';
            $join_condition .= " AND Run_Analysis.FK_Run__ID = Run.Run_ID";
        }
        else {
            $tables = 'Run,Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software';
            $join_condition .= " AND Run_Analysis.FK_Run__ID = Run.Run_ID";
            $join_condition .= " AND Analysis_Step.FK_Run_Analysis__ID = Run_Analysis.Run_Analysis_ID";
            $join_condition .= " AND Analysis_Step.FK_Pipeline_Step__ID = Pipeline_Step.Pipeline_Step_ID";
            $join_condition .= " AND Pipeline_Step.Object_ID = Analysis_Software.Analysis_Software_ID";
        }
    }

    my @field_list = ( 'run_id', 'run_analysis_id', 'analysis_step_id', 'analysis_software_name' );

    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;
    my $runs = Cast_List( -list => $run_id, -to => 'string' );
    if ($runs) { push( @extra_conditions, "Run.Run_ID IN ($runs)" ) }
    if ($multiplex_adapter_index) {

        push @extra_conditions, " Adapter_Index = '$multiplex_adapter_index'";
    }
    if ($analysis_software) { push @extra_conditions, "Analysis_Software_Name like '%$analysis_software%'" }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    my $left_join_conditions = {
        'SOLID_Run_Analysis'            => "SOLID_Run_Analysis.FK_Run_Analysis__ID = Run_Analysis_ID",
        'Solexa_Run_Analysis'           => "Solexa_Run_Analysis.FK_Run_Analysis__ID = Run_Analysis_ID",
        'Solexa_Read'                   => "Run_ID = Solexa_Read.FK_Run__ID",
        'Multiplex_Run_Analysis'        => "Run_Analysis_ID = Multiplex_Run_Analysis.FK_Run_Analysis__ID",
        'Multiplex_Solexa_Run_Analysis' => "Multiplex_Solexa_Run_Analysis.FK_Multiplex_Run_Analysis__ID = Multiplex_Run_Analysis.Multiplex_Run_Analysis_ID",
        'Multiplex_SOLID_Run_Analysis'  => "Multiplex_SOLID_Run_Analysis.FK_Multiplex_Run_Analysis__ID = Multiplex_Run_Analysis.Multiplex_Run_Analysis_ID",
        'Run_Analysis'                  => '',                                                                                                                 #for left join sort
        'Sample'                        => 'Multiplex_Run_Analysis.FK_Sample__ID=Sample_ID',
        'Source'                        => 'Source.Source_ID=Sample.FK_Source__ID',
        'Multiplex_Run'                 => 'Multiplex_Run.FK_Run__ID = Run.Run_ID AND Multiplex_Run.Adapter_Index = Multiplex_Run_Analysis.Adapter_Index',
    };
    $left_join_conditions = RGmath::merge_Hash( -hash1 => $left_join_conditions, -hash2 => $input_left_joins );
    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,

        #-left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,

        #-join_conditions      => $join_conditions,
        -limit      => $limit,
        -quiet      => $quiet,
        -debug      => $debug,
        -date_field => "Run_Analysis.Run_Analysis_Started",
    );

}

####################
#
# New method to get a list of genomes
#
# Return: hash of data
#####################
sub get_genome_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options
    my $genome_id = $args{-genome_id};    ### specify run id

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Genome';

    my @field_list = ( 'reference_genome_id', 'reference_genome_name', 'reference_genome_path', 'taxonomy_id' );

    my @extra_conditions;
    if ($genome_id) {
        $genome_id = Cast_List( -list => $genome_id, -to => 'String' );
        push @extra_conditions, "Genome.Genome_ID IN ($genome_id)";
    }
    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

# Update a genome record
#
# $API->set_genome_data(-fields=>\@array, -values=>\@array,-genome_id=>18,-comment=>"updating some field");
#
sub set_genome_data {
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'values,genome_id' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $table        = $args{-table} || 'Genome';    ## eg SolexaRun or Solexa_Read
    my $fields       = $args{-fields};               ## list of fields to update (using defined aliases)
    my $values       = $args{ -values };             ## associated list of values
    my $genome_id    = $args{-genome_id};            ## specify update based upon run_id
    my $condition    = $args{-condition};
    my $valid_fields = $args{-valid_fields};
    my $quiet        = $args{-quiet};
    my $debug        = $args{-debug};
    my $comment      = $args{-comment};

    ### Generate condition based upon input parameters ###

    ## pass all parameters to allow use of filtering options to retrieve list of run_ids
    $args{-tables} = 'Genome';
    $condition = $args{-condition};

    my %retrieve_args = %args;
    $retrieve_args{-fields} = 'genome_id';    # just get the run_ids given the other filtering options...
    my %genome_data;
    %genome_data = %{ $self->get_genome_data(%retrieve_args) } if defined $self;

    my @genome_ids = @{ $genome_data{genome_id} };
    my $genome_list = Cast_List( -list => \@genome_ids, -to => 'string' );

    my @valid_field_list;
    if   ($valid_fields) { @valid_field_list = @$valid_fields }
    else                 { @valid_field_list = qw(Genome.Genome_URL Genome.Genome_Alias Genome.Genome_Path Genome.Genome_Type Genome.Genome_Status Genome.FKParent_Genome__ID Genome.Genome_Default) }

    if ($genome_list) {
        $condition .= " AND Genome_ID IN ($genome_list)";
    }
    else {
        Message("No runs found") unless $quiet;
        return 0;
    }

    my $start   = timestamp();
    my $updated = $self->set_data(
        -table        => $table,
        -fields       => $fields,
        -values       => $values,
        -condition    => "WHERE 1 $condition",
        -valid_fields => \@valid_field_list,
        -quiet        => $quiet,
        -debug        => $debug,
        -comment      => $comment,
    );

    Message("updated $updated Genome records") unless $quiet;
    return $self->api_output( -data => $updated, -summary => "Updated $updated Genome records", -start => $start, -log => 1, -customized_output => 1 );

}

# API to add a reference genome record
#
# Example:
# $API->add_genome(-genome_name=>"<ref_genome",-genome_path=>"hg19", -taxonomy_id=>9606,-genome_alias=>'hg19',-genome_url=>"http://www...",-parent_genome_id=>18, -genome_type=>'Transcriptome");
sub add_genome {
    my $self = shift;

    $self->log_parameters(@_);
    my %args          = &filter_input( \@_, -mandatory => 'genome_name,genome_path,taxonomy_id' );
    my $genome_name   = $args{-genome_name};                                                         # Genome Name
    my $genome_path   = $args{-genome_path};                                                         # filesystem path name
    my $taxonomy      = $args{-taxonomy_id};                                                         # taxonomy
    my $genome_type   = $args{-genome_type} || 'Genome';                                             #Genome or Transcriptome
    my $genome_alias  = $args{-genome_alias};                                                        # ie hg18
    my $genome_url    = $args{-genome_url};                                                          # web URL for the genome local or external
    my $parent_genome = $args{-parent_genome_id};                                                    # link to a parent genome id
    my @fields;
    my @values;
    @fields = ( 'Genome_Name', 'Genome_Path', 'FK_Taxonomy__ID', 'Genome_Type' );
    @values = ( $genome_name, $genome_path, $taxonomy, $genome_type );
    ## add optional fields
    if ($genome_alias) {
        push @fields, 'Genome_Alias';
        push @values, $genome_alias;
    }
    if ($genome_url) {
        push @fields, 'Genome_URL';
        push @values, $genome_url;
    }
    if ($parent_genome) {
        push @fields, 'FKParent_Genome__ID';
        push @values, $parent_genome;
    }

    my $dbc = $self;
    my $genome_id;
    ## add the genome record
    $genome_id = $dbc->Table_append_array( 'Genome', \@fields, \@values, -autoquote => 1 );

    return $genome_id;
}

####################
#
# New method to get a list of analysis_software
#
# Return: hash of data
#####################
sub get_analysis_software_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options
    my $run_id = $args{-run_id};    ### specify run id

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Analysis_Software';

    my @field_list = ( 'analysis_software_id', 'analysis_software_name' );

    my @extra_conditions;

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

####################
#
# New method to get a list of anatomic site
#
# Return: hash of data
#####################
sub get_anatomic_site_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options
    my $run_id = $args{-run_id};    ### specify run id

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Anatomic_Site';

    my @field_list = ( 'anatomic_site_id', 'anatomic_site_alias' );

    my @extra_conditions;

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

####################
#
# New method to get a list of work request
#
# Return: hash of data
#####################
sub get_work_request_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options
    my $run_id = $args{-run_id};    ### specify run id

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    my $library          = $args{-library};                               ### specify library
    my $goal             = $args{-goal};                                  ### specify goal name
    my $percent_complete = $args{-percent_complete};                      ### specify percent complete

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Work_Request,Funding,Goal';
    $join_condition .= " AND Work_Request.FK_Funding__ID = Funding.Funding_ID";
    $join_condition .= " AND Work_Request.FK_Goal__ID = Goal.Goal_ID";
    $join_condition .= " AND Work_Request.Scope = 'Library'";

    my @field_list = ( 'work_request_id', 'work_request_library', 'work_request_funding_sow', 'work_request_goal' );

    my @extra_conditions;

    my $libraries;
    $libraries = Cast_List( -list => $library, -to => 'string', -autoquote => 1 ) if $library;
    my $goals;
    $goals = Cast_List( -list => $goal, -to => 'string', -autoquote => 1 ) if $goal;

    if ($libraries) { push( @extra_conditions, "Work_Request.FK_Library__Name IN ($libraries)" ) }
    if ($goals)     { push( @extra_conditions, "Goal.Goal_Name IN ($goals)" ) }
    if ($percent_complete) { push @extra_conditions, "Work_Request.Percent_Complete < $percent_complete" }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

####################
#
# Accessor for getting libraries that have goals with analysis pipeline not finish
#
####################
sub get_incomplete_analysis_libraries {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args          = &filter_input( \@_, -args => 'pipeline_name', -mandatory => 'pipeline_name' );
    my $pipeline_name = $args{-pipeline_name};
    my $debug         = $args{-debug};

    my $start = timestamp();

    my %goals = $self->Table_retrieve(
        "Goal,Work_Request,Pipeline",
        [ 'Goal_Tables', 'Goal_Count', 'Goal_Condition', 'FK_Library__Name', 'SUM(Goal_Target)' ],
        "WHERE FK_Goal__ID = Goal_ID AND Pipeline_Name IN ('$pipeline_name') AND Goal_Name = Pipeline_Name AND Scope = 'Library' ",
        -group_by => "FK_Library__Name",
        -debug    => $debug
    );

    #print Dumper \%goals;

    my $libraries = join( ",", map {"\'$_\'"} @{ $goals{FK_Library__Name} } );

    #print "$libraries\n";
    my $tables    = $goals{Goal_Tables}[0];
    my $select    = $goals{Goal_Count}[0];
    my $condition = $goals{Goal_Condition}[0];
    $condition =~ s/\= \'\<LIBRARY\>\'/IN \($libraries\)/;

    my %found;
    %found = $self->Table_retrieve( $tables, [ $select, 'FK_Library__Name' ], "WHERE $condition ", -group_by => "FK_Library__Name", -debug => $debug ) if $select;

    #print Dumper \%found;

    my %goal_met;
    for ( my $i = 0; $i <= $#{ $found{FK_Library__Name} }; $i++ ) {
        $goal_met{ $found{FK_Library__Name}[$i] } = $found{$select}[$i];
    }

    #print Dumper \%goal_met;

    my @incomplete_analysis_libraries;
    for ( my $i = 0; $i <= $#{ $goals{FK_Library__Name} }; $i++ ) {
        if ( $goals{'SUM(Goal_Target)'}[$i] > $goal_met{ $goals{FK_Library__Name}[$i] } ) {

            #print "$goals{FK_Library__Name}[$i] goal not met\n";
            push @incomplete_analysis_libraries, $goals{FK_Library__Name}[$i];
        }
    }

    #print Dumper \@incomplete_analysis_libraries;

    my $output = join( ",", @incomplete_analysis_libraries );

    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}
####################
#
# Get a list of goals
#
# Return: hash of data
#####################
sub get_goal_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    my $goal      = $args{-goal};                                         ### specify goal name
    my $goal_type = $args{-goal_type};                                    # specify the goal type
    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Goal';
    my @field_list = ( 'goal_id', 'goal_name', 'goal_type', 'goal_scope', 'goal_description' );

    my @extra_conditions;

    my $goals;
    $goals = Cast_List( -list => $goal, -to => 'string', -autoquote => 1 ) if $goal;
    my $goal_types;
    $goal_types = Cast_List( -list => $goal_type, -to => 'string', -autoquote => 1 ) if $goal_type;
    if ($goals) {
        push @extra_conditions, "Goal.Goal_Name IN ($goals)";
    }
    if ($goal_types) {
        push @extra_conditions, "Goal_Type IN ($goal_types) ";
    }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

#####################
sub get_control_type_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    ## run specification options

    ## Output options
    my $fields      = $args{-fields} || '';
    my $add_fields  = $args{-add_fields};
    my $order       = $args{-order} || '';
    my $group       = $args{-group} || $args{-group_by} || $args{-key};
    my $KEY         = $args{-key};
    my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
    my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
    my $save        = $args{-save};                                       ### save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};                                ### just generate a list of output fields
    my $debug       = $args{-debug};

    ## Generate Condition ##
    my $join_condition = 'WHERE 1';

    ## normally the tables parameter will NOT be passed (if it is conditions should be also passed if required) ##
    my $tables = 'Control_Type,Organization';
    $join_condition .= " AND Control_Type.FK_Organization__ID = Organization_ID";

    my @field_list = ( 'Control_Type_ID', 'Control_Type_Name', 'Control_Description', 'Organization_Name', 'Control_Type' );

    my @extra_conditions;

    ##if ($goals)     { push( @extra_conditions, "Goal.Goal_Name IN ($goals)" ) }
    ##if ($percent_complete) { push @extra_conditions, "Work_Request.Percent_Complete < $percent_complete" }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input          => \%args,
        -field_list     => \@field_list,
        -group          => $group,
        -key            => $KEY,
        -order          => $order,
        -tables         => $tables,
        -join_condition => $join_condition,
        -conditions     => $conditions,
        -limit          => $limit,
        -quiet          => $quiet,
        -debug          => $debug
    );

}

####################
#
# Accessor for setting the Run_Status through the API
#
####################
sub set_run_status {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args    = &filter_input( \@_, -args => 'run_ids,status', -mandatory => 'run_ids,status' );
    my $run_ids = $args{-run_ids};
    my $status  = $args{-status};
    my $start   = timestamp();
    my $output  = &alDente::Run::set_run_status( -dbc => $self, -run_ids => $run_ids, -status => $status );
    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# Accessor for setting the Run_Comments through the API
#
# usage: $API->set_run_comments(-run_ids=>'90001,90002,90003',-comment=>"This is a test",-name=>'Dean');
#
####################
sub set_run_comments {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args    = &filter_input( \@_, -args => 'run_ids,comment,name', -mandatory => 'run_ids,comment,name' );
    my $run_ids = $args{-run_ids};
    my $comment = $args{-comment};
    my $name    = $args{-name};

    $comment = "Comment by $name: $comment";

    my $start = timestamp();
    my $output = &alDente::Run::annotate_runs( -dbc => $self, -run_ids => $run_ids, -comments => $comment, -quiet => 1 );
    return $self->api_output( -data => "Updated $output Run Comments", -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# Accessor for setting the Run_Validation through the API
#
####################
sub set_run_validation_status {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args    = &filter_input( \@_, -args => 'run_ids,status', -mandatory => 'run_ids,status' );
    my $run_ids = $args{-run_ids};
    my $status  = $args{-status};
    my $start   = timestamp();
    my $output  = &alDente::Run::set_validation_status( -dbc => $self, -run_ids => $run_ids, -status => $status );
    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}

###############
# call for updating the fields in Run tables
#
# usage $Solexa_API->set_run_data=>$dbc,-fields => ['QC_Status'],-values=>['Passed'],-run_id=>'53595,53596');
#
########################
sub set_run_data() {
########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'values,run_id' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $table        = $args{-table} || 'Run,RunBatch';    ## eg SolexaRun or Solexa_Read
    my $fields       = $args{-fields};                     ## list of fields to update (using defined aliases)
    my $values       = $args{ -values };                   ## associated list of values
    my $run_id       = $args{-run_id};                     ## specify update based upon run_id
    my $condition    = $args{-condition} || 1;
    my $valid_fields = $args{-valid_fields};
    my $quiet        = $args{-quiet};
    my $debug        = $args{-debug};
    my $comment      = $args{-comment};

    ### Generate condition based upon input parameters ###

    ## pass all parameters to allow use of filtering options to retrieve list of run_ids
    $args{-tables}    = 'Run,RunBatch';
    $args{-condition} = 'FK_RunBatch__ID = RunBatch_ID';
    $condition        = $args{-condition};

    my %retrieve_args = %args;
    $retrieve_args{-fields} = 'run_id';    # just get the run_ids given the other filtering options...
    my %run_data;
    %run_data = %{ $self->get_run_data(%retrieve_args) } if defined $self;

    my @run_ids = @{ $run_data{Run_ID} };
    my $run_list = Cast_List( -list => \@run_ids, -to => 'string' );

    my @valid_field_list;
    if   ($valid_fields) { @valid_field_list = @$valid_fields }
    else                 { @valid_field_list = qw(QC_Status Run.QC_Status Billable Run_Test_Status) }

    if ($run_list) {
        $condition .= " AND Run_ID IN ($run_list)";
    }
    else {
        Message("No runs found") unless $quiet;
        return 0;
    }

    my $start   = timestamp();
    my $updated = $self->set_data(
        -table        => $table,
        -fields       => $fields,
        -values       => $values,
        -condition    => "WHERE $condition",
        -valid_fields => \@valid_field_list,
        -quiet        => $quiet,
        -debug        => $debug,
        -comment      => $comment,
    );

    Message("updated $updated Run records") unless $quiet;
    return $self->api_output( -data => $updated, -summary => "Updated $updated Run records", -start => $start, -log => 1, -customized_output => 1 );
}

###############
# call for updating the fields in Run tables
#
# usage $Solexa_API->set_run_data=>$dbc,-fields => ['QC_Status'],-values=>['Passed'],-run_id=>'53595,53596');
#
########################
sub set_multiplex_run_analysis_data {
########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'values,run_id,multiplex_adapter_index' );
    return $self->set_multiplex_run_data(%args);

    $self->log_parameters(@_);
    %args = &filter_input( \@_, -mandatory => 'values,run_id,multiplex_adapter_index' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $table         = $args{-table} || 'Multiplex_Run_Analysis';    ## eg SolexaRun or Solexa_Read
    my $fields        = $args{-fields};                               ## list of fields to update (using defined aliases)
    my $values        = $args{ -values };                             ## associated list of values
    my $run_id        = $args{-run_id};                               ## specify update based upon run_id
    my $adapter_index = $args{-multiplex_adapter_index};
    my $condition     = $args{-condition} || 1;
    my $valid_fields  = $args{-valid_fields};
    my $quiet         = $args{-quiet};
    my $debug         = $args{-debug};
    my $comment       = $args{-comment};
    my $force         = $args{-force};

    ### Generate condition based upon input parameters ###

    ## pass all parameters to allow use of filtering options to retrieve list of run_ids
    $args{-tables}                  = 'Multiplex_Run_Analysis,Run_Analysis,Run';
    $condition                      = "Multiplex_Run_Analysis.FK_Run_Analysis__ID = Run_Analysis_ID and Run_Analysis.FK_Run__ID = Run_ID";
    $args{-condition}               = $condition;
    $args{-multiplex_adapter_index} = $adapter_index;
    $args{-current_analysis}        = 1;                                                                                                     ## get the latest run analysis
    my %retrieve_args = %args;
    $retrieve_args{-fields}   = 'multiplex_run_analysis_id,multiplex_adapter_index';                                                         # just get the run_ids given the other filtering options...
    $retrieve_args{-distinct} = 1;
    my %run_data;
    %run_data = %{ $self->get_run_analysis_data(%retrieve_args) } if defined $self;

    my @ids = @{ $run_data{multiplex_run_analysis_id} };
    my $multiplex_list = Cast_List( -list => \@ids, -to => 'string' );

    my @valid_field_list;
    if   ($valid_fields) { @valid_field_list = @$valid_fields }
    else                 { @valid_field_list = qw(Multiplex_Run_QC_Status Multiplex_Run_Analysis_Test_Mode) }

    my $set_condition;
    if ($multiplex_list) {
        $set_condition .= "WHERE 1 AND Multiplex_Run_Analysis_ID IN ($multiplex_list) ";
    }
    else {
        Message("No multiplex runs found") unless $quiet;
        return 0;
    }
    unless ($force) {
        ## check to see if the multiplex run analysis already has comments or qc status set
        my $runs = Cast_List( -list => $run_id, -to => 'string' );
        my @qc_status = $self->Table_find( 'Multiplex_Run_Analysis,Run_Analysis', 'Multiplex_Run_QC_Status', "WHERE Run_Analysis_ID = Multiplex_Run_Analysis.FK_Run_Analysis__ID and FK_Run__ID IN ($runs) and Adapter_Index = '$adapter_index'" );
        if (@qc_status) {
            my $qc_set = 0;
            foreach my $qc_status (@qc_status) {
                if ( $qc_status ne 'N/A' and length($qc_status) > 0 ) {
                    $qc_set = 1;
                }
            }
            if ($qc_set) {
                return 0;
            }
        }

    }
    my $start   = timestamp();
    my $updated = $self->set_data(
        -table        => $table,
        -fields       => $fields,
        -values       => $values,
        -condition    => $set_condition,
        -valid_fields => \@valid_field_list,
        -quiet        => $quiet,
        -debug        => $debug,
        -comment      => $comment,
    );
    Message("updated $updated Run records") unless $quiet;

    return $self->api_output( -data => $updated, -summary => "Updated $updated Run records", -start => $start, -log => 1, -customized_output => 1 );
}

###############
# call for updating the fields in Run tables
#
# usage $Solexa_API->set_run_data=>$dbc,-fields => ['QC_Status'],-values=>['Passed'],-run_id=>'53595,53596');
#
########################
sub set_multiplex_run_data {
########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'values,run_id,multiplex_adapter_index' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $table         = $args{-table} || 'Multiplex_Run';    ## eg SolexaRun or Solexa_Read
    my $fields        = $args{-fields};                      ## list of fields to update (using defined aliases)
    my $values        = $args{ -values };                    ## associated list of values
    my $run_id        = $args{-run_id};                      ## specify update based upon run_id
    my $adapter_index = $args{-multiplex_adapter_index};
    my $condition     = $args{-condition} || 1;
    my $valid_fields  = $args{-valid_fields};
    my $quiet         = $args{-quiet};
    my $debug         = $args{-debug};
    my $comment       = $args{-comment};
    my $force         = $args{-force};

    ### Generate condition based upon input parameters ###

    ## pass all parameters to allow use of filtering options to retrieve list of run_ids
    $args{-tables}                  = 'Multiplex_Run,Run';
    $condition                      = "Multiplex_Run.FK_Run__ID = Run_ID";
    $args{-condition}               = $condition;
    $args{-multiplex_adapter_index} = $adapter_index;
    $args{-current_analysis}        = 1;                                     ## get the latest run analysis
    my %retrieve_args = %args;
    $retrieve_args{-fields}   = 'multiplex_run_id,multiplex_adapter_index';    # just get the run_ids given the other filtering options...
    $retrieve_args{-distinct} = 1;
    my %run_data;
    %run_data = %{ $self->get_run_data(%retrieve_args) } if defined $self;
    my %ids;

    if ( $run_data{multiplex_run_id} ) {
        for ( my $i = 0; $i <= $#{ $run_data{multiplex_run_id} }; $i++ ) {
            $ids{ $run_data{multiplex_adapter_index}[$i] } = $run_data{multiplex_run_id}[$i];
        }
    }
    else {
        for my $key ( keys %run_data ) {
            if ( $run_data{$key}{multiplex_run_id} ) {
                $ids{ $run_data{$key}{multiplex_adapter_index} } = $run_data{$key}{multiplex_run_id};
            }
        }
    }

    my @valid_field_list;
    if   ($valid_fields) { @valid_field_list = @$valid_fields }
    else                 { @valid_field_list = qw(Multiplex_Run_QC_Status) }

    if ( !keys %ids ) {
        Message("No multiplex runs found") unless $quiet;
        return 0;
    }

    my @adapter_index_array = Cast_List( -list => $adapter_index, -to => 'array' );
    my @fields_array        = Cast_List( -list => $fields,        -to => 'array' );
    my @values_array        = Cast_List( -list => $values,        -to => 'array' );
    my @comment_array       = Cast_List( -list => $comment,       -to => 'array' );

    #check to see if all array size the same if not, do not procced
    my %size;
    my $id_size = keys %ids;
    $size{ $id_size - 1 } = 1;
    if ( !$size{$#adapter_index_array} || !$size{$#fields_array} || !$size{$#values_array} || !$size{$#comment_array} ) {
        return "Inconsistent number of entries";
    }

    my $update = 0;
    my $start  = timestamp();
    for ( my $i = 0; $i <= $#adapter_index_array; $i++ ) {
        if ( !$ids{ $adapter_index_array[$i] } ) {next}
        my $set_condition_one = "WHERE 1 AND Multiplex_Run_ID IN ($ids{$adapter_index_array[$i]})";
        my $adapter_index_one = $adapter_index_array[$i];
        my $field             = $fields_array[$i];
        my $value             = $values_array[$i];
        my $comment_one       = $comment_array[$i];

        unless ($force) {
            ## check to see if the multiplex run analysis already has comments or qc status set
            my $runs = Cast_List( -list => $run_id, -to => 'string' );
            my @qc_status = $self->Table_find( 'Multiplex_Run', 'Multiplex_Run_QC_Status', "WHERE FK_Run__ID IN ($runs) and Adapter_Index = '$adapter_index_one'", -debug => $debug );
            if (@qc_status) {
                my $qc_set = 0;
                foreach my $qc_status (@qc_status) {
                    if ( $qc_status ne 'N/A' and length($qc_status) > 0 ) {
                        $qc_set = 1;
                    }
                }
                if ($qc_set) {

                    #return 0;
                    next;
                }
            }
        }
        my $updated = $self->set_data(
            -table        => $table,
            -fields       => [$field],
            -values       => [$value],
            -condition    => $set_condition_one,
            -valid_fields => \@valid_field_list,
            -quiet        => $quiet,
            -debug        => $debug,
            -comment      => $comment_one,
        );
        Message("updated $updated Run records") unless $quiet;
        $update += $updated;
    }

    return $self->api_output( -data => $update, -summary => "Updated $update Run records", -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# Accessor for starting run analysis through the API
#
####################
sub start_run_analysis {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args                   = &filter_input( \@_, -args => 'run_id,pipeline_id', -mandatory => 'run_id,pipeline_id' );
    my $run_id                 = $args{-run_id};
    my $barcode_index          = $args{-barcode_index};                                                                     ## optional list of indices
    my $pipeline_id            = $args{-pipeline_id};
    my $force                  = $args{-force};
    my $parent_run_analysis_id = $args{-parent_run_analysis_id};
    my $batch_id               = $args{-batch_id};
    my $analysis_type          = $args{-analysis_type} || 'Tertiary';
    my $date_time              = $args{-date_time};

    my $start = timestamp();
    require alDente::Run_Analysis;
    require BWA::Run_Analysis;                                                                                              ## <CONSTRUCTION> may want to change scope of create_multiplex_analysis
    my $run_analysis_obj = new alDente::Run_Analysis( -dbc => $self );
    my $bwa_run_analysis = new BWA::Run_Analysis( -dbc     => $self );
    my $run_analysis_id = $run_analysis_obj->start_run_analysis(
        -run_id                 => $run_id,
        -analysis_pipeline_id   => $pipeline_id,
        -run_analysis_type      => $analysis_type,
        -force                  => $force,
        -parent_run_analysis_id => $parent_run_analysis_id,
        -batch_id               => $batch_id,
        -date_time              => $date_time
    );

    if ($barcode_index) {
        $bwa_run_analysis->create_multiplex_run_analysis( -run_analysis_id => $run_analysis_id, -index => $barcode_index, -quiet => 1 );
    }

    $run_analysis_obj->run_analysis();
    return $self->api_output( -data => $run_analysis_id, -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# Accessor for creating run analysis batch through the API
#
####################
sub create_run_analysis_batch {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args      = &filter_input( \@_, -args => 'comments,lims_user' );
    my $comments  = $args{-comments};
    my $lims_user = $args{-lims_user};
    my $start     = timestamp();

    require alDente::Run_Analysis;    ## <CONSTRUCTION> may want to change scope of create_multiplex_analysis
    my $run_analysis_obj = new alDente::Run_Analysis( -dbc => $self );
    my $run_analysis_batch_id = $run_analysis_obj->create_run_analysis_batch( -comments => $comments, -lims_user => $lims_user );

    return $self->api_output( -data => $run_analysis_batch_id, -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# Accessor for finishing run analysis through the API
#
####################
sub finish_run_analysis {
####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args                = &filter_input( \@_, -args => 'run_analysis_id,run_analysis_status', -mandatory => 'run_analysis_status' );
    my $run_analysis_id     = $args{-run_analysis_id};
    my $run_analysis_status = $args{-run_analysis_status};
    my $batch_id            = $args{-batch_id};
    my $date_time           = $args{-date_time};

    my $start = timestamp();
    require alDente::Run_Analysis;
    my $output;
    my $run_analysis_obj = new alDente::Run_Analysis( -dbc => $self );
    my @run_analyses;

    if ($run_analysis_id) {
        @run_analyses = Cast_List( -list => $run_analysis_id, -to => 'array' );
    }
    elsif ($batch_id) {
        @run_analyses = $self->Table_find( 'Run_Analysis', 'Run_Analysis_ID', "WHERE Run_Analysis.FK_Run_Analysis_Batch__ID = $batch_id" );
    }
    else {
        $output = "Argument run_analysis_id or batch_id must be passed, nothing done";
    }
    foreach my $run_analysis (@run_analyses) {
        my ($pipeline_step_id) = $self->Table_find( "Analysis_Step", "FK_Pipeline_Step__ID", "WHERE FK_Run_Analysis__ID = $run_analysis" );
        $run_analysis_obj->finish_analysis_step( -run_analysis_id => $run_analysis, -pipeline_step_id => $pipeline_step_id, -analysis_step_status => $run_analysis_status, -finish_time => $date_time ) if $pipeline_step_id;

        $run_analysis_obj->finish_run_analysis( -run_analysis_id => $run_analysis, -run_analysis_status => $run_analysis_status, -date_time => $date_time );

        my ($info) = $self->Table_find( "Run_Analysis", "FK_Run__ID,Run_Analysis_Type", "WHERE Run_Analysis_ID = $run_analysis" );
        my ( $run_id, $run_analysis_type ) = split( ",", $info );
        my $update = $self->Table_update( 'Run', 'Run_Status', 'Analyzed', "WHERE Run_ID = $run_id", -autoquote => 1 ) if $run_analysis_type eq 'Secondary';

        $output .= "Run_Analysis $run_analysis set to $run_analysis_status\n";
    }
    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}
###########################
sub set_run_analysis_data {
###########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args               = &filter_input( \@_, -args => 'run_analysis_id,batch_id', -mandatory => 'run_analysis_id|batch_id' );
    my $run_analysis_id    = $args{-run_analysis_id};
    my $batch_id           = $args{-batch_id};                                                                                      # run analysis batch id
    my $start              = $args{-start_analysis_datetime};                                                                       ## start datetime SQL format
    my $finish             = $args{-finish_analysis_datetime};                                                                      ## finish datetime SQL format
    my $analysis_comments  = $args{-analysis_comments};                                                                             ## comments for the run analysis
    my $analysis_test_mode = $args{-analysis_test_mode};                                                                            ## Production, Test or Duplicate
    my @run_analyses;
    my $output;

    if ($run_analysis_id) {
        push @run_analyses, $run_analysis_id;
    }
    elsif ($batch_id) {
        @run_analyses = $self->Table_find( 'Run_Analysis', 'Run_Analysis_ID', "WHERE Run_Analysis.FK_Run_Analysis_Batch__ID = $batch_id" );
    }
    else {
        $output = "Argument run_analysis_id or batch_id must be passed, nothing done";
    }
    my @ra_fields;
    my @ra_values;
    my @as_fields;
    my @as_values;
    if ($start) {
        push @ra_fields, 'Run_Analysis_Started';
        push @ra_values, $start;
        push @as_fields, 'Analysis_Step_Started';
        push @as_values, $start;
    }
    if ($finish) {
        push @ra_fields, 'Run_Analysis_Finished';
        push @ra_values, $finish;
        push @as_fields, 'Analysis_Step_Finished';
        push @as_values, $finish;
    }
    if ($analysis_comments) {
        push @ra_fields, 'Run_Analysis_Comments';
        push @ra_values, $analysis_comments;
    }
    if ($analysis_test_mode) {
        push @ra_fields, 'Run_Analysis_Test_Mode';
        push @ra_values, $analysis_test_mode;
    }
    foreach my $run_analysis (@run_analyses) {
        my ($ra_ok) = $self->Table_update_array( 'Run_Analysis', \@ra_fields, \@ra_values, "WHERE Run_Analysis_ID = $run_analysis", -autoquote => 1, -debug => 1 );
        if (@as_fields) {
            my ($as_ok) = $self->Table_update_array( 'Analysis_Step', \@as_fields, \@as_values, "WHERE FK_Run_Analysis__ID = $run_analysis", -autoquote => 1, -debug => 1 );
        }
        $output .= "Run_Analysis $run_analysis @ra_fields set to @ra_values \n";
    }
    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}

####################
#
# New method to simplify run data extraction (avoids complexity of _generate_query method)
# (this style should replace all of the other API methods as well to simplify maintenance / debugging.
#
# Return: hash of data
#####################
sub get_event_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -mandatory => 'study_id|project_id|library|run_id|run_name|plate_id|plate_number|original_plate_id|applied_plate_id|sample_id|since|condition|limit|protocol|protocol_step' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_condition = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id        = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id      = $args{-project_id};          ### specify project_id
    my $library         = $args{-library};             ### specify library
    ## run specification options
    my $run_id         = $args{-run_id};               ### specify run id
    my $run_name       = $args{-run_name};             ### specify run name (must be exact format)
    my $exclude_run_id = $args{-exclude_run_id};       ### specify run id to EXCLUDE (for Run or Read scope)
    ## plate specification options
    my $plate_id          = $args{-plate_id};                   ### specify plate_id
    my $plate_number      = $args{-plate_number};               ### specify plate number
    my $plate_type        = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class       = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};          ### specify original plate id
    my $original_well     = $args{-original_well};              ### specify original well
    my $applied_plate_id  = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant          = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id         = $args{-sample_id};                  ### specify sample_id
    my $library_type      = $args{-library_type};
    my $input_conditions  = $args{-condition};
    my $input_joins       = $args{-input_joins};
    my $input_left_joins  = $args{-input_left_joins};
    ## Custom additions for this method ##
    my $solution_id     = $args{-solution_id};
    my $equipment_id    = $args{-equipment_id};
    my $protocol        = $args{-protocol};                     ### protocol name
    my $protocol_step   = $args{-protocol_step};                ### protocol step name
    my $protocol_steps  = $args{-protocol_steps};
    my $plate_format    = $args{-plate_format};                 ### plate format
    my $include_parents = $args{-include_parents};              ### check for events applied to parent plates as well
    my $include_source  = $args{-include_source};               ### check for events applied to parent plates of redefined source plates as well

    ## Inclusion / Exclusion options
    my $since = $args{-since};                                  ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Prep_DateTime';

            #    my $include    = $args{-include} || 0;                        ### specify data to include (eg. production,approved)
            my $exclude = $args{-exclude} || 0;                 ### OR specify data to exclude (eg. failed)

            ## Output options
            my $fields     = $args{-fields} || '';
            my $add_fields = $args{-add_fields};
            my $order      = $args{-order} || '';
            my $group      = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY        = $args{-key};                                        # || $group;
            my $limit      = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet      = $args{-quiet};                                      ### suppress feedback by setting quiet option

            ### Re-Cast arguments if necessary ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    if ( $plate_id && $include_parents ) {
        $plates = &alDente::Container::get_Parents( -dbc => $self, -id => $plates, -format => 'list', -simple => 1, -include_source => $include_source );

    }
    my $prot_steps;
    if ($protocol_steps) {
        $prot_steps = Cast_List( -list => $protocol_steps, -to => 'string', -autoquote => 1 );
    }

    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $runs;
    $runs = Cast_List( -list => $run_id, -to => 'string' ) if $run_id;
    my $run_names;
    $run_names = Cast_List( -list => $run_name, -to => 'string', -autoquote => 1 ) if $run_name;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;
    my $solutions;
    $solutions = Cast_List( -list => $solution_id, -to => 'string', -autoquote => 1 ) if $solution_id;
    my $equipment;
    $equipment = Cast_List( -list => $equipment_id, -to => 'string', -autoquote => 1 ) if $equipment_id;
    my $protocols;
    $protocols = Cast_List( -list => $protocol, -to => 'string', -autoquote => 1 ) if $protocol;
    my $plate_formats;
    $plate_format = Cast_List( -list => $plate_format, -to => 'string', -autoquote => 1 ) if $plate_format;

    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;

##########################################
    # Retrieve Record Data from the Database #
##########################################

    my $tables         = 'Lab_Protocol,Prep';                                ## <- Supply list of Tables to retrieve data from ##
    my $join_condition = 'WHERE Prep.FK_Lab_Protocol__ID=Lab_Protocol_ID';
    ## Generate Condition ##

    my $left_join_tables = '';

    ## specify optional tables to include (with associated condition) - used in 'include_if_necessary' method ##
    my $join_conditions = {
        'Plate'        => "Plate_Prep.FK_Plate__ID=Plate_ID",
        'Plate_Format' => "Plate_Format.Plate_Format_ID = Plate.FK_Plate_Format__ID",
        'Plate_Prep'   => "Plate_Prep.FK_Prep__ID=Prep_ID",
        'Library'      => "Plate.FK_Library__Name = Library.Library_Name",
        'Run'          => "Run.FK_Plate__ID = Plate.Plate_ID",
    };

    my $left_join_conditions = {
        'Solution'  => "Plate_Prep.FK_Solution__ID=Solution_ID",
        'Equipment' => "Plate_Prep.FK_Equipment__ID=Equipment_ID",
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    if ( defined $libraries ) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($plates)              { push( @extra_conditions, "Plate.Plate_ID IN ($plates)" ) }
    if ($plate_numbers)       { push( @extra_conditions, "Plate.Plate_Number IN ($plate_numbers)" ) }
    if ($runs)                { push( @extra_conditions, "Run.Run_ID IN ($runs)" ) }
    if ($samples)             { push( @extra_conditions, "Clone_Sequence.FK_Sample__ID IN ($samples)" ) }
    if ($library_types)       { push( @extra_conditions, "(Vector_Based_Library.Vector_Based_Library_Type IN ($library_types) OR Library_Type IN ($library_types))" ) }
    if ($solutions)           { push( @extra_conditions, "Plate_Prep.FK_Solution__ID IN ($solutions)" ) }
    if ($equipment)           { push( @extra_conditions, "Plate_Prep.FK_Equipment__ID IN ($equipment)" ) }
    if ($protocols)           { push( @extra_conditions, "Lab_Protocol.Lab_Protocol_Name IN ($protocols)" ) }
    if ($protocol_step)       { push( @extra_conditions, "Prep.Prep_Name like \"%$protocol_step%\"" ) }
    if ($protocol_steps)      { push( @extra_conditions, "Prep.Prep_Name IN ($prot_steps) " ) }
    if ($plate_format)        { push( @extra_conditions, "Plate_Format.Plate_Format_Type IN ($plate_formats)" ) }

    ## Special inclusion / exclusion options ##
    #    if ($since) { push(@extra_conditions,"Run_DateTime >= '$since'") }
    #    if ($until)  { push(@extra_conditions,"Run_DateTime <= '$until'") }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## actually this is the same logic as get_read_data, but looking at slightly different info ...
    my @field_list = qw(event event_time event_comments);
    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet,
        -date_field           => "Prep.Prep_DateTime",
    );
}

sub get_original_reagents {
    my $self = shift;
    $self->log_parameters(@_);
    my %args        = &filter_input( \@_, -args => 'solution_id', -mandatory => 'solution_id' );
    my $solution_id = $args{-solution_id};
    my $class       = $args{-class};                                                               ### To filter original reagents based on Stock_Type. E.g. Primer

    my @field_list     = qw(FKUsed_Solution__ID Stock_Catalog_Name Stock_Type);
    my $conditions     = "FKMade_Solution__ID in ($solution_id)";
    my $tables         = 'Stock_Catalog,Stock,Solution as Made,Mixture,Solution as Used';                                                                                                    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition = 'WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND FKMade_Solution__ID=Made.Solution_ID AND FKUsed_Solution__ID=Used.Solution_ID AND Used.FK_Stock__ID=Stock_ID';
    my $alldata;
    my $used_list = $solution_id;

    while ( $used_list =~ /[1-9]/ ) {
        my $data = $self->generate_data(
            -input          => \%args,
            -field_list     => \@field_list,
            -tables         => $tables,
            -conditions     => $conditions,
            -join_condition => $join_condition,
        );

        if ( ref $data->{Stock_Catalog_Name} eq 'ARRAY' ) {
            push @{ $alldata->{Stock_Catalog_Name} },  @{ $data->{Stock_Catalog_Name} };
            push @{ $alldata->{FKUsed_Solution__ID} }, @{ $data->{FKUsed_Solution__ID} };
            push @{ $alldata->{Stock_Type} },          @{ $data->{Stock_Type} } if $class;
            $used_list = join ',', @{ $data->{FKUsed_Solution__ID} };
            $conditions = "FKMade_Solution__ID in ($used_list)";
        }
        else { $used_list = ''; }
    }

    #take out non-unique solutions
    my %unique;
    my $count = $#{ $alldata->{FKUsed_Solution__ID} };
    for ( my $i = 0; $i <= $count; $i++ ) {
        if ( $unique{ $alldata->{FKUsed_Solution__ID}[$i] } || ( $class && $alldata->{Stock_Type}[$i] ne $class ) ) {
            splice( @{ $alldata->{FKUsed_Solution__ID} }, $i, 1 );
            splice( @{ $alldata->{Stock_Catalog_Name} },  $i, 1 );
            splice( @{ $alldata->{Stock_Type} },          $i, 1 ) if $class;
            $count = $#{ $alldata->{FKUsed_Solution__ID} };
            $i--;
        }
        else { $unique{ $alldata->{FKUsed_Solution__ID}[$i] } = 1; }
    }

    my $start = timestamp();
    $self->api_output( -data => $alldata, -start => $start, -log => 1 );
}

##########################
sub get_gelrun_summary {
##########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    return $self->convert_parameters_for_summary( -scope => 'gelrun', %args );
}

# Gel Run Data
#
#
#####################
sub get_gelrun_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $fields          = $args{-fields};
    my $add_fields      = $args{-add_fields};
    my $group_id        = $args{-group_id};
    my $billable        = $args{-billable};
    my $run_status      = $args{-run_status};
    my $run_validation  = $args{-run_validation};
    my $analysis_status = $args{-analysis_status};
    my $gelrun_purpose  = $args{-gelrun_purpose};
    my $gel_name        = $args{-Gel_Name};          ### If Gel_Name has been passed, return the Approved, Non-aborted/non-failed run
    my $gelrun_type     = $args{-type};

    my @input_conditions = ();
    if ($gelrun_purpose) {
        my $gelrun_purposes = Cast_List( -list => $gelrun_purpose, -to => 'string', -autoquote => 1 );
        push( @input_conditions, "GelRun_Purpose.GelRun_Purpose_Name IN ($gelrun_purposes)" );
    }
    if ($analysis_status) {
        push( @input_conditions, "Gel_Analysis_Status.Status_Name='$analysis_status'" );
    }

    if ($group_id) {
        push( @input_conditions, "Pipeline.FK_Grp__ID in ($group_id)" );
    }

    if ($billable) {
        push( @input_conditions, "Run.Billable in ($billable)" );
    }

    if ( $gel_name and ( $run_status or $run_validation ) ) {
        $self->error("Cant specify both Gel_Name, and Run_Status or Run Validation");
        return;
    }

    if ($gel_name) {
        $run_validation = 'Approved';
        $run_status     = 'Initiated,In Process,Data Acquired,Analyzed,Analyzing';
        push( @input_conditions, "Gel_Name='$gel_name'" );

    }

    if ($run_status) {
        $run_status = Cast_List( -list => $run_status, -to => 'string', -autoquote => 1 );
        push( @input_conditions, "Run.Run_Status in ($run_status)" );
    }

    if ($run_validation) {
        $run_validation = Cast_List( -list => $run_validation, -to => 'string', -autoquote => 1 );
        push( @input_conditions, "Run.Run_Validation in ($run_validation)" );
    }

    if ($gelrun_type) {
        push @input_conditions, "GelRun.GelRun_Type IN ($gelrun_type)";
    }

    my @field_list = qw(run_time run_name run_status plate_id library plate_number gel_type);

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    $args{-fields} = \@field_list;

    my $input_joins;

    $args{-tables} = 'Run,GelRun';
    push @input_conditions, 'GelRun.FK_Run__ID=Run_ID';

    $args{-condition} = \@input_conditions;

    my $input_left_joins;
    $input_left_joins->{'Plate'}                         = 'Run.FK_Plate__ID = Plate.Plate_ID';
    $input_left_joins->{'Library'}                       = 'Plate.FK_Library__Name = Library.Library_Name';
    $input_left_joins->{'Project'}                       = 'Library.FK_Project__ID = Project.Project_ID';
    $input_left_joins->{'GelAnalysis'}                   = 'GelAnalysis.FK_Run__ID = Run.Run_ID';
    $input_left_joins->{'Equipment AS CombEquipment'}    = 'GelRun.FKComb_Equipment__ID = CombEquipment.Equipment_ID';
    $input_left_joins->{'Equipment AS PouredEquipment'}  = 'GelRun.FKAgarosePour_Equipment__ID = PouredEquipment.Equipment_ID';
    $input_left_joins->{'Equipment AS BoxEquipment'}     = 'GelRun.FKGelBox_Equipment__ID = BoxEquipment.Equipment_ID';
    $input_left_joins->{'Equipment AS ScannerEquipment'} = 'RunBatch.FK_Equipment__ID = ScannerEquipment.Equipment_ID';
    $input_left_joins->{'Employee AS PouredEmployee'}    = 'GelRun.FKPoured_Employee__ID = PouredEmployee.Employee_ID';
    $input_left_joins->{'Employee AS LoadedEmployee'}    = 'RunBatch.FK_Employee__ID = LoadedEmployee.Employee_ID';
    $input_left_joins->{'Rack AS GelRack'}               = 'Run.FKPosition_Rack__ID = GelRack.Rack_ID';
    $input_left_joins->{'Status AS Gel_Analysis_Status'} = 'GelAnalysis.FK_Status__ID = Gel_Analysis_Status.Status_ID';
    $input_left_joins->{'Pipeline'}                      = 'Plate.FK_Pipeline__ID = Pipeline.Pipeline_ID';

    # <CONSTRUCTION> dynamically determine Object_Class_ID?
    $input_left_joins->{'FailReason'}     = 'Fail.FK_FailReason__ID = FailReason.FailReason_ID AND FailReason.FK_Object_Class__ID = 7';
    $input_left_joins->{'Fail'}           = 'Fail.Object_ID = GelRun.GelRun_ID';
    $input_left_joins->{'GelRun_Purpose'} = 'GelRun.FK_GelRun_Purpose__ID = GelRun_Purpose.GelRun_Purpose_ID';

    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $input_left_joins;
    $args{-date_format}      = 'SQL';

    my $start = timestamp();
    my $data  = $self->get_run_data(%args);    ## access method in general
    return $self->api_output( $data, -start => $start, -log => 1, -sql => 1 );
}

####################################
# Like get_gelrun_data, but increased degree of focus to include land info.
#
#####################
sub get_lane_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }
    my $fields      = $args{-fields};
    my $add_fields  = $args{-add_fields};
    my $alias_type  = $args{-alias_type};
    my $fail_reason = $args{-fail_reason};    ### Retrieve lanes failed with '%$fail_reason%'
    my $lane_status = $args{-lane_status};    ### Filter out by the given lane status

    ## common options understood by get_run_data (see alDente_API::get_run_data for more options) ##
    my $run_id           = $args{-run_id};                                            ### specify run id
    my $library          = $args{-library};                                           ### specify library
    my $group_by         = $args{-group_by} || 'Lane_ID';
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};
    my @condition        = Cast_List( -list => $args{-condition}, -to => 'array' );

    my @field_list = ( 'run_name', 'run_time', 'lane_sample', 'lane_status', 'well', 'size_estimate', 'band_size', 'band_number', 'band_intensity' );

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    if ($lane_status) {
        push @condition, "Lane.Lane_Status='$lane_status'";
    }

    if ($fail_reason) {
        push @condition, "FailReason.FailReason_Name LIKE '%$fail_reason%'";
    }

    ### Over ride the grouping for get_run_data if multiple failed lanes exist in the database
    if ( $lane_status =~ /failed/i or $fail_reason ) {
        $group_by .= ',Fail.Fail_ID';
    }

    my ($lane_object_id) = $self->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class='Lane'" );

    $args{-fields} = \@field_list;

    $input_joins->{'GelRun'} = 'GelRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Sample'} = 'Sample.Sample_ID = Lane.FK_Sample__ID';
    $input_joins->{'Lane'}   = 'Lane.FK_GelRun__ID = GelRun.GelRun_ID';

    $input_left_joins->{'Equipment AS CombEquipment'}    = 'GelRun.FKComb_Equipment__ID = CombEquipment.Equipment_ID';
    $input_left_joins->{'Equipment AS BoxEquipment'}     = 'GelRun.FKGelBox_Equipment__ID = BoxEquipment.Equipment_ID';
    $input_left_joins->{'Equipment AS ScannerEquipment'} = 'RunBatch.FK_Equipment__ID = ScannerEquipment.Equipment_ID';
    $input_left_joins->{'Employee AS PouredEmployee'}    = 'GelRun.FKPoured_Employee__ID = PouredEmployee.Employee_ID';
    $input_left_joins->{'Employee AS LoadedEmployee'}    = 'RunBatch.FK_Employee__ID = LoadedEmployee.Employee_ID';
    $input_left_joins->{'Rack AS GelRack'}               = 'Run.FKPosition_Rack__ID = GelRack.Rack_ID';
    $input_left_joins->{'Status AS Gel_Analysis_Status'} = 'GelAnalysis.FK_Status__ID = Gel_Analysis_Status.Status_ID';
    $input_left_joins->{'Fail'}                          = 'Lane.Lane_ID = Fail.Object_ID';
    $input_left_joins->{'FailReason'}                    = "FailReason.FailReason_ID = Fail.FK_FailReason__ID AND Fail.FK_Object_Class__ID=$lane_object_id";

    if ($alias_type) {
        $input_left_joins->{'Sample_Alias'} = "Lane.FK_Sample__ID = Sample_Alias.FK_Sample__ID";
        push @field_list, 'alias_name';
        push @condition,  "Sample_Alias.Alias_Type='$alias_type'";
    }

    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $input_left_joins;
    $args{-date_format}      = 'SQL';
    $args{-group_by}         = $group_by;
    $args{-condition}        = \@condition;

    return $self->get_run_data(%args);    ## access method in general
}

####################################
# Like get_gelrun_data, but increased degree of focus to include band info.
#
#####################
sub get_band_data {
#####################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $fields           = $args{-fields};
    my $add_fields       = $args{-add_fields};
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## common options understood by get_run_data (see alDente_API::get_run_data for more options) ##
    my $run_id  = $args{-run_id};     ### specify run id
    my $library = $args{-library};    ### specify library

    my $group_by = 'Band_ID';

    my @field_list = qw(sample_id band_size band_number band_intensity band_type);

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    $input_joins->{'Band'} = 'Lane.Lane_ID = Band.FK_Lane__ID';

    $args{-fields}      = \@field_list;
    $args{-input_joins} = $input_joins;
    $args{-group_by}    = $group_by;

    return $self->get_lane_data(%args);    ## access method in general
}
#####################
# Find out solution information applied to a plate or during a prep
#  <snip>
#   Example:
#      my $data = $API->get_application_data(-plate_id=>$plate);
#  </snip>
#
######################
sub get_application_data {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

    my $fields           = $args{-fields};
    my $add_fields       = $args{-add_fields};
    my $input_joins      = $args{-input_joins} || {};    ## specific join table conditions ...
    my $left_joins       = $args{-left_joins} || {};     ## specific join table conditions ...
    my $include_parents  = $args{-include_parents};      ## include solutions applied to parent plates
    my $input_conditions = $args{-condition};
    my $type             = $args{-type};

    $input_joins->{'Solution'}            = 'Solution.Solution_ID=Plate_Prep.FK_Solution__ID';
    $input_joins->{'Stock'}               = 'Solution.FK_Stock__ID=Stock.Stock_ID';
    $input_joins->{'Stock_Catalog'}       = 'Stock_Catalog.Stock_Catalog_ID = Stock.FK_Stock_Catalog__ID';
    $input_joins->{'Employee as Prepper'} = 'Prep.FK_Employee__ID=Prepper.Employee_ID';
    $input_joins->{'Primer'}              = 'Primer.Primer_Name = Stock_Catalog.Stock_Catalog_Name';         ## will only include primers if Primer fields are requested ##

    my $types;
    $types = Cast_List( -list => $type, -to => 'string', -autoquote => 1 ) if $type;

    my @field_list = qw(event application_time applied_by event_comments solution_id solution_name);
    push( @field_list, 'stock_id', 'solution_id', 'stock_name', 'count(*) as plates', 'GROUP_CONCAT(plate_id) as plate_list', 'applied_qty', 'plate_set_number' );

    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array' ) if $input_conditions;
    push( @extra_conditions, "Solution.Solution_Type IN ($types)" ) if $types;

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    $args{-fields}           = \@field_list;
    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $left_joins;
    $args{-condition}        = \@extra_conditions;

    return $self->get_event_data(%args);
}

######################################################
## methods to facilitate automated query generation ##
######################################################

####################
#
# Generic method which generates the data output by dynamically building the query statement as required:
#  - allows aliases for field names (in either field list, group list or conditions)
#  - dynamically includes only tables necessary based upon join_conditions hash and left_join_conditions hash.
#
####################
sub generate_data {
####################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $save        = $args{-save};           ### (flag) save query results in hash for easy retrieval
    my $list_fields = $args{-list_fields};    ### (flag) just generate a list of output fields
    my $quiet       = $args{-quiet};          ### (flag) suppress most feedback
    my $input       = $args{-input};          ### input arguments (to allow caching of queries)
    ### retrieve applicable object attributes ###
    my @field_list;
    @field_list = &Cast_List( -to => 'array', -list => $args{-field_list} ) if $args{-field_list};    ### list of fields to retrieve
    my $group = $args{-group};
    my $KEY   = $args{-key};
    my $order = $args{-order};
    my $limit = $args{-limit};
    my $debug = $args{-debug};
    my $log;
    $log = $input->{'-log'} if defined $input->{'-log'};
    my $retroactive;
    $retroactive = $input->{'-retroactive'} if defined $input->{'-retroactive'};    ### flag to pass to add_Attributes() for allowing attribute retrieval retroactively back to the original plates if the attribute value for the current plate is empty
    my $view_edit_comments;
    $view_edit_comments = $input->{'-view_edit_comments'} if defined $input->{'-view_edit_comments'};    ### flag to add edit comments of given fields

    my $date_field = $args{-date_field};

    #    my $attribute_link = $args{-attribute_link};   deprecated for now... may be useful, but currently this is figured out automatically      ### explicitly indicate which attributes may be linked to this object

    my $tables               = $args{-tables};                                                           ### static list of tables to include (always)
    my $join_condition       = $args{-join_condition};                                                   ### condition (if applicable) which joins static table list
    my $left_join_tables     = $args{-left_join_tables};                                                 ### static -left_join_tables=>'LEFT JOIN Plate ON Run.FK_Plate__ID=Plate_ID'
    my $conditions           = $args{-conditions} || 1;                                                  ### input conditions
    my $join_conditions      = $args{-join_conditions};                                                  ### dynamic joins eg: -join_conditions=>{'Plate' => 'Run.FK_Plate__ID=Plate_ID'}
    my $left_join_conditions = $args{-left_join_conditions};                                             ### dynamic left joins eg: -left_join_conditions=>{'Plate' => 'Run.FK_Plate__ID=Plate_ID'}

    ## Options that may be passed in as general arguments ##
    my $date_format = 'Simple';                                                                          ## (Mon DD, YYYY)
    if ( defined $input->{-date_format} )    { $date_format    = $input->{-date_format} }
    if ( defined $input->{-tables} )         { $tables         = $input->{-tables} }
    if ( defined $input->{-join_condition} ) { $join_condition = $input->{-join_condition}; }
    if ( defined $input->{-save} )  { $save  ||= $input->{-save}; }
    if ( defined $input->{-debug} ) { $debug ||= $input->{-debug}; }
    if ( defined $input->{-list_fields} ) { $list_fields = $input->{-list_fields}; }
    if ( $group || $KEY ) { push( @field_list, 'Count(*) as count' ); }

    my @include_tables = split ',', $tables;
    if ($join_conditions) {
        push @include_tables, map {
            if   (/(.+) AS (.*)/i) {$1}
            else                   {$_}
        } keys %$join_conditions;
    }
    if ($left_join_conditions) {
        push @include_tables, map {
            if   (/(.+) AS (.*)/i) {$1}
            else                   {$_}
        } keys %$left_join_conditions;
    }

    #    my @include_tables = @{ unique_items( \@unique_tables ) };

    ## parse Since, Until options to applicable date field ##
    my ( $since, $until );
    if ( defined $input->{-since} ) {
        $since = $input->{-since};
    }
    if ( defined $input->{ -until } ) {
        $until = $input->{ -until };
        }

        if ( $since || $until ) {
                my $date_condition = $self->parse_date_condition( -date_field => $date_field, -since => $since, -until => $until, -on_fail => 0 );
            if ( defined $date_condition ) { $conditions .= ' AND ' . $date_condition }
    }

    foreach my $key ( split ',', $KEY ) {
        push( @field_list, $key ) unless ( grep /\b$key\b/, @field_list );    ## add to fields if not already...
    }
###    if ($group =~/month/i){
###	   my $month_replace = "Month($date_field), Year($date_field)";
###	   $group =~s/month/$month_replace/ig;
###    } elsif ($group =~/year/i){
###	   my $year_replace = "Year($date_field)";
###	   $group =~s/year/$year_replace/ig;
###    }
###    print "GROUP $group";
    ## retrieve mapping of simple names to actual fields

    my %Fields = %{
        &alDente::alDente_API::map_to_fields(
            -key        => $KEY,
            -fields     => \@field_list,
            -order      => $order,
            -group      => $group,
            -key        => $KEY,
            -tables     => $tables,
            -quiet      => $quiet,
            -conditions => $conditions,
            -left_joins => $left_join_conditions,
            -joins      => $join_conditions
        )
        };

    ## <CONSTRUCTION> - send reference which is adapted instead (check the way this works with a scalar..)

    ## reset variables as required (replaces aliases as necessary)
    $group      = $Fields{group};
    $KEY        = $Fields{key};
    $order      = $Fields{order};
    $conditions = $Fields{conditions};

    my @final_field_list;
    my @attribute_types;
    foreach my $newfield (@field_list) {
        my $att_types = $self->is_Attribute( -alias => $newfield, -tables => \@include_tables, -debug => $debug );
        if ($att_types) {
            ## this field is actually an attribute (or contains an attribute)
            foreach my $att ( split ',', $att_types ) {
                push @attribute_types, $att;
                my ($att_table) = split /\./, $att;

                if ( !$att_table ) {next}    ## just in case this is somehow blank

                my ($primary_field) = $self->SDB::DBIO::get_field_info( $att_table, undef, 'Primary' );
                push @final_field_list, "$att_table.$primary_field";    ## include reference to records for which there are attributes pointing
            }
            next;
            ## exclude fields which are retrieved via add_Attributes later
        }

        if ( $newfield =~ /(.*) AS (.*)/i ) {
            my $field   = $1;
            my $thiskey = $2;
            if ( $Fields{$thiskey} ) {
                $newfield = "$Fields{$thiskey} AS $thiskey";
            }
        }
        elsif ( $Fields{$newfield} ) {
            $newfield = "$Fields{$newfield} AS $newfield";
        }
        else {
            print "$newfield NOT FOUND (ok if explicit field)\n" if ( $args{-debug} && !$quiet );
        }
        push @final_field_list, $newfield;
    }

    ## Add optional fields if necessary (check fields requested, conditions for extra tables)
    my $dynamic_joins = &alDente::alDente_API::dynamic_joins(
        -fields     => \@final_field_list,
        -condition  => $conditions,
        -table_list => "$tables $left_join_tables",
        -join       => $join_conditions,
        -left_join  => $left_join_conditions,
        -quiet      => $quiet,
        -dbc        => $self
    );

    $left_join_tables .= " $dynamic_joins ";

    ## set limit, group parameters ##
    if ($limit) { $limit = "LIMIT $limit" }
    if ($group) { $group = "GROUP BY $group" }
    if ($order) { $order = "ORDER BY $order" }

    if ($list_fields) {
        if ( $left_join_tables =~ /^\s*$/ ) {
            $self->_list_Fields( $tables, !$quiet );
        }

        else {
            $self->_list_Fields( "$tables $left_join_tables", !$quiet );
        }

        return {};
    }

    my $start = timestamp();
    my $sql;
    $sql = "SELECT " . Cast_List( -list => \@final_field_list, -to => 'String' ) . " FROM ($tables) $left_join_tables" . "$join_condition AND $conditions $group $order $limit";

    $self->{last_query} = $sql;

    my %data;

    %data = $self->Table_retrieve( "($tables) $left_join_tables", \@final_field_list, "$join_condition AND $conditions $group $order $limit", -debug => $debug, -quiet => 1, -date_format => $date_format ) if @final_field_list;

    if (@attribute_types) {
        $self->add_Attributes( -attributes => \@attribute_types, -data => \%data, -fields => \@field_list, -retroactive => $retroactive );
    }

    if ($view_edit_comments) {
        my @view_edit_comment = Cast_List( -list => $view_edit_comments, -to => 'array' );
        map {s/_edit_comments//} @view_edit_comment;
        my %Fields = %{
            &alDente::alDente_API::map_to_fields(
                -fields     => \@view_edit_comment,
                -tables     => $tables,
                -quiet      => $quiet,
                -conditions => $conditions,
                -left_joins => $left_join_conditions,
                -joins      => $join_conditions
            )
            };
        $self->add_edit_comments( -edit_fields => \@view_edit_comment, -fields => \%Fields, -data => \%data );
    }
    Message("keying on $KEY") if ( $KEY && !$quiet );
    return $self->api_output( \%data, -start => $start, -save => $save, -key => $KEY, -sql => $sql, -input => $input, -debug => $debug, -log => $log );
}

###########################
sub parse_date_condition {
###########################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $date_field = $args{-date_field};     ## field of interest
    my $since      = $args{-since};
    my $until      = $args{ -until };
            my $on_fail = $args{-on_fail} || '0';

            my @conditions;

            unless ($date_field) {
        $self->warning("Warning: Since or Until arguments need to be applied to a particular date field");
        return $on_fail;
    }
    my %date_tags = ( 'LASTMONTH' => '-30d', 'LASTWEEK' => '-7d', 'YESTERDAY' => '-1d', 'LASTYEAR' => '-365d', 'TODAY' => '' );

    if ($since) {
        if ( $since =~ /^\d\d\d\d-\d\d-\d\d/ ) {
            push @conditions, "$date_field >= '$since'";
        }
        elsif ( grep /$since/i, keys %date_tags ) {
            $since = date_time( -offset => $date_tags{$since} );
            push @conditions, "$date_field >= '$since'";
        }
        else {
            $self->error("Error in Date Format (since '$since' ?)");
            return $on_fail;
        }
    }
    if ($until) {
        if ( $since =~ /^\d\d\d\d-\d\d-\d\d/ ) {
            push @conditions, "$date_field <= '$until'";
        }
        elsif ( grep /$until/i, keys %date_tags ) {
            $since = date_time( -offset => $date_tags{$until} );
            push @conditions, "$date_field >= '$until'";
        }
        else {
            $self->error("Error in Date Format (since '$since' ?)");
            return $on_fail;
        }
    }

    return join ' AND ', @conditions;
}

##
# Simply determine if a given alias is actually an attribute instead of a field
#
# optionally supply list of attribute_links (eg ["Run.run_id"]) which include Table + alias retrieved (which needs to be in the field_list to work)
#
# Return: class of attribute if field alias is an attribute (0 if not an attribute)
#####################
sub is_Attribute {
#####################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'alias,tables' );
    my $alias     = $args{-alias};
    my $tables    = $args{-tables};
    my $condition = $args{-condition};
    my $debug     = $args{-debug};

    ## <construction> For now leave out handling for attribute_link, though this should be added in.

    $alias =~ s / AS (\w+)//i;    ## ignore second level alias if supplied

    my @words = split /\W+/, $alias;
    my $table_list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );

    if ($table_list) { $condition .= " AND Attribute_Class in ($table_list)" }
    my @found;
    foreach my $word (@words) {

        #check if attribute alias is used
        if ( $Attr_Aliases{$word} ) {
            my ( $table, $attr ) = split( /\./, $Attr_Aliases{$word} );
            $word = $attr;
            $condition .= " AND Attribute_Class in ('$table')";
        }
        my ($class) = $self->Table_find( 'Attribute', 'Attribute_Class', "WHERE Attribute_Name like \"$word\" $condition", -debug => $debug );
        if ($class) { push @found, "$class.$word" }
        if ($debug) { Message("$word attribute ?: $class.$word") }
    }
    return join ',', @found;
}

#####################
sub add_Attributes {
#####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'attributes,data' );

    my $attributes  = $args{-attributes};
    my $data_ref    = $args{-data};
    my $fields      = $args{-fields};
    my $debug       = $args{-debug};
    my $retroactive = $args{-retroactive};    # flag for allowing attribute retrieval retroactively back to the original plates if the attribute value for the current plate is empty

    my @attributes;
    my @field_list = @$fields;                ## fields originally requested so we can check if we want to re-alias an attribute

    if ( ref $attributes eq 'ARRAY' ) {
        @attributes = @$attributes;
    }
    else {
        @attributes = ($attributes);
    }
    @attributes = @{ unique_items( \@attributes ) };

    if ($debug) { Message("Add Attributes: @attributes") }

    ## parse out Attribute table and ID field from indicated attribute_link ##
    foreach my $attribute (@attributes) {

        ### check Attributes for each class of Object requested (eg Plate.plate_id, Run.run_id)

        my ( $primary_table, $attribute_name ) = split /\./, $attribute;
        my ($primary_field) = $self->SDB::DBIO::get_field_info( $primary_table, undef, 'Primary' );

        my $FK_to_primary_field = $primary_field;
        $FK_to_primary_field =~ s/^(.+)_(\w+)$/FK_$1__$2/;    ## figure out what reference to primary key is called

        my @ids;
        @ids = @{ $data_ref->{$primary_field} } if defined $data_ref->{$primary_field};
        unless (@ids) { return $data_ref; }

        my @full_id_list   = Cast_List( -list => \@ids, -to => 'array' );
        my @unique_id_list = @{ unique_items( \@full_id_list ) };
        my $id_list        = Cast_List( -list => \@unique_id_list, -to => 'string', -autoquote => 1 );

        #<CONSTRUCTION> shouldn't this be just a single attribute and id since attribute name and class should be unique? Don't need an array
        my @potential_attributes = $self->Table_find( 'Attribute', 'Attribute_ID,Attribute_Name', "WHERE Attribute_Class = '$primary_table' AND Attribute_Name = '$attribute_name'" );

        my @attributes_requested;
        my @att_ids_requested;
        foreach my $pot_attribute (@potential_attributes) {
            ## check to see which of the potential attributes for this class of object have been requested ##
            my ( $att_id, $att_name ) = split ',', $pot_attribute;

            my @more_atts_requested = grep /\b$att_name\b/, @field_list;    ## allow for more complex requests such as 'PCR_cycles as Cycles' where PCR_cycles is an attribute ##

            if (@more_atts_requested) {
                push @attributes_requested, @more_atts_requested;
            }
            push @att_ids_requested, $att_id;                               ## potential duplicates should not be a problem (eg, PCR_cycles, PCR_cycles as Cycles)
        }

        #check for attribute alias
        foreach my $attr_alias ( keys %Attr_Aliases ) {
            my @more_atts_requested = grep /\b$attr_alias\b/, @field_list;
            if (@more_atts_requested) {
                my ( $table, $attr ) = split( /\./, $Attr_Aliases{$attr_alias} );

                #only substituting the current potential attribute
                my ( $att_id, $att_name ) = split ',', $potential_attributes[0];
                if ( $table eq $primary_table && $attr eq $att_name && $att_name ne $attr_alias ) {
                    for my $more_att_requested (@more_atts_requested) {

                        #substitute alias
                        $more_att_requested =~ s/\b$attr_alias\b/$attr/g;

                        #check to see if need to add AS for alias
                        if ( $more_att_requested !~ /^(.+) AS (\w+)/i ) {
                            $more_att_requested = "$more_att_requested AS $attr_alias";
                        }
                        push @attributes_requested, $more_att_requested;
                        push @att_ids_requested,    $att_id;
                    }
                }
            }
        }

        my $att_id_list = join ',', @att_ids_requested;
        if ( !$att_id_list ) {next}    ## no attributes for this class of object ... check next attribute type...

        my %Attributes = $self->Table_retrieve(
            "Attribute,$primary_table,${primary_table}_Attribute",
            [ $primary_field, 'Attribute_Name', 'Attribute_Value', 'Attribute_Type' ],
            "WHERE FK_Attribute__ID=Attribute_ID AND $FK_to_primary_field=$primary_field AND Attribute_ID IN ($att_id_list) AND $primary_field IN ($id_list) GROUP BY $primary_field,Attribute_Name",
            -debug => $debug
        );

        # retroactive
        if ( $primary_table eq 'Plate' ) {
            foreach my $id (@ids) {
                my @got_ids = ();
                @got_ids = @{ $Attributes{$primary_field} } if ( defined $Attributes{$primary_field} );
                if ( grep /^$id$/, @got_ids ) {
                    next;
                }

                # no attribute value found for this id
                if ($retroactive) {    # retroactive back to the parent plates to get the attribute value
                    my $parents = &alDente::Container::get_Parents( -dbc => $self, -id => $id, -format => 'list' );
                    my %parent_Attributes = $self->Table_retrieve(
                        "Attribute,$primary_table,${primary_table}_Attribute",
                        [ $primary_field, 'Attribute_Name', 'Attribute_Value', 'Attribute_Type' ],
                        "WHERE FK_Attribute__ID=Attribute_ID AND $FK_to_primary_field=$primary_field AND Attribute_ID IN ($att_id_list) AND $primary_field IN ($parents) GROUP BY $primary_field,Attribute_Name",
                        -debug => $debug
                    );
                    ## get the attribute value from parent plates. If multiple values exist, give warning
                    my %parent_values = ();
                    my $index         = 0;
                    while ( defined $parent_Attributes{$primary_field}[$index] ) {
                        my $pf         = $parent_Attributes{$primary_field}[$index];
                        my $attr_name  = $parent_Attributes{Attribute_Name}[$index];
                        my $attr_value = $parent_Attributes{Attribute_Value}[$index];
                        if ( defined $parent_values{$attr_name} ) {
                            push @{ $parent_values{$attr_name} }, $attr_value;
                        }
                        else {
                            $parent_values{$attr_name} = [$attr_value];
                        }
                        $index++;
                    }

                    foreach my $attr ( keys %parent_values ) {
                        my $distinct_values = RGmath::distinct_list( $parent_values{$attr} );
                        if ( @$distinct_values > 1 ) {    # multiple values in parent plates, give warning
                            my $msg = '';
                            $index = 0;
                            while ( defined $parent_Attributes{$primary_field}[$index] ) {
                                if ( $parent_Attributes{Attribute_Name}[$index] eq $attr ) {
                                    my $pla   = $parent_Attributes{$primary_field}[$index];
                                    my $value = $parent_Attributes{Attribute_Value}[$index];
                                    $msg .= "pla$pla $attr=$value; ";
                                }
                                $index++;
                            }
                            Message("WARNING: Multiple different values exist for plate $id attribute name $attr in its parent plates! ( $msg ). A concatenation of these values is returned. Please set the right attribute value for plate $id!");
                        }
                        $parent_values{$attr} = join ',', @$distinct_values;
                    }

                    # merge to %Attributes
                    if ($id) {    # make sure $id is not empty
                        foreach my $attr ( keys %parent_values ) {
                            if ( $parent_values{$attr} ) {    # make sure it is not empty
                                if ( defined $Attributes{$primary_field} ) {
                                    push @{ $Attributes{$primary_field} }, $id;
                                }
                                else {
                                    $Attributes{$primary_field} = [$id];
                                }
                                if ( defined $Attributes{Attribute_Name} ) {
                                    push @{ $Attributes{Attribute_Name} }, $attr;
                                }
                                else {
                                    $Attributes{Attribute_Name} = [$attr];
                                }
                                if ( defined $Attributes{Attribute_Value} ) {
                                    push @{ $Attributes{Attribute_Value} }, $parent_values{$attr};
                                }
                                else {
                                    $Attributes{Attribute_Value} = [ $parent_values{$attr} ];
                                }
                                if ( defined $Attributes{Attribute_Type} ) {
                                    push @{ $Attributes{Attribute_Type} }, $parent_values{$attr};
                                }
                                else {
                                    $Attributes{Attribute_Type} = [ $parent_values{$attr} ];
                                }
                            }
                        }    # END foreach my $attr ( keys %parent_values )
                    }    # END if( $id )
                }    # END retroactive
            }
        }

        my $index = 0;
        my %Attr;

        # Populate hash with attributes indexed by primary object id ##
        # eg Attr{1222}{Cycles} = '10' ....

        while ( defined $Attributes{$primary_field}[$index] ) {
            my $id    = $Attributes{$primary_field}[$index];
            my $attr  = $Attributes{Attribute_Name}[$index];
            my $value = $Attributes{Attribute_Value}[$index];
            my $type  = $Attributes{Attribute_Type}[$index];
            if ( $type =~ /^FK/ ) {
                $value = $self->get_FK_info( $type, $value );    ## convert to readable form
            }
            $index++;

            #	    push @attributes, $attr unless ( grep /^$attr$/, @attributes );    ## add to current list of attributes
            $Attr{$id}{$attr} = $value;

            #	    $Attr{$id}{Attribute_Name} = $attr;
        }

        @attributes_requested = @{ unique_items( \@attributes_requested ) };
        ## populate data attributes for this class of object ##
        foreach my $id (@ids) {
            foreach my $attribute_requested (@attributes_requested) {
                my $alias;
                if ( $attribute_requested =~ /^(.+) AS (\w+)/i ) {
                    my $att = $1;
                    $alias = $2;
                    my $data;
                    if ( defined $Attr{$id}{$att} ) {
                        ## normal case ##
                        $data = $Attr{$id}{$att};
                    }
                    else {
                        ## Attribute embedded in field_name somewhere (eg Concat(Att_Name,' ml'))
                        my $name = $attribute_name;                ## $attribute; ## $Attr{$id}{'Attribute_Name'};
                        my $att_value = $Attr{$id}{$name} || '';

                        $att =~ s/$name/\"$att_value\"/g;          ## replace attribute name in field with actual value (quoted)
                        ## use SQL to convert back to simple string (eg SELECT ConCat('52', ' ml'))
                        ($data) = $self->Table_find_array( -fields => [$att], -debug => $debug );
                    }
                    push @{ $data_ref->{$alias} }, $data;
                }
                else {
                    ## explicitly requested attribute ##
                    my $data;
                    if ( defined $Attr{$id}{$attribute_requested} ) {
                        ## normal case ##
                        $data  = $Attr{$id}{$attribute_requested};
                        $alias = $attribute_requested;
                    }
                    else {
                        ## Attribute embedded in field_name somewhere (eg Concat(Att_Name,' ml'))
                        my $name = $attribute_name;                ## $attribute_requested; ## $Attr{$id}{'Attribute_Name'};
                        my $att_value = $Attr{$id}{$name} || '';
                        $alias = $name;

                        if ($att_value) {
                            my $explicit_value = $attribute_requested;
                            $explicit_value =~ s/$name/\"$att_value\"/g;    ## replace attribute name in field with actual value (quoted)
                            ## use SQL to convert back to simple string (eg SELECT ConCat('52', ' ml'))
                            ($data) = $self->Table_find_array( -fields => [$explicit_value], -debug => $debug );
                        }
                    }
                    push @{ $data_ref->{$alias} }, $data;
                }
            }
        }
    }
    return 1;
}

sub add_edit_comments {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'edit_field,field_info,data' );

    my $edit_fields = $args{-edit_fields};
    my $fields      = $args{-fields};
    my $data_ref    = $args{-data};
    my @edit_field  = Cast_List( -list => $edit_fields, -to => 'array' );
    for my $edit_field (@edit_field) {

        #resolve alias
        my $real_field = $fields->{$edit_field};
        my ( $table, $field );
        if ( $real_field =~ /(\w+)\.(\w+)/ ) { $table = $1; $field = $2; }

        #find primary field for the field
        my ($primary_field) = $self->SDB::DBIO::get_field_info( $table, undef, 'Primary' );

        #add edit comment for each primary id
        my @ids = @{ $data_ref->{$primary_field} } if defined $data_ref->{$primary_field};
        unless (@ids) {next}

        my $sql_comment = "GROUP_CONCAT(CASE WHEN Old_Value = New_Value THEN concat(Date(Modified_Date),': ',Comment) ELSE concat(Date(Modified_Date),': (', Old_Value,' -> ',New_Value,') ',Comment) END ORDER BY Modified_Date DESC SEPARATOR '; ')";
        my ($DBField_ID) = $self->Table_find( "DBField", "DBField_ID", "WHERE Field_Table = '$table' and Field_Name = '$field'" );

        my $id_string = join( ",", grep /.+/, @ids );
        my %info = $self->Table_retrieve(
            'Change_History',
            [ 'Record_ID', "$sql_comment AS Edit_Comment", "MAX(Modified_Date) AS Last_Modified" ],
            "WHERE Change_History.Record_ID IN ($id_string) AND FK_DBField__ID = $DBField_ID GROUP BY Record_ID",
            -key => "Record_ID"
        );

        my $comment_alias       = $edit_field . "_edit_comments";
        my $modified_time_alias = $edit_field . "_last_edited";
        for my $id (@ids) {
            my $comment = $info{$id}{Edit_Comment}[0];
            push @{ $data_ref->{$comment_alias} }, $comment;
            my $last_modified_time = $info{$id}{Last_Modified}[0];
            push @{ $data_ref->{$modified_time_alias} }, $last_modified_time;
        }
    }
    return 1;
}

##################################
#
#  Method used to create new attribute types in the database.
#
##################################
sub set_new_attribute_type {
##################################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'class,name,inherited,group' );

    my $class   = $args{-class};
    my $name    = $args{-name};
    my $inherit = $args{-inherit} || 'No';
    my $group   = $args{-group};
    my $format  = $args{'-format'};
    my $quiet   = $args{-quiet};

    my $start = timestamp();
    if ( $name !~ /^\w+$/ ) {
        Message("Invalid attribute name '$name'") unless $quiet;
        return undef;
    }

    if ( $inherit !~ /^(yes|no)$/i ) {
        Message("Invalid inheritence mode '$inherit'") unless $quiet;
        return undef;
    }

    $group = $self->get_FK_ID( 'FK_Grp__ID', $group );
    unless ($group) {
        return undef;
    }

    my @tables = $self->tables();
    unless ( grep( /^${class}_Attribute$/, @tables ) ) {
        Message("Invalid attribute type '$class'") unless $quiet;
        return undef;
    }

    my @fields = qw(Attribute_Name Attribute_Format Attribute_Type FK_Grp__ID Inherited Attribute_Class);
    my @values = ( $name, '', 'Text', $group, $inherit, $class );

    my $output = $self->Table_append_array( 'Attribute', \@fields, \@values, -autoquote => 1 );
    return $self->api_output( -data => $output, -start => $start, -log => 1, -customized_output => 1 );
}

#################
sub query_preparation {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my %Query_parameters;
    return \%Query_parameters;
}

#################################
#
# Handling api output pipeline
#
#
################
sub api_output {
################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'data' );

    my $data_ref = $args{-data};
    my $key      = $args{-key};
    my $order    = $args{-order};
    my $cache    = $args{-cache};
    my $format   = $args{'-format'};
    my $sql      = $args{-sql};
    my $start    = $args{-start};
    my $save     = $args{-save};
    my $input    = $args{-input};
    my $quiet    = $args{-quiet};
    my $debug    = $args{-debug};
    my $customized_output ||= $input->{-customized_output} || $args{-customized_output};    ### Flag to indicate this structure should not be altered
    my $summary = $args{-summary};                                                          ## optional note to be logged (if applicable)
    my $log = defined $args{ -log } ? $args{ -log } : 1;                                    ## allow manual override of log function only
    my $key_hash;
    $key_hash = $input->{'-key_hash'} if %$input;

    $quiet ||= $input->{-quiet} if %$input;

    $format ||= $input->{'-format'} if %$input;

    if ($customized_output) {
        ## correct data values regardless of the output structure ##
    }
    else {
        ### this assumes the output structure is in standard form ###
        ### Getting path from loaded module because someone can call API in their own directory
        my ($mypath) = $INC{'alDente/alDente_API.pm'} =~ /^(.*)alDente\/alDente_API\.pm$/;
        push( @INC, "$mypath/Imported/" );
        require Text::Unidecode;
        foreach my $key ( keys %$data_ref ) {
            my @values = @{ $data_ref->{$key} };
            map { $_ = Text::Unidecode::unidecode($_) } @values;
            $data_ref->{$key} = \@values;
        }
    }

    my $logged_params = pop @{ $self->{logged_params} };
    if ( $log and $logged_params and $self->{log_call} ) {

        my $message = $logged_params;
        $message .= "** Summary **\n";
        if ($summary) { $message .= "$summary\n" }    ## optional message supplied by argument

        $message .= "Login Name: $self->{DB_user} ($self->{LIMS_user}) ($self->{web_service_user})\n";
        $message .= "Host: $self->{host}.$self->{dbase}\n";

        ## estimate data output size ##
        my $data_dump = Dumper($data_ref);
        $data_dump =~ s/\s//g;
        $data_dump =~ s/\'//g;
        $data_dump =~ s/\$VAR\d+=\{//g;
        $data_dump =~ s/=>//g;

        my $data_size = length($data_dump);

        $message .= "Size: ~$data_size bytes ";
        if ( !$customized_output ) {
            my %data;
            %data = %{$data_ref} if $data_ref;
            my @fields_retrieved = keys %data;
            if ( defined $data{ $fields_retrieved[0] } ) {
                $message .= '(' . int( @{ $data{ $fields_retrieved[0] } } ) . " records)\n";
            }
            else {
                $message .= "(No Records)\n";
            }

            ## save this data as an attribute of this object (for easily accessible records via get_record etc)
            if ($save) { $self->_initialize_data( \%data ); }
        }
        else {
            $message .= "\n";
        }

        ## indicate time spent executing query ##
        my $DB_user   = $self->{DB_user};
        my $LIMS_user = $self->{LIMS_user};

        if ($start) {    ## log time of query ##
            my $end  = timestamp();
            my $time = $end - $start;
            $message .= "*** Executed method in $time second(s) ***\n";
        }

        if ( $sql =~ /^1$/ ) { $sql = $self->{last_query} }

        if ($sql) {
            $message .= "Query:\n************\n$sql\n";

            #	$message .= "STDERR: $!\n" if $!
            $message .= "Error: $DBI::errstr\n" if $DBI::errstr;
        }

        Message($message) if ( $debug && !$quiet );

        #if ($self->{dbase} eq $Configs{PRODUCTION_DATABASE}) {
        #    use Digest::MD5  qw(md5_hex);
        #    my $md5_string = md5_hex(objToJson($data_ref));
        #    $message .= "\nMD5_Output:\t$md5_string\n";
        #}

        unless ( $self->{log_file} ) { $self->set_log_file() }

        &log_usage( -log => $self->{log_file}, -message => $message, -include => 'source', -chmod => 666 );
    }

    ## convert  Hash of Array to Array of Hashes (for each key) ##
    print "\n**************** KEY ON $key ******************\n" unless ( $quiet || !$key );
    if ( !$customized_output && ( $key || ( $format =~ /array/i ) ) ) {
        if ( $key =~ /(.*) as (.*)/ ) { $key = $2 }

        ## return values will sometimes truncate table name...
        if ( $key =~ /(.+)\.(.+)/ && !defined $data_ref->{$key} && defined $data_ref->{$2} ) { $key = $2 }

        my $returnval = convert_HofA_to_AofH( $data_ref, $key, $order );

        if ($cache) { &store( $returnval, $cache ); }
        return $returnval;
    }
    elsif ($key_hash) {
        my $returnval = convert_HofA_to_HHofA( $data_ref, $key_hash );

        if ($cache) { &store( $returnval, $cache ); }
        return $returnval;
    }
    else {

        #	Message("store data ($cache)");
        if ($cache) { &store( $data_ref, $cache ); }
        return $data_ref;
    }
}

###########################
sub customize_join_conditions {
###########################
    my %args = &filter_input( \@_, -args => 'joins,left_joins' );
    my $joins      = $args{-joins}      || {};
    my $left_joins = $args{-left_joins} || {};
    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    if ($input_joins) {
        my @keys = keys %$input_joins;
        foreach my $key (@keys) {
            $joins->{$key} = $input_joins->{$key};
        }
    }

    if ($input_left_joins) {
        my @keys = keys %$input_left_joins;
        foreach my $key (@keys) {
            $left_joins->{$key} = $input_left_joins->{$key} unless defined $joins->{$key};
        }
    }

    return;
}

################
#
# Map aliases to the original fields in the database based upon the defined 'Aliases' hash.
#
# eg.  Field{library} = 'Library.Library_Name'
#
# Return: hash (keys = aliases for fields; values = actual fields in database)
################
sub map_to_fields {
################
    my %args       = &filter_input( \@_, -args => 'list,map,tables' );
    my $field_list = $args{-fields};
    my $map        = $args{ -map };
    my $tables     = $args{-tables};
    my $order      = $args{-order};
    my $group;
    $group = Cast_List( -list => $args{-group}, -to => 'string' ) if $args{-group};
    my $KEY;
    $KEY = Cast_List( -list => $args{-key}, -to => 'string' ) if $args{-key};
    my $quiet      = $args{-quiet};
    my $joins      = $args{-joins};
    my $left_joins = $args{-left_joins};
    my $conditions = $args{-conditions} || 1;

    my %Field;    ## hash in which to store field mapping
    my $all_tables = $tables;
    foreach my $key ( keys %$joins ) {
        $all_tables .= ",$key" unless $all_tables =~ /\b$key\b/;
    }
    foreach my $key ( keys %$left_joins ) {
        $all_tables .= ",$key" unless $all_tables =~ /\b$key\b/;
    }

    unless ($all_tables) { $all_tables = keys %Aliases; print "Checking for aliases in all tables\n"; }    ## list of all possible alias keys.. ##
    my @table_list = Cast_List( -list => $all_tables, -to => 'array' );

    ### ADD alias tables such as Read or Run
    my @additional_aliases;
    foreach my $table (@table_list) {

        # just use table name - exclude AS field
        my $real_table = $table;
        $table =~ s/\s*(\w+)\s+AS.*/$1/i;
        if ( $object_aliases{$table} ) {
            my @alias_list = Cast_List( -list => $object_aliases{$table}, -to => 'Array' );
            push( @additional_aliases, @alias_list );
        }
    }
    push( @table_list, @additional_aliases );

    @table_list = &RGTools::RGIO::adjust_list( \@table_list, 'unique' );
    ### Get unique list

    if ($group) {    ## add group field to field list if necessary ...

        $group = replace_Aliases(
            -tables  => \@table_list,
            -aliases => \%Aliases,
            -query   => $group,
            -debug   => $args{-debug},
            -quiet   => $quiet
        );
        $Field{group} = $group;

        unless ( grep /\b$group\b/, @$field_list ) {
            if ( $group =~ /(.*) as (.*)/ ) {
                $Field{group} = $1;    ## remove label from group, but include label in list
                push( @$field_list, $group );
            }
            else {
                push( @$field_list, split ',', $group );
            }
        }
    }

    if ($KEY) {                        ## add key field to field list if necessary ...
        $KEY = replace_Aliases(
            -tables  => \@table_list,
            -aliases => \%Aliases,
            -query   => $KEY,
            -debug   => $args{-debug},
            -quiet   => $quiet
        );

        if ( grep /\b$KEY\b/, @$field_list ) {
            $Field{key} = $KEY;
        }
        else {
            if ( $KEY =~ /(.*) as (.*)/ ) {
                my $label = $2;
                push( @$field_list, $KEY );
                $Field{key} = $label;    ## remove label from key, but include label in list
            }
            else {
                if ( $KEY =~ /^concat/i ) {
                    $KEY = "$KEY AS KEYFIELD";    ## leave if already concatenated ...
                }
                elsif ( $KEY =~ /,/ ) {           ## concatenate a list of fields, separated by a - ...
                    my @fields = split ',', $KEY;
                    $KEY = "concat(";
                    $KEY .= join ",'-',", @fields;
                    $KEY .= ") AS KEYFIELD";
                }
                else {
                    $KEY = "$KEY AS KEYFIELD";
                }
                push( @$field_list, $KEY );
                ## Save this field as a separately labelled Key field ##
                $Field{key} = 'KEYFIELD';
            }
        }
    }

    foreach my $field (@$field_list) {
        my $selected = $field;
        my $alias    = $field;
        my $prompt   = $field;
        if ( $field =~ /(.+) AS (\w+)/i ) {
            $selected = $1;
            $prompt   = $2;
        }

        $selected = replace_Aliases(
            -tables  => \@table_list,
            -aliases => \%Aliases,
            -query   => $selected,
            -debug   => $args{-debug},
            -quiet   => $quiet
        );
        if ( $prompt eq $selected ) {
            $prompt = '`' . $prompt . '`';
        }

        $Field{$prompt} = $selected;

    }
    if ($order) {
        $order = replace_Aliases(
            -tables  => \@table_list,
            -aliases => \%Aliases,
            -query   => $order,
            -debug   => $args{-debug},
            -quiet   => $quiet
        );
        $Field{order} = $order;
    }

    if ($conditions) {
        $conditions = replace_Aliases(
            -tables  => \@table_list,
            -aliases => \%Aliases,
            -query   => $conditions,
            -debug   => $args{-debug},
            -quiet   => $quiet
        );
        $Field{conditions} = $conditions;
    }
    $Field{table_list} = join ',', @table_list;
    return \%Field;
}

#########################
sub extract_Aliases {
#########################
    my %args      = &filter_input( \@_ );
    my $table_ref = $args{-tables};
    my $alias_ref = $args{-aliases};
    my $query     = $args{-query};
    my $debug     = $args{-debug};
    my $quiet     = $args{-quiet};

    my %aliases = $alias_ref ? %$alias_ref : %Aliases;
    my @tables  = $table_ref ? @$table_ref : keys %aliases;

    my @aliases;

    foreach my $table (@tables) {
        foreach my $key ( keys %{ $aliases{$table} } ) {
            my $alias = $aliases{$table}{$key};
            my $quotes;
            ( $query, $quotes ) = _remove_quotes($query);
            if ( $query =~ s/\b$key\b/$alias/g ) {
                Message("Found $key ($alias) in $query") if ( $args{-debug} && !$quiet );
                push @aliases, "$table.$key";
            }
            $query = _insert_quotes( -string => $query, -quotes => $quotes );
        }
    }

    return @aliases;
}

#########################
sub replace_Aliases {
#########################
    my %args      = &filter_input( \@_ );
    my $tables    = $args{-tables};
    my $alias_ref = $args{-aliases};
    my $query     = $args{-query};
    my $debug     = $args{-debug};
    my $quiet     = $args{-quiet};

    my %aliases;
    %aliases = %$alias_ref if $alias_ref;

    foreach my $table (@$tables) {
        foreach my $key ( keys %{ $aliases{$table} } ) {
            my $alias = $aliases{$table}{$key};
            my $quotes;
            ( $query, $quotes ) = _remove_quotes($query);
            if ( $query =~ s/\b$key\b/$alias/g ) {
                Message("Convert $key -> $alias ($query)") if ( $args{-debug} && !$quiet );
            }
            $query = _insert_quotes( -string => $query, -quotes => $quotes );
        }
    }

    return $query;
}

#################
#
# Checks current conditions, fields etc to ensure all required tables are included.
# Tables which can be optionally included are included if necessary
#
# Input:
#
# Return: dynamically added joins (eg 'LEFT JOIN TableA ON TableA.X=TableB.Y LEFT JOIN TableZ ON J=K')
###########################
sub dynamic_joins {
###########################
    my %args       = &filter_input( \@_, -args => 'tables' );
    my $table_list = $args{-table_list};                        ## current tables
    my $fields     = $args{-fields};                            ## current list of fields to extract
    my $condition  = $args{-condition};                         ## current conditions
    my $joins      = $args{ -join };                            ## regular join conditions (has as below)
    my $left_joins = $args{-left_join};                         ## hash (keys = left join tables; values = left join condition)
    my $quiet      = $args{-quiet};
    my $dbc        = $args{-dbc};
    my $debug      = $args{-debug};

    ## get list of tables always included from starting table list & joins
    my @tables = included_tables( -tables => $table_list );

    my @required_table_list = included_tables( -condition => $condition, -fields => $fields );

    my ( undef, $pending_tables ) = RGmath::intersection( \@required_table_list, \@tables );    #

    ## add left joins ##
    my %left_join_hash;
    %left_join_hash = %$left_joins if $left_joins;

    my @add_tables = ();
    my @add_joins;
    my @required_tables = @{ RGmath::distinct_list($pending_tables) };

    my $abort = 0;                                                                              ## counter to bail if we get stuck in loop below due to poor setup logic ##
    while ( int(@required_tables) > int(@add_tables) ) {

        #	my ($intersection, $missing) = RGmath::intersection(\@required_tables, \@add_tables);
        #        foreach my $pending_table (@$missing) {

        foreach my $pending_table (@required_tables) {
            my $alias = $pending_table;
            if ( $pending_table =~ /(.*) AS (.*)/i ) {
                $alias = $2;

                #		if ( grep /^$pending_table$/, @add_tables && !(grep /^$alias$/, @add_tables) ) { push @add_tables, $alias; next; }                                  ## already included
            }
            if ( grep /^($pending_table|$alias)$/, @add_tables ) {next}    ## already included

            if ( !$joins->{$pending_table} && !$left_joins->{$pending_table} ) {

                #check to see there is pending table as "as"
                my $new_pending_table = $pending_table;
                for my $condition_table ( keys %${joins} ) {
                    if ( $condition_table =~ /(\w+) AS $pending_table/i ) { $new_pending_table = $condition_table; next; }
                }
                if ( $new_pending_table eq $pending_table ) {
                    for my $condition_table ( keys %${left_joins} ) {
                        if ( $condition_table =~ /(\w+) AS $pending_table/i ) { $new_pending_table = $condition_table; next; }
                    }
                }
                if ( $new_pending_table ne $pending_table ) { $pending_table = $new_pending_table; }
            }

            my $join_condition = $joins->{$pending_table};
            my $join_type      = 'INNER JOIN';
            if ( !$join_condition && ( my $lj = $left_joins->{$pending_table} ) ) {
                $join_type      = 'LEFT JOIN';
                $join_condition = $lj;
            }

            if ( $join_condition && necessary_tables_included( -condition => $join_condition, -current_tables => [ @tables, @add_tables ], -table => $alias ) ) {
                ## join condition may be satisfied by current included tables ##
                push @add_tables, $alias;
                push @add_joins,  " $join_type $pending_table ON $join_condition";
                if ($debug) { Message("Added $pending_table") }
            }
            else {
                ## found join table requiring additional intermediate table - need to join it first ... ##
                my @intermediate_tables = included_tables( -condition => $join_condition, -exclude => $pending_table );
                foreach my $intermediate (@intermediate_tables) {
                    if ( !grep /^$intermediate$/, @required_tables ) { push @required_tables, $intermediate }
                    if ($debug) { Message("need to include @intermediate_tables first...") }
                }
            }
        }
        if ( $abort++ > 20 ) {
            ##  abort this loop if it appears to go on too long (probably a problem with the QUERY logic in the api ##
            Message("Warning: probable logic problem with query");
            Call_Stack();
            last;
        }
    }

    my $dynamic_join = join ' ', @add_joins;
    return $dynamic_join;
}

#
# Simply checks current tables to see if necessary tables are included to support condition
#
#
# Return: 1 if ok
#####################################
sub necessary_tables_included {
#####################################
    my %args       = filter_input( \@_ );
    my $condition  = $args{-condition};
    my $join_table = $args{-table};
    my @tables     = Cast_List( -list => $args{-current_tables}, -to => 'array' );

    my $included = 1;
    while ( $condition =~ s /(\w+)\.(\w+)/ / ) {
        my $ref_table = $1;
        if ( $ref_table eq $join_table || $join_table =~ /(\w+) AS $ref_table/i ) {
            ## ok ##
        }
        elsif ( ( grep /^$ref_table$/, @tables ) || ( grep /(\w+) AS $ref_table/i, @tables ) ) {
            $included = 1;
        }
        else {
            $included = 0;
        }
    }
    return $included;
}

#
#
# Retrieve list of tables based upon supplied condition / tables / fields
#
#
#
##########################
sub included_tables {
##########################
    my %args      = filter_input( \@_ );
    my $condition = $args{-condition};
    my @tables    = Cast_List( -list => $args{-tables}, -to => 'array' );
    my @fields    = Cast_List( -list => $args{-fields}, -to => 'array' );
    my $exclude   = $args{-exclude};                                        ## exclude table when using condition parameter (enables ignoring of recursive references) ##
    my $debug     = $args{-debug};

    my @included;
    if (@tables) {
        foreach my $table (@tables) {
            if   ( $table =~ /(\w+) AS (\w+)/ ) { push @included, $1 }
            else                                { push @included, $table }
        }
    }

    if ($condition) {
        while ( $condition =~ s/(\w+)\.(\w+)// ) {
            ## extract any conditional references to tables ##
            my $table = $1;
            if ( $table ne $exclude && $exclude !~ /(\w+) AS $table/i ) { push @included, $1 }
        }
    }

    if (@fields) {
        foreach my $field (@fields) {
            while ( $field =~ /(\w+)\.(\w+)/g ) {
                if ( $2 eq 'jpg' ) {next}    #<CONSTRUCTION> Should have a better way to check this is a valid field
                ## extract table names from fully qualified fields ##
                my $table = $1;
                push @included, $table;
            }
        }
    }

    if ($debug) { Message("Returned @included") }
    return @included;
}

######################################
#
# Temporary routine to Map old Clone IDs to new Sample_IDs
#
# <snip>
# Examples:
#
#   my @ids = $API->get_sample_ids(-alias_type=>'MGC',-alias=>['123','456']) };
#
#   my @ids = $API->get_sample_ids(-plate_id=>1234,-well=>'A07');
#
#   my @ids = $API->get_sample_ids(-plate_id=>[1234,1235,1236],-well=>['A07','G12','B09']);
#
#   my %ids = $API->get_sample_ids(-plate_id=>1234);       ## returns hash since wells must be associated ##
#
#
# </snip>

# Return hash (keys = 'Sample_Name','old_id','new_id')
######################
sub get_sample_ids {
#####################

    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'plate_id,well' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $quiet = $args{-quiet};    ## suppress feedback

    my $alias = $args{-alias} || $args{-alias_name};
    my $alias_type = $args{-alias_type};

    my $plates = $args{-plate_id} || $args{-plates};    ## plate or array of plates
    my $wells = $args{-wells};                          ## well or array of wells (according to plasticware)

    my $run_id         = $args{-run_id};
    my $sequenced_well = $args{-sequenced_well};

    my $format;
    $format = $args{'-format'} || 'array';              ## forced to hash if no well list. ($id = $hash{$plate_id}{$well})

    my $application  = $args{-application_type};        ## eg. original, pooled, rearrayed
    my $library      = $args{-library};                 ## at least supply library with this (since large numbers being extracted)
    my $plate_number = $args{-plate_number};
    my $debug        = $args{-debug};

    my %hash;
    my $start = timestamp();

    my @sample_ids;
    if ( $alias && $alias_type ) {
        ## if alias & alias_type supplied, generate sample_ids, and replace arguments ##
        if ( ref($alias) eq 'ARRAY' ) { $alias = join "','", @$alias }
        @sample_ids = $self->Table_find( 'Sample_Alias', "FK_Sample__ID", "WHERE Alias_Type = '$alias_type' AND Alias in ('$alias')", -debug => $debug );
        ## replace alias arguments with sample_id argument ##
        $args{-alias}      = '';
        $args{-alias_type} = '';
        $args{-sample_id}  = \@sample_ids;
    }
    elsif ($plates) {
        ## if plates supplied, ##
        my $tracked_well;     ## figure out the well as tracked on this plate format (if size != format_size)
        my $original_well;    ## figure out the well on the original plate (if size != original_size)

        my @plate_list = Cast_List( -list => $plates, -to => 'array' );
        my @well_list  = Cast_List( -list => $wells,  -to => 'array' );

        if ( $wells && ( scalar(@plate_list) != scalar(@well_list) ) ) {
            print "ERROR: The number of plates (@plate_list) does not match the number of wells (@well_list)";
            return;
        }

        # Get plate size and plate format size
        my $i = 0;
        foreach my $plate_id (@plate_list) {
            my $sample_id = 0;

            ## First figure out the tracked well

            my $info = $self->Table_retrieve(
                'Plate AS CP,Library_Plate AS CLP,Plate_Format AS CPF,Plate AS OP',
                [ 'CP.Plate_Size AS Child_Plate_Size', 'CPF.Well_Capacity_mL AS Child_Plate_Format_Size', 'CP.Parent_Quadrant AS Child_Parent_Quadrant', 'OP.Plate_ID AS Original_Plate_ID', 'OP.Plate_Size AS Original_Plate_Size' ],
                "WHERE CP.Plate_ID=CLP.FK_Plate__ID AND CPF.Plate_Format_ID=CP.FK_Plate_Format__ID AND CP.FKOriginal_Plate__ID=OP.Plate_ID AND CP.Plate_ID = $plate_id",
                -format => 'RH'
            );

            my ( $child_plate_size, $child_plate_format_size, $child_parent_quadrant, $original_plate_id, $original_plate_size )
                = ( $info->{Child_Plate_Size}, $info->{Child_Plate_Format_Size}, $info->{Child_Parent_Quadrant}, $info->{Original_Plate_ID}, $info->{Original_Plate_Size} );

            ### generate list of wells if array of wells not included ##
            my @wells;

            if ( int(@well_list) ) { @wells = ( $well_list[$i] ); }
            elsif ( $child_plate_size =~ /96/ ) {
                @wells = $self->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Quadrant = 'a' ORDER BY Plate_96", -debug => $debug );
                $format = 'hash';    ## force to hash if no wells provided ##
            }
            elsif ( $child_plate_size =~ /384/ ) {
                my @unformatted_wells = $self->Table_find( 'Well_Lookup', 'Plate_384', "WHERE 1 ORDER BY Plate_384", 'Distinct', -debug => $debug );
                @wells = &alDente::Well::Format_Wells( -dbc => $self, -wells => \@unformatted_wells );
                $format = 'hash';    ## force to hash if no wells provided ##
            }

            foreach my $well (@wells) {    ## foreach well (if well list NOT supplied) ##
                if ( @well_list && $child_plate_size =~ /96/ && $child_plate_format_size =~ /384/ ) {
                    ($tracked_well) = alDente::Well::Convert_Wells( -dbc => $self, -wells => $well, -target_size => '384' );
                    $tracked_well =~ s/([a-zA-Z]\d{2})[abcd]/$1/;
                }
                else { $tracked_well = $well }

                ## Now figure out the original well
                if ( $child_plate_size =~ /96/ && $original_plate_size =~ /384/ ) {
                    if ($child_parent_quadrant) {
                        ($original_well) = alDente::Well::Convert_Wells( -dbc => $self, -wells => "$tracked_well$child_parent_quadrant" );
                    }
                    else {
                        $self->error("ERROR: Parent quadrant NOT found for plate $plate_id");
                        $sample_ids[$i]                                         = $sample_id;
                        $hash{$plate_id}{"$tracked_well$child_parent_quadrant"} = $sample_id;
                        $hash{$plate_id}{$well}                                 = $sample_id;
                        $i++;
                        next;
                    }
                }
                else {
                    $original_well = $tracked_well;
                }

                if ( $original_plate_id && $original_well ) {
                    ($sample_id) = $self->Table_find( 'Plate_Sample', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$original_plate_id AND Well='$original_well'", -debug => $debug );
                }
                $sample_ids[$i] = $sample_id;

                #		$hash{$plate_id}{$well} = $sample_id;
                $hash{$plate_id}{"$tracked_well$child_parent_quadrant"} = $sample_id;

                $i++;
            }
        }
    }
    elsif ( $run_id && $sequenced_well ) {
        ### if run, well supplied ###
        $self->error("Run and Sequenced_well input not yet set up...- ask LIMS admin to get on it..");
    }
    elsif ($application) {
        unless ($library) { $self->error("You need to specify a library to extract by application"); return; }
        my $extra_condition = " AND FK_Library__Name='$library'";
        if ($plate_number) { $extra_condition .= " AND Library_Plate_Number in ($plate_number)" }

        if ( $application =~ /rearray/ ) {
            @sample_ids = $self->Table_find( 'Sample,Clone_Sample,ReArray', "Sample_ID", "WHERE Clone_Sample.FK_Sample__ID = Sample_ID AND ReArray.FK_Sample__ID=Sample_ID AND FK_Library__Name='$library'", -debug => $debug );
        }
        else {
            @sample_ids = $self->Table_find( 'Sample,Clone_Sample', "Sample_ID", "WHERE Clone_Sample.FK_Sample__ID = Sample_ID AND FK_Library__Name='$library'", -debug => $debug );
        }
    }

    if ( $format =~ /hash/i ) {
        return $self->api_output( -data => \%hash, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
    }
    else {
        return $self->api_output( -data => \@sample_ids, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
    }
}

##############################################
##############################################
###### Plate specific data accessors #########
##############################################
##############################################

#############################################
# Get simple plate count for library / study / project ...
#
# <snip>
# Examples:
#   my $count = $API->get_plate_count();
#
#   my $count = $API->get_plate_count(-library=>'MGC01',-condition=>');
#
#   my $data = $API->get_plate_count(-key=>'plate_format');   ## get count for each format type...
#
# </snip>
#
# Count number of plates in library/project/
#
# (see _generate_query method for more details on input parameter options)
#
# Return: Integer = number of plates found OR hash if grouping requested. (%returnval->{fields}[1..$records])
#######################
sub get_plate_count {
#######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id         = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id       = $args{-project_id};          ### specify project_id
    my $library          = $args{-library};             ### specify library
    ## plate specification options
    my $plate_id          = $args{-plate_id};                   ### specify plate_id
    my $plate_number      = $args{-plate_number};               ### specify plate number
    my $plate_type        = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class       = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};          ### specify original plate id
    my $applied_plate_id  = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant          = $args{-quadrant};                   ### specify quadrant from original plate
    my $sample_id         = $args{-sample_id};                  ### specify sample_id
    my $library_type      = $args{-library_type};

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                                  ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field};

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $plates;
    $plates = Cast_List( -list => $plate_id, -to => 'string' ) if $plate_id;
    my $plate_numbers;
    $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' ) if $plate_number;
    my $samples;
    $samples = Cast_List( -list => $sample_id, -to => 'string' ) if $sample_id;
    my $library_types;
    $library_types = Cast_List( -list => $library_type, -to => 'string', -autoquote => 1 ) if $library_type;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;
    push( @extra_conditions, "Library_Name IN ($libraries)" )                if $libraries;
    push( @extra_conditions, "Plate_ID IN ($plates)" )                       if $plates;
    push( @extra_conditions, "Plate_Number IN ($plate_numbers)" )            if $plate_numbers;
    push( @extra_conditions, "Plate_Sample.FK_Sample__ID IN ($samples)" )    if $samples;
    push( @extra_conditions, "Library_Type IN ($library_types)" )            if $library_types;
    push( @extra_conditions, "Plate_Type = '$plate_type'" )                  if $plate_type;
    push( @extra_conditions, "Library_Plate.Plate_Class = '$plate_class'" )  if $plate_class;
    push( @extra_conditions, "Library_Plate.Parent_Quadrant = '$quadrant'" ) if $quadrant;

    ## Initial Framework for query ##
    my $tables           = 'Plate,Library';                                ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE Plate.FK_Library__Name=Library_Name';    ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';                                             ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {
        'Library_Plate' => "Library_Plate.FK_Plate__ID=Plate_ID",
        'Tube'          => "Tube.FK_Plate__ID=Plate_ID",
        'Plate_Format'  => 'Plate.FK_Plate_Format__ID=Plate_Format_ID',
        'Plate_Sample'  => 'Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID',
    };                                                                     ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {

    };                                                                     ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = ('Count(Distinct Plate_ID) as plates');               ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -limit                => $limit,
        -quiet                => $quiet
    );

}

################################33
# Return lineage information (or just plate id / format if a generation is specified).
#
# <snip>
#  Example 1 :   (to retrieve 2nd generation plate(s) given final plate_id).
#
#     my ($plate_id,$format) = @{$API->get_plate_lineage(-plate_id=>$plate,-generation=>2)};
#
#  Example 2 :   (to retrieve plate 1 generation behind - (relative generation = '-1')).
#
#     my ($plate_id,$format) = @{$API->get_plate_lineage(-plate_id=>$plate,-generation=>'-1')};
#
#  Example 3 :   (to retrieve all plates in lineage of specified plate).
#
#     my ($plate_id,$format) = @{$API->get_plate_lineage(-plate_id=>$plate)};
#
# Return : hash of info (if generation NOT specified) or array reference with plate_id(s), format(s) for specified generation.
############################
sub get_plate_lineage {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'plate_id,generation' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $plate_id   = $args{-plate_id};
    my $generation = $args{-generation};
    my $well       = $args{-well};
    my $no_rearray = $args{-no_rearray};

    my %output_data;
    my $start = timestamp();

    my %lineage = &alDente::Container::get_Parents( -dbc => $self, -id => $plate_id, -format => 'hash', -well => $well, -no_rearray => $no_rearray );
    my %child_lineage = &alDente::Container::get_Children( -dbc => $self, -id => $plate_id, -format => 'hash', -include_self => 1 );

    if ($generation) {    ## retrieve a particular generation (where 1st generation is original) ##
        my $generations_above = $lineage{parent_generations} + 1;    ## include current plate as last generation
        if ( $generation =~ /^\-[1-9]/ ) {                           ## relative generation supplied ('-' => parents)
            my $id      = $lineage{generation}{$generation};
            my $formats = $lineage{formats}{$generation};
            my $created = $lineage{created}{$generation};
            %output_data = ( plate_id => $id, format => $formats, created => $created );
        }
        elsif ( $generation =~ /^\+[1-9]/ ) {                        ## relative generation supplied ('+' => children)
            my $id      = $child_lineage{generation}{$generation};
            my $formats = $child_lineage{formats}{$generation};
            my $created = $child_lineage{created}{$generation};
            %output_data = ( plate_id => $id, format => $formats, created => $created );
        }
        elsif ( $generation =~ /^[\+\-]0/ ) {                        ## relative generation supplied (pointing to self)
            my $id      = $child_lineage{generation}{0};
            my $formats = $child_lineage{formats}{0};
            my $created = $child_lineage{created}{0};
            %output_data = ( plate_id => $id, format => $formats, created => $created );
        }
        else {                                                       ## assume generation is a single integer ##
            $generation += 0;
            if ( $generation > $generations_above ) {
                my $generations_below = $generation - $generations_above;
                my $child_generations = $child_lineage{child_generations};
                if ( $generations_below > $child_generations ) {
                    $self->warning("Sorry only $generations_above + $generations_below generations");
                }
                else {
                    my $id      = $child_lineage{generation}{"+$generations_below"};
                    my $formats = $child_lineage{formats}{"+$generations_below"};
                    my $created = $child_lineage{created}{"+$generations_below"};
                    %output_data = ( plate_id => $id, format => $formats, created => $created );
                }
            }
            elsif ( $generation =~ /^$generations_above$/ ) {
                my $format_id = join ',', $self->Table_find( 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID in ($plate_id)" );
                my $format = get_FK_info( $self, 'FK_Plate_Format__ID', $format_id );
                my ($created) = $self->Table_find( 'Plate', 'Min(Plate_Created)', "WHERE Plate_ID in ($plate_id)" );
                %output_data = ( plate_id => $plate_id, format => $format, created => $created );
            }
            else {
                my $gen     = $generation - $generations_above;
                my $id      = $lineage{generation}{$gen};
                my $format  = $lineage{formats}{$gen};
                my $created = $lineage{created}{$gen};
                %output_data = ( plate_id => $id, format => $format, created => $created );
            }
        }
    }
    else {    ## No generation specification supplied ##
        my %Ancestry;
        my $format_id = join ',', $self->Table_find( 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID in ($plate_id)" );
        my $format = get_FK_info( $self, 'FK_Plate_Format__ID', $format_id );
        my ($created) = $self->Table_find( 'Plate', 'Min(Plate_Created)', "WHERE Plate_ID in ($plate_id)" );
        $Ancestry{generation}->{0} = $plate_id;
        $Ancestry{format}->{0}     = $format;
        $Ancestry{created}->{0}    = $created;

        $Ancestry{parent_list}        = $lineage{list};
        $Ancestry{child_list}         = $child_lineage{list};
        $Ancestry{parent_generations} = $lineage{parent_generations};
        $Ancestry{child_generations}  = $child_lineage{child_generations};

        foreach my $key ( keys %{ $lineage{generation} } ) {
            $Ancestry{generation}{$key} = $lineage{generation}{$key};
            $Ancestry{format}{$key}     = $lineage{formats}{$key};
            $Ancestry{created}{$key}    = $lineage{created}{$key};
        }

        foreach my $key ( keys %{ $child_lineage{generation} } ) {
            $Ancestry{generation}{$key} = $child_lineage{generation}{$key};
            $Ancestry{format}{$key}     = $child_lineage{formats}{$key};
            $Ancestry{created}{$key}    = $child_lineage{created}{$key};
        }

        # for sample name, original well, and original plate
        $Ancestry{sample_id} = $lineage{sample_id};
        if ( $Ancestry{sample_id} ) {
            my ($sample_name) = $self->Table_find( "Sample", "Sample_Name", "WHERE Sample_ID=$Ancestry{sample_id}" );
            $Ancestry{sample_name}    = $sample_name;
            $Ancestry{original_plate} = $lineage{original};
            $Ancestry{original_well}  = $lineage{well};
        }
        %output_data = %Ancestry;
    }
    return $self->api_output( -data => \%output_data, -start => $start, -log => 1, -customized_output => 1 );
}
#######################################################################
# specifically to retrieve information on where samples may be located.
#
# <snip>
# Example:
#
# my $plate_data = $API->get_Plate_list(-sample_id=>\@sample_ids);
#
# OR  specify a list of samples by indicating an alias_type and an alias (or array of aliases)
#
# my $plate_data = $API->get_Plate_list(-alias_type=>'AVF',-alias=>['sample1','sample2','sample3');
#
#  ## the following is also possible though slow since it must track each sample individually through generations ##
# my $plate_data = $API->get_Plate_list(-library=>'CC001',-plate_number=>1);
#
# Differences between LIMS 2.5 and LIMS 2.6:
# The hash key 'actual_size' has been replaced with hash keys 'well_capacity_ml', 'capacity_units' and 'plate_format_wells'
# </snip>
#
# Return: hash of plate_id,format,size,well for each plate on which this sample resides.
#################
sub get_Plate_list {
#################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'sample_id,format', -mandatory => 'sample_id|alias_name|alias_type|library|project_id|study|since|date_field' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $sample_ids = $args{-sample_id};    ## list of sample_ids
    my $alias_name = $args{-alias_name};
    my $alias_type = $args{-alias_type};
    my $format_spec;
    $format_spec = $args{'-format'} || $args{-plate_format};    ## indicate format type (checks if this string is IN format description)
    my $library      = $args{-library};
    my $project_id   = $args{-project_id};
    my $plate_number = $args{-plate_number};
    my $study        = $args{ -study };
    my $quiet        = $args{-quiet};                           ## suppress unnecessary feedback
    my $since        = $args{-since};                           ## only retrieve plates generated SINCE this date
    my $until        = $args{ -until };                         ## only retrieve plates generated UNTIL this date
            my $date_field      = $args{-date_field};
            my $clone_condition = $args{-clone_condition};           ## condition that applies to specific clones
            my $plate_condition = $args{-plate_condition} || '1';    ## conditions that apply to plates extracted..
            my $originals_only  = $args{-originals_only} || '0';     ## only retrieve info for the original plates..
            my $debug           = $args{-debug};

            my $start = timestamp();
    foreach my $table ( 'Plate', 'Library', 'Project' ) {
        foreach my $key ( keys %{ $Aliases{$table} } ) {
            if ( $plate_condition =~ /\b$key\b/ ) {
                my $replace = $Aliases{$table}{$key};
                if ( $replace =~ /(.*) AS (.*)/ ) {
                    my $replace = $1;
                }
                $plate_condition =~ s/\b$key\b/$replace/g;
            }                                                        ## include Alias
        }
    }
    my $datespec;
    if ( $since || $until ) {
        $datespec = $self->parse_date_condition( -date_field => "$date_field", -since => $since, -until => $until, -on_fail => 0 );
        if ( defined $datespec ) { $datespec = " AND $datespec" }
    }

    unless ( $args{-fields} ) {
        $args{-fields} = [ 'plate_created', 'sample_id', 'applied_plate_id', 'applied_well', 'original_plate_id', 'original_well', 'original_quadrant', 'sample_name' ];
    }
    ## First retrieve details of sample ##
    my $originals = $self->get_sample_data(
        -sample_id    => $sample_ids,
        -alias_type   => $alias_type,
        -alias_name   => $alias_name,
        -library      => $library,
        -project      => $project_id,
        -study        => $study,
        -plate_number => $plate_number,
        -fields       => $args{-fields},
        -quiet        => $quiet,
        -condition    => $clone_condition
    );

    ## only return information on originals if requested (faster) ##
    if ($originals_only) {
        return $self->api_output( -data => $originals, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
    }

    my @original_ids;
    @original_ids = @{ $originals->{original_plate_id} } if $originals->{original_plate_id};
    my $number = int(@original_ids);
    print "Following lineage for each plate back to $number defined clones...\n" if ( $args{-debug} && !$quiet );
    unless ( $quiet || ( $number < 1000 ) ) {
        print "(This may be very slow when looking at a large number of samples since we need to follow the ancestry back through all generations of plates for each sample individually - progress towards completion is indicated dynamically below)\n";
    }

    my @original_wells     = @{ $originals->{original_well} };
    my @applied_ids        = @{ $originals->{applied_plate_id} };
    my @applied_wells      = @{ $originals->{applied_well} };
    my @original_quadrants = @{ $originals->{original_quadrant} };
    my @sample_ids         = @{ $originals->{sample_id} };
    my @sample_names       = @{ $originals->{sample_name} };
    my @creation_dates     = @{ $originals->{plate_created} };
    my @alias_names;
    @alias_names = @{ $originals->{alias_name} } if ($alias_type);

    my %Found;
    foreach my $index ( 0 .. $#applied_ids ) {
        my $applied_plate_id  = $applied_ids[$index];
        my $applied_well      = $applied_wells[$index];
        my $original_id       = $original_ids[$index];
        my $original_well     = $original_wells[$index];
        my $original_quadrant = $original_quadrants[$index];
        my $sample_id         = $sample_ids[$index];
        my $sample_name       = $sample_names[$index];
        my $created           = $creation_dates[$index];
        my $alias_name        = $alias_names[$index];

        #print progress_tracker($index,$number) if ($args{-debug} && !$quiet);

        my $lineage = $self->get_plate_lineage( -dbc => $self, -plate_id => $applied_plate_id, -well => $applied_well, -no_rearray => 1 );    ## Don't follow through rearrays

        my $children = join ',', @{ $lineage->{child_list} };
        my $parents .= join ',', @{ $lineage->{parent_list} };

        my $all_ids = $children;
        $all_ids .= ",$parents" if ($parents);

        my @details = $self->Table_find(
            'Plate,Library_Plate,Plate_Format,Rack',
            'FKOriginal_Plate__ID,Plate_ID,Plate_Size,Library_Plate.Plate_Position,Parent_Quadrant,Well_Capacity_mL,Plate_Format_Type,Rack_Alias,Library_Plate.Plate_Class,FK_Rack__ID,Capacity_Units,Wells',
            "WHERE FK_Plate_Format__ID=Plate_Format_ID AND FK_Plate__ID=Plate_ID AND FK_Rack__ID=Rack_ID  AND Plate_ID in ($all_ids) $datespec AND $plate_condition"
        );

        foreach my $detail (@details) {
            unless ($detail) { next; }
            my ( $original_id, $plate_id, $plate_size, $position, $quadrant, $format_size, $format, $location, $class, $rack, $capacity_units, $plate_fromat_wells ) = split ',', $detail;
            if ($format_spec) {
                unless ( $format =~ /$format_spec/ ) { next; }
            }    ## skip if this does NOT match specified format
                 #print "$format => $format_spec ($plate_id)\n";
            my $tracked_well;
            my $original_size = $plate_size;
            if ($quadrant) {    ## if this sample was split from 384 well format
                ($tracked_well) = $self->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Left(Plate_384,1) = Left('$applied_well',1) AND Substring(Plate_384,2)+0 = Substring('$applied_well',2)+0 AND Quadrant = '$quadrant'" );
                $original_size = '384-well';
            }
            else {
                $tracked_well = $applied_well;
            }
            my $actual_well = $tracked_well;
            if ( $format_size > $plate_size ) {    ## if actual plasticware is a different size, figure out actual well
                ($actual_well) = $self->Table_find( 'Well_Lookup', 'Plate_384', "WHERE Plate_96 = '$tracked_well' AND Quadrant = '$position'" );
                ($actual_well) = &alDente::Well::Format_Wells( -dbc => $self, -wells => $actual_well );
            }
            if ($actual_well) {
                my $found;
                if   ( $Found{$sample_id} ) { $found = int( keys %{ $Found{$sample_id} } ) + 1; }
                else                        { $found = 1; }
                $Found{$sample_id}{$found}{applied_well}       = $applied_well;
                $Found{$sample_id}{$found}{applied_plate_id}   = $applied_plate_id;
                $Found{$sample_id}{$found}{original_well}      = $original_well;
                $Found{$sample_id}{$found}{tracked_well}       = $tracked_well;         ## (eg. if 96-well plate is tracked on 384-well plasticware
                $Found{$sample_id}{$found}{actual_well}        = $actual_well;          ## the well (assuming user knows nothing about 'tracking' status
                $Found{$sample_id}{$found}{original_plate_id}  = $original_id;
                $Found{$sample_id}{$found}{plate_id}           = $plate_id;
                $Found{$sample_id}{$found}{plate_position}     = $position;             ## position of tracked 96-well plate on 384 (if applicable)
                $Found{$sample_id}{$found}{original_quadrant}  = $quadrant;             ## position of sample in original 384-well plate (if applicable)
                $Found{$sample_id}{$found}{tracked_size}       = $plate_size;           ## size of plate that is tracked
                                                                                        #$Found{$sample_id}{$found}{actual_size}       = $format_size;        ## size of plasticware on which plate exists
                $Found{$sample_id}{$found}{well_capacity_ml}   = $format_size;
                $Found{$sample_id}{$found}{capacity_units}     = $capacity_units;
                $Found{$sample_id}{$found}{plate_format_wells} = $plate_fromat_wells;
                $Found{$sample_id}{$found}{original_size}      = $original_size;        ## size of plasticware on which plate exists
                $Found{$sample_id}{$found}{format}             = $format;
                $Found{$sample_id}{$found}{created}            = $created;
                $Found{$sample_id}{$found}{location}           = $location;
                $Found{$sample_id}{$found}{class}              = $class;
                $Found{$sample_id}{$found}{rack_id}            = $rack;
                $Found{$sample_id}{$found}{sample_name}        = $sample_name;
                if ($alias_type) { $Found{$sample_id}{$found}{alias_name} = $alias_name; }
            }
        }
    }

    return $self->api_output( -data => \%Found, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
}

# Get prep history for a given plate
# <snip>
# Example:
#     my $data = get_Plate_history(-plate_id=>12345,-history=>1);
# </snip>
#
###################
sub get_Plate_history {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args     = &filter_input( \@_, -args => 'plate_id' );
    my $plate_id = $args{-plate_id};
    my $step     = $args{-step};                                ## allow searching for specific step(s)[ wildcard OR list valid]
    my $history  = $args{-history};                             ## follow plate history to include parent plates
    my $debug    = $args{-debug};

    my $start = timestamp();

    my %History = alDente::Container->get_Preps( -dbc => $self, -plate_id => $plate_id, -step => $step, -history => $history );

    return $self->api_output( -data => \%History, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
}

################################################
#
# Retrieve list of libraries given project / study etc.
#
# <snip>
# Example:
#   my @libraries = @{ $API->$self->get_libraries(-study=>2) }
# </snip>
#
# Get a list of libraries by different criteria
#
# Return: A list of libraries in array ref
######################
sub get_libraries {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'project_id', -mandatory => 'library|project_id|study_id' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $library    = $args{-library};
    my $project_id = $args{-project_id};                     ### project id
    my $study_id   = $args{-study_id} || $args{ -study };    ### study id
    my $study_name = $args{-study_name};                     ### study name
    my $quiet      = $args{-quiet};
    my $debug      = $args{-debug};

    my $start = timestamp();

    if ( $library || $project_id || $study_id || $study_name ) {
        my %data = %{ $self->get_library_data( -group => '', -library => $library, -study_id => $study_id, -project_id => $project_id, -fields => ['library'], -quiet => $quiet ) };
        my @libs = ();
        if ( defined $data{library} ) {
            @libs = @{ $data{library} };
        }
        else {
            $self->warning("Warning: No Libraries found matching conditions (Project $project_id; $library)");
            @libs = ('');    ## set to blank to avoid SQL Error ##
        }
        return $self->api_output( -data => \@libs, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
    }
    else {return}
}

######################################
#
# Retrieves library changes (parameters are same as get_library_data() parameters
#
# <snip>
#       $API->get_library_changes(-study=>7,-quiet=>1);
# </snip>
#
#########################
sub get_library_changes {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

    ### Get the list of library names
    my $library_data = $self->get_library_data(%args);
    my $library_list = $library_data->{library};

    ### Retrieve the changes for those librarys
    return $self->get_changes( -object => 'Library', -record_ids => $library_list );

}

######################################
#
# Retrieves plate changes
#
# Inputs:  Input parameters are same as get_plate_data() parameters
# Outputs: Returns a hash of arrays of changes
#
# <snip>
#       $API->get_plate_changes(-plate_id=>102034,-quiet=>1);
# </snip>
#
#########################
sub get_plate_changes {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

    ### Get the list of Plate IDs
    my $plate_data = $self->get_plate_data(%args);
    my $plate_ids  = $plate_data->{plate_id};

    ### Retrieve the changes for those Plates
    return $self->get_changes( -object => 'Plate', -record_ids => $plate_ids );
}

######################################
#
# Retrieves sample changes
#
# Inputs:  Input parameters are same as get_sample_data() parameters
# Outputs: Returns a hash of arrays of changes
#
# <snip>
#       $API->get_sample_changes(-sample_id=>102034,-quiet=>1);
# </snip>
#
#########################
sub get_sample_changes {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

    ### Get the list of Sample IDs
    my $sample_data = $self->get_sample_data(%args);
    my $sample_ids  = $sample_data->{sample_id};

    ### Retrieve the changes for those Samples
    return $self->get_changes( -object => 'Sample', -record_ids => $sample_ids );
}

######################################
#
# Generic method to retrieve changes of an object in the database given its ID.
# You can optionally pass in the specific fields required. By default it will retrieve all
#
#
# Inputs:  Object Name
#          Object IDs
#          [Specified Fields]
# Outputs: Returns a hash of arrays of changes
#
#
# <snip>
#       $API->get_changes(-object=>'Plate', -fields=>['plate_number'], -record_ids=>102034);
# </snip>
#
##########################
sub get_changes {
##########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'object,record_ids,fields', -mandatory => 'object,record_ids', -quiet => 1 );
    if ( $args{ERRORS} ) {
        return 0;
    }

    my $start = timestamp();

    my $record_ids       = $args{-record_ids};    ### Record IDs
    my $object           = $args{-object};
    my $requested_fields = $args{-fields};
    my $debug            = $args{-debug};
    $record_ids = join "','", Cast_List( -list => $record_ids, -to => 'Array' );

    my @requested_fields = Cast_List( -list => $requested_fields, -to => 'Array' );
    my @tables;                                   ### Set of tables that could potentially be used
    my %fields;                                   ### Mapping of fully identified filed names to their aliases

    ### Get all the fields listed in the aliases
    foreach ( keys %{ $Aliases{$object} } ) {
        my $this_field = $Aliases{$object}{$_};
        my ( $table, $field );

        ### Extract the table names and field names
        if ( $this_field =~ /(\w+)\.(\w+)/ ) {
            my $table = $1;
            my $field = $2;

            ### If a set of specific fields have been requested, ignore the others
            if ($requested_fields) {
                next unless ( grep( /$field/i, @requested_fields ) );
            }
            $fields{$this_field} = $_;
            push( @tables, $table );
        }
    }
    @tables = @{ &unique_items( \@tables ) };

    ### If a set of specific fields have been requested, check to see if they all exist
    if ($requested_fields) {
        unless ( scalar( keys %fields ) == scalar(@requested_fields) ) {
            $self->error("Error: No such field(s) were found in the map.");
            Message( "Requested Fields: " . join ',', @requested_fields ) unless $self->{quiet};
            return 0;
        }
    }

    ### Retrieve the DBField_ID(s) of the requried fields
    my $full_fields = join "','", keys %fields;
    my %DBFields = $self->Table_retrieve( 'DBField,DBTable', [ 'DBField_ID', "CONCAT(DBTable_Name,'.',Field_Name) AS Name" ], "WHERE DBTable_ID=FK_DBTable__ID and CONCAT(DBTable_Name,'.',Field_Name) IN ('$full_fields')" );

    my $count = 0;
    ### Record the mapping of DBField_ID(s) to their fully identified field names
    while ( $DBFields{DBField_ID}->[$count] ) {
        $fields{ $DBFields{DBField_ID}->[$count] } = $DBFields{Name}->[$count];
        $count++;
    }

    my $dbfield_ids = join ',', @{ $DBFields{DBField_ID} };

    ### Finally retrieve all the changes for these set of DBFields
    my %Changes = $self->Table_retrieve(
        'Change_History,Employee',
        [ 'FK_DBField__ID', 'Record_ID', 'Old_Value', 'New_Value', 'FK_Employee__ID', 'Employee_Name', 'Modified_Date', 'Comment' ],
        "WHERE Employee_ID=FK_Employee__ID and FK_DBField__ID in ($dbfield_ids) and Record_ID IN('$record_ids') Order by Modified_Date asc"
    );
    $count = 0;

    ### Replace the DBField_ID(s) with the field names in the %Aliases hash
    while ( $Changes{FK_DBField__ID}->[$count] ) {
        push( @{ $Changes{Field_Alias} }, $fields{ $fields{ $Changes{FK_DBField__ID}->[$count] } } );
        $count++;
    }

    ### Remove the DBField_ID(s) from the resulting hash (hide them from end user);
    delete $Changes{FK_DBField__ID};

    #    print Dumper \%Changes;
    return $self->api_output( -data => \%Changes, -start => $start, -log => 1, -debug => $debug );
}

#############################
#
#  <snip> $self->log_parameters(\@_); </snip>
#
####################
sub log_parameters {
####################
    my $self  = shift;
    my %input = @_;

    my ( $package, $filename, $line ) = caller(1);

    my $message = '';
    if ( $package =~ /_API$/ ) {
        if ( !$self->{logged_params} or ( int( @{ $self->{logged_params} } ) == 0 ) ) {
            Call_Stack();
            print Dumper( $self->{logged_params} );
            Message("Warning: Internal API call with no logged parameters! Please fix ASAP");
        }
    }
    else {
        if (%input) {
            delete $input{-dbc};
            delete $input{-connection};
            delete $input{-dbh};

            $self->{logged_params} = [];
            $message .= "Start time: " . date_time() . "\n";
            $message .= "Arguments:\n************\n";
            $message .= Dumper( \%input );
            
            if (JSON->VERSION =~/^1/) { $message .= 'json: ' . JSON::objToJson(\%input) }
            else {  $message .= 'json: ' . JSON::to_json(\%input) }
        }
    }

    push @{ $self->{logged_params} }, $message if $message;

    return 1;
}

####################
#
# This initializes the $self->{data} hash which allows for easy access to retrieved data records
# (enabling $self->get_record etc)
#
# Return:
####################
sub _initialize_data {
####################
    my $self     = shift;
    my $data_ref = shift;

    my %data = %{$data_ref};
    $self->{data} = \%data;
    my @keys = keys %data;
    $self->{records} = int( @{ $data{ $keys[0] } } ) if defined $data{ $keys[0] };
    $self->{more_records} = $self->{records} - 1;
    return;
}

##############################
# Log usage to specified file
#
# Return : (nothing)

###########################
# Require users to only use (and know) their LIMS login password
#
# Return: 1 on validation success
##################
sub _password_check {
##################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'LIMS_password,LIMS_user,DB_user,required' );
    my $password = $args{-LIMS_password};                                                      ## password (LIMS)
    my $user     = $args{-LIMS_user} || '';                                                    ## Name (or email) of user
    my $DB_user  = $args{-DB_user};                                                            ## password (LIMS)
    my $required = $args{-required} || 0;

    ## ensure proper id / password has been entered ##
    my $DB_password = '';
    my $dbase       = $self->{dbase};
    my $host        = $self->{host};
    ## <CUSTOM> ## Supply custom login passwords (put in non-readable file (?)..)
    #
    # Note: administrative privileges are used for WRITING to the database (must connect to production database)
    # (non-administrators connect (with READ-ONLY permission) to the replication database
    #

    ## change temporary viewer password to something else... ##
    ## Temporarily connect to ensure user / login / group specifications are valid ##

    my $Temp_Connection = SDB::DBIO->new( -dbase => $dbase, -host => $host, -user => 'viewer', -password => 'viewer', -connect => 1, -sessionless => 1 );

    my $fail;
    my $pass = 0;
    if ( defined $password ) {
        unless ($user) { $self->error("No User name supplied"); return; }
        my $password_condition = " Password=Password('$password')";

        my $user_condition = "Password=Password('$password') AND (Email_Address = '$user' OR Email_Address like '$user\@' OR Employee_Name='$user')";

        ## check to make sure group is valid ##
        if ( $DB_user && $DB_user ne 'viewer' ) {    ## if DB_user is specified... ensure this DB_user is defined for this user
            ($pass) = $Temp_Connection->Table_find( 'Employee,DB_Login', 'count(*)', "WHERE FK_Employee__ID=Employee_ID AND DB_User = '$DB_user' AND $user_condition" );
        }
        elsif ( $DB_user eq 'viewer' ) {             #for viewer, just chceck for employee login
            ($pass) = $Temp_Connection->Table_find( 'Employee', 'count(*)', "WHERE $user_condition" );
        }
        else {                                       ## if DB_user not specified, ensure only one valid DB_user for this user
            $DB_user = join ',', $Temp_Connection->Table_find( 'Employee,DB_Login', 'DB_User', "WHERE FK_Employee__ID=Employee_ID AND $user_condition" );
            if ( $DB_user =~ /,/ ) {
                $self->error("Group must be supplied if connecting via LIMS (more than one valid user for $user). ('$args{-DB_user}')");
                return;
            }
            else { $pass = 1 }                       ## single DB_User extracted from database
        }
    }
    else {
        $self->error("No password supplied");
        return;
    }

    $Temp_Connection->disconnect();

    if ( $DB_user && $pass ) {
        $self->{DB_user} = $DB_user;
        return 1;                                    ## Success ##
    }
    else {
        $self->error("Verification failed for user: $user ($DB_user) - not on valid DB_Login list");
    }

    return;                                          ## Fail ##
}

####################################################################
# Allow users to specify an alias for a sample (or list of samples)
#
# Users must specify either:
#  - plate id(s) + well(s)
#  - library + plate_number(s) + well(s)
#  - sample_id(s)
#
# <snip>
#  Examples:
#
#  my $data = $API->define_alias(-alias_type=>'MGC',-alias=>12345,-sample_id=>$sample_id);
#
#  my $ok   = $API->define_alias(-alias_type=>'AVF_ID',-alias=>\@names,-library=>'AVF01',-plate_number=>1,-well=>\@wells);
#
#  my $ok   = $API->define_alias(-alias_type=>'AVF_ID',-alias=>\@names,-plate_id=>\@ids,-well=>\@wells)
#
# </snip>
#
# (repeat Alias_Type / Alias / Sample_ID records are ignored - no update since it already exists)
# (repeat Alias_Type / Alias generates either:
#    - ERROR (no update) (if 'allow_repeats' flag is not set);
#    - WARNING but updates the database (if 'allow_repeats' flag is set);
#
# Return : Number of records added to Sample_Alias table.
#####################
###############
sub define_alias {
###############
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => [ 'alias', 'alias_type' ] );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $sample_id     = $args{-sample_id};                      ## sample id (or array reference to list of ids)
    my $plate_id      = $args{-plate_id};                       ## plate id
    my $plate_number  = $args{-plate_number};                   ## plate number
    my $library       = $args{-library};                        ## library of interest
    my $well          = $args{-well};                           ## specific well(s)
    my $alias         = $args{-alias} || $args{-alias_name};    ## alias name
    my $alias_type    = $args{-alias_type};                     ## alias type
    my $allow_repeats = $args{-allow_repeats} || 0;             ## flag necessary if alias is repeated for a separate sample
    my $quiet         = $args{-quiet};
    my $debug         = $args{-debug};

    my $start = timestamp();

    my @alias_names = Cast_List( -list => $alias, -to => 'array' );
    my $number = int(@alias_names);

    my @wells         = Cast_List( -list => $well,         -to => 'array', -pad => $number );
    my @libraries     = Cast_List( -list => $library,      -to => 'array', -pad => $number );
    my @sample_ids    = Cast_List( -list => $sample_id,    -to => 'array', -pad => $number );
    my @plate_ids     = Cast_List( -list => $plate_id,     -to => 'array', -pad => $number );
    my @plate_numbers = Cast_List( -list => $plate_number, -to => 'array', -pad => $number );

    my $condition;    ## Establish condition for extracting sample id from Clone_Sample table ##
    if ( $plate_id && $well ) {
        unless ( ( $#plate_ids == $#wells ) && ( $#plate_ids == $#alias_names ) ) {
            $self->error("Error: number of aliases should match number of wells, plate_ids");
            return;
        }
        $condition = "WHERE FKOriginal_Plate__ID = <P_ID> AND Original_Well = '<WELL>'";
    }
    elsif ( $library && $plate_number && $well ) {
        unless ( ( $#libraries == $#wells ) && ( $#libraries == $#plate_numbers ) && ( $#libraries == $#alias_names ) ) {
            $self->error("Error: number of aliases should match number of wells, libraries, plate_numbers");
            return;
        }
        $condition = "WHERE Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND Plate.FKOriginal_Plate__ID=Plate.Plate_ID AND FK_Library__Name = '<LIB>' AND Plate_Number = <PNUM> AND Well = '<WELL>' ";
    }
    elsif ($sample_id) { }
    else {
        $self->error("Error: you must specify Either plate_id + well, library + plate_number + well, or sample_id");
        return;
    }
    my $updated = 0;
    ### define alias for each respective alias supplied ###
    foreach my $index ( 0 .. $#alias_names ) {
        my $alias = $alias_names[$index];
        my $sid;
        $sid = $sample_ids[$index] if $sample_id;
        my $w;
        $w = $wells[$index] if $well;
        my $pn;
        $pn = $plate_numbers[$index] if $plate_number;
        my $lib;
        $lib = $libraries[$index] if $library;
        my $pid;
        $pid = $plate_ids[$index] if $plate_id;
        my $cond = $condition;

        $cond =~ s/<WELL>/$w/g;
        $cond =~ s/<PNUM>/$pn/g;
        $cond =~ s/<P_ID>/$pid/g;
        $cond =~ s/<LIB>/$lib/g;
        unless ($sid) {
            ($sid) = $self->Table_find( 'Plate_Sample,Plate', 'FK_Sample__ID', $cond );
        }
        unless ( $sid =~ /[1-9]/ ) { $self->error("Error: Sample_ID not found for condition: $cond"); next; }

        ##<CONSTRUCTION> This logic is convoluted a bit
        ### check to see if this Alias / Alias_Type already exists.
        my ($exists) = $self->Table_find( 'Sample_Alias', 'FK_Sample__ID', "WHERE Alias = '$alias' AND Alias_Type = '$alias_type'" );
        if ( $exists =~ /^$sid$/ ) { $self->warning("$alias_type : $alias .... (This entry already exists)"); next; }    ## the exact same entry (add organization ?)
        elsif ( $exists =~ /[1-9]/ ) {
            if ($allow_repeats) {                                                                                        ## allow re-using of same alias for new sample ?
                $self->warning("Overwrote alias for sample: $exists");
            }
            else {                                                                                                       ## default prevents re-use of same alias
                $self->error("Error : This alias exists already for sample: $exists (use -allow_repeats switch to force new alias)");
                next;
            }
        }
        else {
            my ($entry) = $self->Table_find( 'Sample_Alias', 'Alias', "WHERE Alias_Type = '$alias_type' AND FK_Sample__ID=$sid" );
            if ( $entry && lc($entry) ne lc($alias) ) {
                $self->warning("$alias_type for Sample $sid has been set to '$entry' and can not be changed.");
                $self->warning("Please contact a LIMS administrator to update this alias");
                next;
            }
        }

        my $ok = $self->Table_append_array( 'Sample_Alias', [ 'FK_Sample__ID', 'Alias_Type', 'Alias' ], [ $sid, $alias_type, $alias ], -autoquote => 1 );
        Message("Set Alias $alias_type = $alias ($sid)") unless $quiet;
        if   ($ok) { $updated++; }
        else       { $self->warning("Warning: $alias_type = $alias ($sid) Failed"); }
    }
    return $self->api_output( -data => $updated, -start => $start, -customized_output => 1, -log => 1, -debug => $debug );
}

#####################################################
# List aliases for fields available through the API
#
# <snip>
# Example:
#    $API->list_Aliases();
#
# </snip>
# Return: none;
################
sub list_Aliases {
################
    my $self    = shift;
    my $tables  = shift;
    my $verbose = shift;

    $self->_list_Fields( $tables, $verbose );
    return;
}

#####################
# Generate list of aliases and fields available for users to query.
#
#
# Return: (nothing) (prints list of fields / aliases to STDOUT)
###################
sub _list_Fields {
###################
    my $self    = shift;
    my $tables  = shift;
    my $verbose = shift;

    my $table_list = $tables;

    unless ($table_list) { $table_list = join ',', keys %Aliases }
    while ( $table_list =~ /(.*) LEFT JOIN (\S+) ON (.*)/i ) { $table_list = "$1,$2"; }    ## replace single left join in list...

    my $quoted_table_list = Cast_List( -list => $table_list, -to => 'string', -autoquote => 1 );
    my %info = $self->Table_retrieve( 'DBField,DBTable', [ 'Field_Name', 'DBTable_Name as Table_Name', 'Field_Description as Description' ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ($quoted_table_list)" );

    print "\n****************\n** TABLES: **\n****************\n\n";
    print join "\n", Cast_List( -list => $table_list, -to => 'array', -autoquote => 1 );
    print "\n\n";

    my %Descriptions;

    print "\n****************\n** FIELDS: **\n****************\n\n";

    ## (print out list of fields and associated tables)
    printf "\nFields:\n****************\n%-30s %-30s\n\n", 'Field', 'Description' if $verbose;
    my $index = 0;
    while ( defined $info{Field_Name}[ $index++ ] ) {
        my $table = $info{Table_Name}[ $index - 1 ];
        my $field = $info{Field_Name}[ $index - 1 ];
        my $desc  = $info{Description}[ $index - 1 ];
        printf "%-30s %-30s : %s\n", $table, $field, $desc if $verbose;
        $Descriptions{"$table.$field"} = $info{Description}[ $index - 1 ];
    }

    ## Include applicable Aliases ##
    foreach my $table ( split ',', $table_list ) {
        if ( defined $object_aliases{$table} ) {
            my $add = $object_aliases{$table};
            $table_list .= "," . $object_aliases{$table} unless grep /\b$add\b/, $table_list;
        }
    }

    foreach my $table ( split /\s*,\s*/, $table_list ) {
        print "\n$table Aliases\n*******************\n";
        foreach my $key ( keys %{ $Aliases{$table} } ) {
            my $thisfield = $Aliases{$table}{$key};
            printf "%-30s %-30s\n", $key, $Descriptions{$thisfield} . " [$Aliases{$table}{$key}]";
        }
    }
    return;
}
######################
#
#
#
# Return hash ref to list of available fields based on a list of tables
######################
sub get_alias_info {
######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'tables,fields' );

    my $table_list = $args{-tables};
    unless ($table_list) { $table_list = join ',', keys %Aliases }
    my $alias_list = $args{-alias_list};
    my @alias_list = Cast_List( -list => $alias_list, -to => 'Array' );
    my @table_list = Cast_List( -list => $table_list, -to => 'Array' );

    my $quoted_table_list = Cast_List( -list => $table_list, -to => 'String', -autoquote => 1 );

    #    my $quoted_fields_list = Cast_List(-list=>$fiel_list,-to=>'String',-autoquote=>1);

    my $condition = "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ($quoted_table_list)";

    # if ($fields_list) {
    #	push @conditions, "Field_Name IN ($quoted_fields_list)";
    #    }

    my %db_field_info = $self->Table_retrieve( 'DBField,DBTable', [ 'Field_Name', 'DBTable_Name as Table_Name', 'Field_Description as Description' ], $condition );

    my %available_field_list;
    my $index = 0;

    my %field_desc;
    while ( defined $db_field_info{Field_Name}[$index] ) {
        my $field_name = $db_field_info{Field_Name}[$index];
        my $table_name = $db_field_info{Table_Name}[$index];
        my $field_desc = $db_field_info{Description}[$index];
        $field_desc{"$table_name.$field_name"} = $field_desc;
        $index++;
    }

    foreach my $table (@table_list) {
        foreach my $key ( keys %{ $Aliases{$table} } ) {
            my $full_field_name = $Aliases{$table}{$key};
            my $alias           = $key;
            if ( $alias_list && !( grep /^$key$/i, @alias_list ) ) {
                next;
            }
            $available_field_list{$table}{$alias} = { full_name => $full_field_name, description => $field_desc{$full_field_name} };
        }
    }
    return \%available_field_list;
}

#########################
#
# <snip>
#       my %reasons     = $API->get_failreasons(-object=>'Lane');
#       my $reason_id   = $API->get_failreasons(-object=>'Lane',-reason=>'Manually Deselected');
# <snip>
#
#
#########################
sub get_failreasons {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -args => 'Object,Object_Type', -mandatory => 'Object' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $groups = $self->get_local('group_list');

    my $object = $args{-Object};
    my $type   = $args{-Object_Type};
    my $name   = $args{-reason_name};
    my $debug  = $args{-debug};
    my $start  = timestamp();

    my $reasons = &alDente::Fail::get_reasons( -object => $object, -object_type => $type, -grps => $groups, -reason_name => $name );

    return $self->api_output( -data => $reasons, -start => $start, -customized_output => 1, -log => 1, -debug => $debug );

}

#########################
#
# <snip>
#   my $project_details = $API->get_project_data('Human Tum'); ### *Human Tum*
# </snip>
#
#########################
sub get_project_data {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'project_name', -mandatory => 'project_name' );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $start = timestamp();

    my $project_name = $args{-project_name};
    my %project_details = $self->Table_retrieve( 'Project', ['*'], "WHERE Project_Name LIKE '%$project_name%'" );

    return $self->api_output( -data => \%project_details, -start => $start, -log => 1 );
}

#  Return Submission information
#
#
#
#########################
sub get_submission_data {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval
    my $input_conditions   = $args{-condition} || '1';     ### extra condition (vulnerable to structure change)
    my $study_id           = $args{-study_id};             ### a study id (a defined set of libraries/projects)
    my $project_id         = $args{-project_id};           ### specify project_id
    my $library            = $args{-library};              ### specify library
    my $work_request_type  = $args{-work_request_type};
    my $submitted_employee = $args{-submitted_employee};

    my $input_joins      = $args{-input_joins};
    my $input_left_joins = $args{-input_left_joins};

    ## Inclusion / Exclusion options
    my $since = $args{-since};                             ### specify date to begin search (context dependent)
    my $until = $args{ -until };                           ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Submission_DateTime';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $work_request_types;
    $work_request_types = Cast_List( -list => $work_request_type, -to => 'string', -autoquote => 1 ) if $work_request_type;
    my $submitted_employees;
    $submitted_employees = Cast_List( -list => $submitted_employee, -to => 'string', -autoquote => 1 ) if $submitted_employee;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;
    if ($libraries) { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }

    if ($work_request_types)  { push( @extra_conditions, "Work_Request_Type.Work_Request_Type_Name IN ($work_request_types)" ) }
    if ($submitted_employees) { push( @extra_conditions, "Submission.FKSubmitted_Employee__ID IN ($submitted_employees)" ) }

    ## Initial Framework for query ##
    my $tables           = 'Submission';    ## <- Supply list of Tables to retrieve data from ##
    my $join_condition   = 'WHERE 1';       ## <- Supply join condition for Tables retrieved (if > 1) ##
    my $left_join_tables = '';              ## <- Supply additional tables to left_join (includes condition)

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $join_conditions = {};               ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    $join_conditions = {
        ## standards ##
        #	"Submission_Table_Link"  => "Submission_ID = Submission_Table_Link.FK_Submission__ID",
        #	"Submission_Info"       => "Submission_Info.FK_Submission__ID = Submission_ID",
        #	"Library" => "Submission.Key_Value = Library.Library_Name",
    };                                      ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        "Employee as Approver"  => "Approver.Employee_ID = FKApproved_Employee__ID",
        "Employee as Submitter" => "Submitter.Employee_ID = FKSubmitted_Employee__ID",
        "Work_Request"          => "Work_Request.Work_Request_ID  = Submission.Key_Value",
        "Library"               => "Work_Request.FK_Library__Name = Library.Library_Name",
        "Work_Request_Type"     => "Work_Request.FK_Work_Request_Type__ID = Work_Request_Type.Work_Request_Type_ID"

            #"LibraryGoal" => "Library.Library_Name = LibraryGoal.FK_Library__Name",
    };                                      ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};

    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list = qw(submission_date submission_status approved_date submission_id submission_comments submitted_by approved_by);    ## <- Default list of fields to retrieve

    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -date_field           => $date_field,
        -limit                => $limit,
        -quiet                => $quiet,
    );

}

################################
sub get_submission_volume_data {
################################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $data = $self->get_analysis_submission_data(%args);

    return $data;
}

#  Returns submission volume information that is sent to different data centers ie (NCBI/cgHUB)
#
#
#
################################
sub get_analysis_submission_data {
################################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ## Include below any arguments that should appear in perldoc + any arguments needing specific attention

    ## Specify conditions for data retrieval
    my $input_conditions = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $library          = $args{-library};
    my $study_id         = $args{-study_id};
    my $project_id       = $args{-project_id};

    ### Flag for retrieving submission entries if the full tracking set of info (Analysis_Submission/Metadata_Submission/Metadata_Object) is not present
    ###
    ### Only for internal LIMS use!

    my $legacy = $args{-legacy};

    my $input_joins                          = $args{-input_joins};
    my $input_left_joins                     = $args{-input_left_joins};
    my $run_analysis                         = $args{-run_analysis};
    my $multiplex_run_analysis               = $args{-multiplex_run_analysis};
    my $adapter_index                        = $args{-multiplex_adapter_index};
    my $solexa_reference_genome_id           = $args{-solexa_reference_genome_id};
    my $multiplex_solexa_reference_genome_id = $args{-multiplex_solexa_reference_genome_id};
    my $analysis_submission_id               = $args{-analysis_submission_id};
    my $submission_volume_id                 = $args{-submission_volume_id};
    my $analysis_metadata                    = $args{-analysis_metadata};
    my $analysis_metadata_object_alias       = $args{-analysis_metadata_object_alias};
    ## Inclusion / Exclusion options
    my $since = $args{-since};      ### specify date to begin search (context dependent)
    my $until = $args{ -until };    ### specify date to stop search (context dependent)
            my $date_field = $args{-date_field} || 'Submission_Date';

            ## Output options
            my $fields      = $args{-fields} || '';
            my $add_fields  = $args{-add_fields};
            my $order       = $args{-order} || '';
            my $group       = $args{-group} || $args{-group_by} || $args{-key};
            my $KEY         = $args{-key} || $group;
            my $limit       = $args{-limit} || '';                                ### limit number of unique samples to retrieve data for
            my $quiet       = $args{-quiet};                                      ### suppress feedback by setting quiet option
            my $save        = $args{-save};
            my $list_fields = $args{-list_fields};                                ### just generate a list of output fields

            ### Re-Cast arguments as required ###
            my $libs;
            $libs = $self->get_libraries(%args) if ( $library || $study_id || $project_id );
    my $libraries;
    $libraries = Cast_List( -list => $libs, -to => 'string', -autoquote => 1 ) if $libs;
    my $run_analyses;
    $run_analyses = Cast_List( -list => $run_analysis, -to => 'string', -autoquote => 1 ) if $run_analysis;
    my $multiplex_run_analyses;
    $multiplex_run_analyses = Cast_List( -list => $multiplex_run_analysis, -to => 'string', -autoquote => 1 ) if $multiplex_run_analysis;
    my $multiplex_run_indices;
    $multiplex_run_indices = Cast_List( -list => $adapter_index, -to => 'string', -autoquote => 1 ) if $adapter_index;
    my $solexa_reference_genome_ids;
    $solexa_reference_genome_ids = Cast_List( -list => $solexa_reference_genome_id, -to => 'string', -autoquote => 1 ) if $solexa_reference_genome_id;
    my $multiplex_solexa_reference_genome_ids;
    $multiplex_solexa_reference_genome_ids = Cast_List( -list => $multiplex_solexa_reference_genome_id, -to => 'string', -autoquote => 1 ) if $multiplex_solexa_reference_genome_id;
    my $analysis_submission_ids;
    $analysis_submission_ids = Cast_List( -list => $analysis_submission_id, -to => 'string' ) if $analysis_submission_id;
    my $submission_volume_ids;
    $submission_volume_ids = Cast_List( -list => $submission_volume_id, -to => 'string' ) if $submission_volume_id;
    my $analysis_metadata_object_aliases;
    $analysis_metadata_object_aliases = Cast_List( -list => $analysis_metadata_object_alias, -to => 'string', -autoquote => 1 ) if $analysis_metadata_object_alias;

    ## Define Tables / Conditions ##
    my @extra_conditions;
    @extra_conditions = Cast_List( -list => $input_conditions, -to => 'array', -no_split => 1 ) if $input_conditions;
    if ($libraries)                             { push( @extra_conditions, "Library.Library_Name IN ($libraries)" ) }
    if ($run_analyses)                          { push( @extra_conditions, "Analysis_Submission.FK_Run_Analysis__ID IN ($run_analyses)" ) }
    if ($multiplex_run_analyses)                { push( @extra_conditions, "Analysis_Submission.FK_Multiplex_Run_Analysis__ID IN ($multiplex_run_analyses)" ) }
    if ($multiplex_run_indices)                 { push( @extra_conditions, "Multiplex_Run_Analysis.Adapter_Index IN ($multiplex_run_indices)" ) }
    if ($solexa_reference_genome_ids)           { push( @extra_conditions, "Solexa_Run_Analysis.FK_Genome__ID IN ($solexa_reference_genome_ids)" ) }
    if ($multiplex_solexa_reference_genome_ids) { push( @extra_conditions, "Multiplex_Solexa_Run_Analysis.FK_Genome__ID IN ($multiplex_solexa_reference_genome_ids)" ) }
    if ($analysis_submission_ids)          { push @extra_conditions, "Analysis_Submission_ID IN ($analysis_submission_ids)" }
    if ($submission_volume_ids)            { push @extra_conditions, "Submission_Volume_ID IN ($submission_volume_ids)" }
    if ($analysis_metadata_object_aliases) { push @extra_conditions, "analysis_metadata_object_alias IN ($analysis_metadata_object_aliases)" }

    # if ($include_analysis) {
    #     push( @extra_conditions, "(Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID OR Run_Analysis.FK_Sample__ID = Sample_ID) " );

    # }

    ##### DYNAMICALLY JOINED Tables: #####
    ## add Tables as necessary based with specified join conditions ##
    my $tables;
    my $join_condition   = 'WHERE 1';
    my $join_conditions  = {};          ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,
    my $left_join_tables = '';

    if ($legacy) {

        $tables = "Trace_Submission";

        $join_conditions = {
            ## standards ##
            Run                                 => "Trace_Submission.FK_Run__ID = Run.Run_ID",
            Sample                              => "Sample.Sample_ID = Trace_Submission.FK_Sample__ID",
            Library                             => "Sample.FK_Library__Name = Library.Library_Name",
            Submission_Volume                   => "Submission_Volume.Submission_Volume_ID = Trace_Submission.FK_Submission_Volume__ID",
            "Status as Trace_Submission_Status" => "Trace_Submission.FK_Status__ID = Trace_Submission_Status.Status_ID"
        };
    }
    else {

        $tables = "Analysis_Submission";

        $join_conditions = {
            ## standards ##
            Run_Analysis                           => "Analysis_Submission.FK_Run_Analysis__ID = Run_Analysis.Run_Analysis_ID",
            Solexa_Run_Analysis                    => "Solexa_Run_Analysis.FK_Run_Analysis__ID = Run_Analysis.Run_Analysis_ID",
            Run                                    => "Run_Analysis.FK_Run__ID = Run.Run_ID",
            Sample                                 => "Sample.Sample_ID = Analysis_Submission.FK_Sample__ID",
            Library                                => "Sample.FK_Library__Name = Library.Library_Name",
            Submission_Volume                      => "Submission_Volume.Submission_Volume_ID = Analysis_Submission.FK_Submission_Volume__ID",
            "Status as Analysis_Submission_Status" => "Analysis_Submission.FK_Status__ID = Analysis_Submission_Status.Status_ID",

        };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,
    }

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = {
        "Metadata_Submission"                         => "Metadata_Submission.FK_Submission_Volume__ID = Submission_Volume.Submission_Volume_ID",
        "Metadata_Object as Analysis_Metadata_Object" => "Analysis_Metadata_Object.Metadata_Object_ID = Analysis_Link.FKAnalysis_Metadata_Object__ID",
        "Metadata_Object as Sample_Metadata_Object"   => "Sample_Metadata_Object.Metadata_Object_ID = Analysis_Link.FKSample_Metadata_Object__ID",
        "Analysis_Link"                               => "Analysis_Link.FK_Analysis_File__ID = Analysis_File.Analysis_File_ID",

        "Dataset_Link"                        => "Dataset_Link.FKMember_Metadata_Object__ID = Analysis_Metadata_Object.Metadata_Object_ID",
        "Metadata_Object as Analysis_Dataset" => "Analysis_Dataset.Metadata_Object_ID = Dataset_Link.FKDataset_Metadata_Object__ID",

        "Analysis_File"                      => "Analysis_Submission.FK_Analysis_File__ID = Analysis_File.Analysis_File_ID",
        "Multiplex_Run_Analysis"             => "Analysis_Submission.FK_Multiplex_Run_Analysis__ID = Multiplex_Run_Analysis.Multiplex_Run_Analysis_ID",
        "Multiplex_Solexa_Run_Analysis"      => "Multiplex_Solexa_Run_Analysis.FK_Multiplex_Run_Analysis__ID = Multiplex_Run_Analysis.Multiplex_Run_Analysis_ID",
        "Status as Analysis_Metadata_Status" => "Analysis_Metadata_Object.FK_Status__ID = Analysis_Metadata_Status.Status_ID",
        "Organization"                       => "Submission_Volume.FK_Organization__ID = Organization.Organization_ID",
    };    ##	eg { '<TABLENAME>'      => "<JOIN_CONDITION>", ... } ,

    ## adapt conditions using appropriate aliases as required ##
    &customize_join_conditions( $join_conditions, $left_join_conditions, -input_joins => $input_joins, -tables => $tables, -input_left_joins => $input_left_joins );

    ## Add extra_conditions as required by input parameters   eg...##
    ## <- if ($samples) { push(@extra_conditions,"FK_Sample__ID IN ($samples)"};
    ## Concatenate conditions ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    my @field_list;

    if ($legacy) {
        @field_list = qw(run_id library trace_submission_status);    ## <- Default list of fields to retrieve
    }
    else {
        @field_list = qw(run_id library analysis_submission_status analysis_submission_finished analysis_dataset_unique_identifier);    ## <- Default list of fields to retrieve
    }
    if ($analysis_metadata) {
        push @field_list, qw(analysis_metadata_object_unique_identifier analysis_metadata_object_alias analysis_file_path analysis_file_type);
    }
    ## IF fields specified, over-ride default list ##
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    return $self->generate_data(
        -input                => \%args,
        -field_list           => \@field_list,
        -group                => $group,
        -key                  => $KEY,
        -order                => $order,
        -tables               => $tables,
        -join_condition       => $join_condition,
        -conditions           => $conditions,
        -left_join_tables     => $left_join_tables,
        -left_join_conditions => $left_join_conditions,
        -join_conditions      => $join_conditions,
        -date_field           => $date_field,
        -limit                => $limit,
        -quiet                => $quiet,
    );

}

##############################
#
# Arguments:    'reference'        #  Data References
#               'annot_type'       #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#               'annot_value'      #  The value we are setting it to
#               'comments'         #  Optional comments
#               'quiet'            #  Supress the output
# Returns:      1 on success, 0 on failure
#
# <snip>
#      my $ok = $API->set_rundata_annotations(
#                             -reference => ['50:A01','51:A01'],
#                             -annot_type  => 'Sulston Score',
#                             -annot_value => '5.32e-10'
#                             );
# </snip>
#
##############################
sub set_rundata_annotations {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'reference,annot_type,annot_value', -mandatory => 'reference,annot_type,annot_value' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ### Connection parameters ###
    my $dbc = $args{-dbc} || $args{-connection};
    my $start = timestamp();

    ### Mandatory ###
    my $reference   = $args{-reference};      #  Data References
    my $annot_type  = $args{-annot_type};     #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $annot_value = $args{-annot_value};    #  The value we are setting it to

    ### Optional ###
    my $comments = $args{-comments};          #  Optional comments
    my $quiet    = $args{-quiet};

    require alDente::RunDataReference;
    my $obj = alDente::RunDataReference->new( -dbc => $self );
    my $return = $obj->save_annotations( -reference => $reference, -annot_type => $annot_type, -annot_value => $annot_value, -comments => $comments, -quiet => $quiet );

    return $self->api_output( -data => $return, -log => 1, -start => $start, -customized_output => 1 );
}

##############################
# Arguments:    'run_id'                #  Run_ID of interest [mandatory]
#               'well'                  #  Specific field on the given Run [optional]
#               'annot_type'            #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#               'quiet'                 #  Supress the output
#
# Returns:      'annotations hash' on success, 'undef' on failure
#
# <snip>
#       my $score = $API->get_rundata_annotation_sets(
#                             -run_id           => 5000,
#                             -well             => 'A01',
#                             -annot_type       => 'Sulston Score'
#                             );
##############################
sub get_rundata_annotation_sets {
##############################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input( \@_, -args => 'run_id,well', -mandatory => 'run_id' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ### Connection parameters ###
    my $dbc = $args{-dbc} || $args{-connection};
    my $start = timestamp();

    ### Mandatory ###
    my $run_id = $args{-run_id};    #  Run_ID of interest
    my $well   = $args{-well};      #  Specific field on the given Run [optional]

    ### Optional ###
    my $annot_type = $args{-annot_type};    #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
    my $quiet      = $args{-quiet};

    require alDente::RunDataReference;
    my $obj = alDente::RunDataReference->new( -dbc => $self );
    my $return = $obj->get_annotation_sets( -run_id => $run_id, -well => $well, -annot_type => $annot_type, -quiet => $quiet );

    return $self->api_output( -data => $return, -log => 1, -start => $start, -customized_output => 1 );

}

##############################
# Arguments:    'reference'              #  Run_ID of interest [mandatory]
#               'annot_type'            #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name
#
# Returns:      'annotations hash' on success, 'undef' on failure
#
# <snip>
#       my $score = $API->get_rundata_annotation_value(
#                             -reference=>['50:A01','50:A01'],
#                             -annot_type       => 'Sulston Score'
#                             );
# </snip>
##############################
sub get_rundata_annotation_value {
##############################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input( \@_, -args => 'reference,annot_type', -mandatory => 'reference,annot_type' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    ### Connection parameters ###
    my $dbc = $args{-dbc} || $args{-connection};
    my $start = timestamp();

    my $reference  = $args{-reference};     #  Run_ID of interest [mandatory]
    my $annot_type = $args{-annot_type};    #  RunDataAnnotation_Type_ID or RunDataAnnotation_Type_Name

    require alDente::RunDataReference;
    my $obj = alDente::RunDataReference->new( -dbc => $self );
    my $return = $obj->get_annotation_value( -reference => $reference, -annot_type => $annot_type );
    return $self->api_output( -data => $return, -log => 1, -start => $start, -customized_output => 1 );

}

##############################################################################################################
#
# Convert the parameters passed to get_xxx_summary to parameters acceptable by the corresponding get_xxx_data
# eg. given:
#
#  get_read_summary(-group_by=>['project_id', 'library'], -count=>['run_id','run_status'], -avg=>['Q20','Q30','quality_length'], -max=>['Q30'], -sum=>['quality_length'], -min=>['Q20'], -stddev=>['Q20'], -plate_type=>'Library_Plate')
#
#  to be passed to
#  get_read_data(-group_by=>['project_id', 'library'], -fields=>['project_id', 'library', 'count(run_id) as count_run_id', 'count(run_status) as count_run_status', 'avg(Q20) as avg_Q20', 'avg(Q30) as avg_Q30', 'avg(quality_length) as avg_quality_length', 'max(Q30) as max_Q30', 'sum(quality_length) as sum_quality_length', 'min(Q20) as min_Q20', 'stddev(Q20) as stddev_Q20'], -plate_type=>'Library_Plate')
#
# Return: hash ref of the arguments to be passed to get_xxx_data
######################################
sub convert_parameters_for_summary {
######################################

    my $self = shift;
    my %args = filter_input( \@_ );

    my $scope = $args{-scope};

    my $group_by = $args{-group_by};

    my $count  = $args{-count};
    my $avg    = $args{-avg};
    my $sum    = $args{-sum};
    my $min    = $args{-min};
    my $max    = $args{-max};
    my $stddev = $args{-stddev};

    delete $args{-count};
    delete $args{-avg};
    delete $args{-sum};
    delete $args{-min};
    delete $args{-max};
    delete $args{-stddev};

    my $function = "get_" . $scope . "_data";

    my @field_list;

    my $values;

    if ($count) {
        $values = _convert_parameters( -name => 'count', -value => $count );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($avg) {
        $values = _convert_parameters( -name => 'avg', -value => $avg );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($sum) {
        $values = _convert_parameters( -name => 'sum', -value => $sum );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($min) {
        $values = _convert_parameters( -name => 'min', -value => $min );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($max) {
        $values = _convert_parameters( -name => 'max', -value => $max );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($stddev) {
        $values = _convert_parameters( -name => 'stddev', -value => $stddev );
        if ($values) {
            @field_list = ( @field_list, @$values );
        }
    }

    if ($group_by) {
        @field_list = ( @field_list, split( ",", $group_by ) );
    }

    $args{-fields} = \@field_list;

    return $self->$function(%args);

}

#
#
#
#
######################
sub add_work_request {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args              = &filter_input( \@_, -mandatory => 'library,goal' );
    my $goal_target       = $args{-goal_target};                                    # the goal target
    my $comments          = $args{-comment};                                        # optional comments
    my $work_request_type = $args{-work_request_type} || 'Default Work Request';    # optional
    my $funding           = $args{-funding};                                        # mandatory SOW for the work request
    my $library           = $args{-library};                                        # mandatory library
    my $goal_target_type  = $args{-goal_target_type} || "Data Analysis";            # optional
    my $goal              = $args{-goal};                                           # type of goal
    my $scope             = $args{-scope} || 'Library';

    my $dbc = $self;

    my $work_request_title   = $args{-work_request_title};
    my $jira_id              = $args{-jira_id};
    my $work_request_created = &date_time();
    my $source_id            = $args{-source_id};
    my $request_employee_id  = $args{-request_employee_id};
    my $request_contact_id   = $args{-request_contact_id};

    ## find the goal in the available goals
    require alDente::Work_Request;
    my $work_request_obj = alDente::Work_Request->new( -dbc => $dbc, -tables => 'Work_Request' );
    my $work_request_id = $work_request_obj->add_work_request(
        -goal_target       => $goal_target,
        -comment           => $comments,
        -work_request_type => $work_request_type,
        -funding           => $funding,
        -library           => $library,
        -goal_target_type  => $goal_target_type,
        -goal              => $goal,
        -scope             => $scope
    );

    return $work_request_id;
}
###################
#
# Sets attribute on a given object and overwrites if there are existing attributes. Returns the number of updates/inserts
#
# <snip>
#        %attributes = (
#            5001 => 'test01',
#            5002 => 'test02',
#        );
#
#        $set = $self->set_attribute(-object=>'Plate',-attribute=>'Concentration',-list=>\%attributes);
# </snip>
#
#
###################
sub set_attribute {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'object,attribute,list' );

    my $object = $args{-object};
    my $att    = $args{-attribute};
    my %list   = %{ $args{-list} };
    my $quiet  = $args{-quiet};
    my $start  = timestamp();

    my @tables = $self->tables();

    if ( !grep( /^$object$/, @tables ) ) {
        return "Error: Unknown object '$object'";
    }

    if ( !grep( /^${object}_Attribute$/, @tables ) ) {
        return "Error: Can not store attributes for '$object'";
    }

    my ($attrib_id) = $self->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class='$object' AND Attribute_Name='$att'" );
    if ( !$attrib_id ) {
        return "Error: Unknown attribute '$att' for '$object'";
    }

    my $user_id  = $self->get_local('user_id');
    my $datetime = &date_time();
    my ($primary_field) = $self->get_field_info( $object, undef, 'Primary' );
    my ($fk_field) = $self->_get_FK_name( "${object}_Attribute", $object, $primary_field );

    my @fields = ( $fk_field, 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' );
    my %values;

    my @keys = map {"'$_'"} keys %list;
    my @to_update_records = $self->Table_find( "${object}_Attribute", $fk_field, "WHERE $fk_field IN (" . join( ',', @keys ) . ") AND FK_Attribute__ID=$attrib_id" );

    my $updates = 0;
    foreach my $key (@to_update_records) {
        $updates += $self->set_data(
            -table        => "${object}_Attribute",
            -fields       => ['Attribute_Value'],
            -values       => [ $list{$key} ],
            -condition    => "WHERE $fk_field = '$key' AND FK_Attribute__ID=$attrib_id",
            -valid_fields => ['Attribute_Value']
        );
        delete $list{$key};
    }

    my $count = 0;
    foreach my $key ( keys %list ) {
        $values{ ++$count } = [ $key, $attrib_id, $list{$key}, $user_id, $datetime ];
    }

    my $newids;
    if (%values) {
        $newids = $self->smart_append( "${object}_Attribute", \@fields, \%values, -autoquote => 1 );
        $updates += int( @{ $newids->{"${object}_Attribute"}->{newids} } );
    }

    return $self->api_output( -data => $updates, -log => 1, -start => $start, -customized_output => 1 );
}

######################
#
# Retrieves an already preset attribute and returns a key/value pairs of objects and their attribute value
#
# <snip>
#   $API->get_attribute(-object=>'Plate',-attribute=>'Concentration',-keys=>[500,501,503]);   ## get concentrations for all plates in given list {<plate_id> => <concentration>, ...}
#
#   $API->get_attribute(-object=>'Plate',-attribute=>'Concentration',-values[0.5]);   ## get ids for all plates with concentration of 0.5 {<plate_id> = <concentration>, ...}
#
#   $API->get_attribute(-object=>'Plate',-keys=>[500,501,503]);   ## get ALL attributes for given plate {<attribute> => <value>, ...}
# </snip>
#
#
###################
sub get_attribute {
###################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'object,keys|values' );

    ### Limitation:
    ### Either 1 Attribute should be provided with multiple Keys (or values), or Multiple Attributes with 1 Key

    my $object = $args{-object};
    my $attrib = $args{-attribute} || $args{-attributes};
    my @att    = Cast_List( -list => $attrib, -to => 'array' );
    my @keys   = Cast_List( -list => $args{ -keys }, -to => 'array' );
    my @values = Cast_List( -list => $args{ -values }, -to => 'array' );
    my $debug  = $args{-debug};
    my $quiet  = $args{-quiet};
    my $start  = timestamp();

    my @tables = $self->tables();

    if ( !grep( /^$object$/, @tables ) ) {
        return "Error: Unknown object '$object'";
    }

    if ( !grep( /^${object}_Attribute$/, @tables ) ) {
        return "Error: Can not store attributes for '$object'";
    }
    my ($primary_field) = $self->get_field_info( $object, undef, 'Primary' );
    my ($fk_field) = $self->_get_FK_name( "${object}_Attribute", $object, $primary_field );

    my %return;
    my @fields = ( $fk_field, 'Attribute_Value' );
    my $condition = "FK_Attribute__ID=Attribute_ID";

    if ( int(@att) == 1 && int(@keys) > 0 ) {
        $condition .= " AND $fk_field IN ('" . join( "','", @keys ) . "')";
    }
    elsif ( int(@keys) == 1 ) {

        my @groups = $self->get_local('group_list');
        if ( int(@att) == 0 ) {
            ## only one object indicated, so return all attributes if none specified ##
            @att = $self->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Class='$object' AND FK_Grp__ID IN (" . join( ',', @groups ) . ")" );
        }

        $fields[0] = 'Attribute_Name';
        $condition .= " AND $fk_field = '$keys[0]'";
    }
    elsif ( int(@att) == 1 && int(@values) > 0 ) {
        $condition .= " AND Attribute_Value IN ('" . join( "','", @values ) . "')";
    }
    else {
        $self->error("If requesting multiple ids or values, only one attribute at a time may be requested.");
        return 0;
    }

    my $att_list = join "','", @att;
    my %results = $self->Table_retrieve( "${object}_Attribute,Attribute", \@fields, "WHERE $condition AND Attribute_Name IN ('$att_list')", -debug => $debug );
    if (%results) {
        @return{ @{ $results{ $fields[0] } } } = @{ $results{ $fields[1] } };
    }

    return $self->api_output( -data => \%return, -log => 1, -start => $start, -customized_output => 1 );
}
######################
#
# Get process deviation based on a process deviation number, retrieve a list of all the process deviation codes, or retrieve all objects affected by a process deviations
#
# Returns: hash of process deviation data
# <snip>
#
#  ## lists out all process deviations including fields 'Process_Deviation_Name','Process_Deviation_Description','Deviation_No'
#  $API->get_process_deviation_data(-list=>1);
#  ## get informations given a list of process deviation numbers
#  $API->get_process_deviation_data(-process_deviation=>['PD.562','PD.563']);
#  ## get informations given a list of process deviation numbers based on a set of objects you are interested in
#  $API->get_process_deviation_data(-process_deviation=>['PD.562','PD.563'],-object=>['Library','Plate']);
#  ## Get deviations for a given object
#  $API->get_process_deviation_data(-object=>'Library',-object_id=>['A00001','A00002']);
#
#
# </snip>
#
#
################################
sub get_process_deviation_data {
################################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'list|process_deviation|object|object_id' );

    ### Limitation:
    ### Either 1 Attribute should be provided with multiple Keys (or values), or Multiple Attributes with 1 Key

    my $object            = $args{-object};               ## list one or more objects ie Sample,Library,Plate,Source
    my $process_deviation = $args{-process_deviation};    ## process deviation number(s)
    my $debug             = $args{-debug};
    my $quiet             = $args{-quiet};
    my $object_id         = $args{-object_id};            ## list of one or more object ID's, only works if only one object specified
    my $list              = $args{-list};
    my $start             = timestamp();

    my @tables = $self->tables();

    my %return;
    my $query_tables;
    my @query_fields;
    my $object_ids         = Cast_List( -list => $object_id,         -to => 'String', -autoquote => 1 );
    my $process_deviations = Cast_List( -list => $process_deviation, -to => 'String', -autoquote => 1 );
    my @object             = Cast_List( -list => $object,            -to => 'Array' );
    my $condition          = "";
    if ($list) {
        $query_tables = 'Process_Deviation';
        @query_fields = ( 'Process_Deviation_Name', 'Process_Deviation_Description', 'Deviation_No' );
        $condition    = "WHERE 1";
    }
    elsif ($process_deviation) {
        my $object_cond = "";
        if (@object) {
            my $object_str = Cast_List( -list => $object, -to => 'String', -autoquote => 1 );
            $object_cond = " AND Object_Class IN ($object_str) ";
        }
        @query_fields = ( 'Process_Deviation_Name', 'Process_Deviation_Description', 'Deviation_No', 'Object_Class as Object', 'Object_ID as ID', 'Set_DateTime' );
        $query_tables = 'Process_Deviation,Process_Deviation_Object,Object_Class';
        $condition    = "WHERE Process_Deviation_ID = Process_Deviation_Object.FK_Process_Deviation__ID and   
                      Object_Class_ID = Process_Deviation_Object.FK_Object_Class__ID and 
                      Deviation_No IN ($process_deviations) $object_cond";
    }
    elsif ( int(@object) == 1 && $object_id ) {
        $query_tables = 'Process_Deviation,Process_Deviation_Object,Object_Class';
        @query_fields = ( 'Process_Deviation_Name', 'Process_Deviation_Description', 'Deviation_No', 'Object_Class as Object', 'Object_ID as ID', 'Set_DateTime' );
        $condition    = "WHERE Process_Deviation_ID = Process_Deviation_Object.FK_Process_Deviation__ID and   
                      Object_Class_ID = Process_Deviation_Object.FK_Object_Class__ID 
                      AND Object_Class = '$object[0]' and Object_ID IN ($object_ids)";
    }
    else {
        $self->error("If requesting multiple ids or values, only one object at a time may be requested.");
        return 0;
    }

    my %results = $self->Table_retrieve( "$query_tables", \@query_fields, "$condition", -debug => $debug );

    return $self->api_output( -data => \%results, -log => 1, -start => $start, -customized_output => 1 );
}

###########################################################
# This is an accessor used to update data in the database.
#
# It should NEVER be called directly but used to repidly create application specific functionality
#
# External wrappers should be written to supply the mandatory fields:
# -tables => list of tables updated within the SQL update command
# -join_condition => join condition for tables above
# -fields => fields to set
# -values => values for each of fields above
# -valid_fields => mandatory list of fields available for updating.  (this is how we control what is being updated)
#
# <snip>
# Example of usage (application specific wrapper):
#
#	sub set_run_data() {
#		my $self = shift;
#		my %args = &filter_input(\@_,-mandatory=>'fields,values,run_id|flowcell');
#       my $table  = $args{-table} ||
# ;     ## eg SolexaRun or Solexa_Read
#		my $fields = $args{-fields};	## list of fields to update (using defined aliases)
#		my $values = $args{-values};	## associated list of values
#		my $run_id = $args{-run_id};	   ## specify update based upon run_id
#		my $flowcell = $args{-flowcell};   ## specify update based upon flowcell
#		my $condition = $args{-condition} || 1;

#	### Generate condition based upon input parameters ###
#
#       ## pass all parameters to allow use of filtering options to retrieve list of run_ids
#       $args{-fields} = 'run_id';
#       my %run_data = %{ $self->get_run_data(%args) };
#       my @run_ids  = @{%run_data->{Run_ID}}
#
#       my $run_list = Cast_List(-list=>\@run_ids,-to=>'string');

#		my @valid_fields = qw(solexa_qmean, solexa_cycles);

#		if ($run_list) {
#			push @conditions, "FK_Run__ID IN ($run_list)";
#		}
#       else {
#           Message("No runs found");
#           return;
#       }
#
#		my $updated = $self->set_data(
#			-table=>$table,
#			-fields=>$fields,
#			-values=>$values,
#			-condition=>$condition,
#			-valid_fields=>\@valid_fields
#		);
#
#		Message("update $updated records");
#		return $updated;
#	}
#
# </snip>
#
# Return: number of updated records
######################################
sub set_data {
######################################
    my $self         = shift;
    my %args         = &filter_input( \@_, -mandatory => 'fields,values,table,condition,valid_fields' );
    my $fields       = $args{-fields};                                                                     ## list of fields to update
    my $values       = $args{ -values };                                                                   ## list of values to update
    my $table        = $args{-table};                                                                      ## list of tables to update (all tables in SQL update command)
    my $condition    = $args{-condition};                                                                  ## condition
    my $valid_fields = $args{-valid_fields};                                                               ## list of valid field aliases to update
    my $quiet        = $args{-quiet};
    my $debug        = $args{-debug};
    my $comment      = $args{-comment};

    ## allow use of aliases if supplied in field list ##
    map {
        my $field = $_;
        foreach my $tab ( split ',', $table ) {
            if ( $Aliases{$tab}{$field} ) { $field = $Aliases{$tab}{$field}; last; }
        }
        $_ = $field;
    } @$fields;
    ## validate list of fields (ensure fields to update are all in list of valid fields) ##

    my ( $intersection, $invalid ) = RGmath::intersection( $fields, $valid_fields );
    if ( $invalid && @$invalid ) {
        $self->error("Specified fields not in valid field list (@$invalid)");
        return 0;
    }
    ## cast list of fields and values into SQL format ##
    my @field_list = @$fields;    #  Cast_List(-list=>$fields,-to=>'array');
    my @value_list = @$values;    # Cast_List(-list=>$values,-to=>'array');;

    unless ( $table && $condition ) { $self->error("Table and condition must be supplied"); return; }
    return $self->Table_update_array( $table, \@field_list, \@value_list, $condition, -autoquote => 1, -debug => $debug, -comment => $comment );

}

#########################
#
#   Set No Grows & Slow Grows for a given Library Plate.
#
#   <snip>
#       $API->set_plate_growth(
#            -plate_id  => $plate_id,
#            -no_grows  => \@no_grow_well_list,
#            -slow_grows=> \@slow_grow_well_list
#            );
#   </snip>
#
#
#########################
sub set_plate_growth {
#########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'plate_id,no_grows,slow_grows', -mandatory => 'plate_id' );

    if ( $args{ERRORS} ) {
        return 0;
    }
    my $start = timestamp();

    my $plate_id   = $args{-plate_id};
    my @no_grows   = Cast_List( -list => $args{-no_grows}, -to => 'array' );
    my @slow_grows = Cast_List( -list => $args{-slow_grows}, -to => 'array' );

    require alDente::Library_Plate;
    my %existing           = $self->Table_retrieve( 'Library_Plate', [ 'No_Grows', 'Slow_Grows' ], "WHERE FK_Plate__ID=$plate_id" );
    my @existing_no_grow   = @{ $existing{'No_Grows'} };
    my @existing_slow_grow = @{ $existing{'Slow_Grows'} };

    if (@no_grows) {
        &alDente::Library_Plate::set_Wells( -plate_ids => $plate_id, -select_type => 'No Grow', -well_list => \@no_grows );
    }

    if (@slow_grows) {
        &alDente::Library_Plate::set_Wells( -plate_ids => $plate_id, -select_type => 'Slow Grow', -well_list => \@slow_grows );
    }

    return $self->api_output( -data => 1, -log => 1, -customized_output => 1, -start => $start );
}

# Allow updating of the well map for a rearray
#
# Example:
#
# <snip>
#     my $num_wells_updated = $API->update_rearray_well_map(-rearray_request=>12345,
#                                                           -target_plate=>117,
#                                                           -target_wells=>['A02','A01'],
#                                                           -source_wells=>['A01','A03'],
#                                                           -source_plates=>[5000,5001]);
# </snip>
#
# Returns: Number of wells updated
#############################
sub update_rearray_well_map {
#############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = filter_input( \@_, -args => "rearray_request,target_plate,target_wells,source_wells,source_plates" );
    my $start = timestamp();

    require alDente::ReArray1;
    my $rearray_obj = alDente::ReArray1->new( -dbc => $self );
    my $num_wells_updated = $rearray_obj->update_rearray_well_map(%args);

    return $self->api_output( -data => $num_wells_updated, -log => 1, -customized_output => 1, -start => $start );
}
#################################
sub add_custom_aliases {
#################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $custom_aliases = $args{-custom_aliases};
    my %custom_aliases;
    %custom_aliases = %$custom_aliases if $custom_aliases;

    my @table_keys = keys %custom_aliases;
    for my $table (@table_keys) {
        my @field_keys = keys %{ $custom_aliases{$table} };
        for my $field (@field_keys) {
            $Aliases{$table}{$field} = $custom_aliases{$table}{$field};
        }
    }

    return;
}

##########################################################
#  This Method merges two arrays of hashes based on a field
#   The original hash gets additional info from the "additional" input
#   the relation is n-1 not n-0
#   if there are any problems with input it will return null and send apporpriate message
# input:
#
#
# output:
#	a reference to an array of hash exact same format as input
#
# example:
#	    my $lib_data = $API -> get_library_data(-library => 'AS001,AS002,HB001',-format=>'array');
#       my $run_data = $API -> get_run_data(-library => 'AS002,HB001',-format=>'array');
#
#        my $mix_dat =  $API -> merge_Data_on_Field (-original=>$run_data,-additional=>$lib_data,-field=>'library');
#
############################
sub merge_Data_on_Field {
############################
    my $self           = shift;
    my %args           = &filter_input( \@_, -mandatory => 'original,additional,field' );
    my $original_ref   = $args{-original};                                                  # The original array where the additional info will be added (reference to  Array of Hash)
    my $additional_ref = $args{-additional};                                                # The array containing additional info (reference to  Array of Hash)
    my $field          = $args{-field};                                                     # The field which the two array will be matched on
    my @original;
    @original = @$original_ref if $original_ref;
    my @additional;
    @additional = @$additional_ref if $additional_ref;
    my @results;

    if ( $additional[0]{$field} && $original[0]{$field} ) {

        for my $orig_hash_ref (@original) {
            my %original_hash = %$orig_hash_ref;
            my %results       = %original_hash;
            my $counter;

            for my $add_hash_ref (@additional) {
                my %additional_hash = %$add_hash_ref;

                if ( $additional_hash{$field} eq $original_hash{$field} ) {
                    my @keys = keys %additional_hash;

                    for my $key (@keys) {
                        if ( !$original_hash{$key} || $original_hash{$key} eq $additional_hash{$key} ) {
                            $results{$key} = $additional_hash{$key};
                        }
                        else {
                            Message "the two hases contain conflicting information";
                            return;
                        }
                    }
                    $counter++;
                }
                else {
                    next;
                }
                if ( $counter == 1 ) {
                    push @results, \%results;
                }
                else {
                    Message "more than one match for the key field";
                    return;
                }
            }
        }
    }
    else { Message "Key field ($field) missing" }
    return \@results;
}

##############################
sub get_Atomic_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    return $self->get_lane_data(%args);
}

#################################
sub _convert_parameters {
#################################
    my %args   = filter_input( \@_ );
    my $name   = $args{-name};
    my $values = $args{-value};
    my @array;

    if ( $name && $values && ref $values eq 'ARRAY' ) {
        foreach my $value (@$values) {
            if ( $value =~ /^\w+$/ ) {
                my $item = $name . "(" . $value . ") as " . $value . "_" . $name;
                push( @array, $item );
            }
        }
    }
    return \@array;
}

############################
#
# Convert string of values and/or aliases based upon the supplied domain (list of tables used)
# eg. given:
#
#  $domain = "Library,Plate,Sample";
#  $Aliases{Library}{library} = 'Library.Library_Name'
#
#  _convert_Aliases converts condition:
#         WHERE library = 'AS001'  ->  WHERE Library.Library_Name = 'AS001'
#
# Return: replaces alias with their value everywhere in supplied string, array
##################
sub _convert_Aliases {
##################
    my %args         = filter_input( \@_ );
    my $domain       = $args{-domain};
    my $array        = $args{-array};
    my $string_ref   = $args{-string};
    my $alias_fields = $args{-alias_fields};    ##  Boolean - change 'key' -> 'key as alias'
    my $replace      = $args{-replace};         ##  Boolean - change 'key' -> 'alias'

    my $string = $$string_ref;

    foreach my $table ( split ',', $domain ) {
        unless ( defined $Aliases{$table} ) { print "No $table aliases defined"; next; }
        my @keys = keys %{ $Aliases{$table} };
        foreach my $alias (@keys) {
            my $value = $Aliases{$table}{$alias};
            ## handling strings
            if ($string) {
                $string =~ s/\b$alias\b/$value/g;    ## substitute aliases in condition
            }
            ## handling arrays ##
            if ($array) {
                foreach my $element (@$array) {
                    $element =~ s/^$alias$/$value AS $alias/;
                }
            }
        }
    }
    return;
}

#######################
sub _insert_quotes {
#######################
    my %args   = filter_input( \@_ );
    my $string = $args{-string};
    my $quotes = $args{-quotes};

    my @quotes = @$quotes;
    my $quote  = shift @quotes;

    while ( $string =~ s/~/"$quote"/ ) {
        $quote = shift @quotes;
    }

    return $string;
}

#######################
sub _remove_quotes {
#######################
    my $str = shift;
    my @quotes;

    while ( $str =~ s/"(.*?)"/~/ ) {
        push @quotes, $1;
    }

    return ( $str, \@quotes );
}

####################################
# Retrieve the ancestry tree and the original starting sources for the given sources
#
# Usage:
#     my %result = %{$API->get_source_lineage(-source_id=>$source_id)};					# retrieve ancestry tree including pooled parents
#     my %result = %{$API->get_source_lineage(-source_id=>$source_id, -no_pools => 1)};	# retrieve ancestry tree excluding pooled parents
#
# Return : hash of info
# Return:	Hash.
#			$result{original} is the array ref of the original starting source ids;
#			$result{tree} is the hash ref of the ancestry tree, with the input source as the root and its original starting sources as the leaves.
#
#           An example:
#        	my ($originals, $parents) = $self->get_ancestry_tree( -id => '60513', -no_pools => 0 );
#        	Dump of $original:
#			['60234','60210','60202','60214','60208','60232','60206','60204','60236','60212'];
#        	Dump of $parents:
#			{
#          	'60513' => {
#                       '60512' => {
#                                    '60498' => {
#                                                 '60436' => {
#                                                              '60210' => 0,
#                                                              '60202' => 0,
#                                                              '60214' => 0,
#                                                              '60208' => 0,
#                                                              '60206' => 0,
#                                                              '60204' => 0,
#                                                              '60212' => 0
#                                                            },
#                                                 '60442' => {
#                                                              '60234' => 0,
#                                                              '60232' => 0,
#                                                              '60236' => 0
#                                                            }
#                                               }
#                                  }
#                     }
#        	};
############################
sub get_source_lineage {
############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -args => 'source_id,no_pools,' );
    if ( $args{ERRORS} ) { $self->error("Input Errors Found: $args{ERRORS}"); return; }

    my $source_id = $args{-source_id};
    my $no_pools  = $args{-no_pools};
    my $debug     = $args{-debug};

    my $start = timestamp();
    my $Source = new alDente::Source( -dbc => $self );
    my ( $originals, $tree ) = $Source->get_ancestry_tree( -id => $source_id, -no_pools => $no_pools );
    my %output_data;
    $output_data{original} = $originals;
    $output_data{tree}     = $tree;
    return $self->api_output( -data => \%output_data, -start => $start, -log => 1, -customized_output => 1, -debug => $debug );
}
return 1;

