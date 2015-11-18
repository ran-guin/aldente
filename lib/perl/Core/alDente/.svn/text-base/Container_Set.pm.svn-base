################################################################################
# Container_Set.pm
#
# This module handles Container (Plate) Set based functions
#
###############################################################################
package alDente::Container_Set;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Container_Set.pm - This module handles Container (Plate) Set based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) Set based functions<BR>

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
use CGI qw(:standard);
use Data::Dumper;
use RGTools::Barcode;
use strict;
use MIME::Base32;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Container;
use alDente::Container_Views;
use alDente::Security;
use alDente::Sample_Pool;
use alDente::Tools;
use SDB::Session;

use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::Progress;

use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::Views;

use LampLite::CGI;

my $q = new LampLite::CGI;
##############################
# global_vars                #
##############################
use vars qw($current_plates $plate_set);
use vars qw($Connection $Current_Department %Benchmark);
use vars qw(@plate_formats @plate_info @locations @plate_sizes @libraries %Parameters $Security $Sess $testing );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $TABLE = "Plate_Set";

##############################
# constructor                #
##############################

############
sub new {
############
    #
    # Constructor
    #

    my $this = shift;
    my %args = @_;

    ## Mandatory ##
    my $dbc = $args{-dbc};    # Database handle

    ## Optional ##
    my $set             = $args{-set};                     ## specify set number
    my $barcode         = $args{-barcode};                 ## specify barcode instead of ids.
    my $ids             = $args{-ids};
    my $skip_validation = $args{-skip_validation} || 0;    ## flag to indicate basic set NOT used for complex lab protocols (may mix parents & children)

    #    my $attributes = $args{-attributes}; ## allow inclusion of attributes for new record
    my $save    = $args{-save};                            ## save this as a new plate set directly
    my $force   = $args{-force};                           ## force to new set (even if this set of members already exists)
    my $recover = $args{-recover};                         ## recover current set given a possible member

    my $encoded = $args{-encoded} || 0;                    ## reference to encoded object (frozen)

## special case if object encoded (frozen)

    if ($encoded) {
        my $Set = thaw( MIME::Base32::decode($encoded) );
        if ($dbc) {
            $Set->{dbc} = $dbc;                            ## new database handle...
        }
        my ($class) = ref($this) || $this;
        bless $Set, $class;
        return $Set;
    }

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Plate_Set' );
    my ($class) = ref($this) || $this;

    bless $self, $class;

    $self->{tables}           = $TABLE;
    $self->{member_table}     = 'Plate';
    $self->{set_number_field} = "Plate_Set_Number";
    $self->{member_field}     = "FK_Plate__ID";
    $self->{parent_field}     = "FKParent_Plate_Set__Number";
    $self->{primary_field}    = "Plate_Set_ID";
    $self->{dbc}              = $dbc;
    $self->{validate}         = !$skip_validation;

    if ($barcode) { $ids = get_aldente_id( -dbc => $dbc, -barcode => $barcode, -table => $self->{member_table} ); }
    elsif ($set) {
        my $plate_ids = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "where Plate_Set_Number = $set ORDER BY Plate_Set_ID" );

        # only keep validated ids
        $ids = &get_aldente_id( $dbc, $plate_ids, 'Plate' );
    }
    $self->ids($ids);

    if ($save) {
        $self->{set_number} = $self->save_Set( -force => $force );
    }
    elsif ($set) {
        $self->{set_number} = $set;
        $self->load_Info();
    }
    elsif ($recover) {
        $self->{set_number} = $self->_recover_Set( -force => $force );
    }

    return $self;
}

##############################
# public_methods             #
##############################

##################
sub set_number {
#################
    #
    # Return current set
    #
    my $self   = shift;
    my $number = shift;    ## reset if given

    if ($number) { $self->{set_number} = $number }

    return $self->{set_number};
}

############
sub reset_set_number {
############
    my $self = shift;
    my $set  = shift;
    my $dbc  = $self->{dbc};

    if ($scanner_mode) {
        $dbc->message("*** Reset set number to <font size=+1>$set</font> ***");
    }
    else {
        $dbc->message("*** Reset set number to <font size=-1>$set</font> ***");
    }
    $self->{set_number} = $set;

    return;
}

#########
sub ids {
#########
    #
    # Return ids of members in set
    #
    my $self = shift;
    my $ids  = shift;    ## reset if given

    if ($ids) { $self->{ids} = $ids }

    return $self->{ids};
}

################
sub Set_home_info {
################
    #
    # Home page display for container set
    #
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = @_;
    my ($first_member) = split ',', $self->{ids};
    my $default_protocol = $args{-default_protocol} || '';

    if ( $self->{set_number} ) {

    }
    else {
        return;
    }

    #my $group_list =  join(',',@{$dbc->get_local('department_groups')->{$Current_Department}});
    #@protocols = @{$dbc->Security->get_accessible_items(-table=>'Lab_Protocol',-extra_condition=>"Lab_Protocol_Status = 'Active'",-group_list=>$group_list)};
    ### Display ancestry info ###

    #    $output .=  $self->label();
    my $output;
    if ( $dbc->config('screen_mode') eq 'desktop' ) { $output .= &vspace(5) . $self->view_Set_ancestry() . &vspace(10) }

    my $plate_list = $self->{ids};

    $output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'resave', -type => 'plate' ) . lbr;
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );

    if ( $dbc->mobile() ) {    ## Want CSS to match other parts of mobile page
        $output .= "<button class='btn btn-lg btn-danger' name='rm' value='Save As New Plate Set'>Save As New Plate Set</button>" . &hspace(10);
    }
    else {
        $output .= submit( -name => 'rm', -value => 'Save As New Plate Set', -class => 'Action', -mobile => $dbc->mobile() );
        $output .= &vspace(5);
    }
    $output .= hidden( -name => 'Plate_IDs', -value => $plate_list );

    $plate_list =~ s/,/pla/g;

    if ( $dbc->mobile() ) {    ## Making link a button to differentiate from tabs
        $output .= &Link_To( $dbc->config('homelink'), "<button type='button' class='btn btn-lg btn-primary'>Home Page for Current Containers</button>", "&Scan=1&Barcode=pla$plate_list", $Settings{LINK_COLOUR} ) . &vspace(5);
    }
    else {
        $output .= &Link_To( $dbc->config('homelink'), 'Home Page for Current Containers', "&Scan=1&Barcode=pla$plate_list", $Settings{LINK_COLOUR} ) . &vspace(5);
    }

    #    if ($self->{ids}=~/,/) { Message("showing info for first member of set ($first_member)") }  ## if more than one member#
    #
    #    my $Member = alDente::Container->new(-dbc=>$self->{dbc},-id=>$first_member);
    #    $Member->home_info();
    $output .= end_form();

    $output .= &alDente::Container_Views::Set_options( -dbc => $dbc, -set => $self->{set_number}, -type => $self->{type}, -protocol => $default_protocol, -plate_list => $self->{ids} );

    return $output;
}

###########
sub label {
###########
    my $self = shift;

    my $label = &vspace(2);
    $label .= "";    ## etc etc.. <CONSTRUCTION> add brief details (such as the trays currently being used etc).

    return $label;
}

################
sub load_Info {
################
    #
    # Load various information on plate set
    #
    #<snip>    # eg:
##
    # my $Set = Container_Set->new(-dbc=>$dbc,-number=>$set_no);
    # $Set->load_Info(-scope=>'basic');    ## load various basic statistics
##
## (now it is available for retrieval)
##
    # my %Details = $Set->values();
    # my $members = $Details{members};    ## number of members in this set
    # my $member_list = $Details{ids};    ## list of plates
    # my $prep_list = $Details{prep_ids}; ## Preparation IDs performed on this set
    #</snip>

    my $self = shift;
    my $dbc  = $self->{dbc};
    if ( $self->{set_number} =~ /^\d+$/ ) {
        my $ids = join ',', $dbc->Table_find( $TABLE, $self->{member_field}, "where $self->{set_number_field} = $self->{set_number} Order by $self->{primary_field}" );

        #	Message($self->{set_number});
        if ( !$ids ) {
            $self->{set_number} = undef;
        }
        else {

            #$ids = $dbc->SDB::DBIO::valid_ids($ids,'Plate',-validate=>1);
            my $valid = &get_aldente_id( $dbc, $ids, 'Plate', -validate => $self->{validate}, -qc_check => 1 );

            ## show QC Pending plates
            my @QC_pending = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID in ($ids) AND QC_Status = 'Pending'" );
            if (@QC_pending) {
                $dbc->warning("QC Pending: @QC_pending");
            }

            $ids = $valid;

            #            Message("ids in load_info(): $ids");
            $self->ids($ids);
        }
    }

    return;
}

###############
sub save_Set {
###############
    #
    # save current list as new Set
    #
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'ids' );

    my $dbc = $self->{dbc} || $args{-dbc};
    my $ids = $self->{ids} || $args{ -ids };    # current list of members
    my $force      = $args{-force};             # force to new set (even if this list of members exists)
    my $parent_set = $args{-parent_set};        # (Scalar) [Optional] Parent of this set (if applicable)
    my $reactivate = $args{-reactivate};

    if ($reactivate) {
        my $in_use;
        &alDente::Container::activate_Plate( -ids => $reactivate, -dbc => $dbc, -confirm => 1, -rack_id => $in_use );
    }

    my @id_list = split ',', &get_aldente_id( $dbc, $ids, 'Plate', -validate => $self->{validate}, -qc_check => 1 );
    ## show QC Pending plates
    my @QC_pending = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID in ($ids) AND QC_Status = 'Pending'" );
    if (@QC_pending) {
        $dbc->warning("QC Pending: @QC_pending");
    }

    my @entered = Cast_List( -list => $ids, -to => 'array' );
    if ( int(@entered) > int(@id_list) ) {

        my ( $ok, $invalid ) = RGmath::intersection( \@entered, \@id_list );
        my $invalid_ids = join ',', @$invalid;

        print '<HR>';
        $dbc->error("Invalid containers found - may need to re-activate plates: ($invalid_ids)");

        my $entered = join ',', $ids;
        my $okay    = join ',', @id_list;

        print '<P>';
        print Link_To( $dbc->config('homelink'), "Re-activate Invalid Plates and Attempt to Save Set Again", "&cgi_application=alDente::Container_App&rm=Save Plate Set&Plate_ID=$entered&Reactivate=$invalid_ids" );
        print '<P>';
        print Link_To( $dbc->config('homelink'), "Continue to Save Set WITHOUT Inactive Plate(s)", "&cgi_application=alDente::Container_App&rm=Save Plate Set&Plate_ID=$okay" );

        &main::leave();
    }

    #
    # Prevent saving if any of current plates are already saved as a set AND it is pre-printed
    #
    # (not sure if we should also prevent saving sets of other types - eg Failed, Exported etc (?)
    #
    my @pre_printed_sets = $dbc->Table_find( 'Plate_Set,Plate', 'Plate_Set_Number', "where FK_Plate__ID=Plate_ID AND Plate_ID IN ($ids) AND Plate_Status like 'Pre-Printed'", 'Distinct' );
    if (@pre_printed_sets) {
        $dbc->error("At least one plate is a Pre-Printed Plate.  It must be Activated before it can be re-used.");
        &main::leave();
    }

    my $recursive = recursive_set( -dbc => $dbc, -ids => $ids );
    if ( $recursive && $self->{validate} ) {
        $dbc->error("Mixing parent and child together is not allowed. Please make distinct plate sets for parent and child.");
        &main::leave();
    }

    #
    #  First check for the same list in a current set (if force flag NOT set)
    #
    unless ($force) {
        my @possible_sets = $dbc->Table_find( $TABLE, $self->{set_number_field}, "where $self->{member_field} in ($ids)", 'Distinct' );
        foreach my $try_set (@possible_sets) {
            unless ($try_set) {next}
            my $already = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "where Plate_Set_Number = $try_set ORDER BY Plate_Set_ID" );
            if ( $already eq $ids ) {
                $dbc->message("Set $try_set already exists");

                my $barcode = join ',', @id_list;

                ### generate form to allow users to
                print alDente::Form::start_alDente_form($dbc)
                    . hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 )
                    . hidden( -name => 'Force Plate Set', -value => 1 )
                    . hidden( -name => 'Plate_IDs',       -value => $barcode )
                    . hidden( -name => 'Possible_Sets',   -value => $try_set )
                    . $q->submit( -name => 'rm', -value => 'Generate New Set with same plates', -class => 'Action' )
                    . &vspace(10)
                    . $q->submit( -name => 'rm', -value => 'Recover Set', -class => "Std" )
                    . &vspace(10)
                    . submit( -name => 'rm', -value => 'Do not create set', -class => "Std", -force => 1 )

                    #. submit( -name => 'Force Plate Set', -value => 'Generate New Set with same plates', -class => "Action" )
                    #. &vspace(10)
                    #. submit( -name => 'Recover Set', -value => 'Recover Current Set', -class => "Std" )
                    #. &vspace(10)
                    #. submit( -name => 'Scan', value => 'Do not create set', -class => "Std" )
                    #. hidden( -name => 'Barcode', -value => "Pla$barcode" )
                    . end_form();

                &main::leave();
            }
        }
    }

    ## Otherwise, make new plate set... ##

    #    @id_list = split ',', &SDB::DBIO::valid_ids($dbc,join(',',@id_list),'Plate',-validate=>1,-qc_check=>1);
    #    _check_valid_plates(-plates=>join(',', @id_list));
    my $set_number = $self->_next_set();

    my $members  = 0;
    my @new_list = ();

    foreach my $member_id (@id_list) {
        $member_id = $member_id + 0;    # convert to int (stripping leading zeros)

###    Comment out line below (if statement) to allow single plate plate_set
        #	if ($plates=~/,/) {  #### append Plate set if more than one plate...
        my $field_list = "$self->{set_number_field},$self->{member_field}";
        my $value_list = "$set_number,$member_id";
        if ($parent_set) {
            $field_list .= ",$self->{parent_field}";
            $value_list .= ",$parent_set";
        }

        my $ok = $dbc->Table_append( $TABLE, "$field_list", "$value_list", -autoquote => 1 );

        if ($ok) {
            $members++;

            # Message("Assigned $member_id to Set $set_number");
            push( @new_list, $member_id );
        }
        else { $dbc->error("error assigning $member_id to set $set_number."); }

        #	}
    }

    if (@new_list) {
        $self->{set_number} = $set_number;
        $current_plates = join ',', @new_list;
        $plate_set = $set_number;
        $dbc->message("Set $self->{set_number} : ($members members)");
    }

    return $self->{set_number};
}

