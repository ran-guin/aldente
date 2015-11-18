package LampLite::DB_App;

use base RGTools::Base_App;
use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::DB_Views.pm - DB View module for LampLite Package

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
use LampLite::DB;
use LampLite::DB_Views;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

##############################
# global_vars                #
##############################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'             => 'home_page',
            'home'                => 'home_page',
            'View Changes'        => 'view_changes',
            'Edit Record'        => 'edit_Record',
            'Search Records'      => 'search_Records',
            'Find Records'        => 'find_Records',
            'Confirm Propogation' => 'confirm_propogation',
            'Add Record'          => 'add_Record',                     ## 
            'Convert Records'     => 'convert_Records',
            'Update Record'         => 'save_Update',
            'Save Record'         => 'save_Record',
            'Save Record(s)'         => 'save_Record',
            'Save and Finish'         => 'save_Record',
            'Save and Add another record'         => 'save_Record',
            'List Records'        => 'list_Records',
            'Save Changes'        => 'save_Update',
            'View Record'         => 'view_Record',
            'Refresh Record'      => 'view_Record',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    $ENV{CGI_APP_RETURN_ONLY} = 1;    ## flag SUPPRESSES automatic printing of return value when true

    return $self;
}

#
# Quick accessor to View module
#
#
###########
sub View {
###########
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'id,class' );
    my $id    = $args{-id};
    my $class = $args{-class} || ref $self;
    my $dbc   = $args{ -dbc } || $self->dbc();

    if   ( $class =~ s/(\b|\_)App$/$1Views/ ) { }
    else                                      { $class .= '_Views' }

    my $ok = eval "require $class";
    $args{ -dbc } = $dbc;

    if ( !$ok && $dbc ) { $dbc->warning("Could not load $class class") }

    my $View = $class->new(%args);
    $View->{dbc} = $dbc;

    return $View;
}

#
# Quick accessor to View module
#
#
###########
sub Model {
###########
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $id    = $args{-id};
    my $class = $args{-class} || ref $self;
 
    my %pass_args  = @_;

    my $dbc = $self->dbc();

    $class =~ s/(\b|_)App$//;
    if ( !$class || $class =~ /::$/ ) { $class .= 'Model' }
    elsif ( $class !~ /::/ ) {
        my $current = ref $self;
        $current =~ s/::(.+)/::$class/;
        $class = $current;
    }

    eval "require $class";

    my $Model = $class->new( -dbc => $dbc, -id => $id, %pass_args );

    $Model->{dbc} = $dbc;
    return $Model;

}

#####################
sub search_Records {
#####################
    my $self = shift;
    my $q = $self->query();
    my $table = $q->param('Table');
    my $dbc = $self->param('dbc');
    
    my $page = "Generate search form for $table...";  
    # $dbc->Table_retrieve_display($table, ['*'], -return_html=>1);
    
    return $page;
    
}

#################
sub new_Record {
#################
    my $self = shift;
    my $q   = $self->query();
    my $table = $q->param('Table') ;
    my $dbc = $self->dbc();
    
    my $xN   = $q->param('xN');
    my $N   = $q->param('N');

    my $page .= $self->View->update_Record(-table=>$table, -action=>'Add', -loop=>$xN);
        
    return $page;
}


###################
sub SL {
###################
    my $self = shift;
    return $self->{SL};
}
 
###################
sub Template {
###################
    my $self = shift;
    return $self->{SL}{Template};
}

####################
sub view_Record {
####################
    my $self = shift;
    my $q = $self->query();
  
    my $table = $q->param('Table') || $q->param('App') ;
    my $id = $q->param('ID');
    my $class = $q->param('Class');
    
    return $self->View->view_Record(-table=>$table, -id=>$id, -class=>$class);
}

####################
sub list_Records {
####################
    my $self = shift;
    my $q = $self->query();
  
    my $table = $q->param('Table') || $q->param('App') ;
    my $id = $q->param('ID');
    my $class = $q->param('Class');

    return $self->View->list_Records(-table=>$table, -id=>$id, -class=>$class);
}

###################
sub add_Record {
###################
    my $self = shift;
    my $q = $self->query();
  
    my $table = $q->param('Table') || $q->param('App') ;;
    my $records = $q->param('Records');
    
    my $dbc      = $self->param('dbc');

    my $V = $self->View;
    
    return $V->add_Record(-table=>$table, -records=>$records);
}

###################
sub edit_Record {
###################

    my $self = shift;
    my $q = $self->query();
  
    my $table = $q->param('Table') || $q->param('App') ;
    my $edit    = $q->param('ID') || $q->param($table .'_ID');                      

    return $self->View->edit_Record(-table=>$table, -edit=>$edit);
}

###################
sub save_Record {
###################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
    my $table = $q->param('Table') ;
    my $rm  = $q->param('rm');
    my $records = $q->param('Records') || 1;
    
    my $add_another = ($rm =~/add another/i);
    
    if (!$table) { return $dbc->error("No table specified") }
    
    my $field_info = $dbc->table_specs($table);
    
    my @fields = @{$field_info->{Field_Name}};

    my $data;
    my @ids;
    
    my $Input;
    foreach my $field (@fields) {
        my @val = $q->param($field);
        $Input->{$field} = \@val;
    }
    
    foreach my $i (1..$records) {        
        foreach my $field (@fields) {
            $data->{$field} = $Input->{$field}[$i-1];
        }
        my $id = $self->Model->save_Record($table, $data);
        push @ids, $id;
    }
    
    if ($add_another) {
        return $self->View->update_Record(-table=>$table, -append=>1);
    }
    
    if (@ids) {
        return $self->View->view_Record(-table=>$table, -id=>\@ids);
    }
    else { 
        Call_Stack();
        $dbc->error("Error adding record(s)");
    }

    return;
}

##################
sub save_Update {
##################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $table = $q->param('Table') ;
    my $id    = $q->param('ID');
    
    my $field_info = $dbc->table_specs($table);
    my @fields = @{$field_info->{Field_Name}};

    my $data;
    foreach my $field (@fields) {
        my $val = $q->param($field);
        $data->{$field} = $val;
    }
    
    $self->Model->save_Update(-table=>$table, -id=>$id, -data=>$data);

    return $self->View->view_Record(-table=>$table, -id=>$id);
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