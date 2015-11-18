#!/home/echuah/build_perl/perl-5.18.2/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl";
use lib $FindBin::RealBin . "/../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../lib/perl/custom";
use lib $FindBin::RealBin . "/../../lib/perl/Plugins";
use SDB::DBIO;

use RGTools::RGIO;
use Data::Dumper;
use YAML;
use JSON;
use MIME::Base32;
use SDB::CustomSettings;
use Net::LDAP;
use vars qw($web_service_user $valid_LIMS_user $valid_LIMS_password %Configs);
my $default_dbase = $Configs{BACKUP_DATABASE};
my $default_host  = $Configs{BACKUP_HOST};

use Dancer2;
use Dancer2::Plugin::Emailesque;
use Dancer2::Plugin::Database;
use Dancer2::Session::Memcached;
use Crypt::PBKDF2;
use Cache::Memcached;

my $memd = new Cache::Memcached {
  'servers' => [ "lims11:11211" ],
  'debug' => 0,
  'compress_threshold' => 10_000,
};

#set 'session'      => 'Memcached';
set 'template'     => 'template_toolkit';
set 'logger'       => 'file';
set 'log'          => 'core';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set layout => 'main';

# caching pages' response
  
#check_page_cache;

my $flash;

###################################################################################################################################
#
#API Methods start here
#
###################################################################################################################################

sub _get_LDAP_authentication {
    my %args = @_;

    my $username = $args{-username};
    my $password = $args{-password};
    my $server   = $args{-server};          # (Scalar) URL of the LDAP server
    my $port     = $args{-port} || 389;     # (Scalar) LDAP server port. Defaults to 389.
    my $ver      = $args{-version} || 3;    # (Scalar) LDAP server version. Defaults to 3.
    my $access;

    # connect to LDAP
    my $ldap = Net::LDAP->new( $server, port => $port, version => $ver ) or return undef;

    # try to bind with the given username and password.
    # if this fails, then the password is incorrect

    my $err = $ldap->bind( "uid=$username,ou=Webusers,dc=bcgsc,dc=ca", password => $password );

    if ( $err->code ) {                     # if a failure occurs (non-zero return), then authentication failed
        return undef;
    }
    else {
        my $mesg = $ldap->search( base => "cn=Webgroups,ou=Groups,dc=bcgsc,dc=ca", attrs => ['gsc_employee'], filter => "(uid=$user)", scope => 'one' );
        if ( $mesg->code ) {                # This makes Net::LDAP get the server response. If this returns true, then there has been a problem
            return undef;
        }

        # retrieve available information from LDAP
        my $rethash = $mesg->as_struct();

        # get the stored name
        my $name = $rethash->{"uid=$username,ou=Webusers,dc=bcgsc,dc=ca"}{'cn'}[0];

        # get the stored email
        my $email = $rethash->{"uid=$username,ou=Webusers,dc=bcgsc,dc=ca"}{'mail'}[0];

        # unbind from LDAP
        $ldap->unbind();

        # return the name and email
        return 1;
    }
}

sub _setup_web_service_method {
    my $login = shift;
    my $args  = shift;
    my %args  = %{$args};

    unless ( ref $args eq 'HASH' ) {
        return { error_reason => 'Arguments must be supplied in hash' };
    }
    unless ( login_validation($login) ) {
        return { error_reason => 'No permission to use this method' };
    }
    if ( $args{help} ) {
        return _help();
    }
    ## Make sure that the api will work with a dash or un-dashed key
    my %filtered_args;
    foreach my $arg ( keys %args ) {
        if ( $arg =~ /^\-/ ) {

            $filtered_args{$arg} = $args{$arg};
        }
        else {
            $filtered_args{"-$arg"} = $args{$arg};
        }
    }
    $filtered_args{'-sessionless'} = 1;
    $filtered_args{'-quiet'}       = 1;
    return \%filtered_args;
}
 
