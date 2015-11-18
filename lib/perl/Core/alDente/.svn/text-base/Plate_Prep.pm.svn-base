##################
# Plate_Prep.pm #
##################
#
# This module is used to handle Plate_preparation tracking of Plates/Tubes etc.
# It provides for:
#
# - loading of preparation steps completed on plates
# - displaying schedule of preps completed
#
package alDente::Plate_Prep;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Plate_Prep.pm - This module is used to handle Plate_preparation tracking of Plates/Tubes etc.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle Plate_preparation tracking of Plates/Tubes etc.<BR>It provides for:<BR>- loading of preparation steps completed on plates <BR>- displaying schedule of preps completed<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##
use CGI qw(:standard);
use DBI;
use Benchmark;

#use Storable qw(freeze thaw);
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;
use SDB::CustomSettings qw(%Settings %Std_Parameters $Connection $testing %Benchmark $Sess %Prefix);
use alDente::SDB_Defaults;
use alDente::Form;

use Benchmark;
##############################
# global_vars                #
##############################
use vars qw($current_plates $testing %Std_Parameters $Connection %Benchmark $Sess);
## current plates stores current plate_ids (change to extract via %Input hash)
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
## Constants ##
my $TABLE               = "Plate_Prep";
my $PLATE_TABLE         = "Plate";
my $PREP_TABLE          = "Prep";
my $PROTOCOL_TABLE      = "Lab_Protocol";
my $LIBRARY_FIELD       = "Plate.FK_Library__Name";
my $PLATE_NUMBER_FIELD  = "Plate.Plate_Number";
my $PROTOCOL_NAME_FIELD = "Lab_Protocol.Lab_Protocol_Name";
my $PROTOCOL_ID_FIELD   = "Lab_Protocol.Lab_Protocol_ID";
my $PREP_NAME_FIELD     = "Prep.Prep_Name";
my $PREP_DATEFIELD      = "Prep.Prep_DateTime";

#my $FK_PROTOCOL_FIELD   = "FK_Lab_Protocol__ID";
my $PREP_ID_FIELD  = "Prep_ID";
my $PLATE_NAME     = "CONCAT($LIBRARY_FIELD,'-',$PLATE_NUMBER_FIELD)";
my $DEFAULT_TYPE   = "Library_Plate";
my @RELATED_TABLES = ( $PLATE_TABLE, $PREP_TABLE, $PROTOCOL_TABLE );

##############################
# constructor                #
##############################

##########
sub new {
##########
    #
    # constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $protocol = $args{-protocol};                                                                 ## name / id of protocol to load
    my $type     = $args{-type} || $DEFAULT_TYPE;                                                    ## type of Plate (
    my $plates   = $args{-plates} || '';                                                             ## plates to be loaded
    my $set      = $args{-set} || 0;                                                                 ## plate set to be loaded
    my $id       = $args{-id};

    my ($class) = ref($this) || $this;
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $TABLE, %args );

    if ( $args{-encoded} || $args{-frozen} ) {
        return $self;
    }

    bless $self, $class;

    $self->{Plate_Prep_ID} = $id;
    $self->{dbc}           = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

