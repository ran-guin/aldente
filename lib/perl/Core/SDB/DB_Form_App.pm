##################
# DB_Form_App.pm #
##################
#
# This module is used to monitor DB_Forms for Library and Project objects.
#
package SDB::DB_Form_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

#use CGI qw(:standard);
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use SDB::DBIO;
use SDB::HTML;
use SDB::DB_Form_Views;
use SDB::DB_Form;

use RGTools::RGIO;
##############################
# global_vars                #
##############################
use vars qw(%Configs);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'New Record'       => 'new_Record',
            'Regenerate Query' => 'regenerate_Query',
            'View Lookup'      => 'view_Lookup',
            'Save Field Info'  => 'save_Info',
            'Update Fields'    => 'set_Fields',
            'Set Field Info'   => 'set_field_info',
        }
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##########################
sub save_Info {
##########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->{dbc} || $self->param('dbc');

    my $id_list       = $q->param('IDs');
    my $field_id_list = $q->param('DBField_IDs');
    my $table         = $q->param('table');

    my $qid_list = Cast_List( -list => $id_list, -to => 'string', -autoquote => 1 );

    my @ids       = split ',', $qid_list;
    my @field_ids = split ',', $field_id_list;
    my %values;
    my $updated = 0;

    for my $field_id (@field_ids) {
        my @field_values = $self->get_cell_data( -name => "DBFIELD$field_id", -object_ids => \@ids );
        if ( scalar(@field_values) > 0 ) {
            my ($field_name) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE DBField_ID =$field_id" );
            @{ $values{$field_name} } = @field_values;
        }
    }

    my @fields          = $dbc->Table_find( 'DBField',  'Field_Name', "WHERE DBField_ID IN ($field_id_list)" );
    my ($primary_field) = $dbc->get_field_info( $table, undef,        'Primary' );
    my %preset          = $dbc->Table_retrieve( $table, \@fields,     "WHERE $primary_field IN ($qid_list)" );

    for my $field ( keys %values ) {
        my @new     = @{ $values{$field} } if $values{$field};
        my @current = @{ $preset{$field} } if $preset{$field};
        my $size    = @new;
        for my $index ( 0 .. $size - 1 ) {

            if ( $new[$index] eq "''" ) {
                $new[$index] = '';
            }
            elsif ( $field =~ /^FK(\w*?)_(\w+)__(\w+)$/ ) {
                $new[$index] = $dbc->get_FK_ID( -field => $field, -value => $new[$index] );
            }

            my $current_id = $ids[$index];
            if ( $new[$index] ne $current[$index] ) {
                if ( $current_id =~ /[a-z|A-Z]/ && $current_id !~ /\'.+\'/ && $current_id !~ /\".+\"/ ) { $current_id = "'$current_id'" }
                $updated += $dbc->Table_update_array( "$table", [$field], [ $new[$index] ], " WHERE $primary_field= $current_id", -autoquote => 1 );
            }
        }

    }

    if ( $updated || 1 ) {
        ## provide feedback even if no records updated ##
        $dbc->message("Updated $updated $table records");
    }

    $dbc->{session}->homepage("$table=$id_list");

    return;
}

##########################
sub set_Fields {
########################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $field_ids = join ',', $q->param('Field_ID');
    my $class     = $q->param('Class');
    my $ids       = $q->param('ID');

    if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }

    my $page;
    if ($field_ids) {
        $page = SDB::DB_Form_Views::set_Field_form( -title => "Define $class Attributes", -dbc => $dbc, -class => $class, -id => $ids, -fields => $field_ids );
    }
    else {
        $page = SDB::DB_Form_Views::choose_Fields( -dbc => $dbc, -id => $ids, -class => $class );
    }
    return $page;
}

#
# run mode to handle form generation for adding a new Record to any table
#
# (gradually increasing functionality to replace previous code flow)
#
#
# Return: form
###################
sub new_Record {
###################
    my $self = shift;

    my $q = $self->query();

    my $table     = $q->param('Table');
    my $target    = $q->param('Target') || 'Database';
    my $navigator = $q->param('Auto') || '0';           ## use form navigator
    my $finish    = $q->param('Finish');                ## (when Auto = 0) .. force submit button to generate Finish button (rather than trying to Continue to next form) - ONLY SET if this record can be added independently.  (ignores DB_Form dependencies)

    my $dbc = $self->param('dbc');
    if ( !$table ) { return $dbc->err('No Table specified for new record') }

    my %Parameters = %{ $self->_parse_Parameters() };

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target, -db_action => 'append', -wrap => 0 );

    my $Grey   = $Parameters{Grey};
    my $Preset = $Parameters{Preset};
    my $Hidden = $Parameters{Hidden};
    my $Require;

    $form->configure( -preset => $Preset, -require => $Require, -grey => $Grey, -omit => $Hidden );

    #    $form->configure(%$configs_ref) if $configs_ref;

    my $mode;
    if ($finish) { $mode = 'Finish' }    ## force form to generate finish button

    my $output;
    $output .= $form->generate( -title => "New $table Form ", -submit => 1, -mode => $mode, -end_form => 0, -start_form => 1, -form => 'Append', -return_html => 1, -navigator_on => $navigator );
    ### if starting form we need to supply form name

    $output .= $q->end_form();

    return $output;
}

