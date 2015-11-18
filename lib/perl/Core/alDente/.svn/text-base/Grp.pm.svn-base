package alDente::Grp;

use base LampLite::Grp;

use strict;

use RGTools::RGIO;
use RGTools::RGmath;

########################################
#
#  Retruns the list of Groups associated with an object in HTML format
#
#  Inputs: -table=>Object_Table, -id=>Object_ID, [-output=>'name'], -groups=>group list
#
#  Outputs: HTML List of groups
#
#  <snip>
#    ### Display the groups associated with this object
#    alDente::Grp::display_groups('Standard_Solution',$id,-output=>'name');
#
#    ### Display the name of these groups
#    alDente::Grp::display_groups(-groups=>$groups,-output=>'name');
#  </snip>
#
####################
sub display_groups {
####################
    my %args = &filter_input( \@_, -args => 'table,id' );

    my $dbc          = $args{-dbc};
    my $table        = $args{-table};
    my $id           = $args{-id};
    my $output       = $args{-output};
    my $child_groups = $args{-child_groups};
    my $no_add_link  = $args{-noadd};
    my $unlink_group = $args{-unlink_group};
    my $groups       = $args{-groups};

    my @groups;

    if ($groups) {
        @groups = Cast_List( -list => $groups, -to => 'array' );
    }
    else {
        @groups = get_groups( -table => $table, -ids => $id, -child_grps => $child_groups );
    }

    if ( $output =~ /name/ ) {
        @groups = $dbc->Table_find( 'Grp', 'Grp_Name', "WHERE Grp_ID IN(" . join( ',', @groups ) . ")" );
    }

    my $html = "<h2>Viewable by the following groups: ";

    my $user_group = "GrpEmployee";
    if ($table eq 'User') { $user_group = "User_Grp"}
    
    if ( $table && !$no_add_link ) {
        $html .= &Link_To( $dbc->config('homelink'), HTML_Comment('(Add Group)'), "&New+Entry=New+$user_group&FK_$table" . "__ID=$id",'', ['newwin'] );
    }
    
    if ( $table && $unlink_group ) {
	$html .= &Link_To( $dbc->config('homelink'), HTML_Comment('(Unlink Group)'), "&Edit+Table=Edit+$user_group+Table&Condition=FK_Grp__ID+IN+($groups)", '', ['newwin'] );
    }
    
    $html .= "<UL type=circle>" . join( '', map {"<LI>$_</LI>"} @groups ) . "</UL></h2>";

}

############################
sub get_system_groups {
############################
    my %args = &filter_input( \@_, -args => 'level' );
    my $dbc = $args{-dbc};
    my $access = $args{-access};

    my $condition = 'WHERE 1';
    if ($access) {
        $condition = "WHERE Acess='$access'";
    }

    return join ',', $dbc->Table_find( 'Grp', 'Grp_ID', $condition );
}

#############################
#
#  This function takes one of the following as input parameter as an array reference and returns an array reference of the Grp_IDs which the input parameter belongs to.
#  Equipment, Project, Group, Library
#  The include_parent flag allows the search to include the parent groups of the input parameter if it is set to 1.
#############################
sub relevant_grp {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,equipment_ids,project_ids,group_ids,library,include_parent' );

    my $dbc = $args{-dbc};

    my $equipment      = $args{-equipment_ids};     # Equipment_ID from the Equipment Table.
    my $project        = $args{-project_ids};       # Project_ID from the Project Table
    my $group          = $args{-group_ids};         # Grp_ID from the Grp Table
    my $library        = $args{-library};           # Library_Name from the Library Table
    my $include_parent = $args{-include_parent};    # If set to 1, include parent group in the search results

    $equipment = Cast_List( -list => $equipment, -to => 'string', -delimiter => ',' );
    $group     = Cast_List( -list => $group,     -to => 'string', -delimiter => ',' );
    $library   = Cast_List( -list => $library,   -to => 'string', -delimiter => ',', -autoquote => 1 );
    $project   = Cast_List( -list => $project,   -to => 'string', -delimiter => ',' );
    my @grp_id = ();

    if ( length($equipment) > 0 ) {

        # get data from stock
        @grp_id = $dbc->Table_find( 'Equipment,Stock', 'FK_Grp__ID', "WHERE Equipment_ID in ($equipment) and Stock_ID = FK_Stock__ID", -debug => 0, -distinct => 1 );

    }

    if ( length($project) > 0 ) {

        #retrieve from library
        @grp_id = $dbc->Table_find( 'Library', 'FK_Grp__ID', "WHERE FK_Project__ID in ($project)", -debug => 0, -distinct => 1 );

    }

    if ( length($group) > 0 ) {
        @grp_id = Cast_List( -list => $group, -to => 'Array' );
    }

    if ( length($library) > 0 ) {
        @grp_id = $dbc->Table_find( 'Library,Project', 'FK_Grp__ID', "WHERE Library_Name in ($library) and FK_Project__ID = Project_ID", -debug => 0, -distinct => 1 );

    }

    my $group_id;
    my @group_id_list = ();
    if ( $include_parent == 1 ) {
        for my $grp (@grp_id) {
            $group_id = get_parent_groups( -group_id => $grp, -dbc => $dbc );

            my @parent_grps = Cast_List( -list => $group_id, -to => 'array', -delimiter => ',' );
            push( @group_id_list, @parent_grps );
        }
        return \@group_id_list;
    }
    else {
        return \@grp_id;
    }

}

