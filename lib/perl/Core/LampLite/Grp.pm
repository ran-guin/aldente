package LampLite::Grp;

use base LampLite::DB_Object;

use strict;

use RGTools::RGIO;

#
# Return list of Grps of given type, access, and/or department (uses FK_info list with applicable condition)
#
# <snip>
#
#  my @grps = LampLite::Grp::get_Grps($dbc,'Lab,Research');
#
#  or to return just list of ids:
#
#  my @grps = LampLite::Grp::get_Grps($dbc,['Lab','Research'],-format=>'ids');
#
#  Return: Array of groups.
########################
sub get_Grps {
########################
    my %args = filter_input(\@_,-args=>'dbc,type,format', -self=>'LampLite::Grp');
    my $self = $args{-self} || $args{-Grp};

    my $dbc = $args{-dbc} || $self->dbc();
    my $type = $args{-type};
    my $format = $args{-format} || 'names';  ## ids or names
    my $access = $args{-access};
    my $department = $args{-department};	# list of department IDs

    my $types = Cast_List(-list=>$type,-to=>'string',-autoquote=>1);
    my $accesses = Cast_List(-list=>$access,-to=>'string',-autoquote=>1);
    my $departments = Cast_List(-list=>$department,-to=>'string');
    
    my $conditions = "Grp_Status = 'Active' ";
    if( $type ) {
    	$conditions .= " AND Grp_Type IN ($types) ";
    }
    if( $access ) {
    	$conditions .= " AND Access in ($accesses) ";
    }
    if( $department ) {
    	$conditions .= " AND FK_Department__ID IN ($departments) ";
    }

    my @returnval;
    my $field = 'Grp_ID';
    if ($format =~/name/i) {
		$field = $dbc->get_db_value(-sql=>"SELECT Field_Reference FROM DBField WHERE Field_Name = '$field'") || $field;
    }
	@returnval =  $dbc->get_db_array(-table=>'Grp', -field=>$field, -condition => $conditions);

    return @returnval;
}

########################################
#
#  Retrieve the groups associated with an object
#
#  <snip>
#    LampLite::Grp::get_groups('Employee',222)
#  </snip>
#
####################
sub get_groups {
####################
    my %args = &filter_input( \@_, -args => 'table,ids', -self=>'LampLite::Grp' );
    my $self = $args{-self} || $args{-Grp};
    my $dbc           = $args{-dbc} || $self->dbc();
    my $table         = $args{-table};
    my $ids           = $args{-ids};
    my $child_grps    = $args{-child_grps} || 'yes';
    my $access_levels = join( "','", @{ $args{-access} } ) if ( $args{-access} );
    my $superuser     = $args{-superuser} || 0;


    my ($public_group) = $dbc->Table_find('Grp','Grp_ID',"WHERE Grp_Name = 'Public'");
       
	my $condition = '1';
    if ($superuser) {
        $condition = '1';
    }
    elsif ($ids) {    ## previously this also had the condition $ids !~ /\s*/ - why ?
        $condition = 'FK_' . $table . "__ID IN ($ids)";
        if ($access_levels) {
            $condition .= " AND Access IN ('$access_levels')";
        }
    }

    my $user_group = "GrpEmployee";
    if ($table eq 'User') { $user_group = "User_Grp"}
        
    my @object_groups = $dbc->get_db_array(-sql=>"SELECT DISTINCT Grp_ID FROM Grp LEFT JOIN $user_group ON FK_Grp__ID=Grp_ID WHERE $condition ORDER BY Grp_ID");
    if ($superuser) { return @object_groups }    ## return all groups if superuser ##

    my @groups;
    if ( ( $child_grps eq 'yes' ) && @object_groups ) {
        my $group_list = join ',', @object_groups;

        @groups = _get_Groups_below( $dbc, $group_list );
    }
    else {
        @groups = @object_groups;
    }

    push @groups, @object_groups;                ## include original list as well
    push @groups, $public_group if $public_group;   ## add generic public group...
    return @{ RGTools::RGIO::unique_items( \@groups ) };
}