########################
sub get_Prep_history {
########################
    #
    # Extract table showing Prep History
    #
    # (shows list of Protocols done if no Protocol specified)
    # (shows list of steps within protocol done if protocol specified)
    #
    my $self = shift;
    my %args = @_;

    #    my $library         = $args{-library};
    #    my $numbers         = $args{-plate_numbers};
    my $plate_ids = $args{-plate_ids};

    #    my $plate_number    = $args{-plate_number};
    #    my $status          = $args{-status};
    #    my $project         = $args{-project};
    my $condition = $args{-condition} || 1;
    my $sets      = $args{-sets}      || 0;
    my $protocol_id  = $args{-protocol_id};
    my $pipeline_id  = $args{-pipeline_id};
    my $group        = $args{-group};
    my $view         = $args{-view} || 0;
    my $standard     = $args{-include_standards} || 0;                                                                  ## include standard tracked steps (throw away, store .. etc)
    my $split        = $args{-split_quad};                                                                              ## split the protocol history per quadrant
    my $include_fail = $args{-include_fail} || 0;
    my $dbc          = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $group_list   = $args{-group_list};
    my $wait         = $args{ -wait } || param('Wait');                                                                 ## (holds off on query (to allow user to set filter options))
    my $no_filter    = $args{-no_filter};                                                                               ## exclude automated filtering (parse_plate_filter)
    my $page;

    unless ($group_list) {
        $group_list = $dbc->get_local('group_list');
    }

    my $addlink;
    if ( !$no_filter ) {
        my @filter_conditions = alDente::Container::parse_plate_filter($dbc);

        foreach my $cond (@filter_conditions) {
            if ($cond) { $condition .= " AND $cond" }
            if ( $cond =~ /\b(\w+) IN \((.*)\)/ ) {
                $addlink .= "&$1=$2";
            }
        }
    }

    ## reload with new condition if necessary ##
    $page .= "<BR>";

    #    my $number_list = extract_range($numbers) if $numbers;

    my $index = "$LIBRARY_FIELD,$PLATE_NUMBER_FIELD";    ## ordering
    my $key   = $PROTOCOL_NAME_FIELD;                    ## cell key (when searching all protocols)

    if ( $pipeline_id =~ /[a-zA-Z]/ ) { $pipeline_id = $dbc->get_FK_ID( 'FK_Pipeline__ID', $pipeline_id ) }    ## convert if name supplied ##
    my $pipeline_list = Cast_List( -list => $pipeline_id, -to => 'string' ) if ( $pipeline_id =~ /[1-9]/ );

    if ( $protocol_id || 0 ) {

        #        $condition .= " AND Prep.FK_Lab_Protocol__ID in ($protocol_id)";
        $key = $PREP_NAME_FIELD;                                                                               ## cell key when looking at a spec. protocol
        $group ||= $PREP_ID_FIELD;
    }
    else {
        $group ||= $PROTOCOL_NAME_FIELD;
    }

    $dbc->Benchmark('Prep_history');

    if ($plate_ids) {
        my $parents = alDente::Container::get_Parents( -dbc => $self->{dbc}, -id => $plate_ids, -format => 'list', -simple => 1 );
        $condition .= " AND (Plate_Prep.FK_Plate__ID in ($parents)";
        $dbc->Benchmark('got_parents');
        if ($sets) {
            $condition .= "OR Plate_Prep.FK_Plate_Set__Number in ($sets)";
        }
        $condition .= ")";
    }
    elsif ($sets) {
        my $parent_sets = alDente::Container_Set::get_parent_sets( -sets => $sets, -recursive => 10, -format => 'list' );
        $condition .= " AND (Plate_Prep.FK_Plate_Set__Number in ($parent_sets))";

    }
    elsif ($condition) {
        ## ok ##
    }
    else {
        Message("You must specify a list of plate_ids, library, protocol, or pipeline");
        return;
    }

    $page .= create_tree( -tree => { "Condition" => $condition } );

    $group = "$index,$group";
    my @group_by = split ',', $group;

    $self->add_tables('Plate');
    $self->add_tables('Library');
    $self->add_tables('Prep');
    $self->no_joins('Prep,Plate');    ## do not auto-join since last_Prep should NOT be auto-joined.

    $self->add_tables('Lab_Protocol');
    $self->left_join( 'Object_Class',  -condition => "Object_Class='Lab_Protocol'" );
    $self->left_join( 'Pipeline_Step', -condition => "FK_Object_Class__ID=Object_Class_ID AND Object_ID=Lab_Protocol_ID" );
    $self->left_join( 'Pipeline',      -condition => 'Pipeline_Step.FK_Pipeline__ID=Pipeline_ID' );

    unless ( $condition =~ /FK_Library__Name IN /i ) {
        if ( $group_list =~ /[1-9]/ ) {
            $self->add_tables( 'GrpLab_Protocol', -condition => "GrpLab_Protocol.FK_Lab_Protocol__ID=Lab_Protocol_ID" );
            $condition .= " AND GrpLab_Protocol.FK_Grp__ID in ($group_list)";
        }
    }

    unless ($standard) {    ## Exclude Standard protocol steps unless specifically requested... ##
        my ($standard_protocols) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name = 'Standard'" );
        $condition .= " AND Prep.FK_Lab_Protocol__ID != $standard_protocols";
    }

    my $found = $self->load_Object( -multiple => 1, -condition => $condition, -order_by => 'Pipeline_Step_Order,Prep_DateTime', ) unless $wait;
    $dbc->Benchmark('history_loaded');

    unless ( $found || $wait ) {
        Message("No Data found. (Condition: $condition)");

        #Message("No Data found for $library Library plates $plate_ids");
        return;
    }
    if ($view) {
        ## regenerate Plate_Filter with 'Protocol Summary' button ##
        #my %Parameters = Set_Parameters();

        my $form = alDente::Form::start_alDente_form( $dbc, 'protocol_summary' )
            . &alDente::Container::plate_filter(
            -dbc     => $dbc,
            -filter  => 'Pipeline,Library,Status,Project,Plate_Number,Plate_Created',
            -form    => 'protocol_summary',
            -buttons => [ submit( -name => 'Protocol Summary', -value => 'Regenerate Protocol Summary', -class => 'Search' ) ]
            ) . end_form();

        #	print $form;
        $page .= create_tree( -tree => { "Additional Filtering" => $form } );

        ## Display results ##
        ## (arguments should enable all filtered elements (above) to be passed to view_History so that the filtering is consistent through the links) ##
        #	$status_options=~s/\'//g;   ## remove quotes from status options to pass to link...

        if ($wait) {
            Message("Set Filtering Criteria to Generate Protocol Summary");
        }
        else {
            $page .= $self->view_History(
                -plate_ids   => $plate_ids,
                -add_to_link => $addlink,
                -protocol_id => $protocol_id,
                -group_list  => $group_list,
            );
        }
    }

    return $page;
}

