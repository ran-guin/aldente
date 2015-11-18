###########
# User.pm #
###########
#
# This module is used to handle 'User' objects
#
package SDB::User;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

User.pm - This module is used to handle 'User' objects

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle 'User' objects<BR>

=cut
##############################
# superclasses               #
##############################

use base LampLite::User;

push @ISA, 'SDB::DB_Object';
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::Views;

use LampLite::Grp;

##############################
# global_vars                #
##############################

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

##############################
# constructor                #
##############################


#
# Wrapper to set and/or retrieve id
#
#
##########
sub reset {
##########
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $user_id = $args{-id} || $args{-user_id} || $self->{id};

    if ($dbc) { $self->{dbc} = $dbc }

    if ($user_id) {
        $self->{id} = $user_id;
        $self->primary_value( -table => $self->{DB_table}, -value => $user_id );
        $self->load_Object();
        $self->define_User();
    }

    return $user_id;
}

###########################
sub new_User_trigger {
###########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $ok   = 1;

    my ($id) = $dbc->Table_find( $self->{DB_table}, 'Max(' . $self->{DB_table} . '_ID)' );
    my ($email) = $dbc->Table_find( $self->{DB_table}, $self->{email_field}, "WHERE $self->{DB_table}_ID = $id" );

    my $default_domain = $dbc->config('default_email_domain');
    if ( $email =~ /^(.+)\@$default_domain/ ) {
        my $new_email = $1;
        $ok = $dbc->Table_update_array( $self->{DB_table}, [$self->{email_field}], [$new_email], "WHERE $self->{DB_table}_ID = $id ", -autoquote => 1 );
    }

    return $ok;
}

############################
sub new_GrpUser_trigger {
############################
    my $dbc            = shift;
    my $grpUser_id = shift;

    # Note: The following code segment is commented out until further investigation has been completed.
    # It has caused problem for new User account.

=begin
    my ($id) = $dbc->Table_find( 'GrpUser', 'FK_User__ID', "WHERE GrpUser_ID = $grpUser_id" );

    my $self = SDB::User->new( -dbc => $dbc, -id => $id );

    if ( !$id || !$self || !$self->{id} ) { return 0 }

    my @shared_grps = $self->groups("Grp_Type like 'Shared'");
    

    ## Note: To be more robust, we should adjust this to work recursively until no membership in shared groups remains ##
    foreach my $grp (@shared_grps) {
        my @grps = $dbc->Table_find( 'Grp_Relationship', 'FKDerived_Grp__ID', "WHERE FKBase_Grp__ID = $grp" );
        $self->leave_Grp($grp);
        $self->join_Grp( \@grps );
    }
=cut

    return 1;
}

################
sub leave_Grp {
################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'grp,dbc,User' );
    my $grp      = $args{-grp};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $User = $args{-User} || $self->{id};

    my $grps = Cast_List( -list => $grp, -to => 'string' );
    $dbc->delete_record( 'GrpUser', 'FK_User__ID', $User, -condition => "FK_Grp__ID IN ($grps)", -quiet => 1 );

    return 1;
}

##############
sub join_Grp {
##############
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'grp,dbc,User' );
    my $grp         = $args{-grp};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $User    = $args{-User} || $self->{id};
    my $no_triggers = $args{-no_triggers};                                 # suppress triggers

    my @grps_list = Cast_List( -list => $grp, -to => 'array' );

    foreach my $join_grp (@grps_list) {
        my ($count) = $dbc->Table_find( 'GrpUser', "GrpUser_ID", "WHERE FK_User__ID=$User AND FK_Grp__ID=$join_grp" );    ## check if already a member
        if ($count) { Message("Already in $join_grp...($count)"); next; }
        $dbc->Table_append_array( 'GrpUser', [ 'FK_User__ID', 'FK_Grp__ID' ], [ $User, $join_grp ], -no_triggers => $no_triggers );
    }

    return 1;
}

#
# Retrieve Groups to which User is a member
#
#
#############
sub groups {
##############
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'conditon' );
    my $condition = $args{-condition};
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $User  = $args{-User} || $self->{id};
    if ($condition) { $condition = " AND $condition" }

    my @groups = $dbc->Table_find( "Grp$self->{DB_table},$self->{DB_table},Grp", 'FK_Grp__ID', "WHERE FK_Grp__ID=Grp_ID AND FK_$self->{DB_table}__ID=$self->{id_field} AND FK_$self->{DB_table}__ID =$User  $condition" );

    return @groups;
}

