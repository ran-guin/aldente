#################
# Prep.pm #
##################

# This module is used to handle preparation tracking of Plates/Tubes etc.
# It provides for:
#
# - loading of pre-defined protocol information
# - prompting users for appropriate input
# - tracking steps as completed
#
########################
package alDente::Prep;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Prep.pm - This module is used to handle preparation tracking of Plates/Tubes etc.

=head1 SYNOPSIS <UPLINK>

 my $Prep = Prep->new(-dbc=>$dbc,-type=>'Plate',-protocol=>'Full Mech Prep');
 $Prep->load_Plates($plates);
 print $Prep->prompt_User(); 
 ...

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle preparation tracking of Plates/Tubes etc.<BR>It provides for:<BR>- loading of pre-defined protocol information<BR>- prompting users for appropriate input<BR>- tracking steps as completed<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Safe;
use MIME::Base32;
use Data::Dumper;

use vars qw(%Benchmark $Connection);
##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;
use RGTools::HTML_Table;
use RGTools::Conversion;
use RGTools::RGmath;

use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::Session;

#use YAML qw(thaw freeze Load Dump);
use alDente::Protocol;
use alDente::Library_Plate_Set;
use alDente::Container_Set;
use alDente::Solution;    ## had to add solution.pm because otherwise the module could not find sub get_original_reagents
use alDente::Form;        ## for Set_Parameters...
use alDente::SDB_Defaults;
use alDente::Rack;
use alDente::Tube;
use alDente::Notification;
use alDente::LibraryApplication;
use alDente::Prep_Views;
use alDente::Invoice;
use alDente::Invoiceable_Work;
##############################
# global_vars                #
##############################
use vars qw($scanner_mode);    ### optional global giving smaller display size...
use vars qw($testing);         ### test mode (more verbose feedback)
use vars qw(%Parameters);      ### Standard Parameters
use vars qw(%Current);         ### (experimental) - Current status (eg plates, set ...) ?
use vars qw($current_plates);
use vars qw($plate_set);       #
use vars qw(%Input);           ### Input parameters (from param())
use vars qw(%Settings %Track);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

##########
sub new {
##########
    #
    # constructor
    #
    my $this            = shift;
    my %args            = @_;
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $type            = $args{-type} || 'Plate';                                                         ## type of sample (eg. Plate)
    my $encoded         = $args{-encoded} || 0;                                                            ## reference to encoded object (frozen)
    my $input           = $args{-input};                                                                   ## hash of input parameters (optional)
    my $protocol        = $args{-protocol};                                                                ## name / id of protocol to load
    my $plates          = $args{-plates} || '';                                                            ## plates to be loaded
    my $set             = $args{-set} || 0;                                                                ## plate set to be loaded
    my $Set             = $args{-Set};                                                                     ## Plate_Set object
    my $suppress_load   = $args{-suppress_messages_load} || 0;                                             ## Flag to suppress loading messages
    my $skip_validation = $args{-skip_validation};
    my $dynamic_text    = $args{-dynamic_text};
    my $debug           = $args{-debug};

    if ($debug) {
        print HTML_Dump \%args;
    }

    my $prompted;
    my $id = $args{-id};                                                                                   ## prep_id (optional - used when generating home page for a particular prep

    my ($class) = ref($this) || $this;
    my ($self) = {};

    if ($encoded) {                                                                                        ## special case if protocol object encoded (frozen)
        require YAML;
        my $self = YAML::thaw( MIME::Base32::decode($encoded) );
        $self->{dbc} = '';
        $self->{Set} = '';

        if ($dbc) {
            $self->{dbc} = $dbc;
        }
        if ($input) {
            $self->prompted( $self->_check_Input( -input => $input ) );
        }

        if ( $self->{set_number} ) {
            $self->{Set} = alDente::Container_Set->new( -dbc => $dbc, -set => $self->{set_number}, -skip_validation => $skip_validation );
        }
        $self->{split_completed} = 0;    #the scope of this variable is per step
        return $self;
    }
    else {
        bless $self, $class;
    }

    $self->{dbc}             = $dbc;
    $self->{type}            = $type;               ## sample type (eg Plate)
    $self->{suppress_load}   = $suppress_load;      # suppress load messages
    $self->{skip_validation} = $skip_validation;    # standard export / movement protocols only

    if ($Set) {
        $self->{Set}        = $Set;
        $self->{set_number} = $Set->{set_number};
        $set                = $Set->{set_number};
    }
    elsif ($set) {
        $plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number in ($set)" );
        $self->{Set} = alDente::Container_Set->new( -dbc => $dbc, -set => $set, -skip_validation => $skip_validation );
    }
    elsif ($Set) {

        #	$self->{set_number} = $Set->{set_number};
        $self->{Set} = $Set;
        $set = $Set->{set_number};
    }

    if ( $plates || $set ) {
        $self->reset_focus( -current_plates => $plates, -plate_set => $set, -global => 1 );    ## always reset current plates/set when new Prep is defined (?)
    }

    ## list of current plate_ids
    $self->{prep_id}               = $id;
    $self->{protocol_name}         = '';                                                       ## name of protocol
    $self->{protocol_id}           = 0;                                                        ## protocol id
    $self->{tracksteps}            = 0;                                                        ## total number of steps which are tracked
    $self->{totalsteps}            = 0;                                                        ## total number of steps in protocol
    $self->{thisStep}              = -1;                                                       ## number of the current step
    $self->{records}               = 0;                                                        ## number of records found for ancestry
    $self->{fields}                = [];                                                       ## array of fields to append
    $self->{values}                = [];                                                       ## array of values to append
    $self->{Completed}             = {};                                                       ## Protocols completed (by current plate)
    $self->{Skipped}               = {};                                                       ## Protocols skipped (by current plate)
    $self->{Failed}                = {};                                                       ## Protocols failed (by current plate)
    $self->{user}                  = $dbc->get_local('user_id');
    $self->{suppress_print}        = '';
    $self->{ancestries}            = {};
    $self->{dynamic_text_elements} = $dynamic_text || 0;
    $self->{split_completed}       = 0;

    ## set Input prompts ##
    $self->{Input}->{FK_Equipment__ID}->{prefix}        = 'Equ: ';
    $self->{Input}->{FK_Plate__ID}->{prefix}            = 'Pla: ';
    $self->{Input}->{Prep_Time}->{prefix}               = 'for: ';
    $self->{Input}->{Prep_Time}->{size}                 = 4;
    $self->{Input}->{Prep_Time}->{suffix}               = ' min';
    $self->{Input}->{Prep_Conditions}->{prefix}         = 'Conditions: ';
    $self->{Input}->{FK_Solution__ID}->{prefix}         = 'Sol: ';
    $self->{Input}->{Prep_Comments}->{prefix}           = 'Comments: ';
    $self->{Input}->{Transfer_Quantity}->{prefix}       = ' Transfer:';
    $self->{Input}->{Transfer_Quantity_Units}->{suffix} = ' / Tube';
    $self->{Input}->{FK_Rack__ID}->{prefix}             = 'Location:';

    # NOTE: Solution_Quantity treated as a special case below (do not define here)
    #

    #
    # Load up protocol / plate information if details are supplied
    #

    if ( $protocol =~ /^\d+$/ ) {
        $self->load_Protocol( -id => $protocol );
    }
    elsif ( $protocol =~ /\S+/ ) {
        $self->load_Protocol( -name => $protocol );
    }

    if ($set) {
        $self->load_Set( -set => $set );
    }
    elsif ( $plates =~ /\d+/ ) {
        $self->load_Plates( -ids => $plates );
    }

    # retrieve all the protocol steps that have been done
    if ( $protocol && $self->{plate_ids} ) {
        $self->load_Preparation();
    }
    return $self;
}

##############################
# public_methods             #
##############################

####################
sub reset_focus {
####################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'current_plates, plate_set' );
    my $plate_ids = $args{-current_plates};
    my $set       = $args{-plate_set};
    my $global    = defined $args{-global} ? $args{-global} : 1;                 ## also reset current_plates, plate_set globals (in $dbc) ##
    my $debug     = $args{-debug};
    my $dbc       = $self->{dbc};

    if ( $debug && $self->{plate_ids} ne $plate_ids ) { $dbc->message("reset focus from '$self->{plate_ids}' to '$plate_ids' (Set $set)") }

    if ($plate_ids) {
        $self->{plate_ids} = Cast_List( -list => $plate_ids, -to => 'string' );

        ## keep track of previous set if it was different ##
        if ( $self->{set_number} && ( $self->{set_number} ne $set ) ) {
            $self->{prev_set}   = $self->{set_number};
            $self->{set_number} = $set;
            $dbc->message("reset focus from $self->{prev_set} to $self->{set_number} ($self->{plate_ids})");
        }

        if ($global) { alDente::Container::reset_current_plates( $dbc, $plate_ids, $set ) }
    }
    else {
        $self->{plate_ids}  = '';
        $self->{set_number} = '';
        if ($global) { alDente::Container::reset_current_plates( $dbc, $plate_ids, $set ) }
    }
    return 1;
}

####################
#
# Display list of preps and key information given a list of ids.
#
# If only one id supplied, this will also show details for each container (Plate_Prep details)
#
#
# Return: 1 on success
###################
sub home_page {
###################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id} || $self->{prep_id};    ## home page only relevant when prep_id is defined.

    if ($id) {
        my @prep_fields = qw(Prep_ID Prep_DateTime Prep_Name FK_Employee__ID Prep_Comments);
        Table_retrieve_display( $dbc, 'Prep', \@prep_fields, "WHERE Prep_ID IN ($id)", -title => "Prep $id details" );
        print hr;
        if ( $id =~ /,/ ) {
            Message("(click on individual prep id for details for each container)");
        }
        else {
            ## provide details if only one prep supplied ##
            my @plate_fields = qw(FK_Plate__ID FK_Solution__ID FK_Equipment__ID);
            Table_retrieve_display( $dbc, 'Prep,Plate_Prep', \@plate_fields, "WHERE FK_Prep__ID=Prep_ID AND Prep_ID = $id", -title => "Details for each Plate/Tube" );
        }
    }
    else {
        ## no specific prep supplied - no applicable home_page ##
        return;
    }
    return 1;
}

sub plate_set {
    my $self = shift;
    return $self->{set_number};
}

sub current_plates {
    my $self = shift;
    return $self->{plate_ids};
}

#################
sub prompted {
#################
    my $self  = shift;
    my $value = shift;

    if ($value) { $self->{prompted} = $value }
    else        { return $self->{prompted} }

    return 1;
}

####################
# loads all the steps that have been done, and classifies them as Completed, Failed,
####################
sub load_Preparation {
####################
    my $self           = shift;
    my %args           = &filter_input( \@_, -args => 'no_repeat' );
    my $non_repeatable = $args{-no_repeat} || $self->{non_repeatable};
    my $dbc            = $self->{dbc};

    ## Only include the preps that were done before the child plate was aliquoted.  For example, if a solution was applied to the parent plate after it was aliquoted, it should not show up in the plate history of the child.
    ## for each  plate,
    ## get the parents
    ## get the preps that were done after the child plate had been created and add to list
    ## end for

    if ( !param('Freeze Protocol') ) {
        my ($preprinted) = $dbc->Table_find( 'Plate', 'count(*)', "WHERE Plate_ID IN ($self->{plate_ids}) and Plate_Status like 'Pre-Printed'", -debug => 0 );
        $self->{preprinted_plates} = $preprinted;
        if ($preprinted) { Message("Warning: current plates are only pre-printed"); }
    }

    $dbc->Benchmark('StartedLoadPrep');

    my $set_condition;
    unless ($non_repeatable) {
        ## this generates an extra condition that includes current set, parent sets - allowing a new set of identical plates to repeat the same protocol ##
        ## this only applies for the current plates! The history of previous generations will still be checked and they will not be repeatable (unless get_parent_sets didn't include the set of previous generations) ##
        my $set = $self->{set_number};

        # See if we are transferred from previous set
        if ( $self->{set_number} ) {

            # Also get previous sets more than one generation away
            my $parents = alDente::Container_Set::get_parent_sets( -dbc => $dbc, -sets => $self->{set_number}, -recursive => 10, -format => 'list' );
            if ($parents) {
                $set .= ",$parents";
            }
        }
        $set_condition = "AND FK_Plate_Set__Number in ($set) " if $set;
    }

    my %Preps;
    my %ancestries;
    my %plate_prep_completed;

    foreach my $plate ( split ',', $self->{plate_ids} ) {
        ## Get the ancestry for each plate
        my %parent_ancestry;
        if ( defined $self->{ancestries} && %{ $self->{ancestries} } && $self->{ancestries}->{$plate} ) {
            %parent_ancestry = %{ $self->{ancestries}->{$plate} };
        }
        else {
            %parent_ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate, -format => 'hash', -no_sample => 'y', -generation_only => 'y', -generations => 5, -rearrays => 2 );
        }

        $ancestries{$plate} = \%parent_ancestry;
        $parent_ancestry{'generation'}{0} = $plate;

        my ($plate_info) = Table_find( $dbc, 'Plate', 'Plate_Created,Plate_Status', "WHERE Plate_ID = $plate" );
        my ( $plate_created, $plate_status ) = split ',', $plate_info;

        $plate_created = convert_date( $plate_created, 'SQL' );
        $parent_ancestry{'created'}{0} = $plate_created;
        ## go through each generation and get the preps that are applicable to the plate

        my @generations = reverse sort { $b <=> $a } keys %{ $parent_ancestry{'generation'} };

        foreach my $generation (@generations) {

            my $generation_plate       = $parent_ancestry{'generation'}{$generation};
            my $generation_created     = $parent_ancestry{'created'}{$generation};
            my $daughter_plate_created = $parent_ancestry{'created'}{ $generation + 1 };
            my $extra_condition .= "FK_Plate__ID IN ($generation_plate) ";
            ## Get only the preps that apply to the plate when it was created and before it was aliquoted
            if ( $generation_created && $daughter_plate_created ) {
                $extra_condition .= "AND Prep_DateTime <= '$daughter_plate_created'";
            }
            else {
                ### We probably don't need this. This causes problems with setup plates (preps applied before plate creation since plate_created gets updated after aliquot/transfer (reza)
                #                $extra_condition .= "AND Prep_DateTime >= '$generation_created'";
            }

            ## IF awaiting transfer to pre-printed plate, force execution of Aliquot/Transfer step (by ignoring any prior transfers) ##
            if ( ( $plate_status =~ /Pre-Printed/ ) && ( $generation =~ /-1/ ) ) { $extra_condition .= " AND Prep_Name NOT LIKE 'Aliquot %' AND Prep_Name NOT LIKE 'Transfer %'" }
            ## Get the plate prep information for the plate
            my %plate_preps = &Table_retrieve(
                $dbc,
                'Prep,Plate_Prep',
                [   'Prep_ID',         'Prep_Name', 'Prep_DateTime', 'Plate_Prep.FK_Solution__ID', 'Plate_Prep.Solution_Quantity', 'Plate_Prep.FK_Equipment__ID',
                    'Prep_Conditions', 'Prep_Time', 'Prep_Comments', 'Prep_Action',                'FK_Plate_Set__Number',         'Plate_Prep.Transfer_Quantity',
                    'Plate_Prep.Transfer_Quantity_Units'
                ],
                "WHERE FK_Prep__ID=Prep_ID AND $extra_condition $set_condition AND FK_Lab_Protocol__ID=$self->{protocol_id} Group by Prep_ID ORDER BY Prep_DateTime",
            );
            foreach my $key ( keys %plate_preps ) {
                my $values = $plate_preps{$key};
                push @{ $Preps{$key} }, @{$values};
                if ( $key eq 'Prep_Name' ) {
                    push @{ $plate_prep_completed{$plate} }, @{$values};
                }
            }
        }
    }

    #print HTML_Dump \%plate_prep_completed, \%Preps;

    if ( !$non_repeatable ) {
        ## If the protocol is repeatable, go through the preps in chronological order (which is what the above block is for), if the protocol has been completed before, just remove all the preps before and including the Completed Protocol. Do this until the end and what's left are preps that seem like going through the protocol for a first time.
        ## <CONSTRUCTION> Batch edit doesn't work or at least, you can't batch edit the preps that have completed protocol before.
        my $index = 0;
        while ( defined $Preps{Prep_ID}[$index] ) {
            my $step = $Preps{Prep_Name}[$index];
            if ( $step eq 'Completed Protocol' ) {
                for my $key ( keys %Preps ) {
                    splice( @{ $Preps{$key} }, 0, $index + 1 );    # removing all preps before including Completed Protocol
                }
                for my $key ( keys %plate_prep_completed ) {
                    splice( @{ $plate_prep_completed{$key} }, 0, $index + 1 );    # removing all preps before including Completed Protocol
                }
                $index = 0;
            }
            $index++;
        }
    }

    #print HTML_Dump \%plate_prep_completed, \%Preps;

    $dbc->Benchmark('FinishedLoadPrep');
    $self->{ancestries} = \%ancestries;
    my $index = 0;

    # initialize
    my %Completed;
    my %Skipped;
    my %Failed;
    my @Ordered_Prep_Names = ();

    while ( defined $Preps{Prep_ID}[$index] ) {    ### set up rows for completed steps...
        my $step = $Preps{Prep_Name}[$index];
        my %prep_step_info;
        $prep_step_info{Prep_ID}                 = $Preps{Prep_ID}[$index];
        $prep_step_info{Transfer_Quantity}       = $Preps{Transfer_Quantity}[$index];
        $prep_step_info{Transfer_Quantity_Units} = $Preps{Transfer_Quantity_Units}[$index];

        if ( param('Batch_Edit') ) {
            $prep_step_info{Prep_DateTime}     = $Preps{Prep_DateTime}[$index];
            $prep_step_info{FK_Solution__ID}   = $Preps{FK_Solution__ID}[$index];
            $prep_step_info{Solution_Quantity} = $Preps{Solution_Quantity}[$index];
            $prep_step_info{FK_Equipment__ID}  = $Preps{FK_Equipment__ID}[$index];
            $prep_step_info{Prep_Conditions}   = $Preps{Prep_Conditions}[$index];
            $prep_step_info{Prep_Time}         = $Preps{Prep_Time}[$index];
            $prep_step_info{Prep_Comments}     = $Preps{Prep_Comments}[$index];
            $prep_step_info{Prep_Action}       = $Preps{Prep_Action}[$index];
            $prep_step_info{Split}             = $Preps{Split}[$index];
        }

        $index++;

        my $action;
        my $step_name_temp = '';

        if ( ( $step =~ /^Skipped (.*)/ ) || ( $action eq 'Skipped' ) ) {
            $Skipped{$step} = \%prep_step_info;
        }
        elsif ( ( $step =~ /^Failed (.*)/ ) || ( $action eq 'Failed' ) ) {
            $Failed{$step} = \%prep_step_info;
        }
        else {
            foreach my $key ( keys %prep_step_info ) {
                $Completed{$step}{$key} = $prep_step_info{$key};
            }
        }
        push( @Ordered_Prep_Names, $step ) unless ( grep( /^$step$/, @Ordered_Prep_Names ) );
    }

    my @plates_completed;

    foreach my $plate ( split ',', $self->{plate_ids} ) {
        if ( $plate_prep_completed{$plate} ) {
            my @most_completed_preps = keys %Completed;
            my @completed_preps      = @{ $plate_prep_completed{$plate} };

            my @diff = &RGmath::minus( \@most_completed_preps, \@completed_preps );

            if ( scalar(@diff) == 0 ) {
                push @plates_completed, $plate;
            }
        }
    }

    $self->{Completed}          = \%Completed;            ## Protocols completed
    $self->{Skipped}            = \%Skipped;              ## Protocols skipped
    $self->{Failed}             = \%Failed;               ## Protocols failed
    $self->{Ordered_Prep_Names} = \@Ordered_Prep_Names;
    $self->{Plates_Completed}   = \@plates_completed;     ## Plates that have completed the protocol

    return;
}

####################
sub load_Protocol {
####################
    #
    # get protocol definition & details for each step
    #
    my $self = shift;
    my %args = @_;
    ## parameters: ##
    my $protocol_id   = $args{-id};           # - specify id
    my $protocol_name = $args{-name};         # - specify protocol_name
    my $reload        = $args{-load} || 0;    # - load (from Storable) - optional
    my $save          = $args{-save} || 0;    # - save (to Storable) - optional

    my $dbc = $self->{dbc};                   # - database handle

    my @protocol_info = $dbc->Table_find( 'Lab_Protocol', "Lab_Protocol_ID,Lab_Protocol_Name,Max_Tracking_Size,Repeatable", "where Lab_Protocol_ID = \"$protocol_id\" OR Lab_Protocol_Name = \"$protocol_name\"" );

    ( $protocol_id, $protocol_name, my $max_size, my $repeatable ) = split ',', $protocol_info[0];

    #    if ($protocol_id) {               ## get name if given id
    #	    ($protocol_name) = $dbc->Table_find('Lab_Protocol','Lab_Protocol_Name',"where Lab_Protocol_ID = $protocol_id");
    #    }
    #    elsif ($protocol_name) {        ## get id if given name
    #	    ($protocol_id) = $dbc->Table_find('Lab_Protocol','Lab_Protocol_ID',"where Lab_Protocol_Name = \"$protocol_name\"");
    #    }

    $self->{protocol_name}    = $protocol_name;
    $self->{protocol_id}      = $protocol_id;
    $self->{max_size_tracked} = $max_size;
    if ( $self->{max_size_tracked} =~ /96/ ) {
        Message("Forcing all 384-well plates onto Trays to enable quadrant tracking");
    }
    $self->{non_repeatable} = ( $repeatable =~ /No/i );

    #   unless ($self->{suppress_load}) {
    #	print "<span class=small><B>Protocol $protocol_name ($protocol_id)</B></span>";
    #    }
    ### make sure a valid protocol has been entered
    unless ( $protocol_id =~ /[1-9]/ ) {
        $dbc->message("No Protocol specified");

        # Message("No Protocol specified");
        return 0;
    }

    if ($reload) {
        my $storable_file;
        if ( -e $storable_file ) {
## load from Storable
            return 1;
        }
    }

    $self->load_Step();    ### load all steps

## load given id
## load given name

    return 1;
}

