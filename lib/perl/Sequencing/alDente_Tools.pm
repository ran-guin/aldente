package alDente_Tools;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

alDente_Tools.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DBIO);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
# use Storable;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use alDente::SDB_Defaults qw($project_dir);
use alDente::Library_Plate;
use alDente::Sample;
# use alDente::Extraction_Sample;

##############################
# global_vars                #
##############################
##############################
# custom_modules_ref #
##############################
##############################
# global_vars #
##############################
use vars qw($testing $Security $project_dir $Web_log_directory);
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

##############################
# constructor                #
##############################

sub new {
########
    my $this  = shift;
    my $class = ref($this) || $this;

    my %args = @_;

    ### Connection parameters ###
    ### Mandatory ###
    my $dbase         = $args{-dbase        } || '';
    my $host          = $args{-host         } || $Defaults{SQL_HOST};    # Name of host on which database resides [String]
    my $LIMS_user     = $args{-LIMS_user    };                           # LIMS user name (NOT same as Database connection user name) [String]
    my $LIMS_password = $args{-LIMS_password};                           # LIMS password (NOT same as Database connection password) [String]
    my $DB_user       = $args{-DB_user      } || 'guest';                # Database connection username (NOT same as LIMS user)

    ### Common Options ###
    my $connect     = $args{-connect    };                               # Flag to indicate that connection should be made immediately
    my $quiet       = $args{-quiet      } || 0;                          # suppress printed feedback (defaults to 0) [Int]
    my $DB_password = $args{-DB_password} || '';                         # may supply Database password directly if known

    ### Advanced optional parameters ###
    my $driver     = $args{-driver     } || $Defaults{SQL_DRIVER} || 'mysql';   # SQL driver  [String]
    my $dsn        = $args{-dsn        };                                       # Connection string [String]
    my $trace      = $args{-trace_level} || 0;                                  # set trace level on database connection (defaults to 0) [Int]
    my $trace_file = $args{-trace_file } || 'Trace.log';                        # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $alias_file = $args{-alias_file } || "$config_dir/db_alias.conf";        # Location of DB alias file (optional) [String]
    my $alias_ref  = $args{-alias      };                                       # Reference to DB alias hash (optional). If passed in then overrides alias file [HashRef]

    if (!$dsn && $driver && $dbase && $host) {          # If DSN is not specified but all other info are provided, then we build a DSN.
        $dsn = "DBI:$driver:database=$dbase:$host";
    }

    ## Define connection attributes
    my $self = $this->SDB::DBIO::new( -dbase=>$dbase, -host=>$host, -user=>$DB_user, -password=>$DB_password );

    ###  Connection attributes ###
    $self->{sth   } = '';                                                 # Current statement handle [Object]
    $self->{dbase } = $dbase;                                             # Database name [String]
    $self->{host  } = $host;                                              # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver} = $driver;                                            # SQL driver [String]
    $self->{dsn   } = $dsn;                                               # Connection string [String]

    $self->{DB_user      } = $DB_user;
    $self->{LIMS_user    } = $LIMS_user;                                  # Login user name [String]
    $self->{LIMS_password} = $LIMS_password;                              # (MANDATORY unless login_file used) specification of password [String]

    $self->{trace     } = $trace;                                         # set trace level on database connection (defaults to 0) [Int]
    $self->{trace_file} = $trace_file;                                    # optional trace_file where trace info to be written. (required if trace_level set) [String]
    $self->{quiet     } = $quiet;                                         # suppress printed feedback (defaults to 0) [Int]

    if ($connect) {
        $self->connect_to_DB();
        $self->{isConnected} = 1;
    }
    else {
        $self->{isConnected} = 0;
    }

    return $self;
}

##############################
# public_methods             #
##############################