#############################
#
#  This function find all the Libaray for the Group specified by  the input parameter Grp_ID.
#
#############################
sub relevant_library {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,groupid' );

    my $dbc = $args{-dbc};

    my @group_id = $args{-groupid};
    my $group_id_list = Cast_List( -list => @group_id, -to => 'string' );

    my @library_id = $dbc->Table_find( 'Grp', 'FK_Library__ID', "WHERE Grp_ID in ($group_id_list)", -debug => 1 );

    return @library_id;
}

##########################################################
# find all the group ids in which the department belongs to
##########################################################
sub get_dept_groups {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,dept_id,dept_name' );
    my $dbc     = $args{-dbc};
    my $dept_id = $args{-dept_id};
    my $dept_name = $args{-dept_name};
    
    my $tables = "Grp";
    my $conditions = "WHERE 1";
    if( $dept_id ) { 
    	my $id_list = Cast_List( -list => $dept_id, -to => 'string' );
    	$conditions .= " AND FK_Department__ID in ($id_list)" 
    }
    elsif( $dept_name ) {
    	my $name_list = Cast_List( -list => $dept_name, -to => 'string', -autoquote => 1 );
    	$tables .= ",Department";
    	$conditions .= " AND FK_Department__ID = Department_ID AND Department_Name in ($name_list) ";
    }
    my @result  = $dbc->Table_find( $tables, 'Grp_ID', $conditions );
    return \@result;
}

