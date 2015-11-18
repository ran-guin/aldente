###################################################################################################################################
# Social::Event.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package Social::Event;

use base SDB::DB_Object;

use strict;

use RGTools::RGIO;   ## include standard tools

################################
sub generate_Invitation_List {
################################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'event_id', -mandatory=>'event_id');
    my $dbc = $args{-dbc} || $self->dbc;
    my $event_id  = $args{-event_id};
    my $debug = $args{-debug};
    
    my $Skills = $dbc->hashes(-table=>'Event_Skill', -fields=>['FK_Skill__ID as ID', 'Skill_Level as Level'], -condition=>"FK_Event__ID = '$event_id'", -debug=>$debug);
    
    my $Interests = $dbc->hashes(-table=>'Event_Interest', -fields=>['FK_Interest__ID as ID', 'Interest_Level as Level'], -condition=>"FK_Event__ID = '$event_id'", -debug=>$debug);
    
    my $Types = $dbc->hashes(-table=>'Event_Event_Type', -fields=>['FK_Event_Type__ID as ID', 'Event_Type_Interest_Level as Level'], -condition=>"FK_Event__ID = '$event_id'", -debug=>$debug);
    
    my (@skill_conditions, @interest_conditions, @type_conditions);
    
    my @conditions;
    
    my $tables = "User";
    my (%SL, %IL, %TL);
    
    my @conditions = ('User_ID IS NOT NULL');
    my $i = 0;
    if ($Skills) {    
        my $link = "Skill";
        my $link_level = 'Skill_Level';
        my @required = @$Skills;
        
        foreach my $key (@required) {
            my $id = $key->{ID};
            my $level = $key->{Level};
            
            $tables .= " RIGHT JOIN User_$link as LINK$i ON LINK$i.$link_level >= '$level' AND LINK$i.FK_${link}__ID = $id AND LINK$i.FK_User__ID = User_ID";
            push @conditions, "LINK$i.$link_level IS NOT NULL";
        }
    } 
    
    if ($Interests) {    
        my $link = "Interest";
        my $link_level = 'Interest_Level';
        my @required = @$Interests;
        
         foreach my $key (@required) {
            my $id = $key->{ID};
            my $level = $key->{Level};
            $i++;
            
            $tables .= " RIGHT JOIN User_$link as LINK$i ON LINK$i.$link_level >= '$level' AND LINK$i.FK_${link}__ID = $id AND LINK$i.FK_User__ID = User_ID";
            push @conditions, "LINK$i.$link_level IS NOT NULL";
        }
    }
    if ($Types) {    
        my $link = "Event_Type";
        my $link_level = 'Event_Type_Interest_Level';
        my @required = @$Types;
        
        foreach my $key (@required) {
            my $id = $key->{ID};
            my $level = $key->{Level};
            $i++;
            
            $tables .= " RIGHT JOIN User_$link as LINK$i ON LINK$i.$link_level >= '$level' AND LINK$i.FK_${link}__ID = $id AND LINK$i.FK_User__ID = User_ID";
            push @conditions, "LINK$i.$link_level IS NOT NULL";
        }
    }
   
    my $conditions = join ' AND ', @conditions;
    
    my @invitees = $dbc->get_db_array(-tables=>$tables, -field=>'User_ID', -condition=>$conditions, -distinct=>1);
 
    my $matches = int(@invitees);
    
    $dbc->message("$matches Member(s) match event requirements: @invitees");
    
    return @invitees;
}

1;


