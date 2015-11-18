##############################################
#
# $ID$
#
# CVS Revision: $Revision: 1.43 $
#     CVS Date: $Date: 2004/11/25 20:22:52 $
#
##############################################
#
#  This package is used to automatically retrieve chemistry calculations
#  for standard lab solutions based upon specific ratios and formulas
#
#
package alDente::Chemistry;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>
    
Chemistry.pm - $ID$
    
=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

This package is used to automatically retrieve chemistry calculations<BR>for standard lab solutions based upon specific ratios and formulas<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Chemistry_Parameters
    Chemistry_Printout
    groups
    add_group
);
@EXPORT_OK = qw(
    Chemistry_Parameters
    Chemistry_Printout
    create_Formula_interface
    show_Formula
    get_Parameter
    groups
    add_group
);

##############################
# standard_modules_ref       #
##############################

use POSIX;
use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Form_Viewer;
use SDB::CustomSettings;    ### get exported variables...
use alDente::SDB_Defaults;
use alDente::Form;          ### to Set_Parameters
use alDente::Barcoding;
use alDente::Grp;

##############################
# global_vars                #
##############################
use vars qw($scanner_mode $testing $dbh $URL_temp_dir $URL_version $Security $Connection);
use vars qw(@users);

my $q = new CGI;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my @CHEMISTRY_FIELDS = ( 'Standard_Solution_ID', 'Standard_Solution_Name', 'Standard_Solution_Formula', 'Standard_Solution_Message', 'Standard_Solution_Parameters', 'Reagent_Parameter' );
my @PARAMETER_FIELDS = ( 'Parameter_ID', 'Parameter_Name', 'Parameter_Value', 'Parameter_Format', 'Parameter_Type', 'Parameter_SType', 'Parameter_Prompt', 'Parameter_Description', 'Parameter_Units' );

##############################
# constructor                #
##############################

##########
sub new {
##########
    #
    #Constructor of the object
    #
    my $this = shift;
    my %args = @_;

    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $id   = $args{-id};                                                                       ## Standard Solution ID
    my $name = $args{-name};                                                                     ## Standard Solution Name (must be exact match)

    my $class = ref($this) || $this;

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Standard_Solution' );
    bless $self, $class;

    $self->{dbc} = $dbc;
    if    ($id)   { $self->load_chemistry( -id   => $id ) }
    elsif ($name) { $self->load_chemistry( -name => $name ) }

    return $self;
}

################
sub home_page {
################

    return 'homepage';
}

#################################
sub request_broker {
#################################
    my %args  = @_;
    my $event = $args{-event};
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    if ( $event eq 'Add Formula' ) {

        #	&Chemistry_home();

        &alDente::Chemistry::update_Formula( -dbc => $dbc );
        return 1;
    }
    elsif ( $event eq 'Get Parameter' ) {

        #	&Chemistry_home();

        my $param      = param('Parameter');                                                                          ## either name or id should work
        my $formula    = param('Formula_ID') || param('FK_Standard_Solution__ID') || param('Standard_Solution_ID');
        my $formula_id = $dbc->get_FK_ID( 'FK_Standard_Solution__ID', $formula );

        my $multiple = param('Multiple');
        my $append   = param('Append');
        my $Formula  = alDente::Chemistry->new( -dbc => $dbc, -id => $formula_id );
        $Formula->show_Formula( -parameter => $param, -multiple => $multiple, -append => $append );
        return 1;
    }
    elsif ( $event eq 'Update Parameter' ) {                                                                          ## replace with generic form...

        #	&Chemistry_home();

        my $formula_id   = param('Formula_ID');
        my $parameter_id = param('Parameter_ID');
        my $append       = param('Append');
        my $Formula      = alDente::Chemistry->new( -dbc => $dbc, -id => $formula_id );
        $Formula->update_Parameter( -parameter_id => $parameter_id, -append => $append );
        return 1;
    }
    elsif ( $event eq 'Delete Parameter' ) {                                                                          ## replace with generic form...

        #	&Chemistry_home();

        my $formula_id   = param('Formula_ID');
        my $parameter_id = param('Parameter_ID');
        my $delete       = $dbc->delete_record( 'Parameter', 'Parameter_ID', $parameter_id );
        my $Formula      = alDente::Chemistry->new( -dbc => $dbc, -id => $formula_id );
        $Formula->show_Formula();
        return 1;
    }
    elsif ( $event eq 'Add Parameter' ) {

        #	&Chemistry_home();

        my $formula_id   = param('Formula_ID');
        my $parameter_id = param('Parameter_ID');
        my $Formula      = alDente::Chemistry->new( -dbc => $dbc, -id => $formula_id );
        $Formula->show_Formula( -append => 1 );
        return 1;
    }
    elsif ( $event eq 'Initialize Parameters' ) {

        #	&Chemistry_home();

        my $formula_id = param('Formula_ID');
        my $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $formula_id );
        $Formula->initialize_Chemistry_parameters( -formula_id => $formula_id );
        $Formula->show_Formula();
        return 1;
    }
    elsif ( $event eq 'Calculate' ) {

        Message("Calculate method not available");

        #	&Chemistry_calculate();
    }
    elsif ( $event eq 'Check Chemistry Calculator' ) {

        my $chem = param('Chemistry');
        if ( !$chem || $chem eq '-' ) {
            $dbc->message("No standard chemistry was selected");
            return;
        }

        #$chem =~ s/\+/ /g;
        my $chem_id = param('Chemistry_ID') || param('Standard_Solution_ID');
        my $wells   = param('Wells')        || param('Samples');
        my $blocks  = param('Blocks');
        my $blocksX = param('BlocksX');
        if ( $blocks && $blocksX ) { $wells = $blocks * $blocksX }

        my $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $chem_id, -name => $chem );

        if ( $chem_id || $chem ) {
            $Formula->show_Formula();
        }
        else {
            $Formula->list_Formulas();
        }
        return 1;
    }
    elsif ( $event eq 'Copy' ) {

        my $chem_id = param('Chemistry_ID') || param('Standard_Solution_ID');
        my $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $chem_id );
        my $groups = $Formula->groups();

        my $name = $Formula->value('Standard_Solution_Name');

        ## truncate name if it is going to surpass the limit with the ' copy' suffix ##
        my ($field_limit) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Name = 'Standard_Solution_Name'" );
        if ( $field_limit =~ /(\d+)/ ) {
            $field_limit = $1;
            if ( length($name) > $field_limit - 5 ) {
                ## is there space for ' copy' ?  If not, leave space for '... copy' ##
                while ( length($name) > $field_limit - 8 ) { chop $name }
                $name .= '...';    # to clarify that this name has been truncated
                Message("Truncating name to enable saving as '... copy'");
            }
        }
        $name .= " copy";

        my $new_id = $Formula->save_Formula( -name => $name );
        $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $new_id );
        $Formula->add_group( -group => $groups );
        $Formula->show_Formula();
        return 1;
    }
    else {
        Message("Warning: Event ($event) unknown");
    }
    return;
}

##############################
# public_methods             #
##############################

##########
# dbh accessor
#
#########
sub dbh {
#########
    my $self = shift;
    return $self->{dbh};
}
######################################################
# Load information for a given Standard Chemistry
#
#################
sub load_chemistry {
#################
    my $self       = shift;
    my %args       = @_;
    my $name       = $args{-name} || '';
    my $id         = $args{-id} || 0;
    my $dbc        = $self->{dbc};
    my $force      = $args{-force};
    my $quick_load = $args{-quick_load};

    my $parameter = $args{-parameter};
    my $multiple  = $args{-multiple};

    if ( $name && !$id ) {
        ($id) = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_ID', "WHERE Standard_Solution_Name = '$name'" );
    }

    unless ( $self->primary_value( -table => 'Standard_Solution', -value => $id ) ) { Message("Standard_Solution not defined") }
    $self->load_Object( -force => $force, -quick_load => $quick_load );

    $self->{id}         = $self->value('Standard_Solution_ID');
    $self->{name}       = $self->value('Standard_Solution_Name');
    $self->{formula}    = $self->value('Standard_Solution_Formula');
    $self->{formula_id} = $self->value('Standard_Solution_ID');
    $self->{message}    = $self->value('Standard_Solution_Message');
    $self->{parameters} = $self->value('Standard_Solution_Parameters');

    return 1;
}

#################
sub list_Formulas {
#################
    my $self = shift;
    my $type = shift || 'Active';
    my $dbc  = $self->{dbc};

    ## show all solutions ##
    my $group_list = $dbc->get_local('group_list');
    my @standards  = $dbc->Table_find(
        'Standard_Solution,GrpStandard_Solution',
        'distinct Standard_Solution_Name,Standard_Solution_ID',
        "WHERE FK_Standard_Solution__ID=Standard_Solution_ID AND Standard_Solution_Status in ('$type') AND FK_Grp__ID IN ($group_list) ORDER BY Standard_Solution_Name"
    );
    print "$type Standard Solutions:";
    print "<UL>";
    foreach my $SS (@standards) {
        my ( $SS_name, $SS_id ) = split ',', $SS;
        my $link = &Link_To( $dbc->config('homelink'), $SS_name, "&Chemistry_Event=Check Chemistry Calculator&Chemistry_ID=$SS_id", $Settings{LINK_COLOUR} );
        print "<LI>$link";
    }
    print "</UL>";
    return 1;
}

