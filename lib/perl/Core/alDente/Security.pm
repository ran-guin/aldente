###################################################################################################################################
# Security.pm
#
# This object controls access to LIMS components.
#
# $Id: Security.pm,v 1.41 2004/11/30 23:15:18 jsantos Exp $
###################################################################################################################################
package alDente::Security;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Security.pm - This object controls access to LIMS components.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This object controls access to LIMS components.<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(Object);

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

#use Storable;

##############################
# custom_modules_ref         #
##############################

### Reference to alDente modules

use alDente::Validation;

use RGTools::RGIO;
use RGTools::Object;
use RGTools::RGmath;

use alDente::SDB_Defaults;
use SDB::CustomSettings;

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Settings $dbase $version_number $Current_Department );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Modular variables
my %Employee_Name;
my %Department_ID;
my %Group_ID;
my %Department_Group;
my %Group_Name;

##############################
# constructor                #
##############################

############################################################
# Constructor of the object
# RETURN: The object itself
############################################################
sub new {
##########
    my $this = shift;
    my $class = ref($this) || $this;

    my %args    = @_;
    my $frozen  = $args{-frozen} || 0;                                                              # Reference to frozen object if there is any (optional) [Object]
    my $encoded = $args{-encoded} || 0;                                                             # Flag indicate whether object was encoded (optional) [Bool]
    my $dbc     = $args{-dbc};    # Database handle
    my $user_id = $args{-user_id} || 0;                                                             # User ID
    my $user    = $args{-user} || '';                                                               # User name
    my $db_host = $args{-host} ;                        # Database host
    my $db      = $args{-dbase};                                   # Keep track of the database the user logged in to

    my $self = $this->Object::new( -frozen => $frozen, -encoded => $encoded );
    bless $self, $class;
    
    if ($frozen) {                                                                                  # If frozen then reconnect to the database and return the object
        if ($dbc) {                                                                                 # If database handle is passed in then use this new one
            $self->{dbc} = $dbc;
        }
        return $self;
    }

    $self->{dbc}                       = $dbc;
    $self->{checks}                    = {};                                                        # All the security checks that can be done
        
    if (my $Security = $dbc->config('Security')) {
        $self->{login} = $Security;
    } 
    else {
        $self->{login}->{host}             = $db_host;                                                  # Database host
        $self->{login}->{dbase}            = $db;                                                       # Database logged into
        $self->{login}->{user}             = $user;                                                     # Username
        $self->{login}->{user_id}          = $user_id;                                                  # User ID
        $self->{login}->{groups}           = {};                                                        # Groups that the user belongs to
        $self->{login}->{departments}      = {};                                                        # Departments that the user belongs to
        $self->{login}->{LIMS_admin}       = 0;                                                         # Whether the user is a LIMS admin (specical flag to bypass all permission checks)
        $self->{login}->{groups_list}      = 0;                                                         # A comma-delimited list of group ids
        $self->{login}->{departments_list} = '';                                                        # A comma-delimited list of department ids

        $self->_initialize();
    }
       
    return $self;
}

##############################
# public_methods             #
##############################

#####################################
# Retrieves the login info
# RETURN: The login hash ref
#####################################
sub login_info {
#################
    my $self = shift;

    return $self->{login};
}

#####################################
# Retrieves the departments
# RETURN: Ref to array
####################
sub departments {
###################
    my $self = shift;

    my $ret = [];
    if ( $self->{login}->{departments} ) {
        @{$ret} = map { $self->{login}->{departments}->{$_}->{name} } ( keys %{ $self->{login}->{departments} } );
    }

    return $ret;
}

#####################################
# Return whether the user is LIMS admin
# RETURN: Whether it is true or false
#####################################
sub LIMS_admin {
    my $self = shift;

    return $self->{login}->{LIMS_admin};
}

##############################################################
# Return the user access of the department
##############################################################
sub department_access {
########################
    my $self       = shift;
    my $department = shift;
    my $dbc        = $self->{dbc};
    if ( !$department ) { $department = $dbc->config('Target_Department') }
    if ( $self->{login}->{LIMS_admin} == 1 ) {    # Allow access to everything
        return 'Lab,Admin,Guest,Report,Bioinformatics';
    }
    else {
        my $access = 'no access';
        foreach my $dept_id ( keys %{ $self->{login}->{departments} } ) {
            if ( $self->{login}->{departments}->{$dept_id}->{name} eq $department ) {
                $access = $self->{login}->{departments}->{$dept_id}->{access};
                last;
            }
        }
        return $access;
    }
}

