################################################################################
# Form.pm
#
# This module has the user interface controls for alDente
#
###############################################################################
package alDente::Form;

#use base SDB::DB_Form;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Container.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

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
use CGI qw(:standard);
use Data::Dumper;

use RGTools::RGIO;
use RGTools::HTML_Table;

use SDB::HTML;
use SDB::Errors;

use LampLite::Form;
use LampLite::Bootstrap;

use vars qw(%Sess);

### Default Colour Scheme ###
my $tab_clr = '#99c';
my $off_clr = '#ccccff';

## section headings ##
my $page_heading_clr       = '#9ac';    ## may need to make lighter (abd) if links don't work with this background ...
my $section_heading_clr    = '#abd';
my $subsection_heading_clr = '#cdf';

####################################
#### Remove Exporter Block & Connection ASAP ####
####################################
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
    Set_Parameters
);

use vars qw($Connection);

####################################
use strict;

my $BS = new Bootstrap;
##########################
# Wrapper that should be used to initiate all alDente Forms
#  (see start_custom_form) - calls start_custom_form with a few alDente specific parameters set.
#
# <snip>
# eg.
#    print start_alDente_form($dbc, 'NewRecord');
#    ..<include visible form contents here>
#    print end_form();
#</snip>
#
# Return: HTML String.  eg("<Form>...<input type='hidden' name='param1' value='value1'>... ")
##########################
sub start_alDente_form {
#################n#########
    my %args       = filter_input( \@_, -args => 'dbc,name,type,url,parameters' );
    my $dbc        = $args{-dbc};
    my $name       = $args{-form} || $args{-name} || 'thisform';                     ## name of form - optional (passed onto start_custom_form)
    my $type       = $args{-type};                                                   ## eg Plate, Prep etc (optional - may automatically include Parameter types as hidden fields (see _alDente_URL_Parameters))
    my $url        = $args{-url};
    my $parameters = $args{-parameters};
    my $class      = $args{-class} || 'form-horizontal';                                 ## default to use inline form elements (eg radio / checkboxes...) - set class = 'form' to override...
    my $style      = $args{-style};
    my $debug      = $args{-debug};
    my $clear      = $args{-clear} || [];                                            ## input fields in url that will NOT be set as hidden input variables in the form

    ## simply add alDente URL Paramters to arguments and pass on to start_custom_form
    my %P = _alDente_URL_Parameters( -dbc => $dbc, -type => $type, -debug => $debug, -parameters => $parameters );

    ## replace with standardized form generator ##
    my $form = new LampLite::Form( -dbc => $dbc, -name => $name, -type => $type, -style => $style );

    if ( $type eq 'start' ) { push @$clear, 'Database_Mode' }
    elsif ( $clear eq '1' ) { $clear = $dbc->config('url_parameters') }

    my $block = $form->generate( -dbc => $dbc, -open => 1, -parameters => \%P, -clear => $clear, -class => $class );

    if ($debug) { print HTML_Dump \%P, '....', $block }

    return $block;
}

#####################
# Phased out - this should not be used... use 'start_alDente_form' instead to initialize form...
####################
sub Set_Parameters {
####################
    my %args    = filter_input( \@_, -args => 'type,options,dbc' );
    my $type    = $args{-type};
    my $options = $args{-options};
    my $dbc     = $args{-dbc} || $Connection;

    print $BS->warning( "LIMS team: Remove deprecated call to Set_Parameters<HR>if start_aldente_form is used, parameters can simply be removed since it is redundant.<HR>" . Cast_List( -list => Call_Stack( -quiet => 1 ), -to => 'UL' ) );
    SDB::Errors::log_deprecated_usage('Set_Parameters');
    return;
    ## start_alDente_form automatically calls _alDente_URL_Parameters already ... ##
    return _alDente_URL_Parameters( -dbc => $dbc, -type => $type, -options => $options );
}

