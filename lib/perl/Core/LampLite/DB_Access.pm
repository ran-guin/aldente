################################################################################
#
# DB_Access.pm
#
# This module handles DB_Access,
# and provides safer/quicker versiions of standard calls (eg. safe_glob)
#
################################################################################
################################################################################
# $Id: DB_Access.pm,v 1.2 2003/11/27 19:42:52 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2003/11/27 19:42:52 $
################################################################################
# Ran Guin (2001) - rguin@bcgsc.bc.ca
#
package LampLite::DB_Access;

use base LampLite::DB_Object;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Access.pm - This module handles DB_Access, 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles DB_Access, <BR>and provides safer/quicker versiions of standard calls (eg. safe_glob) <BR>Ran Guin (2001) - rguin@bcgsc.bc.ca<BR>

=cut

##############################
# superclasses               #
##############################

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################


#
# Quick accessor to database record access 
# (Based on current user and potential record ownership)
#
# Access action types:  Read Update Insert Delete
#
# Access provided if all of the above are met:
# * db_user has general hard access to perform action (mySQL based permission based upon current db_user (not tied to specific users))
# * user has soft access to table in question (code based permissions based on current user group - tied to specific users)
# ** for owner accessible tables, user should be referenced in the record itself (eg FK_Employee__ID points to current user)
# 
# If field is supplied, field permission should also be checked for mySQL or code based field restrictions
#
#############
sub access {
#############
     my %args = filter_input( \@_, -args => 'dbc,action' );
     my $dbc = $args{-dbc};
     my $action = $args{-action};
     my $table = $args{-table};
     my $field = $args{-field};      ## optional
     
     return 1;   
}

#################
sub db_privileges {
#################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,action' );
 
    return qw(Select Insert Update Delete);
}

#######################
sub db_access_users {
#######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,action' );
    
    my $scope = $args{-scope};
    my $condition = $args{-condition} || 1;
    my $type  = $args{-type} || 'DB_User';   ## DB_User or DB_Access_Title ##
    my $debug = $args{-debug};
    my $dbc = $self->dbc();
    
    if (!$scope) { $dbc->warning("Scope not provided - using nonProduction"); $scope = 'nonProduction'; }
        
    my @users = $dbc->get_db_array(-sql=>"SELECT DISTINCT $type FROM DB_Access LEFT JOIN DB_Login ON FK${scope}_DB_Access__ID=DB_Access_ID WHERE $condition ORDER BY DB_Access_ID", -debug=>$debug);
    
    return @users;
}

#######################
sub db_access {
#######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,action' );
    
    my $access_title = $args{-access_title};
    my $scope = $args{-scope};
    my $key  = $args{-key} || 'DB_User';   ## DB_User or DB_Access_Title ##
    my $condition = $args{-condition} || 1;
    my $debug = $args{-debug};
    my $dbc = $self->dbc();
    
    if (!$scope) { $dbc->warning("Scope not provided - using nonProduction"); $scope = 'nonProduction'; }
        
    if ($access_title) { $condition .= " AND DB_Access_Title = '$access_title'" }
    
    my $fields = join ',', map { $_ . '_priv' } $self->db_privileges();
    my $access = $dbc->hash(-sql=>"SELECT DISTINCT $key, $fields FROM DB_Access LEFT JOIN DB_Login ON FK${scope}_DB_Access__ID=DB_Access_ID WHERE $condition ORDER BY DB_Access_ID", -debug=>$debug);
    
    my $Access;
    my $i = 0;
    while ( defined $access->{"Select_priv"}[$i] ) {
        my $user = $access->{$key}[$i];
        my @fields = keys %{$access};
        my $user_access = {};
        foreach my $field (@fields) {
            if ($field eq $key) { next }
            $user_access->{$field} = $access->{$field}[$i];
        }
        push @{$Access}, {$user => $user_access};
        $i++;
    }
    
    return $Access;
}