###################
sub list_Parameters {
###################
    my $self = shift;
    my $id   = $self->{id};
    my $dbc  = $self->{dbc};

    unless ($id) { Message("ID not specified"); }

    my @reagents;
    my $index   = 0;
    my $formula = $self->{formula};
    while ( $formula =~ s /([a-zA-z]\w*)/\?$index/ ) {
        my $name = $1;
        if ( $name =~ /^(wells|samples)$/ ) {next}
        $reagents[ $index++ ] = $name;
    }
    Message("Reagents");
    print "<UL>";
    foreach my $reag (@reagents) {
        my $link = &Link_To( $dbc->config('homelink'), $reag, "&Chemistry_Event=1&FK_Standard_Solution__ID=$id&Parameter=$reag", 'blue' );
        print "<LI>$link";
    }
    print "</UL>";
}

#####################
sub show_Formula {
#####################
    my $self      = shift;
    my %args      = @_;
    my $name      = $args{-name} || $self->{name};
    my $id        = $args{-id} || $self->{id} || 0;
    my $parameter = $args{-parameter};
    my $multiple  = $args{-multiple};
    my $append    = $args{-append};
    my $dbc       = $self->{dbc};

    ## only users with 'Admin' Grp_Access privilege on the standard chemistry can edit the chemistry
    my $user_groups = $dbc->get_local('group_list');
    my $grp_access  = $self->get_grp_access( -id => $id, -grp_ids => $user_groups );
    my $allow_edit  = grep /Admin/, values %$grp_access;

    my @fields = ( @CHEMISTRY_FIELDS, @PARAMETER_FIELDS, 'Standard_Solution_Status' );
    my %info = $dbc->Table_retrieve( 'Standard_Solution LEFT JOIN Parameter ON Parameter.FK_Standard_Solution__ID=Standard_Solution_ID', \@fields, "WHERE (Standard_Solution_Name = '$name' OR Standard_Solution_ID = $id) ORDER BY Parameter_Name" );
    $name = $info{Standard_Solution_Name}[0];

    my $formula    = $info{Standard_Solution_Formula}[0];
    my $formula_id = $info{Standard_Solution_ID}[0];
    my $message    = $info{Standard_Solution_Message}[0];
    my $parameters = $info{Standard_Solution_Parameters}[0];
    my $status     = $info{Standard_Solution_Status}[0];

    my $message_right           = $message;
    my $message_right_with_unit = $message_right;
    my $calculation_right       = $message;
    my $calculation_unit;

    print Link_To( $dbc->config('homelink'), 'Check other Standard Solutions', '&Chemistry_Event=Check Chemistry Calculator' );
    print &Views::sub_Heading( "<B>$name : $formula</B>", -1 );
    my $Formula = $self->display_Record( -tables => ['Standard_Solution'], -title => "$name Definitions", -view_only => !$allow_edit ) . &vspace(5);

    my $index = 0;

    my $Table = HTML_Table->new( -title => "$name Parameters" );
    $Table->Set_Headers( [ 'Name', 'Description', 'Prompt', 'Value', 'Units', 'Format', 'Reagent Type', 'Parameter Type' ] );

    my $formula2 = $formula;    ## also create formula with values in place of static parameters...
    my $formula3 = $formula;    ## also create formula with values in place of static parameters...
    my @params;
    my @M_names;
    my @M_values;
    my @M_desc;
    my @M_prompt;
    my @M_units;
    my $base;

    my %param_hash;
    my $index2 = 0;
    while ( defined $info{Parameter_Name}[$index2] ) {
        my $name = $info{Parameter_Name}[$index2];
        $param_hash{$name} = $info{Parameter_Value}[$index2];
        $index2++;
    }

    if ($parameters) {
        while ( defined $info{Parameter_Name}[$index] ) {
            my $P_id            = $info{Parameter_ID}[$index];
            my $P_name          = $info{Parameter_Name}[$index];
            my $P_display_value = $info{Parameter_Value}[$index];
            my $P_value         = &get_value( -params => \%param_hash, -value => $info{Parameter_Value}[$index], -name => $P_name, -dbc => $dbc, -wells => 96 );
            my $P_format        = $info{Parameter_Format}[$index];
            my $P_type          = $info{Parameter_Type}[$index];
            my $P_Stype         = $info{Parameter_SType}[$index];
            my $P_units         = $info{Parameter_Units}[$index];
            my $P_prompt        = $info{Parameter_Prompt}[$index];
            my $P_desc          = $info{Parameter_Description}[$index];
            $index++;

            my $link  = &Link_To( $dbc->config('homelink'), $P_name,  "&Chemistry_Event=Get Parameter&Parameter=$P_id&Formula_ID=$formula_id&Multiple=1", 'blue' );
            my $link2 = &Link_To( $dbc->config('homelink'), $P_value, "&Chemistry_Event=Get Parameter&Parameter=$P_id&Formula_ID=$formula_id",            'blue' );
            if ( !$allow_edit ) {    ## no link if editting is not allowed
                $link = $P_name;
            }
            $Table->Set_Row( [ $link, $P_desc, $P_prompt, $P_display_value, $P_units, $P_format, $P_Stype, $P_type ] );

            my ( $message_qty, $message_units ) = &Get_Best_Units( $P_value, $P_units, '', 2 );
            my $message_value           = "$message_qty";
            my $message_value_with_unit = "$message_qty $message_units";

            $message_right           =~ s/\b$P_name\b/$message_value/g;              ## substitute values at the right side of the message
            $message_right_with_unit =~ s/\b$P_name\b/$message_value_with_unit/g;    ## substitute values at the right side of the message
            my ( $normalize_qty, $normalize_units ) = &normalize_units( $P_value, $P_units );
            $calculation_right =~ s/\b$P_name\b/$normalize_qty/g;
            $calculation_unit = $normalize_units;
            if ( $formula =~ s/\b$P_name\b/$link/g ) { $formula2 =~ s/\b$P_name\b/ $link2 /g; $formula3 =~ s/\b$P_name\b/ $P_value /g }
            elsif ( ( $P_name =~ /^(.+?)(\d+)$/ ) && $formula =~ /\b$1\b/ ) {
                if ( $P_name =~ /^(.+?)1$/ ) {                                       ## substite basename if first multiple variable..
                    $base = $1;
                    my $link = &Link_To( $dbc->config('homelink'), " $base ", "&Chemistry_Event=Get Parameter&Parameter=$base&Formula_ID=$formula_id&Multiple=1", 'blue' );
                    $formula  =~ s/\b$base\b/ $link /g;                              ## multiple parameter..##
                    $formula2 =~ s/\b$base\b/ $link /g;
                    $formula3 =~ s/\b$base\b/ $base /g;                              ## add space around character to clarify
                }
                push( @M_names,  $P_name );
                push( @M_values, $P_value );
                push( @M_desc,   $P_desc );
                push( @M_prompt, $P_prompt );
                push( @M_units,  $P_units );
            }

            if ( ( $parameter =~ /^$P_name$/ ) || ( $parameter =~ /^$P_id$/ ) ) {
                push( @params, $self->get_Parameter( -name => $P_name, -formula_id => $formula_id, -allow_edit => $allow_edit ) );
            }
            elsif ( $P_name =~ /^$parameter(\d+)$/ ) {
                push( @params, $self->get_Parameter( -name => $P_name, -formula_id => $formula_id, -allow_edit => $allow_edit ) );
            }
        }
    }

    my $example = $formula2 . &vspace(6);
    $formula2 =~ s /\b(wells|samples)\b/96/ig;
    $formula3 =~ s /\b(wells|samples)\b/96/ig;
    $example .= "<B>Eg. with 96 samples:</B> Qty = $formula2<UL>";
    my @examples;

    while ( my $name = shift @M_names ) {
        my $value        = shift @M_values;
        my $desc         = shift @M_desc;
        my $prompt       = shift @M_prompt;
        my $units        = shift @M_units;
        my $this_example = $formula3;
        my $base_name    = $name;
        if ( $name =~ /^(.*?)\d+$/ ) { $base_name = $1 }
        $this_example =~ s / $base_name / $value /g;
        my $result = $this_example;
        $result =~ s/\s//g;
        $result =~ s /(.*)/$1/ee;
        my ( $new_result, $new_units ) = simplify_units( $result, $units, 2 );
        $example .= "<LI><B>$prompt</B> : $this_example $units = <B>$new_result $new_units</B>";
    }
    $example .= "</UL>";
    print &Views::sub_Heading( $example, -1, 'bgcolor=lightgrey' );

    if ($message) {
        $message_right           =~ s /\b(wells|samples)\b/96/ig;
        $message_right_with_unit =~ s /\b(wells|samples)\b/96/ig;

        if ( $message_right =~ /(.*)=(.+)/ ) {
            my $message_right_final = '';
            my @equs                = split ',', $calculation_right;
            my @equs_with_unit      = split ',', $message_right_with_unit;
            my $count               = scalar(@equs);
            for ( my $i = 0; $i < $count; $i++ ) {
                my $equ           = $equs[$i];
                my $equ_with_unit = $equs_with_unit[$i];
                $message_right_final .= $equ_with_unit;

                #my $name;
                #my $value;
                #if( $equ =~ /(.*)=(.+)/ ) {
                #	$name = $1;
                #	$value = $2;
                #	$value =~ s /(.*)/$1/ee;
                #    $value = join(" ", &Get_Best_Units($value, $calculation_unit, '', 2));
                #    $message_right_final .= "$equ_with_unit = $value";
                #}
                #else {
                #	$message_right_final .= $equ_with_unit;
                #}
            }

            $message_right = $message_right_final;
        }

        Message("$message");
        Message("Eg: $message_right");
        print &vspace;
    }

    #    print "<span class=small>(click on links in formula above, or in tables below to edit)</span>";

    #    print &Link_To($dbc->homelink(),"Add Parameter","&DBAppend=Parameter&DBTable=Parameter&FK_Standard_Solution__ID=$id",$Settings{LINK_COLOUR},['newwin']);

    if ($allow_edit) {
        unless ( $index > 0 ) {
            print &Link_To( $dbc->config('homelink'), "Initialize Parameters", "&Chemistry_Event=Initialize+Parameters&Formula_ID=$id", $Settings{LINK_COLOUR} );
            print &vspace(5);
        }
        print &Link_To( $dbc->config('homelink'), "Add Parameter", "&Chemistry_Event=Add+Parameter&Formula_ID=$id", $Settings{LINK_COLOUR}, ['newwin'] );
    }
    print hr;
    print &Link_To( $dbc->config('homelink'), "Save As New Chemistry", "&Chemistry_Event=Copy&Standard_Solution_ID=$id", $Settings{LINK_COLOUR}, ['newwin'] );

    if ( ( $index < 2 ) && !$append ) {    ## showing only one parameter and no append form
        &Views::Table_Print( content => [ [ $Formula, $Table->Printout(0), @params ] ], print => 1 );
    }
    elsif ($append) {                      ## include append form
        &Views::Table_Print( content => [ [ $Formula, $Table->Printout(0) ] ], print => 1 );
        print hr;
        &Views::Table_Print( content => [ [@params] ], print => 1 );
    }
    else {
        &Views::Table_Print( content => [ [ $Formula, $Table->Printout(0) ] ], print => 1 );
        print hr;
        &Views::Table_Print( content => [ [@params] ], print => 1 );
    }

    if ($append) {
        $self->add_Parameter( -name => '', -formula_id => $formula_id, );
    }

    my $grps   = $dbc->get_local('group_list');
    my $filter = "Access IN ('Lab') AND Grp_Status = 'Active'";

    my $page;
    ## change status button
    $page .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Chemistry' );
    my @status_options = alDente::Chemistry::get_chemistry_status_options( -dbc => $dbc );
    $page
        .= '<P>'
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Chemistry_App', -force => 1 )
        . $q->hidden( -name => 'Chemistry_ID', -value => $formula_id, -force => 1 )
        . $q->scrolling_list( -name => 'Status', -values => \@status_options, -default => $status )
        . &hspace(5)
        . $q->submit( -name => 'rm', -value => 'Change Status', -class => 'Action' )
        . hr . '<P>'
        . $q->end_form();

    ## use standardized interface for managing join tables ##
    my $OV = new alDente::Object_Views( -dbc => $dbc );
    $page .= $OV->join_records(
        -dbc        => $dbc,
        -defined    => "FK_Standard_Solution__ID",
        -id         => $formula_id,
        -join       => 'FK_Grp__ID',
        -join_table => "GrpStandard_Solution",
        -filter     => $filter,
        -title      => 'Group Visibility for this Chemistry',
        -extra      => 'Grp_Access',
        -editable   => $allow_edit
    );

    print $page;
    return;
}

