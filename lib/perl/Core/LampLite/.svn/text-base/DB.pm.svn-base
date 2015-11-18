package LampLite::DB;

use base LampLite::DB_Object;
#push @ISA, 'Object';

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::DB.pm - DB Model module for LampLite Package

=head1 SYNOPSIS <UPLINK>


=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use Data::Dumper;
use DBI;
##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO qw(Call_Stack filter_input Cast_List Link_To Message timestamp now);
use RGTools::Object;

use LampLite::Bootstrap;
##############################
# global_vars                #
##############################
my $BS = new Bootstrap();

################################
# public methods               #
################################

#
# Generic constructor for database connection class
#
# Return: database connection object
##########
sub new {
##########
    my $this       = shift;                      # Store the package name
    my %args       = filter_input( \@_ );
    my $Template   = $args{-Template};
    my $connect    = $args{ -connect };
    my $debug      = $args{-debug};
    my $driver     = $args{-driver};
    my $dsn        = $args{-dsn};
    my $login_file = $args{-login_file};
    my $login_name = $args{-user} || 'guest';    # login user name (MANDATORY) [String]
    my $login_pass = $args{-password} || '';     # (MANDATORY unless login_file used) specification of password [String]
    my $login_table = $args{-login_table} || 'Employee';
    my $session    = $args{-session};
    my $config_file     = $args{-config_file};
    my $config     = $args{-config};

    my $persistent_session = $args{-session_parameters};
    my $persistent_url     = $args{-url_parameters};

    my $dbc = $args{-DB} || $args{-dbc};

    ## may pass connection options directly to connect method ##
    my $dbh   = $args{-dbh};                     # Optionally pass in existing dbh
    my $host  = $args{-host};
    my $dbase = $args{-dbase};
    my $user  = $args{-user};
    my $pass  = $args{-password};

    if ($dbc) { return $dbc }

    my $self  = {};
    my $self  = $this->Object::new(%args);       ##  -frozen => $frozen, -encoded => $encoded );
    my $class = ref($this) || $this;
    bless $self, $class;

    if ($config) { 
        ## initialize config ##
        $self->{config} = $config; 
    }
    if ($config_file) {
        $self->load_config( -load => 1, -config => $config_file );
    }

    if ($session) { $self->{session} = $session }

    if ($persistent_session) { 
        $self->config( 'session_parameters', $persistent_session );
    }
    if ($persistent_url)     { 
        $self->config( 'url_parameters',     $persistent_url );
    }

    ###  Connection attributes ###
    $self->{connected}  = 0;
    $self->{debug_mode} = $debug;                # Debug mode [Object]
    $self->{sth}        = '';                    # Current statement handle [Object]
    $self->{dbase}      = $dbase;                # Database name [String]
    $self->{host}       = $host;                 # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver}     = $driver;               # SQL driver [String]
    $self->{dsn}        = $dsn;                  # Connection string [String]

    $self->{login_name} = $login_name;           # Login user name [String]
    $self->{login_pass} = $login_pass;           # (MANDATORY unless login_file used) specification of password [String]
    $self->{login_file} = $login_file;
    $self->{login_table} = $login_table;

    if ( $connect && !$dbh ) { $self->auto_connect(%args) }
    elsif ($connect) {  $dbh = $self->connect(%args) }
    
    if ($Template) { $self->{Template} = $Template }
    $self->{errors} ||= [];

    if ($dbh) { $self->{dbh} = $dbh }

    return $self;
}

# This method should be defined for all inherited DB object classes 
#
# Dynamically load the given module at the highest available level.
#  (if not found, it will check inherited classes and load them as required)
#
#
# Return: name of module loaded if found 
######################
sub dynamic_require {
######################
	my $self = shift;
    my %args = &filter_input( \@_, -args=>'module');
	my $module = $args{-module};
	my $construct = $args{-construct};
	my $debug  = $args{-debug};
	
	my $scope = 'LampLite';  ## change this line only depending on scope of method ##
	
	my $test = $scope . '::' . $module;
	my $local = eval "require $test";
	if ($local) {
		if ($debug) { $self->message("Found local $test") }
		return $test;
	}
	else {
		if ($debug) { $self->message("$test not found. ") }
		return; ##  $self->SUPER::dynamic_require($module, $debug);  no SUPER option below LampLite... 
	}

}


###########################################################
# Connect to database and obtain database handle
#
# Locally, passwords can be contained in a 'login file' containing user password combinations.
# (NOTE: if this file exists it should have limited READ permissions)
# Alternatively, a password may be supplied explicitly
#
# RETURN: the database handle (if successful)
############################################################
sub connect {
#############
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbase       = $args{-dbase}       || $self->{dbase} || '';          # database to connect to (MANDATORY) [String]
    my $login_name  = $args{-user}        || $self->{login_name};           # login user name (MANDATORY) [String]
    my $login_pass  = $args{-password}    || $self->{login_pass};           # (MANDATORY unless login_file used) specification of password [String]
    my $login_file  = $args{-login_file}  || $self->{login_file};           # login_file (specify file containing passwords) : currently uses format: 'host:user:password' [String]
    my $trace       = $args{-trace_level} || $self->{trace} || 0;           # set trace level on database connection (defaults to 0) [Int]
    my $trace_file  = $args{-trace_file}  || $self->{trace_file};           # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $trace_level = $args{-trace_level} || $self->{trace_level};          # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $quiet       = $args{-quiet}       || $self->{quiet} || 0;           # suppress printed feedback (defaults to 0) [Int]
    my $host        = $args{-host}        || $self->{host};                 # (MANDATORY unless global default set) host for SQL server. [String]
    my $driver      = $args{-driver}      || $self->{driver} || 'mysql';    # SQL driver  [String]
    my $dsn         = $self->{dsn};                                         # Connection string [String]
    my $mode        = $args{-mode} || $self->{mode};
    my $no_password = $args{-no_password};

    my $start_trans = $args{-start_trans} || 0;                             # Optional flag to indicate starting of transaction
    my $force       = $args{-force}       || 0;                             # Force re-connection (even if already connected)
    my $sessionless = $args{-sessionless} || 0;
    my $reconnect = $args{-reconnect};                                      ## optional message (or submit button to try again) on connection failure ##
    my $session   = $args{-session};
    my $debug = $args{-debug};
    
    if ( $self->{connected} && !$force ) { return $self }

    if ( $driver && $dbase && $host ) {

        # If DSN is not specified but all other info are provided, then we build a DSN.
        $dsn = "DBI:$driver:database=$dbase:$host";
    }
    
    if ( !$sessionless ) {
        $self->{session} ||= $session || $self->define_Session($session);
    }
    else {
        $self->{session} = undef;
    }

    $self->{dbase}      = $dbase;
    $self->{login_name} = $login_name;
    $self->{login_file} = $login_file;
    $self->{trace}      = $trace;
    $self->{trace_file} = $trace_file;
    $self->{quiet}      = $quiet;
    $self->{host}       = $host;
    $self->{driver}     = $driver;
    $self->{dsn}        = $dsn;

    $self->{dbase_mode} = $mode;

    my $user = `whoami`;

    chomp $user;
    $self->{user} = $user;
    $self->{file} = $0;

    my $max_tries = 1;    ### after $max_tries return 0 if not available...
    unless ( $host && $login_name && $driver && $dbase ) {
        my @keys = keys %args;
        foreach my $key (@keys) {
            print "$key = $args{$key}<BR>";
        }

        print $self->warning("Require Driver, Host, Database, and User\n($driver + $host + $dbase + $login_name)");
        return 0;
    }

    my $attempts    = 0;
    my $grep_failed = 0;
    if ( !$no_password ) {
        ### This block retrieves a mandatory password unless the 'no_password' parameter is passed in ###
        while ( !$login_pass && $attempts < 2 ) {
            ## there has never been any case where the password was retrieved after more than one attempt - it seems to work or fail (regardless of sleep delay or # of attempts) ##
            unless ($login_file) {
                $self->warning("No Password ($login_pass) or Login File ($login_file) specified");
                return 0;
            }

            eval "require LampLite::Login";
            $login_pass = LampLite::Login::get_password( -host => $host, -user => $login_name, -file => $login_file, -method => 'grep' );
            ## || LampLite::Login::get_password( -host => $host, -user => $login_name, -file => $login_file, -method => 'read');

            $self->{db_user} = $login_name;
             $attempts++;
        }

        if ( $login_pass && $attempts > 1 ) { $self->warning("Required $attempts attempts to access password file") }
        elsif ( !$login_pass ) {
            $self->warning("Unable to access password for '$login_name' on $host via login file: $login_file");
            Call_Stack();
        }    ## for now ... change to debug_message for release .... just to provide feedback to show that read access was used to access password.  (try swapping order of get_password methods)

        #    $self->{login_pass} = $login_pass;   ## comment this line out to increase security by not storing login password in dbc object

        unless ($login_pass) {
            $self->error("Password Not Found for $host:$login_name in login_file [$login_file] ($attempts attempts)");

            if ( $self->config('context') eq 'html' ) {
                my $reload_button = $reconnect || "Could not connect";
                print $reload_button . '<HR>';
                $self->flush_messages();
                main::leave();
            }

            return 0;
        }
    }

    my $count;
    if ( $trace_level && $trace_file ) {
        DBI->trace( $trace_level, $trace_file );
    }

    if ( $force || !( $self->ping() ) ) {
        ## do not connect if already connected (unless forced) ##
        $self->disconnect();
        if ($debug) { print "Connect $login_name : $login_pass [$dsn]" };
        my $dbh = DBI->connect( $dsn, $login_name, $login_pass );
        $self->{dbh} = $dbh;
    }
    
    while ( !$self || !$self->ping() ) {
        if ( $count > $max_tries ) {    ### limit number of tries
            $self->error("Failed after $max_tries tries to connect '$login_name' [$login_pass] using DSN: $dsn"  . $DBI::errstr);
            return 0;
        }
        sleep(1);
        
        my $ok = $self->{dbh} = DBI->connect( $dsn, $login_name, $login_pass );
         $count++;
    }

    ### reconnect as read only viewer if using backup database ##
    if ( $self->{dbase} eq $self->config('BACKUP_DATABASE') && $self->{host} eq $self->config('BACKUP_HOST') && $user != 'viewer' ) {
        $self->disconnect();
        ## connect as read only to avoid writing to replication database ##
        $args{-user}     = 'viewer';
        $args{-password} = 'viewer';
        $self->connect(%args);
    }

    if ( $self && $self->ping() ) {
        $self->{connected} = 1;
    }
    else {
        print $BS->error("'$login_name' still not connected.  DSN: $dsn");
    }

    $self->initialize();

#    if ($self->session)  { $self->session->initialize(-login_table=>$self->{login_table}, -dbc=>$self) }
    return $self->{dbh};
}

#
# Boolean to determine if database is connected
###################
sub is_Connected {
###################
    my $self = shift;
    return $self->{connected};
}