###################
sub define_User {
###################
    my $self = shift;
    my %args      = &filter_input( \@_);

    $self->SUPER::define_User();    

    my $id  = $self->{id};
    my $dbc = $self->dbc();

    # SPECIAL RULE: if user is a member of Site Admin, grant access as if user is Admin
    my $table = $self->{DB_table};
    my $id_field = $self->{id_field};
    my ($grp_jt, $ref) = $self->group_join_table();
    
    my @base_depts = $dbc->get_db_array(-table=>"Grp,$grp_jt,Department",-field=>"Department_Name", -condition=>"FK_Department__ID=Department_ID AND FK_Grp__ID=Grp_ID AND $ref=$id", -distinct => 1 );
     
    my $name = $self->Object_data($self->{name_field});
    
    my $superuser = 0;
    if ( ( $name eq 'Admin' ) || ( grep /Site Admin/, @base_depts ) ) {
        $superuser = 1;
        @base_depts = $dbc->get_db_array(-table=>"Grp,Department", -field=>"Department_Name", -condition=>"FK_Department__ID=Department_ID ORDER BY Department_Name", -distinct => 1 );
    }

    ## get list of groups ##

    my $group_list = join ',', LampLite::Grp::get_groups( $self->{DB_table}, $id, -superuser => $superuser, -dbc => $dbc );
    $group_list ||= 0;

    my @groups = $dbc->get_db_array(-sql=>"SELECT DISTINCT Grp_Name FROM Grp WHERE Grp_ID IN ($group_list)", -order => 'Grp_Name');
  
    my $home_dept = $dbc->get_db_value( -sql=> "SELECT Department_Name FROM $table,Department WHERE FK_Department__ID=Department_ID AND $id_field = $id");

    ## Establish connection attributes for user ##
    $dbc->set_local( 'user_id',       $id );
    $dbc->set_local( 'user_name',     $self->Object_data($self->{name_field}) );
    $dbc->set_local( 'user_initials', $self->Object_data('Initials') );
    $dbc->set_local( 'user_email',    $self->Object_data($self->{email_field}) );
    $dbc->set_local( 'group_list',    $group_list );
    $dbc->set_local( 'groups',        \@groups );
    $dbc->set_local( 'home_dept',     $home_dept );
    $dbc->set_local( 'base_departments',   \@base_depts );
    my $session_dept;

    if ( $dbc->session() ) {
        $session_dept = $dbc->session->param('Target_Department');
    }

    my $chosen_dept = $dbc->config('Target_Department') || $session_dept || $home_dept;
    $dbc->config( 'Target_Department', $chosen_dept );

    my $hash = $dbc->hash(
        -table=>'Grp,Department', 
        -fields=>'Department_Name,Access,Grp_Type', 
        -condition=>"Department.Department_ID=Grp.FK_Department__ID AND Grp_ID IN ($group_list) and Department_Status = 'Active'", 
        -distinct => 1
    );
    
    my %access;
    my %group_type;
    my @tabs;    
    my @departments;
    my $i = 0;
    while ( defined $hash->{Department_Name}[$i] ) {
        my $dept = $hash->{Department_Name}[$i];
        
        push @departments, $dept unless grep /^$dept$/, @departments;
        
        push( @{ $access{$dept} },     $hash->{Access}[$i] );
        push( @{ $group_type{$dept} }, $hash->{Grp_Type}[$i] );

        my $dir = $dept;
        $dir =~ s/ /\_/g;
        if ( -e "$dbc->config('perl_dir')/Departments/$dir/" ) {
            if ( !grep /^$dept$/, @tabs ) { push @tabs, $dept; }    ## replace spaces with underscores for tab names
        }
        $i++;
    }
    $dbc->set_local( 'departments', \@departments );
    $dbc->set_local( 'tabs',        \@tabs );
    $dbc->set_local( 'Access',      \%access );
    $self->{access} = \%access;
    $dbc->set_local( 'group_type', \%group_type );

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
    my $dbc = $self->dbc();
    my $user_id = $self->{id};

    $self->SUPER::load_User_Settings(%args);
}