###########################
# Connect to database using either LIMS password or direct DB password
#
# <snip>
# Example:  $LIMS->connect_to_DB();  # LIMS_user, LIMS_password or DB_user, DB_password should have been sent to constructor
# </snip>
#
################
sub connect_to_DB {
################
    my $self = shift;
	
    ## required to use DIFFERENT password from login password to access database ##

    my $LIMS_user = $self->{LIMS_user};
    my $DB_user   = $self->{DB_user};
    my $DB_password;

    if ($self->{LIMS_user}) {
        $DB_password = $self->_password_check(-LIMS_user=>$LIMS_user,-LIMS_password=>$self->{LIMS_password},-DB_user=>$DB_user);
    }

    $self->connect(-password=>$DB_password);    ## will still allow login if original DB_password specified is correct ##

    my $dbc = $self->dbc();

    if ($dbc && $dbc->ping()) {
        $self->{isConnected} = $dbc;
        $self->{log_file   } = "$LOGPATH/API_usage.$DB_user-$LIMS_user.log";
    } else {
        $self->{isConnected} = 0;
        die "Connection to database failed : Aborting...\n";
    }
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
    my %args = &filter_input(\@_,-log=>$self->{log_file});
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

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
    my $updated;
    if (int(@fields)){ 
	$updated = $dbc->Table_update_array('Sample',\@fields,\@values,"WHERE Sample_ID = $sample_id",-autoquote=>1);
	
	unless ($quiet)
	{
	    print "Updated Sample $sample_id with fields (@fields) and values (@values)\n";
	}
    }
    else{
	print "No fields specified\n";
    }

    return $updated;
}

############################
# Allow users to get the Parent Sample ID of a Sample given a Sample ID
#
#
# <snip>
#  Example:
#  
#  for a single parent id: 
#  $API->get_ParentSampleID(-sample_id=>'2304561');
#  
#  for a list of sample IDs:
#   my %parent_samples=$API->get_ParentSampleID(-sample_list=>\@samples);
# </snip>
#
##############################
sub get_ParentSampleID {
##############################
    my $self = shift;
    my %args = &filter_input(\@_,-log=>$self->{log_file});

    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $dbc = $self->dbc();

    my $sample_id = $args{-sample_id}; #single sample
    my $sample_list = $args{-sample_list}; # list of samples

    #check for a single sample ID
    if ($sample_id){
	my ($parent_sample_id) = $dbc->Table_find('Sample',"FKParent_Sample__ID","WHERE Sample_ID = $sample_id");
	return $parent_sample_id;
    }
    #for a list of sample IDs

    my %parent_samples; # hash where the sample ID is the KEY and the value is the Parent Sample ID
 
    if ($sample_list){	 
 
   	   foreach my $sample (@$sample_list){
   	    
	       my ($parent_sample_id) = $dbc->Table_find('Sample',"FKParent_Sample__ID","WHERE Sample_ID = $sample");
   	  
	       $parent_samples{$sample} = $parent_sample_id;
   	   }			  
    }				  
  
    return %parent_samples;
}

#################################
# Allow User to Add an Attribute to the system
#
# <snip>
#  Example:
#   $API->add_Attribute(-attribute_name=>'Accession_ID', -attribute_format=>'Text', -group_name=>'Sequencing Lab', -inherited=>'Yes', -class =>'Sample');
#   $API->add_Attribute(-attribute_name=>'Accession_ID', -attribute_format=>'Text', -group=>3,-inherited=>'Yes', -class=>'Sample');
#
# </snip>
# Return: 1 on success
#####################
sub add_Attribute {
#####################
    my $self = shift;
    my %args = &filter_input(\@_,-log=>$self->{log_file});
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $attribute_name = $args{-attribute_name};         # Name
    my $attribute_format = $args{-attribute_format};     # describes the type/format of the attribute
    my $grp_id = $args{-group} || 0;                     # Group ID or group name OPTIONAL
    my $grp_name = $args{-group_name};                   # Optional
    my $attribute_class = $args{-class};                 # Mandatory Name of the Object (ie. Sample, Plate)
    my $inherited = $args{-inherited} || 'No';           # Whether or not the samples is inherited or not
    my $attribute_type = $args{-attribute_type};         # Type (Text, Enum)
    my $dbc = $self->dbc();

    if ($grp_name)
    {
	($grp_id) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = '$grp_name'");
    }
 
    my $quiet = $args{-quiet};							      
    											    
    							 
    my @fields = ('Attribute_Name','Attribute_Type','Attribute_Format','FK_Grp__ID', 'Attribute_Class','Inherited');		      
    my @values = ($attribute_name, $attribute_type, $attribute_format, $grp_id, $attribute_class, $inherited);			      
    unless ($attribute_name || $attribute_class)				      
    {		        							      
    	print "Attribute name or class must be specified\n";      
	return 0;								      
    }		        							      
    #$testing=1;	  
    my $added = $dbc->Table_append_array('Attribute',\@fields,\@values,-autoquote=>1);
    #$testing=0;	  
    
    return $added;
}