########################################
#
#  Given a group ID, this method will return the objects that are part of that group
#
#  <snip>
#     LampLite::Grp::get_group_members('Employee',14)
#  </snip>
#########################
sub get_group_members {
#########################
    my %args = &filter_input( \@_, -args => 'table,group_ids', -self=>'LampLite::Grp' );
    my $self = $args{-self} || $args{-Grp};
    my $dbc       = $args{-dbc} || $self->dbc();
    my $table     = $args{-table};
    my $group_ids = $args{-group_ids};

    my @ids = $dbc->get_db_array(-table=>'Grp' . $table, -field=>'FK_' . $table . '__ID', -condition=>"FK_Grp__ID IN ($group_ids)" );
    return @ids;
}
########################################
#
#  Recursively retreive all the child groups given a relation hash in the format (relation{derived} => child)
#
#  <snip>
#     LampLite::Grp::_get_Groups_above(24)
#  </snip>
##########################
sub _get_Groups_above {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,grp_id,relation', -mandatory => 'grp_id', -formats => { 'grp_id' => q{^\d+$} }, -self=>'LampLite::Grp');
    my $self = $args{-self} || $args{-Grp};
    my $dbc = $args{-dbc} || $self->dbc();
    my $grp_id = $args{-grp_id};

    unless ($grp_id) { return (undef) }

    my @parents;
    my $generation = $grp_id;
    while ($generation) {
        my @next_gen = $dbc->get_db_array(-sql=>"SELECT DISTINCT FKDerived_Grp__ID FROM Grp_Relationship WHERE FKBase_Grp__ID IN ($generation)");
        $generation = join ',', @next_gen;
        foreach my $add_grp (@next_gen) {
            push @parents, $add_grp unless ( grep /^$add_grp$/, @parents );
        }
    }
    return @parents;
}


########################################
#
#  recursively retreive all the child groups given a relation hash in the format (relation{derived} => child)
#
#  <snip>
#     LampLite::Grp::_get_Groups_below(24)
#  </snip>
##########################
sub _get_Groups_below {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,grp_id,relation', -mandatory => 'grp_id', -format => { 'grp_id' => q{^\d+\$} } , -self=>'LampLite::Grp');
    my $self = $args{-self} || $args{-Grp};
    my $dbc = $args{-dbc} || $self->dbc();
    my $grp_id = $args{-grp_id};

    my @children;
    my $generation = $grp_id;
    
    while ($generation) {
        my @next_gen = $dbc->get_db_array(-sql=>"SELECT DISTINCT FKBase_Grp__ID FROM Grp_Relationship WHERE FKDerived_Grp__ID IN ($generation)");
        $generation = join ',', @next_gen;
        foreach my $add_grp (@next_gen) {
            push @children, $add_grp unless ( grep /^$add_grp$/, @children );
        }
    }
    return @children;
}

###########################
sub get_parent_groups {
###########################
    my %args = &filter_input( \@_, -args => 'group_id', -mandatory => 'group_id', -self=>'LampLite::Grp' );
    my $self = $args{-self} || $args{-Grp};

    my $dbc = $args{-dbc} || $self->dbc;
    my $group_id = $args{-group_id};

    ## convert to ID if in alphanumeric form ##
    if ( $group_id =~ /\D/ ) { $group_id = $dbc->get_db_value( -table=>'Grp', -field=>'Grp_ID', -condition=>"Grp_Name IN ('$group_id')" ) }

    my $add     = $group_id;
    my $parents = $group_id;

    my $stuck = 64;
    while ( $add && $stuck-- ) {
        $add = join ',', $dbc->get_db_array(-sql=>"SELECT DISTINCT FKDerived_Grp__ID FROM Grp_Relationship WHERFKBase_Grp__ID IN ($add) AND FKDerived_Grp__ID NOT IN ($add)");
        $parents .= ",$add" if $add;
    }

    return $parents;
}

####################
sub get_child_groups {
####################
    my %args     = &filter_input( \@_, -args => 'group_id', -mandatory => 'group_id', -self=>'LampLite::Grp');
    my $self = $args{-self} || $args{-Grp};
    my $group_id = $args{-group_id};
    my $dbc      = $args{-dbc} || $self->dbc;

    ## convert to ID if in alphanumeric form ##
    if ( $group_id !~ /^[\d,\s]+$/ ) {  $group_id = $dbc->get_db_value( -table=>'Grp', -field=>'Grp_ID', -condition=>"Grp_Name IN ('$group_id')" ) }

    my $add      = $group_id;
    my $children = $group_id;

    my $stuck = 64;
    while ( $add && $stuck-- ) {
        $add = join ',', $dbc->get_db_array(-table=>'Grp_Relationship', -field=>'FKBase_Grp__ID', -condition=>"FKDerived_Grp__ID IN ($add) AND FKBase_Grp__ID NOT IN ($add)" );
        $children .= ",$add" if $add;

    }

    return $children;
}

return 1;
