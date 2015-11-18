###################################################################################################################################
# LampLite::User.pm
#
# Basic HTML based tools for LAMP environment
#
###################################################################################################################################
package LampLite::User;

use base LampLite::DB_Object;

use strict;

use CGI;
my $q = new CGI;
#########
sub new {
#########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $user_id    = $args{-id} || $args{-user_id};
    my $user_name  = $args{-name} || $args{-user_name};
    my $initialize = $args{-initialize};                                                              ## initialize session settings (calls define_User if id supplied)
    my $table       = $args{-table} || $dbc->config('login_type') || 'User';
    
    my $retrieve = $args{-retrieve};                                                                  ## retrieve information right away [0/1]
    my $verbose  = $args{-verbose};

    if ( $user_name && !$user_id ) {
        $user_id = get_User_ID( $dbc, $user_name );
    }

    my $self = $this->LampLite::DB_Object::new(-dbc=>$dbc, -table=>$table, -id=>$user_id, -load=>$user_id);

    bless $self, $class;

#    $self->{id}      = $user_id;
#    $self->{DB_table} = $table;  

    $self->{user_id} = $user_id;
    $self->{dbc}     = $dbc;
    $self->{records} = 0;          ## number of records currently loaded

    $self->{id_field} = $self->id_field($table);
    $self->{name_field} = $self->name_field($table);
    $self->{email_field} = $self->email_field($table);

    if ($user_id && $initialize)  { $self->define_User(); }

    return $self;
}

###############
sub id_field {
###############
    my $self = shift;
    return $self->{DB_table} . '_ID';
}

###############
sub name_field {
###############
    my $self = shift;
    return $self->{DB_table} . '_Name';
}

###############
sub email_field {
###############
    my $self = shift;
    return 'Email_Address';
}

#########################
sub get_User_ID {
#########################
    my $self      = shift;
    my $user_name = shift;
    my $dbc       = $self->{dbc};

    my ($user_id) = $dbc->Table_find( $self->{DB_table}, $self->{id_field}, "WHERE $self->{name_field} = '$user_name' OR $self->{email_field} = '$user_name'" );
    return $user_id;
}

###################
sub define_User {
###################
    my $self = shift;

    my $id  = $self->{id};
    my $dbc = $self->dbc();
    
    $self->load_Object();
    
    unless ($id) { $dbc->message("No $self->{DB_table} ID supplied"); Call_Stack(); return 0; }

    # SPECIAL RULE: if user is a member of Site Admin, grant access as if user is Admin
    
    my $table = $self->{DB_table};
    my $id_field = $self->{id_field};    
    my $name_field = $self->{name_field};    
    
    if ($id) {
        my $name = $dbc->get_db_value(-sql=>"SELECT $name_field from $table WHERE $id_field = '$id'");
        $dbc->config('user_name', $name);
        $self->{user_name} = $name;
    }
    
    my $url_param = $dbc->config('url_parameters');
    my $session_param = $dbc->config('session_parameters');
    
    if ($url_param) { 
        foreach my $param (@$url_param) {
            ## pass url_parameters as config settings ##
            my $val = $q->param($param);
            $dbc->config($param, $val);
        }
    }
    
    my @reset = ('Target_Department');

# my $homelink = $dbc->config('homelink') || $dbc->homelink($dbc->config('home'));
#   
#    foreach my $param (@reset) {
#        my $newval   = $dbc->config($param);
#        my $homelink = $dbc->config('homelink');
#        
#        if ( $newval && $homelink !~ /\b$param=/ ) {
#            my $homelink = "$homelink&$param=" . $dbc->config($param);
#            $dbc->config( 'homelink', $homelink );
#        }
#        elsif ( $newval && $homelink =~ s/\b$param=(.*)&/$param=$newval&/ ) {
#            $dbc->config( 'homelink', $homelink );
#        }
#    }
#
#    my $homelink = $dbc->config('homelink');    
    
    if ( $dbc->session() ) {
        $self->load_User_Settings( -department => $dbc->config('Target_Department') );
        ## temporary - define Session as soon as User defined ##
        $dbc->session->{user_id} = $id;

        my ( $session_id, $session_name ) = $dbc->session->generate_session_id();
        
#        if ( $session_id && $homelink =~ s/\bCGISESSID=&/CGISESSID=$session_id&/ ) {
#            $dbc->config( 'homelink', $homelink );
#        }
        
        if ($session_param) {
            ## set persistent session parameters ##
            foreach my $param ( @$session_param ) {
                 my $current = $dbc->session->param($param);
                my $val = $dbc->config($param) || $dbc->{$param}; # || $dbc->session->param($param);                  
                if ($val ne $current) { 
                    $dbc->session->{reset_parameters} = 1; 
                }
                $dbc->session->set_persistent_parameters([$param], [$val]);
            }
        }
        
        $dbc->config( 'CGISESSID',    $session_id );
        $dbc->config( 'session_id',   $session_id );
        $dbc->config( 'session_name', $session_name );
    }
        
#    $dbc->config('User', $self);
    return 1;
}