###################
sub view_History {
###################
    my $self          = shift;
    my %args          = @_;
    my $addtolink     = $args{-add_to_link};
    my $pipeline_id   = $args{-pipeline_id};
    my $protocol_id   = $args{-protocol_id} || 0;
    my $plate_ids     = $args{-plate_ids} || 0;
    my $library       = $args{-library};
    my $plate_numbers = $args{-plate_numbers};
    my $status        = $args{-status};
    my $split_quad    = $args{-split_quad};
    my $group_list    = $args{-group_list};
    my $dbc           = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $split_overwritten;    ### This variable is set when split quadrant has been overwritten
    my $page;
    ## If only one plate is being scanned, automatically split quadrants
    if ( $plate_ids !~ /,/ ) {
        $split_overwritten = 1;
        $split_quad        = 1;
    }

    ## Display if a specific protocol is chosen.. ##
    my $Table = HTML_Table->new( -size => 'small' );
    my @get_fields = (
        $LIBRARY_FIELD,                    $PROTOCOL_NAME_FIELD, $PROTOCOL_ID_FIELD, $PREP_NAME_FIELD,       $PREP_DATEFIELD,              'Plate.Plate_Number',
        'Prep.Prep_ID',                    'FK_Plate__ID',       'Plate.Plate_ID',   'Prep.FK_Employee__ID', 'Plate_Prep.FK_Solution__ID', 'Plate_Prep.FK_Equipment__ID',
        'Plate_Prep.FK_Plate_Set__Number', 'Plate.FK_Pipeline__ID'
    );

    if ($protocol_id) {
        push @get_fields, 'Plate.FK_Branch__Code';
    }

    if ($split_quad) {
        push @get_fields, "Plate.Parent_Quadrant";
    }

    my $records         = $self->record_count();
    my $protocol_name   = $self->value($PROTOCOL_NAME_FIELD);
    my $lab_protocol_id = $self->value($PROTOCOL_ID_FIELD);

    my @sample_groups;
    my @headings;
    my @protocol_list;
    my @pipeline_list;
    my %Display;
    my %Heading;
    my $index = 0;
    my %order_hash;
    my @added_columns = ();
    my @added_preps   = ();

    $dbc->Benchmark('start_loop');
    my %plate_prep_seen;

    foreach my $index ( 0 .. $records - 1 ) {
        my %History   = %{ $self->values( -fields => \@get_fields, -index => $index ) };
        my $row       = $History{$LIBRARY_FIELD} . '-' . $History{'Plate.Plate_Number'} . $History{'Plate.Parent_Quadrant'} . '.' . $History{'Plate.FK_Branch__Code'};
        my $prep      = $History{$PREP_NAME_FIELD};
        my $prep_id   = $History{'Prep.Prep_ID'};
        my $plate_id  = $History{'Plate.Plate_ID'};
        my $prep_date = substr( $History{$PREP_DATEFIELD}, 0, 11 );
        my $emp       = $History{'Prep.FK_Employee__ID'};
        my ($init) = $dbc->Table_find( "Employee", "Employee_Name", "WHERE Employee_ID = $emp" );
        my $set      = $History{'Plate_Prep.FK_Plate_Set__Number'};
        my $pipeline = $History{'Pipeline.Pipeline_Name'};
        my $branch   = $History{'Plate.FK_Branch__Code'};
        $protocol_name   = $History{$PROTOCOL_NAME_FIELD};
        $lab_protocol_id = $History{$PROTOCOL_ID_FIELD};
        $pipeline_id     = $History{'Plate.FK_Pipeline__ID'};

        if ( $plate_prep_seen{$plate_id}{$prep_id} ) {next}
        $plate_prep_seen{$plate_id}{$prep_id} = 1;

        unless ( grep /^$lab_protocol_id$/, @added_columns ) {

            my $protocol = &Link_To( $dbc->config('homelink'), $protocol_name, "cgi_application=alDente::Protocol_App&rm=View+Protocol&Protocol=$lab_protocol_id$addtolink", -tooltip => 'view steps in this protocol' );
            push @added_columns, $lab_protocol_id;
            push @headings,      $protocol;
            push @added_preps,   $prep_id;
            $order_hash{$lab_protocol_id} = $protocol;
        }    ## add protocol to list of headings..
        ## sort @added_column and @heading by Prep_DateTime (chronologically)
        if ( scalar @added_columns > 0 ) {
            my $added_preps_string = join( ",", @added_preps );
            my @ordered_added_columns = $dbc->Table_find( 'Prep', 'FK_Lab_Protocol__ID', "WHERE Prep_ID IN ($added_preps_string)" . " ORDER BY UNIX_TIMESTAMP(Prep_DateTime)", -distinct => 1 );
            my @ordered_headings;
            foreach my $item (@ordered_added_columns) {
                push @ordered_headings, $order_hash{$item};
            }

            @added_columns = @ordered_added_columns;
            @headings      = @ordered_headings;
        }

        my @keys = keys %History;

        unless ( grep /^$row$/, @sample_groups ) {
            push @sample_groups, $row;
        }

        my $column;
        if ($protocol_id) {
            $column = $prep;
            if    ( $prep =~ /^Skipped (.*)/ ) { $column = $1; }
            elsif ( $prep =~ /^Failed (.*)/ )  { $column = $1; }
            my $solution_used;
            my $equipment_used;
            if ( $History{'Plate_Prep.FK_Solution__ID'} =~ /[1-9]/ ) {
                $solution_used = get_FK_info( $self->{dbc}, 'FK_Solution__ID', $History{'Plate_Prep.FK_Solution__ID'} ) . '<br>';
                $solution_used =~ s/\s/_/g;
                $solution_used = $Prefix{Plate} . "$plate_id " . $solution_used;
            }

            if ( $History{'Plate_Prep.FK_Equipment__ID'} =~ /[1-9]/ ) {
                $equipment_used = get_FK_info( $self->{dbc}, 'FK_Equipment__ID', $History{'Plate_Prep.FK_Equipment__ID'} ) . '<br>';
                $equipment_used =~ s/-/_/g;
                $equipment_used =~ s/\s//g;
                $equipment_used = $Prefix{Plate} . "$plate_id " . $equipment_used;
            }

            $Display{$row}->{$column}->{solutions} .= $solution_used  unless $Display{$row}->{$column}->{solutions} =~ /$solution_used/;
            $Display{$row}->{$column}->{equipment} .= $equipment_used unless $Display{$row}->{$column}->{equipment} =~ /$equipment_used/;
        }
        else {
            $column = $lab_protocol_id;
            $Heading{$protocol_name}++;
        }

        $Display{$row}->{$column}->{found}++;
        $Display{$row}->{$column}->{title} = $column;
        $Display{$row}->{$column}->{date} .= "$prep_date $init " if $Display{$row}->{$column}->{date} !~ /$prep_date $init/;
        $Display{$row}->{$column}->{user}        = $init;
        $Display{$row}->{$column}->{protocol_id} = $lab_protocol_id;
        $Display{$row}->{$column}->{set}         = $set;
        $Display{$row}->{$column}->{pipeline}    = $pipeline;
        $Display{$row}->{$column}->{branch}      = $branch;

        push @{ $Display{$row}->{$column}->{prep_ids} }, $prep_id;
        push( @protocol_list, $lab_protocol_id ) unless grep /^$lab_protocol_id$/, @protocol_list;
        push( @pipeline_list, $pipeline_id )     unless grep /^$pipeline_id$/,     @pipeline_list;
        $index++;
    }

    $page .= "<br><font size=2 color=black>Info displayed in the following format: </font>" . " <font color=blue size=2><i>date Month-DD-YYYY (user:number of prep records found for this sample)</i></font>" . &vspace();

    my %hash = %{ RGTools::RGWeb::get_parameters() };
    $hash{Split_Quadrants} = !$hash{Split_Quadrants};
    my $split_name = $split_quad ? 'Suppress Quadrants' : 'Split Quadrants';

    $page .= &Link_To( $dbc->config('homelink'), $split_name, '&' . join( '&', map {"$_=$hash{$_}"} keys %hash ), $Settings{LINK_COLOUR} ) . lbr . lbr unless ($split_overwritten);

    my %Pipeline;
    if ($protocol_id) {
        ## reset headings to list of protocol steps..
        @headings = $dbc->Table_find( 'Protocol_Step', 'Protocol_Step_Name', "where Protocol_Step.FK_Lab_Protocol__ID=$protocol_id" . " AND Scanner>0" . " ORDER BY Protocol_Step_Number" );
        $Table->Set_Title($protocol_name);
        @added_columns = @headings;
    }
    else {
        my $cs_list   = join ',', @protocol_list;
        my $pipelines = join ',', @pipeline_list;
        my @pipelines = $dbc->Table_find(
            'Pipeline,Pipeline_Step,Object_Class,Lab_Protocol,GrpLab_Protocol',
            'Pipeline_Name,Lab_Protocol_ID',
            "WHERE Pipeline_Step.FK_Pipeline__ID=Pipeline_ID"
                . " AND Lab_Protocol_ID=Object_ID"
                . " AND Object_Class='Lab_Protocol'"
                . " AND FK_Object_Class__ID=Object_Class_ID"
                . " AND Lab_Protocol_ID in ($cs_list)"
                . " AND Pipeline_ID in ($pipelines)"
                . " AND GrpLab_Protocol.FK_Lab_Protocol__ID=Lab_Protocol_ID"
                . " and GrpLab_Protocol.FK_Grp__ID in ($group_list)"
                . " order by Pipeline_ID, Pipeline_Step_Order",
            -distinct => 1
        );

        foreach my $details (@pipelines) {
            my ( $pipeline, $prot_id ) = split ',', $details;
            $Pipeline{$prot_id} .= "$pipeline, ";
        }

        $Table->Set_Title("$library Protocols Initiated");
    }

    my @new_headings = @headings;
    map {
        my $header = $_;
        my $prot_id;

        if ( $header =~ /Protocol_ID=(\d+)/ ) {
            $prot_id = $1;
        }

        if ( defined( $Pipeline{$prot_id} ) ) {
            $Pipeline{$prot_id} =~ s/, $/<BR>/;
            $_ = "Pipeline: <Font color=white>$Pipeline{$prot_id}</Font>Protocol: $header";
        }
        else {
            $_ = "Protocol: $header";
        }
    } @new_headings;

    my $main_header = "Sample: <BR>lib-plate(quad)";
    $main_header .= ".branch" if $protocol_id;

    $Table->Set_Headers( [ $main_header, @new_headings ] );
    $Table->Set_Border(1);

    unless (@sample_groups) {
        $Table->Set_Row( ['no data found'] );
    }

    foreach my $plate_number (@sample_groups) {
        my @pla_ids = ( split ',', $plate_ids );

        #  foreach my $pla_id (@pla_ids){
        my $main_link = $plate_number;
        my $plate_num = $plate_number;
        my $lib       = $library;
        if ( $plate_number =~ /(.{5,6})\-(\d+)/ ) {
            $lib       = $1;
            $plate_num = $2;

            #my ($quad) = $dbc->Table_find('Plate','Parent_Quadrant',"where Plate_ID in ($plate_ids)");
            $main_link = &Link_To( $dbc->config('homelink'), "<B>$plate_number</B>", "&Info=1&Table=Plate&Field=FK_Library__Name&Like=$lib&Condition=Plate_Number+IN+($plate_num)", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'Get Sample info' );
        }

        my @row_values = ($main_link);

        foreach my $heading (@added_columns) {
            my %cell;
            if ( defined $Display{$plate_number}->{$heading} ) {
                %cell = %{ $Display{$plate_number}->{$heading} };
            }
            else {
                push( @row_values, "-" );
                next;
            }
            my $title  = $cell{title};
            my $found  = $cell{found};
            my $date   = $cell{date};
            my $user   = $cell{user};
            my $sample = $plate_number;
            my $link   = '';

            if ($protocol_id) {
                my $preps = join ',', @{ $Display{$plate_number}->{$heading}->{prep_ids} };
                $link = '';
                my $set = $Display{$plate_number}->{$heading}->{set};

                if ( $Display{$plate_number}->{$heading}->{solutions} ) {
                    $link .= $Display{$plate_number}->{$heading}->{solutions};
                }

                if ( $Display{$plate_number}->{$heading}->{equipment} ) {
                    $link .= $Display{$plate_number}->{$heading}->{equipment};
                }

                my $plates = join '<BR>', $dbc->Table_find( 'Plate_Prep', 'FK_Plate__ID', "WHERE FK_Prep__ID in ($preps)", 'Distinct' );

                $link .= &Link_To( $dbc->config('homelink'), "$date ($found)", "&HomePage=Prep&ID=$preps", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => "$heading IDs:<BR>Set $set<BR>**********<BR>$plates" );
            }
            else {
                my $lab_protocol_id = $Display{$plate_number}->{$heading}->{protocol_id};
                my $addtolink;

                if ($plate_num) { $addtolink .= "&Plate+Numbers=$plate_num"; }

                #                if ($current_plates) { $addtolink .= "&Plate IDs=$current_plates"; }
                if    ($plate_ids) { $addtolink .= "&Plate IDs=$plate_ids"; }
                elsif ($lib)       { $addtolink .= "&Library_Name=$lib"; }

                #$link = &Link_To( $dbc->config('homelink'), "$date ($found) $user", "$addtolink&Protocol Summary=1&Protocol_ID=$lab_protocol_id", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'view steps in protocol for these plates' );
                $link = Link_To(
                    $dbc->config('homelink'),
                    "$date ($found)",
                    "&cgi_application=alDente::Container_App&rm=Protocol+Summary&Protocol_ID=$lab_protocol_id$addtolink",
                    $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'view steps in protocol for these plates'
                );

                if ( $plate_ids && $lib ) {
                    $addtolink =~ s/Plate IDs=$plate_ids/Library_Name=$lib/;
                    $link .= ' - '
                        . &Link_To(
                        $dbc->config('homelink'),
                        "(all)", "&cgi_application=alDente::Container_App&rm=Protocol+Summary&Protocol_ID=$lab_protocol_id$addtolink",
                        $Settings{LINK_COLOUR}, ['newwin'], -tooltip => 'view steps in protocol for these plates - include siblings'
                        );
                }
            }

            push @row_values, $link;
        }

        $Table->Set_Row( \@row_values );
    }

    $dbc->Benchmark('loop_complete');

    $page .= $Table->Printout(0);

    return $page;
}