###############
sub load_Step {
###############
    #
    # load information for individual (or all) steps
    # Generates:
    #        $self->{Input}->{1..N}
    #        $self->{Step}->{1..N}
    #        $self->{Format}->{1..N}
    #        $self->{Default}->{1..N}
    #
    #  where N = $self->{tracksteps}
    #

    my $self = shift;
    my %args = @_;

    my $save = $args{-save} || 0;
    my $step_name = $args{-step};
    my $condition;

    if ($step_name) {
        my $step_name_s = $step_name;
        $step_name_s =~ s/'/\\'/g;
        $condition = "AND Protocol_Step_Name = \"$step_name_s\"";
    }    ### if only loading one step.

    ## save hash with $self->{Step}->{N}->{Field} values
    my @fields = (
        'Protocol_Step_Name', 'Protocol_Step_Number', 'Scanner',  'Input',                    'Input_Format', 'Protocol_Step_Defaults', 'Protocol_Step_Message', 'Protocol_Step_ID',
        'FKQC_Attribute__ID', 'QC_Condition',         'Validate', 'Protocol_Step.Repeatable', 'Protocol_Step_Instructions'
    );
    my $tracksteps = 0;
    my %steps      = &Table_retrieve( $self->{dbc}, 'Lab_Protocol,Protocol_Step', \@fields, "where FK_Lab_Protocol__ID = Lab_Protocol_ID AND Lab_Protocol_ID = $self->{protocol_id} $condition Order by Protocol_Step_Number" );
    my $i          = 0;
    while ( defined $steps{Protocol_Step_Name}[$i] ) {
        my ( $step_name, $step_num, $onoff, $input, $format, $default, $msg, $protocol_step_id, $QC_attribute, $QC_condition, $Validate, $repeatable, $instructions ) = (
            $steps{'Protocol_Step_Name'}[$i],     $steps{'Protocol_Step_Number'}[$i],  $steps{'Scanner'}[$i],          $steps{'Input'}[$i],              $steps{'Input_Format'}[$i],
            $steps{'Protocol_Step_Defaults'}[$i], $steps{'Protocol_Step_Message'}[$i], $steps{'Protocol_Step_ID'}[$i], $steps{'FKQC_Attribute__ID'}[$i], $steps{'QC_Condition'}[$i],
            $steps{'Validate'}[$i],               $steps{'Repeatable'}[$i],            $steps{'Protocol_Step_Instructions'}[$i]
        );

        if ($onoff) {
            $tracksteps++;
            $self->{Input}->{$tracksteps}        = $input;
            $self->{Format}->{$tracksteps}       = $format;
            $self->{Default}->{$tracksteps}      = $default;
            $self->{Step}->{$tracksteps}         = $step_name;
            $self->{QC_Attribute}->{$tracksteps} = $QC_attribute if ($QC_attribute);
            $self->{QC_Condition}->{$tracksteps} = $QC_condition if ($QC_condition);
            $self->{Validate}->{$tracksteps}     = $Validate if ($Validate);

            $self->{Message}->{$tracksteps}                  = $msg;
            $self->{TrackStepNum}->{$step_name}              = $tracksteps;
            $self->{StepID}->{$tracksteps}                   = $protocol_step_id;
            $self->{Repeatable}{$tracksteps}                 = $repeatable;
            $self->{Protocol_Step_Instructions}{$tracksteps} = $instructions;
        }

        #	print "$step_num ($tracksteps) : $step_name ($onoff)<BR>";
        $i++;
    }

    unless ($step_name) {    ### if All steps are being loaded
        $self->{tracksteps} = $tracksteps;
        $self->{totalsteps} = int( @{ $steps{Protocol_Step_Name} } );
    }

    if ($save) {
## save to storable for quicker local retrieval
    }

    return 1;
}

############
sub load_Set {
############
    #
    # load plate_set
    #
    my $self = shift;
    my %args = @_;

    my $set        = $args{-set};
    my $dbc        = $self->{dbc};
    my $max_listed = 4;              ## maximum number of ids to list (otherwise, just show number found)

    #    unless ($self->{suppress_load}) {
    #	$dbc->session->message("Loading Set $set");
    # Message("Loading Set $set.");
    #    }
    my $type = $self->{type};

    my $ids = join ',', $dbc->Table_find( "$type,$type" . "_Set", $type . "_ID", "where FK_$type" . "__ID = $type" . "_ID AND $type" . "_Set_Number = $set" );

    unless ( $ids =~ /[1-9]/ ) {
        $dbc->error("Error : No $type items in set $set");

        #Message("Error : No $type items in set $set");
        return 0;
    }

    my $list_display = '';
    my @list = split ',', $ids;
    if ( int(@list) > $max_listed ) {
        $list_display = int(@list) . ' ' . $type . 's';
    }
    else {
        $list_display = $type . "s: $ids";
    }

    #    unless ($self->{suppress_load}) {
    #	$dbc->session->message("Retrieved $list_display");
    #Message("Retrieved $list_display");
    #    }
    $current_plates = $ids;      ## set global..<temporary until phased out >
    $self->{plate_ids} = $ids;

    $self->load_Plates( -ids => $ids, -set => $set );
    $self->{set_number} = $set;

    return 1;
}

#####################
sub identical_set {
#####################
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my $plate_ids = shift;

    ## try to determine existing set from list of plates ##
    my @sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "WHERE FK_Plate__ID IN ($plate_ids) ORDER BY Plate_Set_Number DESC", -distinct => 1 );
    my $set;
    foreach my $thisSet (@sets) {
        my $list = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number = $thisSet ORDER BY Plate_Set_ID" );
        if ( $list eq $plate_ids ) { $set = $thisSet; last; }
    }

    return $set;
}

##################
sub load_Plates {
##################
    #
    # define plates to be tracked (and check current history, consistency)
    #
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'ids, sets' );

    my $plate_ids = $args{-ids}  || $args{-id}  || 0;    # - plate ids
    my $set       = $args{-sets} || $args{-set} || 0;    # - sets
    my $history = $args{-history} || 0;
    my $dbc = $self->{dbc};

    if ( $set && !$plate_ids ) {
        $plate_ids = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number in ($set) ORDER BY Plate_Set_ID" );
    }

    if ($plate_ids) {
        $set ||= $self->identical_set($plate_ids);

        $self->reset_focus( -current_plates => $plate_ids, -plate_set => $set );

        # $self->{plate_ids} = $plate_ids;
    }

    ########## CHECKING FUNDING SOURCE #############
    if ( $dbc->package_active('Funding_Tracking') && !$self->{skip_validation} ) {
        if ( $self->{protocol_name} ne 'Standard' ) {
            require alDente::Funding;
            my $funding = alDente::Funding->new( -dbc => $dbc );
            unless ( $funding->validate_active_funding( -plates => $plate_ids, -fatal => 'protocol', -value => $self->{protocol_id}, -multiple_allowed => 0 ) ) {
                $dbc->warning("Valid funding source is required for invoice protocol ($self->{protocol_name}) to continue!");

                ## show the 'Resolve Ambiguous Funding' link for admins
                my $access = $dbc->get_local('Access');
                if ( ( grep {/Admin/xmsi} @{ $access->{$Current_Department} } ) || $access->{'LIMS Admin'} ) {
                    my $link = &Show_Tool_Tip( Link_To( $dbc->config('homelink'), 'Resolve Ambiguous Funding', "&cgi_application=alDente::Container_App&rm=Resolve+Ambiguous+Funding&ID=$plate_ids", $Settings{LINK_COLOUR} ),
                        "Resolve ambiguous funding for current plates" );
                    print "\n$link\n";
                }

                &main::leave();
                return;
            }
        }
    }

    my @plate_formats = $dbc->Table_find( 'Plate,Plate_Format', "Plate_Format_ID,Plate_Type,Plate_Format_Type,Wells,Plate_Format.Wells", "WHERE Plate.FK_Plate_Format__ID = Plate_Format.Plate_Format_ID AND Plate_ID in ($plate_ids)", 'distinct' );
    my $format = $plate_formats[0];
    ( $self->{plate_format_id}, $self->{plate_type}, $self->{plate_format}, $self->{plate_format_size}, $self->{plate_format_wells} ) = split ',', $format;
    if ( int(@plate_formats) > 1 ) {
        $dbc->warning("Multiple formats found");

        # Message("Warning: Multiple formats found");
    }
    elsif ( !@plate_formats ) {
        $dbc->error("Plate format ($format ?) of plates $plate_ids cannot be determined");
        Call_Stack();

        # Message("Error: Plate format cannot be determined");
    }
    my $step = 0;

    if ($history) {
        $self->load_History(
            -protocol_id => $self->{protocol_id},
            -ids         => $self->{plate_ids},
            -sets        => $self->{set_number}
        );
    }

    return $step;
}

###############
sub load_History {
###############
    my $self = shift;
    my %args = @_;

    my $protocol_id = $args{-protocol_id} || $self->{protocol_id} || 0;
    my $ids         = $args{-ids}         || $args{-id}           || 0;
    my $sets        = $args{-sets}        || $args{-set}          || 0;
    my $lib         = $args{-library};
    my $dbc         = $self->{dbc};
    my $tables    = 'Lab_Protocol,Prep LEFT JOIN Plate_Prep on FK_Prep__ID=Prep_ID  LEFT JOIN Plate ON Plate_Prep.FK_Plate__ID=Plate_ID';
    my $condition = "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID";

    my $key = "Lab_Protocol_Name";    ## cell key (when searching all protocols)
    if ($protocol_id) {
        $condition .= " AND FK_Lab_Protocol__ID in ($protocol_id)";
        $key = "Prep_Name";           ## cell key when looking at a spec. protocol
    }

    my $index = "CONCAT(FK_Library__Name,'-',Plate_Number)";

    if ($ids) {
        $condition .= " AND (Plate_Prep.FK_Plate__ID in ($ids) OR Plate_Prep.FK_Plate_Set__Number in ($sets))";
    }
    elsif ($lib) {
        $condition .= " AND FK_Library__Name like '$lib'";
    }
    my $group = "Group by $index,Lab_Protocol_Name,Prep_Name,Plate_Prep.FK_Plate_Set__Number";
    my $order = "Order by $index,$key,Prep_DateTime";

    my @done = $dbc->Table_find_array(
        $tables,
        [ $index, $key, 'Lab_Protocol_ID', 'Lab_Protocol_Name', 'Prep_Name', 'count(Distinct Plate_Prep_ID)', 'Max(Prep_DateTime)', 'Plate_Prep.FK_Plate_Set__Number', 'Plate_Prep.FK_Solution__ID', 'Plate_Prep.FK_Equipment__ID' ],
        "$condition $group $order"
    );

    my ( $time, $link, $index_value, $key_value, $preps );
    my ( @solutions, @equipment, @sets, @headings );
    my ( $lastkey, $lastindex );
    my $i         = 0;
    my $skipped   = 0;
    my $failed    = 0;
    my $completed = 0;
    my $count     = 0;
    my %History;

    foreach my $prep (@done) {
        ( $index_value, my $key_value, my $Pid, my $Pname, my $Sname, my $plates, $time, my $set, my $solution, my $equip ) = split ',', $prep;

        print "$index_value ($key_value) : $plates<BR>";
        unless ( grep /^$key_value$/, @headings ) { push( @headings, $key_value ); }
        if ( $i++ && ( ( $index_value ne $lastindex ) || ( $key_value ne $lastkey ) ) ) {
            my $cell = _update_cell( $link, $preps, $count, $sets, $time, \@solutions, \@equipment );
            $History{$lastindex}->{$lastkey} = $cell;
            $preps                           = 0;
            $count                           = 0;
        }
        $lastindex = $index_value;
        $lastkey   = $key_value;

        ## create name (and link if applicable) for this cell
        $link = $key_value;
        unless ($protocol_id) {

            #$link = &Link_To( $dbc->config('homelink'), $Pname, "&Current+Plates=$ids&Plate+History=1&Protocol_ID=$Pid", $Settings{LINK_COLOUR}, ['newwin'] );
            $link = &Link_To( $dbc->config('homelink'), $Pname, "&cgi_application=alDente::Container_App&rm=Plate+History&FK_Plate__ID=$ids&Protocol_ID=$Pid", $Settings{LINK_COLOUR}, ['newwin'] );
        }

        $preps++;    ## number of preparation records found.
        $count += $plates;    ## number of plates prepped

        ## only generate list of solutions if looking at a specific protocol ##
        if ($protocol_id) {
            if ($solution) { push( @solutions, $solution ); }
            if ($equip)    { push( @equipment, $equip ); }
        }
        if ( $set =~ /[1-9]/ ) {
            push( @sets, $set );
        }
        ## indicate steps Skipped/Failed .. ##
        if ( $Sname =~ /^Skip/i ) {
            $skipped++;
        }
        elsif ( $Sname =~ /^Fail/i ) {
            $failed++;
        }
        else {
            $completed++;
        }
    }
    my $cell = _update_cell( $link, $preps, $count, $sets, $time, \@solutions, \@equipment );
    $History{$lastindex}->{$lastkey} = $cell;
    $History{HEADINGS} = \@headings;

    return %History;
}

###################
sub get_Protocol_list {
###################
    #
    # return hash containing number of steps completed for each protocol
    # (ie $Hash{$protocol}=$count...)
    #
    #
    my $self = shift;
    my %args = @_;

    my $plate_ids = $args{-ids} || $args{-id};      # - plate ids
    my $sets = $args{-sets} || $args{-set} || 0;    # - sets
    my $protocol_id = $args{-protocol_id};
    my $library     = $args{-library};

    if ($protocol_id) { $self->{protocol_id} = $protocol_id }

    if ( $plate_ids || $library ) {

        # Load Prep history for these plates
        my %History = $self->load_History( -protocol_id => $protocol_id, -ids => $plate_ids, -sets => $sets, -library => $library );
        return %History;
    }

    if ($library) {
        return %{ $self->{Protocols} };
    }
    else {
        return %{ $self->{Protocols}->{Name} };
    }
}

################
sub check_History {
################
    #
    # auto-generate display of history for given plates (or plate_set)
    #
    my $self = shift;
    my %args = @_;

    my $plates    = $args{-plates} || 0;    ## specified plates
    my $plate_set = $args{-set}    || 0;    ## specified set (defaults to set attribute)

    unless ( $plates || $plate_set ) { $plate_set = $self->{set_number} }    ## set to current set if undefined
    unless ( $plates || $plate_set ) { $plates    = $self->{plate_ids} }     ## set to current plates if still undefined

    my %done = &Table_retrieve_display(
        $self->{dbc},
        'Lab_Protocol,Prep,Plate_Prep',
        [ 'count(*) as Plates', 'Lab_Protocol_Name as Protocol', 'Prep_Name as Action', 'Prep.FK_Employee__ID as Employee', 'Plate_Prep.FK_Equipment__ID as Equipment', 'Plate_Prep.FK_Solution__ID as Solution', 'Prep_DateTime as Date_Time' ],
        "where FK_Lab_Protocol__ID=Lab_Protocol_ID AND FK_Prep__ID=Prep_ID AND (Plate_Prep.FK_Plate__ID in ($plates) or Plate_Prep.FK_Plate_Set__Number in ($plate_set)) Group by Prep_ID Order by Prep_DateTime"
    );

    return;
}

########################################################################
# Check steps completed for Given Protocol & Plate_Set
# (also allow users to update any number of these records at one time)
#
#
#################
sub check_Protocol {
#################
    my $self              = shift;
    my %args              = @_;
    my $error_stepnum_ref = $args{-error_step};    # (ArrayRef) Step numbers of rows that have errors (from $self->{TrackStepNum})

    my $dbc = $self->{dbc};

    unless ( $self->{protocol_name} && $self->{plate_ids} ) {
        $dbc->error("Plates ($self->{plate_ids}) and Protocol ($self->{protocol_id} : $self->{protocol_name} must be set");
        return 0;
    }
    unless ( $self->{tracksteps} ) {
        $dbc->warning->warning("No steps to track");

        #Message("No steps to track");
        return;
    }

    my $timestamp = &date_time();

    my %Completed;
    my $index = 0;

    # append Completed, Skipped, and Failed hashes into one hash for parsing
    my %Preps = ( %{ $self->{Completed} }, %{ $self->{Skipped} }, %{ $self->{Failed} } );
    my @keys;

    foreach my $step ( @{ $self->{Ordered_Prep_Names} } ) {    ### set up rows for completed steps...
        my $prep_id    = $Preps{$step}{Prep_ID};
        my $datetime   = $Preps{$step}{Prep_DateTime};
        my $conditions = $Preps{$step}{Prep_Conditions};
        my $time       = $Preps{$step}{Prep_Time};
        my $comments   = $Preps{$step}{Prep_Comments};
        my $action     = $Preps{$step}{Prep_Action};

        ## Get Plate_Prep info as well... ##
        my %plate_prep_info = &Table_retrieve( $dbc, 'Plate_Prep', [ 'FK_Plate__ID', 'FK_Equipment__ID', 'FK_Solution__ID', 'Solution_Quantity', 'Transfer_Quantity', 'Transfer_Quantity_Units' ], "WHERE FK_Prep__ID = $prep_id" );
        my $transfer_qty_units;
        my ( $plate, $equipment, $solution, $sol_qty, $transfer_qty ) = map {'<UL>'} ( 1 .. 5 );
        my $index = 0;
        while ( defined $plate_prep_info{'FK_Plate__ID'}[$index] ) {
            my $plate_id   = $plate_prep_info{'FK_Plate__ID'}[$index];
            my $equip_id   = $plate_prep_info{'FK_Equipment__ID'}[$index];
            my $sol_id     = $plate_prep_info{'FK_Solution__ID'}[$index];
            my $sq         = $plate_prep_info{'Solution_Quantity'}[$index];
            my $xfer_qty   = $plate_prep_info{'Transfer_Quantity'}[$index] || 0;
            my $xfer_units = $plate_prep_info{'Transfer_Quantity_Units'}[$index];

            if ( !$index || $plate_id ne $plate_prep_info{'FK_Plate__ID'}[ $index - 1 ] ) {
                $plate .= &Link_To( $dbc->config('homelink'), '<LI>' . get_FK_info( $dbc, 'FK_Plate__ID', $plate_id ), "&HomePage=Plate&ID=$plate_id" ) if $plate_id;
            }
            if ( !$index || $equip_id ne $plate_prep_info{'FK_Equipment__ID'}[ $index - 1 ] ) {
                $equipment .= &Link_To( $dbc->config('homelink'), '<LI>' . get_FK_info( $dbc, 'FK_Equipment__ID', $equip_id ), "&HomePage=Plate&ID=$equip_id" ) if $equip_id;
            }
            if ( !$index || $sol_id ne $plate_prep_info{'FK_Solution__ID'}[ $index - 1 ] ) {
                $solution .= &Link_To( $dbc->config('homelink'), '<LI>' . get_FK_info( $dbc, 'FK_Solution__ID', $sol_id ), "&HomePage=Plate&ID=$sol_id" ) if $sol_id;
            }
            if ( !$index || $sq ne $plate_prep_info{'Solution_Quantity'}[ $index - 1 ] ) {
                $sol_qty .= '<LI>' . $sq if $sq;
            }
            if ( !$index || $xfer_qty ne $plate_prep_info{'Transfer_Quantity'}[ $index - 1 ] ) {
                $transfer_qty .= '<LI>' . $xfer_qty if $xfer_qty;
            }

            $transfer_qty_units = $xfer_units || '';
            $index++;
        }
        $plate        .= '</UL>';
        $equipment    .= '</UL>';
        $solution     .= '</UL>';
        $sol_qty      .= '</UL>';
        $transfer_qty .= '</UL>';

        #	$Preps{$step}{FK_Equipment__ID};
        #	my $solution = $Preps{$step}{FK_Solution__ID};
        #	my $quantity = $Preps{$step}{Solution_Quantity};
        #	my $transfer_quantity = $Preps{$step}{Transfer_Quantity};
        #	my $transfer_quantity_units = $Preps{$step}{Transfer_Quantity_Units};
        #

        my $choose = 'done';
        my $step_link = &Link_To( $dbc->config('homelink'), $step, "&HomePage=Prep&ID=$prep_id", $Settings{LINK_COLOUR}, ['newwin'] );

        my $step_name_temp = '';
        if ( ( $step =~ /^Skipped (.*)/ ) || ( $action eq 'Skipped' ) ) {
            $choose         = 'SKIP';
            $action         = 'Skipped';
            $step_name_temp = $1;
        }
        elsif ( ( $step =~ /^Failed (.*)/ ) || ( $action eq 'Failed' ) ) {
            $choose         = 'FAIL';
            $action         = 'Failed';
            $step_name_temp = $1;
        }

        #	elsif ($step =~ /(.+)/) {
        else {
            $choose         = 'done';
            $action         = 'Completed';
            $step_name_temp = $step;
        }
        my $step_name = $step_name_temp;

        my @line = ( "", $choose, $step_link, $datetime, $equipment, $transfer_qty, $transfer_qty_units, $solution, $sol_qty, $conditions, $time, $comments );
        $Completed{$step_name} = \@line;
        push( @keys, $step_name );
    }

    my $form = alDente::Form::start_alDente_form( $dbc, 'Update_Protocol' );

    $form .= hidden( -name => 'Protocol', -value => $self->{protocol_name} ) . hidden( -name => 'Plate_Set_Number', -value => $self->{set_number} ) . hidden( -name => 'Plate_IDs', -value => $self->{plate_ids} );

    $form .= alDente::Prep_Views::Protocol_step_page( $self, \%Completed, -error_step => $error_stepnum_ref );

    $form .= end_form();

    return $form;
}

