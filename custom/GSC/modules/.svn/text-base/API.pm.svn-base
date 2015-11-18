###################################################################################################################################
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package GSC::API;

use base alDente::alDente_API;
use strict;

## Standard modules ##
use CGI qw(:standard);
use LampLite::Bootstrap();
use Data::Dumper;
use Benchmark;
use Carp;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;
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
$Aliases{BCR_Study}{bcr_study_name}            = "BCR_Study.BCR_Study_Name";
$Aliases{BCR_Study}{bcr_study_code}            = "BCR_Study.BCR_Study_Code";
$Aliases{BCR_Batch}{bcr_supplier_organization} = "BCR_Organization.Organization_Name";
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
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = &filter_input( \@_ );
    if ( $args{ERROR} ) { Message( $args{ERROR} ); return; }

    ### Connection parameters ###
    ### Mandatory ###
    my $dbase = $args{-dbase} || '';
    my $host  = $args{-host}  || $Defaults{SQL_HOST};    # Name of host on which database resides [String]
    my $LIMS_user     = $args{-LIMS_user};               # LIMS user name (NOT same as Database connection user name) [String]
    my $LIMS_password = $args{-LIMS_password};           # LIMS password (NOT same as Database connection password) [String]
    my $DB_user       = $args{-DB_user} || 'guest';      # Database connection username (NOT same as LIMS user)

    ### Common Options ###
    my $connect     = $args{ -connect };                 # Flag to indicate that connection should be made immediately
    my $quiet       = $args{-quiet} || 0;                # suppress printed feedback (defaults to 0) [Int]
    my $DB_password = $args{-DB_password} || '';         # may supply Database password directly if known

    ### Advanced optional parameters ###
    my $driver     = $args{-driver} || $Defaults{SQL_DRIVER} || 'mysql';    # SQL driver  [String]
    my $dsn        = $args{-dsn};                                           # Connection string [String]
    my $trace      = $args{-trace_level} || 0;                              # set trace level on database connection (defaults to 0) [Int]
    my $trace_file = $args{-trace_file} || 'Trace.log';                     # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $alias_file = $args{-alias_file} || "$config_dir/db_alias.conf";     # Location of DB alias file (optional) [String]
    my $alias_ref  = $args{-alias};                                         # Reference to DB alias hash (optional). If passed in then overrides alias file [HashRef]
    my $debug      = $args{-debug};

    if ( !$dsn && $driver && $dbase && $host ) {

        # If DSN is not specified but all other info are provided, then we build a DSN.
        $dsn = "DBI:$driver:database=$dbase:$host";
    }

    ## Define connection attributes
    my $self = $this->alDente::alDente_API::new(%args);
    bless $self, $class;

    ###  Connection attributes ###
    $self->{sth}    = '';         # Current statement handle [Object]
    $self->{dbase}  = $dbase;     # Database name [String]
    $self->{host}   = $host;      # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver} = $driver;    # SQL driver [String]
    $self->{dsn}    = $dsn;       # Connection string [String]

    $self->{DB_user}       = $DB_user;
    $self->{DB_password}   = $DB_password;
    $self->{LIMS_user}     = $LIMS_user;        # Login user name [String]
    $self->{LIMS_password} = $LIMS_password;    # (MANDATORY unless login_file used) specification of password [String]

    $self->{trace}      = $trace;               # set trace level on database connection (defaults to 0) [Int]
    $self->{trace_file} = $trace_file;          # optional trace_file where trace info to be written. (required if trace_level set) [String]
    $self->{quiet}      = $quiet;               # suppress printed feedback (defaults to 0) [Int]

    $self->add_custom_aliases( -custom_aliases => \%Aliases );

    return $self;
}

##############################
# main_header                #
##############################

##############################
# public_methods             #
##############################

##############################
sub get_bcr_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );

#select External_Identifier, BCR_Batch_ID,BCR_Study_Name,BCR_Study_Code,RNA_DNA_Isolation_Method from RNA_DNA_Source,Source_Attribute,Attribute,Source,Project,BCR_Batch,BCR_Study where FKReference_Project__ID = Project_ID and Project_Name = 'TCGA' and Source_Attribute.FK_Source__ID = Source_ID and Source_Attribute.FK_Attribute__ID = Attribute_ID and Attribute_Name = 'BCR_Batch' and Attribute_Value = BCR_Batch_ID and BCR_Study_ID = FK_BCR_Study__ID  and RNA_DNA_Source.FK_Source__ID = Source_ID and External_Identifier <> ''
    my $tables = "Original_Source,Source_Attribute,Attribute,Source,Project,BCR_Batch,BCR_Study";
    my $condition
        = "FKReference_Project__ID = Project_ID and Project_Name = 'TCGA' and Source_Attribute.FK_Source__ID = Source_ID and Source_Attribute.FK_Attribute__ID = Attribute_ID and Attribute_Name = 'BCR_Batch' and Attribute_Value = BCR_Batch_ID and BCR_Study_ID = FK_BCR_Study__ID AND Attribute_Name = 'BCR_Batch'";
    my $left_join_conditions = { 'Organization as BCR_Organization' => 'BCR_Batch.FKSupplier_Organization__ID  = BCR_Organization.Organization_ID', };
    return $self->get_source_data( %args, -tables => $tables, -condition => $condition, -input_left_joins => $left_join_conditions );
}
##########################
sub determine_genome_reference {
##########################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_, -mandatory => 'library' );

    require GSC::GSC;

    my $gsc_obj = GSC::GSC->new( -dbc => $self );

    return $gsc_obj->determine_genome_reference(%args);
}

1;