#################
sub transfer {
#################
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'dbc' );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $new_format_type = $args{'-format'};                                      # format of new plate(s)
    my $rack            = $args{'-rack'};                                        # rack to place Plates on (optional)
    my $pre_transfer    = $args{-preTransfer} || 0;
    my $test_plate      = $args{-test_plate} || param('Test Plate Only') || 0;
    my $volume          = $args{-volume};                                        # The volume to be transferred to the new tube. Only needed if transferring to a Tube.
    my $volume_units    = $args{-volume_units};                                  # The units (mL, uL) of the volume specified to be transferred.
    my $user_id         = $dbc->get_local('user_id');

    my $track_transfer     = $args{-track_transfer} || 'Yes';
    my $new_sample_type    = $args{-new_sample_type};                            # If specified, this means we are creating a new sample (i.e. new original plate/tube) with the specified sample type
    my $new_sample_type_id = $args{-new_sample_type_id};
    my $target_plate_type  = $args{-target_plate_type};
    my $create_new_sample  = $args{-create_new_sample};
    my $new_plate_size     = $args{-new_plate_size};                             ## Optionally pass in the size of new plate
    my $new_pipeline_id    = $args{-pipeline_id};                                ## new pipeline id (if necessary)
    my $pipelines_ref      = $args{-pipelines};                                  ## new pipeline id (if necessary)
    my $combine_list       = $args{-combine_list};                               ## Array ref that describes the combine order, ie a..d for trays or 1..8 for flowcells
    my $existing_tray      = $args{-existing_tray};
    my @ordered_pipelines  = @$pipelines_ref if $pipelines_ref;

    #    my $tray_label        = $args{-tray_label};
    $new_format_type = chomp_edge_whitespace($new_format_type);
    $new_sample_type = chomp_edge_whitespace($new_sample_type);

    my $ids                = $args{ -ids } || $self->{ids};                      # list of source plates
    my $type               = $args{-type};                                       # transfer type (aliquot or transfer or export)
    my $notes              = $args{-notes} || param('Notes');
    my $split              = $args{ -split } || 1;                               # number of targets per source container.
    my $change_set_focus   = $args{-change_set_focus};
    my $plate_label        = param('Target Plate Label');
    my $pack               = $args{ -pack };                                     # for creating tray
    my $datestamp          = $args{-timestamp} || param('Created');
    my $combine_containers = $args{-combine_containers};
    my $show_tray_layout   = $args{-show_tray_layout};

### Error checking ###
    unless ($ids) { $dbc->message("No Set defined"); return }
    $ids = Cast_List( -list => $ids, -to => 'string' );

### check type ###
    my $plate_type = join ',', $dbc->Table_find( 'Plate', 'Plate_Type', "where Plate_ID in ($ids)", 'Distinct' );
    if ( $plate_type =~ /,/ && $new_plate_size ne "1-well" ) { $dbc->error("Please do not mix Plate_Types for group transfers"); return; }
    elsif ( $plate_type =~ /library/i && $new_plate_size ne "1-well" ) { $dbc->warning("Library_Plate transfers (from $ids : $plate_type) should be handled separately"); return; }

    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $new_format_type );

    unless ( $new_format_id =~ /^\d+$/ ) { $dbc->message("No valid target format ($new_format_type ?) detected"); return; }

### Parse input
    my ($new_format_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "where Plate_Format_ID = $new_format_id" );
    my ($new_format_style) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_Style', "where Plate_Format_ID = $new_format_id" );

    # if plates has pre-printed daughter plates, transfer to those plates
    my $new_sample_type_str = 'FK_Sample_Type__ID IS NULL';
    if ($new_sample_type_id) {
        $new_sample_type_str = "FK_Sample_Type__ID=$new_sample_type_id OR " . $new_sample_type_str;
    }
    my @pre_print_array = $dbc->Table_find( "Plate", "FKParent_Plate__ID,Plate_Status", "where FKParent_Plate__ID in ($ids) AND ($new_sample_type_str) AND Plate_Status='Pre-Printed'" );

    if ( scalar(@pre_print_array) > 0 ) {
        my $prep_obj = new alDente::Prep( -dbc => $dbc, -suppress_messages_load => 1 );
        $prep_obj->_transfer( -ids => $ids );
        return;
    }

    ## Set Plate Status to Active unless specified to be Pre-Printed ##
    my $plate_status = 'Active';
    if ($pre_transfer) { $plate_status = 'Pre-Printed'; }
    my $failed = 'No';

    ### allow plates to be set as 'Test' plates...otherwise set to 'Production'
    my $TestStatus = 'Production';
    if ($test_plate) { $TestStatus = 'Test'; }

    ### Set Creation date
    $datestamp ||= date_time();

    my $plate_set_id = $self->{set_number};

    ### Figure out the size that the new plates are to be tracked on (may NOT be the same as format size) ###

    #my $combine_containers = 0;
    my $old_size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($ids)", 'Distinct' );

    if ( $new_plate_size eq '1-well' and ( $new_format_size == 8 || $new_format_size == 4 ) ) {
        $combine_containers = 1;
        unless ($combine_list) {
            $combine_list = [ 1 .. 8 ];
        }

        #  HOT FIX skipping for flowcell... <CONSTRUCTION>
    }
    elsif ( $new_plate_size eq '1-well' && $new_format_size == 96 ) {
        $combine_containers = 1;
        unless ($combine_list) {
            my @output = $dbc->Table_find( 'Well_Lookup', 'Plate_96', '', -distinct => 1, -order => 'Plate_96' );
            $combine_list = \@output;
        }

        #       $new_plate_size = $new_format_size . '-well';
    }
    elsif ( $new_plate_size eq '1-well' && $new_format_size == 384 ) {
        $combine_containers = 1;
        unless ($combine_list) {
            my @output = $dbc->Table_find( 'Well_Lookup', "CASE WHEN Length(Plate_384) = 2 THEN Concat(UPPER(Left(Plate_384,1)),'0',Substring(Plate_384,2,1)) ELSE UPPER(Plate_384) END", '', -distinct => 1, -order => 'Plate_384' );
            $combine_list = \@output;
        }

        #        $new_plate_size = $new_format_size . '-well';
    }
    elsif ( $new_plate_size =~ /96/ && $new_format_size == 384 ) {
        ## handles forced 96-well tracking ##
        $combine_containers = 1;
        unless ($combine_list) { $combine_list = [ 'a', 'b', 'c', 'd' ] }
    }
    else {
        ##
    }
    $new_plate_size ||= $new_format_size . '-well';
    my @list_of_plates = split ',', $ids;

    my %Plate_values;
    my $plates_added = 0;

    my @new_plate_set;
    my $added_prep = 0;

    # Get best units
    if ( $volume && $volume_units ) {
        ( $volume, $volume_units ) = &Get_Best_Units( -amount => $volume, -units => $volume_units );
    }

    # Acquire read lock on Plate table
    #    $dbc->lock_tables(-write=>'Plate,Tube',-read=>'Plate_Set,Plate_Format');
    # <CONSTRUCTION> ... may require more locks for 'withdraw sample'

    my $next_plate_num;    # Maximum plate number of the current library
    my @volumes           = split ',', $volume;
    my @volume_units_list = split ',', $volume_units;
    my $counter           = 0;

    my $target_count    = int(@list_of_plates) * $split;
    my @entered_volumes = Cast_List( -list => \@volumes, -to => 'array', -pad => $target_count, -pad_mode => 'Stretch' );
    my @entered_units   = Cast_List( -list => \@volume_units_list, -to => 'array', -pad => $target_count, -pad_mode => 'Stretch' );

    foreach my $thisplate (@list_of_plates) {
        my %details = $dbc->Table_retrieve(
            'Plate LEFT JOIN Sample_Type ON FK_Sample_Type__ID=Sample_Type_ID',
            [   'Plate_Size',      'FK_Library__Name', 'Plate_Number',       'FK_Plate_Format__ID', 'Plate_Test_Status', 'Plate_Type', 'Current_Volume', 'Current_Volume_Units',
                'FK_Pipeline__ID', 'FK_Branch__Code',  'FK_Sample_Type__ID', 'Sample_Type',         'Plate_Parent_Well'
            ],
            "where Plate_ID = $thisplate"
        );

        my $size       = $details{Plate_Size}[0];
        my $library    = $details{FK_Library__Name}[0];
        my $number     = $details{Plate_Number}[0];
        my $format     = $details{FK_Plate_Format__ID}[0];
        my $TestStatus = $details{Plate_Test_Status}[0];

        if ( !$library ) {
            $dbc->message(
                "incomplete data from PLA 
$thisplate"
            );
            print HTML_Dump \%details;
            Call_Stack();
        }

        #	my $application = param('Plate Application') || $details{Plate_Application}[0];
        my $status            = $details{Plate_Status}[0];
        my $P_type            = $details{Plate_Type}[0];
        my $pipeline_id       = $ordered_pipelines[$counter] || $new_pipeline_id || $details{FK_Pipeline__ID}[0] || 'NULL';
        my $branch_id         = $details{FK_Branch__Code}[0] || '';
        my $sample_type_id    = $details{FK_Sample_Type__ID}[0];
        my $plate_parent_well = $details{Plate_Parent_Well}[0];

        my $quantity = $volumes[$counter] || $volume || $details{Current_Volume}[0];
        $quantity = $volume if defined $volume && $#volumes == 0;
        unless ( $track_transfer eq 'Yes' ) {
            $dbc->message("$thisplate - Volume tracking turned off");
            $quantity = undef;
        }
        my $quantity_units = $volume_units_list[$counter] || $volume_units || $details{Current_Volume_Units}[0];
        my $plate_contents = $details{Sample_Type}[0];

        my $original_plate_id;
        my $parent_plate_id;
        if ( ( $new_sample_type_id || $new_sample_type ) && $create_new_sample ) {    # We are creating a new sample
            $original_plate_id = 0;                                                   # This will have to be figured out after creating the plate
            $parent_plate_id   = 0;
            $plate_contents    = $new_sample_type;
            $sample_type_id    = $new_sample_type_id;
        }
        elsif ( $new_sample_type || $new_sample_type_id ) {
            $plate_contents = $new_sample_type;
            $sample_type_id = $new_sample_type_id;
            ($original_plate_id) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$thisplate" );
            $parent_plate_id = $thisplate;
        }
        else {
            ($original_plate_id) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$thisplate" );
            $parent_plate_id = $thisplate;
        }

        if ( $new_format_style eq 'Plate' ) {
            $plate_type = 'Library_Plate';

            # Force all 1-well plates to be Tubes
            if ( $new_plate_size eq '1-well' ) {
                $plate_type = 'Tube';
            }
            $P_type = $plate_type;
        }

        # allow transfer from Array to Tube
        if ( $new_format_style eq 'Tube' && $P_type eq 'Array' ) {
            $P_type     = $new_format_style;
            $plate_type = $new_format_style;
        }

        # do not allow transfers to Array
        if ( $new_format_type eq 'Array' ) {
            $dbc->error("Cannot manually transfer sample to an array without a microarray barcode");
            return;
        }
        Test_Message( "Transferring $size -> $new_plate_size.", $testing );

        ## repeat below x N if source container is being split into N containers each.
        my $container;
        $container = alDente::Container->new( -dbc => $dbc, -plate_id => $thisplate );
        $container->load_Object();
        foreach my $bottle ( 1 .. $split ) {
            my $enter_quantity       = shift @entered_volumes;
            my $enter_quantity_units = shift @entered_units;
            if ($enter_quantity)       { $quantity       = $enter_quantity }
            if ($enter_quantity_units) { $quantity_units = $enter_quantity_units }

            # update the parents' Tube quantity if they are tubes
            if ( $quantity && $quantity_units ) {
                my $retval = $container->withdraw_sample( -quantity => $quantity, -units => $quantity_units, -update => 1 );
                if ( $retval->{error} ) {
                    $dbc->warning("ERROR: Cannot update Container cnt$thisplate");

                    #		    Message("ERROR: Cannot update Container cnt$thisplate");
                }
                else {
                    $dbc->message("Withdraw $quantity $quantity_units from $thisplate ");
                }
            }

            #$Plate_values{ ++$plates_added } = \@values;
            my @values = (
                $new_plate_size, $library, $user_id,           $datestamp, $rack,           $new_format_id, $parent_plate_id, $TestStatus,     $plate_status,
                $failed,         $P_type,  $original_plate_id, $quantity,  $quantity_units, $branch_id,     $pipeline_id,     $sample_type_id, $plate_parent_well
            );
            my @copy_values = @values;
            $Plate_values{ ++$plates_added } = \@copy_values;
        }
        $counter++;
    }

    $dbc->start_trans('transfer_set');

    my @fields = (
        'Plate.Plate_Size',         'Plate.FK_Library__Name',     'Plate.FK_Employee__ID', 'Plate.Plate_Created',   'Plate.FK_Rack__ID',        'Plate.FK_Plate_Format__ID',
        'Plate.FKParent_Plate__ID', 'Plate.Plate_Test_Status',    'Plate.Plate_Status',    'Plate.Failed',          'Plate.Plate_Type',         'Plate.FKOriginal_Plate__ID',
        'Plate.Current_Volume',     'Plate.Current_Volume_Units', 'Plate.FK_Branch__Code', 'Plate.FK_Pipeline__ID', 'Plate.FK_Sample_Type__ID', 'Plate.Plate_Parent_Well'
    );

    my @plate_labels = Cast_List( -list => $plate_label, -pad => $plates_added, -pad_mode => 'Stretch', -to => 'array' );
    if (@plate_labels) {
        map { push @{ $Plate_values{$_} }, $plate_labels[ --$_ ] } keys %Plate_values;
        push @fields, "Plate.Plate_Label";
    }
    elsif ($plate_label) {
        $dbc->session->error("Incorrect number of target labels for $plates_added plates");
        return;
    }

    if ( $new_sample_type && $create_new_sample ) {
        push @fields, 'Plate.Plate_Class';
        foreach my $pla ( keys %Plate_values ) {
            push @{ $Plate_values{$pla} }, 'Rearray';
        }
    }

    my $monitor;
    if ( $counter > 10 ) { $monitor = 'trigger' }    ## monitor progress when number of plates transferred > 10 (somewhat arbitrary, but should correspond to anything with a delay of more than 5 - 10 seconds)

    $dbc->smart_append( -tables => "Plate,$plate_type", -fields => \@fields, -values => \%Plate_values, -autoquote => 1, -monitor_progress => $monitor );    ## trigger logic handled specifically in new_container_trigger ,-no_triggers=>1);

    # Unlock tables
    #    $dbc->unlock_tables();

    @new_plate_set = @{ $dbc->newids('Plate') };
    my $new_plate_set_number = $self->_next_set();

    ##################### If Plate Barcodes are Pre-Printed ... ######################
    my $new_set_created = 0;
    if ($pre_transfer) {
        my $virtual_plates = join ',', @new_plate_set;
        foreach my $new_plate (@new_plate_set) {
            $new_set_created += $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
        }
        if ($combine_containers) {
            require alDente::Tray;
            if ($existing_tray) {
                my $add_to_tray = &alDente::Tray::add_to_tray( -dbc => $dbc, -plates => \@new_plate_set, -tray_id => $existing_tray, -pos_list => $combine_list );
                $dbc->message("Add to tray $existing_tray") if $add_to_tray;
            }
            else {
                my @new_trays = &alDente::Tray::create_multiple_trays( -dbc => $dbc, -plates => \@new_plate_set, -pos_list => $combine_list, -pack => $pack );    # ,-tray_label=>$tray_label);
                &alDente::Barcoding::PrintBarcode( $dbc, 'Trays', join( ',', @new_plate_set ), "print,$plate_type" );
            }
        }
        else {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $virtual_plates );
        }

        if ( $new_set_created && $change_set_focus ) {
            $self->reset_set_number($new_plate_set_number);
            $self->ids($virtual_plates);
            $plate_set      = $new_plate_set_number;
            $current_plates = $virtual_plates;
        }
        elsif ($new_set_created) {
            print "<BR><B>Pending Plate Set: $new_plate_set_number</B><BR>";

        }
    }
    else {
        my $number_of_new_plates = scalar(@new_plate_set);
        if ( $number_of_new_plates > 0 ) {
            $self->{ids} = "";
            my $new_plate_set_index = 0;

            my $counter = 0;
            foreach my $source_plate (@list_of_plates) {
                $counter++;
                my $split_count = $split || 1;
                my $plate_index = 0;
                for ( my $i = 0; $i < $split_count; $i++ ) {
                    my $new_plate = $new_plate_set[$new_plate_set_index];
                    Test_Message( "<BR>NEW plates created: $new_plate", $testing );

                    #### only make plate set if current plate set defined...
                    if ( $self->{set_number} ) {
                        $new_set_created = $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
                    }
                    $self->{ids} .= "$new_plate,";
                    my $ok;    # check if insert was successful
                    #### If transfer to new sample type, then create extraction and sample records ####

                    if ( $new_sample_type && $create_new_sample ) {
                        $combine_containers = 0;

                        # insert original plate id (pointing to itself)

                        $dbc->Table_update_array( "Plate", ["FKOriginal_Plate__ID"], ["$new_plate"], "WHERE Plate_ID=$new_plate" );

                        my ($plate_format_info) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells,Plate_Format_Style', "WHERE Plate_ID=$new_plate and FK_Plate_Format__ID=Plate_Format_ID" );
                        my ( $plate_size, $plate_format_style ) = split ',', $plate_format_info;
                        my $target_plate_id = $new_plate;
                        my @target_plate_wells;
                        if ( $plate_format_style =~ /plate/i ) {
                            my $well_field;
                            my $condition;
                            if ( $plate_size =~ /96/ ) {
                                $well_field = 'Plate_96';
                                $condition  = "WHERE Quadrant='a'";
                            }
                            elsif ( $plate_size =~ /384/ ) {
                                $well_field = 'Plate_384';
                                $condition  = '';
                            }
                            my %Map;
                            map {
                                my ( $well, $quad ) = split ',', $_;
                                $well = uc( format_well($well) );
                                push( @target_plate_wells, $well );
                                $Map{$well} = $quad;
                            } $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
                        }
                        elsif ( $plate_format_style =~ /tube/i ) {
                            @target_plate_wells = ('n/a');
                        }

                        my $rearray = alDente::ReArray->new( -dbc => $dbc, -dbc => $dbc );
                        my %ancestry      = &alDente::Container::get_Parents( -dbc => $dbc, -id => $source_plate, -simple => 1 );
                        my $original      = $ancestry{original};
                        my $parent_sample = $ancestry{sample_id};

                        my @source_wells = $dbc->Table_find( 'Plate_Sample', 'Well', "WHERE FKOriginal_Plate__ID= $original" );
                        my ($tube) = $dbc->Table_find( 'Tube', 'Tube_ID', "WHERE FK_Plate__ID = $source_plate" );

                        if ($tube) {
                            @source_wells = ('N/A') x scalar(@target_plate_wells);
                        }
                        elsif ( $source_wells[0] ) {
                            @source_wells = ( $source_wells[0] ) x scalar(@target_plate_wells);
                        }
                        else {
                            @source_wells = ('N/A') x scalar(@target_plate_wells);
                        }
                        my @source_plates    = ($source_plate) x scalar(@target_plate_wells);
                        my $type             = 'Extraction Rearray';
                        my $status           = 'Completed';
                        my $target_size      = $plate_size;
                        my $rearray_comments = "Extraction";
                        my $rearray_request;
                        my $target_plate;

                        ### Create the rearray records for the extraction
                        ( $rearray_request, $target_plate ) = $rearray->create_rearray(
                            -source_plates    => \@source_plates,
                            -source_wells     => \@source_wells,
                            -target_wells     => \@target_plate_wells,
                            -target_plate_id  => $target_plate_id,
                            -employee         => $user_id,
                            -request_type     => $type,
                            -status           => $status,
                            -target_size      => $target_size,
                            -rearray_comments => $rearray_comments,
                            -plate_contents   => $new_sample_type,
                            -plate_status     => 'Active',
                            -create_plate     => 0
                        );

                        my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $target_plate, -from_rearray_request => $rearray_request, -type => 'Extraction' );

                    }    # END if ( $new_sample_type && $create_new_sample )
                    $plate_index++;
                    $new_plate_set_index++;
                }    # END for (my $i=0; $i<$split_count; $i++)
            }    # END foreach my $source_plate ( @list_of_plates )
            chop $self->{ids};
        }

        my $number_in_set = int( my @list = split ',', $self->{ids} );
        if ($new_set_created) {
            $self->reset_set_number($new_plate_set_number);
            $plate_set = $new_plate_set_number;

        }

        my $newids = join ',', @new_plate_set;
        $self->ids($newids);    ## Reset current plate ids..

        if ($combine_containers) {
            require alDente::Tray;
            if ($existing_tray) {
                my $add_to_tray = &alDente::Tray::add_to_tray( -dbc => $dbc, -plates => \@new_plate_set, -tray_id => $existing_tray, -pos_list => $combine_list );
                $dbc->message("Add to tray $existing_tray") if $add_to_tray;
            }
            else {
                my @new_trays = &alDente::Tray::create_multiple_trays( -dbc => $dbc, -plates => \@new_plate_set, -pos_list => $combine_list, -pack => $pack );    # ,-tray_label=>$tray_label);
                &alDente::Barcoding::PrintBarcode( $dbc, 'Trays', join( ',', @new_plate_set ), "print,$plate_type" );

                if ($show_tray_layout) {
                    foreach my $tray (@new_trays) {
                        print "NEW TRAY: $tray ";
                        my ($plates_in_tray) = $dbc->Table_find( 'Plate_Tray', "Group_Concat(FK_Plate__ID)", "where FK_Tray__ID = $tray" );
                        my $LP = new alDente::Library_Plate( -dbc => $dbc, -plate_id => $plates_in_tray );
                        $LP->view_plate( -plate_id => $plates_in_tray, -printable_page_link_only => 1, -suppress_sample_display => 1, -action => ' ' );    # -action argument is for removing the default buttons( 'Select All Wells', 'Clear All Wells' )
                        print "<BR><BR>";
                    }
                }    # END if( $show_tray_layout )                                                                                                                                         # END if( $show_tray_layout )
                else {
                    $dbc->message("NEW TRAYS: @new_trays");
                }
            }
        }
        else {

            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', join( ',', @new_plate_set ) );
        }

    }

    $current_plates ||= $self->{ids};

    if ( $type =~ /transfer/i ) {
        $dbc->message("Plates: $ids Thrown away");
        alDente::Container::throw_away( -ids => $ids, -dbc => $dbc, -notes => $notes, -confirmed => 1 );
    }
    elsif ( $type =~ /export/i ) {
        my $notes = param('');
        $dbc->message("Plates: $ids Exported ($notes)");
        alDente::Container::throw_away( -ids => $ids, -dbc => $dbc );
        export_Plate( -ids => $ids, -dbc => $dbc, -notes => $notes );
    }
    else {

        #	$dbc->message("Type: $type");
    }

    $dbc->finish_trans('transfer_set');

    $dbc->message("<B>Current Plates changed to $self->{ids}</B>");
    return $self->{ids};    ##### indicate transferred and appended Preparation table

}

