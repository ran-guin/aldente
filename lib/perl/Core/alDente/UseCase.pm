#
################################################################################
# UseCase.pm
#
# This module handles UseCase functions
#
###############################################################################
package alDente::UseCase;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);
use Data::Dumper;
use SDB::CustomSettings;

use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;
use alDente::Form;
use vars qw($Connection $user);
use vars qw($MenuSearch $scanner_mode);

my $debug = 0;

###########################
# Constructor of the object
###########################
sub new {
    if ($debug) {
        print "--> UseCase::new()<BR>";
    }

    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $dbc     = $args{-dbc}     || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $case_id = $args{-case_id} || $args{-id};                                                       # required
    my $tables  = $args{-tables}  || 'UseCase';
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    my ($step_id) = $dbc->Table_find( "UseCase_Step", 'UseCase_Step_ID', "WHERE FK_UseCase__ID=$case_id" );

    if ($case_id) {
        $self->primary_value( -table => "UseCase", -value => $case_id );
        $self->{id} = $case_id;

        my @step_ids = $dbc->Table_find( "UseCase_Step", 'UseCase_Step_ID', "WHERE FK_UseCase__ID=$case_id" );
        if ( scalar(@step_ids) > 0 ) {
            $self->add_tables('UseCase_Step');
        }
    }

    $self->{dbc} = $dbc;

    $self->load_Object();
    bless $self, $class;
    return $self;
}

############################
sub load_Object {
    #########################
    if ($debug) {
        print "--> UseCase::load_Object()<BR>";
    }

    my $self = shift;
    $self->SUPER::load_Object();

    $self->set( 'id',          $self->get_data('UseCase_ID') );
    $self->set( 'name',        $self->get_data('UseCase_Name') );
    $self->set( 'description', $self->get_data('UseCase_Description') );
    $self->set( 'created',     $self->get_data('UseCase_Created') );
    $self->set( 'modified',    $self->get_data('UseCase_Modified') );

    return 1;
}

#######################
#
# <CONSTRUCTION> - move this to home_page (standardized for Object home pages, and make home_page
#  (script automatically comes here with HomePage=UseCase, ID=$id in Info.pm module)
#
############
sub home_info {
    ############
    my $self = shift;

    print $self->view( -admin_view => 1 );
}

###########################
# Display the homepage
#
# Return: 1 on success
#########################
sub home_page {
#########################
    if ($debug) {
        print "--> UseCase::home_page()<BR>";
    }

    my %args = &filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    print alDente::Form::start_alDente_form( $dbc, 'UseCasePage' );

    ## Get a list of usecases
    my %usecase_hash = $dbc->Table_retrieve( 'UseCase', [ 'UseCase_ID', 'UseCase_Name', 'UseCase_Description', 'UseCase_Created', 'UseCase_Modified' ], "WHERE FKParent_UseCase__ID IS NULL or FKParent_UseCase__ID =0" );

    # save UseCase information in a specific order (to be easily retrieved)
    my @cases = ();
    my $index = 0;
    foreach my $usecase_id ( @{ $usecase_hash{'UseCase_ID'} } ) {
        push( @cases, [ $usecase_id, $usecase_hash{'UseCase_Name'}[$index], $usecase_hash{'UseCase_Description'}[$index], $usecase_hash{'UseCase_Created'}[$index], $usecase_hash{'UseCase_Modified'}[$index] ] );
        $index++;
    }

    if ( scalar(@cases) ) {
        my @case_headers = ( 'Select', 'Name', 'Description', 'Last Modified', 'Created' );
        my $case_table = HTML_Table->new( -width => 800 );
        $case_table->Set_Title("Use Cases");
        $case_table->Set_Headers( \@case_headers );

        foreach my $case (@cases) {

            # Get UseCase info
            my ( $case_id, $case_name, $case_desc, $case_created, $case_modified ) = @{$case};
            $case_table->Set_Row( [ "<INPUT TYPE='radio' NAME='Select UseCase' VALUE='$case_id'>", $case_name, $case_desc, $case_modified, $case_created ] );
        }
        $case_table->Printout();

        print submit( -name => "View UseCase",   -value => 'View Use Case',    -class => "Std" ) . "\t";
        print submit( -name => "Delete UseCase", -value => 'Delete Use Case',  -class => "Action" ) . "\t";
        print submit( -name => "Add UseCase",    -value => 'Add New Use Case', -class => "Std" ) . "\t";
        print checkbox( -name => "Admin_View", -label => "Administrative Mode", -checked => 1 -force => 1 );
    }
    else {
        print "Sorry, no Use Cases available<BR>";
        print submit( -name => "Add UseCase", -value => 'Add Use Case', -class => "Std" );
    }

    print end_form();

    return 1;
}