#
# Accessor to retrieve standard database login username (given LIMS login username)
#
# Return: Database User
###################
sub get_DB_user {
###################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $user_id = $args{-user_id};       ## LIMS user id
    my $user    = $args{-user};          ## LIMS login username
    my $default = $args{-default} || 'guest_user';       ## default db_user
    my $debug  = $args{-debug};

    my $login_table = $dbc->{login_table} || $dbc->config('login_type');
    my $user_group = 'GrpEmployee';
    if ($login_table eq 'User') { $user_group = 'User_Grp' }
    
    my $access_reference = 'FKProduction_DB_Access__ID';
    if ( $dbc->{host} && $dbc->config('PRODUCTION_HOST') && $dbc->config('PRODUCTION_HOST') ne $dbc->{host}) { $access_reference = 'FKnonProduction_DB_Access__ID' }
    if ( $dbc->{dbase} && $dbc->config('PRODUCTION_DATABASE') && $dbc->config('PRODUCTION_DATABASE') ne $dbc->{dbase}) { $access_reference = 'FKnonProduction_DB_Access__ID' }

    my $user_condition;
    if ($user) {
        $user_condition = "${login_table}_Name = '$user' OR Email_Address = '$user'";
#        if ( my $domain = $dbc->config('default_email_domain') ) { $user_condition .= " OR Concat(Email_Address,'\@$domain') = '$user'" }
    }
    elsif ($user_id) { $user_condition = "${login_table}_ID = '$user_id'" }
    else             { return ($default) }

    $user_condition = "($user_condition) AND ${login_table}_Status = 'Active' ORDER BY DB_Access_ID DESC";    ## only retrieve active users... pull out highest access level first

    my $access_host = 'FKProduction_DB_Access__ID';
    
    if (! $dbc->table_loaded('DB_Access') ) { print $dbc->warning("A more secure Login Process has been implemented that is not supported in the current database"); return '' }

    my $user_info = $dbc->hash(
        -tables=>"DB_Login,Grp,$user_group,${login_table},DB_Access", 
        -fields=>"DB_User, ${login_table}_ID, ${login_table}_Name, DB_Access_Title", 
        -condition => "WHERE FK_DB_Login__ID=DB_Login_ID AND $access_reference = DB_Access_ID AND $user_group.FK_Grp__ID=Grp_ID AND $user_group.FK_${login_table}__ID = ${login_table}_ID AND $user_condition", 
        -debug=>$debug);
       
    my ($db_user, $db_access);
    if   ( !$user_info ) {  print $dbc->warning("Could not find '$user' in " . $dbc->{host}  . ':' . $dbc->{dbase} )  }
    else                 { 
       $db_user = $user_info->{DB_User}[0];
       $user_id = $user_info->{"${login_table}_ID"}[0];
       $user = $user_info->{"${login_table}_Name"}[0];
       $db_access = $user_info->{DB_Access_Title}[0];
    }
    if ($user eq 'Guest') { $db_user ||= $default }
    
    return ( $db_user, $user_id, $user, $db_access);
}

#
# Wrapper to add DB User
#
# * Adds user to mysql.user if not already applied
# * Adds user to  mysql.db if not already applied
# * Optionally addes host:user:password to mysql.login file
#
##################
sub add_DB_user {
##################
    my %args              = filter_input( \@_, -self=>'LampLite::DB_Access');
    my $self = $args{-self};
    my $dbc               = $args{-dbc} || $self->{dbc}; 
    my $user              = $args{-db_user}  || $self->{db_user};       ## name of db_user to add
    my $host              = $args{-host} || $dbc->{host};      ## host server to add db_user to
    my $dbase             = $args{-dbase} || $dbc->{dbase};    ## database to provide access to
    my $pass              = $args{-password};
    my $append_login_file = $args{-append_login_file};         ## login file (should have restricted read access )
    my $privileges        = $args{-privileges} || [];          ## temporarily ... array of privileges: (select, insert, update, delete..);
    my $grant             = $args{-grant};
    my $rebuild              = $args{-rebuild};
    my $reset                = $args{-reset};                  ## leaves existing user record, but rebuilds db, table_priv, column_priv records as required
    my $debug             = $args{-debug};
   
    my $user_exists = $dbc->get_db_value(-sql=>"SELECT count(*) FROM mysql.user WHERE User = '$user'" );
    my $added;

    if ($rebuild) {
        ## Allow option to rebuild from scratch ##
            $dbc->execute_command(-sql=>"DELETE FROM mysql.user where User = '$user'");
#            $dbc->execute_command(-sql=>"DELETE FROM mysql.db where User = '$user'");
    }
    
    $user_exists = $dbc->get_db_value(-sql=>"SELECT count(*) FROM mysql.user WHERE User = '$user'" );

    if ( !$user_exists ) {
        if ($append_login_file) {
            my ($included) = split "\n", try_system_command("grep '$host:$user:' $append_login_file");

            if ( $included =~ /^$host:$user:(\S+)/ ) {
                $pass = $1;
                if ($debug) { print "Using existing password\n"; }
            }
            else {
                try_system_command("echo '$host:$user:$pass' >> $append_login_file");
                if ($debug) { print "appended $host:$user:$pass to login file\n" }
            }
        }

        $added = $dbc->execute_command("INSERT INTO mysql.user (Host, User, Password) values ('%', '$user', Password('$pass'))");

        if ($grant) { 
            my $db = $dbase;
            if ($dbase eq '%') { $db = '*' }
            print $dbc->message("GRANT $grant ON $db.* TO '$user'");
            
            $dbc->execute_command("GRANT $grant ON $db.* TO '$user';");
            $dbc->execute_command("FLUSH privileges;");
            
        }       
        if ($debug) { print "INSERT INTO mysql.user ... %, $user, $pass [$added]\n" }
    }
    
    if ($dbase =~/[a-zA-Z]/) {
#        $self->reset_access_privilege(%args);
    }
    else {
        $dbc->message("No dbase specified - not adding mysql.db entries");
    }

    $dbc->execute_command("FLUSH privileges");
    
    return $added;
}