#################################################################################
# Allow the user to choose from the plate and transfer to a number of agar tubes
##################################################################################
sub plate_transfer_to_tube {
#################################
    my %args              = @_;
    my $dbc               = $args{-dbc};
    my $new_format_type   = $args{'-format'};        # format of new plate(s)
    my $rack              = $args{-rack};            # rack to place Plates on (optional)
    my $test_plate        = $args{-test} || 0;
    my $label_colour      = "yellow";
    my $plate_id          = $args{-plate_id};
    my $transfer_quantity = $args{-quantity};
    my $transfer_units    = $args{-units};
    my $material_type     = $args{-material_type};
    print alDente::Form::start_alDente_form( $dbc, 'PlateToTube' );

    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $new_format_type );

    unless ( $transfer_quantity && $transfer_units ) {
        return;
    }
    my @all_wells = ();
    my $last_letter;
    my $last_num;

    my $height = 300;
    my $width  = 450;
    my @list;

    my @sample_wells = $dbc->Table_find( 'Plate_Sample,Plate', 'Well', "WHERE Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID AND Plate_ID IN ($plate_id)" );
    my %sample_available = map { $_ => 1 } grep {$_} @sample_wells;

    my $size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID IN ($plate_id)", -distinct => 1 );
    if ( $size =~ /,/ ) { $dbc->message("Plates being tracked as the same size must be used together"); return; }
    elsif ( $size =~ /\b96\b/ )  { $last_letter = 'H'; $last_num = 12; }
    elsif ( $size =~ /\b384\b/ ) { $last_letter = "P"; $last_num = 24; $height *= 2; $width *= 2; }
    elsif ( $size =~ /\b1\b/ )   { $last_letter = "A"; $last_num = 1; }
    else                         { $dbc->message("Size undefined or unrecognized ($size) - aborting"); return; }

    foreach my $row ( 'A' .. $last_letter ) {
        foreach my $col ( 1 .. $last_num ) {
            push( @all_wells, "$row$col" );
        }
    }
    my $all = join ',', @all_wells;

    my $true         = "SetSelection(document.PlateToTube,'Wells',1,'$all'); ";
    my $false        = "SetSelection(document.PlateToTube,'Wells',0,'all'); ";
    my $parent_plate = HTML_Table->new();

    $parent_plate->Set_Title( "<B>PLA$plate_id Plate</B>: " . alDente::Tools::alDente_ref( 'Plate', $plate_id ), fsize => '-1' );
    $parent_plate->Set_Width('450');
    $parent_plate->Set_Class('small');
    $parent_plate->Set_Border(1);

    foreach my $col ( 0 .. $last_num ) {
        my $col_list  = join ',', map { $_ . $col } ( 'A' .. $last_letter );
        my $col_fill  = "SetSelection(document.PlateToTube,'Wells','toggle','$col_list'); ";
        my $fill_link = radio_group( -name => "", -values => [''], -onClick => $col_fill );

        if ($col) {
            $parent_plate->Set_Column( ["$col $fill_link"] );
            $parent_plate->Set_Column_Colour( $col + 1, $label_colour );

        }
        else {
            $parent_plate->Set_Column( [""] );
            $parent_plate->Set_Column_Colour( $col + 1, $label_colour );
        }
    }

    foreach my $row ( 'A' .. $last_letter ) {
        my $row_list  = join ',', map { $row . $_ } ( 1 .. $last_num );
        my $row_fill  = "SetSelection(document.PlateToTube,'Wells','toggle','$row_list'); ";
        my $fill_link = radio_group( -name => "", -values => [''], -onClick => $row_fill );

        my @checkboxes = ();
        $parent_plate->Set_Column_Colour( 1, $label_colour );

        foreach my $col ( 1 .. $last_num ) {
            my $disable = "-disabled";
            my $well    = "$row$col";
            $well = &format_well($well);
            if ( $sample_available{$well} ) { $disable = '' }
            if ( grep /^$row$col$/, @list ) {
                push( @checkboxes, checkbox( -name => "Wells", -value => "$row$col", -force => 1, -checked => 1, -label => "", $disable ) );
            }
            else {
                push( @checkboxes, checkbox( -name => "Wells", -value => "$row$col", -force => 1, -checked => 0, -label => "", $disable ) );
            }
        }
        $parent_plate->Set_Row( [ "$row$fill_link", @checkboxes ] );

    }
    $parent_plate->Set_Column_Colour( 1, $label_colour );

    if ( $size =~ /\b1\b/ ) {

        #	foreach my $sub_plate (split ',', $plate_id) {
        print hidden( -name => 'Wells', -value => '' );    ## no well for single tube transfer

        #	}
    }
    else {
        print "Please select the wells from the plate to transfer to the $new_format_type(s)<BR><BR>";
        $parent_plate->Printout();

        print radio_group( -name => 'Set All Wells', -values => ['Select All Wells'], -onClick => $true ), hspace(10), radio_group( -name => "Clear All Wells", -values => ['Clear All Wells'], -onClick => $false ), "<BR><BR>";
    }

    print submit( -name => "Transfer to Tube from Plate", -value => "Transfer to $new_format_type", -class => "Action" );
    print hidden( -name => "Current Plates",          -value => $plate_id );
    print hidden( -name => "Transfer_Quantity",       -value => $transfer_quantity );
    print hidden( -name => "Transfer_Quantity_Units", -value => $transfer_units );
    print hidden( -name => "FK_Sample_Type__ID",      -value => $material_type );

    print hidden( -name => "Rack_ID",    -value => $rack );
    print hidden( -name => "New Format", -value => $new_format_id );

    my $frozen = &RGTools::RGIO::Safe_Freeze( -name => "Parent_Plate", -value => $parent_plate, -format => 'hidden', -encode => 1 );
    print $frozen;
    print end_form();
    return 1;
}