#######################
sub update_Formula {
#######################
    my $self       = shift;
    my %args       = @_;
    my $id         = $args{-id} || param('Standard_Solution_ID');
    my $name       = $args{-name} || param('Standard_Solution_Name');
    my $parameters = $args{-parameters} || param('Standard_Solution_Parameters');
    my $formula    = $args{-formula} || param('Standard_Solution_Formula');
    my $message    = $args{-message} || param('Standard_Solution_Message');
    my $status     = $args{-status} || param('Standard_Solution_Status') || 'Under Development';
    my $reagent    = $args{-reagent} || param('Reagent_Parameter');
    my $append     = $args{-append};
    my $dbc        = $self->{dbc};

    my @fields = @CHEMISTRY_FIELDS;
    my @values = ( '', $name, $formula, $message, $parameters, $status, $reagent );

    if ($append) {
        my $new_id = $dbc->Table_append_array( 'Standard_Solution', \@fields, \@values, -autoquote => 1 );
        Message("Created $name specification.");

        if ($new_id) {
            $self->load_chemistry( -id => $new_id );
            $self->list_Parameters();
        }
        else {
            Message("Error creating parameters");
            return 0;
        }
    }
    else {
        if ( $id && $name ) {
            my $updated = $dbc->Table_update_array( 'Standard_Solution', \@fields, \@values, "WHERE Standard_Solution_ID=$id", -autoquote => 1 );
            Message("Updated $updated Formula(s)");
            $self->load_chemistry( -id => $id );
            $self->list_Parameters();
        }
        else {
            Message("Error: must include id / name pair ($id / $name)");
            return 0;
        }
    }
    return 1;
}

###########################################################
#  Copy this chemistry to another name for easier editing
###########################################################
sub save_Formula {
#####################
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $self->{dbc};
    my $formula_id = $self->{id} || $args{-formula_id} || param('FK_Standard_Solution__ID');

    my $name       = $args{-name}        || $self->{name}                                || $self->value('Standard_Solution_Name') || 'New Chemistry';
    my $formula    = $self->{formula}    || $self->value('Standard_Solution_Formula')    || $args{-formula}                        || '1';
    my $message    = $self->{message}    || $self->value('Standard_Solution_Message')    || $args{-message}                        || '';
    my $parameters = $self->{parameters} || $self->value('Standard_Solution_Parameters') || $args{-parameters}                     || 0;
    my $status     = $self->{status}     || $self->value('Standard_Solution_Status')     || $args{-status}                         || 'Under Development';
    my $reagent    = $self->{reagent}    || $self->value('Reagent_Parameter')            || $args{-reagent};

    my @fields = ( 'Standard_Solution_Name', 'Standard_Solution_Formula', 'Standard_Solution_Message', 'Standard_Solution_Parameters', 'Standard_Solution_Status', 'Reagent_Parameter' );
    my @values = ( $name, $formula, $message, $parameters, $status, $reagent );
    my $new_formula_id = $dbc->Table_append_array( 'Standard_Solution', \@fields, \@values, -autoquote => 1 );

    if ( $new_formula_id =~ /[1-9]/ ) {
        if ($parameters) {

            my @P_fields = ( 'Parameter_Name', 'Parameter_Value', 'Parameter_Prompt', 'Parameter_Description', 'Parameter_Format', 'Parameter_Type', 'Parameter_SType', 'Parameter_Units' );
            my %parameter_info = &Table_retrieve( $dbc, 'Parameter', \@P_fields, "WHERE FK_Standard_Solution__ID = $formula_id" );

            my $parameter = 1;
            Message("Please set the name of this new chemistry as soon as possible");
            while ( defined $parameter_info{Parameter_Name}[ $parameter - 1 ] ) {
                my @P_values;
                foreach my $param (@P_fields) {
                    my $value = $parameter_info{$param}[ $parameter - 1 ] || 0;
                    push( @P_values, $value );
                }
                push( @P_values, $new_formula_id );
                my $ok = $dbc->Table_append_array( 'Parameter', [ @P_fields, 'FK_Standard_Solution__ID' ], \@P_values, -autoquote => 1 );
                $parameter++;
            }
        }
        else {
            Message("Initializing parameters");
            $self->initialize_Chemistry_parameters();
        }
    }
    else { Message("No Standard Solution created"); return 0; }

    $self->{parameters} = $parameters;
    $self->{reagent}    = $reagent;
    $self->{formula}    = $formula;
    $self->{id}         = $new_formula_id;

    return $new_formula_id;
}