# Show a table of grouped protocols
#
# Usage:
#  my @protocols = (
#
#                {'Overnights'        => ['BAC 384 Well Overnights','Overnight setup 384','overnight setup 96 TN','Overnight setup 96','overnight setup 384 TN']},
#                {'Preps'            => ['BAC 384 Well Prep','BAC 384 Well Spindowns','384-Well Prep','Full Mech Prep - Abgene','PCR purification 384 well']},
#                {'Reactions'         => ['Rxns_1/256_FRDBrew_400nl','Rxns_BD384_1/24_4uLrxn_2uLDNA','Rxns_BD384_5uLrxn_3uLDNA','Rxns_Dilute_Aliquot_1/256','Rxns_BD384_1/48_4uLrxn_2uLDNA']},
#                {'Precipitations'    => ['Pptn_BD384_1/256_400nl','Pptn_BD96/384_EtOH/EDTA']},
#               {'Resuspensions'     => ['Resuspension of Sequencing Reaction Prod']}
#                );
#  my $output = alDente::Plate_Prep::get_prep_summary_table(-protocol_info=>\@protocols,-library=>$library,-plate_number=>$plate_number,-dbc=>$self->{dbc});
#
#  Returns: HTML table
############################
sub get_prep_summary_table {
############################
    my %args          = filter_input( \@_, -args => 'library,plate_number,quadrant' );
    my $dbc           = $args{-dbc};
    my $library       = $args{-library};
    my $plate_number  = $args{-plate_number};
    my $quadrant      = $args{-quadrant};
    my $protocol_info = $args{-protocol_info};                                           ## arrayref

    my @protocol_info = @{$protocol_info};
    my $prep_summary_table = HTML_Table->new( -title => '' );
    my @headings;
    my @column_widths;
    foreach my $protocol_class (@protocol_info) {
        my @column;
        my %protocol_class = %{$protocol_class};
        my @classes        = keys %protocol_class;
        my $class_name     = $classes[0];
        push @headings, $class_name;
        my @protocols = @{ $protocol_class->{$class_name} };

        my $protocol_list = Cast_List( -list => \@protocols, -to => 'String', -autoquote => 1 );
        my %prep_history = $dbc->Table_retrieve(
            'Plate,Plate_Prep,Prep,Employee,Lab_Protocol',
            [ 'Plate_ID', 'Lab_Protocol_Name', 'Employee.Initials', 'Plate.FK_Branch__Code', 'Prep_DateTime' ],
            "WHERE Plate_ID = Plate_Prep.FK_Plate__ID and 
                                                Prep_ID = Plate_Prep.FK_Prep__ID and 
                                                Lab_Protocol_ID = Prep.FK_Lab_Protocol__ID and 
                                                FK_Library__Name = '$library' and Plate_Number IN ($plate_number) and 
                                                Prep.FK_Employee__ID = Employee_ID and 
                                                Lab_Protocol_Name <> 'Standard' and 
                                                Prep_Name = 'Completed Protocol' and Lab_Protocol_Name iN ($protocol_list) 
                                                group by FK_Lab_Protocol__ID,Plate_Number,Parent_Quadrant,FK_Branch__Code,Prep_DateTime  
                                                order by Prep_DateTime asc,Plate_ID desc", -key => 'Lab_Protocol_Name'
        );

        foreach my $protocol (@protocols) {
            my $row = 0;
            while ( $prep_history{$protocol}{'Plate_ID'}[$row] ) {
                my $employee  = $prep_history{$protocol}{'Initials'}[$row];
                my $prep_date = $prep_history{$protocol}{'Prep_DateTime'}[$row];
                my $plate_id  = $prep_history{$protocol}{'Plate_ID'}[$row];
                $prep_date = convert_date( $prep_date, 'YYYY-MM-DD' );
                my $branch_code = $prep_history{$protocol}{'FK_Branch__Code'}[$row];
                my $protocol_short = substr( $protocol, 0, 15 );
                $protocol_short = &Show_Tool_Tip( Link_To( $dbc->config('homelink'), $protocol_short, "&cgi_application=alDente::Container_App&rm=Plate+History&FK_Plate__ID=$plate_id", $Settings{LINK_COLOUR} ), "$protocol" );
                my $info = "$protocol_short" . lbr() . "$employee," . " $prep_date," . " $branch_code";

                push @column, $info;
                $row++;
            }
        }
        push( @column_widths, 200 );
        $prep_summary_table->Set_Column( \@column );
    }

    $prep_summary_table->Set_Column_Widths( \@column_widths );
    $prep_summary_table->Set_Headers( \@headings );

    my $output = $prep_summary_table->Printout(0);
    return $output;

}