############################
# Subroutine: Update protocols as specified by 'check_Protocol' method..
# return: 0 if successful, arrayref of Step_Numbers of erroneous data otherwise
#         (for marking errors in check_Protocol)
#########################
sub update_Protocol {
#########################
    my $self        = shift;
    my %args        = filter_input( \@_, -mandatory => 'values,order' );
    my $dbc         = $self->{dbc};
    my $protocol_id = $self->{protocol_id};
    my %values      = %{ $args{ -values } };
    my $userid      = $args{-userid};
    my $order       = $args{-order};
    my $debug       = $args{-debug};
    my @input_list  = @{ $args{-fields} };

    # define all fields that are going to be inserted
    my @prep_fields = (
        'Prep_Name',     'FK_Employee__ID',  'FK_Rack__ID',     'FK_Lab_Protocol__ID', 'Prep_Action',       'Prep_DateTime', 'Prep_Time', 'Prep_Conditions',
        'Prep_Comments', 'FK_Equipment__ID', 'FK_Solution__ID', 'Solution_Quantity',   'Transfer_Quantity', 'Transfer_Quantity_Units'
    );
    my %prep_values;

    my $index = 1;

    # save all information needed for insertion into Prep table
    # in a format that DB_append accepts
    # also do error checking and return Step_Numbers if there's an error
    my @error_rownum = ();

    foreach my $prep_name (@$order) {
        my $split;
        my $prep_action = 'Completed';
        my %row_hash    = %{ $values{$prep_name} };

        ## <CONSTRUCTION> -- where did the highlighted red line disappear .. ?
        # check the formats
        $self->{thisStep} = $self->{TrackStepNum}->{$prep_name};

        my $ok = $self->_check_Formats( \%row_hash );
        if ( $ok == 0 ) {
            Message("Invalid entry for $prep_name");
            push( @error_rownum, $self->{TrackStepNum}->{$prep_name} );
            $dbc->warning("Sample preparation tracking aborted");
            last;
        }

        my $sol = $row_hash{'FK_Solution__ID'} || '';
        my $Input = {
            'FK_Solution__ID'        => $sol,
            'FK_Equipment__ID'       => $row_hash{'FK_Equipment__ID'},
            'FK_Rack__ID'            => $row_hash{'FK_Rack__ID'},
            'Transfer_Quantity'      => $row_hash{'Transfer_Quantity'},
            'Tranfer_Quantity_Units' => $row_hash{'Transfer_Quantity_Units'},
            'Prep_Comments'          => $row_hash{'Prep_Comments'},
            'Prep_DateTime'          => $row_hash{'Prep_DateTime'},
            'Prep_Time'              => $row_hash{'Prep_DateTime'},
            'Prep_Conditions'        => $row_hash{'Prep_Conditions'},
            'Solution_Quantity'      => $row_hash{'Solution_Quantity'},
        };

        if (@input_list) {
            foreach my $field (@input_list) {
                my $localfield = $field;
                if ( $field =~ /_Attribute/ ) {
                    my @attr = split '=', $field;
                    $localfield = $attr[1];
                    $Input->{ $attr[0] } = $row_hash{ $attr[0] };
                }
                if ( $field =~ /Split/ ) {
                    $split = $row_hash{'Split'};
                }
                $Input->{$localfield} = $row_hash{$localfield};
            }
        }
        unless ( my $ok = $self->Record( -step => $prep_name, -input => $Input, -debug => $debug, -split => $split ) ) { $dbc->warning("Sample preparation tracking aborted at '$prep_name' step"); last; }
        $index++;
    }

    return $index;
}

##################
sub prompt_User {
##################
    #
    # generate the user prompt for the appropriate step
    #
    my $self = shift;
    my %args = filter_input( \@_ );

    my $prompt = alDente::Prep_Views::prompt_Step( $self, %args );
    return $prompt;    ## return success
}

#################
sub annotate_Plates {
#################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    my $note = $args{-note} || '';
    if ($note) {
        unless ( $note =~ /[.;]$/ ) { $note .= ";"; }    ## put terminator at end of note if applicable

        my ($existing_note) = $dbc->Table_find_array( 'Plate', ['Count(*)'], "WHERE Plate_ID in ($self->{plate_ids}) AND Plate_Comments like '%$note%'" );
        if ( $existing_note == int( split ',', $self->{plate_ids} ) ) { $dbc->warning("Note: '$note' already annotated to these plates ($existing_note)") }
        else {
            my $updated = $dbc->Table_update_array( 'Plate', ['Plate_Comments'], ["CASE WHEN (Length(Plate_Comments) > 1) THEN concat(Plate_Comments,' ','$note') ELSE '$note' END"], "where Plate_ID in ($self->{plate_ids})" );
            $dbc->message("Annotated plates with note: $note");
            return $updated;
        }
    }
    return;
}

########################
sub check_valid_plates {
########################
    my $self = shift;
    if ( defined $self->{Set} && ( ref( $self->{Set} ) eq 'alDente::Container_Set' ) ) {

        if ( defined $self->{Set}{dbc} ) {

            ## Not sure why it does valid plate check like this. Use more specific check for invalid plate ID to resolve the issue temporarily.
            #if ( $self->{Set}{dbc}{warnings}->[0] =~ /invalid/i ) {
            #    return 0;
            #}
            if ( grep {/Invalid \(or Inactive\) Plate ID/} @{ $self->{Set}{dbc}{warnings} } ) {
                return 0;
            }
        }
    }
    return 1;
}
############################################
# Return: 1 if validation succeeds
#####################
sub QC_validate {
#####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'plates,attribute,condition' );

    my $plate_ref = $args{-plate_ids} || $self->{plate_ids};
    my $attribute = $args{-attribute};
    my $condition = $args{-condition};

    my $this_step = $self->{thisStep};
    if ( $attribute =~ /^\d+$/ ) {
        ## allow specific attribute specification check ##
    }
    elsif ($this_step) {
        ## perform validation based upon step currently loaded ##
        $attribute = $args{-attribute} || $self->{QC_Attribute}->{$this_step};
        $condition = $args{-condition} || $self->{QC_Condition}->{$this_step};
    }
    else {
        Message("Cannot validate QC without plate list and valid attribute ID ($attribute)");
        return;
    }

    unless ( $attribute && $condition ) { return 1 }    ## if no attribute specified, pass validation
    my $dbc        = $self->{dbc};
    my @plates     = Cast_List( -list => $plate_ref, -to => 'array' );
    my $plate_list = join ',', @plates;

    ## parse condition into SQL condition ##
    if    ( $condition =~ /^(\d+)-(\d+)$/ )                   { $condition = "Attribute_Value BETWEEN $1 AND $2"; }
    elsif ( $condition =~ /^\s*([><]=?)\s*(\d+)$/ )           { $condition = "Attribute_Value $1 $2"; }
    elsif ( $condition =~ s/\*/%/g )                          { $condition = "Attribute_Value LIKE '$condition'" }
    elsif ( $condition =~ s/\|/\' OR Attribute_Value = \'/g ) { $condition = "Attribute_Value = '$condition'" }
    else                                                      { $condition = "Attribute = '$condition'" }

    my @ok = $dbc->Table_find( 'Plate,Plate_Attribute,Attribute', 'Plate_ID', "WHERE FK_Plate__ID=Plate_ID AND FK_Attribute__ID=Attribute_ID AND Attribute_ID = $attribute AND $condition AND Plate_ID IN ($plate_list)", -distinct => 1 );

    if ( int(@ok) == int(@plates) ) {
        Message( int(@ok) . " Plates passed QC check" );
        ## all plates passed condition ##
        return 1;
    }
    else {
        Message( "Warning: only " . int(@ok) . " of " . int(@plates) . " Plates Passed QA/QC condition. ($condition)" );
        return 0;
    }
}

# Check the current pipeline against the plate schedule for given plates
# Usage: $self->check_pipeline_status();
# Return: 1 on success
###########################
sub check_pipeline_status {
###########################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $plates   = $self->{plate_ids};
    my $protocol = $self->{protocol_id};
    my $debug    = $args{-debug};

    my @scheduled_pipelines = $self->{dbc}->Table_find( 'Plate_Schedule',       'distinct FK_Pipeline__ID',       "WHERE FK_Plate__ID IN ($plates)",                         -debug => $debug );
    my @current_pipelines   = $self->{dbc}->Table_find( 'Plate,Plate_Schedule', 'distinct Plate.FK_Pipeline__ID', "WHERE Plate_ID IN ($plates) AND FK_Plate__ID = Plate_ID", -debug => $debug );
    my $success             = 1;
    foreach my $curr_pipeline (@current_pipelines) {
        if (@scheduled_pipelines) {
            unless ( grep /^$curr_pipeline$/, @scheduled_pipelines ) {
                $success = 0;
            }
        }
    }
    if ( $success == 0 ) {
        $self->{dbc}->warning("Current pipeline for plates not in scheduled pipelines");
    }
    my @protocols_in_pipeline
        = $self->{dbc}->Table_find( 'Pipeline_Step,Object_Class', 'FK_Pipeline__ID', "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Lab_Protocol' and Object_ID = $self->{protocol_id}", -distinct => 1, -debug => $debug );

    my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( \@scheduled_pipelines, \@protocols_in_pipeline );
    if ( int(@$intersec) == 0 && int(@scheduled_pipelines) != 0 ) {
        $success = 0;

        $self->{dbc}->warning("Current protocol not in scheduled pipelines");
    }

    return $success;
}

#############################
sub _mark_plates_as_in_use {
#############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $plate_ids = $args{-plate_id} || $self->{plate_ids};
    my $event     = $args{-event};
    my $dbc       = $args{-dbc} || $self->{dbc};

    if ( !$dbc && $self ) { $dbc = $self->{dbc} }

    my ($inuse_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE  Rack_Name='In Use'" );

    if ( !$inuse_rack ) {
        Message("Error: Can not find the In Use Rack!");
    }

    my $marked      = 0;
    my $ids         = Cast_List( -list => $plate_ids, -to => 'String' );
    my %plate_racks = $dbc->Table_retrieve(
        'Plate,Rack,Equipment,Stock,Stock_Catalog,Equipment_Category', [ 'Plate_ID', 'FK_Rack__ID' ],
        "WHERE FK_Rack__ID=Rack_ID AND FK_Equipment__ID=Equipment_ID  AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID
                            AND Plate_ID IN ($ids)  AND Category IN ('Freezer','Storage') AND Sub_Category NOT IN ('Storage_Site') AND FK_Rack__ID NOT IN ($inuse_rack)",
        -distinct => 1,
        -key      => 'FK_Rack__ID'
    );
    foreach my $stored ( keys %plate_racks ) {
        if ($stored) {
            my $this_event = $event;
            $dbc->message("Recorded Storage Location for Plates; reset to 'In Use'");
            $this_event ||= "Auto-Retrieve Plate from Rac$stored";
            ## if storage location (Freezer / Fridge / Storage)
            my $stored_plates = Cast_List( -list => $plate_racks{$stored}{'Plate_ID'}, -to => 'String' );
            &alDente::Rack::move_Items( -type => 'Plate', -ids => $stored_plates, -rack => $inuse_rack, -event => $this_event, -dbc => $dbc, -quiet => 1, -confirmed => 1 );

            $marked += int( @{ $plate_racks{$stored}{'Plate_ID'} } );
        }
    }
    return $marked;
}

###########################
# Returns plates to the rack they were in when they were initially set to 'In Use'
#
# Adds event indicating that the plate is auto-returned to the rack from whence it came
# 'Auto-Return Plate to Rac$rack'
#
###########################
sub return_in_use_plates {
###########################
    my $dbc        = shift;
    my $force      = shift;
    my $plates_ref = shift;

    my $in_use_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name like 'In Use'" );
    if ( !$in_use_racks ) { return 0 }

    my @in_use_plate_ids;

    if ($plates_ref) {
        my $plate_list = Cast_List( -list => $plates_ref, -to => 'String' );
        @in_use_plate_ids = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE FK_Rack__ID in ($in_use_racks) and Plate_ID in ($plate_list)" );
    }
    else {
        @in_use_plate_ids = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE FK_Rack__ID in ($in_use_racks)" );
    }

    my @returned_plates;
    print "In use plates found: @in_use_plate_ids.\n";

    my $returned = 0;
    foreach my $plate_id (@in_use_plate_ids) {
        unless ($plate_id) {next}
        my ( $rack, $moved ) = get_last_storage_location( $dbc, $plate_id );
        if ($rack) {
            if ( $force || $moved ) {
                push @returned_plates, $plate_id;
                alDente::Rack::move_Items( -type => 'Plate', -ids => $plate_id, -rack => $rack, -confirmed => 1, -event => "Auto-Return Plate to Rac$rack", -dbc => $dbc, -quiet => 1 );
                $returned++;
            }
            else { Message("Leaving Pla$plate_id as 'In Use' (moved today)") }
        }
        else {
            Message("Warning: No original storage location found for Plate $plate_id (set to Temporary Rack)");
            my ($tmp_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name like 'Temporary'" );
            alDente::Rack::move_Items( -type => 'Plate', -ids => $plate_id, -rack => $tmp_rack, -confirmed => 1, -event => "Auto-Return Plate to Temporary Rack", -dbc => $dbc, -quiet => 1 );
        }
    }
    Message("Returned $returned plates to Original Storage location");
    Message("In Use plates returned: @returned_plates");

    return $returned;
}

################################
# Retrieve last storage location based upon standardized format in plate history
#
# 'Auto-Retrieve Plate from Rac$rack_id' - event tracked whenever plate is used and its location is a storage location (Fridge, Freezer, or Storage)
#
#
################################
sub get_last_storage_location {
################################
    my $dbc      = shift;
    my $plate_id = shift;

    my $rack;
    my ($event) = $dbc->Table_find_array(
        'Prep,Plate_Prep',
        [ 'Prep_Name', 'TO_DAYS(CURDATE()) - TO_DAYS(Prep_DateTime) as Move_Date' ],
        "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID=$plate_id AND Prep_Name like 'Auto-Retrieve Plate from Rac%' Order by Prep_DateTime desc LIMIT 1"
    );
    my ( $prep, $moved ) = split ',', $event;

    if ( $prep =~ /Rac(\d+)/i ) {
        $rack = $1;
    }

    return ( $rack, $moved );    ## $rack = rack_Id;  $moved = days ago when it was stored ##
}

#
# Flag to indicate completion of protocol is to be tracked
#
# Return: Boolean (1 = complete protocol step should be included)
#########################
sub track_completion {
#########################
    my $self = shift;

    my $track;
    my $protocol = $self->{protocol_name};

    if ( $protocol =~ /(Export Samples|Receive Samples)/i ) {
        $track = 0;

        # Message("Completion suppressed for $protocol ($protocol)");
    }
    else {
        $track = 1;

        # Message("Completion tracked for '$protocol' ($self->{protocol_name}");
    }
    return $track;
}

############
sub Record {
############
    #
    # Record given step
    #
    # Required:
    #  - protocol (or protocol_id)
    #  - step (name of step being performed)
    #  - user_id
    #  - timestamp (optional - defaults to current time)
    #  - action (Complete, Skip, or Fail)
    #
    ### <CONSTRUCTION> Support for transactions?

    my $self = shift;
    my %args = &filter_input( \@_ );

    my $ids = $args{-ids} || $args{-plate_ids}   || $self->{plate_ids};    ## list of sample ids
    my $set = $args{-set} || $self->{set_number} || '';                    ## sample set (if applicable)
    my $input = defined $args{-input} ? $args{-input} : \%Input;           ## input parameterns
    my $protocol    = $args{-protocol}    || $self->{protocol}    || '';   ## protocol name
    my $protocol_id = $args{-protocol_id} || $self->{protocol_id} || 0;    ## protocol id
    my $action          = $args{-action};                                                   ## type of action (Complete,Skip,Fail)
    my $step_name       = $args{-step} || $self->{Step}->{ $self->{thisStep} } || '';       ## name of step to be recorded
    my $simple          = $args{-simple};                                                   ## skips some subsidiary triggered events
    my $local_focus     = $args{-local_focus};                                              ## prevent resetting global plate_set & current_plate values
    my $change_location = defined $args{-change_location} ? $args{-change_location} : 1;    ## This flag is used to chnage the rack to in use (if = 1 chnage no chnage if 0)
    my $split           = $args{ -split };
    my $debug           = $args{-debug};                                                    ## prevent resetting global plate_set & current_plate values

    if ($debug) {
        print HTML_Dump \%args;
    }

    if ($step_name) {
        $self->{Step}->{ $self->{thisStep} } = $step_name;
    }

    if ($simple) { $change_location = 0 }                                                   ## no automatic location update in simple mode

    my $user      = $args{-user_id}   || $self->{user};                                     ## user id
    my $timestamp = $args{-timestamp} || $self->{timestamp} || &date_time();                ## time to use for record (defaults to now)
    my $notes     = $args{-notes}     || '';

    my $dbc = $self->{dbc};

    $self->reset_focus( -current_plates => $ids, -plate_set => $set, -global => !$local_focus, -debug => $debug );

    #    $self->{set_number} = $set || 0;
    #    $self->{plate_ids} = $ids;

    unless ($step_name) {
        $step_name = $input->{'Prep Step Name'};
    }

    my $relocate_target;    ## flag to indicate that target plate is to be relocated despite focus on current plates
    if ( &alDente::Protocol::new_plate($step_name) ) {
        if ( $step_name =~ /out to /i ) { $relocate_target = 1 }

        #if ($step_name =~ /^(Transfer|Aliquot) to (.+)/i){
        $set = $self->{prev_set} || $self->{set_number};
    }

    #    &show_parameters();

    my $Stype = $args{-type} || $self->{type};    ### allow similar logic for other items (eg 'Tube')

    my $prep_name = "";
    if ( $action =~ /Skip/i ) {
        $action    = "Skipped";
        $prep_name = "Skipped $step_name";
    }
    elsif ( $action =~ /Fail/i ) {
        $action    = "Failed";
        $prep_name = "Failed $step_name";
    }
    else {
        $action    = "Completed";
        $prep_name = "$step_name";
    }

    if ( $protocol && !$protocol_id ) {
        ($protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = \"$protocol\"" );
    }

    $self->{protocol_id} = $protocol_id;
    $self->load_Step($step_name);

    ### Set standard parameters (excluding those determined by input ###
    $self->{records} = 0;
    $self->{fields}  = [ 'Prep_Name', 'FK_Lab_Protocol__ID', 'Prep_DateTime', 'FK_Employee__ID' ];
    $self->{values}  = [ $prep_name, $protocol_id, $timestamp, $user ];

    if ( $action eq 'Completed' ) {
        my $prep_name_s = $prep_name;
        $prep_name_s =~ s/'/\\'/g;
        my ($repeatable) = $dbc->Table_find( 'Protocol_Step', 'Repeatable', "WHERE FK_Lab_Protocol__ID = $protocol_id AND Protocol_Step_Name = '$prep_name_s'" );
        my $recent_completion = $self->just_completed($prep_name);

        my $failed_repeat = 0;
        if ( $repeatable =~ /^Y/i ) {
            ## okay ... continue ...
            $action = 'Repeat';
        }
        elsif ( $repeatable =~ /^N/i ) {
            $dbc->warning('This step cannot be repeated');
            $failed_repeat++;
        }
        else {
            ## repeatable status not specified ... allow if after delay (prevents mistaken repeats on reloaded pages) ##
            if ( $recent_completion && !$self->{repeat_last_step} ) {
                $dbc->warning("Prevented repetition of $prep_name step within 5 minutes... continuing");

                $failed_repeat++;
            }
        }

        if ($failed_repeat) {
            ## restore focus if this step cannot be repeated at this time ##
            if ( alDente::Protocol::new_plate( -step => $prep_name ) ) {
                my ($daughter_set) = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "WHERE FKParent_Plate_Set__Number = $self->{set_number}" );
                if ($daughter_set) {
                    my @daughters = $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number = $daughter_set AND Plate_Set_Number > 0 ORDER BY Plate_Set_ID" );
                    $self->reset_focus( \@daughters, $daughter_set );
                }
            }
            $dbc->warning("Failed to repeat step");
            return 0;
        }
    }

    ## If notes provided, add it to input, it will be parsed using _parse_Input()
    if ($notes) {
        $input->{Prep_Comments} = $notes;
    }

    ### check input and generate field/value lists for record(s) that need to be added..

    my $check_format    = 1;
    my $mandatory_check = 1;

    #if ($prep_name eq 'Completed $self->{protocol_name} Protocol') {
    #if ( $prep_name =~ /^(Completed $self->{protocol_name} Protocol|Moved to a new container)$/ ) {
    if ( $prep_name =~ /^(Completed Protocol|Moved to a new container)$/ ) {

        if ( !$self->track_completion ) {
            return;
        }    ## do not record this step if track_completion not recorded

        ## Turn off format checking for completed protocol
        $check_format    = 0;
        $mandatory_check = 0;
        ## Clear the input values that are still set from previous step
        $input->{Prep_Time}               = '';
        $input->{Prep_Conditions}         = '';
        $input->{Prep_Comments}           = '';
        $input->{FK_Equipment__ID}        = '';
        $input->{FK_Solution__ID}         = '';
        $input->{Solution_Quantity}       = '';
        $input->{Transfer_Quantity}       = '';
        $input->{Transfer_Quantity_Units} = '';
    }

    unless ( $self->_parse_Input( -params => $input, -check_format => $check_format, -mandatory_check => $mandatory_check ) ) { $dbc->warning('problem parsing input ?'); return 0; }

    unless ( $self->{records} ) { $dbc->warning('no records found'); return 0; }    ### repeat prompt (error with input)

    my $rack_id = 0;
    if ( $input && defined $input->{FK_Rack__ID} ) {
        $rack_id = $input->{FK_Rack__ID};
    }

    if ($rack_id) {
        $rack_id = &get_aldente_id( $dbc, $rack_id, 'Rack', -validate => 1 );
    }

    ## Change location used to be here - moved below to apply to target place in case of ' out to ' extraction with rack ##

    my $set_number = $self->{set_number};

    if ( !$rack_id && $change_location ) {

        #($step_name !~/^Throw Away|^Auto-Retrieve|^Auto-Return/) &&
        $self->_mark_plates_as_in_use();
    }

    if ( !$rack_id && $change_location ) {
        if ( $step_name !~ /^Throw Away|^Auto-Retrieve|^Auto-Return|^Export/ ) {
            $self->_mark_plates_as_in_use();
        }
    }

    ### Transaction ###
    my @fields = @{ $self->{field_list} };
    my @values = @{ $self->{value_list} };

    ###############################################################################
    ## Attribute specific funtionality
    my @std_attr_fields = ( 'FK_Employee__ID', 'Set_DateTime' );
    my @std_attr_values  = ( $user, "$timestamp" );
    my @prep_attr_fields = @{ $self->{prep_attr_field_list} };
    my @prep_attr_values = @{ $self->{prep_attr_value_list} };

    $dbc->start_trans('Prep_Record');
    my $newid = $dbc->Table_append_array( 'Prep', \@fields, \@values, -autoquote => 1 );

    my %Prep_Attribute_values_to_insert;
    my $Prep_Attribute_index = 0;
    my %Prep_Attribute_map;

    #if ($prep_name ne 'Completed $self->{protocol_name} Protocol') {
    #if ( $prep_name !~ /^(Completed $self->{protocol_name} Protocol|Moved to a new container)$/ ) {
    if ( $prep_name !~ /^(Completed Protocol|Moved to a new container)$/ ) {
        if ( $newid && $prep_attr_fields[0] ) {
            my $attr_names = Cast_List( -list => join( ',', @prep_attr_fields ), -to => 'string', -autoquote => 1 );
            for ( my $i = 0; $i < scalar(@prep_attr_fields); $i++ ) {
                my $fk_attr_id;
                if ( exists $Prep_Attribute_map{ $prep_attr_fields[$i] } ) {
                    $fk_attr_id = $Prep_Attribute_map{ $prep_attr_fields[$i] };
                }
                else {
                    ($fk_attr_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = '$prep_attr_fields[$i]' AND Attribute_Class = 'Prep'" );
                    $Prep_Attribute_map{ $prep_attr_fields[$i] } = $fk_attr_id;
                }

                my @values_to_insert = ( $newid, @std_attr_values, $fk_attr_id, $prep_attr_values[$i] );
                $Prep_Attribute_values_to_insert{ ++$Prep_Attribute_index } = \@values_to_insert;
            }

            ## batch insert the Prep Attributes
            if ( scalar( keys %Prep_Attribute_values_to_insert ) ) {
                my $new_attr_info = $dbc->smart_append( -tables => "Prep_Attribute", -fields => [ 'FK_Prep__ID', @std_attr_fields, 'FK_Attribute__ID', 'Attribute_Value' ], -values => \%Prep_Attribute_values_to_insert, -autoquote => 1 );
            }

        }
    }

    unless ( ( $prep_name =~ /Failed|Skipped/ ) || ( $protocol =~ /Standard/ ) ) {
        my $ok = $dbc->Table_update( 'Plate', 'FKLast_Prep__ID', $newid, "WHERE Plate_ID in ($ids)", -autoquote => 1 );

        if ( $step_name eq 'Throw Away' ) {
            my $current_plate_list = $self->{plate_ids};
            Message("Throwing away $current_plate_list");
            alDente::Container::throw_away( -ids => $current_plate_list, -dbc => $dbc, -confirmed => 1, -no_record => 1 );
        }
    }

    #update plate,prep set LPID = $newid where Prep_Name = $prep_name and Prep_Name ne Failed|Skipped and labprotname ne Standard and plate_id in $ids

    ##
    ###############################################################################

    my %prep_values;
    if ($newid) {

        @prep_values{@fields} = @values;

        #Call_Stack();

        foreach my $key ( keys %prep_values ) {
            $self->{$action}{$step_name}{$key} = $prep_values{$key} if not defined $self->{$action}{$step_name}{$key};
        }

        #$self->{$action}{$step_name} = \%prep_values;
        $self->_check_Prep_Details( $input, $step_name, $newid );
    }

    my $update_volumes = 0;

    my ( @plate_ids, @solutions, @sol_volumes, @all_solutions );    # @all_solutions includes solution that was scanned with or without quantity; @solutions only includes solution that was scanned with quantity
    my $move_plate_count = 0;
    my @move_plates;
    my @move_racks;
    my @plate_prep_fields = ( 'FK_Plate__ID', 'FK_Equipment__ID', 'FK_Solution__ID', 'Solution_Quantity', 'Solution_Quantity_Units', 'Transfer_Quantity', 'Transfer_Quantity_Units' );
    my %plate_prep_values;

    foreach my $record ( 1 .. $self->{records} ) {
        my @fields            = @{ $self->{plate_field_list}{$record} };
        my @values            = @{ $self->{plate_value_list}{$record} };
        my @plate_prep_values = ();
        foreach my $plate_prep_field (@plate_prep_fields) {
            my $i = 0;
            my $val;
            foreach my $field (@fields) {
                if ( $field eq "$plate_prep_field" ) {
                    $val = $values[$i];
                    if ( $plate_prep_field ne 'FK_Rack__ID' ) {
                        $self->{$action}{$step_name}{$field} = $val;
                    }

                    last;
                }
                $i++;
            }
            push @plate_prep_values, $val;
        }

        $plate_prep_values{$record} = [ $newid, $set_number, @plate_prep_values ];
    }
    my $ok = $dbc->smart_append( -tables => 'Plate_Prep', -fields => [ 'FK_Prep__ID', 'FK_Plate_Set__Number', @plate_prep_fields ], -values => \%plate_prep_values, -autoquote => 1 );
    unless ($ok) {

        #        $dbc->session->error("No preps recorded");
        $dbc->trans_error("No preps recorded");
        $dbc->finish_trans('Prep_Record');
        return 0;
    }

    my %Equipment_Rack_map;
    my @Plate_List;

    foreach my $record ( 1 .. $self->{records} ) {

        my @fields = @{ $self->{plate_field_list}{$record} };
        my @values = @{ $self->{plate_value_list}{$record} };

        # remove FK_Rack__ID from field and values list
        foreach my $index ( 0 .. ( int(@fields) - 1 ) ) {
            if ( $fields[$index] ne 'FK_Rack__ID' ) {
                $self->{$action}{$step_name}{ $fields[$index] } = $values[$index];
            }
        }

        unless ( $prep_name =~ /^(Completed Protocol|Moved to a new container|Skipped \Q$step_name\E)$/ ) {

            @prep_values{@fields} = @values;
            ## monitor solutions, quantities applied to update plate/tube volumes if necessary ##
            my ( $plate_id, $sol, $sol_qty, $equipment_id, $rack_id );
            foreach my $index ( 0 .. $#fields ) {
                $plate_id     = $values[$index] if $fields[$index] eq 'FK_Plate__ID';
                $sol          = $values[$index] if $fields[$index] eq 'FK_Solution__ID';
                $sol_qty      = $values[$index] if $fields[$index] eq 'Solution_Quantity';
                $equipment_id = $values[$index] if $fields[$index] eq 'FK_Equipment__ID';
                $rack_id      = $values[$index] if $fields[$index] eq 'FK_Rack__ID';
            }
            push @Plate_List, $plate_id;

            # Check to see if an equipment with a single rack has been scanned
            # if it has, then that equipment counts as a rack, and the current plates should be moved to that rack
            if ( $equipment_id && !$rack_id ) {
                my @rack_ids;
                if ( exists $Equipment_Rack_map{$equipment_id} ) {
                    @rack_ids = @{ $Equipment_Rack_map{$equipment_id} };
                }
                else {
                    @rack_ids = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FK_Equipment__ID = $equipment_id" );
                    $Equipment_Rack_map{$equipment_id} = \@rack_ids;
                }

                if ( int(@rack_ids) == 1 ) {
                    $rack_id = $rack_ids[0];
                }
            }

            if ( $change_location && $rack_id && !alDente::Protocol::new_plate($step_name) ) {
                $move_plate_count++;
                push @move_plates, $plate_id;
                push @move_racks,  $rack_id;
            }

            ## collect all the solutions that were scanned in. This is for updating solution status to 'Open' if not opened yet
            if ($sol) {
                push @all_solutions, $sol;
            }

            if ($sol_qty) {
                push( @plate_ids,   $plate_id );
                push( @solutions,   $sol );
                push( @sol_volumes, $sol_qty );
                $update_volumes = 1;
            }
        }
    }
    unless ( $prep_name =~ /^(Completed Protocol|Move.+|Skipped \Q$step_name\E)$/ ) {
        my @attributes = @{ $self->{plate_attr_field_list}{1} } if $self->{plate_attr_field_list};
        my $j;
        foreach my $attr (@attributes) {
            my %list;
            my $index = 1;
            foreach my $id (@Plate_List) {
                $list{$id} = $self->{plate_attr_value_list}{$index}[$j];
                $index++;
            }
            $j++;
            my $updated += alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Plate', -attribute => $attr, -list => \%list, -on_duplicate => 'REPLACE' );
        }
    }

    if ( $move_plate_count && $rack_id && int(@move_plates) > 0 ) {

        my @unique_racks = @{ RGTools::RGIO::unique_items( \@move_racks ) };
        if ( int(@unique_racks) == 1 ) {
            my $move_ids = Cast_List( -list => \@move_plates, -to => 'String' );
            &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => $move_ids, -set => $set_number, -rack => $rack_id, -confirmed => 1 );
            $dbc->message( "$move_plate_count Plate(s) -> " . $rack_id );
            $dbc->message("Rack ID is $rack_id");
        }
        else {
            my $i = 0;
            foreach my $mp (@move_plates) {
                &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => $mp, -set => $set_number, -rack => $move_racks[$i], -confirmed => 1 );
                $dbc->message( "Moved Plate(s) -> " . $move_racks[$i] );
                $dbc->message("Rack ID is $rack_id");
                $i++;
            }
        }
    }

    unless ($rack_id) {
        ($rack_id) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Temporary'" );
    }

    if ($simple) {
        $dbc->finish_trans('Prep_Record');
        return 1;
    }

    my $transferred = $self->_check_Transfer( $prep_name, $rack_id, -split => $split, -input => $input );

    if ( $transferred > 1 ) {
        if ($rack_id) { $ids = $transferred }    ## move transferred plates below instead of current plates
    }
    elsif ( !$transferred ) {

        #        $dbc->error('Transfer error');
        $dbc->trans_error("Transfer Error");
        $dbc->finish_trans('Prep_Record');
        return 0;
    }

    # Check to see if we are storing a plate.  If so, then need to move the plate to the rack.
    ## Not sure why we need to check for this below - is there any case in which a rack is scanned and the tubes/plates are NOT stored there ?... removing for now...
    # if ( $step_name =~ /store/i ) {

    # already moved above...
    #
    if ( $change_location && alDente::Protocol::new_plate($step_name) ) {
        if ( defined $input->{FK_Rack__ID} ) {
            if ( $rack_id && $ids ) {
                my @types = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($ids)", -distinct => 1 );
                unless ( scalar(@types) == 1 ) {    # Do not allow moving different types of container at the same time

                    #                    $dbc->session->error("Error: Cannot move different types of container at the same time. @types");
                    $dbc->trans_error("Error: Cannot move different types of container at the same time. @types");
                    $dbc->finish_trans('Prep_Record');
                    return 0;
                }
                my @racks = split( ",", $rack_id );
                if ( scalar(@racks) == 1 ) {
                    &alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => $ids, -rack => $rack_id, -confirmed => 1 );
                }
                else {

                    #                    $dbc->session->error("New containers can only be moved to one rack instead of $rack_id");
                    $dbc->trans_error("New containers can only be moved to one rack instead of $rack_id");
                    $dbc->finish_trans('Prep_Record');
                    return 0;
                }
            }
            else {

                #                $dbc->session->error("Error: Invalid rack specified.");
                $dbc->trans_error("Error: Invalid rack specified.");
                $dbc->finish_trans('Prep_Record');
                return 0;
            }
        }
    }

    ## update solution status to 'Open' if not opened yet
    if ( int(@all_solutions) ) {
        my $sol_list = join ',', @all_solutions;
        my $datetime = &date_time();
        $dbc->Table_update_array( 'Solution', [ 'Solution_Status', 'Solution_Started' ], [ 'Open', $datetime ], "where Solution_ID in ($sol_list) and Solution_Status = 'Unopened'", -autoquote => 1 );
    }

    ## update plate/tube volumes if necessary ##
    if ($update_volumes) {
        _update_vol_solution( -dbc => $dbc, -plates => \@plate_ids, -solutions => \@solutions, -sol_qty_units => $self->{solution_units}, -volumes => \@sol_volumes );

        #$dbc->session->message("Updated Plate/Tube amounts");
    }

    #when plate prep is added and prep is complete call method to add Invoice information
    my $Invoiceable_Work = new alDente::Invoiceable_Work( -dbc => $dbc );
    $Invoiceable_Work->add_invoiceable_prep_info( -dbc => $dbc, -prep_id => $newid );

    ## Start QC
    ## insert Plate_QC record and start QC
    if ( $step_name eq 'Start QC' ) {
        Message("Start QC");
        require alDente::QA;
        my $qc_type = param('QC_Type');
        alDente::QA::set_qc_status( -status => 'Pending', -table => 'Plate', -ids => $ids, -qc_type => $qc_type );
    }

    $dbc->finish_trans('Prep_Record');

    return 1;
}