###########################
# Populates hash of alDente specific parameters to be passed between forms or run modes.
#
# Return: hash;
###########################
sub _alDente_URL_Parameters {
###########################
    #
    # get standard parameters for html forms
    #
    # this routine generates a set of parameters to send to 'start_custom_form',
    #  passing hidden variables as specified in $P{Name}[$index] = $P{Value}[$index]
    #
    #
    my %args = filter_input( \@_, -args => 'dbc,type' );
    my $dbc        = $args{-dbc} || $main::dbc;
    my $type       = $args{-type};
    my $parameters = $args{-parameters};
    my $options    = $args{-options};
    my $debug      = $args{-debug};

    # globals required:
    #
    #  $barcode, $sol_mix
    #  $plate_set, $plate_id, $current_plates, $step_name
    #  $stock_page
    #  $session_id $user, $dbase, $project
    #

    my $Current_Department = $dbc->config('Target_Department');

    my %P;    ## = SDB::HTML::URL_Parameters( $dbc, $options, $type );
    if ($parameters) { %P = %$parameters }

    if ( $Sess{scanner_mode} ) {
        $P{Method} = 'POST';
        if ($Current_Department) { $P{Target_Department} = $Current_Department; }
    }
    else { $P{Method} = 'POST'; }

    if ( $type =~ /protocol/i ) { }
    elsif ( $type =~ /solution/i ) {
        push( @{ $P{Name} }, ( 'Solution_ID', 'Sol Mix' ) );
        push( @{ $P{Value} }, ( $main::barcode, $main::sol_mix ) );
    }
    elsif ( $type =~ /prep/i ) {
        push( @{ $P{Name} }, ( 'Barcode', 'Plate Set', 'Plate ID', 'Current Plates', 'Step Name' ) );
        push( @{ $P{Value} }, ( $main::barcode, $main::plate_set, $main::plate_id, $main::current_plates, $main::step_name ) );
        $P{Method} = 'POST';    #### do not allow back button in Preparation mode..
    }
    elsif ( $type =~ /plate/i ) {
        push( @{ $P{Name} }, ( 'Plate Set', 'Plate ID', 'Current Plates', 'Step Name' ) );
        push( @{ $P{Value} }, ( $main::plate_set, $main::plate_id, $main::current_plates, $main::step_name ) );
        push @{ $P{'Current Plates'} }, $main::current_plates;    # Name-Value pairs will be phased out, set as separate param
    }
    elsif ( $type =~ /order/i ) {
        push( @{ $P{Name} },  ('PageName') );
        push( @{ $P{Value} }, ( param('PageName') ) );
    }

    unless ( $type =~ /start/i ) {
        push @{ $P{Name} },  'Project';
        push @{ $P{Value} }, $main::project;
    }
    return %P;
}

##########################################################################
# Method to simplify initialization of a standard Table object on a given page (HTML)
#
# <snip>
#  eg.
#    my $Table = init_HTML_table('Table title');
#    $Table->Set_Row(\@row);
#    $Table->Printout();
# </snip>
##########################
sub init_HTML_table {
##########################
    my %args       = filter_input( \@_, -args => 'title' );
    my $title      = $args{-title};
    my $supertitle = $args{-supertitle};                      ## title goes on a separate line from the left & right options if applicable
    my $align      = $args{-align};
    my $margin     = $args{-margin};
    my $subsection = $args{-subsection};
    my $centre     = $args{-centre};
    my $left       = $args{-left};                            ## optionally supply left justified, and/or right justified text for the title
    my $right      = $args{-right};
    my $colour     = $args{-colour};
    my $substyle   = $args{-substyle};

    if ( $left && !$title ) { $title = $left; $left = ''; }

    my $header_colour  = $section_heading_clr;
    my $default_margin = 150;

    my $class;
    if ($title) {
        $class = 'section-heading';
        $colour   ||= $section_heading_clr;
        $substyle ||= 'font-size:60%; ';
    }
    if ($subsection) {
        $title ||= $subsection;
        $class = 'subsection-heading';
        $colour   ||= $subsection_heading_clr;
        $substyle ||= 'font-size:75%; ';
    }

    if ( $left || $centre || $right || $title || $supertitle ) {
        my $supertitle;

        if ($supertitle) { $supertitle = "\t<TR><TD colspan=4>$supertitle<HR></TD></TR>\n" }

        $title = "\n<TABLE border=0 cellspacing=0 cellpadding=0 width='100%'>\n$supertitle\t<TR>\n" . "\t\t<TD style='padding-left:50px; padding-right:50px'><b>$title</b></TD>\n";

        if ( $left || $centre || $right ) {
            $title .= "\t\t<TD align=left style='$substyle'><B>$left</B></TD>\n" . "\t\t<TD align=center style='$substyle'><B>$centre</B></TD>\n" . "\t\t<TD align=right style='$substyle'><B>$right</B></TD>\n";
        }

        $title .= "\t</TR>\n</TABLE>\n";
    }

    $args{-width} ||= '100%';
    my $table = HTML_Table->new(%args);

    $table->Toggle_Colour('off');
    $table->Set_Line_Colour('#eeeeee');

    #    $table->Set_Header_Colour($page_heading_clr);

    #    $table->Set_Line_Colour('#ddddda');
    #    $table->Set_Spacing(0);
    #    $table->Set_Padding(0);

    if ($margin) {
        if ( $margin !~ /^(\d+)$/ ) { $margin = $default_margin }    ## default width... or else set to integer
        $table->Set_Column_Colour( 1, '#ffffff' );
        $table->Set_Column_Widths( [$margin] );
    }

    $table->Set_Title( $title, bgcolour => $args{-colour}, class => $class, fclass => 'medium', fstyle => 'bold' );

    return $table;
}