#
# Remove Grp from Database
# * Requires Replacement group if anything references this group
# * Automatically removes group from Relationship hierarchy
#   ie - changes all 'Base' grp records to its list of 'Base' grps
#   - changes all 'Derived' grp records to be derived from its 'Base' grps
#
# Return: 1 on success
##################
sub remove_Grp {
##################
    my $dbc         = shift;
    my $grp_id      = shift;
    my $replacement = shift;
    my $debug       = shift;

    if ( $grp_id =~ /^\d+$/ && $replacement =~ /^\d*$/ ) {
        ## included group ids explicitly ... leave alone
        Message("Replacing Grp$grp_id with Grp$replacement");
    }
    else {
        ## convert names to ids  .. ##
        Message("Replacing $grp_id with $replacement");
        ($grp_id) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = '$grp_id'" );
        if ($replacement) { ($replacement) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = '$replacement'" ) }
    }

    if (!$grp_id) { Message("No Grp found"); return 1; }
    ## example for deleting 'B' given relationship: A -> B -> C

    ## get list of derived groups (eg Admin) ##
    my @derived = $dbc->Table_find( 'Grp_Relationship', 'FKDerived_Grp__ID', "WHERE FKBase_Grp__ID = '$grp_id'" );

    ## get list of base groups ( eg Public)
    my @base = $dbc->Table_find( 'Grp_Relationship', 'FKBase_Grp__ID', "WHERE FKDerived_Grp__ID = '$grp_id'" );

    $dbc->start_transaction('remove_grp');

    ### Delete Grp Relationship records (will be replaced below) ###
    $dbc->delete_record( 'Grp_Relationship', -field => 'FKBase_Grp__ID',    -value => $grp_id, -debug => $debug );
    $dbc->delete_record( 'Grp_Relationship', -field => 'FKDerived_Grp__ID', -value => $grp_id, -debug => $debug );

    ### replace Grp (along with all remaining Grp referencing records) - replace if applicable
    if ($replacement){
        $dbc->replace_records(-table => 'Grp', -field => 'Grp_ID', -value => $grp_id, -replace => $replacement, -debug => $debug );
    }
    else {
        $dbc->delete_record( 'Grp', -field => 'Grp_ID', -value => $grp_id, -replace => $replacement, -debug => $debug );
    }
    ### Replace all Group Relationships (eg change A -> B into A -> C) ##
    foreach my $derived_grp (@derived) {
        foreach my $base_grp (@base) {
            if ( ( $base_grp eq $replacement ) || ( $derived_grp eq $replacement ) ) {next}
            ## add every combination of base -> derived if mid group is replaced...
            my ($count) = $dbc->Table_find( 'Grp_Relationship', 'Count(*)', "WHERE FKBase_Grp__ID=$base_grp AND FKDerived_Grp__ID=$derived_grp" );

            ## only add relationship if it does not already exist .. ##
            if ( !$count ) { $dbc->Table_append_array( 'Grp_Relationship', [ 'FKBase_Grp__ID', 'FKDerived_Grp__ID' ], [ $base_grp, $derived_grp ], -debug => $debug ) }
        }
    }
    return $dbc->finish_transaction('remove_grp');
}

#########################
# To retrieve the pipelines that are associated with the specified group.
# It gets the available pipelines from two places:
#	1. From Pipeline table with Pipeline.FK_Grp__ID in specified group list ( keep this to remain backward compatable )
#	2. From GrpPipeline table with GrpPipeline.FK_Grp__ID in specified group list 
#
# Usage:
#	my @pipelines = @{alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => '48,55', -department_name => 'Biospecimen_Core', -return_format => 'Name' )};
#	my @pipelines = @{alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => '48,55' )};
#
# Return:
#	Array ref of pipelines( ID or string of "Pipeline_Code : Pipeline_Name", as indicated by return_format parameter). 
#########################
sub get_group_pipeline {
#########################	
    my %args = &filter_input( \@_, -args => 'dbc,grp,department_name,return_format', -mandatory => 'dbc,grp' );
    my $dbc     = $args{-dbc};
    my $grps = $args{-grp};	# list of group ids
    my $dept_name = $args{-department_name};	# the department name
    my $return_format = $args{-return_format} || 'ID';	# the return format: ID or Name. If it is ID, it will return array ref of pipeline IDs. If it is Name, it will return array ref of "Pipeline_Code : Pipeline_Name".
    
    my $group_list = Cast_List( -list => $grps, -to => 'string' );
    my $tables = 'Pipeline, Grp';
    my $conditions = "WHERE Pipeline.FK_Grp__ID=Grp_ID AND Grp_ID in ($group_list) AND Pipeline_Status = 'Active'";
    if( $dept_name ) {
    	$tables .= ', Department';
    	$conditions .= " AND Grp.FK_Department__ID= Department_ID and Department_Name ='$dept_name'";
    }
    my @original_pipelines = $dbc->Table_find( $tables, 'Pipeline_ID', $conditions );
    my @associated_pipelines = $dbc->Table_find( 'GrpPipeline,Pipeline', "Pipeline_ID", "WHERE FK_Pipeline__ID = Pipeline_ID AND GrpPipeline.FK_Grp__ID in ( $group_list )", -distinct => 1);
	my $available_pipelines = &RGmath::union( \@original_pipelines, \@associated_pipelines );
	if( $return_format eq 'Name' ) {
		my @available_pipeline_names = ();
		foreach my $id ( @$available_pipelines ) {
			my $info = $dbc->get_FK_info( -field => 'FK_Pipeline__ID', -id => $id );
			push @available_pipeline_names, $info;
		}
		return \@available_pipeline_names;
	}
	else {
		return $available_pipelines;
	}
}


return 1;