######################
sub just_completed {
######################
    my $self      = shift;
    my $prep_name = shift;
    my $set       = $self->{set_number};

    my $dbc = $self->{dbc};

    my $timestamp = date_time('-5m');

    my $just_completed;
    if ($set) {
        $just_completed = $dbc->Table_find( 'Prep,Plate,Plate_Set,Plate_Prep', 'count(*)',
            "WHERE Plate_Set.FK_Plate__ID=Plate_ID AND Plate_Set_Number = $set AND Prep_DateTime > '$timestamp' AND Prep_Name like \"$prep_name\" AND Plate.FKLast_Prep__ID=Prep_ID AND Plate_Prep.FK_Plate__ID = Plate_ID AND FK_Plate_Set__Number = $set GROUP BY Plate_Set_Number"
        );
    }

    return $just_completed;
}

#################
sub fail_Plate {
#################
    #
    # mark the Prep Step for these plates as Failed (removing them from plate set as well)
    # (continues with remaining plates)...
    #
    # Routine to fail a plate from a protocol and create a new entry in the
    # Prep and Plate_Prep table specifying that it was failed from the protocol
    # <snip>
    # Example:
    #    	my $Prep = new alDente::Prep(-dbc=>$dbc,-user=>$user_id);
    #	$Prep->fail_plate(-plate_id=>$plates, -protocol=>$protocol);
    #
    # </snip>
    #

    my $self = shift;
    my %args = @_;

    my $step         = $args{-step};
    my $failed_plate = $args{-ids};
    my $failed_set   = $args{-set} || $self->{set_number};
    my $notes        = $args{-note};
    my $dbc          = $self->{dbc};

    if ( $notes && $notes !~ /[.;]$/ ) { $notes .= ';' }    ## put a terminator at the end of any notes. ##

    $current_plates ||= $self->{plate_ids};                 ## temporary until phased out ##
    my $step_name = $args{-step} || $self->{step};

    my @failed_list = split ',', $failed_plate;

    my $fail_field;
    my $failed_field;
    my $fail_condition;

    my $nowtime = &date_time();

    if ($failed_plate) {                                    ### fail a single plate (or number of plates) only
        $fail_field   = "FK_Plate__ID";
        $failed_field = "$failed_plate";
    }
    elsif ($failed_set) {                                   ### fail entire plate set
        $fail_field   = "FK_Plate_Set__Number";
        $failed_field = "$plate_set";
    }
    else {
        $dbc->warning("Neither Plate nor Set identified");
        return 0;
    }

    my @fields        = qw(FK_Employee__ID Prep_DateTime Prep_Name Prep_Action FK_Lab_Protocol__ID);
    my @failed_values = ( $self->{user}, $nowtime, "Failed $step_name", 'Failed', $self->{protocol_id} );      ### first set to completed
    my $failed        = $dbc->Table_append_array( 'Prep', \@fields, \@failed_values, -autoquote => 1 ) || 0;

    if ($failed_plate) {                                                                                       ### remove failed plate from set ...
        $dbc->message("Failed prep '$step_name' for Container(s) $failed_plate");
        ## Failing ##

        my $ok = $dbc->Table_update_array( 'Plate', ['Plate_Comments'], ["CASE WHEN (Length(Plate_Comments) > 1) THEN concat(Plate_Comments,' ','Failed $step_name; $notes') ELSE 'Failed $step_name; $notes' END"], "where Plate_ID in ($failed_plate)" );

        foreach my $plate_id (@failed_list) {
            my @fields = ( 'FK_Plate__ID', 'FK_Prep__ID' );
            my @values = ( $plate_id, $failed );
            if ( int(@failed_list) == scalar( my @array = split ',', $self->{plate_ids} ) ) {                  ## include plate set in Failed step if ALL plates failed..
                push( @fields, 'FK_Plate_Set__Number' );
                push( @values, $plate_set );
            }
            $dbc->Table_append_array( 'Plate_Prep', \@fields, \@values );

        }

        ############# Reset Plate set to exclude failed plate #################
        my @current = split ',', $self->{plate_ids};                                                           # $current_plates;
        $current_plates = "";                                                                                  ## temporary
        $self->{plate_ids} = '';

        ### extract only plates that have NOT failed from @current plates (temporary inelegant method!)

        my @new_current_list;
        foreach my $plate_id (@current) {
            unless ( grep /^$plate_id$/, @failed_list ) {
                push( @new_current_list, $plate_id );
            }
        }
        $current_plates = join ',', @new_current_list;                                                         ## temporary
        $self->{plate_ids} = join ',', @new_current_list;

        unless ( $self->{plate_ids} =~ /[1-9]/ ) {
            $dbc->warning("No more plates in set... Aborting");

            # Message("No more plates in set... Aborting");
            &main::home('main');
            return 0;
        }

        $self->{Set} = alDente::Container_Set->new( -dbc => $dbc, -ids => join ',', @new_current_list );
        $self->{Set}->save_Set( -force => 1, -parent_set => $failed_set );
        $self->reset_focus( \@new_current_list, $self->{Set}->{set_number}, -global => 1 );

        #        $self->{set_number} = $self->{Set}->{set_number};
        #        $self->{plate_ids}  = join ',', @new_current_list;
        $plate_set = $self->{set_number};

        $dbc->message("Container Set reset to $self->{plate_ids} (set $self->{set_number})");

########## check Daughter plates (& delete from Plate_Sets if unused) #############
        my $daughters = join ',', $dbc->Table_find( 'Plate', 'Plate_ID', "where FKParent_Plate__ID in ($failed_plate) AND Plate_Status like 'Pre-Printed'" );
        if ( $daughters =~ /\d+/ ) {
            print "<BR>Pre-Printed Plates: $daughters<BR>";
            my @waiting_sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "where FK_Plate__ID in ($daughters)" );

            foreach my $thisset (@waiting_sets) {
                if ( !$thisset || $thisset eq 'NULL' ) { next; }
                my $used = join ',', $dbc->Table_find( 'Plate_Prep', 'count(*)', "where FK_Plate_Set__Number in ($thisset)" );
                if ( $used eq 'NULL' || !$used ) {
                    print "Removing Pre-Printed Plates ($daughters) from Set $thisset.";
                    $dbc->dbh()->do("delete from Plate_Set where Plate_Set_Number = $thisset and FK_Plate__ID in ($daughters)");
                }
                else { $dbc->warning("Daughter plate has been Used already ($used) ?"); }
            }
        }
    }
    elsif ( $self->{plate_ids} ) {    ### make comment for all current Plates...
        $dbc->message("Failed plate(s): $failed_plate during $step_name.");

        # Message("Failed plate(s): $failed_plate during $step_name.");
        ## Failing ##

        my $ok
            = $dbc->Table_update_array( 'Plate', ['Plate_Comments'], ["CASE WHEN (Length(Plate_Comments) > 1) THEN concat(Plate_Comments,' ','Failed $step_name; $notes') ELSE 'Failed $step_name; $notes' END"], "where Plate_ID in ($self->{plate_ids})" );
        foreach my $plate_id ( split ',', $self->{plate_ids} ) {
            $dbc->Table_append_array( 'Plate_Prep', [ 'FK_Plate__ID', 'FK_Prep__ID' ], [ $plate_id, $failed ] );
        }
    }

    #    &plate_next_step($current_plates,$plate_set,$step_name);  ### specify go to next step after $step_name...
    if ( $self->{protocol_id} ) {
        $self->load_Preparation();
    }
    print '<hr>';
    $self->load_Step();

    #    $self->load_Step(-step=>$step_name);  ### specify go to next step after $step_name...
    return 1;

}