################
sub User_home {
################
    my $self = shift;
    my %args = @_;

    my $user_id = $args{-user_id} || $self->{user_id};

    if ($user_id) {
        $self->home_info($user_id);
    }
    else {
        print "GENERAL User Page..";
    }

    return;
}

##################
sub home_page {
##################
    my $self = shift;
    my %args = @_;
    return $self->home_info(%args);
}

####################
sub home_info {
####################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $user_id;
    if ( $_[0] =~ /^-/ ) {
        my %args = @_;
        $user_id = $args{-user_id};
    }
    else {
        $user_id = shift;
    }

    $user_id ||= $self->{user_id} || 0;

    my ($grp_jt, $ref) = $self->group_join_table();

    my $timestamp = timestamp();

    $self->primary_value( -table => $self->{DB_table}, -value => $user_id );
    my $details = $self->load_Object();

    my $info = "<h1>" . $self->value($self->{name_field}) . ")</h1>";

    $info .= "<h2>Position: " . $self->value('$self->{DB_table}.Position');
    if ( $self->value('$self->{DB_table}.FK_Department__ID') ) {
        my $department_name = get_FK_info( $dbc, 'FK_Department__ID', $self->value('$self->{DB_table}.FK_Department__ID') );
        $info .= " ($department_name)";
    }
    $info .= "</h2>\n";

    ### Groups info ###
    my @groups = $dbc->Table_find( "$grp_jt,Grp", 'Grp_Name', "WHERE Grp_ID=FK_Grp__ID AND $ref=$user_id" );

    $info .= create_tree(
        -tree => { 'Groups' => $self->View->join_records( -dbc => $dbc, -defined => $ref, -id => $user_id, -join => 'FK_Grp__ID', -join_table => $grp_jt, -filter => "Grp_Status = 'Active'", -title => 'Group Membership' ) } );

    ### Print Run Requests..
    my %Requests = &Table_retrieve( $dbc, 'Run,RunBatch', [ 'count(*) as Count', 'Left(Run_DateTime,4) as inYear' ], "WHERE FK_RunBatch__ID=RunBatch_ID AND $ref=$user_id Group by Left(Run_DateTime,4) Order by Run_DateTime" );

    if ( $Requests{Count}[-1] ) {
        $info .= "<h3>Sequence Run Requests:</h3><UL>\n";
        foreach my $index ( 0 .. $#{ $Requests{Count} } ) {
            my $year  = $Requests{inYear}[$index];
            my $count = $Requests{Count}[$index];
            $info .= "<LI>in $year : $count Runs initiated\n";
        }
        $info .= "</ul>\n";
    }

    #    if ($Sess->user_id() eq $user_id) {
    if ( $dbc->get_local('user_id') eq $user_id ) {
        ### print current settings... ###
        my $Settings = HTML_Table->new( -title => 'Current User Settings' );
        $Settings->Set_Headers( [ 'Setting', 'Value' ] );
        
        my $User_settings = $dbc->session->user_setting();
        foreach my $key ( keys %{$User_settings} ) {
            $Settings->Set_Row( [ $key, $User_settings->{$key} ] );
        }
        $info .= $Settings->Printout(0);
        my $link = &Link_To( $dbc->config('homelink'), 'Edit Settings', "&Edit+Table=$self->{DB_table}Setting&Field=$ref&Like=$user_id" );
        $info .= "<P>$link<BR>(defaults used where setting unspecified)";
    }
    else {
        $info .= "$self->{DB_table}_ID: $user_id";
    }

    return Views::Table_Print( content => [ [ $info, $self->display_Record( -filename => "$dbc->config('URL_temp_dir')/$self->{DB_table}.$timestamp.html" ) ] ], -return_html => 1 );
}

# Return: True if user is an administrator
#############
sub is_admin {
#############
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $emp_id  = $args{-User_id};
    my $dept_id = $args{-dept_id};               ## if specified, check admin privileges for a specific dept (otherwise, return true if admin for any group)
    my $emp     = $args{-User};
    my $dept    = $args{-dept};

    if ( !$emp_id && !$emp ) {
        if   ($self) { $emp_id = $self->{id} }
        else         { $emp_id = $dbc->get_local('user_id') }
    }

    my $admin = 0;

    my $extra_condition;
    if ($dept_id) { $extra_condition .= " AND Department_ID = $dept_id" }
    if ($dept)    { $extra_condition .= " AND Department_Name = '$dept'" }
    if ($emp)     { $extra_condition .= " AND User_Name = '$emp'" }
    if ($emp_id)  { $extra_condition .= " AND User_ID = $emp_id" }

    if ($extra_condition) {
        ($admin) = $dbc->Table_find( 'GrpUser,Grp,User,Department', 'Grp_Name', "WHERE User_ID=FK_User__ID AND Grp.FK_Department__ID=Department_ID AND FK_Grp__ID=Grp_ID AND Grp_Name like '%Admin' $extra_condition" );
    }

    return $admin;
}