##########################################
# Create an Failed button.
# Input: The object which we want to fail, Name of the button
#
# Returns: HTML Button
######################
sub fail_btn {
######################
    my %args   = filter_input( \@_ );
    my $object = $args{-object};
    my $dbc    = $args{-dbc};

    my $groups  = $dbc->get_local('group_list');
    my $reasons = alDente::Fail::get_reasons( -object => $object, -grps => $groups );
    my $status  = "<Table><TR><TD>\n";

    $status .= submit(
        -name    => "Set Failed $object",
        -value   => "Set $object status to Failed",
        -class   => 'Action',
        -onClick => "unset_mandatory_validators(this.form); document.getElementById('failreason_validator').setAttribute('mandatory',1); document.getElementById('comments_validator').setAttribute('mandatory',1); return validateForm(this.form)"
    );

    $status .= "</TD><TD>\n";

    $status .= popup_menu(
        -name   => 'FK_FailReason__ID',
        -values => [ '', keys %{$reasons} ],
        -labels => $reasons,
        -force  => 1
    );

    $status .= set_validator( -name => 'FK_FailReason__ID', -id => 'failreason_validator' );
    $status .= set_validator( -name => 'Comments',          -id => 'comments_validator' );
    $status .= "<font size=3><B>Comments (Mandatory):&nbsp;</B></font>";
    $status .= textfield( -name => 'Comments', -size => 30, -default => '' );
    $status .= "</TD></TR>";

    $status .= "</Table>";
    return $status;
}
##############################################################################
# This method handles the action associated with the failed button.
# User specify the dbc connection and the object which they would like to fail
##############################################################################
sub catch_fail_btn {
##########################
    my %args = filter_input( \@_ );

    my $dbc         = $args{-dbc};
    my $object      = $args{-object};
    my $bypass      = $args{-bypass};
    my $fail_reason = param('FK_FailReason__ID') || $args{-reason};
    my $comments    = param('Comments') || $args{-comments};

    my @ids;

    if ( !($bypass) ) {
        if ( !( param("Set Failed $object") ) ) {
            return 1;
        }
    }

    if ( $object eq 'Plate' ) {
        @ids = param('Mark');
        unless (@ids) {
            @ids = param('FK_Plate__ID');
        }
    }

    if (@ids) {
        my $fk_failreason__id = $fail_reason;
        my $fail_status_field = undef;
        my $fail_status_value = undef;
        if ( $object eq 'Plate' ) {
            $fail_status_field = 'Failed';
            $fail_status_value = 'Yes';
        }
        alDente::Fail::Fail( -object => $object, -ids => \@ids, -reason => $fk_failreason__id, -comments => $comments, -fail_status_field => $fail_status_field, -fail_status_value => $fail_status_value );
    }
    return 1;

}