# Connect to the database if necessary
#
# Return: database handle
########################
sub connect_if_necessary {
###########################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'LampLite::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    if ( $self->ping() ) { return $self->dbh; }    ## already connected... ok, return the existing database handle
    else {
        return $self->connect();
    }
}

#########################################
# Checks if current user is a Site Admin
#########################################
sub Site_admin {
#########################################
    my $self = shift;

    if ( $self->config('user') eq 'Admin' ) { return 1 }

    my $Access = $self->get_local('Access');
    if ($Access) {
        my @access = keys %{$Access};
        if ( exists $access[0] ) {
            if ( grep /Site Admin/, @access ) { return 1 }
        }
    }
    return 1;
}

###################
sub field_exists {
###################
    my $self  = shift;
    my $table = shift;
    my $field = shift;

    if (!$field && $table =~/(.*)\.(.*)/) { $table = $1; $field = $2; }
    
    if ( !$table ) { return }    ## undefined table
    $field ||= '%';
    
    if (! $self->{connected}) { return }

    my $found = $self->query( "SHOW FIELDS FROM $table LIKE '$field'", -finish => 0 );    # ->execute();
    if ( $found eq '0E0' ) { return 0; }                                       ## Table not found ##

    return 1;
}

###################
sub table_loaded {
###################
    my $self  = shift;
    my $table = shift;

    if ( !$table ) {return}    ## undefined table

    if (! $self->{connected}) { return }
        
    my $found = $self->query( "SHOW TABLES LIKE '$table'", -finish => 0 );    # ->execute();
    if ( $found eq '0E0' ) { return 0; }                                       ## Table not found ##

    my $found_table;
    if ($found) {
        my @tables = $found->fetchrow_array;
        if ( int(@tables) == 1 ) {
            $found_table = $tables[0];
        }
    }

    return $found_table;
}