#
# Reset access privileges based upon Database management records (DB_Login, DB_Access, Access_Inclusion, Access_Exclusion)
#
# Return:  (changes mysql.Db as required ) - calls set_privileges to update table & column level privileges 
#############################
sub reset_access_privilege {
#############################
    my $self = shift;
    my %args              = filter_input( \@_, -mandatory=>'db_user,dbase');
    my $dbc               = $args{-dbc} || $self->dbc();  
    my $access_user       = $args{-db_user};                   ## name of db_user to add
    my $access_title      = $args{-access_title};
    my $host              = $args{-host} || '%';      ## host server to add db_user to
    my $dbase             = $args{-dbase};    ## database to provide access to
    my $privileges        = $args{-privileges} || {};          ## temporarily ... array of privileges: (select, insert, update, delete..);
    my $inherit  = $args{-inherit} || $privileges;
    my $reset                = $args{-reset};                  ## leaves existing user record, but rebuilds db, table_priv, column_priv records as required
    my $scope = $args{-scope};
    my $debug             = $args{-debug};

    my $exists;
    my $db_added;

    if ($access_user && !$access_title) {
        $access_title = $dbc->get_db_value(-sql=>"Select DB_Access_Title FROM DB_Login, DB_Access where DB_User = '$access_user' and FK${scope}_DB_Access__ID=DB_Access_ID");
    }

     if ($reset) {
         foreach my $tab ('db', 'column_priv', 'table_priv') { $dbc->execute_command(-sql=>"DELETE FROM mysql.$tab where User = '$access_user' AND Db LIKE '$dbase'") }
     }
     else {
         $exists = $dbc->get_db_value(-sql=>"SELECT count(*) FROM mysql.db WHERE Db LIKE '$dbase' AND User = '$access_user'" );
     }

     my @set_privileges = ('Select', 'Insert', 'Update', 'Delete', 'Create', 'Drop', 'Alter');
     if (ref $privileges eq 'ARRAY') {
         ## reset old default privileges to explicit hash ##
         my $i = 0;
         my $hash = {};
         foreach my $priv (@set_privileges) {
             $hash->{$access_title}{$priv . "_priv"} = $privileges->[$i++] || 'N';
         }
         $privileges = $hash;
     }
     
    my @keys = keys %{$privileges->{$access_title}};

    my @fields = ('Host', 'Db', 'User');
    my @values = ($host, $dbase, $access_user);
    
    if ( my $column_priv = $privileges->{$access_title}{column_priv} ) {
        if (ref $column_priv eq 'HASH') {
            foreach my $col (keys %{$column_priv}) {
                if ($col =~/(.+)\.(.+)/) { 
                    my $table = $1; 
                    $col = $2; 
                    $self->set_privilege(-table=>$table, -column=>$col, -privileges=>$privileges, -host=>$host, -user=>$access_user, -dbase=>$dbase, -scope=>$scope);
                }
            }
        }
        else { $dbc->error("Incorrect column privilege format") }
    }

    if (my $table_priv = $privileges->{$access_title}{table_priv}) {
        if (ref $table_priv eq 'HASH') {
            foreach my $table (keys %{$table_priv}) {
                $self->set_privilege(-table=>$table, -privileges=>$privileges, -host=>$host, -user=>$access_user, -dbase=>$dbase, -scope=>$scope);
            }
        }
        else { $dbc->error("Incorrect table privilege format") }
    }
     
    foreach my $priv (@keys) {        
         if ($priv =~/(table_priv|column_priv)/) { next }   ## already accounted for above ... ##

            
                 my $p = $privileges->{$access_title}{$priv} || 'N';   ## reset in case exclude_privilege 
                                 
                 if ($priv !~/_priv$/) { $priv .= '_priv' }
                 push @fields, $priv;
                 push @values, $p;
     }
     
     $self->rebuild_access(-db_user=>$access_user, -host=>$host, -dbase=>$dbase, -scope=>$scope);

     return;
}