#########################################
# Checks the permission
# RETURN: Whether the user has permission
#########################################
sub check {
    my $self  = shift;
    my $check = shift;

    my $retval = 0;

    if ( $self->{login}->{LIMS_admin} == 1 ) {    # Allow access to everything
        $retval = 1;
    }
    elsif ($check) {
        if ( defined $self->{checks}->{$check} ) {
            my %departments = %{ $self->{checks}->{$check} };
            foreach my $department ( keys %departments ) {
                my $dept_id = $Department_ID{$department};
                my $access  = $departments{$department};
                $access =~ s/,/\|/g;
                if ( exists $self->{login}->{departments}->{$dept_id} && $self->{login}->{departments}->{$dept_id}->{access} =~ /($access)/ ) {
                    $retval = 1;
                    last;
                }
            }
        }
    }

    return $retval;
}

#########################################
# Checks the permission
# RETURN: Whether the user has permission for the specified department and access
#
# This method is to replace check().
# check() uses %Department_ID, which is supposed to be initialized from %Std_Parameters.
# However, %Std_Parameters is phased out, so %Department_ID is not initialized, thus it affects the check() method.
#
# This method checks department access permission from $self->{login}{departments}.
#########################################
sub check_permission {
    my $self       = shift;
    my $department = shift;
    my $access     = shift;

    my $retval = 0;

    if ( $self->{login}->{LIMS_admin} == 1 ) {    # Allow access to everything
        $retval = 1;
    }
    elsif ( $department && $access ) {
        foreach my $dept_id ( keys %{ $self->{login}->{departments} } ) {
            if ( $self->{login}->{departments}{$dept_id}{name} eq $department && $self->{login}->{departments}{$dept_id}{access} =~ /($access)/ ) {
                $retval = 1;
                last;
            }
        }
    }

    return $retval;
}

############################################################
# Gets the records that are accessible by the current user
# RETURN: Reference to an array of item names
############################################################
sub get_accessible_items {
############################
    my $self            = shift;
    my %args            = @_;
    my $dbc             = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table           = $args{-table};                                                                    # The table where the items belong to
    my $blank           = $args{-blank};
    my $extra_condition = $args{-extra_condition};                                                          # Extra condition for the SELECT
    my $groups_list     = $args{-group_list};
    my $order           = $args{-order_by};
    my $debug           = $args{-debug};
    my @items;
    my $tables_list;
    my $condition;

    $groups_list ||= $dbc->get_local('group_list') || 0;                                                    ## much easier...

    my $Current_Department = $dbc->config('Target_Department');

    if ( $Current_Department && $dbc->Table_find( 'DBTable,DBField', 'DBField_ID', "where DBTable_ID = FK_DBTable__ID and DBTable_Name = '$table' and Field_Name = 'FK_Department__ID'" ) ) {

        # If records associated to an entire department, filter on department #
        $tables_list = "$table,Department";
        $condition   = "where FK_Department__ID=Department_ID AND Department_Name = '$Current_Department'";
    }
    elsif ( $dbc->Table_find( 'DBTable', 'DBTable_ID', "where DBTable_Name = 'Grp$table'" ) ) {

        # If grp association is many-to-many # ok
        $tables_list = "$table,Grp$table,Grp";
        $condition   = "where Grp$table.FK_Grp__ID=Grp_ID AND $table." . $table . "_ID = Grp$table.FK_" . $table . "__ID and FK_Grp__ID in ($groups_list)";
        if ($Current_Department) {
            $tables_list .= ",Department";
            $condition   .= " AND Grp.FK_Department__ID=Department_ID AND Department_Name = '$Current_Department'";
        }
    }
    elsif ( $dbc->Table_find( 'DBTable,DBField', 'DBField_ID', "where DBTable_ID = FK_DBTable__ID and DBTable_Name = '$table' and Field_Name = 'FK_Grp__ID'" ) ) {

        # If grp association is one-to-many #
        if ($Current_Department) {
            $tables_list = "$table,Grp,Department";
            $condition .= "WHERE $table.FK_Grp__ID=Grp_ID AND Grp_ID in ($groups_list) AND Grp.FK_Department__ID=Department_ID AND Department_Name = '$Current_Department'";
        }
        else {
            $tables_list = $table;
            $condition   = "where FK_Grp__ID in ($groups_list)";
        }
    }
    else {    # If no grp association then just return all records
        $tables_list = $table;
    }

    if ($extra_condition) { $condition .= " AND $extra_condition" }

    unless ($order) {
        $order = $table . "_Name";
    }

    @items = $dbc->Table_find( $tables_list, $table . '_Name', "$condition Order by " . $order, -distinct => 1, -debug => $debug );

    if ($blank) { unshift( @items, '' ) }    ## add a blank entry at the beginning

    return \@items;
}