sub _load_API {
    my %args          = @_;
    my $api_type      = $args{-api_type} || "Sequencing::Sequencing_API";
    my $module        = $args{-module} || "Sequencing_API";
    my $host          = $args{-host} || $default_host;
    my $dbase         = $args{-dbase} || $default_dbase;
    my $db_user       = $args{-db_user} || 'viewer';
    my $db_password   = $args{-db_password} || 'viewer';
    my $lims_user     = $args{-lims_user} || $valid_LIMS_user;
    my $lims_password = $args{-lims_password} || $valid_LIMS_password;

    eval "require $api_type";

    my $API = $module->new(
        -dbase            => $dbase,
        -host             => $host,
        -DB_user          => $db_user,
        -DB_password      => $db_password,
        -LIMS_user        => $lims_user,
        -LIMS_password    => $lims_password,
        -web_service_user => $web_service_user,
        -quiet            => 1,
    );
    $API->connect( -sessionless => 1 );
    $API->connect_to_DB();
    return $API;
}

sub login_validation {
    my $login = shift;
    my $type  = shift;
    if ( !ref $login ) {
        $login = MIME::Base32::decode($login);
        $login = YAML::thaw($login);
    }

    if ( $type && $login->{user_type} eq $type ) { return 1 }
    elsif ($type) { return 0 }

    #if ($login->{access} == 1) {
    my $ok = 0;
    if ( $login->{LIMS_access} && $login->{login_LIMS_user} && $login->{login_LIMS_password} ) {
        $valid_LIMS_user     = $login->{login_LIMS_user};
        $valid_LIMS_password = $login->{login_LIMS_password};
        $ok                  = 1;
    }
    if ( $login->{access} && $login->{login_username} && $login->{login_password} ) {
        $web_service_user = $login->{login_username};
        $ok               = 1;
    }
    if ($ok) {
        $default_dbase = $login->{database} if $login->{database};
        $default_host  = $login->{host}     if $login->{host};
    }
    return $ok;
}

sub get_projects {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $args     = shift;
	my $login = MIME::Base32::decode($args);
	$login = YAML::thaw($login);
    my $username = $login->{username};
    my @project_ids;
                
    my $dbc       = SDB::DBIO->new(
        -dbase    => config->{plugins}->{Database}->{database},
        -host     => config->{plugins}->{Database}->{host},
        -user     => 'viewer',
        -password => 'viewer',
    );
    $dbc->connect( -sessionless => 1 );

    ## Check the user type,	IF they are a collaborator
    #if ($login->{user_type} eq 'Collaborator') {
    if ( login_validation( $login, 'Collaborator' ) ) {
        @project_ids = $dbc->Table_find( 'Collaboration,Contact', 'FK_Project__ID', "WHERE Canonical_Name = '$username' and FK_Contact__ID = Contact_ID" );
        $dbc->disconnect(); 
        unless (@project_ids) {
            return { errors => 1, error_reason => "No projects associated with Collaborator" };
        }

    }
    elsif ( $login->{user_type} eq 'Internal' ) {
        $dbc->disconnect(); 
        ##
    }
    else {
        $dbc->disconnect(); 
        return { errors => 1, error_reason => "Undefined User Type" };
    }
    my %projects;
    $dbc->disconnect(); 

    $projects{project_ids} = \@project_ids;

    return \%projects;
}
## <CONSTRUCTION>
sub get_project_details {

}