#
# Wrapper to rebuild access privileges based upon the current model settings:
#
# $self->{Privileges}    - has the default settings for Select, Insert, Update, Delete
# $self->{Default}       - has the final privileges for Select, Insert, Update, Delete (accounting for exclusion specifications)
#            (eg if privileges default to 'Y', but there are exclusions defined, then the default must be set to 'N' and all tables explicitly set to 'Y' if not excluded)
# $self->{Exclude}       - specifies tables / columns with explicitly excluded privileges 
# $self->{Include}       - specified tables/columns with explicitly included privileges
#
# Return: privileges updated in mysql.Db, mysql.table_priv, mysql.column_priv for specified user
#####################
sub rebuild_access {
#####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'db_user');
    my $access_user = $args{-db_user};
    my $access_title      = $args{-access_title};
    my $dbase              = $args{-dbase};                   ## name of db_user to add
    my $host              = $args{-host} || '%';      ## host server to add db_user to
    my $scope             = $args{-scope};
    
    my $dbc = $self->dbc();

    if ($access_user && !$access_title) {
        $access_title = $dbc->get_db_value(-sql=>"Select DB_Access_Title FROM DB_Login, DB_Access where DB_User = '$access_user' and FK${scope}_DB_Access__ID=DB_Access_ID");
    }
    
    ## Set standard global privileges ##
    my %Privilege;
    foreach my $priv (keys %{$self->{Privileges}{$access_user}}) {
            ## exclude table & column specifications (accounted for already) ##
            if (defined $self->{Default}{$priv}) {
                $Privilege{"${priv}_priv"} = $self->{Default}{$priv};
            }
            elsif (! ref $self->{Privileges}{$access_user}{$priv}) {
                $Privilege{"${priv}_priv"} = $self->{Privileges}{$access_user}{$priv};
            }
    }

    ## Add Specified Inclusions ##
    my %Table_priv;
    my %Column_priv;
        
    if ($self->{Include}) {
        foreach my $priv (keys %{$self->{Include}}) {
            my (@include_fields, @include_values);
            if ($self->{Default}{$priv} ne 'N' && $self->{Privileges}{$access_user}{$priv} eq 'Y') { next }  ## permission already available ... ##
            my $include = $self->{Include}{$priv};
            foreach my $inclusion (@$include) {
                if ($inclusion =~/(.+)\.(\+)/) {
                    push @{$Column_priv{$1}{$2}{$inclusion}}, $priv;
                }
                else {
                    push @{$Table_priv{$inclusion}}, $priv;
                }
            }
        }
    }

    if ($self->{Exclude}) {
        ## Add Specified Inclusions ##
        my @all_tables = $dbc->tables();

        foreach my $priv (keys %{$self->{Exclude}}) {
            my (@exclude_columns, @exclude_tables);

            if ($self->{Privileges}{$access_user}{$priv} eq 'N') { next }
            elsif ( $self->{Default}{$priv} ne 'N' ) { $dbc->warning("$priv should be defaulted to 'N'"); next }  ## default should be set to N if generated properly... ##
            my @exclude = @{$self->{Exclude}{$priv}};
            foreach my $exclusion (@exclude) {
                if ($exclusion =~/(.+)\.(.+)/) {
                    push @exclude_tables, $1;
                    push @exclude_columns, $exclusion;
                }
                else {
                    push @exclude_tables, $exclusion;
                }
            }
              
            foreach my $table (@all_tables) { 
                if (grep /^$table\./, @exclude_columns) {
                    my $columns = $dbc->fields($table);
                    
                    foreach my $column (@$columns) {
                        if ( grep /^$table\.$column$/, @exclude_columns) {  }
#                       elsif ($Table_priv{$table} && ! (grep /^$priv$/, @{$Table_priv{$table}}) ) { $dbc->warning("Skip exclusion of table $table.$column") }
#                        elsif ($self->{Default}{$priv} eq 'N') {  }
                        elsif ($self->{Privileges}{$access_user}{$priv} eq 'N') {  }
                        else {
                            push @{$Column_priv{$table}{$column}}, $priv unless ( $Column_priv{$table}{$column} && grep /$priv/, @{$Column_priv{$table}{$column}} );
                        }
                    }
                }
                
                if (grep /^$table$/, @exclude_tables) { }
                #                elsif ($self->{Default}{$priv} eq 'N') { $dbc->warning("Skip Default $priv") }
                elsif ($self->{Privileges}{$access_user}{$priv} eq 'N') { $dbc->warning("Skip Priv $priv") }
                else {
                    push @{$Table_priv{$table}}, $priv unless ( $Table_priv{$table} && grep /$priv/, @{$Table_priv{$table}} );
                }

            }
        }
    }
    
    $self->reset_Access(-db_user=>$access_user, -host=>$host, -dbase=>$dbase, -privilege=>\%Privilege, -table_priv=>\%Table_priv, -column_priv=>\%Column_priv);

    return;
}