#
# Apply single Solution ID to 1 or more Plates.
#
# (records as Prep record)
# Return: 1 on success.
##################################
sub apply_Solution_to_Plate {
##################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $solution  = $args{-solution};
    my $plates    = $args{-plate};
    my $qty       = $args{-qty};
    my $qty_units = $args{-units};

    my $now     = &date_time();
    my $user_id = $dbc->get_local('user_id');

    my $ok;
    foreach my $plate ( split ',', $plates ) {
        my ($protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = 'Standard'", 'Distinct' );
        my @fields = ( 'Prep_Name', 'FK_Employee__ID', 'Prep_DateTime', 'FK_Solution__ID', 'Solution_Quantity', 'Solution_Quantity_Units', 'FK_Plate__ID', 'FK_Lab_Protocol__ID' );
        my @values = ( 'Apply Solution', $user_id, $now, $solution, $qty, $qty_units, $plate, $protocol_id );
        if ( $solution && $plate ) {
            alDente::Solution::open_bottle($solution);

            #my $ok = $dbc->Table_append_array('Prep',\@fields,\@values,-autoquote=>1);
            $ok = $dbc->smart_append( -tables => 'Prep,Plate_Prep', -fields => \@fields, -values => \@values, -autoquote => 1 );
            Message("Added $qty $qty_units of Sol$solution to PLA $plate");
        }
    }
    return $ok;    ## nothing returned ...regenerates default home page...
}

##############################
# public_functions           #
##############################

### To be developed... ####

##################
sub post_Prompt {
##################
    #
    # Prompt user for details 'post' preparation (after completing entire protocol)
    # (update all the steps at one time at the end)
    #
    # for every step:
    #
    # prompt for 'completed', 'timestamp', (solution), (equipment), (conditions), etc.

}

##################
sub post_Update {
##################
    #
    # update 'post' preparation input (after checking for validity)
    #

    # for every step:
    # check validity of input as required

    # if any errors:
    # regenerate page

    # otherwise: save preparation steps

}

##############################
# private_methods            #
##############################

###########################
sub _print_instructions {
###########################
    #
    # Print out instructions for Protocol Step
    #
    my $self = shift;
    my %args = @_;

    my $dbc = $self->{dbc};

    my $step = $args{-step} || '%';
    my %info = &Table_retrieve(
        $dbc, 'Lab_Protocol,Protocol_Step',
        [ 'Protocol_Step_Instructions as Instructions', 'Protocol_Step_Name as StepName' ],
        "where FK_Lab_Protocol__ID=Lab_Protocol_ID AND Protocol_Step_Name like '$step' and Lab_Protocol_ID=$self->{protocol_id} Order by Protocol_Step_Number"
    );

    my $Itext;
    my $index = 0;
    while ( defined $info{Instructions}[$index] ) {    ### only loops if multiple instruction steps to be displayed...

        my $instructions = $info{Instructions}[$index];
        my $stepname     = $info{StepName}[$index];

        $Itext .= "<U><B>$stepname<B> Instructions:</U><BR>";
        $Itext .= $instructions . '<P>';
        $index++;
    }

    return $Itext;
}

########################################
#
# Returns the step that this plate is ready for...
#
# if -check_completed is provided, it'll return
#   'Completed': protocol is completed but 'Completed Protocol' is NOT recorded as a prep yet,
#   'Recorded':  protocol is completed and 'Completed Protocol' is recorded as a prep,
#   0:           protocol is not completed yet
#
####################
sub _get_NextStep {
####################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'check_completed' );

    my $check_completed = $args{-check_completed};
    my $dbc             = $self->{dbc};
    my $debug           = $args{-debug} || 0;

    ## List of completed steps;
    my @completed = keys %{ $self->{Completed} };

    ## List of completed and skipped steps
    my @done;

    push( @done, @completed );
    push( @done, keys %{ $self->{Skipped} } );

    #print HTML_Dump \@done;
    #print HTML_Dump $self->{Completed};

    my $stop_here = 0;
    if ($check_completed) {
        my $current_track_step = $self->{Step}->{ $self->{tracksteps} };
        ## We are just checking
        #if ( grep /Completed $self->{protocol_name} Protocol/, @completed ) {
        if ( grep /Completed Protocol/, @completed ) {

            # Message("Completed and recorded");
            return 'Recorded';

            #} elsif (grep m|\Q$current_track_step\E|,@completed) {
        }
        elsif ( grep m|\Q$current_track_step\E|, @done ) {

            # Message("Completed but not recorded");
            return 'Completed';
        }
        else {

            # Message("NOT Completed");
            return 0;
        }
    }
    else {
        ## Find the next step
        my $protocol = $self->{protocol_name};
        ( $self->{plate_format_id} ) = Table_find( $self->{dbc}, 'Plate', 'FK_Plate_Format__ID', "WHERE Plate_ID IN ($self->{plate_ids})", -distinct => 1 );
        my $format = &get_FK_info( $self->{dbc}, 'FK_Plate_Format__ID', $self->{plate_format_id} );
        my $next_step;
        foreach my $step_num ( 1 .. $self->{tracksteps} ) {
            my $step = $self->{Step}->{$step_num};
            if ( $self->{preprinted_plates} ) {
                ## only come here if user is initiating a protocol with pre-printed plates ##

                ## in this case go to the next Aliquot / Transfer / Setup step to see if the parent plates match... ##
                my $xfer = &alDente::Protocol::new_plate($step);
                if ( $xfer && ( $xfer->{transfer_method} =~ /(Setup)/ ) && ( $xfer->{'new_format'} eq $format ) ) {
                    ## check if the parents match ##
                    my $parents = join ',', $dbc->Table_find( 'Plate', 'FKParent_Plate__ID', "WHERE Plate_ID IN ($self->{plate_ids})", -distinct => 1 );
                    my ($found) = $dbc->Table_find( 'Plate_Prep,Prep', 'count(*)', "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID IN ($parents) AND Prep_Name like \"$step\" AND FK_Lab_Protocol__ID=$self->{protocol_id}" );

                    #if ($found >= int(split ',', $self->{plate_ids})) { ## <CONSTRUCTION> this condition doesn't work for 1 single parent with multiple children (e.g. 1 384 into 4 96)
                    if ( $found >= int( split ',', $parents ) ) {    ## <CONSTRUCTION> this may have problem with a parnet set up to different format children, the main thing to check here is for each child, there is a parent who been through setup
                        Message("Resuming Protocol with Pre-Printed plates");
                        $next_step                 = $step_num + 1;
                        $self->{preprinted_plates} = '';             ## <CONSTRUCTION> avoid returning to this block
                        next;
                    }
                    next;
                }
                else {
                    if ( $step_num == $self->{tracksteps} ) {
                        $dbc->warning('These plates are Pre-printed without a Setup step ! - see admin');
                    }
                    next;
                }
            }

            # print "<h4> checking for $step </h4>";
            ## Check to see if this step exist in the protocol
            if ( !$step ) {
                Message("Warning: $step_num is undefined");
                next;
            }

            if ( grep( m|\Q$step\E$|, @done ) ) {
                my $xfer = &alDente::Protocol::new_plate($step);

                ## If this is a transfer step
                if ( $xfer && ( $xfer->{'focus'} eq 'target' ) ) {
                    my $prep = $self->{Completed}{$step}{Prep_ID};
                    my ($already_xferred) = $dbc->Table_find( 'Plate_Prep', 'count(*)', "WHERE FK_Prep__ID=$prep AND FK_Plate__ID IN ($self->{plate_ids})" ) if $prep;

                    $dbc->message("Transfer detected ($format .. $xfer->{'new_format'})");

                    if ( $already_xferred && ( $xfer->{transfer_method} !~ /\b(Pre-Print|Skipped)\b/ ) ) {
                        ## prevent users from going to step FOLLOWING a transfer step if this is the same plate that was transferred

                        my @plates_xferred = $dbc->Table_find( 'Plate_Prep', 'FK_Plate__ID', "WHERE FK_Prep__ID=$prep AND FK_Plate__ID IN ($self->{plate_ids})" );
                        my $xferred_list = Cast_List( -list => \@plates_xferred, -to => 'string', -autoquote => 0 );

                        my @daughter_sets = $dbc->Table_find( 'Plate_Set,Plate', 'Plate_Set_Number', "WHERE FK_Plate__ID=Plate_ID and Plate_Status like 'Pre-Printed' AND FKParent_Plate__ID IN ($self->{plate_ids})", -distinct => 1, -debug => $debug );
                        if ( $step_num >= $self->{tracksteps} ) {
                            ## completing protocol ##
                        }
                        elsif (@daughter_sets) {
                            Message("You cannot go beyond this '$xfer->{transfer_method}' step with this plate set - you should be using the DAUGHTER plate set");
                            Message("Plate(s) $xferred_list have already been transferred in the same protocol.");
                            Message("Potential daughter sets: @daughter_sets");
                            $self->{transferred_plates} = $xferred_list;
                        }
                        else {
                            Message("You cannot go beyond this '$xfer->{transfer_method}' step with this plate set. Please '$xfer->{transfer_method}' again or use the DAUGHTER plate set");
                            Message("Plate(s) $xferred_list have already been transferred in the same protocol.");
                            $self->{transferred_plates} = $xferred_list;
                        }
                        $stop_here = 1;
                    }
                    elsif ( $format eq $xfer->{'new_format'} ) {
                        ## Format is the same, proceed
                        $stop_here = 0;    ## allow user to proceed if format matches target format
                        next;
                    }
                    elsif ( $xfer->{transfer_method} !~ /^(Pre-Print|Setup|Skipped)/ ) {
                        ## this should always be true (ie pre-print, skipped are NOT xfer steps)
                        ## not sure why Setup was added to the list above (?) - clarify in comments if possible
                        $stop_here = 1;
                        ## prevent user from passing this step if it is the last step completed ##
                        $dbc->warning("You cannot skip a Transfer Step.");
                    }
                    else {
                        Message("$format ne $xfer->{'new_format'} ($xfer->{transfer_method}");
                        $stop_here = 0;
                    }

                    #if ($stop_here) {
                    #$next_step = $step_num - 1;
                    #$self->{thisStep} = $next_step;
                    #return $next_step;
                    #}
                    #else {
                    next;

                    #}

                }
                else {
                    ## This step has been completed
                    $stop_here = 0;    ## allow user to proceed since the transfer step has been passed already
                    next;
                }
            }
            else {
                ## This step is not done, set it as the next_step
                $next_step = $step_num;
                if ($stop_here) {
                    $next_step--;
                }    ## go back to previous step if last step completed was a transfer
                last;
            }
        }

        ## Update $self
        $self->{thisStep} = $next_step;
        return $next_step;
    }
}

##################
sub _parse_Input {
##################
    #
    # Error checks input for specified step
    #
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'params,check_format' );
    my $params          = $args{-params};                                         ## hash of input parameters
    my $check_format    = $args{-check_format};
    my $mandatory_check = $args{-mandatory_check};
    my %input           = %{$params} if $params;

    #unless ($params) { return 1; }     ### no input ...

    ## Check input format if required ##
    if ($check_format) {
        my $pass_check = $self->_check_Formats($params);
        unless ($pass_check) { Message('Format checking failure'); return 0; }
    }

    ## Check for mandatory input if required ##
    if ($mandatory_check) {
        my $pass_check = $self->_check_Mandatory($params);
        unless ($pass_check) { Message('Mandatory checking failure'); return 0; }
    }

    my $set                = $input{'Plate Set'}    || 0;
    my $plate_distribution = $input{'FK_Plate__ID'} || 0;    ## from Each Plate

    ### start with standard parameters ###
    my @fields = @{ $self->{fields} };
    my @values = @{ $self->{values} };

    my @pla_attr_fields;
    my @pla_attr_values;
    my @pre_attr_fields;
    my @pre_attr_values;

    my @parameters = ( 'Prep_Attribute', 'Prep_Time', 'Prep_Comments' );
    foreach my $parameter (@parameters) {
        if ( defined $input{$parameter} && $input{$parameter} ) {
            my $value = 0;
            if ( $parameter =~ /Plate_Attribute/ ) {
                my @attributes = param($parameter);
                foreach my $attr (@attributes) {
                    $value = $input{$attr};
                    if ($value) {
                        push( @pla_attr_fields, $attr );
                        push( @pla_attr_values, $value );
                    }
                }
            }
            elsif ( $parameter =~ /Prep_Attribute/ ) {
                my @attributes = param($parameter);
                foreach my $attr (@attributes) {
                    $value = $input{$attr};
                    if ($value) {
                        push( @pre_attr_fields, $attr );
                        push( @pre_attr_values, $value );
                    }
                }
            }
            else {
                $value = $input{$parameter};
                push( @fields, $parameter );
                push( @values, $value );
            }
        }
    }

    #$self->{Set} 	= $set;  	## set the self->set because it was left blank eventhough it get parsed out in this method
    #
### possible multiple entry fields...
    #
    unless ( $self->_check_MultipleInput($params) ) { Message("multiple input failure"); return 0; }    ### and set check for multiple record requirements...

    $self->{field_list} = \@fields;
    $self->{value_list} = \@values;

    #$self->{plate_attr_value_list} = \@pla_attr_values;
    #$self->{plate_attr_field_list} = \@pla_attr_fields;
    $self->{prep_attr_value_list} = \@pre_attr_values;
    $self->{prep_attr_field_list} = \@pre_attr_fields;
    $self->{ids}                  = $self->{plate_ids};

    return 1;
}