##############################
# public_functions           #

##################################################################
#
# Return 1 on success (0 indicates error such as branch conflict)
##############################
sub plate_prep_insert_trigger {
###############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc} || $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id   = $self->{Plate_Prep_ID};

    my %q = $dbc->Table_retrieve( 'Plate_Prep,Prep', [ 'FK_Plate__ID', 'FK_Solution__ID', 'Prep_Name' ], "WHERE FK_Prep__ID = Prep_ID AND Plate_Prep_ID=$id" );

    my $plate_id    = $q{FK_Plate__ID}[0];
    my $solution_id = $q{FK_Solution__ID}[0];
    my $prep_name   = $q{Prep_Name}[0];

    if ( $solution_id && $prep_name !~ /^Skipped / ) {
        my $branch = &_get_branch( -dbc => $dbc, -plate_id => $plate_id, -solution_id => $solution_id );
        if ($branch) {
            if ( $branch == -1 ) {
                return 0;    ## error encountered ##
            }
            else {

                #                Message("Branch changed to $branch for " . $dbc->get_FK_info('FK_Plate__ID',$plate_id));
                $dbc->message("Set Branch to $branch");
                $self->{dbc}->Table_update( 'Plate', 'FK_Branch__Code', $branch, "WHERE Plate_ID=$plate_id", -autoquote => 1 );
            }
        }
    }

    return 1;
}