####################
sub update_Access {
####################
    my $self = shift;
    my %args = filter_input(\@_, -mandatory=>'dbase,access_user|access_title');

    my $access_user = $args{-access_user};
    my $access_title = $args{-access_title};
    my $dbase              = $args{-dbase};                   ## name of db_user to add
    my $table_inclusions = $args{-include_tables} || {};
    my $field_inclusions = $args{-include_fields} || {};
    my $table_exclusions = $args{-exclude_tables} || {};
    my $field_exclusions = $args{-exclude_fields} || {};

    my $dbc = $self->dbc();

    my @fields = qw(FK_DBTable__ID FK_DB_Access__ID Privilege FK_DBField__ID);
    
    my $access_id = $dbc->get_db_value(-table=>'DB_Access', -field=>'DB_Access_ID', -condition=>"DB_Access_Title = '$access_title'");
    
    foreach my $priv (keys %{$table_inclusions}, keys %{$field_inclusions}) {
        my @tables = Cast_List(-list=>$table_inclusions->{$priv}, -to=>'array');
        foreach my $table (@tables) {
            my $field;
            if ($table =~/(.+)\.(.+)/) {
                $table = $1;
                $field = $2;
            }
            my $table_id = $dbc->get_db_value(-table=>'DBTable', -field=>'DBTable_ID', -condition=>"DBTable_Name = '$table'");
            my $field_id = $dbc->get_db_value(-table=>'DBField', -field=>'DBField_ID', -condition=>"Field_Name = '$field' AND Field_Table = '$table'");
            $field_id ||= 'NULL';
            my @values = ($table_id, $access_id, "'$priv'", $field_id);
            
            $dbc->append_DB(-table=>"Access_Inclusion", -fields=>\@fields, -values=>\@values, -autoquote=>0);
        }
    }
    
    foreach my $priv (keys %{$table_exclusions}) {
        my @tables = Cast_List(-list=>$table_exclusions->{$priv}, -to=>'array');
        foreach my $table (@tables) {
            my $table_id = $dbc->get_db_value(-table=>'DBTable', -field=>'DBTable_ID', -condition=>"DBTable_Name = '$table'");
            my @values = ($table_id, $access_id, $priv);
            $dbc->append_DB(-table=>"Access_Exclusion", -fields=>\@fields, -values=>\@values, -autoquote=>1);
        }
    }
      
    return;
}

#################
sub set_Access {
#################
    my $self = shift;
    my %args = filter_input(\@_, -mandatory=>'action,dbase,access_user|access_title');

    my $access_user = $args{-access_user};
    my $access_title = $args{-access_title};
    my $dbase      = $args{-dbase};                   ## name of db_user to add
    my $table = $args{-table};
    my $field = $args{-field};
    my $priv  = $args{-privilege};
    my $action = $args{-action};   ## Include or Exclude

    my $dbc = $self->dbc();
    my $table_id = $dbc->get_db_value(-table=>'DBTable', -field=>'DBTable_ID', -condition=>"DBTable_Name = '$table'");
    my $field_id =  $dbc->get_db_value(-table=>'DBField', -field=>'DBField_ID', -condition=>"DBTable_Name = '$table' AND Field_Name = '$field'") || 'NULL';
    my $access_id = $dbc->get_db_value(-table=>'DB_Access', -field=>'DB_Access_ID', -condition=>"DB_Access_Title = '$access_title'");
    
    my @fields = qw(FK_DBTable__ID FK_DB_Access__ID Privilege FK_DBField__ID);

    my $access_table;
    if ($action =~/^In/) { $access_table = 'Access_Inclusion' }
    elsif ($action =~/^Ex/) { $access_table = 'Access_Exclusion' }
    
    my @values = ($table_id, $access_id, "'$priv'", $field_id);
    
    my $ok = $dbc->append_DB(-table=>$access_table, -fields=>\@fields, -values=>\@values, -autoquote=>0);
    
    return $ok;
    
}

##########################
sub update_Table_Access {
##########################
    my $self = shift;
    my %args = filter_input(\@_, -mandatory=>'dbase,access_user|access_title');

    my $access_user = $args{-access_user};
    my $access_title = $args{-access_title};
    my $dbase              = $args{-dbase}; 
    my $scope = $args{-scope};
    my $table = $args{-table};
                     
    my @accessers = $self->db_access_users(-type=>"DB_Access_Title");
    my @privs     = $self->db_privileges();
    
    foreach my $access_title (@accessers) {
        foreach my $priv (@privs) {
            print "A: $access_title -> $priv<BR>";
        }
    }    
    return 'x';
}

