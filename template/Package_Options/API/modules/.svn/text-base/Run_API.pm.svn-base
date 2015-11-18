################################################################################
# Run_API.pm
#
# This module handles custom data access functions for the solexa plug-in
#
###############################################################################
package Run_API;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Run_API.pm - This module handles custom data access functions for the TemplateRun plug-in

=head1 SYNOPSIS <UPLINK>
 
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

        my $solexa_data = $web_service_client->call('lims_web_service.get_solexa_run_data',$valid_login,
                                                         {
                                                         'flowcell' => 'FC123',
                                                         }) -> result;
        print Dumper $data;



        Python Example:
        
        #!/usr/local/bin/python

        from xmlrpclib import ServerProxy

        limsy = ServerProxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl")

        login = limsy.lims_web_service.login( {'username':'testlims','password':'testlims'} )

        data = limsy.lims_web_service.get_solexa_run_data(login,{'flowcell':'FC123' })

        print data


NOTE:  The api arguments passed into the web service are equivalent to those passed directly to the API
=head1 DESCRIPTION <UPLINK>

=for html
This module handles custom data access functions for the SolexaRun plug-in<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw( alDente::alDente_API );

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
use Carp;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;
use alDente::alDente_API;
use SDB::HTML;

##############################
# global_vars                #
##############################
##############################
# custom_modules_ref #
##############################
##############################
# global_vars #
##############################
use vars qw(
            $AUTOLOAD          $testing
            $Security          $project_dir
            $Web_log_directory $Connection
            %Aliases
          );
## declare Aliases here
# like:
# $Aliases{SolexaRun}{flowcell_code   } = "Flowcell.Flowcell_Code";

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################

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
    my $dbase           = $args{-dbase} || '';
    my $host            =  $args{-host} || $Defaults{SQL_HOST};                 # Name of host on which database resides [String]
    my $LIMS_user       = $args{-LIMS_user};                                    # LIMS user name (NOT same as Database connection user name) [String]
    my $LIMS_password   = $args{-LIMS_password};                                # LIMS password (NOT same as Database connection password) [String]
    my $DB_user         = $args{-DB_user} || 'guest';                           # Database connection username (NOT same as LIMS user)
    
    ### Common Options ###
    my $connect         = $args{-connect};                                      # Flag to indicate that connection should be made immediately
    my $quiet           = $args{-quiet} || 0;                                   # suppress printed feedback (defaults to 0) [Int]
    my $DB_password     = $args{-DB_password} || '';                            # may supply Database password directly if known       
    
    ### Advanced optional parameters ###
    my $driver          = $args{-driver} || $Defaults{SQL_DRIVER} || 'mysql';   # SQL driver  [String]
    my $dsn             = $args{-dsn};                                          # Connection string [String]
    my $trace           = $args{-trace_level} || 0;                             # set trace level on database connection (defaults to 0) [Int]
    my $trace_file      = $args{-trace_file} || 'Trace.log';                    # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $alias_file      = $args{-alias_file} || "$config_dir/db_alias.conf";    # Location of DB alias file (optional) [String]
    my $alias_ref       = $args{-alias};                                        # Reference to DB alias hash (optional). If passed in then overrides alias file [HashRef]
    my $debug           = $args{-debug};

    if (!$dsn && $driver && $dbase && $host) {          
                                                                                # If DSN is not specified but all other info are provided, then we build a DSN.
	$dsn = "DBI:$driver:database=$dbase:$host";
    }
    
    ## Define connection attributes
    my $self = $this->alDente::alDente_API::new(%args);
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
    
    $self -> add_custom_aliases (-custom_aliases=>\%Aliases);
      
    return $self;
}



##############################
# main_header                #
##############################



##############################
# public_methods             #
##############################


##############################
sub get_Template_run_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);

} 

##############################
sub get_Atomic_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input(\@_);
    return $self-> get_Template_run_data (%args);
}

return 1;