#############
sub tables {
#############
    my $self = shift;
    
    my @tables = map { ~s/^\`(.*)\`$/$1/ } @{$self->dbh->tables()};
    
    return @tables;
}

#######################
sub table_populated {
#######################
   my $self  = shift;
   my $table = shift;
   
   if (!$self->table_loaded($table)) { return }
   
   my $records;
   if ($self->table_loaded('DBTable')) { $records = $self->get_db_value(-sql=>"SELECT Records from DBTable where DBTable_Name = '$table'") }
   else { $records = $self->get_db_value(-sql=>"SELECT Count(*) from $table") }
   
   return $records;
}

#
# Need to set up basic table to keep track of addons / options
#
# (may replace older $dbc->package_active and plugin checking methods)
#
# Return: True if addon included
###############
sub addons {
###############
    my $self = shift;
    my $addon = shift;
    
    if ( $self->table_populated('Addon') ) {
        my $loaded = $self->get_db_value(-sql=>"SELECT Addon_Name FROM Addon WHERE Addon_Name like '$addon'");
        return $loaded;
    }
    return;
}

######################################################
#
# This executes a simple query statement
#  and will print a message if there is an error
#
# RETURN: a string handle
#
######################################################
sub query {
##########
    my %args = &filter_input( \@_, -args => 'dbc,query', -mandatory => 'dbc|self', -self => 'LampLite::DB' );
    my $self       = $args{-self} || $args{-dbc};
    my $query      = $args{ -query };               # query string (MANDATORY) [String]
    my $target     = $args{-target};                # target to display the output [String]
    my $filename   = $args{-file} || '';            # optional filename for output [String]
    my $values_ref = $args{ -values };
    my $autoquote  = $args{-autoquote};
    my $sth        = $args{ -sth } || 0;            # (removed ||= $self->{sth} )... See if there is an existing statment handle and if so use it instead  [String]

    my $headers = $args{-headers} || '';            # send reference to array [String]
    my $quiet = $args{-quiet};                      ## no print statements

    my $finish = defined $args{-finish} ? $args{-finish} : 1;    # whether to finish the statement handle [Int]

    $query = qq{$query};
    unless ( $self && ( $query || $sth ) ) { return; }

    ### may repeat query if sth sent as argument...
    unless ($sth) {
        $sth = $self->dbh()->prepare($query);
    }

    #    if ($values_ref) {
    my @values;                                                  ## enables multiple calls supplying values...
    if ($values_ref) { @values = @$values_ref }
    
    $sth->execute(@values);

    #    }
    #    else { Message("NO VALUES"); }

    if ( defined $sth->err() ) {
        $self->error( "Error with $query:" . $DBI::errstr );
        print "Error with $query:" . $DBI::errstr unless ($quiet);
    }

    if ($target) {
        my $ok = $self->dump_results( -sth => $sth, -headers => $headers, -target => $target, -file => $filename );
    }

    unless ($sth) {
        $self->error( "Error with $query: ", $DBI::errstr );
        return;
    }

    if ($finish) {
        $sth->finish();
    }
    else {
        $self->{sth} = $sth;
    }
    return $sth;
}

############################################################
#
# Dump results of statement handle to: screen/file/html
# RETURN: number of records returned (or -1 if file could not be opened)
#
############################################################
sub dump_results {
####################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    my $sth      = $args{ -sth };                     # statement handle [Object]
    my $limit    = $args{-limit} || 0;                # optional limit on number of records dumped [Int]
    my $line_sep = $args{-line_separator} || "\n";    # line separator (defaults to \n) [String]
    my $sep      = $args{-separator} || "\t";         # field separator (defaults to \t) [String]
    my $target   = $args{-target} || 'text';          # target type = text/html/file (defaults to text) [String]
    my $filename = $args{-file} || '';                # filename (changes target default to file) [String]
    my $headers  = $args{-headers} || '';             # header [String]

    my $html = 0;
    my $file = '';
    if ( $target =~ /html/i ) { $html = 1; }

    if ( $target =~ /file/i ) { $file = $filename || 'Dump_Results'; }
    elsif ($filename) { $file = $filename; }

    my $prefix = '';
    my $finish = "\n";

    my $FILE;
    if ($file) {
        open $FILE, '>', $file or return -1;
    }
    if ($html) {
        $prefix   = "\n<Table border=1>\n<TR><TD>";
        $sep      = "</TD><TD>";
        $line_sep = "</TD></TR>\n<TR><TD>";
        $finish   = "</TD></TR></Table>";
    }

    my @field_names;
    my $records = 0;
    my $row;
    while ( $row = $sth->fetchrow_hashref ) {
        if ( $records == 0 ) {    ## just check once..
            @field_names = keys %{$row};
            unless ($headers) { $headers = \@field_names; }
            if ($file) {
                print $FILE join $sep, @$headers;
                print $FILE $line_sep;
            }
            else {
                print join $sep, @$headers;
                print $line_sep;
            }
        }
        $records++;
        if ( $limit && ( $records > $limit ) ) { last; }
        my @field_values;
        foreach my $index ( 0 .. $#field_names ) {
            my $value  = $row->{ $field_names[$index] };
            my $length = length $value;
            push( @field_values, $value );
        }
        if ($file) {
            print $FILE join $sep, @field_values;
            print $FILE $line_sep;
        }
        else {
            print join $sep, @field_values;
            print $line_sep;
        }
    }
    close $FILE;
}

###############################################
# Get attributes that have been set locally
# (This enables custom connection attributes to be monitored)
#
# <snip>
#  Example:
#     my $user_id = $dbc->get_local('user_id');
# </snip>
# Return: value
################
sub get_local {
################
    my $self      = shift;
    my $attribute = shift;

    if ($attribute) {
        if ( $self->{LocalAttribute}{$attribute} ) {
            return $self->{LocalAttribute}{$attribute};
        }
        elsif ( $self->session() ) {
            my $sess_param = $self->session->param($attribute);
            if ($sess_param) {
                return $sess_param;
            }
        }
    }
    else {
        my $session_param;
        if ( $self->session() ) {
            $session_param = $self->session->param();
        }
        return $self->{LocalAttribute} || $session_param;
    }

    return;
}

###############################################
# Set attributes locally
#
# (This enables custom connection attributes to be monitored)
#
# <snip>
#  Example:
#     my $user_id = $dbc->set_local('user_id');
# </snip>
# Return : 1 on success.
###############
sub set_local {
###############
    my $self      = shift;
    my $attribute = shift;
    my $value     = shift;

    if ( ref $value eq 'ARRAY' ) {
        my @val = @$value;
        $self->{LocalAttribute}{$attribute} = \@val;
    }
    else {
        $self->{LocalAttribute}{$attribute} = $value;
    }

    if ( defined $self->{session} ) {
        $self->session()->param( $attribute, $value );    ## apply to session
    }

    return $self->{LocalAttribute}{$attribute};
}

####################
sub define_Session {
####################
    my $self  = shift;
    my $class = shift;

    $class ||= ref $self;
    $class =~ s/::(\w+)$/::Session/;

    eval "require $class";
    my $session = $class->new( 'id:md5' );

    if ( ref $self ) { $self->{session} = $session }

    return $session;
}

#
# Initialize session object and setup configuration values
#
#
#########################
sub initialize {
#########################
    my $self = shift;

    my $session = $self->session();

    $self->set_persistent_parameters( -scope => 'url' );
    $self->set_persistent_parameters( -scope => 'session' );

    my $persistent = $self->config('session_parameters');
    if ( $persistent && $session ) {
        foreach my $param (@$persistent) {
            if ($param eq 'homelink') { next }
            my $val = $self->config($param);
            my $input = $session->get_param($param);
            if ( $input && $input ne $val ) {
                if ($param eq 'homelink') { next }   ## remove this once we figure out why the session parameter is incorrect above... 
                $self->config( $param, $input );
            }
        }
    }

    if ($self->is_Connected && $self->table_loaded('Version')) {
        my $code_version = $self->get_db_value('Version', 'Version_Name', "Version_Status = 'In Use'");
        if ($code_version) { $self->config('CODE_VERSION', $code_version) }
    }

    $self->{initialized} = 1;
    return;
}

#####################
sub merge_configs {
#####################
    my $configs = shift;

    if ( !ref $configs ) { $configs = [$configs] }

    my ( $hash_type, $array_type, $value_type ) = ( 0, 0, 0 );
    my ( $Config, @list, $value );

    foreach my $config (@$configs) {
        if ( ref $config eq 'HASH' ) {
            ## if hash ... merge hash keys independently (still inherit non-defined keys from parent hash) ##
            my %hash = %$config;
            foreach my $key ( keys %hash ) {
                if ( defined $Config->{$key} ) {
                    my $merged = merge_configs( [ $Config->{$key}, $hash{$key} ] );
                    $Config->{$key} = $merged;
                }
                else {
                    $Config->{$key} = $hash{$key};
                }
            }
            $hash_type = 1;
        }
        elsif ( ref $config eq 'ARRAY' ) {
            push @list, @$config;
            $array_type = 1;
        }
        else {
            $value      = $config;
            $value_type = 1;
        }
    }

    if    ($value_type) { return $value }
    elsif ($array_type) { return \@list }
    else                { return $Config }

    if ( $value_type + $array_type + $hash_type != 1 ) {
        print "Error single ref type not defined";
        return;
    }

    return $Config;
}

##############################
sub load_config {
##############################
    #
    # Load customizable configs from system.conf file
    #
    my %args = &filter_input( \@_, -args => 'dbc, config', -self => 'LampLite::DB' );
    my $self    = $args{-self} || $args{-dbc};
    my $configs = $args{-config};
    my $load    = $args{-load};

    if ( !$configs ) {return}
    elsif ( ref $configs ne 'ARRAY' ) { $configs = [$configs] }
    my %Loaded_Config;
    foreach my $config_file (@$configs) {
        if ( !$config_file ) {next}
        my %core_configs;
        ## Load Standard Configuration Variables ##
        if ( -f $config_file ) {
            require XML::Simple;
            my $data = XML::Simple::XMLin("$config_file");
            %core_configs = %{$data};

            if ($load) {
                foreach my $key ( keys %core_configs ) {
                    $self->config( $key, $core_configs{$key} );
                }
            }
            %Loaded_Config = ( %Loaded_Config, %core_configs );
        }
        elsif ( ref $config_file eq 'HASH' ) {
            %Loaded_Config = ( %Loaded_Config, %$config_file );

            if ($load) {
                foreach my $key ( keys %$config_file ) {
                    $self->config( $key, $config_file->{$key}, -overwrite => 0 );
                }
            }

        }
        else {
            return;
            print "Specified Config File $config_file Not Found " . ref $config_file;
        }
    }

    return \%Loaded_Config;
}

#
# Checks config values for indicated parameter
#
# First checks loaded configuration settings for current DB object
#
# If this is not defined, it also checks scope specific Config modules for module based configuration settings
#
#############
sub config {
#############
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'name,value' );
    my $name       = $args{-name};
    my $value     = $args{-value};
    my $key       = $args{-key};
    my $overwrite = defined $args{-overwrite} ? $args{-overwrite} : 1;
    
    use Params::Util qw(_HASH _HASH0 _HASHLIKE);
    
    my $temp_dbc;
    my $returnval;
    if ($name) {
        if ($value) {            
            if ( $overwrite || !$self->{config}{$name} ) {
                $self->{config}{$name} = $value;
            }
        }
        my $stored = $self->{config}{$name};

        if ( ref $stored eq 'HASH' && $stored->{value} ) { $returnval = $stored->{value} }
        elsif ( defined $stored ) { $returnval = $self->{config}{$name} }
        elsif ( $self->session && $self->session->param($name) ) { $returnval = $self->session->param($name) }
        else {
            ## check module based config files ##
            my $class = ref $self;
            if ( $class =~ /(\w+)::/ ) {
                my $scope = $1 . '::Config';
                my $ok    = eval "require $scope";
                if ($ok) { $returnval = $scope->value($name) }
            }
        }
    }
    else {
        return $self->{config};
    }
    
    if ($returnval && ref $returnval eq 'HASH' && defined $returnval->{$key}) { return $returnval->{$key}}
    else { return $returnval }
}

#
# Accessor to access config value directly from config hash (rather than dbc class)
#
# Return: config value if it exists.
###################
sub config_value {
###################
    my $config = shift;
    my $key    = shift;

    if ( defined $config && defined $config->{$key} ) {
        my $value = $config->{$key};
        if ( ref $value eq 'HASH' && defined $config->{$key}{value} ) {
            return $config->{$key}{value};
        }
        else { return $config->{$key} }
    }

    return;
}

##############
sub mobile {
##############
    my $self = shift;

    my $screen_mode = $self->config('screen_mode');

    if ( $screen_mode =~ /(mobile|tablet|phone)/ ) {
        return $1;
    }

    return;
}

##############################
# get the host argument of the connection
##############################
sub get_host {
##############################
    my $self = shift;
    return $self->{host};
}

##############################
# get the database argument of the connection
##############################
sub get_dbase {
##############################
    my $self = shift;
    return $self->{dbase};
}

#####################################
# Returns the database handle 
#####################################
sub dbh {
###########
    my $self = shift;
    
    return $self->{dbh};
}

#################################
# confirm connection to database
#################################
sub ping {
############
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DBI' );
    my $self = $args{-self} || $args{-dbc};
    my $debug = $args{-debug};

    if    ( !$self )              { $self->error("NO DBIO object")         if $debug }
    elsif ( !( $self->dbh() ) )   { $self->error("No dbh for DBIO object") if $debug }
    elsif ( !$self->dbh->ping() ) { $self->error("dbh cannot be pinged")   if $debug }
    else                          { return 1 }

    return 0;
}

################
sub session {
################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $reset = $args{ -initialize };

    if ($reset) { $self->initialize() }    # run again since some parameters may not be set yet... (shouldn't really need to do this)

    return $self->{session};
}

################################
sub set_persistent_parameters {
################################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'persistent' );
    my $persistent = $args{-persistent};
    my $scope      = $args{-scope} || 'session';                   ## session or url

    if ($persistent) {
        $self->config( "${scope}_parameters", $persistent );
    }
    else {
        $persistent = $self->config("${scope}_parameters");
    }

    if ( $persistent && $self->{session} ) {
        foreach my $param (@$persistent) {
            my $val = $self->session->param($param) || $self->config($param);
            my $input_val = $self->session->get_param($param);

            if ( $input_val && ( $val ne $input_val ) ) {
                if ( $self->session() && $scope eq 'session' ) { $self->session->param( $param, $input_val ) }    ## Session IDs may be reset despite input value
                                                                                                                  # if ( $scope eq 'url' ) { $self->config($param, $input_val) }
            }

            if ( $param eq 'homelink' ) {
                ## temporary ... ensure homelink is set (legacy code may rely on dbc->{homelink} rather than session or config)
                if    ($input_val) { $self->{$param} = $input_val }
                elsif ($val)       { $self->{$param} = $val }
            }
        }
    }
    return;
}

##############
##############

#################
sub connect2 {
#################
    my $self  = shift;
    my $host  = shift;
    my $dbase = shift;
    my $user  = shift;
    my $pass  = shift;

    my $driver = 'mysql';
    my $dsn    = "DBI:$driver:database=$dbase:$host";
    my $dbh    = DBI->connect( $dsn, $user, $pass ) or print "Errors found: $DBI::errstr";

    $self->{dbh} = $dbh;
    if   ($dbh) { $self->{connected} = 'TRUE' }
    else        { $self->{connected} = 'FALSE' }

    return $self;
}

##################
sub fetch_query {
##################
    my $self = shift;
    my $sql  = shift;

    my $dbh = $self->{dbh};  
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    
    my $array_ref = $dbh->selectall_arrayref( $sth, { Slice => {} } );

    return $array_ref;
}

#############
sub insert {
#############
    my $self = shift;
    my $sql  = shift;
    my $dbh  = $self->{dbh};
    my $sth  = $dbh->prepare($sql);

    $sth->execute();

    my $id = $dbh->{'mysql_insertid'};

    if ( !$id ) { $self->debug_message("NO ID GENERATED: $sql") }

    return $id;
}

#############
sub update {
#############
    my $self = shift;
    my $sql  = shift;

    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare($sql);

    my $ok = $sth->execute();

    if   ( !$ok ) { print "$sql<BR>\n" }

    return $ok;
}

#
# Wrapper to fetch hash of data give an SQL statement or a list of fields & tables.
#
#
# Return: data hash of query results
############
sub hash {
############
    my $self = shift;

    my %args      = filter_input( \@_, -args => 'table,fields,condition' );
    my $SQL       = $args{-SQL} || $args{-sql};
    my $fields    = $args{-fields} || $args{-field};   ## default to retrieve all fields (in build_query) ##
    my $tables    = $args{-tables} || $args{-table};
    my $condition = $args{-condition};
    my $group     = $args{-group};  # these arguments are used by build_query ... 
    my $order     = $args{-order};
    my $limit     = $args{-limit};
    my $return_type = $args{-return_type} || 'hash';  ## may be array or hash  eg { 'Name' => ['John','Mary'], 'Age' => [33, 45] } OR [ {'Name' => 'John', 'Age' => 33}, {'Name' => 'Mary', 'Age' = 45 } ]
    my $debug     = $args{-debug};
    
    $SQL ||= $self->build_query(%args);    ## enable use of additional arguments including group, order, limit, distinct ... 
  
    if ($debug) { Call_Stack();  print $SQL }
    if ( !$SQL ) {return}

    my $array = $self->hashes(-sql=>$SQL);

    my $hash;

    if ( !$array ) { return {} }

    my $count = int(@$array);    
    foreach my $i ( 1 .. $count ) {
        my $fetch = $array->[ $i - 1 ];
        my @keys  = keys %{$fetch};
        foreach my $key (@keys) {
            my $val = $fetch->{$key};
            if ($return_type =~/^h/) { $hash->{$key}->[ $i - 1 ] = $val }
            elsif ($return_type =~/^a/) { $hash->[$i-1]{$key} = $val }
        }
    }

    return $hash;
}

#
# Wrapper to fetch array of hashes of data give an SQL statement or a list of fields & tables.
#
#
# Return: array of data hashes for query results
############
sub hashes {
############
    my $self = shift;

    my %args      = filter_input( \@_, -args => 'table,fields,condition' );
    my $SQL       = $args{-SQL} || $args{-sql};
    my $fields    = $args{-fields} || $args{-field};   ## default to retrieve all fields (in build_query) ##
    my $tables    = $args{-tables} || $args{-table};
    my $condition = $args{-condition};
    my $group     = $args{-group};  # these arguments are used by build_query ... 
    my $order     = $args{-order};
    my $limit     = $args{-limit};
    my $return_type = $args{-return_type} || 'hash';  ## may be array or hash  eg { 'Name' => ['John','Mary'], 'Age' => [33, 45] } OR [ {'Name' => 'John', 'Age' => 33}, {'Name' => 'Mary', 'Age' = 45 } ]
    my $debug     = $args{-debug};
    
    $SQL ||= $self->build_query(%args);    ## enable use of additional arguments including group, order, limit, distinct ... 
  
    if ($debug) { Call_Stack();  print $SQL }
    if ( !$SQL ) {return}

    my $array = $self->fetch_query($SQL);

    return $array;
}


##################
sub Table_find {
##################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,field,condition');

    return $self->get_db_array(%args);
}

######################
sub Table_find_array {
######################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,field,condition');

    return $self->get_db_array(%args);
}

#
# Get single value from SQL query
#
# Usage:
#
#   my $value = $dbc->get_db_value(-sql=>"SELECT field from table where condition");
#
#   or
#
#   my $value = $dbc->get_db_value(-field=>$field, -table=>$table, -condition=>$condition)
#
# Return: value if retrieved
################
sub get_db_value {
################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,field,condition');
    my $sql   = $args{-sql};
    my $table = $args{-table};
    my $field = $args{-field} || $args{-value} ;
    my $condition = $args{-condition} || 1;
    
    my $index = $args{-index};
    my $array = $args{-array};                   ## return results as array (allows for mutliple values to be retrieved)
    my $distinct = $args{-distinct};
    my $debug = $args{-debug};

    $condition =~s/^WHERE //i;  ## ignore where in condition if supplied explicitly... 

    if (!$sql) { 
        $sql = $self->build_query(%args);    ## enable use of additional arguments including group, order, limit, distinct ... 
    }    
    if ($debug) { print "<BR>sql: $sql<BR>"; Call_Stack(); }

    my $hash = $self->hash(-SQL=>$sql);
    if (ref $hash ne 'HASH') { return }
    
    if (!$field) { ($field) = keys %{$hash} }
    my $values = $hash->{$field};         
        
    if (!$field) { return }
    
    if ($array && $values) {
        if (ref $values eq 'ARRAY') { return @$values }
        else { return }
    }
    elsif ($values) {
        if ($index) { return $values->[$index] }
        elsif ( int(@$values) < 1 ) { return }
        elsif ( int(@$values) > 1 ) { return $self->debug_message('get_db_value returning more than one value (using first value found)'); }
        return $values->[0];
    }
    
    return;
    
}

#
# Get values from multiple fields via SQL query
#
# Usage:
#
#   my @values = $dbc->get_db_value(-sql=>"SELECT field1, field2 from table where condition");
#
#   or
#
#   my @values = $dbc->get_db_value(-fields=>[$field1,$field2], -table=>$table, -condition=>$condition)
#
# Return: value if retrieved
#####################
sub get_db_values {
#####################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,field,condition');
    my $sql   = $args{-sql};
    my $table = $args{-table};
    my $fields = $args{-fields} || $args{-values} ;
    my $condition = $args{-condition} || 1;
    
    my $hash = $self->hash(%args);
    my @fields = Cast_List(-list=>$fields, -to=>'ARRAY');
    
    my @values;
    foreach my $field (@fields) {
        if ($field =~ /(.*) AS (.*)/) { $field = $2 }
        push @values, $hash->{$field}[0];
    }
    
    return @values;
}

#
# Extend scope of table to include left joins accounting for Field_Reference values which include related tables
#
# Input: 
#    - current table reference
#    - field reference required to retrieve data from object
# 
#   eg $self->extend_Object_scope(-table=>'Source', -reference=>'Concat(Source_ID, ':', Sample.Sample_Type)');
#
#    ... returns: "Source LEFT JOIN Sample_Type ON Sample_Type_ID = Source.FK_Sample_Type__I"
#
# Return: full table reference string (extended as required to include related tables in scope)
###########################
sub extend_Object_scope {
###########################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,reference');
    
    my $table = $args{-table};
    my $ref = $args{-reference};

    my $quoted_table_list = Cast_List( -list => $table, -to => 'string', -autoquote => 1 );
    my $check_for_extra_tables = $ref;

    while ( $check_for_extra_tables =~ s/(\w+)\.(\w+)/$2/ ) {
        my $extra_table = $1;
        my $extra_field = $2;

        if ( $table =~ /\b$extra_table\b/ ) {next}                            ## already included ...
        my @fk_fields = $self->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table IN ($quoted_table_list) AND Foreign_Key LIKE '$extra_table\.%'" );
        if ( int(@fk_fields) == 1 ) {
            ## Sometimes the corresponding FK's can be null, so a left join is needed to avoid
            ## forgetting records with missing FK entries

            $table            .= " LEFT JOIN $extra_table ON $fk_fields[0] = ${extra_table}_ID";
            $quoted_table_list .= ",'$extra_table'";
        }
        else { $self->warning("Could not dynamically include $extra_table (ambiguous reference)") }
    }
    
    return $table;
}
 
##################
sub build_query {
##################
    my $self  = shift;
    my %args  = filter_input( \@_, -args=>'table,field,condition');
    my $distinct = $args{-distinct};
    my $tables = $args{-table} || $args{-tables};
    my $fields = $args{-field} || $args{-fields} || ['*'];
    my $condition = $args{-condition} || 1;
    my $group     = $args{-group};
    my $order     = $args{-order};
    my $limit     = $args{-limit};

    if (!$fields && $tables) { $fields = $self->fields($tables) }
    if (ref $fields eq 'ARRAY') { $fields = Cast_List(-list=>$fields, -to=>'string') }

    my $sql = "SELECT";
    if ($distinct) { $sql .= " DISTINCT "}
    $sql .= ' ' . $fields;
    if ($tables) { $sql .= " FROM $tables" }
    if ($condition =~ /^WHERE /i) { $sql .= " $condition" }
    elsif ($condition) { $sql .= " WHERE $condition" }
    
    if ($group) { $sql .= " GROUP BY $group" }
    if ($order) { $sql .= " ORDER BY $order" }
    if ($limit) { $sql .= " LIMIT $limit" }
    
    return $sql;
}

#
# Accessor to simplify retrieval of array using get_db_value 
#
# Return: array of database values retrieved (see get_db_value for input options)
####################
sub get_db_array {
####################
    my $self = shift;
    my %args  = filter_input( \@_, -args=>'sql');
    $args{-array} = 1;
    return $self->get_db_value(%args);
}

###########################
sub query_output_table {
###########################
    my $self      = shift;
    my $array     = shift;
    my $field_ref = shift;
    my $border    = 1;

    if ( !$field_ref || !$field_ref->[0] || $field_ref->[0] =~ /\*/ ) {
        ## retrieve all keys from first record if no field specified ##
        my @keys = keys %{ $array->[0] };
        $field_ref = \@keys;
    }

    my $table = "\n<Table border=$border>\n";
    foreach my $fetch (@$array) {
        my @cols;
        foreach my $key (@$field_ref) {
            my $val = $fetch->{$key} || '-';
            my $displayed_value = $self->display_value( -field=>$key, -value=>$val );
            push @cols, $displayed_value;
        }
        $table .= Table_row( \@cols );
    }
    $table .= "</Table>\n";
    return $table;
}
################
sub Table_row {
################
    my $row_ref = shift;

    my $table = "<TR>\n";

    foreach my $i ( 1 .. int(@$row_ref) ) {
        my $cell = $row_ref->[ $i - 1 ];
        $table .= "\t<TD>$cell</TD>\n";
    }
    $table .= "</TR>\n";

    return $table;
}

### Simple accessors to record links and primary / alias fields ##

####################
sub display_value {
####################
    my $self  = shift;
    my %args       = filter_input( \@_, -args=>'table,value');
    my $table = $args{-table};
    my $field = $args{-field};
    my $value = $args{-value} || $args{-id};
    my $no_link = $args{-no_link};
    my $debug = $args{-debug};
        
    if (!$table) {
        if ( $field =~ /^FK[a-zA-Z]*\_(\w+)\_\_ID$/ixms ) {
            $table = $1;
        }
        elsif ($field =~/^(\w+)\_ID$/i) { $table = $1 }
        elsif ($field =~/^(\w+)\_Name$/i) { $table = $1 }
    }
    
    if ($table) {
        $table =~s/(\w+)\:\://;  ## trim leading scope if specified ... ## 
        $field ||= $self->primary_field($table);

        my $alias = $self->record_alias($table) || $field ;
        
        my $ref_table = $self->extend_Object_scope($table, $alias);
        
        my $display = $self->get_db_value(-table=>$ref_table, -field=>$alias, -condition=>"$field = '$value'", -debug=>$debug);

        my $ref;
        if ($field =~/\bName$/) { $ref = 'Name '}
        else { $ref = 'ID' }

        if ($table) {
            if ($no_link) { return $display }
            else { 
                my $link = Link_To( $self->homelink(), $display, "&HomePage=$table&$ref=$value", -tooltip => "Go to $display page" );
                return $link ;
            }
        }
    }
    
    return;
}

#####################
sub primary_field {
#####################
    my $self = shift;
    my $table = shift;
    
    my $Info = $self->fetch_query("show index from $table");
    
    foreach my $index (@$Info) {
        my $key = $index->{Key_name};
        my $column = $index->{Column_name};
        if ($key eq 'PRIMARY') { return $column }
    }

    return;
}

###################
sub record_alias {
###################
    my $self = shift;
    my $table = shift;
    my $field = shift;
    my $condition = shift;
    
    if ($field) { $condition = ''}

    my $field_info = $self->table_specs($table, -condition=>"Field_Index like 'PRI%'");

    my $fields = $field_info->{Field_Name} || $field_info->{Field};
    
    if (defined $field_info->{Key}) {
        foreach my $i (1..int(@{$fields}) ) {
            if ($fields->[$i-1] =~/\bName$/) { return $fields->[$i-1] }
        }
    }
    elsif (defined $field_info->{Field_Reference}) {
        return $field_info->{Field_Reference}[0];
    }
 
    return;
}

#
# Saves record based upon input data
#
# my $id = $dbc->save_Record(-table=>'Employee', -data=>{'Name' => 'John', 'Status' => 'Active'} ) 
#
# Return: new id
###################
sub save_Record {
###################
    my $self  = shift;
    my $table = shift;
    my $data  = shift;

    my $dbc = $self->dbc();

    my $field_info = $self->table_specs($table);

    my $fields     = $field_info->{Field} || $field_info->{Field_Name};

    my ( @add_fields, @add_values );
    foreach my $field (@$fields) {
        my $val = $data->{$field};

        if (ref $val eq 'ARRAY' && int(@$val) == 1) { $val = $val->[0] }
        
        if ($val) {
            push @add_fields, $field;
            push @add_values, $val;
        }
    }

    my $add_fields = join ",",     @add_fields;
    my $add_values = join "\",\"", @add_values;

    my $sql = "INSERT INTO $table ($add_fields) values (\"$add_values\")";

    my $id = $self->insert($sql);

    if ($id) {
        $BS->success("Generated $table record $id");
    }
    else {
        $BS->warning("No $table ID created");
    }
    
    return $id;
}

#
# Saves multiple records at one time based upon array of input values
#
# my $id = $dbc->save_Record(-table=>'Employee', -data=>{'Name' => ['John', 'Mary'], 'Status' => ['Active', 'Active']} ) 
#
# Return: array of new ids
###################
sub save_Records {
###################
    my $self  = shift;
    my $table = shift;
    my $data  = shift;

    my $field_info = $self->table_specs($table);

    my $field_list     = $field_info->{Field} || $field_info->{Field_Name};
    my $records = int( @{$data->{'Site_Name'}});  ## <CONSTRUCTION> .. remove ..

    my ( @add_fields, @add_values );
    my $k = 1;
    foreach my $field (@$field_list) {
        my $values = $data->{$field};
    
        foreach my $i (1..$records) {
            my $val;
            if ( ref $values eq 'ARRAY' && int(@{$values}) > 1) {
                $val = $values->[$i-1];
            }
            elsif (ref $values eq 'ARRAY') {
                $val = $values->[0];
            }
            else {
                $val = $values;
            }

            if (defined $val) {
                push @{$add_fields[$i-1]}, $field;
                push @{$add_values[$i-1]}, $val;
            }
        }

    }
    
    my @new_ids;
    foreach my $i (1..$records) {
        my $F = $add_fields[$i-1];
        my $V = $add_values[$i-1];
     
        my $add_fields = join ",",     @{$add_fields[$i-1]};
        my $add_values = join "\",\"", @{$add_values[$i-1]};

        my $sql = "INSERT INTO $table ($add_fields) values (\"$add_values\")";#
        my $sth  = $self->dbh->prepare($sql);

        my $ok = $sth->execute();
        
        if ($ok) {
            my $id = $self->dbh()->{'mysql_insertid'};
            push @new_ids, $id;
        }
        else {
            $self->error($DBI::errstr);
        }
    }

    print $BS->success("Added " . int(@new_ids) . " $table records...");

    return \@new_ids;    
}

##############
sub save_Update {
##############
    my $self  = shift;
    my %args  = @_;
    my $table = $args{-table};
    my $id    = $args{-id};
    my $data  = $args{-data};

    my $field_info = $self->table_specs($table);
    
    my $fields = $field_info->{Field_Name} || $field_info->{Field};
    
    my @fields     = @{ $fields };

    my @set_values;
    foreach my $field (@fields) {
        my $val = $data->{$field};
        if (defined $val) { push @set_values, "$field = \"$val\"" }
    }
    my $set_values = join ", ", @set_values;

    my $sql = "UPDATE $table SET $set_values WHERE ${table}_ID = $id";

    if ($set_values) { 
        my ($ok) = $self->execute_command($sql);
        return $ok;
    }
    return;
}

#
# Loads information on database field.
#
#  saves this info by default to avoid repetition 
#  option to load advanced field information via DB_Field table management 
#
# Return: & updates $self->{Field_Info} information if cached option indicated
##################
sub field_info {
###################
    my $self  = shift;
    my %args  = filter_input(\@_, -args=>'table');
    my $table = $args{-table};
    my $field = $args{-field};
    my $attribute = $args{-attribute};
    my $regenerate = $args{-regenerate};   ## regenerate info 
    my $debug = $args{-debug};
    
    if (!$table) {
        if ($field =~/^(\w+)\.(\w+)$/) {
            ## fully qualified field name instead of table specification ##
            $table = $1;
            $field = $2;
        }
        elsif ($field =~/^([a-zA-Z]+)\_([a-zA-Z]+)$/) {
            ## inferred table from simple field name (eg 'Plate_ID' ) ##
            $table = $1;
        }
    }
    
    my $cache = 1;
    
    my @std_attributes = qw(Field Type Null Key Default Extra);
    my @custom_attributes = qw(DBField_ID Field_Name Field_Type Field_Format Field_Default Field_Status Field_Order Prompt Field_Reference Field_Table Field_Options Editable Tracked Records List_Condition Field_Index Field_Description DBTable_Type Attach_Tables);
    
    my $index = 0;
    
    my $Field_Info;
    if (!$regenerate && defined $self->{Field_Info} && defined $self->{Field_Info}{$table} && $self->{Loaded_Field_Info}{$table}) {
        ## use cached value if supplied ##
        $Field_Info = $self->{Field_Info}{$table};
    }
    else {
        ## generate field information and cache it .. ##
        my $hash = $self->table_specs($table, -debug=>$debug);
        
        my ($fields, @attributes);
        if (defined $hash->{Field_Name}) {
            ## Use DBField attributes ##
            $fields = $hash->{Field_Name};
            @attributes = @custom_attributes;
        }
        else {
            $fields = $hash->{Field};
            @attributes = @std_attributes;
        }
        
         while (defined $fields->[$index]) {
             my $f = $fields->[$index];
            foreach my $att (@attributes) {
                $Field_Info->{$f}{$att} = $hash->{$att}[$index];
            }
            $index++;
            if ($cache) { 
                $self->{Field_Info}{$table} = $Field_Info;
                $self->{Loaded_Field_Info}{$table} = 1;
             };
        }
    }
    
    if ($field) { 
        if ($attribute) { return $Field_Info->{$field}{$attribute} }
        else { return $Field_Info->{$field} }
    }
     
    return $Field_Info;   
}


###################
sub enum_options {
###################
    my $self = shift;
    my %args  = filter_input(\@_, -args=>'field');
    my $table = $args{-table};
    my $field = $args{-field};
    
    if ($field =~/(.+)\.(.+)/ ) { $table = $1; $field = $2 }
    
    my $options = $self->field_info(-attribute=>'Field_Type', -table=>$table, -field=>$field);
    
    if ($options =~/ENUM\((.*)\)/i ) { 
        my @list = split /\s*,\s*/, $1;
        map { $_ =~s/^['"]//; $_ =~s/["']$//; } @list;
        return \@list;
    }
    
    return [];
}

###################
sub table_specs {
###################
    my $self  = shift;
    my %args       = filter_input( \@_, -args=>'table,condition');
    my $table = $args{-table};
    my $condition = $args{-condition} || 1; 
    my $debug = $args{-debug};

    my $hash;
    if ($self->table_loaded('DBField')) {
        $hash = $self->hash(-table=>'DBField,DBTable', -fields=>['*'], -condition=>"WHERE FK_DBTable__ID=DBTable_ID AND Field_Table = '$table' AND $condition ORDER BY Field_Order", -debug=>$debug);
    }
    else {
        $hash = $self->hash(-sql=>"DESC $table", -debug=>$debug);
    }
    
    return $hash;
}

############
sub fields {
############
    my $self  = shift;
    my $table = shift;

    my $field_info = $self->table_specs($table);
    
    my @fields;

    if (defined $field_info->{Field}) { @fields = @{ $field_info->{Field} } }               ## retrieved from DESC 
    elsif (defined $field_info->{Field_Name}) { @fields = @{ $field_info->{Field_Name} } }  ## retreived from DBField table 


    return \@fields;
}

sub test { return 'hello' }

#########
#########
#########

###################
sub auto_connect {
###################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbase      = $args{-dbase};
    my $host       = $args{-host};
    my $user       = $args{-user};
    my $pass       = $args{-password};
    my $SL         = $args{-SL};
    my $dbc        = $args{-dbc};                                 # Optionally pass in existing dbc
    my $login_file = $args{-login_file} || $self->{login_file};

    $self->{dbc} ||= $dbc || $self->connect(%args);               # keep track of dbc
}

############################################################
# Disconnect operator
# - make sure statement handle is finished
# - make sure connection is closed
# - essentially the same as destructor, but called manually
# RETURN: Nothing
############################################################
sub disconnect {
###################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'LampLite::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    #    if ($self->{transaction}) {
    #	    $self->{transaction}->finish(-force=>1);
    #    }

    my $returnval;

    if ( $self->{sth} ) { $self->{sth}->finish() }
    if ( $self->ping() ) {
        $returnval = $self->dbh->disconnect();
    }
    else {
        $returnval = undef;
    }
    $self->{connected} = 0;

    return $returnval;
}

#
# Simple accessor to set or retrieve class attributes
#
# Return: Attribute value (after setting if applicable)
#############
sub value {
#############
    my $self  = shift;
    my $field = shift;
    my $value = shift;

    if ($value) {
        $self->{attribute}{$field} = $value;
    }
    else { $value = $self->{attribute}{$field} }

    return $value;
}

######################
sub initialize_page {
######################
    my $self = shift;

    my $init_script = <<INIT;
// <html manifest='../cache/manifest.pl'>
<meta charset="utf-8">
<meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no, width=device-width">
<meta name="apple-mobile-web-app-capable" content="yes">

<LINK rel=stylesheet type='text/css' href='../css/mobile.css'>
<LINK rel='stylesheet' type='text/css' href='../css/socio.css'>
<link type="text/css" href="../skin/jplayer.blue.monday.css" rel="stylesheet" />
    

<script type="text/javascript"
      src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCsyK7DfqGJs73u4qpS2iEKDOdnp6SJxzQ&sensor=true">
</script>

<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js"></script>

<script src='../js/socio.js'></script>
<script src='../js/guide.js'></script>
<script src='../js/map.js'></script>
<script src='../js/iscroll.js'></script>
<script src='../js/contact_scroll.js'></script>

	<script type="text/javascript">
		/* Local JavaScript Here */
		var initScrolling = function() {
			var scroller = new iScroll('scroller', { bounceLock:true, desktopCompatibility: true});
			var buttons = document.getElementsByClassName("button");
			for (var i = 0, len = buttons.length; i < len; i++) {
				buttons[i].addEventListener("touchstart", function() {
					this.className = "button touched";
				});
				buttons[i].addEventListener("touchend", function() {
					this.className = "button";
				});
			}
		};
		document.addEventListener('DOMContentLoaded', initScrolling, false);
	</script>

INIT

    return $init_script;

    #<link type="text/css" href="../skin/jplayer.blue.monday.css" rel="stylesheet" />
    #<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js"></script>
    #<script type="text/javascript" src="../js/jquery.jplayer.min.js">
    #
    #

    #<LINK rel='stylesheet' type='text/css' href='../css/socio.css'>
    #<LINK rel=stylesheet type='text/css' href='../css/mobile.css'>
    #<LINK rel=stylesheet type='text/css' href='../css/tablet.css' media="screen">

    #<link rel="stylesheet" href="style.css" type="text/css" title="main" charset="utf-8">
    #<meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1.0, maximum-scale=1.0">
    #<meta name="apple-mobile-web-app-status-bar-style" content="black">
    #<meta name="apple-mobile-web-app-capable" content="yes">
    #<link rel="apple-touch-icon" href="apple-touch-icon.png">
    #<link rel="apple-touch-startup-image" href="splash.png">

}

#
# Simple wrapper to access or set dbc homelink parameters
#
# Optional clear parameter to strip current homelink of specified parameters
#
################
sub homelink {
################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'value' );
    my $value = $args{-value};
    my $clear = $args{-clear};                           # optionally clear specified parameters arguments

    if ( $self->config('homelink') && !$value && !$clear ) { return $self->config('homelink') }
    if ( $self->{homelink}         && !$value && !$clear ) { return $self->{homelink} }

    my $url_dir = $self->config('URL_domain');    ## why is this returning 1 when undefined ??!!

    my $homelink = $self->config('homelink');
    if ($value) {
        $homelink = $value;
         my $url_params = $self->config('url_parameters');
        if ($url_params) {
            $homelink .= '?';
            foreach my $param (@$url_params) {
                my $paramval = $self->config($param);
                $homelink .= "$param=$paramval&";
            }
        }
        $self->{homelink} = $homelink;
        $self->config( 'homelink', $homelink );
    }
    elsif ( $self->{homelink} ) { $homelink ||= $self->{homelink}; }
    elsif ( $url_dir) {  
        my $version = $self->config('version_name'); 
        my $dir = $self->config('URL_dir_name');  
        if ($dir) { $url_dir .= '/$dir' }
        if ($version &&  $version ne 'production') { $dir .= '_' . $version }
        $url_dir .= '/$dir/cgi-bin';
              
        my $file = $0;
        $file =~ s /^(.+)\///;
        $homelink = "$url_dir/$file";
        $self->{homelink} = $homelink;
    }

    if ($clear) {
        
        if ( $clear eq '1' ) { $homelink =~ s/[\?].*// }    ## Clear all parameters ... ##
        else {
            if ( !ref $clear ) { $clear = [$clear] }
            foreach my $clear_param (@$clear) {
                $homelink =~ s/([\?|\&])$clear_param\=[\w\s]*\&/$1/;    ## clear specified parameter
                $homelink =~ s/([\?|\&])$clear_param\=[\w\s]*$//xms;    ## clear specified parameter
            }
        }
    }

    if ( my $session = $self->config('session_id') ) {
        if ( $self->{homelink} !~ /CGISESSID\b/ ) { $self->{homelink} .= "?CGISESSID=$session" }
    }
    return $homelink;
}

##############
sub homelink_old {
###############
    my $self  = shift;
    my $value = shift;

    my $url_dir = $self->config('URL_dir') || "./../cgi-bin/";    ## why is this returning 1 when undefined ??!!

    if ($value) { $self->{homelink} = $value }
    elsif ( $self->{homelink} ) { }
    elsif ( $url_dir =~ /a-z/i ) {

        my $file = $0;
        $file =~ s /^(.+)\///;
        $self->{homelink} = "$url_dir/$file";
    }

    if ( my $session = $self->config('sid') ) {
        if ( $self->{homelink} !~ /\bCGISESSID\b/ ) { $self->{homelink} .= "?CGISESSID=$session" }
    }

    return $self->{homelink};
    ## return "http://sociolite.org/cgi-bin/$file";
}

## Simple Accessors ##
###########################################################
sub dbc { my $self = shift; return $self->{dbc} || $self }
###########################################################

sub Template { my $self = shift; return $self->{Template}; }
######################

#
# query generating table output directly
#
##################
sub query_Table {
##################
    my $self      = shift;
    my $query     = shift;
    my $field_ref = shift;
    my $dbc       = $self->dbc();

    my ( @fields, @tables, $condition );

    if ( $query =~ /^SELECT (.+) FROM /ixms ) {
        if ( !$field_ref ) {
            @fields = split /,\s*/, $1;
            $field_ref = \@fields;
        }
    }

    map { $_ =~ s/^(.*) AS (.*)$/$2/i; $_; } @$field_ref;    ## use labels if supplied ##

    my $results = $dbc->query($query);
    my $table = $dbc->query_output_table( $results, $field_ref );

    return $table;
}

###########
sub home {
###########
    return 'home';
}

#################################
#### Data Execution Methods ######
#################################

####################
sub execute_command {
####################
    #
    # This routine executes a non query command
    # (returns the number of records affected if successful)
    #
    my %args = &filter_input( \@_, -args => 'dbc,command', -mandatory => 'dbc|self', -self => 'LampLite::DBIO' );
    my $self     = $args{-self} || $args{-dbc};
    my $command  = $args{'-command'} || $args{-sql};
    my $feedback = $args{'-feedback'} || $args{-debug};

    my $fback = '';

    if ($feedback) { print "** $command **\n"; Call_Stack(); }

    unless ($command) { return; }

    if ( !$self ) { $fback .= "Error - need to re-establish connection\n"; return; }

    my $results;
    
    eval { $results = $self->dbh()->do(qq{$command}); };

    if ($@) {
        $fback .= "$@\n";
    }
    if ( $self->trans_started() ) { $self->error($fback) }

    if ( !$results ) {
        $fback .= "*** Error executing SQL: $DBI::err ($DBI::errstr)(" . now() . ").\n";
    }
    else {
        $results += 0;
        $fback .= "--- Executed SQL successfully ($results row(s) affected)(" . now() . ").\n";
    }

    # Returns the number of rows affected and also the newly created primary key ID.
    if ($feedback) { print "$fback. $results ( $self->{dbh}->{'mysql_insertid'} )\n" }
    return ( $results, $self->{dbh}->{'mysql_insertid'}, $fback );
}

###################################################
# Simple record append to a single table (though multiple records may be added at one time)
# (supply fields, and values for insertion)
#
# May supply multiple values in form:
#     $values{1} = ('1','b','George'); $values{2} = ('2','d','Julie');   (send -values=>\%values)
#   .. or single value in form:
#     @values = ('1','b','George');     ... and send -values=>\@values
#
# Table specification is optional, but is necessary to auto-update foreign keys or if multiple tables share field names.
#
# RETURN : %returnval.
#       $returnval{newids} = list of newids (primary values)
#       $returnval{updated} = # of records added
######################
sub append_DB_old {
######################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values', -mandatory => 'dbc|self', -self => 'LampLite::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table     = $args{-table};     # table to update
    my $field_ref = $args{-fields};    # fields to insert into
    my $value_ref        = $args{ -values };                               # values to insert
    my $sth              = $args{ -sth };                                  # (optional) - supplied statement handle (good for repeating commands)
    my $return_ref       = $args{-return};
    my $on_duplicate     = $args{-on_duplicate};
    my $autoquote        = $args{-autoquote};
    my $debug            = $args{-debug};

    my %returnval = %{$return_ref} if $return_ref;
    
    if (ref $value_ref eq 'ARRAY') {
        $value_ref = {'1' => $value_ref };
    }
    
    my %Values = %{$value_ref} if $value_ref;
    my @fields = Cast_List(-list=>$field_ref, -to=>'array');
    my $updated = 0;
    
    my @keys = keys %Values;
    unless (@fields) { $self->warning( "No fields in $table to update ?", -priority => 2 ) }

    # Search for primary value to see if it is specified (i.e. for cases like Library_Name is a primary value but not auto_increment)
    my ($primary_field) = $self->primary_field( $table);
    my @primary_values;
    my $records = int( keys %Values );
    
    for ( my $i = 0; $i < @$field_ref; $i++ ) {
        ## only applicable if primary values supplied as part of the input information (eg - only applicable for non-standard tables with no Autoincrement ID field) ##
        if ( $field_ref->[$i] =~ /^($primary_field|$table\.$primary_field)$/ ) {
            @primary_values = map { $Values{$_}->[$i] } ( 1 .. $records );
            last;
        }
    }
    
    my $no_primary = 0;
    my $command;
    if (! $sth && !($table && @fields && @keys) ){
        $self->error("Append requires statement handle or Table, Fields, Values");
    }
    elsif ( int(@keys) < 1 ) {
        $self->warning("No Values to append into $table(?!)");
    }
    elsif ( defined $sth && int(@keys) == 1) {    
        my @values  = @{ $Values{1} };
        if (!$sth) {
            
            $command = "INSERT $on_duplicate INTO $table (";
            $command .= join ',', @fields;
            $command .= ") values (";
            
            ## Prepare and Execute statement first time through
            my @emptylist = map { $_ = '?' } ( 0 .. $#values );
            $command .= join ",", @emptylist;
            $command .= ')';

            $sth = $self->dbh()->prepare($command);
            $self->message( "<BR>** PREPARE:$command.<BR>", -priority => 2 );

            $returnval{$table}{sth} = $sth;
            $self->message( "** (1st time) SEND @fields\n=@values\n", -priority => 2 );
            $updated = $sth->execute(@values);
            ### update object attributes for this method (to allow repeated calls..)
        }
        else {
            ### Insert statement already prepared ... add another record ... ###
             my @values = @{ $Values{1} };
            $updated = $sth->execute(@values);
            $returnval{$table}{sth} = $sth;
            if ( $self->dbh()->{'mysql_insertid'} ) {
                my $new_id = $self->dbh()->{'mysql_insertid'};
                $returnval{newids} = [ $new_id];
            }
            elsif ( $primary_values[0] ) {
                $returnval{newids} = [ $primary_values[0] ];
            }
            else {
                if ( !$on_duplicate ) { $self->warning("no primary value detected") }
                $no_primary++;
            }
            $self->message( ( "** (quick execute) SEND " . join ',', @fields ), -priority => 2 );
            $self->message( ( join ',', @values ), -priority => 2 );
        }
    }
    else {
        ### Normal process - one or more records at one time... (sth cannot be used if more than one record supplied at one time)
        $command = "INSERT $on_duplicate INTO $table (";
        $command .= join ',', @fields;
        $command .= ") values ";
        
        my $q;
        if ($autoquote) { $q = "\"" }
        foreach my $record ( sort { $a <=> $b } keys %Values ) {
            $command .= "($q";
            my @values = @{ $Values{$record} };
            $command .= join "$q\,$q", @values;
            $command .= "$q),";
        }
        chop $command;
        
         ($updated) = $self->execute_command($command);
 
        if ($updated && $primary_values[0] ) { $returnval{newids} = \@primary_values }
        elsif ($updated) {
            my $firstid = $self->dbh()->{'mysql_insertid'};

            my $lastid = $firstid + $updated - 1;
            $returnval{newids} = $firstid;
        }
        else {
            $self->warning("Problem adding records @$ ");
        }
        
        if ($debug) {
            $self->message( "Command:\n$command\n($updated)\n", -priority => 2 );
        }
    }
    $returnval{SQL_command} = $command;

    if ( $no_primary && $on_duplicate ) { $self->warning("Duplicate record(s) ignored") }

    return $returnval{newids};
}

###################################################
# Simple record append to a single table (though multiple records may be added at one time)
# (supply fields, and values for insertion)
#
# May supply multiple values in form:
#     $values{1} = ('1','b','George'); $values{2} = ('2','d','Julie');   (send -values=>\%values)
#   .. or single value in form:
#     @values = ('1','b','George');     ... and send -values=>\@values
#
# Table specification is optional, but is necessary to auto-update foreign keys or if multiple tables share field names.
#
# RETURN : %returnval.
#       $returnval{newids} = list of newids (primary values)
#       $returnval{updated} = # of records added
######################
sub append_DB {
######################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values', -mandatory => 'dbc|self', -self => 'LampLite::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table     = $args{-table};     # table to update
    my $field_ref = $args{-fields};    # fields to insert into
    my $value_ref        = $args{ -values };                               # values to insert
    my $sth              = $args{ -sth };                                  # (optional) - supplied statement handle (good for repeating commands)
    my $return_ref       = $args{-return};
    my $on_duplicate     = $args{-on_duplicate};
    my $autoquote        = $args{-autoquote};
    my $debug            = $args{-debug};

    my %returnval = %{$return_ref} if $return_ref;
    
    if (! ref $value_ref) {
        ## scalar value supplied ##
        $value_ref = [[ $value_ref ]];
    }
    elsif (ref $value_ref eq 'ARRAY') {
        ## array supplied - (normal) ## 
    
        if (ref $value_ref->[0] eq 'ARRAY') {
            ## multiple records at one time - (array of arrays) - normal ##
        }
        elsif (! ref $value_ref->[0] ) {
            ## single array only - convert to standard format ##
            $value_ref = [ $value_ref ];
        }
        else {
            $self->error("Improper format for append values.  Array of " . ref $value_ref->[0] . ' ?');
            return;
        }        
    } elsif (ref $value_ref eq 'HASH') {
        $self->debug_message("Phased out append structure");
        return $self->append_DB_old(%args);
    }
    
    my @Values = @{$value_ref};
    ## Values standardized to ([a1, a2], [b1, b2]) ##
    
    my @fields = Cast_List(-list=>$field_ref, -to=>'array');
    my $updated = 0;
    
    unless (@fields) { $self->warning( "No fields in $table to update ?", -priority => 2 ) }

    # Search for primary value to see if it is specified (i.e. for cases like Library_Name is a primary value but not auto_increment)
    my ($primary_field) = $self->primary_field( $table);
    my @primary_values;
    my $records = int(@Values);
    
    for ( my $i = 0; $i < @$field_ref; $i++ ) {
        ## only applicable if primary values supplied as part of the input information (eg - only applicable for non-standard tables with no Autoincrement ID field) ##
        if ( $field_ref->[$i] =~ /^($primary_field|$table\.$primary_field)$/ ) {
            @primary_values = map { $Values[$_][$i] } ( 1 .. $records );
            last;
        }
    }
    
    my $no_primary = 0;
    my $command;
    
    if (! $sth && !($table && @fields && @Values) ) {
        $self->error("Append requires statement handle or Table, Fields, Values");
    }
    elsif ( $records < 1) {
        $self->warning("No Values to append into $table(?!)");
    }
    elsif ( defined $sth && $records == 1) {    
        my @values  = $Values[0];
        if (!$sth) {
            $command = "INSERT $on_duplicate INTO $table (";
            $command .= join ',', @fields;
            $command .= ") values (";
            
            ## Prepare and Execute statement first time through
            my @emptylist = map { $_ = '?' } ( 0 .. $#values );
            $command .= join ",", @emptylist;
            $command .= ')';

            $sth = $self->dbh()->prepare($command);
            $self->message( "<BR>** PREPARE:$command.<BR>", -priority => 2 );

            $returnval{$table}{sth} = $sth;
            $self->message( "** (1st time) SEND @fields\n=@values\n", -priority => 2 );
            $updated = $sth->execute(@values);
            ### update object attributes for this method (to allow repeated calls..)
        }
        else {
            ### Insert statement already prepared ... add another record ... ###
             my @values = $Values[0];
            $updated = $sth->execute(@values);
            $returnval{$table}{sth} = $sth;
            if ( $self->dbh()->{'mysql_insertid'} ) {
                my $new_id = $self->dbh()->{'mysql_insertid'};
                $returnval{newids} = [ $new_id];
            }
            elsif ( $primary_values[0] ) {
                $returnval{newids} = [ $primary_values[0] ];
            }
            else {
                if ( !$on_duplicate ) { $self->warning("no primary value detected") }
                $no_primary++;
            }
            $self->message( ( "** (quick execute) SEND " . join ',', @fields ), -priority => 2 );
            $self->message( ( join ',', @values ), -priority => 2 );
        }
    }
    else {
        ### Normal process - one or more records at one time... (sth cannot be used if more than one record supplied at one time)
        $command = "INSERT $on_duplicate INTO $table (";
        $command .= join ',', @fields;
        $command .= ") values ";
        
        my $q;
        if ($autoquote) { $q = "\"" }
        foreach my $record (@Values) {
            $command .= "($q";
            my @values = @$record;
            $command .= join "$q\,$q", @values;
            $command .= "$q),";
        }
        chop $command;
        
         ($updated) = $self->execute_command($command);
 
        if ($debug) { $self->message($command) }
        
        if ($updated && $primary_values[0] ) { $returnval{newids} = \@primary_values }
        elsif ($updated) {
            my $firstid = $self->dbh()->{'mysql_insertid'};

            my $lastid = $firstid + $updated - 1;
            $returnval{newids} = $firstid;
        }
        else {
            $self->warning("Problem adding records @$ ");
        }
        
        if ($debug) {
            $self->message( "Command:\n$command\n($updated)\n", -priority => 2 );
        }
    }
    $returnval{SQL_command} = $command;

    if ( $no_primary && $on_duplicate ) { $self->warning("Duplicate record(s) ignored") }

    return $returnval{newids};
}

##############
sub update_DB {
##############
    my $self = shift;
    my %args  = filter_input( \@_, -args => 'table,fields,values,condition' );
    my $table = $args{-table};
    my $fields = $args{-fields};
    my $values = $args{-values};
    my $condition = $args{-condition} || 1;
    my $autoquote = $args{-autoquote};
    my $quiet = $args{-quiet};
    my $ids = $args{-id};

    $condition =~s/^WHERE //i;

    my @fields = Cast_List(-list=>$fields, -to=>'array');
    my @sets;
    foreach my $i (0..$#fields) {
        my $f = $fields->[$i];
        my $v = $values->[$i];

        if (! defined $v) { next }

        if (! length($v) || $autoquote) { $v = "'$v'" }
        push @sets,  qq($f = $v);
    }

    my $command = "UPDATE $table SET ";
    $command .= join ',', @sets;    
    $command .= " WHERE $condition";

    my $updated = $self->query($command)->execute();

    return $updated;
}

#############################
#### Transaction Methods ####
#############################

#########################################
# Get/Set the Transaction object
#########################################
sub transaction {
#########################################
    my $self  = shift;
    my $value = shift;    ##

    if ($value) {
        $self->{transaction} = $value;
    }

    return $self->{transaction};
}

###############
sub transactions {
###############
    my $self = shift;
    return $self->{transactions};
}

#######################
sub start_transaction {
#######################
    return start_trans(@_);
}

##############################
# Starts a transaction
##############################
sub start_trans {
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'name,message' );
    my $name    = $args{-name} || 'unnamed';
    my $message = $args{ -message };
    my $restart = $args{-restart};
    my $quiet   = $args{-quiet};
    my $debug   = $args{-debug} || $self->{debug_mode};

    unless ( $restart || $self->{transaction} ) {
        eval "require LampLite::Transaction";
        $self->{transaction} = LampLite::Transaction->new( -dbc => $self );
    }

    my $transaction = $self->{transaction}->start( $name, -quiet => $quiet, -debug => $debug );

    if ($message) { $transaction->message($message) }    ## initiate messages with input message
    return $transaction;
}

#######################
sub finish_transaction {
#######################
    return finish_trans(@_);
}

##############################
# Finishes a transaction
# pass in $@ from the eval
##############################
sub finish_trans {
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'name,error' );
    my $name    = $args{-name};
    my $message = $args{ -message };
    my $errors  = $args{ -error };
    my $quiet   = $args{-quiet};
    my $debug   = $args{-debug} || $self->{debug_mode};

    my $started = $self->{transaction}{start_times}[0];    ### Latest entry
    my $now     = timestamp();
    $self->{transaction_time} = $now - $started;

    $self->{transaction}->message($message) if $message;

    ## <CONSTRUCTION> need to also include start stop messages in Transaction module ##
    ## (and should establish Connection object within Transaction module (instead of dbc ?)...

    $errors = $self->parse_mySQL_errors($errors);

    #    $self->error("$errors")          if $errors;
    $self->message("Ending Transaction $name") if $debug;
    return $self->{transaction}->finish( $name, -error => $errors, -quiet => $quiet, -debug => $debug );
}

##############################
# Commits a transaction (bypasses error check used by finish)
##############################
sub commit_trans {
#####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'name,error' );

    my $name   = $args{-name};
    my $errors = $args{ -error };

    return $self->{transaction}->commit($name);
}

##############################
# Rollback a transaction
##############################
sub rollback_trans {
#########################################    
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'name,error' );
    my $name  = $args{-name};
    my $error = $args{ -error };

    if ($error) { $self->error("$error from $name") }

    return $self->{transaction}->rollback();
}

#########################################
# Query whether a transaction has started
#########################################
sub trans_started {
#########################################    
    my $self = shift;

    if ( $self->{transaction} ) {
        return $self->{transaction}->started();
    }
    else { return 0 }
}

########################################
# Get/Set transaction error
########################################
sub trans_error {
#########################################    
    my $self  = shift;
    my $value = shift;

    if ($value) {
        $self->{transaction}->error($value);
    }

    return $self->{transaction}->error();
}

#
# allows mysql error messages to be converted to more user friendly messages...
#
##############################
sub parse_mySQL_errors {
##############################
    my $self = shift;
    my $errors = shift;

    if ( $errors =~ /\bDBD::mysql::db\b/ ) {
        if ( $errors =~ /Duplicate entry (\S+)/i ) {
            $errors = "mySQL Error: Duplicate entry: $1 is already being used.";
        }
        else {
            $errors = "<B>mySQL error<B>: $errors";
        }
    }
    return $errors;
}

#########################################
######## Messaging Methods ###########
#########################################

#
# Accessor to turn on message deferral flag.
#
# Usage:
#
# $dbc->defer_messages();
#
# ...do stuff
#
# ... later dump messages out ...
#
# $dbc->flush_messages();
#
#####################
sub defer_messages {
#####################
    my $self = shift;

    $self->{defer_messages}    = 1;
    $self->{deferred_messages} = [];
    $self->{deferred_warnings} = [];
    $self->{deferred_errors}   = [];
    return 1;
}

#
# Simple wrapper for displaying debug details so that normal users are not inundated with meaningless information, but developers have access to debugging info
#
####################
sub debug_message {
####################
    my $self         = shift;
    my $message      = shift;
    my $user_message = shift;    ## optional message visible to std users

    $self->{debug_messages} ||= [];
    my $count = int( @{ $self->{debug_messages} } ) + 1;

    $message .= '<HR>';
    $message =~ s/\n/<BR>/g;

    my @stack = @{ Call_Stack( -quiet => 1 ) };
    foreach my $stack (@stack) { $message .= "$stack<BR>" }
    $message .= '<HR>';

    if ( !$self->{quiet} && $self->Site_admin ) { $self->warning("Site Admin Note: Debug messages directed to Debug Folder below") }

    ## include the warning in the session if applicable ##
    if ( $self->session() ) {
        $self->session()->warning( -value => $message );
    }
    if ($user_message) { $self->message($user_message) }

    push @{ $self->{debug_messages} }, "<H4>Debug Message $count</H4>$message";

    return;
}

#####################
sub flush_messages {
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $combine = $args{-combine};        ## combine messages together ... ##

    my $colours = { 'messages' => 'yellow', 'warnings' => 'orange', 'errors' => 'red' };
    $self->{defer_messages} = 0;

    foreach my $type ( 'errors', 'warnings', 'messages' ) {
        my $message_type = $type;
        chop $message_type;               ## remove plural .. for alert type ...

        my @list;
        if ( $self->{"deferred_$type"} && @{ $self->{"deferred_$type"} } ) {
            for my $value ( @{ $self->{"deferred_$type"} } ) {
                if ($combine) { push @list, $value }
                else {
                    $BS->alert( $value, -type => $message_type, -print => 1 );
                }
            }
            if ( $combine && @list ) {
                ## Print messages together within one combined alert message ##
                my $message = Cast_List( -list => \@list, -to => 'UL' );
                $BS->alert( $message, -type => $message_type, -print => 1 );
            }
        }
    }

    $self->{deferred_messages} = [];
    $self->{deferred_warnings} = [];
    $self->{deferred_errors}   = [];

    return;
}

############################################################
# Get or set the latest error. Also add the error to the list of errors
# RETURN: The latest error
############################################################
sub error {
##########
    my %args = &filter_input( \@_, -args => 'dbc,value,ignore,hide', -mandatory => 'dbc|self', -self => 'LampLite::DB' );
    my $self    = $args{-self} || $args{-dbc};
    my $value   = $args{-value};                         ## Error to be added [String]
    my $ignore  = $args{-ignore};                        ## option to ignore error (do not set success to 0)
    my $hide    = $args{-hide} || $args{-return_html};
    my $force   = $args{-force} || 0;                    ## force message onto list even if it is a repeat message.
    my $context = $args{-context} || $self->context();

    if ($value) {
        unless ( $force || grep /^\Q$value\E$/, @{ $self->{errors} } ) {
            push( @{ $self->{errors} }, $value );

            if ( $self->{defer_messages} ) {
                push @{ $self->{deferred_errors} }, $value;
                $hide = 1;
            }
            if ( $self->{session} ) { $self->session()->error(%args) }    ## handle message through session object if applicable

            if ( $context eq 'html' ) { return $BS->error( $value, -print => !$hide ) }
            else                      { return Message( $value, -colour => 'orange', -return_html => $hide ) || $value }
        }
        return $value;
    }
    else {
        if ( $self->{errors} ) {
            my @errors = @{ $self->{errors} };
            return $errors[ $#errors - 1 ];
        }
        else {
            return '';
        }
    }
}

############################################################
# Get or set the errors
# RETURN: The errors occured (array ref)
############################################################
sub errors {
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    @_ ? ( $self->{errors} = $_[0] ) : $self->{errors};
}

############################################################
# Get or set the latest warning. Also add the error to the list of warnings
# RETURN: The latest warning
############################################################
sub warning {
##############
    my %args = &filter_input( \@_, -args => 'dbc,value,ignore,hide', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    my $value   = $args{-value};                         ## Error to be added [String]
    my $hide    = $args{-hide} || $args{-return_html};
    my $context = $args{-context} || $self->context();
    my $force   = $args{-force} || 0;                    ## force message onto list even if it is a repeat message.
    my $subtext = $args{-subtext};

    my $quiet = $self->{quiet};

    if ($value) {
        unless ( $force || grep /^\Q$value\E$/, @{ $self->{warnings} } ) {
            push( @{ $self->{warnings} }, $value );
            $value = "<Font size=+1>$value</Font>\n";

            if ( $self->{defer_messages} ) {
                push @{ $self->{deferred_warnings} }, $value;
                $hide = 1;
            }

            if ( $self->{session} ) { $self->session()->warning( %args, -quiet => $quiet ) }    ## handle message through session object if applicable

            if ( $context eq 'html' ) { return $BS->warning( $value, -print => !$hide ) }
            elsif ( !$self->{quiet} ) { return Message( $value, $subtext, -type => $context, -colour => 'orange', -return_html => $hide ) || $value }
        }
    }
    else {
        if ( $self->{warnings} ) {
            my @warnings = @{ $self->{warnings} };
            return $warnings[ $#warnings - 1 ];
        }
        else {
            return '';
        }
    }
}

############################################################
# Get or set the warnings
# RETURN: The warnings occured (array ref)
############################################################
sub warnings {
###############
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    @_ ? ( $self->{warnings} = $_[0] ) : $self->{warnings};
}

#################
sub clear_messages {
#################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    $self->{messages} = [];
    return;
}
#################
sub clear_warnings {
#################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    $self->{warnings} = [];
    return;
}
#################
sub clear_errors {
#################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    $self->{errors} = [];
    return;
}

##############
sub context {
##############
    my $self = shift;

    my $context = $self->config('context');

    unless ($context) {
        if ( $0 =~ /ajax/i ) {
            $context = 'ajax';
        }
        elsif ( $0 =~ /Web_Service/i ) {
            $context = 'text - web_service';
        }
        elsif ( $0 =~ /\.html$/ || $0 =~ /\/cgi-bin\// ) {
            $context = 'html';
        }
        elsif ( $0 =~ /\.xml$/ ) {
            $context = 'xml';
        }
        elsif ( $0 =~ /\bbin\b/ ) {
            $context = 'text';
        }
        else {
            $context = 'text';
        }
        $self->config( 'context', $context );
    }

    return $context;
}

############################################################
# Get or set the latest message. Also add the error to the list of messages
#
# Priority levels (optional) allow specification of priority (0 = always show ... 5 = very verbose)
#
# RETURN: The latest message
############################################################
sub message {
##############
    my %args = &filter_input( \@_, -args => 'dbc,value', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self     = $args{-self} || $args{-dbc};
    my $value    = $args{-value};                           ## Error to be added [String]
    my $hide     = $args{-hide} || $args{-return_html};
    my $priority = $args{-priority} || 5;                   ## set priority : never = 1 ... always = 5
    my $force    = $args{-force} || 0;                      ## force message onto list even if it is a repeat message.
    my $context  = $args{ -context } || $self->context();
    my $defer    = $args{ -wait };
    my $type     = $args{-type};                            ## only used to vary type of bootstrap message class generated to screen - eg 'success', 'info', or 'message' (default)

    my $quiet = $self->{quiet};

    my $index = int( @{ $self->{messages} } );
    $self->{message_priority}->{$index} = $priority;

    #if ($priority >= $self->{messaging}) { &RGTools::RGIO::Message($value) }

    if ($value) {
        if ( $force || !( grep /^\Q$value\E$/, @{ $self->{messages} } ) ) {
            push( @{ $self->{messages} }, $value );

            if ( $self->{defer_messages} ) {
                $hide = 1;
                push @{ $self->{deferred_messages} }, $value;
            }

            if ( $priority >= $self->{messaging} ) {
                ## Display message to user

                if ( $self->{session} ) { $self->session()->message( %args, -quiet => $quiet ) }    ## handle message through session object if applicable
                                                                                                    #               else                      { Message(%args) }

                if ( $context eq 'html' ) { return $BS->message( $value, -type => $type, -print => !$hide ) }
                elsif ( !$quiet ) { return Message( $value, -return_html => $hide, -type => $context ) }
            }
            else {
                if ( $context eq 'html' ) { return $BS->message( $value, -type => $type, -print => 0 ) }
                elsif ( !$quiet ) { return Message( $value, -no_print => 1) }
            }
        }
    }
    else {
        if ( $self->{messages} ) {
            my @messages = @{ $self->{messages} };
            return $messages[ $#messages - 1 ];
        }
    }

    return '';
}

############################################################
# Get or set the messages
#
# RETURN: Array of messages sent
############################################################
sub messages {
################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'self|dbc', -self => 'LampLite::DB' );
    my $self     = $args{-self}       || $args{-dbc};
    my $format   = $args{'-format'}   || 'text';
    my $priority = $args{'-priority'} || 5;             ## set priority : never = 1 ... always = 5
    my $separator = "\n";

    if    ( $format =~ /html/i ) { $separator = "<BR>" }
    elsif ( $format =~ /text/i ) { $separator = "\n" }

    my $i = 0;
    my @messages;
    foreach my $message ( @{ $self->{messages} } ) {
        if ( $priority >= $self->{message_priority}->{ $i++ } ) {
            push( @messages, $message );
        }
    }
    return \@messages;
}

#
# Accessor to test field to see if it is a media type field
#
#
# Return: extension if recognized media field
###################
sub media_field {
###################
    my %args = &filter_input( \@_, -args => 'field', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    my $field = $args{-field};

    if ($field =~/(Audio|Image|Video)/) {
        return $1;
    }
    
    return;
}

###########################
sub foreign_key_check {
###########################
    #
    # Check if a field name corresponds to foreign key format
    #
    # Return target Table, target field if foreign key.
    #
    my %args = &filter_input( \@_, -args => 'field,class', -self => 'LampLite::DB' );
    my $self = $args{-self} || $args{-dbc};

    my $field = $args{-field};
    my $class = $args{-class};
    my $group = $args{-include_group_concat};    ## include group_concat ##
    my $debug = $args{-debug};

    if ( $class =~ /^\d+$/ ) {
        ## convert ID to class name ##
        $class = $self->get_db_value( -table=>'Object_Class', -field=>'Object_Class', -condition=>"Object_Class_ID = $class" );
    }

    my $TableName;                               ### target table
    my $target;                                  ### target field name
    my $descrip;                                 ### description of field...

    if ( $field =~ /^(\w+)\.(\w+)/ ) {
        ## truncate .. AS Alias if applicable ? ##
        $field = $2;
    }

    ############# Custom Insertion (Foreign Key specification) #################
    if ($group) {
        $field =~ s /^GROUP_CONCAT\((.*)\)/$1/i;
    }
    $field =~ s/^DISTINCT //i;                   ## ignore leading 'Distinct' spec
    $field =~ s/^(\w+)\.//;

    if ( $field =~ /^FK([A-Za-z0-9]*?)_(\S+)__(\S+)/i ) {
        ## changed to prevent matching of Concat.. CASE variations ##
        $TableName = $2;
        $target    = "$2_$3";
        $descrip   = $1;
    }
    elsif ( ( $field eq 'Object_ID' ) && $class ) {
        ## Special case : Object_ID references another record dynamically (references the id in the '$class' table)
        $TableName = $class;
        $target    = $class . "_ID";
    }
    else { return () }

    ############# End Custom Insertion (Foreign Key specification) #################
    my @list = ( $TableName, $target, $descrip );
    return @list;
}

#
# Wrapper to simplify use of Benchmarks within dbc session
#
#
#
#################
sub Benchmark {
#################
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

#    if ( !$self->{benchmarking} ) {return}

    require Benchmark;
    if ($key) {
        if ( defined $self->{Benchmark}{$key} ) {
            my $i = 1;
            while ( defined $self->{Benchmark}{"$key.$i++"} ) { }
            $key = "$key.$i";
        }

        if ($value) {
            $self->{Benchmark}{$key} = $value;
        }
        else {
            $self->{Benchmark}{$key} = new Benchmark();
        }
        return $self->{Benchmark}{$key};
    }

    return $self->{Benchmark};
}

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

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