###############################
sub _check_MultipleInput {
###############################
    #
    #
    #  Input: $dbc, $input (hashref)
    #  Output: returns 1 or 0 depending on if the method succeeded
    #          Updates $self->{plate_field_list} $self->{plate_value_list} and $self->{records}
    #
    #
    #  If no input has been provided, just return true, no checking requried
    #  Create an indexing array -> @index_array
    #  Find the total number of physical plates (trays,plates) -> $NFP
    #  Pad the @machines, @solutions, @solqty, @xfer_qty with $NFP ie: if equipment ids are: 1,2 and plates are
    #     10,20,30,40, @equipments will be (1,1,2,2)
    #    [The checking of the number of sources and targets should be done in Cast_List pad mode]
    #  If Targets and Sources params are defined, check to see whether targets are a multiple of sources
    #  If Transfer quantity is being tracked...
    #    Check to see if all plate formats are the same, and the plate type is a Tube
    #    Update the volumes based on the number of sources and targets
    #    Create the @Xfer_qties to associate it to the corresponding  plate
    #  loop foreach number of actual plates (plates + plates inside the tray)

    #    Distribute equip/sol/input with their corresponding plate.. Table_append)
    #    Store the fields/values array's in the $self->{plate_field_list}/$self->{plate_value_list} corresnpondingly and update
    #      the $self->{records} index

    my $self  = shift;
    my $input = shift;           # input parameters (submitted with form)
    my $dbc   = $self->{dbc};    # database handle

    my %Finput;

    #  If no input has been provided, just return true, no checking requried
    if ($input) {
        %Finput = %{$input} if $input;    # input parameters
    }
    else {
        return 1;
    }

    my @plates;

    if ( $self->{plate_ids} ) {
        @plates = split ',', $self->{plate_ids};
    }
    elsif ( $Finput{'Current Plates'} ) {
        @plates = split ',', $Finput{'Current Plates'};
    }
    elsif ($current_plates) {
        ## temporary
        Message("CODE SHOULD NEVER COME HERE ($self->{plate_ids} should be defined instead)");
        @plates = split ',', $current_plates;
    }

    my $prep_step_name = $input->{'Prep Step Name'};
    my $xfer = &alDente::Protocol::new_plate( -step => $prep_step_name );

    if ($xfer) {
        my $plate_list = join( ',', @plates );
        ### Check for Xfer after a Setup Step...
        ###   Check to see if current_plates have been pre-printed... if yes, set the @plates array to the parent plate set
        my @list = $dbc->Table_find( 'Plate', 'FKParent_Plate__ID', "where Plate_ID in ($plate_list) and Plate_Status = 'Pre-Printed'", -distinct => 1 );

        if (@list) {
            my $list = join ',', @list;
            $dbc->message("Recovering Parents of Setup Plates ($list)");
            @plates = @list;
        }
    }

    my $number_of_plates = int(@plates);
    unless ($number_of_plates) {
        $dbc->error("No current plates");
        return 0;
    }

    #  Create an indexing array -> @index_array

    my $tray_groups = alDente::Tray::group_ids( $dbc, 'Plate', \@plates );

    my @index_array = @{ $tray_groups->{grouped} };

    if ( !@index_array ) { return 0; }

    #  Find the total number of physical plates (trays,plates) -> $NFP

    my $split   = $Finput{Split_X} || 1;                    #$number_of_plates;    ## in case splitting to multiple targets...
    my $sources = $Finput{Sources} || $number_of_plates;    ## in case splitting to multiple targets...
    my $targets = $sources * $split;                        ## int( $targets / $sources );

    my $NPP = scalar( @{ unique_items( \@index_array ) } ); ## Number of parent plates ##

    my $wells = $Finput{QuantityX} || 1;

    ### Custom code for single Trays ###
    ###
    ### If _only_ ONE tray, then assume input data is being scanned for the number of the content of the tray
    if ( $tray_groups->{complete_trays} > 0 && $tray_groups->{physical_plates} > 0 && $tray_groups->{nontray_plates} == 0 && $tray_groups->{tray_singlets} == 0 ) {

        $NPP         = $number_of_plates;
        @index_array = 0 .. $NPP - 1;
    }
    elsif ( $tray_groups->{complete_trays} > 0 && $tray_groups->{physical_plates} > 1 && ( $tray_groups->{nontray_plates} > 0 || $tray_groups->{tray_singlets} > 0 ) ) {
        $NPP         = scalar(@index_array);
        @index_array = 0 .. $NPP - 1;
    }

    #  Pad the @machines, @solutions, @solqty, @xfer_qty with $NFP
    #    ie: if equipment ids are: 1,2 and plates are 10,20,30,40, @equipments will be (1,1,2,2)

    ## Equipment Tracking ##
    my $machine = _expand_multiples( $Finput{FK_Equipment__ID} );
    my @machines;
    if ($machine) {
        @machines = Cast_List(
            -list     => &get_aldente_id( $dbc, $machine, 'Equipment', -validate => 1, -allow_repeats => 1 ),
            -pad      => $NPP,
            -pad_mode => 'Stretch',
            -to       => 'array',
            -default  => 0
        );
    }
    ## Solution Tracking ##
    my $solution = _expand_multiples( $Finput{FK_Solution__ID} );
    my @solutions;
    if ($solution) {
        my $validated = &get_aldente_id( $dbc, $solution, 'Solution', -validate => 1, -qc_check => 1, -fatal_flag => 1, -allow_repeats => 1 );
        unless ($validated) { return 0; }
        @solutions = Cast_List(
            -list     => $validated,
            -pad      => $NPP,
            -pad_mode => 'Stretch',
            -to       => 'array',
            -default  => 0
        );
    }

    my $rack = _expand_multiples( $Finput{FK_Rack__ID} );
    my @racks;
    if ($rack) {
        my $e_rack = alDente::Rack::check_equipment_to_rack( -dbc => $dbc, -ID => $rack );
        if ($e_rack) {
            @racks = Cast_List(
                -list     => &get_aldente_id( $dbc, $e_rack, 'Rack', -validate => 1, -allow_repeats => 1 ),
                -pad      => $NPP,
                -pad_mode => 'Stretch',
                -to       => 'array',
                -default  => 0
            );
        }
    }

    my $solution_quantity = $Finput{Solution_Quantity};
    my @solqty;
    if ($solution_quantity) {
        @solqty = Cast_List(
            -list     => $solution_quantity,
            -pad      => $NPP,
            -pad_mode => 'Stretch',
            -to       => 'array',
            -default  => 0
        );
    }

    #<Construction> revert by to using param because Finput only contain the first value instead of array
    #note that Finput is parsed in from barcode.pl and changing it in barcode.pl may have too many unforseen impacts
    #also, the individual attribute still use Finput since those are only single values
    my @plate_attributes = param('Plate_Attribute');

    #my @plate_attributes = $Finput{Plate_Attribute};
    my %Plate_Attr;

    foreach my $attr (@plate_attributes) {
        my ($attr_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = '$attr'" );

        #
        # Replaced this statement with the code block below to enable accepting attiribute value '0'
        #
        #my $attribute_object = $Finput{"$attr"} || $Finput{"$attr Choice"} || $Finput{"ATT$attr_id"} || $Finput{"ATT$attr_id Choice"};
        my $attribute_object = $Finput{"$attr"};
        if ( !length($attribute_object) ) {
            $attribute_object = $Finput{"$attr Choice"};
            if ( !length($attribute_object) ) {
                $attribute_object = $Finput{"ATT$attr_id"};
                if ( !length($attribute_object) ) {
                    $attribute_object = $Finput{"ATT$attr_id Choice"};
                }
            }
        }

        my $attr_input = _expand_multiples($attribute_object);
        ## convert to FK value if attribute type is FK
        my ($attr_type) = $dbc->Table_find( 'Attribute', 'Attribute_Type', "WHERE Attribute_Name = '$attr'" );
        if ( $attr_type =~ /^FK(\w*?)_(\w+)__(\w+)$/ ) {
            $attr_input = $dbc->get_FK_ID( -field => $attr_type, -value => $attr_input );
        }
        @{ $Plate_Attr{$attr} } = Cast_List(
            -list     => $attr_input,
            -pad      => $NPP,
            -pad_mode => 'Stretch',
            -to       => 'array',
            -default  => 0
        );
    }

    if ( $machine           && !@machines )  { $dbc->error("Incorrect number of Equipment scanned for $NPP plates");           return 0; }
    if ( $solution          && !@solutions ) { $dbc->error("Incorrect number of Solutions scanned for $NPP plates");           return 0; }
    if ( $solution_quantity && !@solqty )    { $dbc->error("Incorrect number of Solution Quantities scanned for $NPP plates"); return 0; }
    foreach my $attr (@plate_attributes) {
        my ($attr_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = '$attr'" );
        my $attribute_object = $Finput{"$attr"} || $Finput{"$attr Choice"} || $Finput{"ATT$attr_id"} || $Finput{"ATT$attr_id Choice"};
        if ( $attribute_object && !@{ $Plate_Attr{$attr} } ) { Message("Incorrect number of $attr values scanned for $NPP plates"); return 0; }
    }

    my $sol_qty_units = $Finput{Quantity_Units};
    $self->{solution_units} = $sol_qty_units;

    # allow pooling to 1 target
    if ( $targets > 1 && ( $split != $targets / $sources ) ) {
        $dbc->error("Error: Number of Targets ($targets) must be a multiple of the number of sources ($sources)");
        return 0;
    }

    #  If Transfer quantity is being tracked...
    #    Check to see if all plate formats are the same, and the plate type is a Tube
    #    Update the volumes based on the number of sources and targets
    #    Create the @Xfer_qties to associate it to the corresponding  plate

    my $Xfer_qty       = $Finput{'Transfer_Quantity'}     || 0;
    my $Xfer_qty_units = $Finput{Transfer_Quantity_Units} || 'ml';
    if ($Xfer_qty) {

        # check to see if all current plates are tubes, and if they have enough sample left to do the transfer
        my @platetype = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID in ($self->{plate_ids})", 'distinct' );
        if ( scalar(@platetype) > 1 ) {
            $dbc->warning("?? Transferring containers of different types together");
            return 0;
        }
        if ( $platetype[0] !~ /tube/i ) {
            $dbc->warning("?? Transferring $platetype[0]! May not be tracking volumes.");

            #            return 0;
        }
    }

    if ( $Xfer_qty =~ s /([\d\s\,\.])+([pnum]?[gl])$/$1/ ) {
        ## extract units if supplied in text field ##
        $Xfer_qty_units = $1;
    }

    my @Xfer_qties = Cast_List(
        -list     => $Xfer_qty,
        -pad      => $targets,
        -pad_mode => 'Stretch',
        -to       => 'array'
    );

    if ( $Xfer_qty && ( int(@Xfer_qties) != $targets ) ) {
        $dbc->warning("Transfer quantity ($Xfer_qty) must be single value or match no. of targets ($targets).");
        return 0;
    }

    my @Xfer_qties_units = Cast_List(
        -list     => $Xfer_qty_units,
        -pad      => $targets,
        -pad_mode => 'Stretch',
        -to       => 'array'
    );

    my $plate_label = $Finput{'Target Plate Label'} || '';
    my @plate_labels = Cast_List(
        -list     => $plate_label,
        -pad      => $targets,
        -pad_mode => 'Stretch',
        -to       => 'array'
    );
    if ( $plate_label && ( int(@plate_labels) != $targets ) ) {
        $dbc->warning("Target Label ($plate_label) must be single value or match no. of targets ($targets).");
        return 0;
    }

    #  loop foreach number of actual plates (plates + plates inside the tray)
    #    distribute equip/sol/input with their corresponding plate.. Table_append)

    #    ## Loop on a diff array
    #    ## If we are going to use $number_of_plates in the following loop,
    #    ## then we have to use the same variable $number_of_plates as the pad for transfer quantity and units
    #

    ## TODO: This method is for validating data, setting values should be moved to a different method
    for ( my $i = 0; $i < $number_of_plates; $i++ ) {
        my $plate_index = $index_array[$i];

        ## avoid running this duplicate times (eg when recording a throw away prep record after a split transfer) ##
        if ( $self->{split_completed} || !$split ) { $split = 1 }

        foreach my $split_index ( 1 .. $split ) {
            my $index = $plate_index * $split + $split_index;

            my ( @fields,            @values );
            my ( @plate_attr_fields, @plate_attr_values );

            push( @fields, "FK_Plate__ID" );
            push( @values, $plates[$i] );      ## this is the only value that is not distributed across splits (eg reference parent plate rather than daugher):

            push( @fields, "FK_Equipment__ID" );
            push( @values, $machines[ $index - 1 ] );

            push( @fields, "FK_Rack__ID" );
            push( @values, $racks[ $index - 1 ] );

            foreach my $attr (@plate_attributes) {
                push( @plate_attr_fields, $attr );
                push( @plate_attr_values, $Plate_Attr{$attr}[ $index - 1 ] );
            }

            push( @fields, "FK_Solution__ID" );
            push( @values, "$solutions[$index - 1]" );

            my $volume = $solqty[ $index - 1 ];
            push( @fields, 'Solution_Quantity', 'Solution_Quantity_Units' );
            push( @values, $volume, $sol_qty_units );

            if ($Xfer_qty) {
                my $transfer_qty   = $Xfer_qties[ $index - 1 ]       || 0;
                my $Xfer_qty_units = $Xfer_qties_units[ $index - 1 ] || '';
                my $Xfer_qty_units = $Xfer_qties_units[ $index - 1 ] || '';

                # get the remaining sample quantity
                #	    my @tube_info = $dbc->Table_find("Plate","Plate_ID,Current_Volume,Current_Volume_Units","WHERE Plate_ID in ($current_plates)");
                #	    foreach my $row (@tube_info) {
                #		my ($id,$orig_quantity,$orig_quantity_units) = split ',',$row;
                #		# Normalize the units to mL
                #		($orig_quantity,$orig_quantity_units) = &convert_to_mils($orig_quantity,$orig_quantity_units);
                if ($Xfer_qty_units) {
                    ( $transfer_qty, $Xfer_qty_units ) = &convert_to_mils( $transfer_qty, $Xfer_qty_units );
                }

                #		if ($orig_quantity && ($orig_quantity lt ($transfer_qty * $split) )) {
                #		    ## <CONSTRUCTION>  Leave out this message for now... until rest of tracking is working properly... ##
                #		    ## $dbc->session->error("Trying to Transfer $transfer_qty$units of sample x $split; but source has only $orig_quantity$orig_quantity_units of sample left");
                #		    return 0;
                #		}

                # Get best units
                ( $transfer_qty, $Xfer_qty_units ) = &Get_Best_Units( -amount => $transfer_qty, -units => $Xfer_qty_units );
                push( @fields, "Transfer_Quantity" );
                push( @values, "$transfer_qty" );
                push( @fields, "Transfer_Quantity_Units" );
                push( @values, "$Xfer_qty_units" );
            }

            my @f = @fields;
            my @v = @values;

            $self->{plate_attr_field_list}{$index} = \@plate_attr_fields;
            $self->{plate_attr_value_list}{$index} = \@plate_attr_values;
            $self->{plate_field_list}{$index}      = \@f;
            $self->{plate_value_list}{$index}      = \@v;
            $self->{records}                       = $index;
        }
    }

    $self->{split_completed} = !$self->{split_completed};    ## avoid running this duplicate times (eg when recording a throw away prep record after a split transfer), but reset for subsequent split steps (?)  ##

    return 1;
}

##################################
sub _check_Prep_Details {
##################################
    # Check for prep details and add to the database if they exist
    my $self    = shift;
    my $input   = shift;                                     # input parameters (submitted with form)
    my $step    = shift;
    my $prep_id = shift;
    my %Finput  = %{$input} if $input;                       # input parameters
    my $dbc     = $self->{dbc};                              # database handle
    my @keys    = keys %Finput;

    #my $step = $Finput{'Prep Step Name'};
    my $protocol_step_id = $self->{StepID}->{ $self->{thisStep} };
    unless ($protocol_step_id) {
        return 0;
    }
    my ($prep_step_id) = $dbc->Table_find( 'Prep_Attribute_Option', 'FK_Protocol_Step__ID', "WHERE FK_ProtocoL_Step__ID=$protocol_step_id" );
    if ($prep_step_id) {
        my %prep_detail_options = Table_retrieve( $dbc, 'Prep_Attribute_Option,Attribute', [ 'Attribute_Name', 'Attribute_ID' ], "WHERE FK_ProtocoL_Step__ID= $prep_step_id and Attribute_ID=FK_Attribute__ID" );
        my @fields = ( 'Prep_Attribute_ID', 'FK_Prep__ID', 'FK_Attribute__ID', 'Attribute_Value' );
        foreach my $key (@keys) {
            my $index = 0;
            while ( defined $prep_detail_options{Attribute_Name}[$index] ) {
                my $attribute_name = $prep_detail_options{Attribute_Name}[$index];
                my $attribute_id   = $prep_detail_options{Attribute_ID}[$index];
                if ( $key eq $attribute_name ) {

                    #print "key: $key, value:".$Finput{$key};
                    my @values = ( '', $prep_id, $attribute_id, $Finput{$key} );

                    $dbc->Table_append_array( 'Prep_Attribute', \@fields, \@values, -autoquote => 1 );

                }
                $index++;
            }
        }
    }
    return 1;
}

#
#
# Return: transferred_id_list; 0 on error (-1 if ok, but nothing transferred);
####################
sub _check_Transfer {
#####################
    #
    # check Transfer to another plate (first look for pre-printed plates)
    #
    #show_parameters();
    my $self = shift;
    my %args = filter_input( \@_, -args => 'action,rack_id,split' );

    my $action       = $args{-action};                        # Transfer type (eg. 'Transfer' or 'Aliquot')
    my $rack_id      = $args{-rack_id};                       # final rack location (optional)
    my $split        = $args{ -split } || param('Split_X');
    my $volume       = $args{-volume};
    my $volume_units = $args{-units};
    my $dbc          = $self->{dbc};
    my $input        = $args{-input};

    my $new_pipeline_id = &get_Table_Param( -table => "Plate", -field => "FK_Pipeline__ID", -dbc => $dbc );
    if ( $new_pipeline_id eq 'Inherit from parent' ) { $new_pipeline_id = ''; }

    if ($new_pipeline_id) {
        $new_pipeline_id = $dbc->get_FK_ID( -field => "FK_Pipeline__ID", -value => $new_pipeline_id );
    }

    my @check_inputs = split ':', $self->{Input}->{ $self->{thisStep} };
    my $track_transfer;
    unless ( grep /Track_Transfer/, @check_inputs ) {
        $track_transfer = 'No';

    }

    my $current_plate_list = $self->{plate_ids};    ## Differentiate from global
    $current_plate_list ||= param('Current Plates') || param('Current_Plates');

    my $new_format;
    my $transferred = 0;
    my $pooled      = 0;
    my $new_set     = 0;
    my $new_sample_type;
    my $new_sample_type_id;
    my $sample_check;
    my $transfer_method;
    my $create_new_sample;

    my $step_name            = $self->{Step}->{ $self->{thisStep} };
    my $pre_transfer_failure = 0;

    #if ($action=~/^((?:Transfer|Aliquot|Pool)\s*\w*) to (.*)\s*(\(Track New Sample\))?$/) {

    if ( $action =~ /^Decant\b/i ) {
        if ( $current_plate_list =~ /\d/ ) {
            my $decant_type  = param('Decant_Type') || 'Decant_Down_To';    # if decant type not set, set default to be 'Decant_Down_To'
            my $volume       = param('Transfer_Quantity');
            my $volume_units = param('Transfer_Quantity_Units');
            $self->decant( -type => $decant_type, -volume => $volume, -units => $volume_units, -plate_ids => $current_plate_list );
        }
        else { $dbc->warning("No current plates ($current_plate_list)"); }
    }

    # Ensure current plates have been pre-transferred to a new set of plates
    if ( my $det = &alDente::Protocol::new_plate( $action, -include => 'Pre-Print' ) ) {
        $transfer_method = $det->{'transfer_method'};
        my $instance_num    = $det->{'instance_num'}    if $det->{'instance_num'};
        my $new_sample_type = $det->{'new_sample_type'} if $det->{'new_sample_type'};
        my $new_format      = $det->{'new_format'}      if $det->{'new_format'};
        my $focus = $det->{'focus'};    ## 'out to' (retain focus on current plates) or 'to' (change focus to target plates)

        my $change_set_focus = 0;
        if ( $focus eq 'target' ) {
            $change_set_focus = 1;
        }

        $create_new_sample = $det->{'track_new_sample'} if $det->{'track_new_sample'};
        my $new_sample_type_id = $det->{'new_sample_type_id'} if $det->{'new_sample_type_id'};

        my @new_sample_type_ids = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$new_sample_type'" );
        $new_sample_type_id ||= $new_sample_type_ids[0];
        unless ( $new_format =~ /[a-zA-Z]/ ) {
            $new_format = param('Transfer Format');
            $step_name  = "$transfer_method to $new_format";
        }

        my $force = param('Force Transfer') || 0;    ### checkbutton... (not used)

        #if ($transfer_method =~ /\w+\s+(\w+)/) {$new_sample_type = $1}
        my @trans_volume_units;
        my @trans_volumes;

        my $index = 1;
        foreach my $record ( 1 .. $self->{records} ) {
            $split ||= 1;

            #        foreach my $i (1..$split) {
            my $trans_volume      = _return_value( -fields => $self->{plate_field_list}{$index}, -values => $self->{plate_value_list}{$index}, -target => 'Transfer_Quantity' );
            my $trans_volume_unit = _return_value( -fields => $self->{plate_field_list}{$index}, -values => $self->{plate_value_list}{$index}, -target => 'Transfer_Quantity_Units' );
            ( $trans_volume, $trans_volume_unit ) = &Get_Best_Units( -amount => $trans_volume, -units => $trans_volume_unit );
            push @trans_volumes,      $trans_volume      if $trans_volume;
            push @trans_volume_units, $trans_volume_unit if $trans_volume_unit;

            $index++;

            #        }
        }

        my $volume       = Cast_List( -list => \@trans_volumes,      -to => 'string', -autoquote => 0 );
        my $volume_units = Cast_List( -list => \@trans_volume_units, -to => 'string', -autoquote => 0 );

        if ( defined $self->{Completed}{$step_name} ) {
            $volume       ||= $self->{Completed}{$step_name}{'Transfer_Quantity'};
            $volume_units ||= $self->{Completed}{$step_name}{'Transfer_Quantity_Units'};
        }

        ## allow for forced 96-well tracking ##
        my ( $max_size, $quadrants );
        if ( $self->{max_size_tracked} =~ /96/ ) {
            ## cases to handle: Library_Plate_Set->transfer; Prep->_transfer; Prep->pool;
            $max_size  = '96-well';
            $quadrants = 'a,b,c,d';    ## used in Library_Plate_Set->transfer
        }
        ## allow for forced tray tracking for tubes
        my @check_plate_size = $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($current_plate_list)", 'Distinct' );
        if ( int(@check_plate_size) == 1 && $check_plate_size[0] eq '1-well' && !$create_new_sample ) {
            $max_size = '1-well';
        }
        if ( $transfer_method =~ /(Transfer|Convert|Extract|Aliquot)/ ) {
            my $transfer_type;
            if ( $transfer_method =~ /Transfer|Convert/ ) {
                ## potentially convert can be a new type which is an extraction that assumes original is gone (same as transfer)
                $transfer_type = 'transfer';
            }
            elsif ( $transfer_method =~ /Aliquot/ ) {
                $transfer_type = 'aliquot';
            }
            elsif ( $transfer_method =~ /Extract/ ) {
                $transfer_type = 'Extract';
            }
            else {
                Message("Transfer type $transfer_method unrecognized");
            }

            ( $transferred, $new_set ) = $self->_transfer(
                -type               => $transfer_type,
                -ids                => $current_plate_list,
                -format             => $new_format,
                -force              => $force,
                -rack_id            => $rack_id,
                -new_sample_type    => $new_sample_type,
                -new_sample_type_id => $new_sample_type_id,
                -volume             => $volume,
                -volume_units       => $volume_units,
                -split              => $split,
                -create_new_sample  => $create_new_sample,
                -track_transfer     => $track_transfer,
                -pipeline_id        => $new_pipeline_id,
                -max_size           => $max_size,
                -quadrants          => $quadrants,
                -change_set_focus   => $change_set_focus,
            );
            if ($transferred) {
                ##### throw away old plate.. ###
            }
            else {
                Test_Message( "$current_plate_list not Pre-transferred", $testing );

                $pre_transfer_failure = 1;
            }
        }
        elsif ( $transfer_method =~ /^Pool/ ) {
            my %input = %{$input};

            # Pooling
            # Get the pooling quantities and units
            my %details;
            my $pool_type = param('Pool_Type') || $input{'Pool_Type'};    ## Type of pool (Plate,Tube)
            my $pool_x    = param('Pool_X')    || $input{'Pool_X'};       # Number of pool plates to create

            if ( $pool_type eq 'Pool_Plate' ) {
                ( $pooled, $new_set ) = $self->_pool( -pool_type => $pool_type, -ids => $current_plate_list, -pool_x => $pool_x, -format => $new_format );
            }
            else {
                foreach my $plate ( split /,/, $current_plate_list ) {
                    my $quantity = param("Pool_Quantity:$plate") || $input{"Pool_Quantity:$plate"};
                    my $units    = param("Pool_Units:$plate")    || $input{"Pool_Units:$plate"};
                    $details{$plate}{quantity} = $quantity;
                    $details{$plate}{units}    = $units;
                }
                ( $pooled, $new_set ) = $self->_pool( -pool_type => $pool_type, -ids => $current_plate_list, -format => $new_format, -rack_id => $rack_id, -details => \%details, -split => $split, -track_transfer => $track_transfer );
            }

        }
        elsif ( $action =~ /^Pre-Print/i || $action =~ /^Setup/i ) {
            ## <CONSTRUCTION> Should be checked with &alDente::Protocol::new_plate($action,-step_type=>'Pre-Print')
            #
            # Pre-Print barcodes for later automatic transfer (creates Plates in advance)
            #
            my ($plate_type) = $dbc->Table_find( 'Plate', 'Plate_Type', "where Plate_ID in ($current_plate_list)", 'Distinct' );

            my $ok = 0;
            my $Set;
            if ( $plate_type =~ /library/i && $max_size ne "1-well" ) {
                $Set = alDente::Library_Plate_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );
            }
            else {
                $Set = alDente::Container_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );
            }

            $ok = $Set->transfer(
                -ids                => $current_plate_list,
                -format             => $new_format,
                -rack               => $rack_id,
                -preTransfer        => 1,
                -change_set_focus   => $change_set_focus,
                -pipeline_id        => $new_pipeline_id,
                -split              => $split,
                -new_plate_size     => $max_size,
                -new_sample_type_id => $new_sample_type_id,
                -quadrants          => $quadrants,
                -volume             => 0,
            );

            unless ($ok) { return 0; }

            if ( $action =~ /^Setup/i ) {
                $self->reset_focus( $Set->ids(), $Set->{set_number}, -global => 1 );

                #                $self->{plate_ids}  = $Set->ids();
                #                $self->{set_number} = $Set->{set_number};
                $current_plate_list = $self->{plate_ids};
            }
            $self->load_Plates( -ids => $current_plate_list );

            # $dbc->session->message("Printed barcodes");
            Test_Message( $ok, $testing );
            return $transferred || -1;
        }
        else {
            ## standard non-transfer action ##
        }
    }

    else { return $transferred || -1; }

    ### establish Plate_Set

    my $thisplateset = $self->{set_number};

    #if (($step_name=~/^((?:Transfer|Aliquot)\s*\w*)/) && $transferred) {  	## or Aliquot ? }
    if ( ( my $xfer = &alDente::Protocol::new_plate($step_name) ) && $transferred ) {
        ## or Aliquot ?
        #        if ($xfer->{focus} eq 'target') { $thisplateset = $new_set }
    }

    # elsif ($step_name=~/Pool\s*\w* to/i && $pooled) {  						## Pooled }
    elsif ( ( my $xfer = &alDente::Protocol::new_plate($step_name) ) && $pooled ) {
        ## Pooled
        #	if ($xfer->{focus} eq 'target') { $thisplateset = $new_set }
    }
    elsif ($plate_set) {
        $thisplateset = $plate_set;

        unless ($transferred) {
            $dbc->warning("Transfer failed");
            return 0;
        }
    }
    ## Retain Plate_Set Number
    #
    #    Message ($self->{set_number} . " NOT EQUAL " . $thisplateset");
    $self->load_Plates( -set => $thisplateset ) unless $self->{set_number} == $thisplateset;
    return $transferred || -1;
}