##################################
#
#
#################################
sub initialize_Chemistry_parameters {
#################################
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $self->{dbc};
    my $formula_id = $args{-formula_id};

    my @defined_params = $dbc->Table_find( 'Parameter', 'Parameter_ID', "WHERE FK_Standard_Solution__ID=$formula_id" );
    if (@defined_params) {return}

    my $parameters = $self->value('Standard_Solution_Parameters');
    my $reagent    = $self->value('Reagent_Parameter');
    my $formula    = $self->value('Standard_Solution_Formula');

    ### find all of the parameters from the formula (and ensure specified reagent parameter exists ###
    my @variables;
    my $found_reagent_in_formula = 0;

    my $original_formula = $formula;
    $formula =~ s/\b(wells|samples)/\./gi;
    while ( $formula =~ /\b([a-z]\w+)\b/i ) {
        my $param = $1;
        $formula =~ s/\b$param\b/./g;
        if ( $param eq $reagent ) { $found_reagent_in_formula = 1; }
        elsif ( grep /^$param$/, @variables ) { }                               ## got it already...
        else                                  { push( @variables, $param ); }
    }

    unless ( $formula_id && $formula ) { Message("Initialization failed - insufficient information"); return 0; }

    if (@variables) {
        foreach my $index ( 0 .. $#variables ) {
            $dbc->Table_append_array(
                'Parameter',
                [ 'FK_Standard_Solution__ID', 'Parameter_Name',   'Parameter_Prompt', 'Parameter_Value', 'Parameter_Type', 'Parameter_Units' ],
                [ $formula_id,                $variables[$index], $variables[$index], 1,                 'Static',         '' ],
                -autoquote => 1
            );
        }
        Message( int(@variables) . " variables initialized (@variables)", "Note: Value & Description need to be added (click on variable to edit)" );
    }
    else { Message("No variables found to initialize"); }

    if ( !$parameters ) { Message("No parameters found to initialize"); return 1; }
    elsif ($reagent) {
        unless ( $original_formula =~ /\b$reagent\b/ ) { Message("Error: Formula ($original_formula) does not include reagent parameter ($reagent)"); return 0; }
        foreach my $index ( 1 .. $parameters ) {
            $dbc->Table_append_array(
                'Parameter',
                [ 'FK_Standard_Solution__ID', 'Parameter_Name',  'Parameter_Prompt', 'Parameter_Value', 'Parameter_Type', 'Parameter_Units' ],
                [ $formula_id,                $reagent . $index, $reagent . $index,  1,                 'Multiple',       'ul' ],
                -autoquote => 1
            );
        }
        Message( "$parameters parameters initialized", "Note: Please update Description (Name of reagent required), Value, Units etc." );
    }
    else {
        Message("Initialization failed - insufficient information");
        return 0;
    }
    return 1;
}
#################
sub get_Parameter {
#################
    my $self       = shift;
    my %args       = @_;
    my $id         = $args{-id} || param('Parameter_ID') || 0;
    my $name       = $args{-name} || param('Parameter_Name');
    my $formula_id = $args{-formula_id} || param('FK_Standard_Solution__ID');
    my $dbc        = $self->{dbc};
    my $allow_edit = $args{-allow_edit};
    my $text_width = 15;

    unless ( ( $name || $id ) && $formula_id ) { Message("Sorry - both a parameter ($id/$name) and formula ($formula_id) must be specified"); return; }

    my %current_info = &Table_retrieve( $dbc, 'Parameter,Standard_Solution', \@PARAMETER_FIELDS, "WHERE FK_Standard_Solution__ID=Standard_Solution_ID AND Standard_Solution_ID=$formula_id AND (Parameter_Name = '$name' OR Parameter_ID = $id)" );
    my ( $D_id, $D_value, $D_desc, $D_prompt, $D_format, $D_type, $D_Stype, $D_units );
    if ( $current_info{Parameter_ID}[0] ) {
        $D_id     = $current_info{Parameter_ID}[0]          || 0;
        $D_value  = $current_info{Parameter_Value}[0]       || 0;
        $D_desc   = $current_info{Parameter_Description}[0] || '';
        $D_prompt = $current_info{Parameter_Prompt}[0]      || '';
        $D_format = $current_info{Parameter_Format}[0]      || '';
        $D_type   = $current_info{Parameter_Type}[0]        || '';
        $D_Stype  = $current_info{Parameter_SType}[0]       || '';
        $D_units  = $current_info{Parameter_Units}[0]       || '';
    }

    # This should use a standard form, but need to allow return of form rather than auto-printing...
    #
    #    my %Config;
    #    $Config{preset}{FK_Standard_Solution__ID} = $formula_id;
    #    my $form = SDB::DB_Form->new(-dbc=>$dbc,-table=>'Parameter',-parameters=>{'FK_Standard_Solution__ID'=>$formula_id},-target=>'Database');
    #    $form->configure(%Config);
    #
    #    my $output = $form->generate(-action=>'edit');
    #
    my $output = alDente::Form::start_alDente_form( $dbc, 'ChemForm', undef );

    #if ($name) { $output .= hidden(-name=>'Parameter_Name',-value=>$name,-force=>1); }
    #else { $name = textfield(-name=>'Parameter_Name',-size=>$text_width,-default=>$name,-force=>1); }
    my $Table = HTML_Table->new( -title => "$name details" );
    $output .= hidden( -name => 'FK_Standard_Solution__ID', -value => $formula_id, -force => 1 );
    $output .= hidden( -name => 'Parameter_ID',             -value => $D_id,       -force => 1 );
    $output .= hidden( -name => 'Formula_ID',               -value => $formula_id, -force => 1 );

    #    $Table->Set_Headers(['Code','Name','Value','Description','Format']);
    $Table->Set_Row( [ 'Name of Parameter: ', Show_Tool_Tip( textfield( -name => 'Parameter_Name', -size => $text_width, -default => $name, -force => 1 ), "(as it appears in formula (reagent parameters will be suffixed with an index number)" ) ] );
    $Table->Set_Row( [ "Value: ", textfield( -name => 'Parameter_Value', -size => $text_width, -default => $D_value, -force => 1 ) ] );
    $Table->Set_Row( [ 'Units: ', popup_menu( -name => 'Parameter_Units', -values => [ '', get_enum_list( $dbc, 'Parameter', 'Parameter_Units' ) ], -default => $D_units, -force => 1 ) ] );
    $Table->Set_Row(
        [ 'Parameter Type: ', Show_Tool_Tip( popup_menu( -name => 'Parameter_Type', -values => [ get_enum_list( $dbc, 'Parameter', 'Parameter_Type' ) ], -default => $D_type, -force => 1 ), "Use Multiple for new reagent, and Static otherwise" ) ] );
    $Table->Set_Row( [ 'Prompt: ',      Show_Tool_Tip( textfield( -name => 'Parameter_Prompt',      -size => $text_width, -default => $D_prompt, -force => 1 ), "This should be brief (< 20 char) and will be TRUNCATED if too long" ) ] );
    $Table->Set_Row( [ 'Description: ', Show_Tool_Tip( textfield( -name => 'Parameter_Description', -size => $text_width, -default => $D_desc,   -force => 1 ), "What is this parameter for" ) ] );
    $Table->Set_Row( [ 'Format: ',      Show_Tool_Tip( textfield( -name => 'Parameter_Format',      -size => $text_width, -default => $D_format, -force => 1 ), "Optionally provide a string here - name of reagent entered MUST contain this string" ) ] );
    $Table->Set_Row(
        [   'Reagent Type: ',
            Show_Tool_Tip(
                popup_menu( -name => 'Parameter_SType', -values => [ '', get_enum_list( $dbc, 'Parameter', 'Parameter_SType' ) ], -default => $D_Stype, -force => 1 ),
                "You ONLY need to add this for error checking IF you want to ensure proper reagent type used"
            )
        ]
    );

    if ($allow_edit) {
        $Table->Set_Row( [ submit( -name => 'Chemistry_Event', -value => 'Update Parameter', -class => "Action" ) ] );
        $Table->Set_Row( [ submit( -name => 'Chemistry_Event', -value => 'Delete Parameter', -class => "Action" ) ] );
    }
    $output .= $Table->Printout(0);
    $output .= end_form();

    return $output;
}

#################
sub add_Parameter {
#################
    my $self       = shift;
    my %args       = @_;
    my $name       = $args{-name} || '';
    my $formula_id = $args{-formula_id} || param('FK_Standard_Solution__ID') || 0;
    my $dbc        = $self->{dbc};

    my $text_width = 15;

    my ($Fname) = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_Name', "WHERE Standard_Solution_ID = $formula_id" );
    unless ($formula_id) { Message("Sorry - both a formula_id must be specified"); return; }

    my $output = alDente::Form::start_alDente_form( $dbc, 'ChemForm', undef );

    my %P;
    $P{FK_Standard_Solution__ID} = $Fname;

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Parameter' );
    $form->configure( -preset => \%P, -grey => { 'FK_Standard_Solution__ID' => $Fname } );
    $form->generate( -action => 'add' );

    return $output;
}