###########################
sub get_form_input {
###########################
    # This function takes in table name and retrieves the fields and values associated with that table which have been passed
    # to the run mode from the previous run mode from params.
    #
    # Usage:
    #		(my $fields,my $values) = $dbc->get_form_input(-table=> 'Stock_Catalog', -object => $object);
    #	or
    #		my $hidden_Info =  $dbc->get_form_input(-table=> 'Stock_Catalog', -object => $object, -HTML_on =>1);
###########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $object       = $args{-object};
    my $q            = $object->query;
    my $table        = $args{-table};
    my $return_HTML  = $args{-HTML_on};         ###### used to pass info through a run mode as hidden values
    my $array_return = $args{-array_return};    ##### if need array ref returned instead of scalars
    my $hidden_info;
    my @fields = $dbc->get_field_info( $table, undef );
    my @values;
    require SDB::HTML;

    foreach my $field (@fields) {

        if ($array_return) {
            my @array = SDB::HTML::get_Table_Params( -table => $table, -field => $field, -convert_fk => 1, -dbc => $dbc );
            push @values, \@array;
            $hidden_info .= hidden( -name => $field, -value => \@array, -force => 1 );
        }
        else {
            my $value = SDB::HTML::get_Table_Param( -table => $table, -field => $field, -convert_fk => 1, -dbc => $dbc );
            push @values, $value;
            $hidden_info .= hidden( -name => $field, -value => $value, -force => 1 );
        }
    }

    if   ($return_HTML) { return ($hidden_info) }
    else                { return ( \@fields, \@values ) }

}

#
# The next two methods are VIEWS
#
##
##################
sub merging_info {
##################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $preset    = $args{-preset};
    my $conflicts = $args{-conflicts};
    my $input     = $args{-input};
    my $ignore    = $args{-ignore};
    my $id        = $args{-id};

    my $output;
    if ($preset) {
        my $PC = new HTML_Table( -title => 'Pooling Consensus values' );
        foreach my $key ( keys %$preset ) {
            $PC->Set_Row( [ $key, $preset->{$key} ] );
        }
        $output .= SDB::HTML::create_tree( -tree => { 'Preset' => $PC->Printout(0) } );
    }
    if ( $input && int( keys %$input ) ) {
        my $PC = new HTML_Table( -title => 'User Input' );
        foreach my $field ( keys %$input ) {
            my @tables = keys %{ $input->{$field} };
            my $table = int(@tables) ? $tables[0] : '';

            if ( $ignore =~ /\b$field\b/ ) {next}
            my $field_id = $field;
            if ($id) { $field_id .= ".$id" }
            $output .= hidden( -name => 'Input_List', -value => $field_id, -force => 1 ) . SDB::HTML::set_validator( -name => "IN.$field_id", -mandatory => 1, -prompt => "You must enter a value for $field" );
            my ($type) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Name = '$field'" );
            my $input_spec = &SDB::DB_Form_Views::get_Element_Output(
                -dbc          => $dbc,
                -field        => $field,
                -table        => $table,
                -element_name => "IN.$field_id",
                -field_type   => $type,
            );
            $PC->Set_Row( [ $field, $input_spec ] );
        }
        $output .= $PC->Printout(0);
    }
    if ($conflicts) {
        my $PC = new HTML_Table( -title => 'Pooling Conflicts' );
        my $rows = 0;
        foreach my $key ( keys %$conflicts ) {
            if ( $ignore =~ /\b$key\b/ ) {next}
            my $field_id = $key;
            if ($id) { $field_id .= ".$id" }
            $output .= hidden( -name => 'Conflict_List', -value => $field_id, -force => 1 ) . SDB::HTML::set_validator( -name => "OC.$field_id", -mandatory => 1, -prompt => "You must clarify how to handle $key conflicts" );
            $PC->Set_Row( [ $key, &on_conflict_prompt( $dbc, $conflicts->{$key}, $key, $id ) ] );
            $rows++;
        }
        if ( !$rows ) {
            $PC->Set_Row( ['No conflict'] );
        }
        $output .= $PC->Printout(0);
    }

    return $output;
}