#
# retrieves Plates (and Plate_Set) IF they have been pre-printed and are being Transferred.
# (accessed when 'Tranfer to' or 'Aliquot to' step is accomplished)...
# otherwise... Transfer to new plates, reset current_plates, plate_set.
#
########################
sub _transfer {
########################
    my $self               = shift;
    my %args               = @_;
    my $dbc                = $self->{dbc};
    my $these_plates       = $args{-ids};
    my $new_format         = $args{'-format'};
    my $type               = $args{-type};                 ### The type of transfer (transfer or aliquot)
    my $force              = $args{-force};                #### force transfer (even if daughters already exist)
    my $rack_id            = $args{-rack_id};
    my $volume             = $args{-volume};               # volume to be transferred. Used only if Container is a tube.
    my $volume_units       = $args{-volume_units};         # units of the volume to be transferred.  Used only if Container is a tube.
    my $new_sample_type    = $args{-new_sample_type};      # If specified, this means we are creating a new sample (i.e. new original plate/tube) with the specified sample type
    my $new_sample_type_id = $args{-new_sample_type_id};
    my $split              = $args{ -split } || 1;              # number of containers to split originals into per source #
    my $create_new_sample  = $args{-create_new_sample};
    my $track_transfer     = $args{-track_transfer};
    my $new_pipeline_id    = $args{-pipeline_id};
    my $max_size           = $args{-max_size};             ## pass on to Set->transfer to allow forced 96-well tracking
    my $quadrants          = $args{-quadrants};            ## pass on to Set->transfer to allow forced 96-well tracking
    my $change_set_focus   = $args{-change_set_focus};     ## change focus to target plates

    ############### Remove this once the new method is in place... ##########
    if ( $new_sample_type && !$new_sample_type_id ) {
        $new_sample_type_id = $dbc->get_FK_ID( 'FK_Sample_Type__ID', $new_sample_type );
        if ( !$new_sample_type_id ) {
            ($new_sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$new_sample_type'" );
        }
    }

    my $new_format_id = $dbc->get_FK_ID( -field => 'FK_Plate_Format__ID', -value => $new_format );

    my ($old_type) = $dbc->Table_find( 'Plate', 'Plate_Type', "where Plate_ID in ($these_plates)", 'Distinct' );
    my $old_size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($these_plates)", 'Distinct' );
    my $old_format_size = join ',', $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "where Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID in ($these_plates)", 'Distinct' );
    if ( $old_size =~ /,/ ) {
        $dbc->warning("different plate sizes found ! ($old_size)");

        #	return ();
    }
    if ( $old_format_size =~ /,/ ) {
        $dbc->warning("different plate format sizes found ! ($old_format_size)");

        #	return ();
    }

    my @source_plates = split ',', $current_plates;
    my @new_plates;
    if ( $type !~ /Pre-Print/i ) {
        ### Try to figure out if current plates have pre-printed children

        my $condition = "Plate_Status = 'Pre-Printed'";
        if ( $new_format_id      =~ /^\d+$/ ) { $condition .= " AND FK_Plate_Format__ID = $new_format_id" }
        if ( $new_sample_type_id =~ /^\d+/ )  { $condition .= " AND FK_Sample_Type__ID = $new_sample_type_id" }

        my $number_of_plates = int(@source_plates);

        my $total_limit = $number_of_plates * $split;    ## total number of target plates
        my $split_limit = $split;                   ## number to retrieve for EACH source plate

        $split_limit = " LIMIT $split_limit ";                 ## if explicitly indicating target number of plates, then only retrieve this many pre-printed plates ##

        @new_plates;
        foreach my $source_plate (@source_plates) {
            push @new_plates, $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE $condition AND FKParent_Plate__ID = $source_plate ORDER BY FKParent_Plate__ID $split_limit", -debug => 0 );
        }

        ### if not, check if they are themselves pre-printed (for setup)
        if ( !@new_plates ) {

            my %result = $dbc->Table_retrieve( 'Plate', [ 'Plate_ID', 'FKParent_Plate__ID' ], "WHERE Plate_ID in ($these_plates) AND $condition LIMIT $total_limit", -debug => 0 );
            if ( $result{Plate_ID} ) {
                @new_plates = @{ $result{Plate_ID} };
                my @parents = @{ $result{FKParent_Plate__ID} };
                @parents = @{ unique_items( \@parents ) };
                $these_plates = join ',', @parents;
            }
        }
    }

    my $num_preprinted_plates = scalar(@new_plates);
    my $new_plate_list = join ',', @new_plates;    ## NOT necessarily new current plates ....

    #### Reset current plates to most recent daughter plates
    if ( @new_plates && $change_set_focus ) {
        $current_plates = join ',', @new_plates;    ### Moved this from outside the if block
    }
    my @number_plates = split ',', $current_plates;
    my $num_current_plates = scalar(@number_plates);    ### Moved this here from before if() block, and used $current_plates instead of $these_plates

    ### <CONSTRUCTION> - urgent - is this right ? - current plates set to NULL if they are NOT pre-printed ?!...
    my $pack;
    $old_format_size =~ /96/ && $max_size ne "1-well" ? ( $pack = 1 ) : ( $pack = 0 );    ### Only pack if the source plate size is 96.
    if ($force) {
        my $transferred = 0;
        my $new_set     = 0;
        ###### unless already transferred (or transfer forced)... #######
        if ( $old_type =~ /library/i && $max_size ne "1-well" ) {
            my $Set = Library_Plate_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );
            $transferred = $Set->transfer(
                -type              => $type,
                -ids               => $these_plates,
                -format            => $new_format,
                -rack              => $rack_id,
                -pack              => $pack,
                -new_sample_type   => $new_sample_type,
                -split             => $split,
                -create_new_sample => $create_new_sample,
                -pipeline_id       => $new_pipeline_id,
                -new_plate_size    => $max_size,
                -quadrants         => $quadrants,
                -no_print          => $self->{suppress_print},
                -change_set_focus  => $change_set_focus,
            );
            $self->{prev_set} = $self->{set_number};
            $new_set = $Set->set_number();    # $self->{set_number};
            $self->reset_focus( $Set->ids(), $Set->set_number() );

            #            $self->{plate_ids}  = $Set->ids();
            #            $self->{set_number} = $Set->set_number();    ## reset plate set, ids
        }
        else {
            my $Set = alDente::Container_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );
            unless ( $track_transfer eq 'Yes' ) {
                $dbc->message("Transfer $volume $volume_units in prep..");
            }
            $transferred = $Set->transfer(
                -type               => $type,
                -ids                => $these_plates,
                -format             => $new_format,
                -rack               => $rack_id,
                -pack               => $pack,
                -volume             => $volume,
                -volume_units       => $volume_units,
                -new_sample_type    => $new_sample_type,
                -new_sample_type_id => $new_sample_type_id,
                -split              => $split,
                -create_new_sample  => $create_new_sample,
                -track_transfer     => $track_transfer,
                -pipeline_id        => $new_pipeline_id,
                -new_plate_size     => $max_size,
                -quadrants          => $quadrants,
                -no_print           => $self->{suppress_print},
                -change_set_focus   => $change_set_focus,
            );

            $self->{prev_set} = $self->{set_number};
            $new_set = $Set->set_number();

            $self->reset_focus( $Set->ids(), $Set->set_number() );

            #            $self->{set_number} = $Set->set_number();    ## reset plate set, ids
            #            $self->{plate_ids}  = $Set->ids();
            Message("Resetting IDs from $these_plates ($self->{set_number}) TO $Set->ids ($Set->set_number)");

        }

        ### gets new 'current'_plates and new plate set number
        return ( $transferred, $new_set );
    }
    ######## if pre - printed plates exist..
    elsif ( $new_plates[0] =~ /\d+/ ) {

        $dbc->message("Activating previously Pre-Printed $new_format(s). ($new_plate_list)");

        my $fields = [ 'Plate_Status', 'Plate_Created' ];
        my $values = [ 'Active',       &date_time() ];
        ## update sample type if applicable ##
        if ($new_sample_type_id) {
            push @$fields, 'FK_Sample_Type__ID';
            push @$values, $new_sample_type_id;
        }
        if ($new_pipeline_id) { push @{$fields}, 'FK_Pipeline__ID'; push @{$values}, $new_pipeline_id; }
        $dbc->Table_update_array( 'Plate', $fields, $values, "where Plate_ID in ($new_plate_list)", -autoquote => 1 );

        if ($volume) {
            my $v = Cast_List( -list => $volume, -to => 'string', -pad => $split * $num_current_plates );

            my $remove = $v;
            $remove =~ s/,/,\-/g;
            $remove = "-$remove";

            ## if volumes supplied ... update applicable plate volumes ##
            alDente::Container::update_Plate_volumes( -dbc => $dbc, -ids => $new_plate_list, -volume => $v, -units => $volume_units, -initialize => 1);    ## add volumes to new_plate_list
             
            alDente::Container::update_Plate_volumes( -dbc => $dbc, -ids => $these_plates, -volume => "$remove", -split=>$split, -units => $volume_units);                 ## subtract volumes from old_plate_list
        }
        elsif ( !$volume && ( !$split || $type =~ /transfer/i ) ) {                                                                                         #transfer all the volumes
            my @new_ids = Cast_List( -list => $new_plate_list, -to => 'array' );
            my @old_ids = Cast_List( -list => $these_plates,   -to => 'array' );
            if ( int(@new_ids) == int(@old_ids) ) {
                my $index = 0;
                foreach my $old_id (@old_ids) {
                    my ( $t_volume, $t_volume_units ) = alDente::Container::empty_Plate_volumes( -dbc => $dbc, -ids => $old_id );
                    alDente::Container::update_Plate_volumes( -dbc => $dbc, -ids => @new_ids[$index], -volume => $t_volume, -units => $t_volume_units, -initialize => 1);    ## add volumes to new_plate_list
                    $index++;
                }
            }
        }

        if ( $type =~ /transfer/i ) {
            Message("Throw away $these_plates");
            alDente::Container::throw_away( -ids => $these_plates, -set => $self->identical_set($these_plates), -dbc => $dbc, -confirmed => 1 );
        }
    }
    else {
        my $transferred = 0;
        my $new_set     = 0;
        my $Set;

        my %transfer = (
            -type               => $type,
            -ids                => $these_plates,
            -format             => $new_format,
            -rack               => $rack_id,
            -pack               => $pack,
            -new_sample_type    => $new_sample_type,
            -new_sample_type_id => $new_sample_type_id,
            -split              => $split,
            -create_new_sample  => $create_new_sample,
            -track_transfer     => $track_transfer,
            -pipeline_id        => $new_pipeline_id,
            -new_plate_size     => $max_size,
            -quadrants          => $quadrants,
            -no_print           => $self->{suppress_print},
            -change_set_focus   => $change_set_focus,
        );

        if ( $old_type =~ /library/i && $max_size ne "1-well" ) {
            $Set = alDente::Library_Plate_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );
        }
        else {
            $Set = alDente::Container_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );

            $transfer{-volume}       = $volume;
            $transfer{-volume_units} = $volume_units;
        }

        if ( $track_transfer eq 'Yes' ) {
            $dbc->message("Transfer $volume $volume_units in prep..");
        }

        $transferred = $Set->transfer(%transfer);

        if ($change_set_focus) {
            $self->{prev_set} = $self->{set_number};
            $self->reset_focus( $transferred, $Set->{set_number}, -global => 1 );
            $self->load_Plates( -set => $Set->set_number ) unless $self->{set_number} == $Set->set_number;
        }

        $new_set = $self->{set_number};
        return ( $transferred, $new_set );
    }

    ####### (continues only if pre-printed plates ..) ########

    if ( $num_preprinted_plates != $num_current_plates ) {

        #        $dbc->session->warning("(Check: $num_current_plates plates to transfer, $num_preprinted_plates activated)");
    }

    ########## find plate sets containing daughters (with unchanging # of plates) ########
    my @new_sets = $dbc->Table_find(
        'Plate_Set, Plate_Set as FPS',
        'Plate_Set.Plate_Set_Number,count(Distinct FPS.FK_Plate__ID)',
        "where Plate_Set.Plate_Set_Number=FPS.Plate_Set_Number AND Plate_Set.FK_Plate__ID in ($current_plates) group by Plate_Set.Plate_Set_Number having count(Distinct FPS.FK_Plate__ID) = $num_current_plates Order by Plate_Set.Plate_Set_ID desc"
    );
    my $sets = scalar(@new_sets);

    my $container_set_obj = new alDente::Container_Set( -dbc => $dbc, -ids => $current_plates );
    if ( !$change_set_focus ) { return ($new_plate_list) }
    ## continue to reset focus to new plate set ##

    if ( $sets == 1 ) {
        ( my $new_set, my $new_count ) = split ',', $new_sets[0];
        if ( $new_count == $num_preprinted_plates ) {
            my $old_plate_set = $plate_set;
            $plate_set = $new_set;
            $dbc->message("New Working Container Set: $plate_set");
            ########## reset current plates (in case more daughters were found) ######
            $current_plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "where Plate_Set_Number = $plate_set ORDER BY Plate_Set_ID" );    ## original order

            $self->{prev_set} = $self->{set_number};
            $self->load_Plates( $current_plates, $plate_set );                                                                                           ## Re-load Plate info...
                                                                                                                                                         # NEW CODE - TEST !!!
            $self->reset_focus( $current_plates, $new_set, -global => 1 );

            #return ($current_plates,$old_plate_set);   ### was new_set or old_set ??
            return ( $current_plates, $new_set );                                                                                                        ### was new_set or old_set ??
        }
        else {
            $dbc->warning("Plate Set ambiguous");
            if ( $container_set_obj->_recover_Set() ) { return (); }
            else {                                                                                                                                       #### if you need to choose a plate set
                return ();
            }
        }
    }
    elsif ( !$sets ) {
        $dbc->message("Create New Plate Set");
        if ( my $set = $container_set_obj->save_Set( -recover => 1 ) ) { $self->reset_focus( $current_plates, $set ); return ( $current_plates, $set ); }
        else                                                           { }
    }
    else {
        $dbc->message("$sets Sets found for these Plates $new_sets[0]..$new_sets[1]");
        if   ( $container_set_obj->_recover_Set() ) { return (); }
        else                                        { return (); }
    }

    return ();
}

###########################
#
# Handles sample pooling
#
###########################
sub _pool {
#############
    my $self = shift;
    my %args = @_;

    my $these_plates = $args{-ids};
    my $new_format   = $args{'-format'};
    Message("New Format $new_format");
    my $new_type  = $args{-type};
    my $rack_id   = $args{-rack_id};
    my $details   = $args{-details};
    my $pool_type = $args{-pool_type};
    my $pool_x    = $args{-pool_x};

    my $dbc             = $self->{dbc};
    my $new_sample_type = $args{-new_sample_type};

    my @parent_sample_types;
    unless ($new_sample_type) {
        my @parent_sample_types = $dbc->Table_find( 'Plate,Sample_Type', 'distinct Sample_Type', "WHERE Plate_ID IN ($these_plates) AND FK_Sample_Type__ID = Sample_Type_ID" );

        #if ( int(@parent_sample_types) == 0 || ( grep /^0$/, @parent_sample_types ) ) { @parent_sample_types = $dbc->Table_find( 'Plate', 'distinct Plate_Content_Type', "WHERE Plate_ID IN ($these_plates)" ); }

        if    ( scalar(@parent_sample_types) > 1 )  { $new_sample_type = 'Mixed' }
        elsif ( scalar(@parent_sample_types) == 1 ) { $new_sample_type = $parent_sample_types[0] }

    }

    # Look for pre-printed plates if any
    my @new_plates = $dbc->Table_find( 'Plate', 'Plate_ID', "where FKParent_Plate__ID in ($these_plates) and Plate_Status = 'Pre-Printed' order by FKParent_Plate__ID" );
    my $plates = scalar(@new_plates);

    my $current_num = int( my @plate_list = split ',', $these_plates );
    #### Reset current plates to most recent daughter plates

    ## $current_plates = join ',',@new_plates;
    ## $self->load_Plates($current_plates);    ## Re-load Plate info...

    ######## if pre - printed plates exist..
    my $new_set = 0;
    my $pooled;
    my $Set = alDente::Container_Set->new( -dbc => $self->{dbc}, -set => $self->{set_number} );

    if ( $pool_type eq 'Pool_Plate' ) {

        my $pool_index = 0;
        my %pool_plates;
        my $index = 0;

        my $num_plates = int(@plate_list);

        my $result = $num_plates % $pool_x;
        if ( $result != 0 ) {
            $dbc->warning("Cannot pool plates, please check number of plates and target number of pooled plates");
            return ();
        }
        $pool_x = $num_plates / $pool_x;

        foreach my $plate (@plate_list) {
            if ( $index == $pool_x ) {
                $pool_index++;
                $index = 0;
            }
            push @{ $pool_plates{$pool_index} }, $plate;
            $index++;
        }

        my @pooled_plates = ();
        foreach my $pool_set ( sort { $a <=> $b } keys %pool_plates ) {
            if ( &alDente::Container::validate_pool( -dbc => $dbc, -plate_ids => $pool_plates{$pool_set}, -format => $new_format, -is_tray => 1 ) ) {
                my $id = &alDente::Container::pool_tray( -dbc => $dbc, -plate_ids => $pool_plates{$pool_set}, -format => $new_format );
                if ($id) { my @ids = split( ",", $id ); push @pooled_plates, @ids; }
            }
            else {
                my $id = $Set->pool_identical_plates( -plate_ids => $pool_plates{$pool_set}, -format => $new_format, -pool_x => 1 );
                push @pooled_plates, $id if $id;
            }
        }
        unless (@pooled_plates) {
            return ();
        }

        my $new_plate_set_number = $Set->_next_set();
        $Set->set_number($new_plate_set_number);
        $plate_set = $new_plate_set_number;
        foreach my $id (@pooled_plates) {
            my $new_set_created = $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$id,$new_plate_set_number,$self->{set_number}", -autoquote => 1 );
        }
        $pooled = join ',', @pooled_plates;
        $Set->ids($pooled);
    }
    else {
        if ( $new_plates[0] =~ /\d+/ ) {
            $pooled = $Set->pool_to_tube( -ids => $these_plates, -format => $new_format, -rack => $rack_id, -pre_printed => 1, -details => $details, -new_sample_type => $new_sample_type );
        }
        else {
            $pooled = $Set->pool_to_tube( -ids => $these_plates, -format => $new_format, -rack => $rack_id, -pre_printed => 0, -details => $details, -new_sample_type => $new_sample_type );
        }

        my $new_plate_set_number = $Set->_next_set();
        $Set->set_number($new_plate_set_number);
        $plate_set = $new_plate_set_number;
        my $new_set_created = $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$pooled,$new_plate_set_number,$self->{set_number}", -autoquote => 1 );

        $Set->ids($pooled);

    }

    ## <CONSTRUCTION>  I think this is what was desired, but not positive. (otherwise, current plates not properly reset to new pooled plates)
    ## (added next three lines; removed lines commented out above ##
    $current_plates = $pooled;
    $self->load_Plates($pooled);
    Message("Pooled -> $pooled");

    $self->{prev_set} = $self->{set_number};

    #    $self->{set_number} = $Set->set_number();    ## reset plate set, ids
    $new_set = $self->{set_number};

    #    $self->{plate_ids}  = $Set->ids();
    $self->reset_focus( $Set->ids(), $Set->set_number() );

    return ( $pooled, $new_set );
}