#
# Enables access to specific privilege with exclusions for specific tables / columns
# 
#  (this grants access to all tables / columns EXCEPT those indicated)
# 
# Return: updates mysql records
######################################
sub reset_Access {
######################################
    my $self = shift;
    my %args = filter_input(\@_, -mandatory=>'host,dbase,db_user');
    
    my $db_user = $args{-db_user};
    my $dbase              = $args{-dbase};                   ## name of db_user to add
    my $host              = $args{-host} || '%';      ## host server to add db_user to
    my $privilege         = $args{-privilege};
    
    my $table_priv = $args{-table_priv};
    my $column_priv = $args{-column_priv};
    
    my $dbc = $self->dbc();
 
    $dbc->message("Updating inclusion / exclusion specs....");
    
    ## Ensure host / dbase / user supplied explicitly ##
    if (!$host || !$dbase || !$db_user) { 
        $dbc->error("Must explicitly supply host ('$host'), dbase ('$dbase') & user ('$db_user') to reset access privileges"); 
        return 0; 
    }
     
    ###############################
    ## Clear existing privileges ##
    ###############################
    my $clear1 = $dbc->execute_command("DELETE FROM mysql.db where User = '$db_user' and Db = '$dbase' AND Host = '$host'");
    my $clear2 = $dbc->execute_command("DELETE FROM mysql.tables_priv where User = '$db_user' and Db = '$dbase' AND Host = '$host'");
    my $clear3 = $dbc->execute_command("DELETE FROM mysql.columns_priv where User = '$db_user' and Db = '$dbase' AND Host = '$host'");
    
    if ($clear1 =~/successfully \((\d+) row/ ) { $dbc->message("cleared $1 record from db") }
    else { $dbc->warning($clear1) }

    if ($clear2 =~/successfully \((.*) row/ ) { $dbc->message("cleared $1 record from tables_priv") }
    else { $dbc->warning($clear2) }
    
    if ($clear3 =~/successfully \((.*) row/ ) { $dbc->message("cleared $1 record from columns_priv") }
    else { $dbc->warning($clear3) }
    
    #########################################
    ## Add standard privileges to mysql.Db ##
    #########################################
    my $command = "INSERT INTO mysql.db (";
    my @privs = keys %{$privilege};
        
    my @fields = qw(Host Db User);
    my @values = ("'$host'", "'$dbase'", "'$db_user'");
    foreach my $priv (@privs) {
        push @fields, $priv;
        push @values, "'$privilege->{$priv}'";
    }

    $command .= join ',', @fields;
    $command .= ") values (";
    $command .= join ',', @values;
    $command .= ");";
    
    $dbc->message($command);
    my $ok = $dbc->execute_command($command);
    if ($ok =~/successfully \((.*) row/ ) { $dbc->message("added $1 records to tables_priv") }
    else { $dbc->warning($ok) }
    
    #####################
    ## Add tables_priv ##
    #####################
    if ($table_priv && keys %{$table_priv}) {
        my $T_command = "INSERT INTO mysql.tables_priv (Host, Db, User, Table_name, Table_priv, Column_priv) values ";
        
        my @add_values;
        my @tables_added = keys %{$table_priv};

        foreach my $table (sort @tables_added) {
            my $priv = $table_priv->{$table};
            if ($priv) {
                my $column_priv = join ',', grep /^(Select|Insert|Update|References)$/, @$priv;
                $priv = join ",", @$priv;
                push @add_values, "('$host', '$dbase', '$db_user', '$table', '$priv', '$column_priv')";
            }
        }
        
        if (@add_values) {
            $T_command .= join ", ", @add_values;
            my $ok = $dbc->execute_command($T_command);
            $T_command =~s/\),/\),\<BR\>/g;

            if ($ok =~/successfully \((.*) row/ ) { $dbc->message("added $1 records to tables_priv") }
            else { $dbc->warning($ok) }
            
            if ($@) { $dbc->error($@) }
        }
    }
    ######################
    ## Add columns_priv ##
    ######################
    if ($column_priv && keys %{$column_priv}) {
        my $C_command = "INSERT INTO mysql.columns_priv (Host, Db, User, Table_name, Column_name, Column_priv) values ";
        
        my @add_values;
        my @tables_added = keys %{$column_priv};

        foreach my $table (sort @tables_added) {
            my $priv = $column_priv->{$table};
            my @columns = keys %{$priv};
            foreach my $col (@columns) {
                my $c_priv = $column_priv->{$table}{$col};
                $priv = join ",", @$c_priv;
                push @add_values, "('$host', '$dbase', '$db_user', '$table', '$col', '$priv')";
            }
        }
        
        if (@add_values) {
            $C_command .= join ", ", @add_values;
            my $ok = $dbc->execute_command($C_command);

            if ($ok =~/successfully \((.*) row/ ) { $dbc->message("added $1 records to columns_priv") }
            else { $dbc->warning($ok) }
            
            if ($@) { $dbc->error($@) }
        }
    }    
    return 1;
}

#
# Reset access privileges based upon Database management records (DB_Login, DB_Access, Access_Inclusion, Access_Exclusion)
#
# Return:  (changes table_priv, column_priv settings as required )
#########################
sub set_privilege {
########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'table');
    
    my $table = $args{-table};
    my $column = $args{-column};
    my $privileges = $args{-privileges};
    
    my $access_user              = $args{-user};                   ## name of db_user to add
    my $access_title      = $args{-access_title};
    my $host              = $args{-host} || '%';      ## host server to add db_user to
    my $dbase             = $args{-dbase};    ## database to provide access to
    my $scope = $args{-scope};
    
    my $dbc = $self->dbc();

    if ($access_user && !$access_title) {
        $access_title = $dbc->get_db_value(-sql=>"Select DB_Access_Title FROM DB_Login, DB_Access where DB_User = '$access_user' and FK${scope}_DB_Access__ID=DB_Access_ID");
    }

    my $table_priv;
    my $column_priv;
    
    my @TP_fields = qw(Db Host User);
    my @TP_values = ($dbase, $host, $user);
    my @CP_fields = @TP_fields;
    my @CP_values = @TP_values;
    
    unless ($host && $dbase && $user) { $dbc->error("Must specify Host, Dbase & User ($host, $dbase, $user)"); return }
 
    if ($column) {
        my $col = $column;
        if ($column =~/(.*)\.(.+)/) { $table ||= 1; $col = $2; }
        
        if ($privileges->{$access_title}{'column_priv'} && $privileges->{$access_title}{'column_priv'}{"$table.$column"}) {
            my @enable_access;
            foreach my $key (keys %{$privileges->{$access_title}{'column_priv'}{"$table.$column"}}) {
                 my $priv =  $privileges->{$access_title}{'column_priv'}{"$table.$column"}{$key};
                 if (! ref $priv && $priv eq 'Y') { 
                     push @enable_access, $key;
                    push @{$self->{Include}->{$key}}, "$table.$column";
                }
                elsif (! ref $priv && $priv eq 'N') { 
                     push @{$self->{'Exclude'}->{$key}}, "$table.$column";
                     $self->exclude_privilege(-table=>$table, -column => $col, -privilege=>$key, -inherit=>$privileges); 
                }
                else { $dbc->error("urecognized format for access privilege") }
            }
 
            $column_priv = join ',', @enable_access;
            push @CP_fields, 'Table_name', ('Column_name', 'Column_priv');
            push @CP_values, $table, ($col, $column_priv);
        }
        else {
            $dbc->error("Format error in privilege specification for $column column");
        }
    }
    elsif ($table) { 
        ## specify Table privileges for either column or table specs ##
        if ($privileges->{$access_title}{'table_priv'} && $privileges->{$access_title}{'table_priv'}{$table} ) {
            my @enable_access;
            foreach my $key (keys %{$privileges->{$access_title}{'table_priv'}{$table}}) {
                my $priv =  $privileges->{$access_title}{'table_priv'}{$table}{$key};
                if (! ref $priv && $priv eq 'Y') { 
                    push @enable_access, $key;
                    push @{$self->{Include}->{$key}}, "$table";
                }
                elsif (! ref $priv && $priv eq 'N') { 
                    $self->exclude_privilege(-table=>$table, -privilege=>$key, -inherit=>$privileges); 
                    push @{$self->{Exclude}->{$key}}, $table;
                }                
                else { $dbc->error("urecognized format for access privilege") }
            }
            
            $table_priv = join ',', @enable_access;
            push @TP_fields, ("Table_name", 'Table_priv');
            push @TP_values, ($table, $table_priv);
        }
        else { $dbc->error("Error with table privilege format") }
    }
    else {
        $dbc->warning("no table specified");
    }
    
#   my @set_privileges = ('Select', 'Insert', 'Update', 'Delete', 'Create', 'Drop', 'Alter');
#    foreach my $key (@set_privileges) {
#        if (defined $privileges->{$key}) {
#            $self->{Default}{$key} = $privileges->{$key}
#        }
#    }

    return ($table_priv, $column_priv);
}

#
# Adjusts privilege hash to set default privilege level above when privilege is set to "N" for a specific table or column
# (eg if Select_priv = 'Y', but a single table has excluded select privileges, then the default Select_priv value is reset to 'N')
# 
# (another method will enable all tables EXCEPT the excluded table to have the select privilege set explicitly to 'Y')
#
# Return:  resets privilege hash to account for excluded privilege specifications 
#########################
sub exclude_privilege {
########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'table');
    
    my $table = $args{-table};
    my $column = $args{-column};
    my $inherit = $args{-inherit};
    my $privilege = $args{-privilege};
    
    my $dbc = $self->dbc();
    if ($inherit->{$privilege} eq 'Y') {
        $self->{Default}{$privilege} = 'N';
    }
    else { 
#        $dbc->message("$privilege Privilege already denied for $table ($column)");
    }
    
    return 1;
}

#
# Parse access privileges retrieved from DB_Access, Access_Inclusion, Access_Exclusion records to generate hash representing full privilege settings
#
# Input: either db_user or db_table 
#
# Return:  Hash indicating full resultant privilege settings
##############################
sub parse_Access_privileges {
##############################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'db_user');

    my $host = $args{-host};
    my $db_user = $args{-db_user};
    my $access_title = $args{-access_title};
    my $db_table = $args{-db_table};
    my $scope = $args{-scope};
    my $debug = $args{-debug};

    my $dbc = $self->dbc();

#    my @privileges = qw(Select Insert Update Delete);
    my @standard_privileges = qw(Select Insert Update Delete);
    my @fields = qw(DB_User DB_Access_Title);

    my $privileges;

    foreach my $priv (@standard_privileges) {
    #    push @fields, "${priv}_priv";
        push @fields, "${priv}_priv";
    }
    
    my $condition = "WHERE 1";
    if ($db_user) { $condition .= " AND DB_User = '$db_user'" }
    elsif ($access_title) { $condition .= " AND DB_Access_Title = '$access_title'"}
    elsif ($db_table =~/^\d+$/) {
        $condition .= " AND DBTable_ID = '$db_table'";
    }
    elsif ($db_table) { 
        $condition .= " AND DBTable_Name = '$db_table'";
    }

    if ($scope =~/prod/) { $condition .= " AND FKProduction_DB_Access__ID=DB_Access_ID" }
    else { $condition .= " AND FKnonProduction_DB_Access__ID=DB_Access_ID" }
    
    my $default = $dbc->hash(-table=>'DB_Access, DB_Login', -fields=>\@fields, -condition=>$condition);
    
    my $include = $dbc->hash(-table=>'DB_Access, DB_Login, Access_Inclusion LEFT JOIN DBTable ON Access_Inclusion.FK_DBTable__ID=DBTable_ID LEFT JOIN DBField ON Access_Inclusion.FK_DBField__ID=DBField_ID', 
                            -fields=>[@fields, 'DBTable_Name', 'Field_Name', 'Privilege'], 
                            -condition=>"$condition AND FK_DB_Access__ID=DB_Access_ID",
                            -debug=>$debug);

    if ($include) {  
        my $i = 0;
        while (defined $include->{DB_User}[$i]) {
            my $column = $include->{Column_name}[$i];
            my $table = $include->{DBTable_Name}[$i];
            my $user = $include->{DB_User}[$i];
            my $access = $include->{DB_Access_Title}[$i];
            my $priv = $include->{Privilege}[$i];
            
            ## turn off access at level above ##
            
            ## turn on access for column / table ##
            if ($column) {
                if ($include->{"${priv}_priv"}[$i] eq 'I') { 
                    $privileges->{$access}{'column_priv'}{"$table.$column"}{$priv} = 'Y';
                }
            }    
            else {
                if ($include->{"${priv}_priv"}[$i] eq 'I') { 
                    $privileges->{$access}{'table_priv'}{"$table"}{$priv} = 'Y';               
                }
            }
            $i++;
        }      
    }
    
    my $exclude = $dbc->hash(-table=>'DB_Access, DB_Login, Access_Exclusion LEFT JOIN DBTable ON Access_Exclusion.FK_DBTable__ID=DBTable_ID LEFT JOIN DBField ON Access_Exclusion.FK_DBField__ID=DBField_ID', 
                            -fields=>[@fields, 'DBTable_Name as Table_name', 'Field_Name as Column_name', 'Privilege'], 
                            -condition=>"$condition AND FK_DB_Access__ID=DB_Access_ID",
                            -debug=>$debug
                            );

    if ($exclude && %$exclude) {
        my $i = 0;
        
        while (defined $exclude->{DB_User}[$i]) {
            my $column = $exclude->{Column_name}[$i];
            my $table = $exclude->{Table_name}[$i];
            my $user = $exclude->{DB_User}[$i];
            my $access = $exclude->{DB_Access_Title}[$i];
            my $priv = $exclude->{Privilege}[$i];
           
            ## turn off access at level above ##
            if ($column) {
                if ($exclude->{"${priv}_priv"}[$i] eq 'X' ) { 
                    $privileges->{$access}{'column_priv'}{"$table.$column"}{$priv} = 'N';
                }
                elsif (ref $exclude->{"${priv}_priv"}[$i] eq 'ARRAY' && grep /^X$/, @{$exclude->{"${priv}_priv"}[$i]} ) { 
                    $privileges->{$access}{'column_priv'}{"$table.$column"}{$priv} = 'N';
                }
            }    
            else {
                if ($exclude->{"${priv}_priv"}[$i] eq 'X') { 
                    $privileges->{$access}{'table_priv'}{"$table"}{$priv} = 'N';               
                }
                elsif (ref $exclude->{"${priv}_priv"}[$i] eq 'ARRAY' && grep /^X$/, @{$exclude->{"${priv}_priv"}[$i]} ) { 
                    $privileges->{$access}{'table_priv'}{"$table"}{$priv} = 'N';               
                }
                
            }                           
            $i++;
        }
    }
    
    $self->{Privileges} = $privileges;
  
    return $privileges;
}

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

$Id: DB_Access.pm,v 1.2 2003/11/27 19:42:52 achan Exp $ (Release: $Name:  $)

=cut

return 1;