#################################
# Allow User to Add an Sample_Attribute to the system
#
# <snip>
#  Example:
#   $API->add_Sample_Attribute(-samples=>$sample_id,-attribute_info=>\%attribute);
#
#
#   Scenario 1:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   $attribute{2} = ['Accession_ID', 'NM001'];
#   my @samples = ['2881915','2885194'];
#   $API->add_Sample_Attribute(-sample_id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1}
#   Sample 2885194 gets attribute info from $attribute{2}
#
#   Scenario 2:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   
#   my @samples = ['2881915','2885194'];
#   $API->add_Sample_Attribute(-sample_id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1}
#   Sample 2885194 gets attribute info from $attribute{1}
#
#   Scenario 3:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   $attribute{2} = ['Accession_ID', 'NM001'];
#
#   my @samples = ['2881915'];
#   $API->add_Sample_Attribute(-sample_id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1} and $attribute(2)
#
#   The number of Samples and Attributes must be equal unless of them has only 1 value.
#
# </snip>
# Return: 1 on success
#####################
sub add_Sample_Attribute {
#####################
    my $self = shift;
    my %args = &filter_input(\@_,-log=>$self->{log_file});
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    
    my $sample_ids = $args{-sample_id};                   # Sample IDs

    
    my @sample_ids = Cast_List(-list=>$sample_ids,-to=>'Array');
    my $attribute_info = $args{-attribute_info};          # hash reference containing an the Attribute Name, Attribute Value, and Inherited Value

    
    
    my %attribute = ();
    
    if ($attribute_info) {%attribute = %$attribute_info;}
    my $sample_count = scalar(@sample_ids);
    print "Sample count: $sample_count\n";
    my $attribute_count = keys(%attribute);
    print "Attribute count: $attribute_count\n";

    my $dbc = $self->dbc();
   
    my $quiet = $args{-quiet};
    my @fields = ('FK_Sample__ID','FK_Attribute__ID','Attribute_Value');
    #print Dumper @sample_ids;
    

    if (($attribute_count == $sample_count) || ($attribute_count == 1 && $sample_count >1) || ($attribute_count>1 && $sample_count==1)){
    	   my $index = 1;
    	   foreach my $sample (@sample_ids)
    	   {
    	      
    	      my $attribute_name = $attribute{$index}[0];
    	      my $attribute_value = $attribute{$index}[1];
	      
    	      my ($attribute_id) = $dbc->Table_find('Attribute','Attribute_ID',"WHERE Attribute_Name = '$attribute_name'");
    	      unless ($sample && $attribute_id && $attribute_value)				      
    	      {		        							      
    	
		  return 0;								      
    	      }
    	      my @values = ($sample, $attribute_id, $attribute_value);
    	      # check if the attribute already exists 
	      my ($check_existing) = $dbc->Table_find('Sample_Attribute','FK_Sample__ID',"WHERE FK_Attribute__ID = $attribute_id AND FK_Sample__ID=$sample");
	      if ($check_existing) {
		  my $update = $dbc->Table_update('Sample_Attribute','Attribute_Value',$attribute_value,"WHERE FK_Attribute__ID = $attribute_id AND FK_Sample__ID=$sample", -autoquote=>1);
	      }
	      else {
		  #$testing=1;
		  my $added = $dbc->Table_append_array('Sample_Attribute',\@fields,\@values,-autoquote=>1);
		  #$testing=0;
	      }
    	      if ($attribute_count == 1){
    	     
    	      }
    	      else {
    		  $index++;
    	      }
    	  }
    }
    else {
	print "Number of samples do not match Number of attributes\n";
        return 0;
    }
     
    return 1;
}

