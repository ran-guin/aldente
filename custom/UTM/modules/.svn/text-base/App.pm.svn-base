##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package UTM::App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use LampLite::Bootstrap;

use UTM::Model;
use UTM::Views;

my $BS = new Bootstrap();
############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
        'Help'                             => 'help',
        'Summary'                          => 'summary',
        'Generate Summary'                 => 'summary',
        'Register as Member' => 'register_Member',
        'Register as Host' => 'register_Host',
);

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

#    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    
    my $page;
    return $page;
}



#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes
##################
sub home_page {
##################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $page = 'home page under construction';
    return $page;
}

###########
sub help {
############
    my $self = shift;
    my $page;

    return $page;
}

######################
sub register_Member {
######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->dbc;

    my $field_info = $dbc->table_specs('User');
    
    my $f = $field_info->{Field} || $field_info->{Field_Name};
    my @fields = @{$f} if $f;

     my $data;
     foreach my $field (@fields) {
         my $val = $q->param($field);
         $data->{$field} = $val;
     }
    
    my $name = $data->{User_Name};
    my $existing =  $dbc->get_db_value(-sql=>"SELECT User_ID from User where User_Name = '$name'");

    my $public = $dbc->get_db_value(-sql=>"SELECT Department_ID from Department where Department_Name = 'Public'");
    
    if ($existing) {
        print $BS->error("Sorry - the username: '$name' is already taken.  Please try another user name.");
 
        my %hidden;
        $hidden{FK_Department__ID} = $public;
        $hidden{User_Status} = 'Active';
        $hidden{User_Access} = 'Member';
        
        print $dbc->View->update_Record(-table=>'User', -hidden=>\%hidden, -append=>1 , -cgi_app=>'UTM::App', -rm=>'Register as Member', -form_columns=>2);
    }
    else {
        $data->{'FK_Department_ID'} ||= $public;
        $data->{'User_Status'} ||= 'Active';
        $data->{'User_Access'} ||= 'Member';

        if ( $data->{'Password'} ) { 
            $data->{'Password'} = $dbc->get_db_value(-sql=>"SELECT Password('" . $data->{'Password'} . "')");
        }
        my $id = $dbc->save_Record('User', $data);  

        print "You are now registered.  Please login again.";
    }
     
     
    ## Also add to public group ... ## 
     main::leave($dbc);
}

####################
sub register_Host {
####################
    my $self = shift;
    
    return "register host ...";
    
}

return 1;
