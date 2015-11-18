#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Imported/SOAP";
use lib $FindBin::RealBin . "/../lib/perl/Imported/LDAP";
use SDB::DBIO;
use XMLRPC::Transport::HTTP;

use RGTools::RGIO;
use Data::Dumper;
use Net::LDAP;
use YAML;
use MIME::Base32;
use SDB::CustomSettings;
use vars qw(%Configs);
## Make this a viewer connection
my $default_dbase = $Configs{BACKUP_DATABASE};
my $default_host  = $Configs{BACKUP_HOST};
my $dbc           = SDB::DBIO->new(
    -dbase    => $default_dbase,
    -host     => $default_host,
    -user     => 'viewer',
    -password => 'viewer',

    #    -session  => 1                 #no need for session tracking for web service since track by api log and also _initialize somehow break web service
);
$dbc->connect( -sessionless => 1 );
XMLRPC::Transport::HTTP::CGI->dispatch_to('lims_web_service')->handle;

package lims_web_service;
use lib $FindBin::RealBin . "/../lib/perl/Core";
use SDB::CustomSettings;
use vars qw($web_service_user $valid_LIMS_user $valid_LIMS_password %Configs);

sub login {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $args = shift;
    my %args = %{$args};

    my $username      = $args{username};
    my $password      = $args{password};
    my $LIMS_user     = $args{LIMS_user};
    my $LIMS_password = $args{LIMS_password};
    my $database      = $args{database};
    my $host          = $args{host};
    my %login;
    unless ( ( $username && $password ) || ( $LIMS_user && $LIMS_password ) ) {
        $login{errors}       = 1;
        $login{error_reason} = 'No Username/password';
        return \%login;
    }
    my $LDAP = 'ldap://ldap-lb1.bcgsc.ca';
    my $access = _get_LDAP_authentication( -server => $LDAP, -username => $username, -password => $password );

    my ($LIMS_access) = $dbc->Table_find( 'Employee', 'count(*)', "WHERE (Employee_Name = '$LIMS_user' OR Email_Address = '$LIMS_user' OR Email_Address like '$LIMS_user\@') and password('$LIMS_password') = Password" );

    unless ( $access || $LIMS_access ) {
        $login{errors}        = 1;
        $login{error_reason}  = 'Username/password not recognized';
        $login{username}      = $username;
        $login{password}      = $password;
        $login{LIMS_user}     = $LIMS_user;
        $login{LIMS_password} = $LIMS_password;
        return \%login;
    }

    $login{access}              = $access;
    $login{LIMS_access}         = $LIMS_access;
    $login{login_username}      = $username;
    $login{login_password}      = $password;
    $login{login_LIMS_user}     = $LIMS_user;
    $login{login_LIMS_password} = $LIMS_password;
    $login{database}            = $database;
    $login{host}                = $host;

    $login{errors} = '';
    my $user_type = _get_user_type($username);

    #	$login{projects} = $projects;

    $login{user_type} = $user_type;

    ## Permission scheme
    #my $encrypted_login = Safe_Freeze(-value=>\%login, -format=>'array', -encode=>1);
    #return \%login;
    my $encrypted_login = YAML::freeze( \%login );
    $encrypted_login = MIME::Base32::encode($encrypted_login);

    #return 'abc';
    return $encrypted_login;
}

sub _get_user_type {

    ## The user type is a single label. Internal users have more permissions than collaborators
    my $username = shift;

    my $user_type;

    ## Check to if the user belongs to the Contact list
    ($user_type) = $dbc->Table_find( 'Contact', 'Contact_Type', "WHERE Canonical_Name = '$username'" );

    ## Check to see if the user belongs internally (Could be a contact as well)

    ## <CONSTRUCTION> here is where we would check to see if the user is internal, if the user is internal, override the user type

    return $user_type;
}

## Called by login method to authenticate the user
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

sub get_projects {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $args     = shift;
    my %args     = %{$args};
    my $login    = $args{login};
    my $username = $login->{username};
    my @project_ids;

    ## Check the user type,	IF they are a collaborator
    #if ($login->{user_type} eq 'Collaborator') {
    if ( login_validation( $login, 'Collaborator' ) ) {
        @project_ids = $dbc->Table_find( 'Collaboration,Contact', 'FK_Project__ID', "WHERE Canonical_Name = '$username' and FK_Contact__ID = Contact_ID" );

        unless (@project_ids) {
            return { errors => 1, error_reason => "No projects associated with Collaborator" };
        }

    }
    elsif ( $login->{user_type} eq 'Internal' ) {
        ##
    }
    else {
        return { errors => 1, error_reason => "Undefined User Type" };
    }
    my %projects;

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

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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
    my $api_results = $API->set_solexa_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub add_work_request {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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

sub set_run_analysis_data {
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

    my $api_results = $API->set_run_analysis_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub create_run_analysis_batch {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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
    my $api_results = $API->set_attribute(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_run_comments {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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
    my $api_results = $API->set_run_comments(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_multiplex_run_analysis_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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
    my $api_results = $API->set_multiplex_run_analysis_data(%filtered_args);

    ## call the API get_read_data method with the correct parameters

    $API->DESTROY();
    return $api_results;
}

sub set_multiplex_run_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    $default_dbase = $Configs{PRODUCTION_DATABASE};
    $default_host  = $Configs{PRODUCTION_HOST};

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

sub get_analysis_submission_data {
    shift if UNIVERSAL::isa( $_[0] => __PACKAGE__ );
    my $login = shift;
    my $args  = shift;

    my $setup_results = _setup_web_service_method( $login, $args );

    return $setup_results if ( $setup_results->{error_reason} || $setup_results->{usage} );
    ## parse the parameters/values passed in by the user
    ## map to the API arguments
    ## create an API object
    my $API = _load_API();

    my %filtered_args = %{$setup_results};                                    ## the arguments for the API
    my $api_results   = $API->get_analysis_submission_data(%filtered_args);

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

sub _help {
    ## <CONSTRUCTION>
    ## return the usage for this method
    my $help_message = "Generic help message for this method";
    return { usage => $help_message };
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
    if ( $login->{LIMS_access} == 1 && $login->{login_LIMS_user} && $login->{login_LIMS_password} ) {
        $valid_LIMS_user     = $login->{login_LIMS_user};
        $valid_LIMS_password = $login->{login_LIMS_password};
        $ok                  = 1;
    }
    if ( $login->{access} == 1 && $login->{login_username} && $login->{login_password} ) {
        $web_service_user = $login->{login_username};
        $ok               = 1;
    }
    if ($ok) {
        $default_dbase = $login->{database} if $login->{database};
        $default_host  = $login->{host}     if $login->{host};
    }
    return $ok;
}

=head SYNOPSIS

Using the API as a web service:

    Authentication:  LDAP
    Username: LDAP username
    Password: LDAP password
        (ie same password for JIRA)

        PERL Example:
        
        use XMLRPC::Lite;

        my $web_service_client =  XMLRPC::Lite ->proxy("http://lims02.bcgsc.ca/SDB_beta/cgi-bin/Web_Service.pl");


        ## Creating a login object 

        my $valid_login = $web_service_client->call('lims_web_service.login',{'username' =>'testlims', 'password' =>'testlims', 'LIMS_user' =>'Guest', 'LIMS_password'=>'pwd'})-> result;
        ## Either username/password or LIMS_user/LIMS_password can be used individually, the use of test users is discouraged.

        ## Calling an API method:

        my $return_data = $web_service_client->call('lims_web_service.<API_method_name>',<login_object>, {<api arguments as HASHREF>);

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


=cut