#######################################################################
# Generate list of email addresses based upon standard lists.
#  (generated from Grp, GrpUser tables in the database based upon Access privileges)
#
# -list => <list>
#    options:
#     lab admin : administrators who have 'Lab' access privileges (for at least one group)
#     admin : anyone who has 'Admin' access to at least one group
#     LIMS  : anyone who is a member of the LIMS group.
#
# -domain => <domain>   ## this adds a default domain to any email addresses that do not contain the '@' character.
#
# <snip>
#  Eg.
#
# my $target_list = join '; ', get_email_list($dbc,'lab admin');
#
# </snip>
#
# Return : reference to string of email addresses.
########################
sub get_email_list {
########################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,list',
        -mandatory => 'dbc|self',
        -self      => 'User'
    );
    my $self = $args{-self};                                                                   ## if used as method...
    my $dbc = $args{-dbc};

    my $list   = $args{-list};                                                                 ## list to extract ('admin', 'report' or 'LIMS')
    my $domain = $args{-domain} || 'bcgsc.ca';
    my $debug  = $args{-debug};

    my $group      = $args{ -groups } || $args{-group};                                        ## optional group_id for filtering
    my $department = $args{-department};                                                       ## optional department for filtering
    my $project    = $args{-project};                                                          ## optional project for filtering
    my $library    = $args{-library};                                                          ## optional project for filtering

    my $group_condition = " AND $self->{DB_table}_Status='Active'";

    my $tables         = "$self->{DB_table},Grp,Grp$self->{DB_table}";
    my $join_condition = "Grp$self->{DB_table}.FK_Grp__ID = Grp.Grp_ID AND Grp$self->{DB_table}.FK_$self->{DB_table}__ID=$self->{id_field}";
    if ($department) {
        $tables          .= ",Department";
        $join_condition  .= " AND Grp.FK_Department__ID=Department_ID";
        $group_condition .= " AND Department_Name LIKE '$department'";
    }

    ## if this applies to a specific project... ##
    my $extended_group_list;
    if ($library) {
        $extended_group_list = join ',', $dbc->Table_find( 'Library', 'FK_Grp__ID', "WHERE Library_Name = '$library'", -distinct => 1 );
    }
    elsif ($project) {
        ## first get a full list of all groups associated with all libraries under the same project(s) ##
        $extended_group_list = join ',', $dbc->Table_find( 'Library,Project', 'FK_Grp__ID', "WHERE FK_Project__ID=Project_ID AND (Project_Name like '$project' OR Project_ID IN ('$project'))", -distinct => 1 );
    }
    elsif ($group) {
        $extended_group_list = LampLite::Grp::get_parent_groups( -dbc => $dbc, -group_id => $group );    ## include parent groups

        # add the group/s that was originally given
        my @grp_list = split ',', $extended_group_list;
        push( @grp_list, split( ',', $group ) );
        $extended_group_list = join( ',', @grp_list );

        Message("Group derived from $group -> $extended_group_list") if ($debug);
    }

    if ($extended_group_list) {
        ## add the applicable groups to the group_list ##
        $group_condition .= " AND Grp.Grp_ID IN ($extended_group_list)";
    }
    my @target_list = ();
    if ( $list =~ /admin/i && $list =~ /report/ ) {
        $group_condition .= " AND Grp.Access in ('Report','Admin') ";
    }
    elsif ( $list =~ /admin/i ) {
        ## Get Users who have BOTH 'Admin' Access and 'Lab' Access (in Grp table) to at least one group.
        $group_condition .= " AND Grp.Access in ('Admin') ";
    }
    elsif ( $list =~ /report/i ) {
        $group_condition .= " AND Grp.Access in ('Report') ";
        ## Get Users who have 'Admin' Access (in Grp Table) to at least one group ##
    }
    elsif ( $list =~ /LIMS/i ) {
        $group_condition .= " AND Grp.Grp_Name like 'LIMS%' ";
        ## Get Users who have 'LIMS' Access (in Grp Table) to at least one group ##
    }
    else {

        #Message("No members found for list: $list");
    }

    @target_list = $dbc->Table_find( $tables, 'Email_Address', "WHERE $join_condition AND Grp$self->{DB_table}.FK_Grp__ID = Grp.Grp_ID AND Grp$self->{DB_table}.FK_$self->{DB_table}__ID=$self->{id_field} $group_condition", -distinct => 1 );

    map {
        unless (/\@/) { $_ = $_ . '@' . $domain }
    } @target_list;
    return \@target_list;
}