#######################
#
# Ensure input meets format requirements...
#
########################
sub _check_Formats {
########################
    my $self       = shift;
    my $parameters = shift;
    my $dbc        = $self->{dbc};

    my %input = %{$parameters} if $parameters;

    my $step = $self->{Step}->{ $self->{thisStep} };

    my @inputs  = split ':', $self->{Input}->{ $self->{thisStep} };
    my @defs    = split ':', $self->{Default}->{ $self->{thisStep} };
    my @formats = split ':', $self->{Format}->{ $self->{thisStep} };
    my $validate = $self->{Validate}->{ $self->{thisStep} };

    my $current_plates_list = $current_plates || $input{'Current Plates'} || $self->{plate_ids};
    ## Validate QC if applicable ##
    unless ( $self->QC_validate() ) {
        $dbc->warning("Failed QC validation");
        return 0;
    }

    ### Check standard formats if specified... ###
    my $solutions_used = '';
    my @solution_list;
    foreach my $index ( 0 .. $#inputs ) {
        my $formats = $formats[$index];
        my $inputs  = $inputs[$index];
        ########## Check Equipment #############
        if ( $inputs[$index] =~ /^FK_Equipment__ID/ ) {

            #my @machines = split ',', $input{FK_Equipment__ID};

            if ( ( $input{FK_Equipment__ID} ) && ( !( ( $input{FK_Equipment__ID} =~ /equ/i ) || ( $input{FK_Equipment__ID} =~ /^\d+$/i ) ) ) ) {
                $dbc->warning("$input{FK_Equipment__ID} is not an equipment");
                return 0;
            }

            my @machines = Cast_List(
                -list     => &get_aldente_id( $dbc, $input{FK_Equipment__ID}, 'Equipment', -validate => 1, -allow_repeats => 1 ),
                -pad_mode => 'Stretch',
                -to       => 'array',
                -default  => 0
            );

            foreach my $number ( 1 .. int(@machines) ) {
                my $id = $machines[ $number - 1 ];    ##### get Equipment ID
                unless ( $machines[ $number - 1 ] ) {next}    ##### ignore if no equipment ID

                unless ( $id =~ /\d+/ ) {
                    $dbc->warning("Invalid ID : $machines[$number-1] ?");
                    return 0;
                }

                ( my $type ) = $dbc->Table_find_array(
                    'Equipment,Equipment_Category,Stock,Stock_Catalog',
                    ["Concat(Category,' - ',Sub_Category)"],
                    "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_ID in ($id)"
                );
                if ( ( defined $formats ) && ( defined $formats[$index] ) && $formats[$index] ) {
                    my $expected = $formats[$index];
                    unless ( $type =~ /$formats[$index]/i ) {
                        $expected =~ s/\|/ OR /g;
                        $dbc->warning("<B>** Use $expected **</B> Equ$id is a $type.");
                        return 0;
                    }
                }
            }
        }

        ################ Check Solution Formats ##################
        elsif ( $inputs[$index] =~ /^FK_Solution__ID/ ) {

            #my @sols = split ',', $input{'FK_Solution__ID'};

            if ( $input{FK_Solution__ID} && ( !( ( $input{FK_Solution__ID} =~ /sol/i ) || ( $input{FK_Solution__ID} =~ /\d+/i ) ) ) ) {
                $dbc->warning("$input{FK_Solution__ID} is not a solution");
                return 0;
            }

            my @sols = Cast_List(
                -list     => &get_aldente_id( $dbc, $input{FK_Solution__ID}, 'Solution', -validate => 1, -qc_check => 1, -fatal_flag => 1, -allow_repeats => 1 ),
                -pad_mode => 'Stretch',
                -to       => 'array',
                -default  => 0
            );

            my @input_sols = Cast_List(
                -list     => &get_aldente_id( $dbc, $input{FK_Solution__ID}, 'Solution', -allow_repeats => 1 ),
                -pad_mode => 'Stretch',
                -to       => 'array',
                -default  => 0
            );

            my $is_equal = RGmath::xor_array( \@input_sols, \@sols );

            if ( ( @{$is_equal} ) && ( $sols[0] != 0 ) ) {    ###Input and output are different, error
                $dbc->error("You have put in Invalid Solutions : @$is_equal. Please remove the invalid solutions and try again.");
                return 0;
            }

            @solution_list = @sols;
            foreach my $number ( 1 .. int(@sols) ) {
                my $id = $sols[ $number - 1 ];                ##### get Valid Solution ID
                unless ( $sols[ $number - 1 ] ) {next}        ##### ignore if no Solution ID
                unless ( $id =~ /\d+/ ) {
                    $dbc->warning("Invalid ID : $sols[$number-1] ?");
                    return 0;
                }
                ( my $name ) = $dbc->Table_find( 'Stock_Catalog,Solution left join Stock on FK_Stock__ID=Stock_ID', 'Stock_Catalog_Name', "where Solution_ID in ($id) AND FK_Stock_Catalog__ID =Stock_Catalog_ID" );
                unless ($name) { ($name) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Solution_ID in ($id)" ) }

                $solutions_used .= "$name,";                  ### keep track of solution_name list..
                if ( ( defined $formats ) && ( defined $formats[$index] ) && $formats[$index] ) {
                    ## Check if the solution is a primer plate <CONSTRUCTION>

                    unless ( $name =~ /$formats[$index]/i ) {
                        $dbc->error( "Error: Sol$id ($name) should contain '$formats[$index]'" . '. Try again....' );
                        return 0;
                    }
                }
            }
        }
    }

    ################ Check Antibiotic Marker ################

    my $AB_test = 'Antibiotic';    ## $Track{Antibiotic};
    if ( $AB_test && $step =~ /$AB_test/i ) {    ######### check for proper antibiotic  ** Sequencing Specific **
        my $trans = '';
        my @antibiotics;
        my @problems;

        my @plates = split( ',', $current_plates_list );
        my $curr_plate = '';
        foreach my $plate (@plates) {
            $curr_plate = $plate;
            if ( $step =~ /poson/i ) {           #### if Xposon or Transposon in step name ####
                @antibiotics = $dbc->Table_find_array(
                    'Plate,Library_Source,Transposon_Pool,Transposon', ['Antibiotic_Marker'], "WHERE Plate.FK_Library__Name=Library_Source.FK_Library__Name AND Library_Source.FK_Source__ID=Transposon_Pool.FK_Source__ID AND FK_Transposon__ID=Tra
                                                                                                                       nsposon_ID AND Plate_ID in ($plate)", -distinct => 1
                );
                ## if there are no valid transposon antibiotics, give a warning but continue
                if ( int(@antibiotics) == 0 ) {
                    $dbc->warning("No transposon antibiotics defined for plate $curr_plate");
                    push @problems, "No transposon antibiotics defined for plate $curr_plate";
                    next;
                }
                ## Check solution against list of suggested antibiotics for the library
                my @libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID in ($plate)", -distinct => 1 );

                my $library_antibiotics = alDente::LibraryApplication->new( -dbc => $dbc );
                my $ok = $library_antibiotics->validate_application( -library => \@libraries, -object_class => 'Antibiotic', -value => $solutions_used, -valid_values => \@antibiotics );
                if ( !$ok ) {
                    push @problems, "Validation of sol: $solutions_used application failed for $curr_plate";
                }

                $trans = 'Transposon';    #### just to include in message below
            }
            else {
                ## Check solution against list of suggested antibiotics for the library
                my @libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID in ($plate)", -distinct => 1 );
                my $library_antibiotics = alDente::LibraryApplication->new( -dbc => $dbc );

                my $ok = $library_antibiotics->validate_application( -library => \@libraries, -object_class => 'Antibiotic', -value => $solutions_used );
                if ( !$ok ) {
                    push @problems, "$solutions_used Validation failed for @libraries";
                }

                if ( $library_antibiotics->{valid_values} && ( ref $library_antibiotics->{valid_values} ) eq 'ARRAY' ) {
                    @antibiotics = @{ $library_antibiotics->{valid_values} };
                }
            }
        }

        if (@problems) {
            foreach my $problem (@problems) {
                $dbc->error($problem);
            }
            return 0;
        }
    }

################ Check Primer ################
    ### Can be generalized

    #### <CONSTRUCTION> ####
    ### Currently sequencing specific. ie check for valid primers if user is part of sequencing group
    #    my $groups = $dbc->get_local('group_list');
    #    my %seq_grps;
    #    %seq_grps = Table_retrieve($dbc,'Grp',['Grp_ID','Grp_Name'],"WHERE Grp_ID IN ($groups) AND Grp_Name like 'Sequencing%'") if($groups);
    #

    my @validations = ();
    push @validations, $validate if $validate;    ## only really necessary to preset this in cases where NO Associations are yet defined for the given library.

    my $libraries = join "','", $dbc->Table_find( "Plate", "FK_Library__Name", "WHERE Plate_ID IN ($current_plates_list)" );

    ## Standard Prep outside of protocol
    #	@validations = ();
    my @possible_validations = ( 'Enzyme', 'Primer', 'Antibiotic' );

    ## turn on validation for reagent types that have at least one 'suggested' reagent defined (forces validation) ##
    foreach my $validating (@possible_validations) {
        ## associations already defined ##
        my @suggested = $dbc->Table_find( 'LibraryApplication,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = '$validating' AND FK_Library__Name IN ('$libraries')" );
        if (@suggested) {
            ## at least one specified association exists -> perform validation checking for this type ##
            push @validations, $validating unless grep /^$validating$/, @validations;
        }
    }

    foreach my $validate_class (@validations) {
        my @sols = &alDente::Solution::get_original_reagents( $dbc, join( ',', @solution_list ), -class => $validate_class );
        if ( int(@sols) == 0 ) {
            if ( $validate eq $validate_class ) {
                ## validation explicitly requested ##
                $dbc->error("No valid $validate_class found in applied solution");
                return 0;

                #		next;
            }
            else {
                ## no applicable reagents ... skip validation ##
                next;
            }
        }

        my @applied_names = $dbc->Table_find( "Stock_Catalog,Stock,Solution", "Stock_Catalog_Name", "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID AND Solution_ID in (" . join( ',', @sols ) . ")", -distinct => 1 );
        my $applied_name_list = join "','", @applied_names;

        # check foreach plate
        foreach my $plate ( split( ',', $current_plates_list ) ) {
            my ($library) = $dbc->Table_find( "Plate", "FK_Library__Name", "WHERE Plate_ID = $plate" );
            my $lib_apps = alDente::LibraryApplication->new( -dbc => $dbc, -library => $library );

            my $ok = $lib_apps->validate_application( -object_class => $validate_class, -value => \@applied_names );
            my @ok_apps = @{ $lib_apps->{valid_values} };
            unless (@ok_apps) {
                $dbc->error("$applied_name_list Not a valid $validate_class for $library library");
                return 0;
            }
            unless ($ok) {
                my @types = 'Standard';
                if ( $validate_class =~ /Primer/ ) { @types = $dbc->Table_find( 'Primer', "distinct Primer_Type", "WHERE Primer_Name in ('$applied_name_list')" ) }

                if ( ( $applied_name_list =~ /^Custom/i ) && ( grep /^Custom$/i, @ok_apps ) ) { }    ## ignore if applying custom items (if custom items are valid) ##
                elsif ( grep /Standard/, @types ) {
                    $dbc->error( "'$applied_name_list' not a valid $validate_class for '$library'. <BR> Valid $validate_class options: '" . join( "','", @ok_apps ) . "'" );
                    return 0;
                }
            }
        }
    }

    return 1;
}

# Check for mandatory inputs such as Equipment ID, Solution_ID
#
#
########################
sub _check_Mandatory {
########################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'parameters' );
    my $parameters = $args{-parameters};                                 ## INPUT params to be checked
    my %input      = %{$parameters} if $parameters;
    my @inputs     = split ':', $self->{Input}->{ $self->{thisStep} };
    my $dbc        = $self->{dbc};

    if ( $Input{'rm'} eq "Skip Step" ) {
        ### Don't need to check for mandatory fields if this step is being skipped
        return 1;
    }

    foreach my $input (@inputs) {
        if ( $input =~ /^Mandatory_Equipment/ ) {
            unless ( get_aldente_id( -dbc => $dbc, -barcode => $input{FK_Equipment__ID}, -table => 'Equipment', -validate => 1, -allow_repeats => 1 ) ) {
                $dbc->warning("Please scan in equipment(s) - this is a Mandatory step");
                return 0;
            }
        }
        elsif ( $input =~ /^Mandatory_Solution/ ) {
            unless ( get_aldente_id( -dbc => $dbc, -barcode => $input{FK_Solution__ID}, -table => 'Solution', -validate => 1, -qc_check => 1, -fatal_flag => 1, -allow_repeats => 1 ) ) {
                $dbc->warning("Please scan in solution(s) - this is a Mandatory step");
                return 0;
            }
        }
        elsif ( $input =~ /^Mandatory_Rack/ ) {
            unless ( get_aldente_id( -dbc => $dbc, -barcode => $input{FK_Rack__ID}, -table => 'Rack', -validate => 1, -qc_check => 1, -fatal_flag => 1, -allow_repeats => 1 ) ) {
                $dbc->warning("Rack location is mandatory for this step");
                return 0;
            }
        }
        elsif ( $input =~ /^Mandatory_(\w+)Attribute_(\w+)/ ) {
            my $attr_class = $1;
            my $attr_name  = $2;
            unless ( length( $input{$attr_name} ) > 0 ) {
                ## check cases that 'ATTxxx' is used instead of attribute name
                my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = '$attr_name' AND Attribute_Class = '$attr_class' " );
                unless ( length( $input{"ATT$attribute_id"} ) > 0 ) {
                    $dbc->warning("$attr_class Attribute $attr_name is mandatory for this step");
                    return 0;
                }
            }

        }

    }

    return 1;
}

##############################
# private_functions          #
##############################

###############
sub _update_cell {
###############
    my $link      = shift;
    my $preps     = shift;
    my $count     = shift;
    my $sets      = shift;
    my $time      = shift;
    my $sol       = shift;
    my $equip     = shift;
    my @solutions = @{$sol} if $sol;
    my @equipment = @{$equip} if $equip;

    my $used = '';
    if (@solutions) { $used .= "@solutions<BR>"; }
    if (@equipment) { $used .= "@equipment<BR>"; }
    my $cell = "<B>$link</B><BR>$preps ($count plates)<BR>Set:$sets<BR>$used$time";
    return $cell;
}

############
sub _check_Input {
############
    #
    # Thaw Prep object from session
    #
    my $self  = shift;
    my %args  = @_;
    my $dbc   = $self->{dbc};
    my $input = defined $args{-input} ? $args{-input} : \%Input;    ## reference to hash containing input parameters

    if ($input) { %Input = %{$input}; }

    #Message($self->{protocol_name});
    my $step = $self->{Step}->{ $self->{thisStep} };
    my $action;

    ## Save self Step information ##
    my $ok = 0;

    if ( $Input{'Save Prep Step'} ) {
        $action = 'Completed';
        $ok = $self->Record( -step => $step, -action => $action, -input => $input );
    }
    elsif ( $Input{'Skip Prep Step'} ) {
        $action = 'Skipped';
        $ok = $self->Record( -step => $step, -action => $action, -input => $input );
    }
    elsif ( $Input{'Annotate Prep Plate'} ) {
        my $note = $Input{'Prep Plate Note'};
        $self->annotate_Plates( -note => $note );
    }

    #Remove plates from plate set, and fail them for this step
    elsif ( $Input{'RemovePlateFailPrep'} ) {
        if ( $Input{'Plates To Fail Prep'} eq '' ) {
            ### The user is trying to fail all the plates, ask for confirmation
            if ( $Input{'Confirm Fail'} ) {

                # Fail all of current plates
                my $plate_ids = &get_aldente_id( $dbc, $Input{'Current_Plates'}, 'Plate', -validate => 1 );
                $ok = $self->fail_Plate( -ids => $plate_ids, -step => $step, -note => $Input{'Prep Plate Note'} );
            }
            else {
                return $self->prompt_User( -confirm_fail => 1 );
            }
        }
        else {
            ### The user is only failing a set of plates, check to see if plates are in Current_Plates

            my $plate_ids = get_aldente_id( $dbc, $Input{'Plates To Fail Prep'}, 'Plate' );

            # Check to see if requested plates exist in the current plates list
            my @Current_Plates = split( ',', $Input{'Current_Plates'} );
            my @ToFail         = split( ',', $plate_ids );
            my @invalids;
            foreach my $id (@ToFail) {
                if ( !grep( /^$id$/, @Current_Plates ) ) {
                    push( @invalids, $id );
                }
            }
            if (@invalids) {
                my $ids = join ',', @invalids;
                Message("Plate(s) $ids not in the current plate set.");
            }
            else {
                $ok = $self->fail_Plate( -ids => $plate_ids, -step => $step, -note => $Input{'Prep Plate Note'} );
            }
        }
    }
    elsif ( $Input{'Prep Instructions'} ) {
        my $prompted = $self->prompt_User( -instructions => 1 );
        return $prompted;
    }
    elsif ( $Input{'Check History'} ) {
        my $prompted = $self->check_History();
        return $prompted;
    }
    elsif ( $Input{'Repeat last step'} ) {
        my $prev_step = $self->{thisStep};
        $prev_step = --$prev_step;
        my $prev_step_name = $self->{Step}->{$prev_step};
        $dbc->message("Repeating step $prev_step_name");
        my $prompted = $self->prompt_User( -step_num => $prev_step, -repeat_last_step => 1 );
        return $prompted;
    }
    elsif ( $Input{'Prep_RePrint_Barcode'} ) {

        my $barcode_name = $Input{'Barcode Name'};
        my $curr_plates  = $Input{Current_Plates};
        my %printed_trays;
        foreach my $curr_id ( split( ',', $curr_plates ) ) {
            if ( my $tray_id = &alDente::Tray::exists_on_tray( $dbc, 'Plate', $curr_id ) ) {
                unless ( $printed_trays{$tray_id} ) {
                    &alDente::Barcoding::PrintBarcode( $dbc, 'Tray', $curr_id, 'print,library_plate' );
                    $printed_trays{$tray_id} = 1;
                }
            }
            else {
                &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $curr_id );
            }
        }
    }
    else { Call_Stack(); $dbc->message("Nothing"); print HTML_Dump $input; }

    if ( $action && $ok ) {

        # Get info regarding previous step
        my $prev_step = $self->{Step}->{ $self->{thisStep} };
        if ( $action !~ /Completed/ ) { $dbc->message("$action step '$prev_step'<br>") }
        if ( $input->{FK_Solution__ID} && $action ne 'Skipped' ) {
            $dbc->message("Applied solution $input->{FK_Solution__ID}<BR>");
        }
        $self->load_Preparation();
    }
    return;
}

###################################################################
# Update the volume of the plate or tube when applying solutions
# <snip>
#    _update_vol_solution(-plates=>$plate_list, -solutions=>\@solutions, -sol_qty_units=>$sol_qty_units,-volumes=>$volume);
# </snip>
# Return: 1 on success
##########################
sub _update_vol_solution {
##########################

    my %args = filter_input( \@_, -args => 'plates,solutions,volumes' );
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_list    = $args{-plates};                                                                  ## Plates/Tubes
    my $solutions     = $args{-solutions};                                                               ## Solution IDs
    my $sol_qty_units = $args{-sol_qty_units};                                                           ## Solution Units
    my $volumes       = $args{-volumes};                                                                 ## volume of Solution

    my @plate_list = Cast_List( -list => $plate_list, -to => 'Array' );
    my $plate_count = int(@plate_list);

    my $pad = $plate_count;

    my @solutions = Cast_List( -list => $solutions,     -to => 'Array', -pad => $pad, -pad_mode => 'Stretch' );
    my @units     = Cast_List( -list => $sol_qty_units, -to => 'Array', -pad => $pad );
    my @volumes   = Cast_List( -list => $volumes,       -to => 'Array', -pad => $pad, -pad_mode => 'Stretch' );

    my $solutions_list = join ',', @solutions;

    # Get the current Solution Volume
    #    my @curr_sol_qty = $dbc->Table_find('Solution', 'Solution_Quantity',"WHERE Solution_ID in ($solutions_list)");

    my $index = 0;

    foreach my $plate (@plate_list) {
        my ($plate_info) = $dbc->Table_find( "Plate,Plate_Format", "Current_Volume,Current_Volume_Units,Wells", "WHERE Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID =$plate" );
        my ( $curr_quantity, $curr_quantity_units, $wells ) = split ',', $plate_info;

        #if (!$curr_quantity) { next; }  ## undefined current quantity
        #elsif (!$volumes[$index])     { $dbc->session->warning("Sample qty not tracked (no volume)"); next; }
        #elsif (!$curr_quantity_units) { $dbc->session->warning("Current sample amount has no units (not tracking)"); next; }
        #elsif (!$units[$index])       { $dbc->session->warning("Added amount has no units (not tracking)"); next; }
        if    ( !$volumes[$index] )     { $dbc->warning("Sample qty not tracked (no volume)");                next; }
        elsif ( !$curr_quantity_units ) { $dbc->warning("Current sample amount has no units (not tracking)"); next; }
        elsif ( !$units[$index] )       { $dbc->warning("Added amount has no units (not tracking)");          next; }

        $units[$index] =~ /(g|l)/i;
        my $units_base_units = $1;

        $curr_quantity_units =~ /(g|l)/i;
        my $current_base_units = $1;

        if ( $current_base_units =~ /g/ ) {
            $dbc->warning("Not tracking sample qty (mass)");
            next;
        }
        elsif ( !$current_base_units ) {
            $dbc->warning("Unrecognized base units (not tracking sample qty)");
            next;
        }
        elsif ( lc($current_base_units) ne lc($units_base_units) ) {
            $dbc->warning("Added amt type ($units_base_units) different from current units ($current_base_units) (not tracking sample qty)");
            next;
        }

        # Normalize the units to mL for the for the solution

        ( $volumes[$index], $units[$index] ) = &convert_to_mils( $volumes[$index], $units[$index] );

        # Update the volume in the solution

        if ( !defined $curr_quantity ) { $curr_quantity = 0; $curr_quantity_units = 'ml'; }    ## default to empty containers if volume now being added

        if ( $solutions[$index] ) {
            ## update solution quantity used
            if ( $volumes[$index] ) {
                ## DO NOT use this statement because if the Quantity_Used in database is NULL, it will not get updated
                #$dbc->Table_update_array( 'Solution', ['Quantity_Used'], ["Quantity_Used + $volumes[$index]*$wells"], "where Solution_ID=$solutions[$index]" );

                my ($qty_used_in_record) = $dbc->Table_find( 'Solution', 'Quantity_Used', "where Solution_ID=$solutions[$index]" );
                my $qty_used_value = $qty_used_in_record + $volumes[$index] * $wells;
                $dbc->Table_update_array( 'Solution', ['Quantity_Used'], [$qty_used_value], "where Solution_ID=$solutions[$index]" );
            }
        }
        if ( defined $curr_quantity ) {
            unless ($curr_quantity_units) {
                $dbc->warning("Units must be specified, volume not tracked for this tube/plate");
                next;
            }

            # Normalize the units to mL for the plate

            ( $curr_quantity, $curr_quantity_units ) = &convert_to_mils( $curr_quantity, $curr_quantity_units );
            my $updated_plate_vol = $curr_quantity + $volumes[$index];

            # Update the Volume in the plate
            ( $updated_plate_vol, $units[$index] ) = &Get_Best_Units( -amount => $updated_plate_vol, -units => $units[$index] );

            ### CONSTRUCTION : put this in a transaction..

            $dbc->Table_update_array( 'Plate', [ 'Current_Volume', 'Current_Volume_Units' ], [ $updated_plate_vol, $units[$index] ], "where Plate_ID = $plate", -autoquote => 1 );

        }
        $index++;
    }
    return 1;
}

############
sub _get_from {
############
    #
    # routine to extract a subset from a list.
    # eg to get the groups of three from a list of 6 :
    #
    my $list             = shift;    ## eg. '12,13,14,15,16,17'
    my $number_of_groups = shift;    ## group size (eg 3)
    my $get_group        = shift;

    my @array = split ',', $list;

    my $group_size = int(@array) / $number_of_groups;

    my %Group;
    my $group = 0;
    foreach my $index ( 0 .. $#array ) {
        my $group = int( $index / $group_size ) + 1;
        push( @{ $Group{$group} }, $array[$index] );
    }

    my @groups = ($list);
    foreach my $group ( keys %Group ) {
        $groups[$group] = join ',', @{ $Group{$group} };
    }
    return $groups[$get_group];
}

########################################
#
# Expands asterikes (*) in barcode
#
# <snip>
#   my $var = 'sol3equ5*3mul23equ10*2pla40';
#   print expand_multiples($var);
#
#   (converts pla2*2pla3 -> pla2pla2pla3)
#   will print: sol3equ5equ5equ5mul23equ10equ10pla40
# </snip>
#
####################
sub _expand_multiples {
####################
    my %args   = &filter_input( \@_, -args => 'input' );
    my $input  = $args{-input};
    my $outstr = $input;
    my $limit  = 100;                                      ## limit on expansion (in case of types eg. pla3*222)

    while ( $outstr =~ /([\w\.]+)(\*)(\d+)/i ) {           ## pattern = ABC123*<num>
        my $object = $1;
        my $repeat = $3;

        if ( $repeat > $limit ) { Message("Warning: cannot expand > $limit at one time !"); $repeat = 1; }

        my $replacement = ( $object . ',' ) x $repeat;
        $outstr =~ s/$object\*$repeat/$replacement/;
    }
    $outstr =~ s/,,/,/g;
    $outstr =~ s/,$//;
    return $outstr;
}

###############################################
# Warn the user to scan in plates in temporary
#
#
##############################
sub _plates_to_be_scanned {
##############################
    my $self         = shift;
    my $dbc          = $Connection;
    my %args         = filter_input( \@_ );
    my $default_rack = $args{-default_rack};

    my $output;
    my @step_names = values %{ $self->{Step} };    #->{Input};

    my @prep_ids;
    my @plate_ids;

    if ( $self->{Completed} ) {
        foreach my $step_name (@step_names) {
            my $prep_id = $self->{Completed}{$step_name}{Prep_ID};
            push( @prep_ids, $prep_id ) if $prep_id;
        }
        my $prep_ids = Cast_List( -list => \@prep_ids, -to => 'String' );

        my $condition = "Plate_ID = FK_Plate__ID and FK_Rack__ID = Rack_ID and Rack_Name = 'Temporary' AND FK_Prep__ID IN ($prep_ids)";

        ## Find the plate ids that are in temporary

        @plate_ids = $dbc->Table_find( "Plate_Prep,Plate,Rack", "distinct FK_Plate__ID", "WHERE $condition" ) if ($prep_ids);

        my @curr_plates_not_stored = $dbc->Table_find( 'Plate,Rack', 'Plate_ID', "WHERE Rack_ID=FK_Rack__ID AND Rack_Name = 'Temporary' AND Plate_ID IN ($self->{plate_ids})" );

        ### Add the current_plates as well (if no preps have been recorded for them)
        if (@curr_plates_not_stored) {
            push( @plate_ids, @curr_plates_not_stored );
            @plate_ids = @{ unique_items( \@plate_ids ) };
        }
    }

    if (@plate_ids) {

        my $default_location;
        if ($default_rack) {
            ($default_location) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias like '$default_rack'" );
        }

        if ( !$default_location ) {
            ($default_location) = $dbc->Table_find( 'Setting', 'Setting_Default', "WHERE Setting_Name = 'DEFAULT_LOCATION'" );    ## figure out default if possible <CONSTRUCTION>
        }

        if ($default_location) {
            alDente::Rack::move_Items( -dbc => $self->{dbc}, -type => 'Plate', -ids => \@plate_ids, -rack => $default_location, -confirmed => 1 );
        }
        else {
            $output = "The following plates need to be scanned in" . lbr();
            $output .= "their proper Rack or they will be thrown" . lbr();
            $output .= "out at the end of the day:" . lbr();
        }
    }

    foreach my $plate (@plate_ids) {

        #        $output .= $dbc->get_FK_info( "FK_Plate__ID", $plate ) . "<BR>";
    }
    if ($output) {
        $dbc->message($output);
    }
    return $output;
}

##########################
sub _return_value {
##########################
    my %args         = &filter_input( \@_ );
    my $fields_ref   = $args{-fields};
    my $values_ref   = $args{ -values };
    my $target       = $args{-target};
    my $index_return = $args{-index_return};

    my $value;
    my @fields  = @$fields_ref;
    my @values  = @$values_ref;
    my $counter = 0;

    foreach my $field_name (@fields) {
        if ( $field_name eq $target ) {
            if ($index_return) {
                return $counter;
            }
            else {
                return $values[$counter];
            }
        }
        $counter++;
    }
    return;
}

###############################
# Decant the specified plates
#
# Usage:	my $ok = decant( -type => $decant_type, -volume => $volume, -units => $volume_units, -plate_ids => $current_plate_list );
# Return:	Scalar, number of records being updated
###############################
sub decant {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'type,volume,units,plate_ids' );
    my $type      = $args{-type};                                                  # Decant type. Two valid values: 'Decant_Down_To' and 'Decant_Out'
    my $volume    = $args{-volume};                                                # volume
    my $units     = $args{-units};                                                 # volume units
    my $plate_ids = $args{-plate_ids};                                             # comma separated list of plate ids
    my $dbc       = $self->{dbc};

    my $ok;
    if ( $type =~ /Decant_Down_To/xmsi ) {
        if ( !$volume ) { $volume = '0' }
        if ($units) {                                                              # update both volume and units if units passed in
            $ok = $dbc->Table_update_array( 'Plate', [ 'Current_Volume', 'Current_Volume_Units' ], [ $volume, "'$units'" ], "where Plate_ID in ($plate_ids)" );
            $dbc->message("Decanted down to $volume from current plates. Set Current Volume Units = $units") if ($ok);
        }
        else {                                                                     # update only volume if units not passed in
            $ok = $dbc->Table_update_array( 'Plate', ['Current_Volume'], [$volume], "where Plate_ID in ($plate_ids)" );
            $dbc->message("Decanted down to $volume from current plates.") if ($ok);
        }
    }
    else {
        if ($volume) {
            $volume = $volume * -1;
            $ok = alDente::Container::update_Plate_volumes( -dbc => $dbc, -ids => $plate_ids, -volume => $volume, -units => $units );
        }
        else {
            $ok = $dbc->Table_update_array( 'Plate', ['Current_Volume'], [0], "where Plate_ID in ($plate_ids)" );
            $dbc->message('Decanted down to 0 from current plates.') if ($ok);

        }
    }
    return $ok;
}

####################################
# Send completion email notification
####################################
###sub _send_completion_email {
###    my $self = shift;
###
###    my ($to_email) = Tabl_find($dbc,'Lab_Protocol','Completion_Email_List',"where Lab_Protocol_Name = '$protocol'");
###    if ($to_email) {
###	   my @full_to_email;
###	   foreach my $email (split /,/, $to_email) {
###	       if ($to_email =~ /\@/) {
###		   push(@full_to_email,$to_email);
###	       }
###	       else {
###		   push(@full_to_email,"$to_email\@bcgsc.bc.ca");
###	       }
###	   }
###
###	   my $to_email_list = join(",",@full_to_email);
###	   my $from_email = 'aldente@bcgsc.ca';
###	   my ($user_info) = get_FK_info($dbc,'FK_Employee__ID',$self->{user});
###
###	   my $subject = "Protocol Completed";
###	   my $msg = "<b>Protocol:</b> $protocol<br>";
###	   $msg .= "<b>Plate Set:</b> $self->{set_number}<br>";
###	   $msg .= "<b>Employee:</b> $user_info<br>";
###	   $msg .= "<b>Datetime:</b> " . date_time() . "<br>";
###	   my $header = "Content-type: text/html\n\n";
###	   my $ok = &alDente::Noti ficat ion::Emai l_Not ifica tion($to_email_list,$from_email,$subject,$header . $msg);
###
###	   if ($ok) {
###	       $dbc->session->message("Completion email notification successfully sent to $to_email_list.");
###	   }
###	   else {
###	       $dbc->session->warning("Failed to send completion email notification to $to_email_list.");
###	   }
###    }
###}

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

2003-07-15

=head1 REVISION <UPLINK>

$Id: Prep.pm,v 1.122 2004/12/15 18:49:57 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