##########################
sub _parse_Parameters {
##########################
    my $self = shift;

    my $q = $self->query;

    my %Param;
    my @types = qw(Grey Hidden Preset Require);
    foreach my $type (@types) {
        my $param = join ',', $q->param($type);
        my @fields = split ',', $param;
        foreach my $field (@fields) {
            ## may need to adapt in case of multiple values ??
            $Param{$type}{$field} = $q->param($field) || '';
        }
    }
    return \%Param;
}

################################################################################################################
# Method to enable regeneration of previous 'Table_retrieve_display views with adjusted filtering or grouping
#
# ie (allows for easy breaking out of records originally grouped by a given field)
#
# This is currently used automatically when the group and regroup paramters are applied to Table_retrieve_display.
#
# eg Table_retrieve_display(...., -group=>'Month', -regroup=>'Plate_ID')
#  This will generate the original table with grouping of records by month.
#  A breakout button will also appear on each line enabling the user to go directly to a subset of the records now grouping by Plate_ID
#
# Used in conjunction with regenerate_query_link method in DB_Form_Views;
#
# Return Regenerated Table
##########################
sub regenerate_Query {
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $separator = $q->param('separator');

    my @hashes  = $q->param('Hashes');
    my @arrays  = $q->param('Arrays');
    my $regroup = $q->param('Regroup');

    my %args;
    foreach my $param ( $q->param() ) {
        my $value = $q->param($param);

        #	Message("Got $param = $value");
        if ( $param =~ /^-/ ) {
            if ( grep /^$param$/, @hashes ) {

                #		Message("Set $param to hash");
                my @pairs = split $separator, $value;
                my %hash;
                foreach my $pair (@pairs) {
                    my ( $key, $val ) = split '=>', $pair;
                    $hash{$key} = $val;
                }
                if ( $param eq '-fields' ) {
                    ## special case for converting fields back to array (not sure why it comes out as a hash. ?)
                    my @fields;
                    foreach my $key ( keys %hash ) {
                        push @fields, "$hash{$key} AS $key";
                    }
                    $args{$param} = \@fields;
                }
                else {
                    $args{$param} = \%hash;
                }
            }
            elsif ( grep /^$param$/, @arrays ) {

                #		Message("Set $param to array");
                my @array = split $separator, $value;
                $args{$param} = \@array;
            }
            else {
                $args{$param} = $value;
            }
        }
    }
    if ($regroup) {
        $args{-group}   = $regroup;
        $args{-regroup} = '';
        unshift @{ $args{-fields} }, $regroup;
    }

    print create_tree( -tree => { 'Query Details' => HTML_Dump \%args } );
    return $dbc->Table_retrieve_display(%args);
}

#########################################################################
# Simple accessor to generate list of records in existing lookup tables
#
# (this is useful if adding another entry to ensure consistency)

#
#########################################################################
sub view_Lookup {
#########################################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $table = $q->param('Table');
    my $condition = $q->param('Lookup Condition') || 1;

    my $title = "$table Records";
    if ( $condition ne '1' ) { $title .= " (WHERE $condition)" }

    my $list = $dbc->Table_retrieve_display( $table, ['*'], "WHERE $condition", -return_html => 1, -title => $title );

    return $list;
}

##########################
sub set_field_info {
##########################
    my $self      = shift;
    my $dbc       = $self->param('dbc');
    my $q         = $self->query();
    my $class     = $q->param('Class');
    my @marked    = $q->param('Mark');
    my $defaults  = $q->param('Defaults');
    my $mandatory = $q->param('Mandatory');
    my $ids       = join ',', @marked;

    if ( $q->param('Set Field Info') ) {
        if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }
        my $page = SDB::DB_Form_Views::choose_Fields( -dbc => $dbc, -title => 'Set Attributes', -id => $ids, -class => $class );
        return $page;
    }
    return;
}

return 1;