##########################################
# Gets or Sets the security checks
##########################################
sub security_checks {
    my $self       = shift;
    my $checks_ref = shift;

    if ($checks_ref) {
        $self->{checks} = $checks_ref;
    }

    return $self->{checks};
}

#######################################################
# Generate list for popup menu based on security checks
#######################################################
sub generate_popup_choices {
##############################
    my $self      = shift;
    my $list_ref  = shift;
    my $label_ref = shift;    # If labels are passed in then it will be used for the ordering

    my @choices;
    my %labels;
    foreach my $item ( keys %{$list_ref} ) {
        my %departments = %{ $list_ref->{$item} };
        foreach my $department ( keys %departments ) {
            my $access = $departments{$department};
            $access =~ s/,/\|/g;
            if ( $department eq $Current_Department && ( $self->department_access($department) =~ /\b$access\b/ || $self->LIMS_admin() ) ) {
                if   ( exists $label_ref->{$item} ) { $labels{ $label_ref->{$item} } = $item }
                else                                { $labels{$item}                 = $item }
                last;
            }
        }
    }

    @choices = map { $labels{$_} } sort keys %labels;

    return \@choices;
}

##################################################
# Get group IDs or names based on several criteria
##################################################
sub get_groups {
#################  OLD - replace with $Connection->get_local('groups');
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $department_id   = $args{-department_id};
    my $department_name = $args{-department_name};
    my $return          = $args{ -return } || 'id';

    my @grps;

    # Resolve department ID if department bame given
    if ($department_name) {
        $department_id = $Department_ID{$department_name};
    }

    my $condition = '';
    if ( $department_id && ( $department_id !~ /all/i ) ) { $condition = "WHERE FK_Department__ID in ($department_id)"; }
    @grps = &get_FK_info( $dbc, 'FK_Grp__ID', -condition => "$condition ORDER BY Grp_Name", -list => 1 );

    return \@grps;
}

##################################################
# displays a page to set groups for employees
##################################################
sub display_set_groups {
##################################################
    my $self   = shift;
    my %args   = @_;
    my $emp_id = $args{-emp_id};
    my $dbc    = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    print alDente::Form::start_alDente_form( $dbc, "Group_Setting", $dbc->homelink() );
    print hidden( -name => "Employee_ID", -value => $emp_id );
    my $emp_name = &get_FK_info( -dbc => $dbc, -field => 'FK_Employee__ID', -id => $emp_id );

    # display groups the user is a member of
    my @belongs_to_list = $dbc->Table_find( "GrpEmployee", "FK_Grp__ID", "WHERE FK_Employee__ID=$emp_id" );

    # convert to names
    print "User $emp_name belongs to:<BR><ul>";
    foreach (@belongs_to_list) {
        $_ = &get_FK_info( -dbc => $dbc, -field => 'FK_Grp__ID', -id => $_ );
        print "<li>$_</li>";
    }
    print "</ul>";

    print Views::sub_Heading( "Select Departments", -1 );

    # display all groups, with the groups the user belongs to selected
    my @group_list = &get_FK_info( -dbc => $dbc, -field => "FK_Grp__ID", -list => 1 );
    print scrolling_list( -name => 'Add_Group_List', -multiple => 'true', -values => \@group_list, -default => \@belongs_to_list, -force => 1 );
    print "<BR>" . submit( -name => 'Set Employee Groups', -class => "Action" );
    print br() . reset( -class => "Search" );
    print end_form();
}