#
# This may be phased out by enabling this functionality within get_prompt or search_list, but for now this enables users to resolve conflicts on certain fields when merging multiple records into one.
#
# Return: html for user prompt
#########################
sub on_conflict_prompt {
#########################
    my %args     = filter_input( \@_, -args => 'dbc,conflict,field,id' );
    my $dbc      = $args{-dbc};
    my $conflict = $args{-conflict};                                        ## hash of conflicts found (eg 'value1' => count )
    my $field    = $args{-field};                                           ## specific field to resolve conflict for
    my $id       = $args{-id};                                              ## ID to distinguish different batches of conflicts

    my $field_id = $field;
    if ($id) { $field_id .= ".$id" }                                        ## append $id if $id is passed in

    my $current_options = keys %$conflict;

    my $current_options = "Current Settings:\n";
    foreach my $key ( keys %$conflict ) {
        $current_options .= "$key [x$conflict->{$key}]\n";
    }

    my ( $rtable, $rfield ) = $dbc->foreign_key_check($field);
    my ($type) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Name = '$field'" );
    my $onclick;

    my $radio_buttons;
    if ($rtable) {
        my @options = keys %$conflict;
        my $options = Cast_List( -list => \@options, -to => 'string', -autoquote => 1 );
        $radio_buttons
            = alDente::Tools::search_list( -dbc => $dbc, -name => "set.$field_id", -table => $rtable, -field => $field, -condition => "$rfield IN ($options)", -onChange => "SetElement('OC.$field_id', document.getElementById('set.$field_id').value);" );
    }
    elsif ( $type =~ /^DATE/i ) {
        $radio_buttons = radio_group( -name => "set.$field_id", -value => "clear", -onclick => "SetElement('OC.$field_id','<clear>');" );

        my $format = 'Y-m-d';
        if ( $type =~ /TIME/i ) { $format .= ' H:i' }
        $onclick = $BS->calendar( -id => "OC.$field_id", -format => $format );
    }
    elsif ( $type =~ /^ENUM\((.+)\)/i ) {
        my $opts = $1;
        $opts =~ s/\'//g;
        my @options = split /,/, $opts;

        if ( grep /^[\'\"]?(Mixed)[\'\"]?$/, @options ) { @options = ('Mixed') }    ## if mixed option is available, set to this value (only other option should be clear)
        $radio_buttons = radio_group( -name => "set.$field_id", -value => "clear", -onclick => "SetElement('OC.$field_id','<clear>');" )
            . popup_menu( -name => "set.$field_id", -id => "set.$field_id", -values => [ '', @options ], -onChange => "SetElement('OC.$field_id', document.getElementById('set.$field_id').value);" );
    }
    elsif ( $type =~ /(float|int|decimal)/ ) {
        $radio_buttons = radio_group( -name => "set.$field_id", -value => "clear", -onclick => "SetElement('OC.$field_id','<clear>');" ) . radio_group( -name => "set.$field_id", -value => 'average', -onclick => "SetElement('OC.$field_id','<average>')" );
    }
    elsif ( $type =~ /(varchar|TEXT)/i ) {
        $radio_buttons = radio_group( -name => "set.$field_id", -value => "clear", -onclick => "SetElement('OC.$field_id','<clear>');" ) . auto_increment_prompt( $field, -target => "OC.$field_id" );
    }

    my $text = textfield( -name => "OC.$field_id", -id => "OC.$field_id", -onclick => $onclick );
    my $prompt = $text . Show_Tool_Tip( ' (current)', $current_options ) . '<br>' . $radio_buttons;

    return $prompt;
}

#
# Wrapper for generating auto-increment field using prefix & padding fields.
#
# Return: HTML required for form
#############################
sub auto_increment_prompt {
#############################
    my %args   = filter_input( \@_, -args => 'name,prompt' );
    my $field  = $args{-name};
    my $id     = $args{-id} || $field;
    my $target = $args{-target};

    my $prompt = $args{-prompt} || 'Auto Increment';

    my $onchange = "document.getElementById('$target').value = document.getElementById('$field.ai.prefix').value + '<N' + document.getElementById('$field.ai.padding').value + '>'";

    my $string = radio_group( -name => "set.$field", -value => 'auto-increment', -onclick => "set_mandatory_validators(this.form, '$field.ai.prefix'); set_mandatory_validators(this.form, '$field.ai.padding'); $onchange; validateForm(this.form);" );

    $string .= " Prefix: " . textfield( -name => "$field.ai.prefix",  -size => 10, -id => "$field.ai.prefix",  -onChange => $onchange );
    $string .= " Digits: " . textfield( -name => "$field.ai.padding", -size => 3,  -id => "$field.ai.padding", -onChange => $onchange );

    return $string;
}

return 1;