##################################################################################
# Allow the user to choose from the plate and transfer to a number of agar tubes
##################################################################################
sub create_tube_from_plate {
#################################
    my $dbc     = shift;
    my $user_id = $dbc->get_local('user_id');

    print alDente::Form::start_alDente_form( $dbc, 'PlateToTubeCreate' );
    my %args = @_;

    my $dbc              = $args{-dbc};
    my $rack             = $args{-rack};
    my $wells            = $args{-wells};
    my $material_type    = $args{-material_type};
    my $material_type_id = $dbc->get_FK_ID( 'FK_Sample_Type__ID', $material_type ) if $material_type;

    my @wells = Cast_List( -list => $wells, -to => 'Array' );

    my $label_colour = "yellow";
    my $datestamp    = date_time();

    my $parent_plate_id = $args{-parent_plate_id};
    my $quantity        = $args{-quantity};
    my $quantity_units  = $args{-units};
    unless ($rack) {
        ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name='Temporary'" );
    }
    $rack = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );
    my $new_format_id = $args{-new_format_id};
    my @format_info = $dbc->Table_find( 'Plate_Format', 'Wells,Plate_Format_Type', "where Plate_Format_ID = $new_format_id" );
    my ( $new_format_size, $new_format_type ) = split ',', $format_info[0];
    my $plate_size = $new_format_size . '-well';

    my %details = $dbc->Table_retrieve(
        'Plate,Library_Plate,Sample_Type',
        [ 'FK_Library__Name', 'Plate_Number', 'FK_Plate_Format__ID', 'Plate_Test_Status', 'Plate_Status', 'Failed', 'FKOriginal_Plate__ID', 'Plate.Parent_Quadrant', 'FK_Sample_Type__ID', 'FK_Pipeline__ID', 'Plate_ID', 'Plate.Plate_Label', 'Sample_Type' ],
        "where FK_Sample_Type__ID=Sample_Type_ID AND Plate_ID IN ($parent_plate_id) and FK_Plate__ID=Plate_ID"
    );

    my $library    = $details{FK_Library__Name};
    my $plate_num  = $details{Plate_Number};
    my $TestStatus = $details{Plate_Test_Status};

    #    my $application = param('Plate Application') || $details{Plate_Application}[0];
    my $plate_status      = $details{Plate_Status};
    my $failed            = $details{Failed};
    my $original_plate_id = $details{FKOriginal_Plate__ID};
    my $parent_quad       = $details{Parent_Quadrant};

    #    my $plate_content_type = $details{Plate_Content_Type};
    my $sample_type      = $details{Sample_Type};
    my $plate_content_id = $details{FK_Sample_Type__ID};
    my $pipeline_id      = $details{FK_Pipeline__ID};
    my $plate_id         = $details{Plate_ID};
    my $plate_label      = $details{Plate_Label};

    my %Plate_values;
    my $plates_added = 0;
    my @list         = @wells;
    my $last_letter  = "H";
    my $last_num     = 12;
    my $height       = 300;
    my $width        = 450;

    my $size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID IN ($parent_plate_id)", -distinct => 1 );
    if ( $size =~ /384/ ) { $last_letter = "P"; $last_num = 24; $height *= 2; $width *= 2; }
    elsif ( $size =~ /\b1\b/ )  { $last_letter = "A"; $last_num = 1; }
    elsif ( $size =~ /\b96\b/ ) { $last_letter = 'H'; $last_num = 12; }
    else                        { $dbc->message("Size ($size) unrecognized - aborting"); return; }

    my $parent_plate = HTML_Table->new();

    $parent_plate->Set_Title( "<B>PLA$plate_id->[0] Plate: $library->[0]-$plate_num->[0]...</B>", fsize => '-1' );
    $parent_plate->Set_Width('450');
    $parent_plate->Set_Class('small');
    $parent_plate->Set_Border(1);

    foreach my $col ( 0 .. $last_num ) {
        my $col_list = join ',', map { $_ . $col } ( 'A' .. $last_letter );
        my $col_fill = "SetSelection(document.PlateToTubeCreate,'Wells','toggle','$col_list'); ";

        #my $fill_link = radio_group(-name=>"",-values=>[''],-onClick=>$col_fill);

        if ($col) {
            $parent_plate->Set_Column( ["$col "] );
            $parent_plate->Set_Column_Colour( $col + 1, $label_colour );
        }
        else {
            $parent_plate->Set_Column( [""] );
            $parent_plate->Set_Column_Colour( $col + 1, $label_colour );
        }
    }
    my $row_index = 2;
    foreach my $row ( 'A' .. $last_letter ) {

        my @checkboxes = ();
        $parent_plate->Set_Column_Colour( 1, $label_colour );
        foreach my $col ( 1 .. $last_num ) {
            if ( grep /^$row$col$/, @list ) {

                push( @checkboxes, checkbox( -name => "Wells", -value => "$row$col", -force => 1, -checked => 1, -label => "", -disabled => 1 ) );
                $parent_plate->Set_Cell_Colour( $row_index, $col + 1, 'Red' );
            }
            else {
                push( @checkboxes, checkbox( -name => "Wells", -value => "$row$col", -force => 1, -checked => 0, -label => "", -disabled => 1 ) );
            }
        }
        $parent_plate->Set_Row( [ "$row", @checkboxes ] );
        $row_index++;
    }
    $parent_plate->Set_Column_Colour( 1, $label_colour );

    if ( $size =~ /\b1\b/ ) {
        print hidden( -name => 'Wells', -value => '' );    ## no parent well if size is already 1-well ##
    }
    else {
        $parent_plate->Printout();
    }
    print "<BR><BR>";

    my $plates = int(@$library);
    foreach my $index ( 0 .. $plates - 1 ) {
        foreach my $well (@wells) {
            my $mat_type = $material_type_id || $plate_content_id->[$index];
            my @values = (
                $plate_size,            $library->[$index],      $user_id,               $datestamp, $rack,                        $plate_num->[$index], $new_format_id, $plate_id->[$index],
                $TestStatus->[$index],  $plate_status->[$index], $failed->[$index],      'Tube',     $original_plate_id->[$index], $mat_type,            $quantity,      $quantity_units,
                $parent_quad->[$index], format_well($well),      $pipeline_id->[$index], $plate_label->[$index]
            );
            $Plate_values{ ++$plates_added } = \@values;
        }
    }

    my $display_agar = HTML_Table->new();

    $display_agar->Set_Title( "<B>$new_format_type Information</B>", fsize => '-1' );
    $display_agar->Set_Width('500');
    $display_agar->Set_Class('small');
    $display_agar->Set_Headers( [ 'Field', 'Value' ] );
    my @fields = (
        'Plate.Plate_Size',        'Plate.FK_Library__Name',  'Plate.FK_Employee__ID', 'Plate.Plate_Created', 'Plate.FK_Rack__ID',          'Plate.Plate_Number', 'Plate.FK_Plate_Format__ID', 'Plate.FKParent_Plate__ID',
        'Plate.Plate_Test_Status', 'Plate.Plate_Status',      'Plate.Failed',          'Plate.Plate_Type',    'Plate.FKOriginal_Plate__ID', 'FK_Sample_Type__ID', 'Current_Volume',            'Current_Volume_Units',
        'Plate.Parent_Quadrant',   'Plate.Plate_Parent_Well', 'FK_Pipeline__ID',       'Plate_Label'
    );

    my $index = 0;
    foreach my $field (@fields) {
###	   if ($field eq "Parent_Quadrant"  or $field eq "Tube.Parent_Well"){#
###	       next;
###	   }
        my @row = $field;
        foreach my $key ( keys %Plate_values ) {
            unless ( $key =~ /^\d+$/ ) {next}    ## not an index key ##
            my $display_value = $Plate_values{$key}[$index];
            if ( foreign_key_check($field) ) {
                $display_value = $dbc->get_FK_info( $field, $display_value );
            }
            push @row, $display_value;
        }
        $display_agar->Set_Row( \@row );

        #        $display_agar->Set_Row([$field,$display_value]);
        #print "field: $field<br>";
        $index++;
    }
    $display_agar->Printout();

    print "<BR>You are about to create $plates_added $new_format_type(s).  Are you sure you want to continue? <BR>";
    print submit( -name => "Confirm Create Tube from Plate Transfer", -class => "Action" );
    my $frozen = Safe_Freeze( -name => "PlateToTubeTransfer", -value => \%Plate_values, -format => 'hidden', -encode => 1 );
    print $frozen;

    #print end_form();
    return 1;
}

###############################################
# Confirm and create tubes
###############################################
sub confirm_tube_to_plate_transfer {
###############################################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    print alDente::Form::start_alDente_form( $dbc, );

    my $thawed = Safe_Thaw( -name => 'PlateToTubeTransfer', -thaw => 1, -encoded => 1 );
    my %Plate_values;

    if ($thawed) { %Plate_values = %$thawed; }

    my @fields = (
        'Plate.Plate_Size',        'Plate.FK_Library__Name',  'Plate.FK_Employee__ID', 'Plate.Plate_Created', 'Plate.FK_Rack__ID',          'Plate.Plate_Number', 'Plate.FK_Plate_Format__ID', 'Plate.FKParent_Plate__ID',
        'Plate.Plate_Test_Status', 'Plate.Plate_Status',      'Plate.Failed',          'Plate.Plate_Type',    'Plate.FKOriginal_Plate__ID', 'FK_Sample_Type__ID', 'Current_Volume',            'Current_Volume_Units',
        'Plate.Parent_Quadrant',   'Plate.Plate_Parent_Well', 'Plate.FK_Pipeline__ID', 'Plate.Plate_Label'
    );

    my $started = $dbc->start_trans( -name => 'tube_to_plate_transfer' ) if $dbc;    ### start transaction
    my $trans = $dbc->transaction() if $dbc;

    # $dbc->finish_trans() if $dbc->get_transaction_status eq 'started';
    $dbc->smart_append( -tables => "Plate,Tube", -fields => \@fields, -values => \%Plate_values, -autoquote => 1 );    ## trigger logic handled specifically in new_container_trigger ,-no_triggers=>1);

    if ($started) { $dbc->finish_trans( -name => 'tube_to_plate_transfer' ); }

    my @plate_list = Cast_List( -list => $dbc->newids('Plate'), -to => 'Array' );
    my $plate_list = join( ",", @plate_list );

    &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $plate_list );
    ## go back to the Parent plate homepage
    my ($new_plate_id) = $dbc->Table_find( 'Plate', 'FKParent_Plate__ID', "WHERE Plate_ID=$plate_list[0]" );
    &alDente::Info::info( $dbc, "PLA" . $new_plate_id );
    return 1;
}

#################################################################################
# Allow the user to choose wells to fill from a set of tubes
##################################################################################
sub tube_transfer_to_plate {
#################################
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $action            = $args{-action};
    my $new_format_type   = $args{'-format'};                                     # (Scalar) format name of new plate(s)
    my $rack              = $args{-rack};                                         # (Scalar) rack to place Plates on (optional)
    my $test_plate        = $args{-test} || 0;                                    # (Scalar) test status of the new plate
    my $plate_id          = $args{-plate_id};                                     # (Scalar) Comma-delimited list of plate IDs for the source tubes
    my $transfer_quantity = $args{-quantity};
    my $transfer_units    = $args{-units};
    my $fill_by           = $args{-fill_by} || 'column';                          # (Scalar) Defines the ordering of the wells (by row A1, B1, C1 or by col A1,A2,A3)
    my $pipeline_id       = $args{-pipeline_id};                                  # (Scalar) Pipeline of the daughter plate.
    my $plate_label       = $args{-plate_label} || param('Target Plate Label');
    my $material_type     = $args{-material_type};

    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'TubeToPlate' )
        . hidden( -name => "Plate_Format",       -value => $new_format_type )
        . hidden( -name => "Rack",               -value => $rack )
        . hidden( -name => "Pipeline_ID",        -value => $pipeline_id )
        . hidden( -name => "quantity",           -value => $transfer_quantity )
        . hidden( -name => "units",              -value => $transfer_units )
        . hidden( -name => "material_type",      -value => $material_type )
        . hidden( -name => "Target Plate Label", -value => $plate_label );

    my @source_plates = split( ',', $plate_id );

    # retrieve format_id from format name
    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $new_format_type );
    my ($size) = $dbc->Table_find( "Plate_Format", "Wells", "WHERE Plate_Format_ID=$new_format_id" );
    if ( $new_format_type =~ /FlowCell|Slide/ ) {
        $page .= hidden( -name => 'cgi_application', -value => 'Illumina::Run_App', -force => 1 ) . hidden( -name => 'rm', -value => 'create_flowcell', -force => 1 );

        if ( int(@source_plates) > $size ) {
            $dbc->error("$new_format_type only has $size available positions");
            return 0;
        }

        my $table = &tube_transfer_to_flowcell(
            -dbc               => $dbc,
            -action            => $action,
            -source_plates     => $plate_id,
            -format_type       => $new_format_type,
            -material_type     => $material_type,
            -daughter_pipeline => $pipeline_id
        );
        $page .= $table->Printout(0);
    }
    else {
        my @plate_types = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID IN ($plate_id)" );
        if ( grep !/1-well/, @plate_types ) { $dbc->warning("All plates should be 1-well!") }

        # display prompt for wells per tube
        $page .= 'Exclude: ' . Show_Tool_Tip( textfield( -name => 'Exclude', -id => 'Exclude', -size => 15 ), 'optionally indicate wells to skip or exclude. Eg: A01,A02,B01 ' ) . &vspace(5);
        my $rearray = new HTML_Table();
        my $row_well;
        my $col_well;
        my $all_row_well;
        my $all_col_well;

        for ( my $i = 0; $i < $size; $i++ ) {
            $row_well = &alDente::ReArray::nextwell( $row_well, $new_format_type, 'Row' );
            $col_well = &alDente::ReArray::nextwell( $col_well, $new_format_type, 'Col' );
            if ( !$all_row_well ) { $all_row_well = $row_well }
            else                  { $all_row_well .= ",$row_well" }
            if ( !$all_col_well ) { $all_col_well = $col_well }
            else                  { $all_col_well .= ",$col_well" }
        }
        my $all_plates;
        my %duplicate_plate;
        foreach my $source_plate (@source_plates) {
            if ( $duplicate_plate{$source_plate} ) {
                $duplicate_plate{$source_plate}++;
                $source_plate .= "_$duplicate_plate{$source_plate}";
            }
            else {
                $duplicate_plate{$source_plate} = 1;
            }
            if ( !$all_plates ) { $all_plates = "WellsForPlate${source_plate}"; }
            else                { $all_plates .= ",WellsForPlate${source_plate}"; }
        }

        my $byrow = "SetListSelection(this.form,'$all_plates','$all_row_well','Exclude'); document.getElementById('Order_By').value = 'Row';";
        my $bycol = "SetListSelection(this.form,'$all_plates','$all_col_well','Exclude'); document.getElementById('Order_By').value = 'Column';";

        my $byrow_btn = button( -name => 'By Row',    -onClick => "$byrow", -class => 'Button' );
        my $bycol_btn = button( -name => 'By Column', -onClick => "$bycol", -class => 'Button' );
        $page .= hidden( -id => 'Order_By', -name => 'Order_By', -value => 0, -force => 1 );

        my $by_raindance_btn;

        if ( $dbc->package_active('Raindance') ) {
            require Raindance::Run;
            my $raindance_run = new Raindance::Run();
            my $raindance_row_layout_wells = $raindance_run->determine_raindance_layout( -plate_ids => [ 1 .. 96 ], -format => 'Thunderstorm' );
            $raindance_row_layout_wells = join( ",", @{$raindance_row_layout_wells} );
            my $raindance_column_layout_wells = $raindance_run->determine_raindance_layout( -plate_ids => [ 1 .. 96 ], -format => 'Thunderstorm', -order => 'column' );
            $raindance_column_layout_wells = join( ",", @{$raindance_column_layout_wells} );

            #print HTML_Dump $raindance_layout_wells;
            my $by_raindance_row_layout    = "SetListSelection(this.form,'$all_plates','$raindance_row_layout_wells','Exclude')";
            my $by_raindance_column_layout = "SetListSelection(this.form,'$all_plates','$raindance_column_layout_wells','Exclude')";

            #            $by_raindance_btn = button( -name => 'By Thunderstorm Row Layout', -onClick => "$by_raindance_row_layout", -class => 'Button' );
            #            $by_raindance_btn .= hspace(10) . button( -name => 'By Thunderstorm Column Layout', -onClick => "$by_raindance_column_layout", -class => 'Button' );

            $page .= hidden( -name => 'Original_Order', -value => 1, -force => 1 );
        }

        $rearray->Set_Headers( [ "Source Tube", "Well", $byrow_btn . hspace(5) . $bycol_btn . hspace(5) . $by_raindance_btn ] );
        foreach my $source_plate (@source_plates) {
            my $real_source_plate = $source_plate;
            $real_source_plate =~ s/_.*//g;
            my $plate_info = $dbc->get_FK_info( "FK_Plate__ID", $real_source_plate );
            my ($default_value) = $dbc->Table_find( "Plate_Tray", "Plate_Position", "WHERE FK_Plate__ID = $real_source_plate" );
            my $wellwindow = &alDente::Tools::show_well_table( -plate_id => $source_plate, -form => 0, -size => $size, -dbc => $dbc );
            $rearray->Set_Row(
                [   "$plate_info",
                    textfield(
                        -name     => "WellsForPlate${source_plate}",
                        -id       => "WellsForPlate${source_plate}",
                        -value    => $default_value,
                        -readonly => 1,
                        -force    => 1
                    ),
                    &SDB::HTML::create_collapsible_link(
                        -linkname => 'Assign Wells',
                        -html     => $wellwindow,
                        -style    => 'collapsed'
                    )
                ]
            );
            $page .= hidden( -name => "Source Plates", -value => $source_plate, -force => 1 );
            $page .= "<validator name='WellsForPlate${source_plate}' format='' mandatory='1'> </validator>\n";
        }
        my ($source_lib) = $dbc->Table_find( "Plate", "FK_Library__Name", "WHERE Plate_ID in ($plate_id)" );

        my $label = param('Target Plate Label');
        if ($label) { $page .= hidden( -name => 'Target Plate Label', -value => $label ) }

        # add prompt for library (if different than the library of the first tube
        my %transfer_options;

        $transfer_options{'ReArray'} = "This will rearray the current plates/tubes to a Single tracked plate (<B>Individual wells will no longer be handled separately</B>)<P>";
        $transfer_options{'ReArray'} .= "Target Library: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'Library.Library_Name', -search => 1, -filter => 1, -default => $source_lib, -form => 'TubeToPlate', -filter_by_dept => 1 ) . "<p ></p>\n";
        $transfer_options{'ReArray'} .= checkbox( -name => 'set_unused_wells', -force => 1, -label => 'Set unused wells' ) . "<p ></p>\n";
        $transfer_options{'ReArray'} .= submit( -name => "ReArray To Plate from Tube", -value => "ReArray to $new_format_type", -class => "Action", -onClick => 'return validateForm(this.form)' );

        my $transfer_type = param('rm');
        $transfer_options{'Tray'} = "This will track samples individually upon the target plate<P>";
        $transfer_options{'Tray'}
            .= 'Adding to existing tray: ' . Show_Tool_Tip( textfield( -name => 'Existing_Tray', -id => 'Existing_Tray', -size => 15 ), 'optionally indicate a tray that you want aliquot tubes to. For example: tra12345 or 12345. ' ) . &vspace(15);
        $transfer_options{'Tray'}
            .= hidden( -name => 'rm', -value => 'Transfer To Plate from Tube', -force => 1 )
            . hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 )
            . submit( -name => "Transfer To Plate from Tube", -value => "$transfer_type to $new_format_type", -class => "Action", -onClick => 'return validateForm(this.form)' )
            . hidden( -name => "transfer_type", -value => "$transfer_type" );
        $transfer_options{'Tray'} .= hidden( -name => 'Extract', -value => 1 ) if param('rm') eq 'Extract';

        $page .= $rearray->Printout(0);

        $page .= vspace() . define_Layers( -layers => \%transfer_options, -default => 'ReArray', -align => 'left' ) . vspace();    # . "</TABLE>"

    }
    $page .= end_form();
    return $page;
}