########################
sub get_User_Groups {
########################
    my $self   = shift;                           ## if used as method...
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $public = $args{-public};
    my $admin  = $args{-admin};
    my $groups = $dbc->get_local('group_list');

    ## Remove Public group
    my ($public_grp) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Public'" );
    my ($lims_grp)   = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Site Admin'" );
    $groups =~ s/\b$public_grp,//g;
    $groups =~ s/,$public_grp\b//g;

    if ($admin) {
        my @admin;
        if ( $groups =~ /\b$lims_grp\b/ ) {
            ## GOTTA MAKE SURE LIMS ADMIN HAS ACCESS TO ALL
        }
        else {
            my @group_names = $dbc->Table_find( 'Grp', 'Grp_Name', "WHERE Grp_ID IN ($groups)" );
            for my $name (@group_names) {
                if ( $name =~ /(.+) Admin$/ ) {
                    my @groups = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name LIKE '$1%'" );
                    push @admin, @groups;
                }
            }
            $groups = join ',', @admin;
        }
    }

    if ($public) {
        $groups .= ",$public_grp";
    }

    return $groups;
}

###################
sub save_Setting {
###################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'setting,scope' );
    my $dbc     = $self->{dbc};
    my $setting = $args{-setting};
    my $value   = $args{-value};
    my $scope   = $args{-scope};

    my $emp_id = $self->{id};

    my ($setting_id) = $dbc->Table_find( 'Setting', 'Setting_ID', "WHERE Setting_Name = '$setting'" );

    my $ref_id;
    if ( $scope =~ /^Dep/i ) {
        ($ref_id) = $dbc->Table_find( $self->{DB_table}, 'FK_Department__ID', "WHERE $self->{id_field} = $emp_id" );
        $scope = 'Department';
    }
    elsif ( $scope =~ /^Emp/i ) {
        $ref_id = $emp_id;
        $scope  = $self->{DB_table};
    }
    else {return}

    my $ok = 0;

    my $current = $self->get_Settings( -setting => $setting, -scope => $scope );
    if ( $current eq $value ) {
        ## already set ##
        $ok = 1;
    }
    elsif ($current) {
        if ($value) {
            ## Set value if it is defined and is not empty ##
            $ok = $dbc->Table_update_array( "${scope}Setting", ['Setting_Value'], [$value], "WHERE FK_${scope}__ID=$ref_id AND FK_Setting__ID = $setting_id", -autoquote => 1 );
            $dbc->message("CHANGING $setting for $scope $ref_id: $current -> $value");
        }
        else {
            ## otherwise, clear value
            $ok = $dbc->delete_record( "${scope}Setting", "FK_${scope}__ID", $ref_id, -condition => "FK_Setting__ID=$setting_id" );
            $dbc->message("CLEARING $setting for $scope $ref_id");
        }
    }
    else {
        $ok = $dbc->Table_append_array( "${scope}Setting", [ 'Setting_Value', 'FK_Setting__ID', "FK_${scope}__ID" ], [ $value, $setting_id, $ref_id ], -autoquote => 1 );
        $dbc->message("SETTING $setting for $scope $ref_id: -> $value");
    }

    return $ok;
}

###################
sub clear_Setting {
    ###################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'setting,scope' );
    my $setting = $args{-setting};
    my $scope   = $args{-scope};

    return $self->save_Setting( -setting => $setting, -scope => $scope );
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

2003-11-27

=head1 REVISION <UPLINK>

$Id: User.pm,v 1.23 2004/11/30 23:15:02 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