sub get_run_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                    ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_run_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_library_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                        ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_library_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_pipeline_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                         ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_pipeline_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_read_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                     ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_read_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_rearray_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                       ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_rearray_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_source_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                      ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_source_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_source_lineage {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                          ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_source_lineage(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_sample_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                      ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_sample_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_application_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                           ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_application_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_Primer_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                                                     ## the arguments for the API
    my $API           = _load_API( -api_type => 'Sequencing::Sequencing_API', -module => 'Sequencing_API' );
    my $api_results   = $API->get_Primer_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_goal_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                    ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_goal_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_control_type_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                            ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_control_type_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_plate_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                     ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_plate_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_plate_lineage {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                         ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_plate_lineage(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_SAGE_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};                                    ## the arguments for the API
    my $API           = _load_API(%filtered_args);
    my $api_results   = $API->get_SAGE_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_solexa_run_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'Illumina::Solexa_API',
        -module        => 'Solexa_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->get_solexa_run_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_SOLID_run_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'SOLID::SOLID_API',
        -module        => 'SOLID_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->get_SOLID_run_data( %filtered_args, -fatal => 1 );

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_event_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );
    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my $API           = _load_API( -api_type => 'alDente::alDente_API', -module => 'alDente::alDente_API' );
    my %filtered_args = %{$setup_results};                                                                     ## the arguments for the API
    my $api_results   = $API->get_event_data( %filtered_args, -fatal => 1 );
    $API->DESTROY();
    return $api_results;
}

sub create_rearray {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API
    my $API           = _load_API(
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->create_rearray(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_solexa_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'Illumina::Solexa_API',
        -module        => 'Solexa_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_solexa_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub add_work_request {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->add_work_request(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub start_run_analysis {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->start_run_analysis(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub create_run_analysis_batch {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->create_run_analysis_batch(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub finish_run_analysis {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->finish_run_analysis(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_flowcell_index {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'Illumina::Solexa_API',
        -module        => 'Solexa_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_flowcell_index(%filtered_args);

    $API->DESTROY();
    return $api_results;
}

sub set_attribute {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_attribute(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_run_comments {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_run_comments(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_multiplex_run_analysis_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_multiplex_run_analysis_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_multiplex_run_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_multiplex_run_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_sample_origin_type_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_sample_origin_type_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_original_reagents {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_original_reagents(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_alias_info {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_alias_info(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_run_analysis_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_run_analysis_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_genome_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_genome_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_genome_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->set_genome_data(%filtered_args);

    $API->DESTROY();
    return $api_results;
}

sub add_genome {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->add_genome(%filtered_args);

    $API->DESTROY();
    return $api_results;
}

sub get_analysis_software_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_analysis_software_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_anatomic_site_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_anatomic_site_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_work_request_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_work_request_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_submission_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my $API = _load_API();

    my %filtered_args = %{$setup_results};                           ## the arguments for the API
    my $api_results   = $API->get_submission_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_submission_volume_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my $API = _load_API();

    my %filtered_args = %{$setup_results};                                  ## the arguments for the API
    my $api_results   = $API->get_submission_volume_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_incomplete_analysis_libraries {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_incomplete_analysis_libraries(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub mapping_api {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my %filtered_args = %{$setup_results};    ## the arguments for the API
    my $API           = _load_API(
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user} || $filtered_args{-LIMS_user},
        -lims_password => $filtered_args{-lims_password} || $filtered_args{-LIMS_password},
        -host          => $filtered_args{-host},
        -dbase         => $filtered_args{-dbase},
        -api_type      => 'Mapping::Mapping_API',
        -module        => 'Mapping_API'
    );

    my $method_name = $filtered_args{-method};

    delete $filtered_args{-method};
    delete $filtered_args{-dbase};
    delete $filtered_args{-host};
    delete $filtered_args{-db_user};

    return $API->$method_name( %filtered_args, -fatal => 1 );
}

sub get_bcr_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'GSC::API',
        -module        => 'GSC::API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->get_bcr_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}
###############################
sub determine_genome_reference {
###############################
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'GSC::API',
        -module        => 'GSC::API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );

    my $api_results = $API->determine_genome_reference(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub get_alert_reason_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->get_alert_reason_data(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub add_alert_reason {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object

    my %filtered_args = %{$setup_results};    ## the arguments for the API

    my $API = _load_API(
        -api_type      => 'alDente::alDente_API',
        -module        => 'alDente::alDente_API',
        -db_user       => $filtered_args{-db_user},
        -db_password   => $filtered_args{-db_password},
        -lims_user     => $filtered_args{-lims_user},
        -lims_password => $filtered_args{-lims_password},
        -dbase         => $filtered_args{-dbase},
        -host          => $filtered_args{-host},
    );
    my $api_results = $API->add_alert_reason(%filtered_args);

    ## call the API get_original_reagents method with the correct parameters

    $API->DESTROY();
    return $api_results;
}


###################################################################################################################################
#
#API Methods end here
#
###################################################################################################################################

sub set_flash {
    my $message = shift;
 
    $flash = $message;
}
 
sub get_flash {
 
    my $msg = $flash;
    $flash = "";
 
    return $msg;
}

#################################################################
# Email Old Password
# First argument: username
# Second argument: password
# 
# Only activated if LIMS DB has old password hash
# Emails the user IF LIMS DB has the email info
# 
# Will generate a random password and email the user with change
# url and the random password
#
#################################################################
sub email_old_password {
    my $username = shift;
    my $password = shift;
    my $err;
 
    my $query = database->prepare(
        'select Email_Address, Employee_Name from Employee where (Employee_Name = ? OR Email_Address = ?) and Password = Password(?)',
    );
    $query->execute("$username","$username","$password");
    my $email = $query->fetchrow_hashref;

    # Check to see if there is a valid email in the LIMS account registered by the name
    if ( $email->{Email_Address} ) {
        my $pbkdf2 = Crypt::PBKDF2->new(
            hash_class => 'HMACSHA2',
            hash_args => {
                sha_size => 512,
            },
            iterations => 10000,
            output_len => 20,
            salt_len => 10,
        );
        $err = "Your password is still in the old format. Your password has been changed to a temporary password that has been emailed to you. Please change your password using the emailed link.";

        # Generate a not cryptographically secure using rand for making a temp password
        #
        # THIS MUST BE CHANGED TO USING Math::Random::Secure
        my $random;
        my @chars = ("A".."Z", "a".."z", "0".."9", ",", ".", "!", "@", "#", "\$", "^", "&", "*", "(", ")", "-", "_", "+", "=");
        $random  .= $chars[rand @chars] for 1..32;

        # Using the Dancer 2 Email plugin
        email {
            to          => $email->{Email_Address} . "\@bcgsc.ca",
            from        => "Do Not Reply <jhong\@bcgsc.ca>",
            subject     => "LIMS Password Reset Information",
            message     => "<p>Hi $email->{Employee_Name},</p><p>You are receiving this email because of a password reset request.</p><p>Username:   $email->{Employee_Name}</p><p>Alternate Username:   $email->{Email_Address}</p><p>Your Temporary Password:   $random</p><br><p>Please go to <a href=\"https://lims11.bcgsc.ca/change\">LIMS</a> and use this temporary password to change your password immediately.</p>",
            cc         => "aldente\@bcgsc.ca",
        };

        my $hash = $pbkdf2->generate("$random");
        database->quick_update('Employee', { Employee_Name => "$username" }, { Password => "$hash" });
    }
    else {
        $err = "You do not have a valid Email address or a LIMS account registered with us. Please contact the LIMS team at aldente\@bcgsc.ca.";
    }
    return $err;
}

hook before_template => sub {
   my $tokens = shift;
 
   $tokens->{'css_url'} = request->base . 'css/style.css';
   $tokens->{'bootstrap_theme_url'} = request->base . 'bootstrap/css/bootstrap-theme.min.css';
   $tokens->{'bootstrap_css_url'} = request->base . 'bootstrap/css/bootstrap.min.css';
   $tokens->{'bootstrap_js_url'} = request->base . 'bootstrap/js/bootstrap.min.js';
   $tokens->{'jquery_url'} = request->base . 'javascripts/jquery.js';
   $tokens->{'pwd_css_url'} = request->base . 'passfield-build-v1/css/passfield.min.css';
   $tokens->{'pwd_js_url'} = request->base . 'passfield-build-v1/js/passfield.min.js';
   $tokens->{'pwd_validate_js_url'} = request->base . 'javascripts/validate.js';

   $tokens->{'login_url'} = uri_for('/login');
   $tokens->{'apilogin_url'} = uri_for('/api/login');
   $tokens->{'api_call_url'} = uri_for('/api/call');
   $tokens->{'change_url'} = uri_for('/change');
   $tokens->{'logout_url'} = uri_for('/logout');
};

any ['get','post'] => '/change' => sub {
    my $err;
    if ( request->method() eq "POST" ) {
        my $username    = params->{'username'};
        my $password    = params->{'oldpassword'};
        my $new         = params->{'newpassword'};
        my $newconf     = params->{'newconf'};

        my $pbkdf2 = Crypt::PBKDF2->new(
            hash_class => 'HMACSHA2',
            hash_args => {
                sha_size => 512,
            },
            iterations => 37500,
            output_len => 20,
            salt_len => 10,
        );
        my $pwd = database->quick_select('Employee', { Employee_Name => $username } ) || database->quick_select('Employee', { Email_Address => $username } ) ;

        if (!$pwd) {  #Username not in LIMS, so must get approved first
            $err = "Failed for unrecognized user " . $username;
        } 
        elsif ( $pwd->{Password} !~ /PBKDF2/ ) {   ###!$pbkdf2->validate($pwd->{Password}, $password) ) { Change to this once everyone's passwords is changed
            $err = email_old_password( $username, $password);
        }
        elsif ( !$pbkdf2->validate($pwd->{Password}, $password) ) { #Does the password check out?
            $err = "Wrong old password";
        }
        elsif ($new && $newconf ) { 
            if ( $new ne $newconf ) {
                $err = "Your two passwords do not match";
            }
            elsif ( $new eq $password ) {
                $err = "Your new password cannot be the same as your old password";
            }
            elsif ( $new !~ /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{7,}/ ) {
                $err = "Your new password must be at least 7 characters long, and must have both upper and lower case letters and numbers";
            }
            else {
                my $hash = $pbkdf2->generate($new);
                database->quick_update('Employee', { Employee_Name => "$username" }, { Password => "$hash" });
                return "Successfully changed the password. <br> <a href=\"http://limsmaster/SDB/cgi-bin/alDente.pl\">Back to LIMS</a>";
            }
        }
        else {
            $err = "Please fill in all the fields";
        }
    }
    template 'change.tt', {
        'err' => $err, 'msg' => $flash
    };
};

get '/logout' => sub {
   # destroy session
   context->destroy_session;
   set_flash('You are logged out.');
   redirect '/api/login';
};

prefix '/api' => sub { # Anything prefixed with /api (eg /api/login or /api/call) go here
    any ['get', 'post'] => '/call' => sub{
        my $session = session('user');

        if ($session) { 
            if ( request->method() eq "POST" ) {
                my $call    = params->{'call'};
                my %params  = %{from_json(params->{'params'})}; # Parameters MUST be given in JSON format, or this will crash
                
                # This hash is how we convert string from the call parameter to what api function to call
                my %actions = ( 
                                "get_projects" => \&get_projects,
                                "get_project_details" => \&get_project_details,
                                "get_run_data" => \&get_run_data,
                                "get_library_data" => \&get_library_data,
                                "get_pipeline_data" => \&get_pipeline_data,
                                "get_read_data" => \&get_read_data,
                                "get_rearray_data" => \&get_rearray_data,
                                "get_source_data" => \&get_source_data,
                                "get_source_lineage" => \&get_source_lineage,
                                "get_sample_data" => \&get_sample_data,
                                "get_application_data" => \&get_application_data,
                                "get_Primer_data" => \&get_Primer_data,
                                "get_goal_data" => \&get_goal_data,
                                "get_control_type_data" => \&get_control_type_data,
                                "get_plate_data" => \&get_plate_data,
                                "get_plate_lineage" => \&get_plate_lineage,
                                "get_SAGE_data" => \&get_SAGE_data,
                                "get_solexa_run_data" => \&get_solexa_run_data,
                                "get_SOLID_run_data" => \&get_SOLID_run_data,
                                "get_event_data" => \&get_event_data,
                                "create_rearray" => \&create_rearray,
                                "set_solexa_data" => \&set_solexa_data,
                                "add_work_request" => \&add_work_request,
                                "start_run_analysis" => \&start_run_analysis,
                                "create_run_analysis_batch" => \&create_run_analysis_batch,
                                "finish_run_analysis" => \&finish_run_analysis,
                                "get_flowcell_index" => \&get_flowcell_index,
                                "set_attribute" => \&set_attribute,
                                "set_run_comments" => \&set_run_comments,
                                "set_multiplex_run_analysis_data" => \&set_multiplex_run_analysis_data,
                                "set_multiplex_run_data" => \&set_multiplex_run_data,
                                "get_sample_origin_type_data" => \&get_sample_origin_type_data,
                                "get_original_reagents" => \&get_original_reagents,
                                "get_alias_info" => \&get_alias_info,
                                "get_run_analysis_data" => \&get_run_analysis_data,
                                "get_genome_data" => \&get_genome_data,
                                "set_genome_data" => \&set_genome_data,
                                "add_genome" => \&add_genome,
                                "get_analysis_software_data" => \&get_analysis_software_data,
                                "get_anatomic_site_data" => \&get_anatomic_site_data,
                                "get_work_request_data" => \&get_work_request_data,
                                "get_submission_data" => \&get_submission_data,
                                "get_submission_volume_data" => \&get_submission_volume_data,
                                "get_incomplete_analysis_libraries" => \&get_incomplete_analysis_libraries,
                                "mapping_api" => \&mapping_api,
                                "get_bcr_data" => \&get_bcr_data,
                                "determine_genome_reference" => \&determine_genome_reference,
                                "get_alert_reason_data" => \&get_alert_reason_data,
                                "add_alert_reason" => \&add_alert_reason,
                            );
                
                # Retrieve the session data
                my %session = %{$session};
                my $login = $session{encrypted_login};
                
                #######################
                # For now you have to have encrypted login to do this
                # 
                # IMPORTANT IMPORTANT IMPORTANT
                #
                # This passes in the encrypted login as the first parameter (retrieved from the session) and the rest second 
                #
                # Ensure that the user logs in by passing in username and password first in /api/login AND THEN calls /api/call 
                ######################
                if ($login) {
                    my $data = $actions{$call}->( $login, \%params );
                    return $data;
                }
                else {
                    return "Login Failed. Encrypted Login is missing. You must be logged in using /api/login."
                }
            }
            template 'api_call.tt', {};
        }
        else {
            return "Sorry not logged in";
        }
    };

    any ['get', 'post'] => '/login' => sub {
        my $err;
        my $session = session('user');
        my %login;
        my %sess;

        if (!$session) { 
            if ( request->method() eq "POST" ) {
                my $username = params->{'username'};
                my $password = params->{'password'};
                my $host     = params->{'host'};
                my $dbase    = params->{'database'};

                my $pbkdf2 = Crypt::PBKDF2->new(
                    hash_class => 'HMACSHA2',
                    hash_args => {
                        sha_size => 512,
                    },
                    iterations => 37500,
                    output_len => 20,
                    salt_len => 10,
                );
                my $hash = $pbkdf2->generate($password);            
                my $pwd = database->quick_select('Employee', { Employee_Name => $username } ) || database->quick_select('Employee', { Email_Address => $username } ) ;

                my $LDAP = 'ldap://ldap-lb1.bcgsc.ca';
                my $access = _get_LDAP_authentication( -server => $LDAP, -username => $username, -password => $password );
                # process form input
                if ( !$pwd ) { #Error if not in LIMS. Does not matter if they have LDAP or not
                    $err = "Failed login for unrecognized user " . $username;
                } 
                elsif ( !$access && $pwd->{Password} !~ /PBKDF2/ ) {   ###!$pbkdf2->validate($pwd->{Password}, $password) ) { Change to this once everyone's passwords is changed
                    $err = email_old_password( $username, $password);  #If old password, force them to change to new format
                }
                elsif ( $access || $pbkdf2->validate($pwd->{Password}, $password)) { #If password checks out OR LDAP access, grant access
                    my $user_type = database->quick_select('Contact', { Canonical_Name => $username } );
                    if ( $access ) {
                        $login{access}              = $access;
                        $login{login_username}      = $username;
                        $login{login_password}      = $password;
                    }
                    else {
                        $login{login_LIMS_user}     = $username;
                        $login{login_LIMS_password} = $password;
                        $login{LIMS_access}         = 1;
                    }
                    $login{database}            = $host || config->{plugins}->{Database}->{database};
                    $login{host}                = $dbase || config->{plugins}->{Database}->{host};
                    $login{user_type}           = $user_type->{Contact_Type};

                    # This stuff should be factored out eventually
                    my $encrypted_login = YAML::freeze( \%login );
                    $encrypted_login = MIME::Base32::encode($encrypted_login);
                    
                    # Store in the session
                    $sess{info} = $pwd;
                    $sess{login} = \%login;
                    $sess{encrypted_login} = $encrypted_login;
                    session 'user' => \%sess;
                    
                    set_flash('You are logged in.');
                    return "Logged in! your encrypted login is: " . $encrypted_login;
                }
                else {
                    $err = "Wrong password for user: " . $username;
                }
            }
            # display login form
            template 'apiLogin.tt', {
                'err' => $err,
            };
        }
        else {
            return "nope... already logged in";
        }
    };

    get '/logout' => sub {
        context->destroy_session;
        set_flash('You are logged out.');
        redirect '/api/login';
    };
};
dance;