##########################
sub update_Parameter {
##########################
    my $self   = shift;
    my %args   = @_;
    my $id     = $args{-id} || param('Parameter_ID');
    my $name   = $args{-name} || param('Parameter_Name') || '';
    my $value  = $args{-value} || param('Parameter_Value') || 0;
    my $prompt = $args{-prompt} || param('Parameter_Prompt') || '';
    my $desc   = $args{-desc} || param('Parameter_Description') || '';
    my $format = $args{'-format'} || param('Parameter_Format') || '';
    my $type   = $args{-type} || param('Parameter_Type') || '';
    my $Stype  = $args{-Stype} || param('Parameter_SType') || '';
    my $units  = $args{-units} || param('Parameter_Units') || '';
    my $append = $args{-append};
    my $dbc    = $self->{dbc};

    my $formula_id = $self->{id};

    unless ( $formula_id && ( $append || ( $id && $value ) ) ) { Message("Sorry - a formula_id, parameter id and value must be specified ($id, $formula_id, $value)"); return; }

    my @fields = ( 'FK_Standard_Solution__ID', 'Parameter_Name', 'Parameter_Value', 'Parameter_Prompt', 'Parameter_Description', 'Parameter_Format', 'Parameter_Type', 'Parameter_SType', 'Parameter_Units' );
    my @values = ( $formula_id, $name, $value, $prompt, $desc, $format, $type, $Stype, $units );

    if ($append) {
        my $new_id = $dbc->Table_append_array( 'Parameter', \@fields, \@values, -autoquote => 1 );
        print "Created Parameter ($new_id)";
        $id = $new_id;
    }
    else {
        my $updated = $dbc->Table_update_array( 'Parameter', \@fields, \@values, "WHERE FK_Standard_Solution__ID=$formula_id AND Parameter_ID = $id", -autoquote => 1 );
        Message("Updated $updated Parameter(s)");
    }
    $self->show_Formula( -id => $formula_id, -parameter => $id );

    return;
}

##############################
# public_functions           #
##############################

############
############
############ older...(but may be used)...

###############################################################################################
# Generate hash containing details of solutions expected (along with default values, name etc)
#
# (probably could be rewritten - a bit hacked out early in code dev, though working effectively)
#
# Return : hash containing quantities, labels, format, SolType, units, baseline (?), message
##############################
sub Chemistry_Parameters {
##############################
    #
    # Generate Hash for parameters based on default database parameters...
    #
    #
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $chemistry = $args{-type} || param('Chemistry');                                              #### name of standard solution
    my $wells     = $args{-samples} || 0;
    my $verbose   = $args{-verbose} || 0;

    if ( !$dbc->mobile() ) {
        print &Link_To( $dbc->config('homelink'), "Standard Chemistry Formulas", '&Chemistry_Event=Check Chemistry Calculator', 'blue' )
            . &hspace(50)
            . &Link_To( $dbc->config('homelink'), 'Chemistry Calculator Help', '&Quick+Help=Chemistry_Calculator', 'blue' );
    }

    my %details = &Table_retrieve( $dbc, 'Standard_Solution', [ 'Standard_Solution_Formula', 'Standard_Solution_Message', 'Standard_Solution_Parameters', 'Standard_Solution_ID', 'Prompt_Units' ], "where Standard_Solution_Name like '$chemistry'" );

    my $formula      = $details{Standard_Solution_Formula}[0];
    my $message      = $details{Standard_Solution_Message}[0];
    my $prompt_units = $details{Prompt_Units}[0];
    my $parameters   = $details{Standard_Solution_Parameters}[0];
    my $id           = $details{Standard_Solution_ID}[0];

    unless ( $id =~ /[1-9]/ ) {
        print SDB::DB_Form_Viewer::view_records( $dbc, 'Standard_Solution', undef, undef );
        return;
    }

    my %Param = &Table_retrieve(
        $dbc, 'Parameter',
        [ 'Parameter_Name', 'Parameter_Prompt', 'Parameter_Description', 'Parameter_Value', 'Parameter_Type', 'Parameter_Units', 'Parameter_Format', 'Parameter_Type', 'Parameter_Units', 'Parameter_SType' ],
        "where FK_Standard_Solution__ID = $id Order by Parameter_Name"
    );

    if ($wells) {
        $dbc->message("Setting up mixture for $wells samples:");
    }
    else {
        $dbc->warning("No samples selected.");
    }

    if ( $dbc->config('screen_mode') eq 'desktop' ) {
        print &Views::sub_Heading( "<B>$chemistry:</B> $formula  ($message)", -1 );
        if ( $dbc->Security->department_access() =~ /Admin/i ) {
            print &Link_To( $dbc->config('homelink'), ' (Edit)', "&Chemistry_Event=Check Chemistry Calculator&Chemistry_ID=$id", $Settings{LINK_COLOUR}, ['newwin'] ) . &vspace(2);
        }
        if ( defined $Param{Parameter_Name}[0] && $Param{Parameter_Name}[0] =~ /\S/ ) {
            print "<span class=small><B>Parameters:</B><UL>";
        }
    }
### substitute Wells for Wells in Formula & Message

    $formula =~ s/\b(wells|samples)\b/$wells/ig;
    $message =~ s/\b(wells|samples)\b/$wells/ig;

    my $message_with_unit = $message;
    my $calculation_right = $message;
    my $calculation_unit;

    my %Mix;
    $Mix{formula} = $formula;
    $Mix{name}    = $chemistry;

    my %parameters;
    my $index = 0;
    while ( defined $Param{Parameter_Name}[$index] ) {
        my $name = $Param{Parameter_Name}[$index];
        $parameters{$name} = param("Std_Sol_$name") || $Param{Parameter_Value}[$index];
        $index++;
    }

    my @Name;
    my @Values;
    my @Type;
    my @Desc;
    my @Prompt;
    my @Format;
    my @SolType;
    my @Units;

    print alDente::Form::start_alDente_form( $dbc, 'Re-make Std Sol', -form => 'Re-make Std Sol' );

    my $user_define       = 0;
    my $index             = 0;
    my $parameter         = 0;    ## index for multiple parameters...
    my $static_parameters = 0;

    while ( defined $Param{Parameter_Name}[$index] ) {
        my $name   = $Param{Parameter_Name}[$index];
        my $type   = $Param{Parameter_Type}[$index];
        my $desc   = $Param{Parameter_Description}[$index];
        my $prompt = $Param{Parameter_Prompt}[$index];
        my $value  = param("Std_Sol_$name") || $Param{Parameter_Value}[$index];
        my $units  = $Param{Parameter_Units}[$index];

        $value =~ s/\b(wells|samples)\b/$wells/ig;

        if ( $name =~ /^(wells|samples)$/ig ) {
            $value = $wells;
        }
        else {
            $value = &get_value( -params => \%parameters, -value => $value, -name => $name, -dbc => $dbc );
        }

        if ( $type eq 'Multiple' ) {
            if ( $name =~ /^(\w+?)(\d+)$/ ) {
                $Name[$parameter]    = $name;
                $Type[$parameter]    = $type;
                $Desc[$parameter]    = $desc;
                $Prompt[$parameter]  = $prompt;
                $Format[$parameter]  = $Param{Parameter_Format}[$index];
                $SolType[$parameter] = $Param{Parameter_SType}[$index];
                $Values[$parameter]  = $value;
                $Units[$parameter]   = $units;
                $parameter++;
            }
            $index++;
            next;
        }
        else {
            $Mix{Parameter_name}[$static_parameters]  = $name;
            $Mix{Parameter_value}[$static_parameters] = $value;
            $static_parameters++;
        }

        #	 ($type eq 'Static') {$index++; next;}  ### only replace Static parameters...

        $formula =~ s /\b$name\b/$value/g;
        my ( $message_qty, $message_units ) = &Get_Best_Units( $value, $units, '', 2 );
        my $message_value           = "$message_qty";
        my $message_value_with_unit = "$message_qty $message_units";
        $message           =~ s /\b$name\b/$message_value/g;
        $message_with_unit =~ s /\b$name\b/$message_value_with_unit/g;
        my ( $normalize_qty, $normalize_units ) = &normalize_units( $value, $units );
        $calculation_right =~ s/\b$name\b/$normalize_qty/g;
        $calculation_unit = $normalize_units;

        if ( $type eq 'User_Define' ) {
            print "<LI><B>$prompt = " . textfield( -name => "Std_Sol_$name", -size => 15, -default => "$value", -force => 1 );
            $user_define = 1;
            $index++;
            next;
        }

        if ( !$dbc->mobile() ) {
            if ( $value =~ /\S/ ) { print "<LI><B>$prompt = $value</B>"; }
        }
        $index++;
    }

    if ( !$dbc->mobile() ) {
        print "</UL>";
    }

    print hidden ( -name => "cgi_application",   -value => "alDente::Solution_App" );
    print hidden ( -name => "Make Std Solution", -value => param('Make Std Solution') );
    print hidden ( -name => "Blocks",            -value => param('Blocks') );
    print hidden ( -name => "BlocksX",           -value => param('BlocksX') );
    print submit ( -name => "rm", -value => "Re-calculate Standard Solution", -class => "Action", -force => "1" ) if $user_define;
    print end_form();

    my @Formulas;
    foreach my $index ( 1 .. $parameters ) {
        $Formulas[ $index - 1 ] = $formula;
        my $substitute = $Name[ $index - 1 ];

        unless ($substitute) { next; }

        if ( $Type[ $index - 1 ] =~ /Mult/i ) {
            $substitute =~ s /(\d+)$//;    ### get rid of parameter index...
        }

        $Formulas[ $index - 1 ] =~ s /\b$substitute\b/$Values[$index-1]/g;

        #	print "<HR><B>".$Desc[$index-1].": ".$Formulas[$index-1]."</B>";
        if ($verbose) {
            print " For <B>$Name[$index-1] ($Desc[$index-1])</B>: $substitute = <B>$Values[$index-1] $Units[$index-1]</B><BR>";
            print $Formulas[ $index - 1 ] . " = ";
        }
        $Formulas[ $index - 1 ] =~ s/^(.*)$/$1/ee;    #### Evaluate the result of the formula...
        if ($verbose) {
            print "<B>" . $Formulas[ $index - 1 ] . "</B><BR>";
        }

        #	print " = ".$Formulas[$index-1]."</B><BR>";
        my ( $q, $u ) = &Get_Best_Units( -amount => $Formulas[ $index - 1 ], -units => $Units[ $index - 1 ] );
        $Mix{quantities}[ $index - 1 ] = $q;
        $Mix{units}[ $index - 1 ]      = $u;
        $Mix{labels}[ $index - 1 ]     = $Prompt[ $index - 1 ];
        $Mix{format}[ $index - 1 ]     = $Format[ $index - 1 ];
        $Mix{SolType}[ $index - 1 ]    = $SolType[ $index - 1 ];
        $Mix{baseline}[ $index - 1 ]   = $Values[ $index - 1 ];
    }
    $Mix{solutions} = $parameters;
    print hr;    # temp

    $Mix{message} = $message;
    $Mix{prompt_units} = $prompt_units if $prompt_units;

    if ( !$dbc->mobile() ) {
        print "</span>";
    }

    ####### Allow editing...
    #    if (!$wells) {
    #	 print &Views::Heading("Adjust Standard Formula as req'd for $chemistry");
    #	 print "Formula: <B>$formula</B><BR>";
##       &SDB::DB_Form_Viewer::edit_records($dbc,'Standard_Solution','Standard_Solution_ID',$id);
    #	 print SDB::DB_Form_Viewer::view_records($dbc,'Standard_Solution','Standard_Solution_ID',$id);
    #
    #	 print &Views::Heading("Adjust Parameters for $chemistry as req'd");
    #	 &SDB::DB_Form_Viewer::edit_records($dbc,'Parameter','FK_Standard_Solution__ID',$id,-order=>"Parameter_Name");
##       $dbc->disconnect();
    #	 return 1;
    #    }

    return %Mix;
}

