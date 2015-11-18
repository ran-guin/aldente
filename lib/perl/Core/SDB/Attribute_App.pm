###################################################################################################################################
# SDB::Attribute_App.pm
#
# Controller in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Attribute_App;

use base LampLite::Attribute_App;
use strict;

# Local modules required ##

use RGTools::RGIO;

use LampLite::CGI;

use SDB::DBIO;
use SDB::HTML;

## global_vars ##

my $q = new LampLite::CGI;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                => 'default',
            'Set Attributes'         => 'set_Attributes',
            'Save Attributes'        => 'save_Attributes',
            'Add Attribute'          => 'add_Attribute',
            'Define Attribute'       => 'define_Attribute',
            'Delete Attribute'       => 'delete_Attribute',
            'Delete Attributes'      => 'delete_Attribute',
            'Display Attribute Link' => 'display_attribute_link',
        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    my $id = $q->param("Attribute_ID");    ### Load Object by default if standard _ID field supplied.

    #    my $Attribute = new SDB::Attribute( -dbc => $dbc, -id => $id );
    #    my $Attribute_View = new SDB::Attribute_Views( -model => { 'Attribute' => $Attribute } );
    #
    #    $self->param( 'Attribute'      => $Attribute );
    #    $self->param( 'Attribute_View' => $Attribute_View );
    $self->param( 'dbc' => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = 1; ## ;
    return $self;
}

###############
sub default {
###############

    return 'Attribute Home Page - Under Construction ...';
}

sub display_attribute_link {
    my $self    = shift;
    my @id_list = $q->param("Mark");
    my $object  = $q->param("TableName");
    my $link    = SDB::Attribute_Views::show_attribute_link( -object => $object, -id => \@id_list, -dbc => $self->param('dbc'), -display => 1 );
    return $link;
}

#
#
#
#
#
# Return: number of attributes updated
########################
sub save_Attributes {
########################
    my $self = shift;

    my $id_list        = $q->param('IDs');
    my $att_list       = $q->param('ATTs');
    my $reset_homepage = $q->param('Reset Homepage');

    my $class = $q->param('Attr_Class') || 'Plate';
    my $dbc = $self->param('dbc');

    my @ids      = split ',', $id_list;
    my @attr_ids = split ',', $att_list;

    my $saved   = 0;
    my $updated = 0;
    my %values;

    foreach my $attr (@attr_ids) {
        my @att_values = $self->get_cell_data( -name => "ATT$attr", -object_ids => \@ids );
        if ( scalar(@att_values) > 0 ) {
            @{ $values{$attr} } = @att_values;
        }
    }

    ## format check
    my @attr_id_list;
    my @attr_value_list;
    my $i = 0;
    foreach my $id (@ids) {
        foreach my $attr (@attr_ids) {
            my $value = $values{$attr}->[$i];
            if ( $value eq "''" && ( $i > 0 ) ) {
                $value = $values{$attr}->[ $i - 1 ];    ## use value of previous record ##
                $values{$attr}->[$i] = $value;          ## update the value in hash
            }
            push @attr_id_list,    $attr;
            push @attr_value_list, $value;
        }
        $i++;
    }
    my ( $pass, $messages ) = SDB::Attribute::check_attribute_format( -dbc => $dbc, -ids => \@attr_id_list, -values => \@attr_value_list );

    ## update database

    foreach my $attr (@attr_ids) {
        my %list;
        $i = 0;
        foreach my $id (@ids) {
            $list{$id} = $values{$attr}->[$i];
            $i++;
        }
        $updated += SDB::Attribute::set_attribute( -dbc => $dbc, -object => $class, -attribute_id => $attr, -list => \%list, -on_duplicate => 'REPLACE' );
    }

    Message("Updated $updated records");

    if ( defined $reset_homepage ) {
        $dbc->session->reset_homepage($reset_homepage);
    }
    else {
        $dbc->session->reset_homepage("$class=$id_list");
    }

    return;
}

