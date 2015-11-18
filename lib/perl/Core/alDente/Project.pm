# Project.pm
#
# Class module that encapsulates a DB_Object that represents a single Project
#
# $Id: Project.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $
###################################################################################################################################
package alDente::Project;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Project.pm - Class module that encapsulates a DB_Object that represents a single Project

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Class module that encapsulates a DB_Object that represents a single Project<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw(get_project_stats);
@EXPORT_OK = qw(get_project_stats);

##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use SDB::DB_Object;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use RGTools::HTML_Table;
use RGTools::RGIO;
use alDente::Validation;

use alDente::Project_Views;
use alDente::Run_Statistics;
use Sequencing::SDB_Status;
use strict;

##############################
# global_vars                #
##############################

use vars qw(%Benchmark %Configs);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Local constants
my $PROJECT_ID_FIELD        = "Project.Project_ID";
my $PROJECT_NAME_FIELD      = "Project.Project_Name";
my $PROJECT_DESC_FIELD      = "Project.Project_Description";
my $PROJECT_INIT_DATE_FIELD = "Project.Project_Initiated";
my $PROJECT_END_DATE_FIELD  = "Project.Project_Completed";
my $PROJECT_STATUS_FIELD    = "Project.Project_Status";

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a project ID and constructs a project object
# RETURN: Reference to a Project object
############################################################
sub new {
########
    my $this = shift;
    my %args = @_;

    my $dbc        = $args{-dbc}        || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $project_id = $args{-project_id} || $args{-id};                                                        # Project ID of the project
    my $frozen     = $args{-frozen}     || 0;                                                                 # flag to determine if the object was frozen
    my $encoded = $args{-encoded};                                                                            # flag to determine if the frozen object was encoded
    my $class = ref($this) || $this;

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    else {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Project" );
        bless $self, $class;
        if ($project_id) {
            $self->primary_value( 'Project', $project_id );

            #acquire all information necessary for Projects
            $self->load_Object();
        }
    }
    $self->{dbc} = $dbc;
    $self->{id}  = $project_id;

    return $self;
}

##############################
# public_methods             #
##############################
###########################
sub get_Published_files {
###########################
    my %args     = &filter_input( \@_, -self => 'alDente::Project' );
    my $self     = $args{-self};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $id       = $args{-id} || $self->{id};                           ## if passing in id anyways, method should be available as function
    my $proj_Dir = $Configs{project_dir};
    my @files;

    require RGTools::Directory;
    my ($project_path) = $dbc->Table_find( 'Project', 'Project_Path', "WHERE Project_ID = $id" );
    unless ($project_path) {
        Message "Invalid project_id $id";
    }

    ## FIND Project Published
    my $pattern = $proj_Dir . '/' . $project_path . '/published/*';
    my @p_files = Directory::find_Files( -pattern => $pattern );
    @p_files = sort(@p_files);

    ## FIND Library Published
    $pattern = $proj_Dir . '/' . $project_path . '/*/published/*';
    my @l_files = Directory::find_Files( -pattern => $pattern );
    @l_files = sort(@l_files);

    push @files, @p_files;
    push @files, @l_files;

    return \@files;
}

###########################
sub new_Project_trigger {
###########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};

    ## update sessions list of active project IDs ##
    if ($id) { $dbc->config( 'visible_Projects', $dbc->config('visible_Projects') . ",$id" ) }

    return;
}

##############
sub home_info {
##############
    my $self = shift;

    print alDente::Project_Views::home_info($self);

}

###########################
sub list_funding_sources {
###########################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'field' );
    my $field = $args{-field} || 'Funding_ID';
    my $link  = $args{ -link };

    my $dbc = $self->{'dbc'};
    my $id  = $self->{id};

    #    Message("id=$id");
    my @funding = $dbc->Table_find( 'Funding,Library,Work_Request', $field, "WHERE Work_Request.FK_Funding__ID=Funding_ID AND FK_Library__Name=Library_Name and FK_Project__ID IN ($id) ", -distinct => 1 );

    if ($link) {
        my @linked = map { alDente::Tools::alDente_ref( 'Funding', $_, -dbc => $dbc ) } @funding;
        @funding = @linked;
    }

    return @funding;
}

