###################################################################################################################################
# LampLite::Form.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package LampLite::Form;

use base LampLite::DB_Object;

use strict;

use RGTools::HTML_Table;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Form.pm - Form Model module for LampLite Package

=head1 SYNOPSIS <UPLINK>


=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use LampLite::Bootstrap;

##############################
# global_vars                #
##############################

my $BS = new Bootstrap;
################/default#####
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_, -args => 'name' );
    my $name = $args{-name};
    my $type = $args{-type};
    my $style = $args{-style};
    my $span  = $args{-span};
    my $class = $args{-class};
    my $framework = $args{-framework} || 'table';   ## eg table or bootstrap
    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    
    $self->initialize(%args);

    return $self;
}

################
sub initialize {
################
    my $self = shift;
    
    my %args = &filter_input( \@_, -args => 'name' );
    
    foreach my $key ( qw(dbc name type class style span framework title default_col_size label_style)) {
        $self->{$key} = $args{"-$key"};
    }
    return;
}


##################
sub configure {
##################

    my $self = shift;
    my %args = @_;

    my @config_settings = qw(default list options labels preset grey required conditions onchange);
    foreach my $arg ( keys %args ) {
        $arg =~ /\-?(.*)/;
        my $config = $1;
        if ( ( exists $self->{configs}->{$config} ) || ( grep /^$config$/, @config_settings ) ) {
            $self->{configs}->{$config} = $args{$arg};
        }
        else {
            #            Message("warning: $config does not exist");
        }
    }

    return;
}

#
# Store customization details in session attributes
#
#
# Return: null
################
sub customize {
################
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'name' );
    my $dbc        = $args{-dbc};
    my $persistent = $args{-persistent};                      ## persistent url parameters ##

    foreach my $param (@$persistent) {
        push @{ $dbc->session->{url_parameters} }, $param;
    }

    return;
}

#
# Wrapper to append all the fields from a specified table
#
# calls $Form->append subsequently for each field
#
#
# Requires installation of DBField table or defined field_info
#
# Return: updated form model with an extra row for every field
#####################
sub append_fields {
#####################
    my $self = shift;
    my %args       = &filter_input( \@_, -mandatory=>'table');   
    my $Preset = $args{-preset};
    my $Hidden = $args{-hidden};
    my $Default = $args{-default};
    my $table = $args{-table};
    my $style = $args{-style};
    my $id_suffix = $args{-id_suffix};
    my $record_id = $args{-record_id};
    my $name   = $args{-name};              ## in this case, name should be a pattern: eg "F.<Record_ID>" or "F.<DBField_ID>.<Record_ID>";
    my $fields = $args{-fields};
    my $action = $args{-action};            ## Append, Search or Edit 
    my $records = $args{-records} || 1;
    
    my @record_ids = Cast_List(-list=>$record_id, -to=>'ARRAY');
    if ($record_id) {
        ## if list of ids supplied, track number of records ##
        $records = int(@record_ids);
        $action ||= 'Edit';
    }
    else {
        $action ||= 'Append';
    }

    if ($records == 1) { 
        ## default to use matrix style form for multiple records if applicable ##
        $style ||= 'vertical'
    }
    else {
        $style ||= 'horizontal';
    }
    
    my @exclude = Cast_List(-list=>$args{-exclude}, -to=>'array');
    my $dbc = $self->{dbc};
    
    my $Field_Info = $dbc->field_info(-table=>$table);
    
    my %Map;
    if ($fields && @$fields) {
        my $field_list = join ',', @$fields;   
        if ($field_list && $field_list =~/^[\d,\s]+$/ && $dbc->table_loaded('DBField')) {
            ## map field ids to actual field names if supplied as ids ##
            my $Fields = $dbc->hash(-table=>'DBField', -fields=>['Field_Name', 'DBField_ID'], -condition=>"WHERE DBField_ID in ($field_list)");
            my $index = 0;
            while (defined $Fields->{DBField_ID}[$index] ) {
                my $id = $Fields->{DBField_ID}[$index];
                my $name = $Fields->{Field_Name}[$index];
                $Map{$id} = $name;
                $index++;
            }
        }
    }
    else {
        $fields = $dbc->fields($table);   
    }
    
    my $matrix = new HTML_Table();  ## only used for horizontal style ... 
    foreach my $i (1..$records) {
        my ($hidden, @row, @headers);
        if ($fields && @$fields) {
            foreach my $field (@$fields) {
                if (defined $Map{$field}) { $field = $Map{$field}}  ## map field ids to actual field names ##
                if ( grep /\b$field\b/, @exclude ) { next }
                if ( $field eq $table .'_ID' && $action =~/append/i) { next }  ## no prompt for new auto_increment id field ##
                my $id = $field;
                if ($id_suffix) { $id .= "-$id_suffix" }
                if ($records > 1) { $id .= "-$i" }
                
                my $record_id = $record_ids[$i-1];
                
                if (defined $Hidden->{$field}) { 
                    my $hidden = $Hidden->{$field};
                    $hidden =~s/<ID>/$record_id/g;  ## enable record specific hidden values 

                    push @{$self->{hidden}}, { 'name' => $field, 'value' => $Hidden->{$field}, 'id' => $id };
                    next; 
                }

                my $default = $Default->{$field} || '';

                my $preset = $Preset->{$field} || '';
                $preset =~s/<ID>/$record_id/g;  ## enable record specific hidden values 

                if ($style =~/vertical/) {
                    my ($label, $input) = $self->View->prompt(-table=>$table, -field=>$field, -id => $id, -value=>$preset, -default=>$default, -record_id=>$record_id, -name=>$name, -context=>$action);
                    $self->append($label, $input );
                }
                else {
                    my ($label, $input) = $self->View->prompt(-table=>$table, -field=>$field, -id => $id, -value=>$preset, -default=>$default, -record_id=>$record_id, -name=>$name, -context=>$action, -class=>''); ## class='' overrides 'form-control' default
                    push @headers, $label;
                    push @row, $input;
                }
            }
        }
        
        if ($style =~/horizontal/) { 
            if ($i == 1) {
                ## first pass only ... ##
                $matrix = new HTML_Table();
                $matrix->Set_Headers(\@headers);
            }
            $matrix->Set_Row(\@row);
        }
        elsif ($i < $records) {
            $self->append('', 'Next Record...');
        }
    }
    
    if ($matrix) { $self->append($matrix->Printout(0), -label_style=>"padding:0px") }  ## append entire table if displaying as horizontal record(s)

    return;
}