#####################
sub convert_message {
#####################
    my $self      = shift;
    my %args      = @_;
    my $name      = $args{-name} || $self->{name};
    my $id        = $args{-id} || $self->{id} || 0;
    my $parameter = $args{-parameter};
    my $multiple  = $args{-multiple};
    my $append    = $args{-append};
    my $dbc       = $self->{dbc};

    my @fields = ( @CHEMISTRY_FIELDS, @PARAMETER_FIELDS );
    my %info = $dbc->Table_retrieve( 'Standard_Solution LEFT JOIN Parameter ON Parameter.FK_Standard_Solution__ID=Standard_Solution_ID', \@fields, "WHERE (Standard_Solution_Name = '$name' OR Standard_Solution_ID = $id) ORDER BY Parameter_Name" );

    $name = $info{Standard_Solution_Name}[0];

    my $formula    = $info{Standard_Solution_Formula}[0];
    my $formula_id = $info{Standard_Solution_ID}[0];
    my $message    = $info{Standard_Solution_Message}[0];
    my $parameters = $info{Standard_Solution_Parameters}[0];

    my $message_right           = $message;
    my $message_right_with_unit = $message_right;
    my $calculation_right       = $message;
    my $calculation_unit;

    my $Formula = $self->display_Record( -tables => ['Standard_Solution'], -title => "$name Definitions" ) . &vspace(5);

    my $index = 0;

    my $formula2 = $formula;    ## also create formula with values in place of static parameters...
    my $formula3 = $formula;    ## also create formula with values in place of static parameters...
    my @params;
    my @M_names;
    my @M_values;
    my @M_desc;
    my @M_prompt;
    my @M_units;
    my $base;

    my %param_hash;
    my $index2 = 0;
    while ( defined $info{Parameter_Name}[$index2] ) {
        my $name = $info{Parameter_Name}[$index2];
        $param_hash{$name} = $info{Parameter_Value}[$index2];
        $index2++;
    }

    if ($parameters) {
        while ( defined $info{Parameter_Name}[$index] ) {
            my $P_id            = $info{Parameter_ID}[$index];
            my $P_name          = $info{Parameter_Name}[$index];
            my $P_display_value = $info{Parameter_Value}[$index];
            my $P_value         = &get_value( -params => \%param_hash, -value => $info{Parameter_Value}[$index], -name => $P_name, -dbc => $dbc );
            my $P_format        = $info{Parameter_Format}[$index];
            my $P_type          = $info{Parameter_Type}[$index];
            my $P_Stype         = $info{Parameter_SType}[$index];
            my $P_units         = $info{Parameter_Units}[$index];
            my $P_prompt        = $info{Parameter_Prompt}[$index];
            my $P_desc          = $info{Parameter_Description}[$index];
            $index++;

            my ( $message_qty, $message_units ) = &Get_Best_Units( $P_value, $P_units, '', 2 );
            my $message_value           = "$message_qty";
            my $message_value_with_unit = "$message_qty $message_units";

            $message_right           =~ s/\b$P_name\b/$message_value/g;              ## substitute values at the right side of the message
            $message_right_with_unit =~ s/\b$P_name\b/$message_value_with_unit/g;    ## substitute values at the right side of the message
        }
    }

    if ($message) {
        $message_right           =~ s /\b(wells|samples)\b/384/i;
        $message_right_with_unit =~ s /\b(wells|samples)\b/384/i;

        if ( $message_right =~ /(.*)=(.+)/ ) {
            my $message_right_final = '';
            my @equs                = split ',', $calculation_right;
            my @equs_with_unit      = split ',', $message_right_with_unit;
            my $count               = scalar(@equs);
            for ( my $i = 0; $i < $count; $i++ ) {
                my $equ           = $equs[$i];
                my $equ_with_unit = $equs_with_unit[$i];
                $message_right_final .= $equ_with_unit;
            }

            $message_right = $message_right_final;
        }
    }

    return $message_right;
}