####################################
#
#
#
#####################################
sub tube_transfer_to_flowcell {
#####################################
    my %args = &filter_input( \@_ );

    my $dbc               = $args{-dbc};
    my @source_plates     = Cast_List( -list => $args{-source_plates}, -to => 'array' );
    my $format_type       = $args{-format_type};
    my $action            = $args{-action};
    my $daughter_pipeline = $args{-daughter_pipeline};
    my $xfer_table        = HTML_Table->new( -title => 'Assign lane numbers for each tube' );
    my @flowcell_headers  = ( 'Plate', 'Lane', 'Pipeline', 'Scheduled Loading Concentration', 'Plate Comments', 'Change Pipeline' );
    my @pipelines         = $dbc->get_FK_info_list("FK_Pipeline__ID");
    my $pipeline_info     = $dbc->get_FK_info( "FK_Pipeline__ID", $daughter_pipeline );

    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $format_type );
    my ($size) = $dbc->Table_find( "Plate_Format", "Wells", "WHERE Plate_Format_ID=$new_format_id" );

    $xfer_table->Set_Headers( \@flowcell_headers );
    foreach my $plate (@source_plates) {
        my $plate_info = $dbc->get_FK_info( "FK_Plate__ID", $plate );
        my ($pipeline_code) = $dbc->Table_find( 'Plate,Pipeline', 'Pipeline_Code', "WHERE FK_Pipeline__ID = Pipeline_ID and Plate_ID = $plate" );

        my $lane_box = textfield( -name => "PlatePosition${plate}", -force => 1, -size => 5, -maxlength => 1 ) . set_validator( -name => "PlatePosition${plate}", -mandatory => 1, -format => '\d' );
        if ( $size == 1 ) {
            $lane_box = 1;
            $lane_box .= hidden( -name => "PlatePosition${plate}", -force => 1, -value => 1 );
        }

        $xfer_table->Set_Row(
            [   $plate_info . hidden( -name => 'SourcePlate', -value => $plate ),
                $lane_box, $pipeline_code,
                textfield( -name => "Scheduled_Concentration${plate}", -force => 1, -size => 5 ) . set_validator( -name => "Scheduled_Concentration${plate}", -mandatory => 1 ),
                textarea( -name  => "Comments${plate}",                -force => 1 ),
                popup_menu( -name => "New_Pipeline${plate}", -values => \@pipelines, -default => $pipeline_info ),
            ],
            -repeat => 1
        );
    }

    $xfer_table->Set_Row( [ hidden( -name => 'Action', -value => $action ) . submit( -name => "Transfer Tube To FlowCell_Lane", -value => "$action to $format_type", -class => "Action", -onClick => 'return validateForm(this.form)' ) ] );

    return $xfer_table;

}

#################################################################################
# Allow the user to create a plate from a set of plates
##################################################################################
sub create_plate_from_tube {
#####################################
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $source_plates_ref = $args{-source_plates};                             # (ArrayRef) List of source tubes
    my $target_wells_ref  = $args{-target_wells};                              # (ArrayRef) List of target wells
    my $new_format_type   = $args{'-format'};                                  # (Scalar) format of new plate(s)
    my $rack              = $args{-rack};                                      # (Scalar) rack to place Plates on (optional)
    my $test_plate        = $args{-test} || 0;
    my $library           = $args{-library};                                   # (Scalar) Library of the new plate
    my $pipeline_id       = $args{-pipeline_id};                               # (Scalar) Pipeline of the daughter plate.
    my $transfer_type     = $args{-type} || 'Tray';                            # optionally rearray
    my $plate_label       = $args{ -label } || param('Target Plate Label');
    my $transfer_quantity = $args{-quantity};
    my $transfer_units    = $args{-units};
    my $material_type     = $args{-material_type} || param('material_type');
    my $existing_tray     = $args{-existing_tray};
    my $extract           = $args{-extract} || param('Extract');
    my $transfer_action   = $args{-transfer_type} || param('transfer_type');

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'TubeToPlate' );
    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $new_format_type );

    my @all_wells     = @{$target_wells_ref};
    my @source_plates = @{$source_plates_ref};

    # display summary information. This is to allow the user to confirm the transfer before it is done
    $dbc->message("$transfer_action to $library ($transfer_type)");
    my $rearray = new HTML_Table();
    $rearray->Set_Headers( [ "Source Tube", "Well" ] );
    my $counter = 0;
    my %availability;
    foreach my $source_plate (@source_plates) {
        my $plate_info = $dbc->get_FK_info( "FK_Plate__ID", $source_plate );
        my $well_field = "$all_wells[$counter]";
        $rearray->Set_Row( [ $plate_info, $well_field ] );
        my $well = format_well( $well_field, 'nopad' );
        $availability{$well} = $plate_info;
        $counter++;
    }
    $page .= $rearray->Printout(0);

    require alDente::Well;
    my ($well_size) = $dbc->Table_find( "Plate_Format", "Wells", "WHERE Plate_Format_ID = $new_format_id" );
    my ( $min_row, $max_row, $min_col, $max_col, $size ) = &alDente::Well::get_Plate_dimension( -size => $well_size );
    my %preset_colour;
    my $plate_box = &alDente::Container_Views::select_wells_on_plate(
        -dbc            => $dbc,
        -table_id       => 'plate_box',
        -max_row        => $max_row,
        -max_col        => $max_col,
        -input_type     => 'link',
        -availability   => \%availability,
        -preset_colour  => \%preset_colour,
        -tray_flag      => 1,
        -display_simple => 1,
        -action         => ' ',               # for removing the default buttons( 'Select All Wells', 'Clear All Wells' )
    );
    $page .= $plate_box;

    my $label = param('Target Plate Label');
    if ($label) { $page .= hidden( -name => 'Target Plate Label', -value => $label ) }

    $page
        .= submit( -name => "Confirm Transfer To Plate from Tube", -value => "Confirm $transfer_action to $new_format_type as $transfer_type", -class => "Action" )
        . hidden( -name => 'Track As',        -value => $transfer_type )
        . hidden( -name => 'rm',              -value => 'Transfer To Plate from Tube', -force => 1 )
        . hidden( -name => 'confirmed',       -value => 1, -force => 1 )
        . hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );

    # freeze values into a parameter for easy parameter passing
    my %Tube_values;
    $Tube_values{'Source_Plates'} = $source_plates_ref;
    $Tube_values{'Target_Wells'}  = $target_wells_ref;
    $Tube_values{'Plate_Format'}  = $new_format_type;
    $Tube_values{'Rack'}          = $rack;
    $Tube_values{'quantity'}      = $transfer_quantity;
    $Tube_values{'units'}         = $transfer_units;
    $Tube_values{'material_type'} = $material_type;

    #    $Tube_values{'Application'} = $application;
    $Tube_values{'Library'}       = $library;
    $Tube_values{'Pipeline_ID'}   = $pipeline_id;
    $Tube_values{'Existing_Tray'} = $existing_tray;
    $Tube_values{'Extract'}       = $extract;

    my $frozen = Safe_Freeze( -name => "TubeToPlateTransfer", -value => \%Tube_values, -format => 'hidden', -encode => 1 );
    $page .= $frozen;
    $page .= hidden( -name => 'set_unused_wells', -value => param('set_unused_wells') );

    $page .= end_form();
    return $page;
}

#################################################
# insert a rearray into the database to transfer tubes to a plate
#################################################
sub confirm_create_plate_from_tube {
#################################################
    my %args             = &filter_input( \@_ );
    my $dbc              = $args{-dbc};
    my $transfer_type    = $args{-track_as} || param('Track As');                   ## treat target as tray of tubes
    my $set_unused_wells = $args{-set_unused_wells} || param('set_unused_wells');
    my $tube_data        = $args{-tube_data};
    my $action           = $args{-action};

    my $user_id = $dbc->get_local('user_id');

    # thaw parameters from create_plate_from_tube()
    my $thawed = $tube_data || Safe_Thaw( -name => 'TubeToPlateTransfer', -thaw => 1, -encoded => 1 );

    #    my $tray_label;
    my $tray = 0;                                                                   ## flag if transferring as a tray
    if ( $transfer_type =~ /Tray/i ) {
        $tray = 1;

        #       $tray_label = param('Tray Label');
    }
    elsif ( $transfer_type =~ /ReArray/i ) { $tray = 0 }
    else                                   { $dbc->message("Transfer type not defined - assume Rearray") }

    # retrieve parameters from thawed hash
    my $source_plates     = $thawed->{Source_Plates};
    my $target_wells      = $thawed->{Target_Wells};
    my $pipeline_id       = $thawed->{Pipeline_ID};
    my $created           = $thawed->{Plate_Created};
    my $location          = $thawed->{Rack};
    my $transfer_quantity = $thawed->{quantity};
    my $transfer_units    = $thawed->{units};
    my $existing_tray     = $thawed->{Existing_Tray};
    my $material_type     = $thawed->{material_type};
    my $extract           = $thawed->{Extract};

    ## retrieve source wells. Generally, source wells should be N/A for tubes. However, if the tube was created as 1-well Library_Plate, the well is 'A01' in stead of N/A
    my @source_wells;
    my $source_plate_list = join ',', @$source_plates;
    my %plate_well = $dbc->Table_retrieve( 'Plate_Sample,Plate', [ 'Plate_ID', 'Well' ], "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_ID IN ($source_plate_list)", -key => 'Plate_ID' );
    foreach my $plate (@$source_plates) {
        push @source_wells, $plate_well{$plate}{Well}[0];
    }

    my $new_format_id = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $thawed->{'Plate_Format'} );

    my ($target_size) = $dbc->Table_find( "Plate_Format", "Wells", "WHERE Plate_Format_ID=$new_format_id" );

    if ( $target_size =~ /384/ ) {
        $target_size = 384;
    }
    elsif ( $target_size =~ /96/ ) {
        $target_size = 96;
    }
    elsif ( $target_size =~ /\b1\b/ ) {
        $target_size = 1;
    }
    else {
        $dbc->message("Undefined target size ($target_size)");
        return;

        # $target_size = 96;
    }

    #    my $application = $thawed->{Application};
    my $library = $thawed->{Library};

    my $target_plate;

    use Benchmark;

    $dbc->Benchmark('pre_array');
    my $homepage;
    if ($tray) {
        my $material_type_id = $dbc->get_FK_ID( 'FK_Sample_Type__ID', $material_type ) if $material_type && $extract;
        $dbc->message("Transfer to Tray...");
        ## NEW functionality - May 2007 ##
        my $pack = 1;    ## default to packing unless target wells supplied ##
        if ($target_wells) { $pack = 0 }

        # create number of Tubes and Tray record #
        #	&alDente::Tray::create_multiple_trays(-dbc=>$dbc,
        my $Set = new alDente::Container_Set( -dbc => $dbc, -ids => $source_plates );
        $target_plate = $Set->transfer(
            -dbc                => $dbc,
            -plate_type         => 'Tube',
            -type               => $action,              # The type expected in transfer is the action type e.g. transfer, extract, aliquot
            -format             => $new_format_id,
            -combine_list       => $target_wells,
            -new_plate_size     => '1-well',
            -pack               => 1,
            -timestamp          => $created,
            -rack               => $location,
            -volume             => $transfer_quantity,
            -volume_units       => $transfer_units,
            -pipeline_id        => $pipeline_id,
            -existing_tray      => $existing_tray,
            -new_sample_type_id => $material_type_id,
            -show_tray_layout   => 1

                #		       -tray_label => "$tray_label"
        );

        # Go to homepage
        if ($target_plate) {
            my $container = new alDente::Container( -dbc       => $dbc, -id    => $target_plate );
            my $view_obj  = new alDente::Container_Views( -dbc => $dbc, -model => $container );
            $homepage = $view_obj->std_home_page( -Object => $container, -id => $target_plate );
        }
    }
    else {
        $dbc->message("Rearray onto new Plate");

        # call rearray function to create the rearray and the new plate
        require alDente::ReArray;
        my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = 'Clone'" );
        my $ro = new alDente::ReArray( -dbc => $dbc, -dbc => $dbc );
        ( my $rearray_id, $target_plate ) = $ro->create_rearray(
            -dbc            => $dbc,
            -status         => 'Completed',
            -source_plates  => $source_plates,
            -target_wells   => $target_wells,
            -source_wells   => \@source_wells,
            -employee       => $user_id,
            -request_type   => 'Clone ReArray',
            -target_size    => $target_size,
            -target_library => $library,
            -target_rack    => 1,
            -plate_format   => $new_format_id,
            -pipeline       => $pipeline_id,
            -plate_class    => 'ReArray',
            -sample_type_id => $sample_type_id,
            -timestamp      => $created,
            -rack           => $location
        );

        $dbc->Benchmark('mid_array');
        if ($set_unused_wells) { &alDente::ReArray::auto_assign( -dbc => $dbc, -plate => $target_plate, -requested => $rearray_id ) }

        # add Plate_Sample entries
        $ro->update_plate_sample_from_rearray( -request_id => $rearray_id );

        # print barcode
        &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $target_plate );

        # Go to homepage
        if ($target_plate) {
            my $container = new alDente::Container( -dbc => $dbc, -id => $target_plate );
            $homepage = $container->View->std_home_page( -id => $target_plate );
        }
    }
    $dbc->Benchmark('post_array');

    return $homepage;
}