#################################
# Allow User to get set inherited attributes 
#
# <snip>
#  Example:
#
#   $API->inherit_Attribute(-parent_id=>3421054,-child_ids=>3421055,-table=>'Sample');
#
#
# </snip>
# Return: 1 on success
sub inherit_Attribute {
    my $self = shift;
    my %args = &filter_input(\@_);
    my $dbc = $self->dbc();

    my $parent_id = $args{-parent_id}; # ie Parent Sample_ID
    my $child_ids = $args{-child_ids}; # ie Sample ID
    my @children =  Cast_List(-list=>$child_ids,-to=>'Array');

    my $table = $args{-table};  ## ie Sample
    my $fk_field =  foreign_key($table);
    #print Dumper $self->{primary_fields};
    
    ## get a list of inherited attributes for the table
    my @inherited_attributes = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Inherited = 'Yes' and Attribute_Class = '$table'");
    my $inherited_list = join ',', @inherited_attributes;
   
    $table .="_Attribute";
    #  get list of table attributes
    my @table_attributes = $dbc->Table_find( $table, 'FK_Attribute__ID, Attribute_Value', "WHERE $fk_field = $parent_id AND FK_Attribute__ID IN ($inherited_list)");

    if (@table_attributes){
    		 my @fields = ($fk_field,'FK_Attribute__ID','Attribute_Value');
    
    		 foreach my $child_id (@children) {
    		 
    		     foreach my $table_attribute (@table_attributes){
    			 my ($attribute_id, $attribute_value) = split ',',$table_attribute;
    	      
    			 my @values = ($child_id, $attribute_id, $attribute_value);	  

			
			 my @check_exists =$dbc->Table_find( $table, 'FK_Attribute__ID, FK_Sample__ID',"WHERE $fk_field = $child_id and FK_Attribute__ID=$attribute_id");

			 if (@check_exists){
			  
			 }
			 else{
			   my $added = $dbc->Table_append_array($table,\@fields,\@values,-autoquote=>1);
			 }
		     }
    		 }
    }
    else{
    		 return 0;
    }

    return 1;
}

#################################
# Allow User to get a Sample_Attribute from the system
#
# <snip>
#  Example:
#
#  Get a hash containing the sample id and specified attribute name
#  my %hash = $API->get_Sample_Attribute(-sample_id=>\@samples, -attribute_name=>'Accession_ID');
#
#  Get a hash containing all the attributes for each sample id
#  my %hash = $API->get_Sample_Attribute(-sample_id=>\@samples);
#
#
# </snip>
# Return: HofH
#####################
sub get_Sample_Attribute {
    my $self = shift;
    my %args = &filter_input(\@_);
    my $dbc = $self->dbc();
    my $sample_ids = $args{-sample_id}; ## Sample ID's
    my $attribute_name = $args{-attribute_name}; ## Attribute Names
    
    unless ($sample_ids)
    {
	return 0;
    }
    
    my @sample_ids = Cast_List(-list=>$sample_ids,-to=>'Array');
    my $sample_list = join ',', @sample_ids;
    
    my $condition="WHERE FK_Sample__ID IN ($sample_list)";

    if ($attribute_name)
    {
	my ($attribute_id) = $dbc->Table_find('Attribute','Attribute_ID',"WHERE Attribute_Name = '$attribute_name'");	
	$condition .=" AND FK_Attribute__ID = $attribute_id";
    }

    my @sample_attributes = $dbc->Table_find( 'Sample_Attribute', 'FK_Sample__ID,FK_Attribute__ID, Attribute_Value', $condition);

    my %sample_attribs=();

   
    my $index =1;
    foreach my $sample_attribute(@sample_attributes) {
	my ($sample_id,$attribute_id,$attribute_value) = split ',' , $sample_attribute;
	my ($attribute_name) =  $dbc->Table_find('Attribute','Attribute_Name',"WHERE Attribute_ID = $attribute_id");
	my %values = (Sample_ID=>$sample_id,Attribute_Name=>$attribute_name, Attribute_Value=>$attribute_value);
	$sample_attribs{$index} = \%values; 
	#print "attrib name:$attribute_name, attrib value: $attribute_value, inherit: $inherited\n";
	$index++;
    }
    #print Dumper %sample_attribs;
    return %sample_attribs;
}