#
#
# <snip>
#    print set_Attributes(-attributes=>['Height','Weight'], -class=>'Patient', -defaults => {'Height'=>'short'}, -ids=>[1..10]);
#
#
#
# Return: view to prompt user to set multiple attributes for multiple records
##########################
sub set_Attributes {
########################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $attributes    = join ',', $q->param('Attribute');
    my $attribute_ids = join ',', $q->param('Attribute_ID');
    my $class     = $q->param('Class');
    my $defaults  = $q->param('Defaults');
    my $ids       = $q->param('ID');
    my $mandatory = $q->param('Mandatory');

    if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }

    my $page;
    if ( $attributes || $attribute_ids ) {
        $page = &SDB::Attribute_Views::set_multiple_Attribute_form( -title => "Define $class Attributes", -dbc => $dbc, -class => $class, -id => $ids, -attribute_ids => $attribute_ids, -attributes => $attributes, -mandatory => $mandatory );
    }
    else {
        $page = SDB::Attribute_Views::choose_Attributes( -dbc => $dbc, -title => 'Set Attributes', -id => $ids, -class => $class, -mandatory => $mandatory, -defaults => $defaults );
    }
    return $page;
}

##########################
sub delete_Attribute {
########################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $attributes    = join ',', $q->param('Attribute');
    my $attribute_ids = join ',', $q->param('Attribute_ID');
    my $class     = $q->param('Class');
    my $defaults  = $q->param('Defaults');
    my $ids       = $q->param('ID');
    my $mandatory = $q->param('Mandatory');
    my $confirmed = $q->param('Confirmed');
    my $marked    = join ',', $q->param('Mark');
    unless ($ids) { $ids = $marked }

    if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }

    my $page;
    if ($confirmed) {
        my $ok = $dbc->delete_records(
            -table   => $class,
            -id_list => $ids,
            -confirm => 1
        );
        return;
    }
    elsif ( $attributes || $attribute_ids ) {
        $page = SDB::Attribute_Views::display_Delete_Attributes( -dbc => $dbc, -title => 'Delete Attributes', -ids => $ids, -class => $class, -attributes => $attribute_ids );
    }
    else {
        $page = SDB::Attribute_Views::choose_Attributes( -dbc => $dbc, -title => 'Delete Attributes', -id => $ids, -class => $class, -mandatory => $mandatory, -defaults => $defaults, -rm => 'Delete Attribute' );
    }
    return $page;
}

#######################
sub add_Attribute {
#######################

    my $now   = &date_time();
    my $class = $q->param('Class');

    my $group_list = $dbc->get_local('group_list');

    my %grey;
    my %hidden;

    my $id = $q->param('ID');

    $grey{ 'FK_' . $class . '__ID' } = $id;
    $hidden{'FK_Employee__ID'}       = $dbc->get_local('user_id');
    $hidden{'Set_DateTime'}          = $now;

    require SDB::DB_Form;

    my %list;
    my @attributes = &get_FK_info( $dbc, 'FK_Attribute__ID', -condition => "WHERE FK_Grp__ID in ($group_list) AND Attribute_Class = '$class'", -list => 1 );
    $list{'FK_Attribute__ID'} = \@attributes;

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $class . '_Attribute', -target => 'Database', -mode => 'Normal' );
    $form->configure( -grey => \%grey, -omit => \%hidden, -list => \%list );
    return $form->generate( -title => "Add $class attribute", -return_html => 1 );

}

##########################
sub define_Attribute {
##########################

    my $class      = $q->param('Class');
    my $group_list = $dbc->get_local('group_list');
    my @groups     = $dbc->get_FK_info( 'FK_Grp__ID', -condition => "WHERE Grp_ID in ($group_list)", -list => 1 );
    require SDB::DB_Form;

    my %grey;
    my %hidden;
    my %preset;
    my %list;
    my $form;

    $preset{Attribute_Type}   = 'Text';
    $hidden{Attribute_Format} = '';
    $grey{Attribute_Class}    = $class;
    $list{'FK_Grp__ID'}       = \@groups;
    $list{'Attribute_Type'} = [ 'Text', 'Int', 'Decimal' ];

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Attribute', -target => 'Database', -mode => 'Normal' );
    $form->configure( -grey => \%grey, -omit => \%hidden, -preset => \%preset, -list => \%list );
    my $page = $form->generate( -title => "Define a new $class attribute", -return_html => 1 );
    $page .= SDB::Attribute_Views::display_attribute_help( -dbc => $dbc, -class => $class );

    return $page;

}

1;