###############################################
# Pool all tubes in the current set to new tube
###############################################
sub pool {
###########
    my $self = shift;

    my %args            = @_;
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $new_format_type = $args{'-format'} || param('Target Plate Format');      # format of new plate(s)
    my $rack            = $args{-rack} || param('FK_Rack__ID');                  # rack to place Plates on (optional)
    my $test_plate      = $args{-test_plate} || param('Test Plate Only') || 0;

    #    my $volumes          = $args{-details};                                          # Details about the pooling
    my $new_sample_type = $args{-new_sample_type} || 'Mixed';                    # The type of the new pooled sample
    my $ids             = $args{ -ids }           || $self->{ids};               # list of source plates
    my $pre_printed     = $args{-pre_printed}     || 0;                          # Whether the new plate was pre-printed
    my $empty           = $args{-empty};

### Error checking ###
    unless ($ids) { $dbc->message("No Set defined"); return; }

    #    unless ($volumes) { $dbc->message("No details specified"); return; }

    my $new_format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $new_format_type );
    unless ( $new_format_id =~ /^\d+$/ ) { $dbc->message("No valid target format ($new_format_type ?) detected"); return; }

    # Check that all source plates are coming from the same library
    my $libs = $dbc->Table_retrieve(
        -table     => 'Plate',
        -fields    => ['FK_Library__Name'],
        -condition => "WHERE Plate_Id IN ($ids)",
        -format    => 'CA',
        -distinct  => 1
    );

    unless ( int(@$libs) == 1 ) {
        if ( $Configs{source_tracking} ) {
            $dbc->error("All source containers should come from the same library (detected @{[int(@$libs)]} libraries)");
            return;
        }
        else {
            $dbc->warning("Trying to pool samples from different libraries (detected @{[int(@$libs)]} libraries) - make sure to update Library");
        }
    }

    my $lib = $libs->[0];

### Parse input
    ## Set Plate Status to Active unless specified to be Pre-Printed ##
    my $plate_status = 'Active';

    ## Get rack if specified or set to Temporary ##
    $rack = &get_FK_ID( $dbc, 'FK_Rack__ID', $rack );
    unless ( $rack =~ /[1-9]/ ) {    ### set as temporary and notify if not put away later..
        ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_Name='Temporary'" );
    }

    ### allow plates to be set as 'Test' plates...otherwise set to 'Production'
    my $TestStatus = 'Production';
    if ($test_plate) { $TestStatus = 'Test'; }

    ### Set Creation date
    my $datestamp = param('Created');
    $datestamp ||= date_time();

    my $plate_set_id = $self->{set_number};

    ### Figure out the size that the new plates are to be tracked on (may NOT be the same as format size) ###
    my ($new_format_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "where Plate_Format_ID = $new_format_id" );
    my $old_size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($ids)", 'Distinct' );
    my $new_plate_size = $new_format_size . '-well';

    my @list_of_plates = split ',', $ids;

    my %Plate_values;
    my $plates_added = 0;

    my @new_plate_set;
    my $added_prep = 0;

    my ( $total_quantity, $total_units, $volumes );

    my $new_plate_set_number;
    if ($pre_printed) {
        $dbc->message("Retrieved Latest Pre-Printed Plates");
        $dbc->Table_update_array( 'Plate', ['Plate_Status'], ['Active'], "where Plate_ID in ($ids)", -autoquote => 1 );
    }
    else {

        # Acquire read lock on Plate table
        #	print "lock Plate,Tube";
        #       <CONSTRUCTION>  .. require more locks when calling other functions.... #
        #	$dbc->lock_tables(-write=>'Plate,Tube',-read=>'Plate_Set');

        # Figure out the total quantity of the new tube from the sources

        $dbc->start_trans('pool_containers');

        ( $total_quantity, $total_units, $volumes ) = $self->_pool_volumes( -ids => $ids, -empty => $empty );

        my $pooled = $self->pool_to_tube( -ids => $ids, -format => $new_format_type, -rack => $rack, -pre_printed => 0, -new_sample_type => $new_sample_type );

        if ($pooled) {
            @new_plate_set        = ($pooled);
            $new_plate_set_number = $self->_next_set();

            #update pooled plate's quantity and volume
            $dbc->Table_update_array( 'Plate', [ 'Current_Volume', 'Current_Volume_Units' ], [ $total_quantity, $total_units ], "WHERE Plate_ID = $pooled", -autoquote => 1 );

            my $comments = param('Plate_Comments');
            if ($comments) {

                #update pooled plate's Plate_Comments
                $dbc->Table_update_array( 'Plate', ['Plate_Comments'], [$comments], "WHERE Plate_ID = $pooled", -autoquote => 1 );
            }

            my $label = param('Plate_Label');
            if ($label) {

                #update pooled plate's Plate_Label
                $dbc->Table_update_array( 'Plate', ['Plate_Label'], [$label], "WHERE Plate_ID = $pooled", -autoquote => 1 );
            }
        }
        else {
            $dbc->error("No pooled tube created");
        }
    }

    ##################### If Plate Barcodes are Pre-Printed ... ######################

    my $new_set_created = 0;
    if ($pre_printed) {
        my $virtual_plates;
        foreach my $new_plate (@new_plate_set) {
            $new_set_created += $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
            $virtual_plates .= "$new_plate,";
        }
        chop $virtual_plates;

        &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $virtual_plates );

        if ($new_set_created) {
            print "<BR><B>Pending Plate Set: $new_plate_set_number</B><BR>";
        }
    }
    else {
        my $number_of_new_plates = scalar(@new_plate_set);
        if ( $number_of_new_plates > 0 ) {
            $self->{ids} = "";
            foreach my $new_plate (@new_plate_set) {
                Test_Message( "<BR>NEW plates created: $new_plate", $testing );
                #### only make plate set if current plate set defined...
                if ( $self->{set_number} ) {
                    $new_set_created = $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
                }
                $self->{ids} .= "$new_plate,";
            }
            chop $self->{ids};
        }

        my $number_in_set = int( my @list = split ',', $self->{ids} );
        if ($new_set_created) {
            $self->reset_set_number($new_plate_set_number);
            $plate_set = $new_plate_set_number;
        }

        &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $self->{ids} );
        my $newids = join ',', @new_plate_set;
        $self->ids($newids);    ## Reset current plate ids..
    }

    ## now ensure that the new pooled plates inherit the attributes of their parents...
    foreach my $new_plate ( split ',', $self->{ids} ) {
        my $object = alDente::Container->new( -dbc => $dbc, -id => $new_plate );
        $object->inherit_attributes();
    }

    $self->{dbc}->finish_trans('pool_containers');

    print "\n<span class=small><B>Current Plates changed to $self->{ids}</B></span><BR>\n";
    return $self->{ids};        ##### indicate transferred and appended Preparation table

}

#####################
sub _pool_volumes {
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'ids,volumes' );
    my $ids     = $args{ -ids };
    my $volumes = $args{-volumes};
    my $empty   = $args{-empty};
    my $dbc     = $args{-dbc} || $self->{dbc};

    $ids = Cast_List( -list => $ids, -to => 'string' );    ## convert to string if necessary ##

    ## retrieve indicated transfer volumes if applicable ##
    my $quantity = param("Transfer_Quantity");
    my $units    = param("Transfer_Quantity_Units");
    foreach my $plate ( split /,/, $ids ) {
        $volumes->{$plate}{quantity} = $quantity;
        $volumes->{$plate}{units}    = $units;
    }

    my $total_quantity = 0;
    my $total_units    = "ml";

    ## auto-set the quantities based upon the input parameters ..##
    if ($quantity) {    ## track individual quantities ##
        my @quantities = split ',', $quantity;
        if ( $ids =~ /,/ && $quantity !~ /,/ ) {    ## set to array of same size as number of plates if necessary
            @quantities = map {$quantity} ( split ',', $ids );
        }
        if ( int(@quantities) == int( my @pool_ids = split ',', $ids ) ) {
            foreach my $plate (@pool_ids) {
                $volumes->{$plate}{quantity} = $quantity;
                $volumes->{$plate}{units}    = $units;
            }
        }
        else { $dbc->message("Number of quantities entered must be single value or equal number of plates"); }
    }
    else {                                          ## assume full volume transferred ##
        $dbc->message("Transferring entire source volumes");
        $empty = 1;
        my %volumes = &Table_retrieve( $self->{dbc}, 'Plate', [ 'Current_Volume', 'Current_Volume_Units', 'Plate_ID' ], "WHERE Plate_ID in ($ids)" );
        my $index = 0;
        while ( defined $volumes{Plate_ID}[$index] ) {
            unless ( $volumes{Plate_ID}[$index] =~ /[1-9]/ ) {next}
            $volumes->{ $volumes{Plate_ID}[$index] }{quantity} = $volumes{Current_Volume}[$index];
            $volumes->{ $volumes{Plate_ID}[$index] }{units}    = $volumes{Current_Volume_Units}[$index];

            #		Message("$volumes{Plate_ID}[$index] : $volumes{Current_Volume}[$index] $volumes{Current_Volume_Units}[$index]");
            $index++;
        }
    }

    my $xfer_qty = join ',', param('Transfer_Quantity');
    if ( $xfer_qty || $volumes ) {
        my %quantities;
        foreach my $source ( sort { $a <=> $b } keys %$volumes ) {
            my $quantity = $volumes->{$source}{quantity};
            my $units    = $volumes->{$source}{units};
            ( $quantity, $units ) = &convert_to_mils( $quantity, $units );    # Normalize the units to mL

            # Figure out the quantity used of the source - run withdraw_sample as a check
            my $container = alDente::Container->new( -dbc => $dbc, -plate_id => $source );
            my $retval = $container->withdraw_sample( -quantity => $quantity, -units => $units, -update => 0, -empty => $empty );

            if ( $retval->{error} ) {
                $dbc->error("Cannot pool sample");

                #		$dbc->unlock_tables();
                return 0;
            }
            else {
                $quantities{$source}{quantity_used}       = $retval->{quantity_used};
                $quantities{$source}{quantity_used_units} = $retval->{quantity_used_units};
            }

            # Tracks the total quantity
            $total_quantity += $quantity;
        }

        # Update the quantity used for the sources
        foreach my $plate ( sort { $a <=> $b } keys %quantities ) {
            my $container    = alDente::Container->new( -dbc => $dbc, -plate_id => $plate );
            my $volume       = $quantities{$plate}{quantity_used};
            my $volume_units = $quantities{$plate}{quantity_used_units};

            if ( $volume && $volume_units ) {
                $container->withdraw_sample( -quantity => $volume, -units => $volume_units, -update => 1 );
            }
        }
    }

    # Get best units
    ( $total_quantity, $total_units ) = &RGTools::Conversion::Get_Best_Units( -amount => $total_quantity, -units => $total_units );

    return ( $total_quantity, $total_units, $volumes );
}

##########################################################################################
#  Pool a list of given identical (same original plate and samples) plates into one plate
#
#  Usage  : my $pooled_plate = $self->pool_identical_plates(-plate_ids=>[1000,1001]);
#  Return : scalar of plate_id (or error)
##########################################################################################
sub pool_identical_plates {
###########################
    my $self         = shift;
    my %args         = filter_input( \@_, -mandatory => "plate_ids" );
    my $plate_ids    = $args{-plate_ids};                                       ## list of plate ids
    my $user_id      = $args{-user_id} || $self->{dbc}->get_local('user_id');
    my $parent_plate = $args{-parent_plate};                                    ## set the parent plate of the pooled plate (for plate history)
    my $format       = $args{'-format'};                                        ## Format of the pooled plate
    my $pipeline     = $args{-pipeline};                                        ## pipeline of the pooled plate
    my $volumes      = $args{-volumes};
    my $empty        = $args{-empty};                                           ## empty source plates if applicable
    my $no_print     = $args{-no_print};

    if ($format) {
        $format = $self->{dbc}->get_FK_ID( 'FK_Plate_Format__ID', $format );
    }
    if ($pipeline) {
        $pipeline = $self->{dbc}->get_FK_ID( 'FK_Pipeline__ID', $pipeline );
    }

    my @plate_ids = Cast_List( -list => $plate_ids, -to => 'Array' );
    my $plates    = Cast_List( -list => $plate_ids, -to => 'String' );

    my @plate_types = $self->{dbc}->Table_find( 'Plate', 'distinct Plate_Type', "WHERE Plate_ID IN ($plates)" );
    my $plate_type;
    if ( int(@plate_types) == 1 ) { $plate_type = $plate_types[0]; }
    else                          { $self->{dbc}->message("Can't pool mixture of plate type"); return 0; }

    ## Begin ignoring plates with all unused wells
    if ( $plate_type eq 'Library_Plate' ) {
        my %plate_well_info = $self->{dbc}->Table_retrieve( 'Library_Plate,Plate', [ 'Plate_ID', 'Unused_Wells', 'Plate_Size' ], "WHERE FK_Plate__ID = Plate_ID AND Plate_ID IN ($plates)" );
        my @filter_plates;
        my $index = -1;
        while ( defined $plate_well_info{Plate_ID}[ ++$index ] ) {
            my ( $plate_id, $unused_wells, $plate_size ) = ( $plate_well_info{Plate_ID}[$index], $plate_well_info{Unused_Wells}[$index], $plate_well_info{Plate_Size}[$index] );
            $unused_wells = &format_well($unused_wells);
            my @wells_used = &alDente::Library_Plate::not_wells( $unused_wells, $plate_size );

            if ( @wells_used or !$unused_wells ) { push @filter_plates, $plate_id }
            else                                 { $self->{dbc}->message("Ignoring blank plate $plate_id") }
        }
        @plate_ids = Cast_List( -list => \@filter_plates, -to => 'Array' );
        $plates    = Cast_List( -list => \@filter_plates, -to => 'String' );
    }
    if ( !$plates ) { return 0 }
    ## End ignoring plates with all unused wells

    ## Check each plate to ensure that they have the same original plate
    my %plate_info = $self->{dbc}->Table_retrieve(
        'Plate', [ 'FK_Library__Name', 'Plate_Number', 'Parent_Quadrant',
            'Plate_Parent_Well', 'FKOriginal_Plate__ID', 'Plate_Type' ],
        "WHERE Plate_ID IN ($plates)",
        -distinct => 1,
        -group_by => "FK_Library__Name,Plate_Number,Parent_Quadrant,Plate_Parent_Well"
    );

    my $identical_plates = scalar @{ $plate_info{FK_Library__Name} };

    require SDB::DB_Form;
    my $db_form = SDB::DB_Form->new( -dbc => $self->{dbc} );
    my $plate_data = $self->{dbc}->merge_data(
        -tables        => "Plate,$plate_type",
        -primary_list  => \@plate_ids,
        -primary_field => 'Plate_ID'
    );
    delete $plate_data->{FK_Plate__ID};    ## in case user is pooling one plate

    unless ( $identical_plates == 1 ) {
        ## non-identical plates ## merge from other module later (?)
        $self->{dbc}->error("NON-identical plates");
        print Dumper \%plate_info;
        return 0;
    }

    my $original_plate  = $plate_info{FKOriginal_Plate__ID}[0];
    my $parent_quadrant = $plate_info{Parent_Quadrant}[0];

    ## Find the source wells
    my @plate_source_wells = $self->{dbc}->Table_find( 'Plate_Sample', 'Well', "WHERE FKOriginal_Plate__ID = $original_plate" );
    my @content_type_ids = $self->{dbc}->Table_find( 'Plate', 'distinct FK_Sample_Type__ID', "WHERE Plate_ID IN ($plates)" );
    my $content_type_id;
    if ( int(@content_type_ids) == 1 ) {
        $content_type_id = $content_type_ids[0];
    }
    else {
        $content_type_id = $self->{dbc}->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = 'Mixed'" );
    }
    $plate_data->{FK_Sample_Type__ID} = $content_type_id;
    if ($parent_quadrant) {
        @plate_source_wells = &alDente::Well::Convert_Wells( -dbc => $self->{dbc}, -wells => \@plate_source_wells, -quadrant => $parent_quadrant );
    }

    ## Find the target wells

    my @target_wells;

    my @source_plates;
    $plate_data->{FK_Employee__ID} = $self->{dbc}->get_local('user_id');
    ## Set the parent plate ID for the pooled plate
    if ($parent_plate) {
        $plate_data->{FKParent_Plate__ID} = $parent_plate;
    }
    else {
        $plate_data->{FKParent_Plate__ID} = $plate_ids[0];
    }

    ## Set the plate format if one is supplied
    if ($format) {
        $plate_data->{FK_Plate_Format__ID} = $format;
    }
    if ($pipeline) {
        $plate_data->{FK_Pipeline__ID} = $pipeline;
    }
    $plate_data->{Plate_Created} = &date_time();
    if ( $plate_data->{Plate_Comments} ) {
        $plate_data->{Plate_Comments} .= "; Pooled from identical plates";
    }
    else {
        $plate_data->{Plate_Comments} = "Pooled from identical plates";
    }

    my ( $total_quantity, $total_units ) = $self->_pool_volumes( -ids => \@plate_ids, -volumes => $volumes, -empty => $empty );
    $plate_data->{Current_Volume}       = $total_quantity;
    $plate_data->{Current_Volume_Units} = $total_units;

    my @fields = keys %{$plate_data};
    my @values = values %{$plate_data};

    my $type = $plate_data->{Plate_Type};

    $self->{dbc}->smart_append(
        -tables    => "Plate,$type",
        -fields    => \@fields,
        -values    => \@values,
        -autoquote => 1
    );

    my $target_plate_id = @{ $self->{dbc}->newids('Plate') }[0];
    my @source_wells;
    my $number_of_source_wells = int(@plate_source_wells);

    foreach my $source_plate (@plate_ids) {
        my @sources_pla = ($source_plate) x $number_of_source_wells;
        push @source_plates, @sources_pla;
        push @source_wells,  @plate_source_wells;
    }

    ## Merge the data between the plates.. attributes and fields
    ## create new target plate
    ## Set the data for the new pooled plate

    ## create pool rearray from source plates to target plate (new original plate) with new samples
    my $rearray = alDente::ReArray->new( -dbc => $self->{dbc} );
    my ( $rearray_request, $pooled_plate ) = $rearray->create_rearray(
        -source_plates    => \@source_plates,
        -employee         => $user_id,
        -source_wells     => \@source_wells,
        -target_wells     => \@source_wells,
        -request_type     => 'Pool Rearray',
        -request_status   => 'Completed',
        -target_size      => '384-well',
        -target_plate_id  => $target_plate_id,
        -rearray_comments => "Pool Identical Plates",
        -plate_status     => 'Active',
        -create_plate     => 0
    );
    $rearray->update_plate_sample_from_rearray( -request_id => $rearray_request, -pool => 1 );

    if ( !$no_print ) { &alDente::Barcoding::PrintBarcode( $self->{dbc}, 'Plate', $pooled_plate ); }
    return $pooled_plate;
}

