###################################################################################################################################
# Social::Event_Views.pm
#
# View in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package Social::Event_Views;

use base SDB::DB_Object_Views;
use strict;

use Social::Event;
use LampLite::CGI;

my $q = new LampLite::CGI;

use RGTools::RGIO;   ## include standard tools


####################
sub std_home_page {
####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $Object = $args{-Object};
    my $event_id = $args{-id} || $args{-event_id} || $Object->{id};
    
    my $dbc = $self->dbc;

    $dbc->message("Event $event_id");
    my $condition = 1;
    
    my $view;
    if ($event_id) { 
        $condition .= " AND Event_ID = $event_id";
        $view .= $dbc->View->display_Record(-table=>'Event', -id=>$event_id); #  = $dbc->view_Record(-table=>'Event', -id=> $event_id);
    }

    my $tables = 'Event';
    my @fields = ("Event_ID as Event");
    my @links = qw(Event_Type Interest Skill);
    
    foreach my $join (@links) { 
        $tables .= " LEFT JOIN Event_$join ON Event_$join.FK_Event__ID=Event_ID LEFT JOIN $join ON ${join}_ID = Event_$join.FK_${join}__ID";

        my $level;
        if ($join eq 'Event_Type') { $level = 'Event_Type_Interest_Level' }
        elsif ($join eq 'Interest') { $level = 'Interest_Level'  }
        elsif ($join eq 'Skill') { $level = 'Skill_Level'  }

        push @fields, "GROUP_CONCAT(DISTINCT ${join}_Name, ' - [if >= ', Event_$join.$level, ']') AS $join";
    }

    $view .= $self->list_Events(-event_id=>$event_id);
    
    return $view;
    
}

##################
sub list_Events {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'condition');
    my $condition = $args{-condition} || 1;
    my $dbc = $args{-dbc} || $self->dbc;
    my $title = $args{-title} || "Attendance Filters";
    my $user_id = $args{-user_id};
    my $event_id = $args{-event_id};
    my $enable = $args{-enable} || $dbc->config('user_id');

    my $current_user = $dbc->config('user_id');
    
    my $tables = 'Event';
    
    if ($user_id) { 
        $tables .= ",User_Event";
        $condition .= " AND User_Event.FK_User__ID=User_ID";
    }
    if ($event_id) {
        $condition .= " AND Event_ID = $event_id";        
    }
    my @fields = ("Event_ID as Event", "Event_Start as Start", 'Event_Finish as Finish','Event_Description as Description','FKHost_User__ID as Host');
    my @links = qw(Event_Type Interest Skill);
    foreach my $join (@links) { 
        $tables .= " LEFT JOIN Event_$join ON Event_$join.FK_Event__ID=Event_ID LEFT JOIN $join ON ${join}_ID = Event_$join.FK_${join}__ID";
        
        my $level;
        if ($join eq 'Event_Type') { $level = 'Event_Type_Interest_Level' }
        elsif ($join eq 'Interest') { $level = 'Interest_Level'  }
        elsif ($join eq 'Skill') { $level = 'Skill_Level'  }
        
        push @fields, "GROUP_CONCAT(DISTINCT '<B>', ${join}_Name, '</B> - [if >= ', Event_$join.$level, ']') AS $join";
    }
    
    my $view = $dbc->Table_retrieve_display(
        -title=>$title,
        -table=>$tables, -fields=>\@fields, -condition=>"WHERE $condition GROUP BY Event_ID", -return_html=>1, -list_in_folders=>\@links);

    my $status = $dbc->get_db_value(-table=>'Event', -field=>'Event_Status', -condition=>"Event_ID = '$event_id'");
    
    if ($current_user && $event_id) { 
        eval "require LampLite::Form";
        my $Form = new LampLite::Form(-dbc=>$dbc);
        my $include = $q->hidden(-name=>'cgi_app', -value=>'Social::Event_App', -force=>1)
        . $q->hidden(-name=>'User_ID', -value=>$current_user, -force=>1, -class=>'Action')
        . $q->hidden(-name=>'Event_ID', -value=>$event_id, -force=>1, -class=>'Action');
        
         if ($status eq 'Published') {
             $include .= $q->submit(-name=>'rm', -value=>'Attend', -force=>1, -class=>'Action');
         }
        if ($status eq 'Draft') {
            $include .= $q->submit(-name=>'rm', -value=>'Generate Invitation List', -class=>'Action');
        }
        if ($status eq 'Draft' ) {
            $include .= $q->submit(-name=>'rm', -value=>'Publish', -class=>'Action');
        }
        if ($status eq 'Published') {
            $include .= $q->submit(-name=>'rm', -value=>'Cancel Event', -class=>'Action');
        }
    
        $view .= $Form->generate(-wrap=>1, -include=> $include);
    }
    
    return $view;
}

###########################
sub display_record_page {
###########################
    my $self = shift;
    my $dbc= $self->dbc;
    
    $dbc->message("RD");
    return "ok";
}

1;