#########################
#
# Marks the parent step as a branch step
#
#
###########################
sub mark_as_branch {
    #########################
    if ($debug) {
        print "--> UseCase::mark_as_branch()<BR>";
    }

    my %args = &filter_input( \@_, -args => 'dbc,step_id,child' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $step_id = $args{-step_id};
    my $table   = "UseCase_Step";
    my $ok      = 0;
    my $case_id = 0;

    $ok = $dbc->Table_update( $table, 'UseCase_Step_Branch', "1", "where UseCase_Step_ID = '$step_id'" );

    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }

}

#########################
#
# Deletes the UseCase step and resets the FKParent_UseCase_Step__ID of its child step
#
###########################
sub delete_step {
    #########################
    if ($debug) {
        print "--> UseCase::delete_step()<BR>";
    }

    my %args = &filter_input( \@_, -args => 'dbc,step_id' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $step_id = $args{-step_id};
    my $table   = "UseCase_Step";
    my $ok      = 0;

    my $deleted = $dbc->delete_records( -table => $table, -dfield => 'UseCase_Step_ID', -id_list => $step_id, -override => 1 );

    # update other steps to account for the deleted step
    my ($parent_info) = $dbc->Table_find( $table, 'FKParent_UseCase_Step__ID,FK_UseCase__ID', "WHERE UseCase_Step_ID=$step_id" );
    my ( $parent_id, $case_id ) = split( ',', $parent_info );

    if ($deleted) {

        my @children = $dbc->Table_find( $table, 'UseCase_Step_ID', "WHERE FKParent_UseCase_Step__ID=$step_id" );
        my $child_list = Cast_List( -list => \@children, -to => 'string' );

        if ( scalar(@children) > 0 ) {
            $ok = $dbc->Table_update( $table, 'FKParent_UseCase_Step__ID', "$parent_id", "WHERE UseCase_Step_ID IN ($child_list)" );

            if ( ( scalar(@children) > 1 ) && $ok ) {
                mark_as_branch( -dbc => $dbc, -step_id => $parent_id );
            }
        }
    }

    my $usecase = alDente::UseCase->new( -dbc => $dbc, -case_id => $case_id );
    print $usecase->view( -dbc => $dbc );

}

#########################
#
# Deletes the UseCase and all UseCase_Steps associated with that UseCase
#
###########################
sub delete_case {
    #########################
    if ($debug) {
        print "--> UseCase::delete_case()<BR>";
    }

    my %args = &filter_input( \@_, -args => 'dbc,case_id' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $case_id = $args{-case_id};
    my $table   = "UseCase";
    my $ok      = 0;

    my @children = $dbc->Table_find( $table, 'UseCase_ID', "WHERE FKParent_UseCase__ID=$case_id" );
    my $child_list = Cast_List( -list => \@children, -to => 'string' );
    my @children_steps = $dbc->Table_find( $table, 'UseCase_Step_ID', "WHERE FK_UseCase__ID IN ($child_list)" );
    my $children_steps_list = Cast_List( -list => \@children_steps, -to => 'string' );
    my $children_deleted;
    my $case_deleted;

    if ( scalar(@children) > 0 ) {
        my $children_steps_deleted = $dbc->delete_records( -table => "UseCase_Step", -dfield => 'UseCase_Step_ID', -id_list => $children_steps_list );

        if ($children_steps_deleted) {
            $children_deleted = $dbc->delete_records( -table => $table, -dfield => 'UseCase_ID', -id_list => $child_list );
        }
    }

    if ($children_deleted) {
        my $case_deleted = $dbc->delete_records( -table => $table, -dfield => 'UseCase_ID', -id_list => $case_id );
    }

    home_page( -dbc => $dbc );

}

#########################
#
# Display the homepage
#
# Return: 1 on success
###########################
sub view_case {
    #########################
    if ($debug) {
        print "--> UseCase::view_case()<BR>";
    }

    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $step_id = $args{-step_id};
    my $case_id = $args{-case_id} || 0;
    my $tables  = $args{-table} || "UseCase,UseCase_Step";

    if ($step_id) {
        my ($case_id) = $dbc->Table_find( $tables, 'FK_UseCase__ID', "WHERE UseCase_Step_ID=$step_id" );
        if ($case_id) {
            my $usecase = alDente::UseCase->new( -dbc => $dbc, -case_id => $case_id );
            print $usecase->view( -dbc => $dbc, -admin_view => 1 );
        }
    }
    elsif ($case_id) {
        my $usecase = alDente::UseCase->new( -dbc => $dbc, -case_id => $case_id );
        print $usecase->view( -dbc => $dbc, -admin_view => 1 );
    }
}

#########################
#
# Display the homepage
#
# Return: 1 on success
###########################
sub view {
    #########################

    if ($debug) {
        print "--> UseCase::view()<BR>";
    }

    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $tree        = $args{-tree};
    my $case_id     = $args{-use_case_id} || $self->{id};
    my $admin_view  = $args{-admin_view};
    my $rootusecase = $args{-rootusecase};                  # (Scalar) Indicates that this is the root of the UseCase tree - displays the add, delete, and use case home buttons

    # if the rootusecase flag is not defined, assume that it is the root of the tree
    unless ( defined $rootusecase ) {
        $rootusecase = 1;
    }

    my $tables = 'UseCase_Step';

    #my @cases = $dbc->Table_find( 'UseCase','UseCase_ID,UseCase_Name,UseCase_Description,UseCase_Created,UseCase_Modified');

    my %details = $dbc->Table_retrieve( 'UseCase', [ 'UseCase_Name as name', 'FKParent_UseCase__ID as parent', 'UseCase_Description as description', 'UseCase_Created', 'UseCase_Modified' ], "WHERE UseCase_ID = $case_id" );

    unless ( defined $details{name}[0] ) {
        Message("Use case $case_id not found");
        return;
    }
    my $name        = $details{name}[0];
    my $description = $details{description}[0];
    my $created     = $details{UseCase_Created}[0];
    my $modified    = $details{UseCase_Created}[0];
    my $parent      = $details{parent}[0];

    my $output;
    $output .= alDente::Form::start_alDente_form( $dbc, 'UseCase', -type => 'start' );

    if ( $parent && !$tree ) {
        $output .= Link_To( $dbc->config('homelink'), "<- (parent Use Case)", "&HomePage=UseCase&ID=$parent" ) . vspace(2);
    }

    # get all usecase steps that belong to the requested usecase
    my %case_steps = $dbc->Table_retrieve( $tables, [ 'UseCase_Step_ID', 'UseCase_Step_Title', 'UseCase_Step_Description', 'UseCase_Step_Comments', 'UseCase_Step_Branch', 'FKParent_UseCase_Step__ID' ], "WHERE FK_UseCase__ID=$case_id" );

    unless ( defined $case_steps{UseCase_Step_ID}[0] ) {
        Message("No steps found for use case $case_id");
    }
    my @step_id = @{ $case_steps{UseCase_Step_ID} };

    my @step_title  = @{ $case_steps{UseCase_Step_Title} }        if $case_steps{UseCase_Step_Title};
    my @step_desc   = @{ $case_steps{UseCase_Step_Description} }  if $case_steps{UseCase_Step_Description};
    my @step_cmnt   = @{ $case_steps{UseCase_Step_Comments} }     if $case_steps{UseCase_Step_Comments};
    my @branch_step = @{ $case_steps{UseCase_Step_Branch} }       if $case_steps{UseCase_Step_Branch};
    my @step_parent = @{ $case_steps{FKParent_UseCase_Step__ID} } if $case_steps{FKParent_UseCase_Step__ID};

    # get a list of all steps that have child steps (for the requested usecase)
    my @parent_ids = $dbc->Table_find( $tables, 'FKParent_UseCase_Step__ID' );

    my $case_edit_link = &Link_To( $dbc->config('homelink'), "Edit", "&Search=1&Table=UseCase&Search+List=" . $case_id, $Settings{LINK_LIGHT} );
    my $case_title = $description;
    $case_title .= $case_edit_link if $admin_view;
    my %Rows;
    my $case_table = HTML_Table->new( -width => 800, -title => "<B><span class=large>$case_title</span></B>" );
    $case_table->Set_Border(1);
    ## indicate Creation / Modification dates ##
    # $case_table->Set_sub_header("Created: $created",'white') if $created;
    # $case_table->Set_sub_header("Last Modified: $modified",'white') if $modified;

    for ( my $i = 0; $i < scalar(@step_id); $i++ ) {
        my $edit_link   = &Link_To( $dbc->config('homelink'), "Edit", "&Search=1&Table=UseCase_Step&Search+List=$step_id[$i]", $Settings{LINK_COLOUR} );
        my $add_link    = '';
        my $del_link    = '';
        my $branch_link = '';

        ##if a step already has a child step user can only add a branch
        if ( !( grep /$step_id[$i]/, @parent_ids ) && !$branch_step[$i] ) {
            $add_link = &Link_To( $dbc->config('homelink'), "Add Step", "&Add+UseCase+Step=$step_id[$i]&UseCase+ID=$case_id", $Settings{LINK_COLOUR} );
        }

        # user can't delete branches
        if ( !$branch_step[$i] && $step_parent[$i] ) {
            $del_link = &Link_To( $dbc->config('homelink'), "Delete", "&Delete+UseCase+Step=$step_id[$i]", $Settings{LINK_EXECUTE} );
        }

        $branch_link = &Link_To( $dbc->config('homelink'), "Add Branch", "&Add+Branch+Step=$step_id[$i]&UseCase+ID=$case_id", $Settings{LINK_COLOUR} );
        my @view_step = ( $step_title[$i], $step_desc[$i], $step_cmnt[$i] );
        push( @view_step, $add_link, $branch_link, $edit_link, $del_link ) if $admin_view;
        push( @{ $Rows{ $step_id[$i] }{details} }, \@view_step );

        $Rows{ $step_id[$i] }{branch} = $branch_step[$i];
    }

    foreach my $row ( sort { $a <=> $b } keys %Rows ) {

        if ( $Rows{$row}->{branch} ) {

            $case_table->Set_Row( @{ $Rows{$row}->{details} }, "lightbluebw" );
            next unless $row;

            #my @children = $dbc->Table_find('UseCase_Step,UseCase','distinct UseCase_Step.FK_UseCase__ID',"WHERE FK_UseCase__ID=UseCase_ID AND FK_UseCase_Step__ID=$row");

            my @children = $dbc->Table_find( 'UseCase', 'distinct UseCase_ID', "WHERE FK_UseCase_Step__ID=$row" );

            foreach my $child (@children) {
                next unless $child;
                $case_table->Set_sub_header( $self->view( -use_case_id => $child, -tree => 1, -admin_view => $admin_view, -rootusecase => 0 ), 'white' );
            }
        }
        else {
            $case_table->Set_Row( @{ $Rows{$row}->{details} } );
        }
    }
    ## Options for bottom of the page ##
    my $options = &vspace(10);
    if ($admin_view) {
        if ($rootusecase) {
            $options .= submit( -name => "Add UseCase",    -value => 'Add New Use Case', -class => "Std" ) . "\t";
            $options .= submit( -name => "Delete UseCase", -value => 'Delete Use Case',  -class => "Action" ) . "\t";
        }
        if ( scalar(@step_id) == 0 ) {
            $options .= submit( -name => "Add UseCase Step", -value => 'Add Step', -class => "Std" ) . "\t";
            $options .= hidden( -name => "First Step", -value => 1 );
        }
        if ($rootusecase) {
            $options .= submit( -name => "UseCase Home", -value => 'Use Case Home', -class => "Std" );
        }
    }

    $options .= hidden( -name => "UseCase ID", -value => $case_id );

    $options .= end_form();

    #$options .= hr;

    if ($tree) {    ## put expandable folder in place of details..

        $output .= hspace(20) . create_tree( -tree => { $name => $case_table->Printout(0) . $options } );
    }
    else {
        $output .= "<h2>$name</h2>" . $case_table->Printout(0) . $options;
    }
    unless ($parent) {
        print $case_table->Printout( "$URL_temp_dir/usecase$case_id.html", "$java_header\n$html_header" );
    }
    return $output;
}

return 1;