##############
sub append {
##############
    my $self = shift;
    my %args       = &filter_input( \@_, -args=>'label,input');
    my $label = $args{-label};
    my $input = $args{-input};
    my $raw   = $args{-raw};      ## raw input (eg -raw=>"<TR><TD>label</TD><TD>input</TD></TR>")
    my $span = $args{-span} || $self->{span};
    my $style = $args{-style};
    my $class = $args{-class};
    my $framework = $args{-framework} || $self->{framework};
    my $no_format = $args{-no_format};
    my $input_style = $args{-input_style};
    my $label_style = $args{-label_style} || $self->{label_style};
    my $width = $args{-width} || '100%';
    my $col_size = $args{-col_size} || $self->{default_col_size} || 'md';    ## optional size for bootstrap column specification (eg 'xs, sm, md, lg') - xs forces onto single line for mobile devices  
    
    my $fullwidth = $args{-fullwidth};   ## applicable only for table framework - enable label to span full width.
    if (!defined $input) { $fullwidth = 1 }  ## span full width if only one element supplied (can override by defining other element as '')
    
    my $row;
    if ($framework =~ /bootstrap/) { 
        $row = $BS->form_element(-label=>$label, -input=> $input, -span=>$span, -style=>$style, -class=>$class, -no_format=>$no_format, -col_size=>$col_size, -framework=>$framework);
    }
    else {
        if ($raw) { $row = $raw }
        else {
            $span ||= [2,10];   ## similar default in BS->form_element ... 
            
            my $label_span = "col-$col_size-" . $span->[0];           
            my $input_span = "col-$col_size-" .  $span->[1];
            
            my $w1 = int( $span->[0] / $span->[1] * 100 );
            my $w2 = 100 - $w1;
            if ($fullwidth) {
                $row = "<tr class='tr $class' style='$style' ><td class='td $label_span' style='$label_style' colspan=2 >$label</TD></TR> <!-- End of row -->\n";
            } 
            else {
                $row = "<tr class='tr $class' style='$style'><td class='td $label_span' style='$label_style' width='$w1%'>$label</td>\n<td class='td $input_span' style='$input_style' width='$w2%'>$input</TD></TR> <!-- End of row ($framework)-->\n";
            }
        }
        if ($framework !~/table/i) { $row = "<!-- Internal Table -->\n<Table width=$width>$row</Table>\n" }
    }
    
    push @{$self->{rows}}, $row;
    return;
}

#
# Wrapper to generate form block
#
# Input options:
#   -content (content elements of form)
#   -wrap (wrap form in start and end form tags)
#
# Return: block of HTML representing form
###############
sub generate {
###############
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'name' );

    $args{-Form} = $self;

    return $self->View->generate(%args);
}

#
# Simple end of form tag with formatting to match generated form start tag
#
# Return: end_form with html comment tag
###############
sub end_form {
###############
    my $self = shift;
    return $self->View->end_form();
}

##########################
# Wrapper that should be used to initiate all Forms
#
# <snip>
# eg.
#    ... $dbc->set_form_options();  ## prior to calling, various options may be defined for standard forms
#
#    my $form =  new LampLite::Form('NewRecord', -dbc=>$dbc);
#    ...
#    print $form->generate();

#</snip>
#
# Return: HTML String.  eg("<Form>...<input type='hidden' name='param1' value='value1'>... ")
##########################
sub start_Form {
##########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,name,url,parameters' );
    my $name = $args{-form} || $args{-name} || 'thisform';    ## name of form - optional (passed onto start_custom_form)
    my $dbc  = $args{-dbc} || $self->dbc();
    my $method = $args{-method} || 'POST';


    my $url        = $args{-url};                             ## optionally override default url
    my $parameters = $args{-parameters};                      ## optional parameters to include in addition to default persistent parameters
    my $debug      = $args{-debug};
    my $clear      = $args{-clear};                           ## input fields in url that will NOT be set as hidden input variables in the form

    if (!$parameters->{Method}) { $parameters->{Method} = $method }

    my $form = new LampLite::Form( -dbc => $dbc );
    return $form->generate( -open => 1, %args );              ## just start the form with the standard persistent parameters
}

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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