##############################
# View plate set ancestry
#
##############################
sub view_Set_ancestry {
####################
    my $self = shift;

    my $dbc = $self->{dbc};

    my $display;
    $display = HTML_Table->new();
    $display->Set_Title( "<B>Ancestry of Set Number $self->{set_number}</B>", fsize => '-1' );
    $display->Set_Width('500');
    $display->Set_Class('small');

    my $col = 1;

    # Get parent sets

    my $parents = $self->get_parent_sets( -sets => $self->{set_number} );
    if ($parents) {
        if ( $parents->{parent_sources} ) {
            my $parents_list;
            foreach my $parent ( @{ $parents->{parent_sources} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $parent, "&Grab+Plate+Set=1&Plate+Set+Number=$parent", $Settings{LINK_COLOUR} );
                $parents_list .= "$link<BR>";
            }
            if ($parents_list) {
                $display->Set_Column( [$parents_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                #        $display->Set_sub_title('Parent Sets',int(@{$parents->{parent_sources}}),'mediumbluebw');
                $display->Set_sub_title( 'Parent Sets', 1, 'mediumbluebw' );
            }
        }

        if ( $parents->{extraction_sources} ) {
            my $parents_list;
            foreach my $parent ( @{ $parents->{extraction_sources} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $parent, "&Grab+Plate+Set=1&Plate+Set+Number=$parent", $Settings{LINK_COLOUR} );
                $parents_list .= "$link<BR>";
            }
            if ($parents_list) {
                $display->Set_Column( [$parents_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                $display->Set_sub_title( 'Extracted from Sets', 1, 'darkbluebw' );
            }
        }
        if ( $parents->{pooling_sources} ) {
            my $parents_list;
            foreach my $parent ( @{ $parents->{pooling_sources} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $parent, "&Grab+Plate+Set=1&Plate+Set+Number=$parent", $Settings{LINK_COLOUR} );
                $parents_list .= "$link<BR>";
            }
            if ($parents_list) {
                $display->Set_Column( [$parents_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                $display->Set_sub_title( 'Pooled from Sets', 1, 'darkbluebw' );
            }
        }

    }

    # Get sister sets
    my @sisters = @{ $self->get_sister_sets( -sets => $self->{set_number} ) };
    if ( int(@sisters) > 1 ) {    ## not just THIS set.. ##
        my $sis_list = '';
        foreach my $sis (@sisters) {
            my $link .= &Link_To( $dbc->config('homelink'), $sis, "&Grab+Plate+Set=1&Plate+Set+Number=$sis", $Settings{LINK_COLOUR} );
            $sis_list .= "$link<BR>";
        }
        if ($sis_list) {
            $display->Set_Column( [$sis_list] );
            $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );
            ##
            $display->Set_sub_title( 'Sister Sets', 1, 'lightredbw' );
        }
    }

    # Get child sets
    my $children = $self->get_child_sets( -sets => $self->{set_number} );
    if ($children) {
        if ( $children->{child_targets} ) {
            my $children_list = '';
            foreach my $child ( @{ $children->{child_targets} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $child, "&Grab+Plate+Set=1&Plate+Set+Number=$child", $Settings{LINK_COLOUR} );
                $children_list .= "$link<BR>";
            }
            if ($children_list) {
                $display->Set_Column( [$children_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                $display->Set_sub_title( 'Child Sets', 1, 'lightredbw' );
            }
        }

        if ( $children->{extraction_targets} ) {
            my $children_list;
            foreach my $child ( @{ $children->{extraction_targets} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $child, "&Grab+Plate+Set=1&Plate+Set+Number=$child", $Settings{LINK_COLOUR} );
                $children_list .= "$link<BR>";
            }
            if ($children_list) {
                $display->Set_Column( [$children_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                $display->Set_sub_title( 'Extracted to Sets', 1, 'darkbluebw' );
            }
        }

        if ( $children->{pooling_targets} ) {
            my $children_list;
            foreach my $child ( @{ $children->{pooling_targets} } ) {
                my $link .= &Link_To( $dbc->config('homelink'), $child, "&Grab+Plate+Set=1&Plate+Set+Number=$child", $Settings{LINK_COLOUR} );
                $children_list .= "$link<BR>";
            }
            if ($children_list) {
                $display->Set_Column( [$children_list] );
                $display->Set_Cell_Colour( 1, $col++, 'lightgrey' );

                $display->Set_sub_title( 'Pooled to Sets', 1, 'darkbluebw' );
            }
        }
    }

    return $display->Printout(0);    ## print out Ancestry Table
}

##############################
# Get parent plate sets
# Return: parent plate set numbers (arrayref)
##############################
sub get_parent_sets {
##################
    # First handle method VS function call
    unless ( UNIVERSAL::isa( $_[0], 'Container_Set' ) || UNIVERSAL::isa( $_[0], 'alDente::Container_Set' ) ) {    # Function call
        my %args    = @_;
        my $dbc     = $args{-dbc};
        my $cnt_set = alDente::Container_Set->new( -dbc => $dbc );
        return $cnt_set->get_parent_sets(%args);
    }

    my $self      = shift;
    my %args      = @_;
    my $sets      = $args{-sets} || 0;
    my $recursive = $args{-recursive} || 0;                                                                       ## Whether to recursively get parents (i.e. more than 1 generation)
    my $parents   = $args{-parents};                                                                              ## Existing parents info
    my $format    = $args{'-format'} || 'hash';                                                                   ## Return format
    my $dbc       = $args{-dbc} || $self->{dbc};

    my %parents;
    $parents{all_sources}        = [];
    $parents{parent_sources}     = [];
    $parents{extraction_sources} = [];
    $parents{pooling_sources}    = [];
    $parents{set_sources}        = [];

    my @curr_sources;

    if ($parents) { %parents = %$parents }

    $sets = Cast_List( -list => $sets, -to => 'string' );

    unless ( defined $parents{all_sources} )        { $parents{all_sources}        = [] }
    unless ( defined $parents{parent_sources} )     { $parents{parent_sources}     = [] }
    unless ( defined $parents{extraction_sources} ) { $parents{extraction_sources} = [] }
    unless ( defined $parents{pooling_sources} )    { $parents{pooling_sources}    = [] }
    unless ( defined $parents{set_sources} )        { $parents{set_sources}        = [] }

    # retrieve all parents depending on plate set ancestry
    # Regular ancestry
    my @parent_plate_set = $dbc->Table_find( 'Plate_Set', 'FKParent_Plate_Set__Number', "WHERE Plate_Set_Number in ($sets) AND FKParent_Plate_Set__Number NOT IN ($sets)", 'Distinct' );

    if ( int(@parent_plate_set) ) {
        push( @{ $parents{set_sources} }, @parent_plate_set );
        push( @curr_sources,              @parent_plate_set );
        push( @{ $parents{all_sources} }, @parent_plate_set );
    }

    # Regular ancestry
    my @regs = $dbc->Table_find(
        'Plate_Set AS Child_Plate_Set, Plate AS Child_Plate, Plate_Set AS Parent_Plate_Set, Plate AS Parent_Plate',
        'Parent_Plate_Set.Plate_Set_Number',
        "WHERE Child_Plate_Set.FK_Plate__ID=Child_Plate.Plate_ID AND Parent_Plate_Set.FK_Plate__ID=Parent_Plate.Plate_ID AND Child_Plate.FKParent_Plate__ID=Parent_Plate.Plate_ID AND Child_Plate_Set.Plate_Set_Number IN ($sets)  AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Parent_Plate_Set.Plate_Set_Number",
        'Distinct'
    );

    if ( int(@regs) ) {
        push( @{ $parents{parent_sources} }, @regs );
        push( @curr_sources,                 @regs );
        push( @{ $parents{all_sources} },    @regs );
    }

=pod
    # Extraction ancestry
    my @extractions = $dbc->Table_find('Plate_Set AS Child_Plate_Set, Plate_Set AS Parent_Plate_Set, Extraction','Parent_Plate_Set.Plate_Set_Number',"WHERE Child_Plate_Set.FK_Plate__ID=Extraction.FKTarget_Plate__ID AND Parent_Plate_Set.FK_Plate__ID=Extraction.FKSource_Plate__ID AND Child_Plate_Set.Plate_Set_Number IN ($sets)  AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Parent_Plate_Set.Plate_Set_Number",'Distinct');
    if (int(@extractions)) {
	push(@{$parents{extraction_sources}}, @extractions);
	push(@curr_sources, @extractions);
	push(@{$parents{all_sources}}, @extractions);
    }

    # Pooling ancestry
    my @poolings = $dbc->Table_find('Plate_Set AS Child_Plate_Set, Plate_Set AS Parent_Plate_Set, Sample_Pool, PoolSample','Parent_Plate_Set.Plate_Set_Number',"WHERE Child_Plate_Set.FK_Plate__ID=Sample_Pool.FKTarget_Plate__ID AND Parent_Plate_Set.FK_Plate__ID=PoolSample.FK_Plate__ID AND Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND Child_Plate_Set.Plate_Set_Number IN ($sets) AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Parent_Plate_Set.Plate_Set_Number",'Distinct');
    if (int(@poolings)) {
	push(@{$parents{pooling_sources}}, @poolings);
	push(@curr_sources, @poolings);
	push(@{$parents{all_sources}}, @poolings);	
    }
=cut

    my $index = 0;
    if ( $recursive-- && int(@curr_sources) ) {
        %parents = %{ $self->get_parent_sets( -sets => \@curr_sources, -parents => \%parents, -recursive => $recursive ) };
    }

    if ( $format =~ /list/ ) {
        return join( ",", @{ $parents{all_sources} } );
    }
    else {
        return \%parents;
    }
}

##############################
# Get sister plate sets
# Return:  array reference for list of sister sets - containing at least one plate in common with current set(s)
##############################
sub get_sister_sets {

    # First handle method VS function call
    unless ( UNIVERSAL::isa( $_[0], 'Container_Set' ) || UNIVERSAL::isa( $_[0], 'alDente::Container_Set' ) ) {    # Function call
        my %args = @_;

        my $dbc = $args{-dbc};
        my $cnt_set = alDente::Container_Set->new( -dbc => $dbc );

        return $cnt_set->get_sister_sets(%args);
    }

    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc} || $args{-dbc};
    my $sets = $args{-sets} || 0;
    $sets = Cast_List( -list => $sets, -to => 'string' );

    my $plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number in ($sets)", 'Distinct' );

    my @sister_sets = $dbc->Table_find( 'Plate_Set', 'Plate_Set_Number', "WHERE FK_Plate__ID in ($plates)", 'Distinct' );
    return \@sister_sets;
}
##############################
# Get child plate sets
##############################
sub get_child_sets {

    # First handle method VS function call
    unless ( UNIVERSAL::isa( $_[0], 'Container_Set' ) || UNIVERSAL::isa( $_[0], 'alDente::Container_Set' ) ) {    # Function call
        my %args = @_;

        my $dbc = $args{-dbc};
        my $cnt_set = alDente::Container_Set->new( -dbc => $dbc );

        return $cnt_set->get_child_sets(%args);
    }

    my $self      = shift;
    my %args      = @_;
    my $dbc       = $self->{dbc} || $args{-dbc};
    my $sets      = $args{-sets} || 0;
    my $recursive = $args{-recursive} || 0;        ## Whether to recursively get parents (i.e. more than 1 generation)
    my $children  = $args{-children};              ## Existing children info
    my $format    = $args{'-format'} || 'hash';    ## Return format

    my %children;
    my @curr_targets;

    if ($children) { %children = %$children }

    $sets = Cast_List( -list => $sets, -to => 'string' );

    unless ( defined $children{all_targets} )        { $children{all_targets}        = [] }
    unless ( defined $children{parent_targets} )     { $children{parent_targets}     = [] }
    unless ( defined $children{extraction_targets} ) { $children{extraction_targets} = [] }
    unless ( defined $children{pooling_targets} )    { $children{pooling_targets}    = [] }

    # Regular ancestry
    my @regs = $dbc->Table_find(
        'Plate_Set AS Child_Plate_Set, Plate AS Child_Plate, Plate_Set AS Parent_Plate_Set, Plate AS Parent_Plate',
        'Child_Plate_Set.Plate_Set_Number',
        "WHERE Child_Plate_Set.FK_Plate__ID=Child_Plate.Plate_ID AND Parent_Plate_Set.FK_Plate__ID=Parent_Plate.Plate_ID AND Child_Plate.FKParent_Plate__ID=Parent_Plate.Plate_ID AND Parent_Plate_Set.Plate_Set_Number IN ($sets)  AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Child_Plate_Set.Plate_Set_Number",
        'Distinct'
    );
    if ( int(@regs) ) {
        push( @{ $children{child_targets} }, @regs );
        push( @curr_targets,                 @regs );
        push( @{ $children{all_targets} },   @regs );
    }

    # Extraction ancestry
    my @extractions = $dbc->Table_find(
        'Plate_Set AS Child_Plate_Set, Plate_Set AS Parent_Plate_Set, Extraction',
        'Child_Plate_Set.Plate_Set_Number',
        "WHERE Child_Plate_Set.FK_Plate__ID=Extraction.FKTarget_Plate__ID AND Parent_Plate_Set.FK_Plate__ID=Extraction.FKSource_Plate__ID AND Parent_Plate_Set.Plate_Set_Number IN ($sets)  AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Child_Plate_Set.Plate_Set_Number",
        'Distinct'
    );
    if ( int(@extractions) ) {
        push( @{ $children{extraction_targets} }, @extractions );
        push( @curr_targets,                      @extractions );
        push( @{ $children{all_targets} },        @extractions );
    }

    # Pooling ancestry
    my @poolings = $dbc->Table_find(
        'Plate_Set AS Child_Plate_Set, Plate_Set AS Parent_Plate_Set, Sample_Pool, PoolSample',
        'Child_Plate_Set.Plate_Set_Number',
        "WHERE Child_Plate_Set.FK_Plate__ID=Sample_Pool.FKTarget_Plate__ID AND Parent_Plate_Set.FK_Plate__ID=PoolSample.FK_Plate__ID AND Sample_Pool.FK_Pool__ID=PoolSample.FK_Pool__ID AND Parent_Plate_Set.Plate_Set_Number IN ($sets)  AND Parent_Plate_Set.Plate_Set_Number NOT IN ($sets) ORDER BY Child_Plate_Set.Plate_Set_Number",
        'Distinct'
    );
    if ( int(@poolings) ) {
        push( @{ $children{pooling_targets} }, @poolings );
        push( @curr_targets,                   @poolings );
        push( @{ $children{all_targets} },     @poolings );
    }

    if ( $recursive-- && int(@curr_targets) ) {
        %children = %{ $self->get_child_sets( -sets => \@curr_targets, -children => \%children, -recursive => $recursive ) };
    }

    if ( $format =~ /list/ ) {
        return join( ",", @{ $children{all_targets} } );
    }
    else {
        return \%children;
    }
}

##############################
# public_functions           #
##############################

##############################
#
#  This method defines the homepage of a container set, which indicates the plates inside the container set and some details about those plates
#
################
sub home_page {
################
    my %args       = &filter_input( \@_, -args => 'dbc,set_number,brief' );
    my $dbc        = $args{-dbc};
    my $set_number = $args{ -set_number };
    my $brief      = $args{-brief};

    unless ($brief) {
        &Table_retrieve_display(
            $dbc,
            'Plate_Set,Plate,Rack,Employee',
            [ 'FK_Plate__ID', 'Plate_Created', 'Employee_Name', 'Plate_Status', 'Failed', 'Rack_Alias' ],
            "WHERE FK_Rack__ID=Rack_ID and FK_Plate__ID=Plate_ID AND Employee_ID=FK_Employee__ID AND Plate_Set_Number=$set_number",
            -title => "Content of Plate Set $set_number"
        );
    }
    my $plate_ids = join( ',', $dbc->Table_find( "Plate_Set", "FK_Plate__ID", "WHERE Plate_Set_Number=$set_number" ) );

    print &Link_To( $dbc->config('homelink'), "Reprint Plate Set $set_number", "&Barcode_Event=Re-Print+Plate+Labels&Mark=$plate_ids", $Settings{LINK_COLOUR} );

    return 0;
}

####################
# Global functions #
####################
# Given a list of plate check to see if the list contain parent of any other plate in the list
# if there is, return 1, else return 0
sub recursive_set {
    my %args = &filter_input( \@_, -args => 'dbc,ids' );
    my $dbc  = $args{-dbc};
    my $ids  = $args{ -ids };

    my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $ids, -no_sample => 'no_sample' );

    my @list = @{ $Ancestry{list} } if defined $Ancestry{list};
    shift @list;    #i.e. take out self

    my $parents = join ',', @list;

    my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( $ids, $parents );

    if   ( @$intersec && $ids && $parents ) { return 1 }
    else                                    { return 0 }

}

##############################
# private_methods            #
##############################

##################
sub _recover_Set {
##################
    #
    # Recover possible Sets given set member(s)
    #
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $force = $args{-force};         # force to last set if more than one exists...

    my $member_id  = $self->{ids};           # id or barcode of current plate
    my $set_number = $self->{set_number};    # choose this plate set
    my $dbc        = $self->{dbc};

    $member_id = get_aldente_id( $dbc, $member_id, $self->{member_table}, -validate => $self->{validate}, -qc_check => 1 );

    #    if ($member_id=~/pla(\d+)/i) {$member_id=$1;}
    unless ($member_id) {
        $dbc->message("No valid plates chosen");
        &main::leave();
    }

    unless ($set_number) {
        my $set = join ',', $dbc->Table_find( $TABLE, $self->{set_number_field}, "where $self->{member_field} in ($member_id)", -distinct => 1 );

        if ( $set =~ /^(\d+)[,]/ ) {
            ## more than one potential set ##

            ## compare number of plates in possible sets ##
            my @plates     = split /,/, $member_id;
            my $count      = int(@plates);
            my $valid_sets = join ',', $dbc->Table_find( $TABLE, $self->{set_number_field}, "WHERE $self->{set_number_field} IN ($set) GROUP BY $self->{set_number_field} HAVING COUNT(*) = $count ORDER BY Plate_Set_Number" );

            if ( $valid_sets =~ /^\d+$/ ) {
                ## found only one set with proper number of plates ##
                $set_number = $valid_sets;
            }
            elsif ( $force && $valid_sets =~ /,(\d+)$/ ) {
                $set_number = $1;    ## choose last set if forced.
            }
            else {
                ## unable to uniquely distinguish which set to recover ##
                $self->_choose_set( -id => $member_id, -set => $set );
                print "(Set Ambiguous) : $set", "<br>";
                return 0;
            }
        }
        elsif ( $set == "" ) {
            $dbc->warning("No Set found containing member: $member_id");
            return 0;
        }
        else {
            $set_number = $set;
        }
    }

    if ($set_number) {
        my $list = join ',', $dbc->Table_find( $TABLE, $self->{member_field}, "where $self->{set_number_field}=$set_number ORDER BY $self->{primary_field}" );
        $self->ids($list);    ## recover in original order
    }

    unless ( $set_number && ( $self->{ids} =~ /\d+/ ) ) {
        $dbc->message("Invalid Set (?) ");
        $set_number = '';
        return $set_number;
    }

    if ( !$scanner_mode ) {
        $dbc->message("Set $set_number recovered (Plate ID: $current_plates).");
    }
    else { print "Set $set_number: ($current_plates)"; }
    $self->{set_number} = $set_number;

    return $set_number;
}

##################
sub _choose_set {
##################
    #
    # prompt user to choose from a list of possible sets
    #
    my $self = shift;
    my %args = @_;

    my $member_id  = $args{-id};
    my $set_number = $args{-sets};
    my $dbc        = $self->{dbc} || $args{-dbc};

    $set_number = join ',', $dbc->Table_find( $TABLE, $self->{set_number_field}, "where $self->{member_field} in ($member_id)", 'Distinct' ) unless ($set_number);

    $dbc->warning("more than one plate set using plate $member_id");

    my @set_number_choices = split ',', $set_number;
    @set_number_choices = sort { $b <=> $a } @set_number_choices;

    my $protocol = param('Protocol');

    print lbr, alDente::Form::start_alDente_form( $dbc, 'plate' ), hidden( -name => 'Protocol', -force => 1, -value => $protocol );

    my $set_table = HTML_Table->new( -border => 1 );
    $set_table->Set_Headers( [ 'Set', 'Plates' ] );
    foreach my $set_number_choice (@set_number_choices) {
        unless ($set_number_choice) { next; }
        my @more_info
            = $dbc->Table_find( "$TABLE, $self->{member_table}, Employee", "$self->{member_field}, FK_Library__Name, Plate_Number, Initials", "where $self->{set_number_field}=$set_number_choice and Employee_ID=FK_Employee__ID and Plate_ID=FK_Plate__ID" );

        my $contents;
        foreach my $info (@more_info) {
            ( my $pid, my $ln, my $pn, my $init ) = split ',', $info;
            $contents .= "$self->{member_table}: $pid - $ln $pn $init<BR>";
        }
        my $set_radio_btn = radio_group( -name => 'Chosen Set', -values => [$set_number_choice], -labels => {$set_number_choice}, -default => 'x' );
        $set_table->Set_Row( [ $set_radio_btn, $contents ] );
    }
    $set_table->Printout();

    print submit( -name => 'Recover Set', -class => "Std" ), "</FORM>", lbr;

    &main::leave();

    return 1;
}

########################
sub _next_set {
########################
    #
    # Find next Set Number to be defined (autoincrements)
    #
    my $self  = shift;
    my $dbc   = $self->{dbc};
    my $count = 0;

    my $next_set = $dbc->Table_append_array( 'Defined_Plate_Set', [ 'Plate_Set_Defined', 'FK_Employee__ID' ], [ &date_time(), $dbc->get_local('user_id') ], -autoquote => 1 );
    return $next_set;

    ## below should be obsolete - vulnerable to duplication if simultaneous plate_set definitions taking place ##
    #    my @sets = $dbc->Table_find($TABLE,$self->{set_number_field},'','Distinct');
    #    foreach my $set_number (@sets) {
    #	if ($set_number > $count) {
    #	    $count = $set_number;
    #	}
    #    }
    #    my $next_set = $count + 1;##
    #
    #    return $next_set;
}

###############################################
sub pool_to_tube {
###############################################
    # Description:
    #   Pool all tubes in the current set to new tube
    # Input:
    #   -ids       		ids of plates to be pooled
    #   -format       		format of the new plate
    #   -rack           	rack to place Plates on
    #   -new_sample_type        the type of the new pooled sample
    #	-pre_printed		whether the new plate was pre-printed
    # output:
    #   returns the new plate id
    # <snip>
    # $pooled = $Set->protocol_pool_to_tube( -ids => $these_plates, -format => $new_format, -rack => $rack_id, -pre_printed => 1, -details => $details, -new_sample_type => $new_sample_type );
    # </snip>
####################################
    my $self            = shift;
    my %args            = @_;
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $new_format_type = $args{'-format'} || param('Target Plate Format');      # format of new plate(s)
    my $rack            = $args{-rack} || param('FK_Rack__ID');                  # rack to place Plates on
    my $test_plate      = $args{-test_plate} || param('Test Plate Only') || 0;
    my $new_sample_type = $args{-new_sample_type} || 'Mixed';                    # The type of the new pooled sample
    my $ids             = $args{ -ids } || $self->{ids};                         # list of source plates
    my $pre_printed     = $args{-pre_printed} || 0;                              # Whether the new plate was pre-printed
    my $empty           = $args{-empty};

    unless ($ids) { $dbc->message("No Set defined"); return; }

    my $format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $new_format_type );
    unless ( $format_id =~ /^\d+$/ ) { $dbc->message("No valid target format ($new_format_type ?) detected"); return; }

    my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "where Sample_Type = '$new_sample_type'" );

    # Check that all source plates are coming from the same library
    my $libs = $dbc->Table_retrieve(
        -table     => 'Plate',
        -fields    => ['FK_Library__Name'],
        -condition => "WHERE Plate_Id IN ($ids)",
        -format    => 'CA',
        -distinct  => 1
    );

    unless ( int(@$libs) == 1 ) {
        if ( $Configs{source_tracking} ) {
            $dbc->message("Error: All source containers should come from the same library (detected @{[int(@$libs)]} libraries)");
            return;
        }
        else {
            $dbc->message("Warning: Trying to pool samples from different libraries (detected @{[int(@$libs)]} libraries) - make sure to update Library");
        }
    }

    my @source_plates        = split ',', $ids;
    my @rearray_source_wells = ('N/A') x scalar(@source_plates);
    my @rearray_target_wells = ('N/A') x scalar(@source_plates);

    # Get info from the source plate
    my $plate_info = $dbc->Table_retrieve( -table => 'Plate', -fields => [ 'FK_Library__Name', 'FK_Pipeline__ID', 'Plate_Label' ], -condition => "WHERE Plate_ID in ($ids) ORDER BY Plate_Number DESC LIMIT 1", -format => 'RH' );
    my $pipeline = $plate_info->{FK_Pipeline__ID};

    # Figure out the size that the new plates are to be tracked on (may NOT be the same as format size) ###
    my ($format_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "where Plate_Format_ID = $format_id" );
    my $target_plate_size = $format_size . '-well';

    my $create_plate = ( $pre_printed + 1 ) % 2;
    my $library      = $libs->[0];
    my $plate_type   = 'Tube';

    my $rearray = alDente::ReArray->new( -dbc => $dbc );

    my ( $rearray_request, $target_plate ) = $rearray->create_rearray(
        -source_plates    => \@source_plates,              # List of source plate ids
        -source_wells     => \@rearray_source_wells,       # N/A x scalar
        -target_wells     => \@rearray_target_wells,       # N/A x scalar
        -employee         => $dbc->get_local('user_id'),
        -pipeline         => $pipeline,
        -request_type     => "Pool Rearray",
        -request_status   => 'Completed',
        -target_size      => $target_plate_size,           #size for target tube
        -create_plate     => $create_plate,                # 0 for pre-printed 1 for create
        -rearray_comments => "",
        -target_library   => $library,                     # assuming all source samples belong to the same library
        -plate_format     => $format_id,                   # target plate format id
        -sample_type_id   => $sample_type_id,              # target sample type id
        -plate_status     => 'Active',
        -target_rack      => $rack,
        -plate_class      => 'ReArray',
        -plate_type       => $plate_type,                  # 'Tube'
    );

    if ($target_plate) {
        $rearray->create_pool_sample(
            -dbc                  => $dbc,
            -library              => $library,
            -target_plate         => $target_plate,
            -source_plates        => \@source_plates,
            -rearray_request      => $rearray_request,
            -rearray_source_wells => \@rearray_source_wells,
            -rearray_target_wells => \@rearray_target_wells
        );
        return $target_plate;
    }
}

#########################################
##
##  Check for non-active plates
#####################
#sub _check_valid_plates {
#####################
#    my %args = &filter_input(\@_,-args=>'plates');
#    my $plates = $args{-plates};
#    # first check to see if there are any plates (sanity check)
#    unless ($plates) {
#	Message("ERROR: No plates available to be listed");
#	&main::leave();
#	return;
#    }
#    # First set the plate status of all the members.  If status are 'Failed', 'Thrown Out', 'Reserved', 'Exported' then do not allow saving the set
#    my %row = &Table_retrieve($dbc->dbc(),'Plate',['Plate_ID','Plate_Status'],"WHERE Plate_Status NOT IN ('Active','Temporary') AND Plate_ID in ($plates)");

#    my $index=0;
#    if(%row) {
#	my %bad_plates;
#	while(defined $row{Plate_ID}->[$index]) {
#	    push(@{$bad_plates{$row{Plate_Status}->[$index]}},$row{Plate_ID}->[$index]);
#	    $index++;
#	}

#	Message("ERROR: $index problematic containers found. Can not save/recover this set");

#	foreach(keys %bad_plates) {
#	    Message("$_: " . join(',',@{$bad_plates{$_}}));
#	}
#	&main::leave();
#	return;
#    }
#}

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

2003-08-08

=head1 REVISION <UPLINK>

$Id: Container_Set.pm,v 1.83 2004/12/09 00:25:34 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