############################################################
# Load Settings as set by individual users if available
#
#
##########################
sub load_User_Settings {
##########################
    my $self = shift;
    my %args = @_;

    my $dbc        = $args{-dbc} || $self->{dbc};
    my $department = $args{-department};
    my $reload     = $args{-reload};
    my $debug      = $args{-debug};

    my $table = $self->{DB_table};
    my $id_field = $self->{id_field};
    my $user_id = $self->{id};

    my $department_setting = $dbc->session->param('department_setting');
    if ( $dbc->session->user_setting('LOADED') ) { return 1 }    ## already loaded ##

    my $department_id = $dbc->get_db_value(-sql=>"SELECT Department_ID FROM Department WHERE Department_Name like '$department'");
    $department_id ||= $dbc->get_db_value(-sql=>"SELECT FK_Department__ID from $table WHERE $id_field = $user_id");

    ### Load default settings
    my $Settings = $dbc->hash(-table=>'Setting', -fields=>[ 'Setting_Name', 'Setting_Default' ] );

    if ($Settings) {
        ### Load department settings for current department
        my $dept_settings_hash = $dbc->hash(
            -table     => 'Setting LEFT JOIN DepartmentSetting ON FK_Setting__ID=Setting_ID',
            -fields    => [ 'Setting_Name', 'Setting_Default', 'Setting_Value' ],
            -condition => "WHERE FK_Department__ID = $department_id",
        );

        ### Load user settings
        my $user_settings_hash = $dbc->hash(
                    -table     => "Setting LEFT JOIN ${table}Setting ON FK_Setting__ID=Setting_ID",
                    -fields    => [ 'Setting_Name', 'Setting_Default', 'Setting_Value' ],
                    -condition => "WHERE (FK_${table}__ID = $user_id OR FK_${table}__ID IS NULL)",
        );
        
        my $index = 0;
        while ( defined $Settings->{Setting_Name}[$index] ) {
            my $setting = $Settings->{Setting_Name}[$index];
            my $default = $Settings->{Setting_Default}[$index];

            if ( defined $dbc->session->user_setting($setting) ) { $index++; next; }
            my $default_type = 'Std';

            my $dept_value;
            if ( defined $dept_settings_hash->{Setting_Value}[$index] ) {
                $dept_value = $dept_settings_hash->{Setting_Value}[$index];
                if ($dept_value) { $default_type = 'Dept' }
            }

            my $user_value;
            if ( defined $user_settings_hash->{Setting_Value}[$index] ) {
                $user_value = $user_settings_hash->{Setting_Value}[$index];
                if ($user_value) { $default_type = $self->{DB_table} }
            }
            
            my $setting_value = $user_value || $dept_value || $default;    # Order of precedence is user setting > department setting > default setting
            $dbc->session->user_setting( $setting, $setting_value );

            #$dbc->message("$setting set to $setting_value [ $default_type Default ]");
            $index++;
        }
    }

    my ($user);
    $dbc->session->user_setting("LOADED", 1);
    $dbc->session->param( 'department_setting', $department );
    $dbc->session->param( 'user_name', $dbc->config('user_name') );

    return 1;
}

###################
sub get_Settings {
###################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->{dbc};
    my $setting = $args{-setting};
    my $scope   = $args{-scope};

    my $table = $self->{DB_table};
    my $id_field = $self->{id_field};

    my $setting_condition;
    if ($setting) { $setting_condition = " AND Setting_Name = '$setting'" }

    my $emp_id = $self->{id};
    my $tables = "$table, Setting";
    my $case;
       
    if ( !$scope || $scope =~ /^Emp/i ) {
        $tables .= " LEFT JOIN ${table}Setting ON $self->{DB_table}Setting.FK_${table}__ID = $id_field AND ${table}Setting.FK_Setting__ID=Setting_ID";
        $case   .= " WHEN ${table}Setting.FK_Setting__ID IS NOT NULL THEN ${table}Setting.Setting_Value";
    }
    if ( !$scope || $scope =~ /^Dep/i ) {
        $tables .= " LEFT JOIN DepartmentSetting ON DepartmentSetting.FK_Department__ID=$table.FK_Department__ID AND DepartmentSetting.FK_Setting__ID=Setting_ID";
        $case   .= ' WHEN DepartmentSetting.FK_Setting__ID IS NOT NULL THEN DepartmentSetting.Setting_Value';
    }

    if   ($case) { 
        if (!$scope) { $case .= " ELSE Setting_Default END as Value" }
        $case = "CASE $case END AS Setting";
    }
    else         { $case = 'Setting_Default' }

    my %settings = $dbc->hash(-tables=>$tables, -fields=>[ 'Setting_ID', 'Setting_Name', $case ], -condition=>"WHERE $id_field = $emp_id $setting_condition");

    if ($setting) {
        return $settings{Value}[0];
    }
    else {
        return \%settings;
    }
}

#
# Wrapper to set and/or retrieve id
#
#
##########
sub reset {
##########
    my $self = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};
    my $user_id   = $args{-id} || $args{-user_id};
    
    if ($dbc) { 
#        $self->{dbc} = $dbc;
        $self->SUPER::reset($dbc);
    }
    
    if ($user_id) {
        $self->{id} = $user_id;
        $self->primary_value( -table => $self->{DB_table}, -value => $user_id );
        $self->load_Object();
    }
    
    return $user_id;
}

#
# Accessor to name of Grp / User join table 
#
#
#
#######################
sub group_join_table {
#######################
    my $self = shift;
    my %args      = @_;
    my $table = $args{-table};
    
    if (!$table) {
        my $dbc       = $args{-dbc} || $self->dbc();
        $table ||= $self->{DB_table} || $dbc->config('login_type') || 'Employee';
    }
    
    my $grp_jt = "${table}_Grp";
    if ($table eq 'Employee') { $grp_jt = 'GrpEmployee'}  ## legacy support ... ##

    return ($grp_jt, "FK_${table}__ID");
}

1;