####################################################
# Updates branch attribute for Plates if applicable
#
#
# Returns the branch code on success or -1 on error. If no
####################
sub _get_branch {
####################
    my %args = &filter_input( \@_, -args => 'dbc,plate_id,solution_id', -mandatory => 'dbc,plate_id,solution_id' );
    if ( $args{ERRORS} ) {
        Message("Input Errors Found: $args{ERRORS}");
        return;
    }

    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id    = $args{-plate_id};
    my $solution_id = $args{-solution_id};

    my $debug = $args{-debug};

    my @branch_types = ( 'Primer', 'Enzyme' );
    my $plate_fk_info = $dbc->get_FK_info( 'FK_Plate__ID', $plate_id );

    my %q = $dbc->Table_retrieve( 'Plate', [ 'FK_Pipeline__ID', 'FK_Branch__Code' ], "WHERE Plate_ID=$plate_id" );

    my $plate_pipeline = $q{FK_Pipeline__ID}[0];
    my $plate_branch   = $q{FK_Branch__Code}[0];

    my $error_if_no_branch;

    require alDente::Solution;

    my $added_reagents = join ',', &alDente::Solution::get_original_reagents( $dbc, $solution_id, -unique => 1 );

    my $branch_condition;

    if ($plate_pipeline) {
        require alDente::Pipeline;
        ## this was wrong (and is still wrong)... we should get the full parent pipeline list (including the current pipeline)
        my $parent_pipelines = join ',', &alDente::Pipeline::get_parent_pipelines( $dbc, $plate_pipeline, -include_self => 1 );
        if ($parent_pipelines) {
            $branch_condition = " ( IF(Branch_Condition.FK_Pipeline__ID,0,1) OR Branch_Condition.FK_Pipeline__ID IN ($parent_pipelines))";
        }
        else {
            $branch_condition = "IF(Branch_Condition.FK_Pipeline__ID,0,1) ";
        }
    }
    else {
        $branch_condition = " IF(Branch_Condition.FK_Pipeline__ID,0,1)";    ## returns true if FK_Pipeline__ID = 0 or NULL.
    }

    $branch_condition .= " AND Stock_Catalog_Name NOT LIKE 'Custom Oligo %'";    ## Exclude custom primer/enzyme/oligos

    my @branch;
    ## try all branch types (eg on Primer; on Enzyme; etc)
    foreach my $object (@branch_types) {

        my $tables    = "Branch,Branch_Condition,Stock,Stock_Catalog,Solution,Object_Class,$object";
        my $condition = "WHERE Branch_Condition.FK_Branch__Code=Branch_Code AND Solution.FK_Stock__ID=Stock_ID AND Branch_Condition.Object_ID = ${object}_ID AND Branch_Condition_Status='Active'
                                     AND Object_Class.Object_Class_ID = Branch_Condition.FK_Object_Class__ID AND Object_Class='$object' AND
                                     Stock_Catalog_Name = ${object}_Name AND $branch_condition AND FK_Stock_Catalog__ID = Stock_Catalog_ID";
        ## group by stock name if more than one solution with the same stockname has been applied (ie an aliquot)
        my @applicable_reagents = $dbc->Table_find_array(
            $tables,
            ['Solution_ID'],
            "$condition AND Solution_ID IN ($added_reagents) ",
            -distinct => 1,
            -debug    => $debug,
            -group_by => 'Stock_Catalog.Stock_Catalog_Name'
        );

        foreach my $reagent (@applicable_reagents) {
            ## for every reagent that may trigger a branch on this pipeline: ##
            my @new_branches;    ## only one applicable branch should be available per reagent ##

            ## (note in each loopk, the plate branch code may be different) ##
            my @branches = $dbc->Table_find_array(
                $tables,
                [ 'Branch_Code', 'Branch_Condition.FKParent_Branch__Code', 'Branch_Condition.Object_ID', 'Branch_Condition.FK_Object_Class__ID', 'Stock_Catalog_Name', 'Branch_Condition.FK_Pipeline__ID' ],
                "$condition AND Solution_ID IN ($reagent)",
                -distinct => 1,
                -debug    => $debug
            );

            ## for each branch applicable to the applied reagents: ##
            foreach my $branch_info (@branches) {
                my ( $new_branch, $parent, $object, $class, $stock, $branch_pipeline ) = split ',', $branch_info;

                if ( $plate_branch eq $new_branch ) {
                    $error_if_no_branch = "Warning: Branch has already been set.  (You have added '$stock' to '$plate_fk_info' already !)";
                }
                elsif ($plate_branch) {
                    if ( $parent eq $plate_branch ) {
                        ## allow conditional branches dependent upon an existing branch value ##
                        push( @new_branches, $new_branch );
                    }
                    elsif ($parent) {
                        if ($debug) {
                            Message("Warning: Failed conditional branch");
                        }
                    }
                    else {
                        ## cannot change branch unless specifically set up as a secondary branch ##
                        $error_if_no_branch = "Warning: Not set to '$new_branch': Branch already set to '$plate_branch' for plate $plate_fk_info (Define secondary branch if necessary)";
                    }
                }
                elsif ( $parent && $parent ne 'NULL' ) {
                    ## this is a secondary branch, but the plate has no current branch ##
                    $error_if_no_branch = "Warning: $new_branch requires stem from branch '$parent'";
                }
                else {
                    push( @new_branches, $new_branch );
                }
            }

            if ( int(@new_branches) == 1 ) {
                $plate_branch = $new_branches[0];    ## reset the plate_branch on this loop..
                push @branch, $new_branches[0];
            }
            elsif ( int(@new_branches) > 1 ) {
                $dbc->warning("Ambiguous branch target");    ### more than one branch found (?) - cannot deduce appropriate action
                print join ' or ', @new_branches;
                return -1;
            }
            elsif ($error_if_no_branch) {
                Message($error_if_no_branch);
                return -1;
            }
            else {

                # 	    return 0;                            ## no branch found; no special reagents used ... ok (continue - no branch)
            }
        }
    }

    if (@branch) {
        return $branch[-1];
    }    ## return last branch set.  (may involve two-step branch setting) ##
    else {
        return 0;
    }
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

$Id: Plate_Prep.pm,v 1.19 2004/11/24 21:22:33 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