#################################
# Allow User to get an Attribute from the system
#
# <snip>
#  Example:
#
#  Get a hash of hashes containing Attribute_ID,Attribute_Name,Attribute_Class,Inherited, Attribute_Format
#  my %hash = $API->get_Attribute(-attribute_name=>'Accession_ID');
#  my %hash = $API->get_Attribute(-attribute_name=>\@attribute_names);
# 
#
#
# </snip>
# Return: HofH
#####################
sub get_Attribute {
    my $self = shift;
    my %args = &filter_input(\@_);
    my $dbc = $self->dbc();
    my $attribute_id = $args{-attribute_id}; ## Mandatory: attribute ID or list of attribute ID's
    my $attribute_name = $args{-attribute_name}; ## OR OPTIONALLY an attribute name or list of attribute names
  
    my @attribute_ids = Cast_List(-list=>$attribute_id,-to=>'Array');
   
    my $name_list = Cast_List(-list=>$attribute_name,-to=>'String', -autoquote=>1);
    
    #print Dumper @attribute_names;
    if ($attribute_name)
    {		    
   	   @attribute_ids = $dbc->Table_find('Attribute','Attribute_ID',"WHERE Attribute_Name IN ($name_list)");	
   		       
    }		    
    my $attrib_list = join ',',@attribute_ids;
   		       
   		       
    my %attributes = Table_retrieve($dbc,'Attribute',['Attribute_ID','Attribute_Name','Attribute_Class','Inherited', 'Attribute_Format'],"WHERE Attribute_ID IN ($attrib_list)");
    return %attributes;
	    

}