###########################
# Print chemistry barcode
# (used in conjunction with chemistry_print_parameters (?)...
#
#
############################
sub large_chemistry_barcode {
############################
    #
    #  Print Barcode for chemistry
    #
    my %args = &filter_input( \@_, -args => 'sol,samples,printer' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sol     = $args{-sol};
    my $printer = $args{-printer};

    my %Sol = %{$sol};

    my $blocks        = $Sol{blocks};
    my $block_samples = $Sol{samples_per_block};
    my $samples       = $Sol{blocks} * $Sol{samples_per_block};
    my $newids        = $Sol{'new solutions'};
    my @newids_info   = ();

    # convert newids to human readable form
    foreach my $newid ( split( ',', $newids ) ) {
        push( @newids_info, $dbc->get_FK_info( -field => "FK_Solution__ID", -id => $newid ) );
    }
    $newids = join( ',', @newids_info );

    my $index = 0;
    my @Rname;
    my @Ramt;
    my @Rwell;
    my @Rtotal;
    my $RTtotal = 0;

    foreach my $param ( 1 .. $Sol{solutions} ) {
        $Rname[$index] = $Sol{labels}[$index];
        my $sol_ids = $Sol{Solution_ID}[$index];

        if ($sol_ids) {
            my @solution_bottles = split ',', get_aldente_id( $dbc, $sol_ids, 'Solution', -feedback => 0 );
            my $info = $dbc->get_FK_info( -field => "FK_Solution__ID", -id => $solution_bottles[0] );
            $Ramt[$index] = $info;
        }

        if ( $Sol{baseline}[$index] < 0.1 ) {
            $Rwell[$index] = sprintf( "%4.4g", $Sol{baseline}[$index] * 1000 ) . " ul/w";
        }
        else {
            $Rwell[$index] = sprintf( "%4.4g", $Sol{baseline}[$index] ) . " ml/w";
        }

        my ( $amt, $units ) = &Get_Best_Units( -amount => $Sol{quantities}[$index], -units => $Sol{units}[$index] );
        my ($mils) = &normalize_units( $Sol{quantities}[$index], $Sol{units}[$index] );
        $RTtotal += $mils;

        $Rtotal[$index] = sprintf( "%4.4g %s", $amt, $units );

        $index++;
    }

    ( $RTtotal, my $RTunits ) = &Get_Best_Units( -amount => $RTtotal, -units => 'mL' );
    $RTtotal = ( int( $RTtotal * 100 ) / 100 ) . " $RTunits";
    my $solinfo = substr( &now(), 0, 10 );
    my $solname = $Sol{name};
    if ($samples) {
        $solinfo .= " - $blocks x $block_samples";
    }
    $solinfo .= " ($user)";
    my $message   = $Sol{message};
    my %labelinfo = (
        'name'    => $solname,
        'solinfo' => $solinfo,
        'message' => substr( $message, 0, 60 ),

        #'formula'=>"Formula: ".substr($Sol{formula},0,100)
        'RTtotal' => $RTtotal,
        'RTamt'   => "TOTAL",

        #'RTrect'  => "500",
        'newids' => $newids,
    );

    foreach my $i ( 0 .. ( $index - 1 ) ) {
        $labelinfo{ "R" . ( $i + 1 ) . "name" }  = "$Rname[$i]";
        $labelinfo{ "R" . ( $i + 1 ) . "amt" }   = "$Ramt[$i]";
        $labelinfo{ "R" . ( $i + 1 ) . "total" } = "$Rtotal[$i]";
        $labelinfo{ "R" . ( $i + 1 ) . "well" }  = "($Rwell[$i])";
        $labelinfo{ "R" . ( $i + 1 ) . "box" }   = "box";
        $labelinfo{ "R" . ( $i + 1 ) . "rect" }  = "800";
    }

    if ( $index < 3 ) {
        $labelinfo{ "R" . (4) . "name" } = substr( $message, 0,  41 );
        $labelinfo{ "R" . (5) . "name" } = substr( $message, 41, 44 );
        $labelinfo{ "R" . (6) . "name" } = substr( $message, 85 );
        $labelinfo{'message'} = '';
    }

    #    if ($Sol{Parameter_name}) {
    #	foreach my $i (0..(@{$Sol{Parameter_name}}-1) ) {
    #	    if ($Sol{Parameter_name}[$i]) {
    #		$labelinfo{"F".($i+1)."line"} = $Sol{Parameter_name}[$i] . ' = ' . $Sol{Parameter_value}[$i];
    #	    }
    #	}
    #    }
    my $label_type = "large_chemistry_calc";
    require alDente::Barcode;
    my $bc = alDente::Barcode->new( -type => "large_chemistry_calc", -dbc=>$dbc);

    $bc->set_fields(%labelinfo);

    $bc->print(-printer => $printer );
    return 1;
}

##################################
# Function to call the correct print functions
# Depending on printer capabilities
###################################
sub print_chemistry_sheet {
###################################
    my %args    = &filter_input( \@_, -args => 'sol,samples' );
    my $sol     = $args{-sol};
    my $samples = $args{-samples};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    # get label type (format of label - either laser or barcode)
    my ($output) = $dbc->Table_find( "Standard_Solution", "Label_Type", "WHERE Standard_Solution_Name = '$sol->{name}'" );

    my $label_type = "chemistry_calc";
    require alDente::Barcode;
    my $bc = alDente::Barcode->new( -type => "chemistry_calc" );

    # get the printer and reroute depending on if it is a ZPL printer or a normal printer
    my $printer = '';
    if ( $output =~ /zpl/i ) {
        $printer = $bc->get_printer( -label_type => $label_type, -label_height => $bc->get_attribute("height") );

        # ZPL barcode printer, call barcode printing functions
        $dbc->message("printing chemistry to $printer");
        &alDente::Chemistry::large_chemistry_barcode( $sol, $samples, $printer );
    }
    else {
        my ( $printer, $printer_id ) = $bc->get_printer( -label_type => 'laser', -label_height => '11.5', -dbc => $dbc );

        $dbc->message("printing chemistry to $printer");

        # normal laser printer, call LaTeX printing function
        &chemistry_latex_printout( $sol, $samples, $printer, $dbc );
    }
}

###################################
# Function that prints
###################################
sub chemistry_latex_printout {
###################################
    my $sol     = shift;
    my $samples = shift;
    my $printer = shift;
    my $dbc     = shift;

    my %Sol = %{$sol};

    my $index = 0;
    my @Rname;
    my @Ramt;
    my @Rtotal;

    foreach my $param ( 1 .. $Sol{solutions} ) {
        $Rname[$index] = $Sol{labels}[$index];
        $Ramt[$index]  = $Sol{Solution_ID}[$index];

        #if ( $Sol{baseline}[$index] < 0.1 ) {
        #    $Ramt[$index] = sprintf( "%4.4g %s", $Sol{baseline}[$index] * 1000, "ul/w" );
        #}
        #else {
        #    $Ramt[$index] = sprintf( "%4.4g %s", $Sol{baseline}[$index], "ml/w" );
        #}

        my ( $amt, $units ) = &Get_Best_Units( -amount => $Sol{quantities}[$index], -units => $Sol{units}[$index] );
        $Rtotal[$index] = sprintf( "%4.4g %s", $amt, $units );

        $index++;
    }

    my $today_date = &today();
    my $user_name  = $dbc->get_local('user_name');

    my $latex_str = '';

    # start LaTeX document
    $latex_str .= "\\documentstyle[12pt]{article}\n";
    $latex_str .= "\\pagestyle{empty}\n";
    $latex_str .= "\\begin{document}\n";

    # write out solution name
    $latex_str .= "\\large\\textbf{" . escape_latex_str( $Sol{name} ) . "} x ($samples)\\normalsize\n\n";
    $latex_str .= "$today_date ($user_name)\n\n";
    $latex_str .= "Constituents : \n";

    # start table
    $latex_str .= "\\begin{center}\n";
    $latex_str .= "\\begin{tabular}[b]{|r|r|r|r|}\n";
    $latex_str .= "\\hline\n";

    # write out table headers
    $latex_str .= "Reagent Name & Solution & Amount & \\hspace{20 mm} \\\\ \n";
    $latex_str .= "\\hline\\hline\n";

    # write out table elements
    my $count = 0;
    while ( $count < $index ) {
        my $row_str = escape_latex_str( $Rname[$count] ) . " & $Ramt[$count] & $Rtotal[$count] & \\hspace{20 mm} \\\\ \n";
        $row_str   .= "\\hline\n";
        $latex_str .= $row_str;
        $count++;
    }

    # end table
    $latex_str .= "\\end{tabular}\n";
    $latex_str .= "\\end{center}\n";

    # escape latex special characters
    my $escaped_message = escape_latex_str( $Sol{message} );

    # write out message
    $latex_str .= "\nMessage: \\emph{$escaped_message}\n\n";

    # print out formula
    #my $escaped_formula = escape_latex_str( $Sol{formula} );
    #$latex_str .= "\nFormula: $escaped_formula\n\n\n\n";

    # print out paramters if they are printable
    $count = 0;
    my $print_param_head = 1;
    while ( $count < $index ) {
        my $param_name = $Sol{Parameter_name}[$count];
        if ($param_name) {
            if ($print_param_head) {
                $latex_str .= "\\textbf{Parameters:}\n\n";
                $latex_str .= "\\begin{itemize}\n";
                $print_param_head = 0;
            }
            $param_name = escape_latex_str($param_name);
            $latex_str .= "\\item\n";
            $latex_str .= $param_name . ' = ' . $Sol{Parameter_value}[$count] . "\n\n";
        }
        $count++;
    }

    # only print end if the param_head has been switched from 1 to 0
    if ( !$print_param_head ) {
        $latex_str .= "\\end{itemize}\n";
    }

    # Add solution number
    $latex_str .= escape_latex_str("Sol$Sol{'new solutions'}: $Sol{name}") . "\n\n";

    # end document
    $latex_str .= "\\end{document}\n";

    # grab the correct printer (has to be a laser printer!)

    # print if the URL
    # write out to the temp directory with a random name
    my $texfile = "$alDente::SDB_Defaults::URL_temp_dir/Chemistry@{[timestamp()]}";
    open( INF, ">$texfile.tex" );
    print INF $latex_str;
    close INF;
    try_system_command("cd $alDente::SDB_Defaults::URL_temp_dir && latex $texfile.tex");
    try_system_command("dvips -P$printer $texfile.dvi");
    return 1;
}

#########################
sub escape_latex_str {
#########################
    my $str = shift;
    $str =~ s/([\#\$%&_{}])/\\$1/g;
    return $str;
}

####################################
sub create_Formula_interface {
####################################
    my $dbc = shift;

    Message("Create new Standard Chemistry Formula");

    print alDente::Form::start_alDente_form( $dbc, 'ChemForm', undef );
    my $Table = HTML_Table->new( -title => 'Standard Chemistry Details' );
    $Table->Set_Row( [ 'Name of Solution to be made: ',      textfield( -name => 'Standard_Solution_Name',       -size => 20, -force => 1 ) ] );
    $Table->Set_Row( [ 'Formula for each reagent: ',         textfield( -name => 'Standard_Solution_Formula',    -size => 20, -force => 1 ), "This will be calculated independently for each reagent.  (eg. Reagent*samples + DeadVolume)" ] );
    $Table->Set_Row( [ 'Number of Reagents to be Scanned: ', textfield( -name => 'Standard_Solution_Parameters', -size => 20, -force => 1 ) ] );
    $Table->Set_Row( [ 'Message to be Generated: ',          textfield( -name => 'Standard_Solution_Message',    -size => 20, -force => 1 ), "Use format : 'text message = (formula)'.  Anything to the right of the '=' will be evaluated." ] );
    $Table->Set_Row( [ submit( -name => 'Chemistry_Event', -value => 'Add Formula', -class => "Action" ), popup_menu( -name => 'Standard_Solution_Status', -values => [ 'Active', 'Archived', 'Under Development' ], -default => 'Under Development' ) ] );
    $Table->Printout();
    print end_form();

    return;
}

################################################
# Retrieve groups for which formula is visible
#
###########
sub groups {
###########
    my $self = shift;
    my %args = filter_input( \@_, -args => ('formula_id') );
    my $id   = $args{-formula_id} || $self->{id};
    my $dbc  = $self->{dbc};

    my $group_ids = join ',', $dbc->Table_find( 'GrpStandard_Solution', 'FK_Grp__ID', "WHERE FK_Standard_Solution__ID = $id" );
    return $group_ids;
}

################################################
# Add group(s) for which formula is visible
#
# Return : Added groups.
#############
sub add_group {
#############
    my $self   = shift;
    my $dbc    = $Connection;
    my %args   = filter_input( \@_, -args => ( 'formula_id', 'group' ) );
    my $id     = $args{-formula_id} || $self->{id};
    my $groups = $args{-group} || $args{ -groups };

    my $added = 0;
    if ( $groups =~ /[1-9]/ && $id ) {
        foreach my $group ( split ',', $groups ) {
            my $ok = $dbc->Table_append_array( 'GrpStandard_Solution', [ 'FK_Grp__ID', 'FK_Standard_Solution__ID' ], [ $group, $id ] );
            $added++ if $ok;
        }
    }
    else {
        Message("Must supply formula id and group list to update");
    }
    return $added;
}

sub get_value {
    my %args     = filter_input( \@_, -args => ( 'params', 'value' ) );
    my $params   = $args{-params};
    my $value    = $args{-value};
    my $name     = $args{-name};
    my $dbc      = $args{-dbc};
    my $count    = defined $args{-count} ? $args{-count} : keys %{$params};
    my $wells    = $args{-wells} || 0;
    my $original = $value;

    my $index = 0;
    for my $key ( keys %{$params} ) {
        my $param_value = $params->{$key};
        if ( $param_value =~ /[\+\-\*\/]/ ) { $param_value = "($param_value)" }
        $value =~ s/\b$key\b/$param_value/g;    #substitute variable with real value
    }

    if ($wells) {
        $value =~ s /\b(wells|samples)\b/$wells/ig;
    }

    my $pre_evaluate = $value;
    $value =~ s/^(.*)$/$1/ee;                   #evaluate formula

    if ( !$value && $value ne 0 ) {
        if ($count) {
            $count--;
            return &get_value( -params => $params, -value => $pre_evaluate, -name => $name, -dbc => $dbc, -count => $count );
        }
        else {
            $dbc->{session}->warning("Invalid parameter value for $name: $original") if $dbc->{session};
        }
    }

    return $value;
}

##########################
# Get the Grp_Access privileges for the specified chemistry
#
# Example:	my $access = get_grp_access( -dbc => $dbc, -id => $id, -grp_ids => '8,9' );
#
# Return:	Hash Ref of Grp ID and Grp_Access
##########################
sub get_grp_access {
##########################
    my $self           = shift;
    my %args           = filter_input( \@_, -args => 'dbc' );
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $chemistry_id   = $args{-id} || $self->{id};
    my $chemistry_name = $args{-name};
    my $grp_ids        = $args{-grp_ids};

    my $extra_conditions = '';
    if ($grp_ids) {
        my $grp_list = Cast_List( -list => $grp_ids, -to => 'String', -autoquote => 0 );
        $extra_conditions .= " and FK_Grp__ID in ( $grp_list ) ";
    }

    my %grp_access;
    my %access_info;
    if ($chemistry_id) {
        %access_info = $dbc->Table_retrieve( 'GrpStandard_Solution', [ 'FK_Grp__ID', 'Grp_Access' ], "WHERE FK_Standard_Solution__ID = $chemistry_id $extra_conditions" );
    }
    elsif ($chemistry_name) {
        %access_info = $dbc->Table_retrieve( 'Standard_Solution, GrpStandard_Solution', [ 'FK_Grp__ID', 'Grp_Access' ], "WHERE FK_Standard_Solution__ID = Standard_Solution_ID and Standard_Solution_Name = '$chemistry_name' $extra_conditions" );
    }
    my $index = 0;
    while ( defined $access_info{FK_Grp__ID}[$index] ) {
        $grp_access{ $access_info{FK_Grp__ID}[$index] } = $access_info{Grp_Access}[$index];
        $index++;
    }
    return \%grp_access;
}

sub get_chemistry_status_options {
    my %args = filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my ($field_type) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Table = 'Standard_Solution' and Field_Name = 'Standard_Solution_Status'" );
    my @options;
    if ( $field_type && $field_type =~ /^enum\((.*)\)$/ ) {
        my @values = split ',', $1;
        foreach my $option (@values) {
            if ( $option =~ /^[\'\"](.*)[\'\"]$/ ) {
                push @options, $1;
            }
        }
    }
    return @options;
}

##############################
# Retrieve standard chemistries that meet the given conditions
#
# Example:	my $chemistries = get_standard_chemistries( -dbc => $dbc, -department => 'Lib_Construction', -status => 'Active' );
#
# Return:	Array ref of standard chemistries
##############################
sub get_standard_chemistries {
##############################
    my %args       = filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc};
    my $department = $args{-department};
    my $grp_ids    = $args{-grp_ids};
    my $grp_type   = $args{-grp_type};                      # specify Grp.Grp_Type
    my $access     = $args{-access};                        # specify Grp.Access
    my $grp_access = $args{-grp_access};                    # specify GrpStandard_Solution.Grp_Access
    my $status     = $args{-status};

    my $tables     = 'Standard_Solution,GrpStandard_Solution,Grp';
    my $conditions = ' WHERE Standard_Solution.Standard_Solution_ID = GrpStandard_Solution.FK_Standard_Solution__ID AND GrpStandard_Solution.FK_Grp__ID = Grp_ID ';
    if ($department) {
        $tables     .= ',Department';
        $conditions .= " AND Grp.FK_Department__ID = Department_ID AND Department_Name = '$department' ";
    }
    if ($grp_type) {
        my $list = Cast_List( -list => $grp_type, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Grp_Type in ( $list ) ";
    }
    if ($grp_ids) {
        my $list = Cast_List( -list => $grp_ids, -to => 'String', -autoquote => 0 );
        $conditions .= " AND Grp_ID in ( $list ) ";
    }
    if ($access) {
        my $list = Cast_List( -list => $access, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Grp.Access in ( $list ) ";
    }
    if ($grp_access) {
        my $list = Cast_List( -list => $grp_access, -to => 'String', -autoquote => 1 );
        $conditions .= " AND GrpStandard_Solution.Grp_Access in ( $list ) ";
    }
    if ($status) {
        my $list = Cast_List( -list => $status, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Standard_Solution_Status in ( $list ) ";
    }
    my @chemistries = $dbc->Table_find(
        -table     => $tables,
        -fields    => 'Standard_Solution_Name',
        -condition => $conditions,
        -distinct  => 1
    );
    return \@chemistries;
}

sub convert_to_labeled_list {
    my %args = filter_input( \@_, -args => 'names', -mandatory => 'names' );
    my $names = $args{-names};

    my @choices = ('-');
    my %labels = ( '-' => '--Select--' );
    foreach my $chem (@$names) {
        my $pad_chem = URI::Escape::uri_unescape($chem);
        push( @choices, $pad_chem );
        $labels{$pad_chem} = $chem;
    }
    @choices = sort(@choices);
    return ( \@choices, \%labels );
}

##########################
# Set chemistry status
#
# Example:	my $ok = set_chemistry_status( -dbc => $dbc, -id => $id, -status => 'Active' );
#
# Return:	1 if success; 0 if fail
##########################
sub set_chemistry_status {
##########################
    my $self           = shift;
    my %args           = filter_input( \@_, -args => 'dbc' );
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $chemistry_id   = $args{-id} || $self->{id};
    my $chemistry_name = $args{-name} || $self->{name};
    my $status         = $args{-status};

    if ( !$chemistry_id && !$chemistry_name ) {
        return;
    }

    my $conditions = "WHERE 1 ";
    if ($chemistry_id) {
        $conditions .= " and Standard_Solution_ID = $chemistry_id ";
    }
    elsif ($chemistry_name) {
        $conditions .= " and Standard_Solution_Name = '$chemistry_name' ";
    }
    my $ok = $dbc->Table_update_array( 'Standard_Solution', ['Standard_Solution_Status'], [$status], "$conditions", -autoquote => 1 );
    return $ok;
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

$Id: Chemistry.pm,v 1.43 2004/11/25 20:22:52 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
