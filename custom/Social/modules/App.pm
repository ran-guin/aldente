##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Social::App;

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
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);

use Social::Model;
use Social::Views;

##############################
# global_vars                #
##############################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
        'Save Preferences' => 'save_Preferences',
        'Create Event'     => 'create_Event',
);

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
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

    my $home_form = $self->help();

    return $home_form;
}

###################
sub create_Event {
########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $user_id = $q->param('User_ID');
    
    my $event_id; ## create ... 
    
    return $self->View->home_Event($event_id);
}

########################
sub save_Preferences {
########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $user_id = $q->param('User_ID');
    my $scope = $q->param('Scope');
    my $status_field = $q->param('Interest_Field');
    my $table = "User_$scope";
    my $ref_field = "FK_${scope}__ID";
    
    my @Input = $q->param();
    
    my @current = $dbc->get_db_array(-table=>"User_$scope", -field=>"Concat(FK_${scope}__ID, '-',$status_field)", -condition=>"FK_User__ID = $user_id");
    
    my %Set;
    my @Append;
    my $appends = 0;
    foreach my $save ( grep /^$scope\-(\d+)/, @Input) {
        if ($save =~/^$scope\-(\d+)/) {
            my $id = $1;
            my $val = $q->param($save);
            
            if (my ($curval) = grep /^$id\-(.+)/, @current) {
                $curval =~s/^$id\-//;
                if ($curval eq $val) { next }
                else { 
                    print "'$curval' ne '$val' for $id..<BR>";
                    push @{$Set{$val}}, $id;
                }
            }
            else {
                push @Append, [$user_id, $id, $val];
            }
        }
    }
    
    foreach my $key (keys %Set) {
        my $ids = join ',', @{$Set{$key}};
        my $updated = $dbc->update_DB(-table=>$table, -fields=>[$status_field], -values=>[$key], -condition=>"FK_User__ID = $user_id AND $ref_field IN ($ids)", -autoquote=>1);
        $dbc->message("Updated $updated $table records");
    }
    
    if (@Append) {
        my $appended = $dbc->append_DB(-table=>$table, -fields=>['FK_User__ID', $ref_field, $status_field], -values=>\@Append, -autoquote=>1);
        $dbc->message("Appended $appended records to the $table table");
    }
    return;
}


###########
sub help {
############

    my $page;

    $page .= "<B>General Instructions:</B>....";
    return $page;
}

return 1;
