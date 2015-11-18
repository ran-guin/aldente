###################################################################################################################################
# LampLite::DB_Access_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package LampLite::DB_Access_App;

use base RGTools::Base_App;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::DB_Access_App.pm - Controller for basic DB_Access functionality

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

use Time::localtime;

## Local modules ##
use LampLite::DB_Access_Views;
use LampLite::DB_Access;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Show Access');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Show Access' => 'display_Access',
            'Reset Access' => 'reset_Access',
            'Edit Access'  => 'edit_Access',
            'Update Access' => 'update_Access',
            'Set Table Access' => 'set_Table_Access',
            'Update Table Access' => 'update_Table_Access',
            'Update Column Access' => 'update_Table_Access',
         }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

######################
sub display_Access {
######################
	my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
    my $db_user = $q->param('db_user');
	my $access_user = $q->param('access_user');
	my $access_db = $q->param('access_dbase');
	my $access_title = $q->param('DB_Access_Title');
	my $scope = $q->param('Scope');
	
	return $self->View->display_DB_Access(-access_user=>$access_user, -dbase=>$access_db, -scope=>$scope, -db_user=>$db_user, -access_title=>$access_title);
}

##################
sub edit_Access {
##################
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->dbc();

    my $db_user = $q->param('db_user');
	my $access_user = $q->param('access_user');
	my $access_db = $q->param('access_dbase');
	my $access_title = $q->param('DB_Access_Title');
	my $scope = $q->param('Scope');

    return $self->View->edit_User_Access(-access_user=>$access_user, -dbase=>$access_db, -scope=>$scope, -db_user=>$db_user, -access_title=>$access_title)
}

##################
sub update_Access {
##################
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->dbc();

    my $db_user = $q->param('db_user');
	my $access_host = $q->param('access_host');
	my $access_user = $q->param('access_user');
	my $access_title = $q->param('DB_Access_Title');
	my $access_db = $q->param('access_dbase');
	my $scope = $q->param('Scope');
	
	my ($T, $F) = ({},{});
	    
    foreach my $priv ('Select', 'Insert', 'Update', 'Delete') {
        foreach my $scope ('Inclusions', 'Exclusions') {
            $T->{$scope}{$priv} = $q->param("Table_${priv}_$scope");
            $F->{$scope}{$priv} = $q->param("Field_${priv}_$scope");
        }
    }
    
    my @users = ($access_user);
    if ($access_title && !$access_user) {
        @users = $self->Model->db_access_users(-condition=>"DB_Access_Title = '$access_title'");
    }
     
    
    foreach my $access_user (@users) {
        $self->Model->reset_Access(-host=>$access_host, -dbase=>$access_db, -db_user=>$access_user, -access_title=>$access_title, -scope=>$scope);
    }
    $self->Model->update_Access(-dbase=>$access_db, -access_title=>$access_title, -include_tables=>$T->{Inclusions}, -include_fields=>$F->{Inclusions}, -exclude_tables=>$T->{Exclusions}, -exclude_fields=>$F->{Exclusions});

    my $page = $self->View->display_DB_Access(-access_user=>$access_user, -dbase=>$access_db, -scope=>$scope, -db_user=>$db_user, -access_title=>$access_title);
    
    return $page;
}

###########################
sub update_Table_Access {
###########################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
	my $access_host = $q->param('access_host');
	my $access_user = $q->param('access_user');
	my $access_title = $q->param('DB_Access_Title');
	my $access_db = $q->param('access_dbase');
	my $scope = $q->param('Scope');
	my $table = $q->param('DB_Table_Name');
	my $form_scope = 'Table';
	
    my @fields = ('');
	if ( $q->param('rm') =~/Column/ ) { 
	    $form_scope = 'Column';
	    @fields = $dbc->get_fields($table);
	}
	else {
	    $dbc->message($q->param('rm'));
	}
	
	my $condition;
	if ($access_title) { $condition = "DB_Access_Title = '$access_title'" }
	
	my $Model = $self->Model();
	my @accessers = $Model->db_access_users(-type=>"DB_Access_Title");
    my @privs     = $Model->db_privileges();
    my $access    = $Model->db_access(-scope=>$scope, -key=>'DB_Access_Title', -condition=>$condition);

    foreach my $access_level (@$access) {
        my ($accesser) = keys %{$access_level};
        my ($F, $T) = ( {}, {} );
        
        foreach my $priv (@privs) {
             my $set = $q->param("$accesser-$priv");
             my $std = $access_level->{$accesser}{"${priv}_priv"};
             
             foreach my $field (@fields) {
                 if ( $field=~/(\w+)\.(\w+)/ ) {
                     ## Column based specification ##
                     $field = $2;
                     $set = $q->param("$accesser-$priv-$field");
                  }
                 elsif ( $field=~/(\w+)/ ) {
                      ## Column based specification ##
                      $set = $q->param("$accesser-$priv-$field");
                  }
                  
                 if ( $set eq 'Y' && $std eq 'I') {
                     $dbc->message("Include $priv access to $table.$field");
                     $self->Model->set_Access(-dbase=>$access_db, -access_title=>$accesser, -privilege=>$priv, -table=>$table, -field=>$field, -action=>'Include');
                 }
                 elsif ($set eq 'N' && $std eq 'X') {
                     $dbc->message("Exclude $priv access to $table.$field");
                     $self->Model->set_Access(-dbase=>$access_db, -access_title=>$accesser, -privilege=>$priv, -table=>$table, -field=>$field, -action=>'Exclude');
                 }
                 
             }
        }
    }

    my $page = $self->View->display_DB_Access(-scope=>$scope);
    
    return $page;
}

###################
sub reset_Access {
###################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $db_user = $q->param('access_user') || 'lab_admin';
	my $access_db = $q->param('access_dbase');
	
    my $scope = $q->param('scope') || $q->param('Scope') || 'nonProduction';   ## dev or production
    
    my $access_control = $dbc->table_populated('DB_Login') && $dbc->table_populated('DB_Access');
    my $access_privilege = 1;

    if (!$access_control) { 
        $dbc->warning('no access control'); 
        return 'no'; 
    }
    elsif (!$access_privilege) { 
        $dbc->error("Access control only available to root user");
        return 'no';
    }
    
    my $dbase;
    my $production_dbase = $dbc->config('PRODUCTION_DATABASE');
    if ($scope eq 'production') { $dbase = $production_dbase }
    else { $dbase = $production_dbase . '_%' }
    
    ## load privileges ##
    my $privileges = $self->Model->parse_Access_privileges($db_user);
    
    $self->Model->reset_access_privilege(-dbc=>$dbc, -db_user=>$db_user, -dbase=>$dbase, -privileges=>$privileges, -reset=>1, -scope=>$scope);
    
    return $self->View->display_DB_Access(-access_user=>$db_user, -dbase=>$dbase, -scope=>$scope);
}

######################
sub set_Table_Access {
######################
    my $self = shift;
    
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $table_id = $q->param('FK_DBTable__ID');
    my $table = $q->param('Table');
    my $scope = $q->param('Scope');
    my $access_title = $q->param('DB_Access_Title');
    my $access_level = $q->param('Access Level');
    my $dbase = $q->param('access_db');
    
    if ($access_level eq 'Column') {
        return $self->View->edit_Column_Access(-table=>$table, -table_id=>$table_id, -scope=>$scope, -access_title=>$access_title, -dbase=>$dbase);
    }
    else {
        return $self->View->edit_Table_Access(-table=>$table, -table_id=>$table_id, -scope=>$scope, -access_title=>$access_title, -dbase=>$dbase);
    }
}

return 1;