########################
#
# Set Project Status automatically if all libraries have goals which are completed.
#
#
#
#
########################
sub set_Project_status {
########################
    my %args        = filter_input( \@_, -mandatory => 'dbc,library|project_id' );
    my $dbc         = $args{-dbc};
    my $library     = $args{-library};
    my $project_ids = $args{-project_id};
    my $debug       = $args{-debug};

    my $project_list;
    if ($library) {
        ($project_list) = $dbc->Table_find( 'Library', 'FK_Project__ID', "WHERE Library_Name = '$library'" );
    }
    else {
        $project_list = Cast_List( -list => $project_ids, -to => 'string' );
    }

    Message("setting project status if required for $project_list") if $debug;
    my $total_changed = 0;
    foreach my $project ( split ',', $project_list ) {
        my @libs = $dbc->Table_find( 'Library', 'Library_Name,Library_Status', "WHERE FK_Project__ID = $project", -distinct );
        my $complete = 0;
        foreach my $lib_status (@libs) {
            my ( $lib, $status ) = split ',', $lib_status;
            if ($debug) { Message("$lib $lib_status") }
            if ( $lib_status =~ /(Complete|Cancelled)/ ) {
                $complete++;
            }
            else {
                ## at least one library incomplete ##
                $complete = -1;
                last;
            }
        }
        my ($today) = split ' ', &date_time;

        my ($project_name) = $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_ID = $project" );
        if ( $complete < 0 ) {
            my $changed = $dbc->Table_update_array( 'Project', [ 'Project_Status', 'Project_Completed' ], [ 'Active', '0000-00-00' ], "WHERE Project_ID=$project AND Project_Status = 'Completed'", -autoquote => 1 );
            if ($changed) { Message("** NOTE ** Project $project ($project_name) Re-opened - completed"); $total_changed++; }

            if ( my $active_ids = $dbc->config('visible_Projects') ) {
                ## reset session tracking of active Project IDs ##
                $active_ids .= ",$project";
                $dbc->config( 'visible_Projects', $active_ids );
            }
        }
        elsif ( $complete > 0 ) {
            my $changed = $dbc->Table_update_array( 'Project', [ 'Project_Status', 'Project_Completed' ], [ 'Completed', $today ], "WHERE Project_ID=$project AND Project_Status != 'Completed'", -autoquote => 1 );
            if ($changed) { Message("** NOTE ** Project $project ($project_name) marked as completed ($today) - completed"); $total_changed++; }
            if ( my $active_ids = $dbc->config('visible_Projects') ) {
                ## reset session tracking of active Project IDs ##
                $active_ids =~ s/\b$project\b//;
                $active_ids =~ s/,,/,/g;
                $dbc->config( 'visible_Projects', $active_ids );
            }
        }
        else {
            if ($debug) { Message("Project $project ($project_name) unchanged") }
        }
    }

    return $total_changed;
}

########################
#
# Generate list of projects with links to main project pages.
#
#
######################
sub list_projects {
######################
    my %args = &filter_input( \@_, -args => 'dbc,condition' );

    return alDente::Project_Views::list_projects(%args);
}

############################################################
# Function: Returns project information in a hash reference (fieldname=>info)
# RETURN: Reference to a hash containing project information
############################################################
sub get_project_info {
    my $self = shift;
    my %proj_info;
    foreach my $field ( @{ $self->fields() } ) {
        $proj_info{$field} = $self->value($field);
    }
    return \%proj_info;
}

############################################################
# Subroutine: Uses a Run_Statistics object to print the statistics for an entire project
# RETURN: HTML
############################################################
sub get_project_stats {
    my $self = shift;

    print alDente::Project_Views::show_project_stats($self);
}

####################
sub get_projects {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->dbc;

    my %layers = (
        "Unassociated Projects" => &alDente::Project::list_projects( $dbc, "Library_Name IS NULL", -no_filter => 1 ),
        "Nonfunded Projects"    => &alDente::Project::list_projects( $dbc, "Funding_ID IS NULL",   -no_filter => 1 ),
    );

    my @depts = $dbc->Table_find( "Department,Grp,Library", "Department_Name", "Where FK_Department__ID = Department_ID and Grp_ID = FK_Grp__ID group by Department_Name" );

    my @order;
    foreach my $dept (@depts) {
        my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('$dept')" );

        $layers{"$dept Projects"} = alDente::Project::list_projects( $dbc, "Library_Name IN ('$libs')" );
        push @order, "$dept Projects";

    }
    push @order, ( 'Unassociated', 'Nonfunded' );

    return \%layers, \@order;
}

1;

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Project.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $ (Release: $Name:  $)

=cut