##################################################
# sets groups for employees
##################################################
sub set_groups {
##################################################
    my $self    = shift;
    my %args    = @_;
    my $emp_id  = $args{-emp_id};
    my $grp_ids = $args{-group_ids};

    # remove all previous settings
    $self->{dbc}->delete_records( -table => "GrpEmployee", -dfield => 'FK_Employee__ID', -id_list => $emp_id );

    # add new settings
    foreach my $grp_id ( @{$grp_ids} ) {
        $self->{dbc}->Table_append_array( "GrpEmployee", [ 'FK_Grp__ID', 'FK_Employee__ID' ], [ $grp_id, $emp_id ] );
    }
}

##################################################
# Get permissions on a particular table
##################################################
sub get_table_permissions {
    my $self  = shift;
    my %args  = @_;
    my $dbc   = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = $args{-table};

    my $groups_list = $dbc->get_local('group_list');    ## $self->login_info()->{groups_list};

    my @permissions;

    if ( $self->LIMS_admin() ) {                        # Give everything to LIMS admin
        @permissions = ( 'R', 'W', 'U', 'D', 'O' );
    }
    else {
        my @group_perms = $dbc->Table_find_array( 'GrpDBTable,DBTable', ['Permissions'], "WHERE DBTable_ID=FK_DBTable__ID AND FK_Grp__ID in ($groups_list) AND DBTable_Name = '$table'" );
        foreach my $group_perm (@group_perms) {
            foreach my $p ( split /,/, $group_perm ) {
                unless ( grep /^$p$/, @permissions ) { push( @permissions, $p ) }
            }
        }
    }

    return \@permissions;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

#####################################
# Initialization
# - Populate the login hash
#####################################
sub _initialize {
#################
    my $self = shift;
    my $dbc = $self->{dbc};

    # If username is not set then find it now.
    unless ( $self->{login}->{user} ) {
        $self->{login}->{user} = $dbc->get_local('user_name');
    }

    $self->{login}{host} ||= $dbc->{host};                        # Database host
    $self->{login}{dbase} || $dbc->{dbase};                         # Keep track of the database the user logged in to

    # Get all the groups the user belongs to.
    my $groups_list = $dbc->get_local('group_list');    ## $self->_get_user_groups();

    #    my $groups_list = join ",", @{$groups};

    # Get department and access info from the groups
    ## <CONSTRUCTION> - should not need default - or set up $Defaults{DEFAULT_GROUP}..

    # If not belong to any group then default to Public
    unless ($groups_list) {
        my ($public_grp_id) = $dbc->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = 'Public'" );
        $groups_list = $public_grp_id;
    }

    my $info = $dbc->hash( 'Grp,Department', [ 'Grp_ID', 'Grp_Name', 'Access', 'Department_ID', 'Department_Name' ], "where Department_ID=FK_Department__ID and Grp_ID in ($groups_list) ORDER BY Department_Name") if $groups_list;

    my $i = 0;
    while ( defined $info->{Grp_ID}[$i] ) {
        my $grp_id    = $info->{Grp_ID}[$i];
        my $grp_name  = $info->{Grp_Name}[$i];
        my $access    = $info->{Access}[$i];
        my $dept_id   = $info->{Department_ID}[$i];
        my $dept_name = $info->{Department_Name}[$i];

        $self->{login}->{groups}->{$grp_id}->{name}       = $grp_name;
        $self->{login}->{departments}->{$dept_id}->{name} = $dept_name;

        if ( $grp_name =~ /LIMS Admin/ ) { $self->{login}->{LIMS_admin} = 1 }

        # See if we are adding additional access
        if ( defined $self->{login}->{departments}->{$dept_id}->{access} ) {
            if ( $self->{login}->{departments}->{$dept_id}->{access} !~ /$access/ ) {
                $self->{login}->{departments}->{$dept_id}->{access} .= ",$access";
            }
        }
        else {
            $self->{login}->{departments}->{$dept_id}->{access} = $access;
        }

        $i++;
    }

    #    print HTML_Dump($self);
    $self->{login}->{groups_list} = $dbc->get_local('group_list');

    $self->{login}->{departments_list} = join ",", keys %{ $self->{login}->{departments} };
    $self->{login}->{initialized} = 1;
    
    $dbc->config('Security', $self->{login});
    
    return $self->{login};
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

$Id: Security.pm,v 1.41 2004/11/30 23:15:18 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
