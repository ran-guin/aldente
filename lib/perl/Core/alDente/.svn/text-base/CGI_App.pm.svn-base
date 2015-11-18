package alDente::CGI_App;

##################################################################################################################################
# This is the standard package to include with alDente modules that wish to use MVC design protocol from CGI_Application package #
# (Recommended for ongoing module development and refactoring)
#
#####################################

use base 'RGTools::Base_App';

use alDente::Form;
use alDente::SDB_Defaults;

use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;

use RGTools::RGIO;

use vars qw(%Configs);

##################
sub go_button {
##################
    return "/$Configs{'URL_dir_name'}/images/icons/arrow_fwd_blue.gif";
}

#
# Simple accessor to extract class from table name
#  
# This simply centralizes logic to account for exceptions where table names do not match class names
#
#
# Return: class
############
sub class {
############
    my $self = shift;
    
    my $table = shift;
    
    my $Map = {
        'Plate' => 'Container'        
    };
    
    my $class = $table;
    if ($Map->{$table}) { $class = $Map->{$table}}
    
    if ($class !~/::/) { $class = 'alDente::' . $class } 
    
    return $class;
}

######################################
sub validate_session_attribute {
######################################
    my $self = shift;
    my $attribute = shift;

    my $dbc = $self->param('dbc');

    return $self->prompt_for_session_info($attribute);
}

#
# Usage:
#
#   To be used within _App methods only.
#
#   Note: to retrieve information dynamically, include in the setup method of the same _App the line:
#  
#    $self->update_session_info();   ## needed to dynamically recover session attributes if not supplied (eg printer_group)
#
#
# <snip> 
#
#    
#   my $printer_group = $dbc->session->{printer_group_id} || return $self->prompt_for_session_info('printer_group_id');
#
# </snip>
#
# Return:  html form to enable user to specify missing information ...(or nothing if already defined)
#################################
sub prompt_for_session_info {
#################################
    my $self = shift;
    my $attribute = shift;
    my $dbc = $self->param('dbc');

    my $page;

    my $q = new CGI;

    my ($field, $element_name) = _session_attributes($attribute);

    if (defined $dbc->session) {
        if (defined $dbc->session->{$attribute}) {
            # $dbc->session->message("Found $attribute: " . $dbc->session->{$attribute})
        }
        elsif (defined $dbc->session->param($attribute)) {
            # $dbc->session->message("Found $attribute: " . $dbc->session->{$attribute});
        }
        elsif ( defined $dbc->session->user_setting($attribute) ) {
            # $dbc->session->message("Found $attribute: " . $dbc->session->user_setting($attribute);
        }
        else {
            $dbc->session->message("$attribute not yet defined...please update below");
            $page .= '<P>'; 
            $page .= alDente::Form::start_alDente_form($dbc, 'reload');

            $page .= $q->hidden(-name => 'Update Session Info', -value => $attribute);	    
            $page .= SDB::HTML::query_form($dbc,[$field], -submit=>0, 
                -element_names=>{ $element_name => 'Update Session Values'});

            foreach my $p ( $q->param() ) {
                my @values = $q->param($p);
                foreach my $value (@values) {
                    # $value =~ s/\+/ /g;
                    $page .= $q->hidden( -name => $p, -value => $value, -force => 1 );
                }
            }
            $page .= $q->submit(-name=>"Update $attribute", -class => 'Action');
            $page .= $q->end_form();
        }
    }
    else {
	    Message("Warning: Session class not defined...");
	    Call_Stack();
    }

    return $page;
}

#
# This  method can be called from any _App setup method to dynamically update Session attributes previously queried for
#
# Notes:
# 
#  * include the line 'use base alDente::CGI_App;' in the _App in question 
#  * the setup method should include the call update_session_info
#  * insert the call 'prompt_for_session_info' wherever you are retrieving a session parameter that is required for a given action 
#
#
#############################
sub update_session_info { 
#############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q = $self->query();

    if ($q->param('Update Session Info')) {
        ## only update session information if supplied ##
        my @attributes = $q->param('Update Session Info');
        my @values     = $q->param('Update Session Values');

        for my $i (0 .. $#attributes) {
            my $attr = $attributes[$i];
            my $value = $values[$i];
            if (!defined $value) { next }   ## skip if value not defined... ##

            my ($ref_field, $element) =  _session_attributes($attr);
            #	    my $value = $q->param($element);
            if (foreign_key_check($ref_field, -dbc=>$dbc) ) {
                my $value_id = $dbc->get_FK_ID($ref_field,$value);
                $dbc->session->set($attr => $value_id);
                $dbc->session->param($attr, $value_id);    ## new standard for saving session parameters ( or $session->user_setting($attr) )
                if ($attr =~ /(.+)_id$/i) { 
                    ## if fk_id is set, also set name attribute ##
                    my $class = $1;
                    $dbc->session->set("${class}_name" => $value);
                    $dbc->session->param("${class}_name", $value);    ## new standard for saving session parameters ( or $session->user_setting($attr) )
                    Message("Set ${name}_name -> '$value'");
                }
            }
            else {
                $dbc->session->set($attr => $value);
                $dbc->session->param($attr, $value);    ## new standard for saving session parameters ( or $session->user_setting($attr) )
                Message("Set $attr -> $value");
            }

            ## secondary attributes inherited from primary attributes ##

            if ($attr eq 'printer_group_id') {
                my $printer_group_id =  $dbc->session->{printer_group_id} || $dbc->session->param('printer_group_id') || $dbc->session->user_setting('printer_group_id');
                ## set local site attribute if printer group defined ##
                if ($printer_group) { 
                    require LampLite::Barcode;                    
                    my $User = new alDente::Employee( -id => $dbc->get_local('user_id'), -dbc => $dbc );   ## should probably be part of $dbc, but pass in for now to reduce potential legacy problems
                    LampLite::Barcode->reset_Printer_Group($dbc, -id =>$printer_group_id, -User=>$User);
                }
            }

            Message("Continuing...");
            print "<P>";
        }
    }
    return;
}

############################
sub _session_attributes {
############################
    my $attribute = shift;

    my $session_attributes = {
        'site_id' => 'Location.FK_Site__ID',
        'site_name' => 'Location.FK_Site__ID',
        'printer_group_id' => 'Printer_Assignment.FK_Printer_Group__ID',
    };

    if (defined $session_attributes->{$attribute}) {
        my $field = $session_attributes->{$attribute};
        my $element_name = $field;
        $element_name =~s/^.+\.//;  ## clear table specifier from field name to define element name ##

        return  ($field, $element_name);
    }

    return;
}

return 1;