#################################
# Allow User to Add an Sample_Attribute to the system
#
# <snip>
#  Example:
#   $API->add_Table_Attribute(-table=>'Sample',-id=>@samples,-attribute_info=>\%attribute);
#
#   Scenario 1:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   $attribute{2} = ['Accession_ID', 'NM001'];
#   my @samples = ['2881915','2885194'];
#   $API->add_Table_Attribute(-table=>'Sample',-id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1}
#   Sample 2885194 gets attribute info from $attribute{2}
#
#   Scenario 2:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   
#   my @samples = ['2881915','2885194'];
#   $API->add_Table_Attribute(-table=>'Sample',-id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1}
#   Sample 2885194 gets attribute info from $attribute{1}
#
#   Scenario 3:
#   
#   my %attribute;
#   $attribute{1} = ['Size Estimate','1224'];
#   $attribute{2} = ['Accession_ID', 'NM001'];
#
#   my @samples = ['2881915'];
#   $API->add_Table_Attribute(-table=>'Sample',-id=>@samples,-attribute_info=>\%attribute);
#
#   Sample 2881915 gets attribute info from $attribute{1} and $attribute(2)
#
#   The number of Samples and Attributes must be equal unless of them has only 1 value.
#
# </snip>
# Return: 1 on success
#####################
sub add_Table_Attribute {
#####################
    my $self = shift;
    my %args = &filter_input(\@_,-log=>$self->{log_file});
    if ($args{ERRORS}) { Message("Input Errors Found: $args{ERRORS}"); return; }

    
    my $ids = $args{-id}; ## ID of the Table object ie FK_Sample__ID 
    my $table = $args{-table}; ## Table Name (ie Sample or Original_Source)
    
    my @ids = Cast_List(-list=>$ids,-to=>'Array');
    my $attribute_info = $args{-attribute_info};          # hash reference containing an the Attribute Name, Attribute Value, and Inherited Value

    my $fk_field =  foreign_key($table);
    
    my %attribute = ();
    
    if ($attribute_info) {%attribute = %$attribute_info;}
    my $count = scalar(@ids);
    print "ID count: $count\n";
    my $attribute_count = keys(%attribute);
    print "Attribute count: $attribute_count\n";

    my $dbc = $self->dbc();
   
    my $quiet = $args{-quiet};
    my @fields = ($fk_field,'FK_Attribute__ID','Attribute_Value');

    if (($attribute_count == $count) || ($attribute_count == 1 && $count >1) || ($attribute_count>1 && $count==1)){
    	   my $index = 1;
    	   foreach my $id (@ids)
    	   {
    	      
    	      my $attribute_name = $attribute{$index}[0];
    	      my $attribute_value = $attribute{$index}[1];
	      
    	      my ($attribute_id) = $dbc->Table_find('Attribute','Attribute_ID',"WHERE Attribute_Name = '$attribute_name'");
    	      unless ($id && $attribute_id && $attribute_value)				      
    	      {		        							      
    	
		  return 0;								      
    	      }
    	      my @values = ($id, $attribute_id, $attribute_value);
    	      # check if the attribute already exists 
	      my ($check_existing) = $dbc->Table_find($table."_Attribute",$fk_field,"WHERE FK_Attribute__ID = $attribute_id AND $fk_field=$id");
	      if ($check_existing) {
		  my $update = $dbc->Table_update($table."_Attribute",'Attribute_Value',$attribute_value,"WHERE FK_Attribute__ID = $attribute_id AND $fk_field=$id", -autoquote=>1);
	      }
	      else {
		  #$testing=1;
		  my $added = $dbc->Table_append_array($table ."_Attribute",\@fields,\@values,-autoquote=>1);
		  #$testing=0;
	      }
    	      if ($attribute_count == 1){
    	     
    	      }
    	      else {
    		  $index++;
    	      }
    	  }
    }
    else {
	print "Number of samples do not match Number of attributes\n";
        return 0;
    }
     
    return 1;
}

#################################
# Allow User to get a table attribute from the system ie (from the table Sample_Attribute)
#
# <snip>
#  Example:
#
#  Get a hash containing the sample id and specified attribute name
#  my %hash = $API->get_Table_Attribute(-table=>'Sample',-id=>\@samples, -attribute_name=>'Accession_ID');
#
#  Get a hash containing all the attributes for each sample id
#  my %hash = $API->get_Table_Attribute(-table=>'Sample',-id=>\@samples);
#
#
# </snip>
# Return: HofH
#####################
sub get_Table_Attribute {
    my $self = shift;
    my %args = &filter_input(\@_);
    my $dbc = $self->dbc();
    my $ids = $args{-id}; ## ID of the Table object ie FK_Sample__ID 
    
    my $attribute_name = $args{-attribute_name}; ## Attribute Names
    my $table = $args{-table}; ## Table Name (ie Sample or Original_Source)
    my $fk_field =  foreign_key($table);
    unless ($ids)
    {
	return 0;
    }
    
    my @ids = Cast_List(-list=>$ids,-to=>'Array');
    my $id_list = join ',', @ids;
    
    my $condition="WHERE $fk_field IN ($id_list)";

    if ($attribute_name)
    {
	my ($attribute_id) = $dbc->Table_find('Attribute','Attribute_ID',"WHERE Attribute_Name = '$attribute_name'");	
	$condition .=" AND FK_Attribute__ID = $attribute_id";
    }

    my @table_attributes = $dbc->Table_find( $table."_Attribute", "$fk_field,FK_Attribute__ID, Attribute_Value", $condition);

    my %table_attribs=();

   
    my $index =1;
    foreach my $table_attribute(@table_attributes) {
	my ($id,$attribute_id,$attribute_value) = split ',' , $table_attribute;
	my ($attribute_name) =  $dbc->Table_find('Attribute','Attribute_Name',"WHERE Attribute_ID = $attribute_id");
	my %values = (ID=>$id,Attribute_Name=>$attribute_name, Attribute_Value=>$attribute_value);
	$table_attribs{$index} = \%values; 
	#print "attrib name:$attribute_name, attrib value: $attribute_value, inherit: $inherited\n";
	$index++;
    }

    return %table_attribs;
}

### TEMPORARY Script DO NOT USE
sub fix_pcr_plates {
  my $self = shift;
  my $dbc = $self->dbc();
    my $new_plate_ids = '74289,74290,74449,74666';
    my ($first_plate_id) = $new_plate_ids =~ /^(\d+)/;
    my $new_plate_count = 0;
    
    print $new_plate_ids;
    foreach my $new_plate_id (split /,/, $new_plate_ids) {
	#print $new_plate_id;
	#my $name = get_FK_info($dbc,'FK_Plate__ID',$new_plate_id);
	my $returnval;
        # Get plate size of the newly create plate
        #$testing=1;
	my ($plate_size) = $dbc->Table_find('Plate,Plate_Format','Wells',"WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID=$new_plate_id");
        #$testing=0;
	$plate_size =~ s/(\d+)/$1/i;
	print "plate_size: $plate_size";
        my $sub_quadrants;
        if ($plate_size =~ /384/) {$sub_quadrants = "a,b,c,d"}
        else {$sub_quadrants = ""}

        # Create the Library_Plate record
        $returnval = $dbc->Table_append_array('Library_Plate',['FK_Plate__ID','Plate_Class','Sub_Quadrants'],[$new_plate_id,'Standard',$sub_quadrants],-autoquote=>1);
	print $returnval;
        my $Plate = alDente::Library_Plate->new(-dbc=>$dbc,-id=>$returnval);
        my $plate_id = $Plate->value('Plate.Plate_ID');    ## (returnval is Library_Plate_ID )
        
        # insert original plate id (pointing to itself)
        $dbc->Table_update_array("Plate",["FKOriginal_Plate__ID"],["$plate_id"],"WHERE Plate_ID=$plate_id");

        ### set plate size based on plate format ###
        my ($size) = $dbc->Table_find('Plate,Plate_Format','Wells',"WHERE FK_Plate_Format__ID=Plate_Format_ID AND Plate_ID = $plate_id");
        $Plate->update(-fields=>['Plate.Plate_Size','Library_Plate.Parent_Quadrant','Plate_Type'],-values=>["$size-well",'','Library_Plate']);

        ### set unused wells if sub_quadrants chosen ###
        if (param('Sub_Quadrants')) {
    	my $sub_quadrants = join ',', param('Sub_Quadrants');
    	unless ($sub_quadrants =~/a,b,c,d/) {
    	    $Plate->reset_SubQuadrants(-quadrants=>$sub_quadrants);
    	    print "Reset subquadrants for $returnval to $sub_quadrants (rest marked as unused)";
    	}
        }	    	    
	#$testing=1;
        my ($newplate) = $dbc->Table_find('Library_Plate,Plate','FK_Plate__ID,FKParent_Plate__ID,FK_Library__Name,Plate.Plate_Number,Library_Plate.Parent_Quadrant,Plate.Plate_Size,Plate.FK_Sample_Type__ID',"where FK_Plate__ID=Plate_ID AND Library_Plate_ID=$returnval");
        #$testing=0;
	($plate_id,my $parent,my $lib,my $number,my $quad,$size, my $sample_type) = split ',', $newplate;
        if ($plate_id) {
   # 	my ($rearrayed) = $dbc->Table_find('ReArray_Request','count(*)',"where FKTarget_Plate__ID = $plate_id");
    #	if ($rearrayed) { $Transaction->message("Rearrayed Plate Detected : link to Clone") }
    	#else {  
    	    #$Transaction->message("Saved extraction info for plate $new_plate_id");
    	    #print br;
    	    	   ## Check if the extraction is a plate or a tube (added in later development)
    	    # for Extraction_Samples:  create Clone_Sample, Plate_Sample, and Sample records as necessary
    	    my $RNA_Sample = SDB::DB_Object->new(-dbc=>$dbc,-tables=>'Sample');
    	    my $condition;
    	    my $well_field; 

    	    if ($plate_size =~ /96/) { $well_field='Plate_96'; $condition="WHERE Quadrant='a'"; }
    	    elsif ($plate_size =~ /384/) { $well_field = 'Plate_384'; $condition=''; }
    	    my %Map;
    	    my @wells;
    	    map { 
    		my ($well,$quad) = split ',', $_;
    		$well = &format_well($well);
    		push(@wells,$well);
    		$Map{$well} = $quad;
    	    } $dbc->Table_find('Well_Lookup',"$well_field,Quadrant","$condition");
	    print Dumper @wells;
    	    foreach my $i (0..$#wells) {
    		my $well = $wells[$i];
		print $well;
    		my $quad = $Map{$well};    ## Store Quadrant for 384 well plates as well...
  
            ## FORCE TO DNA
            $sample_type = 'DNA';  ## <CONSTRUCTION> - why is this forced ... 
            
    		$RNA_Sample->values(-fields=>['Sample.Sample_Name','Sample.FKOriginal_Plate__ID','Sample.Plate_Number','Sample.FK_Library__Name','Sample.FK_Sample_Type__ID', 'Sample.Original_Well'],
    		    -values=>["$lib-$number\_$well",$plate_id,$number,$lib,$sample_type,$well],-index=>$i);
    	    }
    	    #print Dumper($RNA_Sample);
    	    $RNA_Sample->insert();
    	    #my ($sample_id) = @{$RNA_Sample->newids('Sample')};
    	    #my ($rna_sample_id) = @{$RNA_Sample->newids('Extraction_Sample')};

    	    ## ADD INFORMATION ABOUT PLATE_SAMPLE
    	    # retrieve information set in Extraction_Sample
	    #$testing=1;
    	    my @plate_sample_rows = $dbc->Table_find('Sample','Sample_ID, Original_Well',"WHERE FKOriginal_Plate__ID=$plate_id");
    	    #$testing=0;
	    my %plate_sample_info;
    	    my $index = 1;
    	    foreach my $row (@plate_sample_rows) 
    	    {
    		my ($sample_id, $well) = split ',',$row;
    		# fill in plate sample information
    		$plate_sample_info{$index} = [$plate_id,$sample_id,$well];
    		$index++;
    	    }
    	    # use smart_append to add plate samples
#    	    print Dumper %plate_sample_info;
	    my $ok = $dbc->smart_append(-tables=>'Plate_Sample',-fields=>['FKOriginal_Plate__ID','FK_Sample__ID','Well'],-values=>\%plate_sample_info,-autoquote=>1);
    	    if (!$ok) {
    		print "Failed to insert to Plate_Sample table!";
    	    }
    	    else {
    		#$Transaction->message("Added Plate Sample entries");
		print "plates added";
    	    }
    	    
    
        
       
	}
	$new_plate_count++;
    }
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

2004-11-29

=head1 REVISION <UPLINK>

$Id: alDente_Tools.pm,v 1.16 2004/12/09 17:40:42 rguin Exp $ (Release: $Name:  $)

=cut


return 1;
