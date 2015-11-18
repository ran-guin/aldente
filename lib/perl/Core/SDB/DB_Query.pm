##############################################################################################################
# DB_Query.pm
#
# This object encapsulates the login for building dynamic query and reports.
#
##############################################################################################################
# $Id: DB_Query.pm,v 1.7 2004/11/30 01:43:21 rguin Exp $
##############################################################################################################
package SDB::DB_Query;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Query.pm - This object encapsulates the login for building dynamic query and reports.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This object encapsulates the login for building dynamic query and reports.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use MIME::Base32;
use RGTools::RGIO;
use SDB::HTML;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::Object;
use RGTools::HTML_Table;

use strict;
##############################
# global_vars                #
##############################
use vars qw(%Settings);

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

#
# ### Obtaining feedback from the operations
# $dbo->error();       # Returns the latest error
# $dbo->errors();      # Returns the reference to a list of all errors that have occured since the DBIO object was created
# $dbo->warning();     # Returns the latest warning
# $dbo->warnings();    # Returns the reference to a list of all errors that have occured since the DBIO object was created
# $dbo->success();     # Returns whether the last operation was success or fail
#
##################
sub new {
##################
    #
    #Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args    = @_;
    my $encoded = $args{-encoded} || 0;    # Reference to frozen encoded object if there is any. [Object]
    my $dbc     = $args{-dbc};

    unless ($dbc) {
        print "Please provide a dbc/DBIO object.<br>\n";
        return;
    }

    if ($encoded) {                        ## special case if protocol object encoded (frozen)
        my $self = Storable::thaw( MIME::Base32::decode($encoded) );
        $self->{dbc} = $dbc;
        return $self;
    }

    my $self = $this->Object::new(%args);

    $self->{dbc} = $dbc;

    # Attributes
    $self->{tables}         = [];          # List of tables to query from [arrayref]
    $self->{tables_list}    = '';          # List of tables to query from [list]
    $self->{fields_info}    = {};          # Fields available on the criteria screen along with their properties [hashref]
    $self->{fields}         = [];          # List of fields available on the criteria screen [arrayref]
    $self->{special_fields} = [];          # List of special fields available on the criteria screen (e.g. Count(*)) [arrayref]

    return $self;
}

##############################
# public_methods             #
##############################

####################################
# Set the tables to be query from
####################################
sub tables {
    my $self  = shift;
    my $value = shift;

    if ($value) {
        $self->{tables} = Cast_List( -list => $value, -to => 'arrayref' );
        $self->{tables_list} = join( ',', @{ $self->{tables} } );
    }

    return $self->{tables};
}

####################################
# Generates the Criteria form
####################################
sub generate_criteria_form {
#########################
    my $self = shift;
    my %args = @_;

    my $title     = $args{-title}     || $self->{tables_list};    # The title of the form
    my $form_name = $args{-form_name} || 'Criteria_Form';
    my $submit   = $args{-submit_button};
    my $hidden   = $args{-hidden};
    my $defaults = $args{-defaults};                              # Default values.  Valid items are 'Fields','Condition','Group_By'
    my $dbc = $args{-dbc};

    my %submit_button;
    if ($submit) { %submit_button = %$submit }
    else {
        $submit_button{name}  = 'Get_Results';
        $submit_button{value} = 'Get Results';
    }

    # Get the fields to be used on criteria form
    $self->_get_fields();

    require LampLite::Form_Views;
    print LampLite::Form_Views::start_custom_form( $form_name, -dbc=>$dbc);

    my $table = HTML_Table->new();
    $table->Set_Title($title);

    my %labels = map { $_, "$self->{fields_info}{$_}{table}.$self->{fields_info}{$_}{alias}" } @{ $self->{fields} };

    # Fields to select from
    my $onClick
        = qq{if (document.$form_name.Fields.value && document.$form_name.Fields_Selection.value) {document.$form_name.Fields.value = document.$form_name.Fields.value + '\\n' + document.$form_name.Fields_Selection.value;} else if (document.$form_name.Fields_Selection.value) {document.$form_name.Fields.value = document.$form_name.Fields_Selection.value;} document.$form_name.Fields_Selection.selectedIndex = -1;};
    my $special_onClick
        = qq{if (document.$form_name.Fields.value) {document.$form_name.Fields.value = document.$form_name.Fields.value + '\\n' + document.$form_name.Special_Fields_Selection.value;} else {document.$form_name.Fields.value = document.$form_name.Special_Fields_Selection.value;}};
    my $default_value;
    if ( exists $defaults->{Fields} ) { $default_value = $defaults->{Fields} }

    $table->Set_Row(
        [   "<b>Retrieve fields:</b>",
            popup_menu( -name => 'Fields_Selection',         -values => $self->{fields}, -labels => \%labels, -size  => 5, -force   => 1, -onClick => $onClick ),
            popup_menu( -name => 'Special_Fields_Selection', -values => ['Count(*)'],    -size   => 5,        -force => 1, -onClick => $special_onClick ),
            textarea( -name   => 'Fields',                   -rows   => 4,               -cols   => 40,       -force => 1, -value   => $default_value )
        ]
    );

    # Conditions
    my @cmp_operators     = ( '=', '<', '>', '<=', '>=', '!=', 'LIKE', 'NOT LIKE' );
    my $cmp_onClick       = qq{document.$form_name.Condition.value = document.$form_name.Condition.value + ' ' + document.$form_name.Condition_Cmp_Operator.value;};
    my @logical_operators = ( 'AND', 'OR' );
    my $logical_onClick   = qq{document.$form_name.Condition.value = document.$form_name.Condition.value + ' ' + document.$form_name.Condition_Logical_Operator.value;};
    my $value_onChange    = qq{document.$form_name.Condition.value = document.$form_name.Condition.value + ' ' + "'" + document.$form_name.Condition_Value.value + "'";};
    undef($default_value);
    if ( exists $defaults->{Condition} ) { $default_value = $defaults->{Condition} }

    $onClick
        = qq{if (document.$form_name.Condition.value && document.$form_name.Condition_Selection.value) {document.$form_name.Condition.value = document.$form_name.Condition.value + '\\n' + document.$form_name.Condition_Selection.value;} else if (document.$form_name.Condition_Selection.value) {document.$form_name.Condition.value = document.$form_name.Condition_Selection.value;} document.$form_name.Condition_Selection.selectedIndex = -1;};
    $table->Set_Row(
        [   "<b>Condition:</b>" . br . br . popup_menu( -name => 'Condition_Logical_Operator', -values => \@logical_operators, -size => 2, -force => 1, -onClick => $logical_onClick ),
            popup_menu( -name => 'Condition_Selection', -values => $self->{fields}, -labels => \%labels, -size => 5, -force => 1, -onClick => $onClick ),
            popup_menu( -name => 'Condition_Cmp_Operator', -values => \@cmp_operators, -force => 1,  -size  => 4, -onClick => $cmp_onClick ) . br . textfield( -name => 'Condition_Value', -size => 20, -onChange => $value_onChange ),
            textarea( -name   => 'Condition',              -rows   => 4,               -cols  => 40, -force => 1, -value   => $default_value )
        ]
    );

    # Group By
    $onClick
        = qq{if (document.$form_name.Group_By.value && document.$form_name.Group_By_Selection.value) {document.$form_name.Group_By.value = document.$form_name.Group_By.value + '\\n' + document.$form_name.Group_By_Selection.value;} else if (document.$form_name.Group_By_Selection.value) {document.$form_name.Group_By.value = document.$form_name.Group_By_Selection.value;} document.$form_name.Group_By_Selection.selectedIndex = -1;};
    undef($default_value);
    if ( exists $defaults->{Group_By} ) { $default_value = $defaults->{Group_By} }

    $table->Set_Row(
        [   "<b>Group By:</b>",
            popup_menu( -name   => 'Group_By_Selection', -values => $self->{fields}, -labels => \%labels, -size  => 5, -force => 1, -onClick => $onClick ),
            '', textarea( -name => 'Group_By',           -rows   => 4,               -cols   => 40,       -force => 1, -value => $default_value )
        ]
    );

    $table->Set_Row( [ '', reset( -class => "Search" ) . submit( -name => $submit_button{name}, -value => $submit_button{value}, -class => "Search" ), checkbox( -name => 'Show_SQL', -label => 'Show SQL', -force => 1 ) ] );

    $table->Set_VAlignment( 'top', 1 );
    $table->Set_VAlignment( 'top', 2 );
    $table->Printout();

    my $frozen_query = $self->freeze( -encode => 1 );
    print hidden( -name => 'Frozen_Query', -value => $frozen_query );

    foreach my $h ( keys %$hidden ) {
        print hidden( -name => $h, -value => $hidden->{$h}, -force => 1 );
    }

    print "</form>";

}

###################################
# Generates the results
###################################
sub generate_results {
##################
    my $self = shift;
    my %args = @_;

    my $results        = $args{-results}        || '';    # Whether to display the results or not.  Valid formats are 'table','list'
    my $results_header = $args{-results_header} || '';    # Results header

    # Get the parameters
    my $fields    = param('Fields');
    my $condition = param('Condition');
    my $group_by  = param('Group_By');
    my $show_sql  = param('Show_SQL') || 0;

    $fields   =~ s/(?:\r\n|\n)/,/g;
    $group_by =~ s/(?:\r\n|\n)/,/g;

    my $join_condition = $self->{dbc}->get_join_condition( $self->{tables_list} );

    if   ($join_condition) { $condition = "$join_condition AND $condition" }
    if   ($condition)      { $condition = "WHERE 1 AND $condition" }
    else                   { $condition = "WHERE 1 " }
    if ($group_by) { $condition = "$condition GROUP BY $group_by" }

    my @retrieve_fields;
    foreach my $field ( split /,/, $fields ) {
        if   ( grep /^\Q$field\E$/, @{ $self->{special_fields} } ) { push( @retrieve_fields, $field ) }
        else                                                       { push( @retrieve_fields, "$field AS '$field'" ) }
    }

    my $data = $self->{dbc}->Table_retrieve( -table => $self->{tables}, -fields => \@retrieve_fields, -condition => $condition, -format => 'AofH' );
    if ($show_sql) {
        print "SQL: SELECT " . $self->{tables} . " FROM " . join( ',', @retrieve_fields ) . " WHERE $condition<BR>\n";
    }

    # Transform the data
    my %info;
    my $index;
    foreach my $d (@$data) {
        my $keys;
        my %record;
        if ($group_by) {
            foreach my $f ( split( /,/, $group_by ) ) {
                $keys .= '{$d->{\'' . $f . '\'}}';
            }
        }
        else { $keys = '{ALL}' }    # Assign a default group

        foreach my $f ( split( /,/, $fields ) ) {
            $record{$f} = $d->{$f};
        }

        eval( 'push(@{$info' . $keys . '}, \%record)' );

        $index++;
    }

    return \%info;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

#########################################
# Get fields to be used on criteria form
#########################################
sub _get_fields {
################
    my $self = shift;

    # Set database fields
    my $fields = $self->{dbc}->Table_retrieve(
        -table  => 'DBTable,DBField',
        -fields => [ 'DBTable_Name', 'Field_Name', 'Field_Alias', 'Field_Type', 'Field_Options' ],
        -condition => "WHERE DBTable_ID=FK_DBTable__ID AND DBTable_Name IN ('" . join( "','", @{ $self->{tables} } ) . "') ORDER BY Field_Alias",
        -format    => 'AofH'
    );

    foreach my $field (@$fields) {
        my ( $tn, $fn, $fa, $ft, $fo ) = ( $field->{DBTable_Name}, $field->{Field_Name}, $field->{Field_Alias}, $field->{Field_Type}, $field->{Field_Options} );
        unless ( $fo =~ /hidden/i ) {    # Exclude hidden fields
            $self->{fields_info}->{"$tn.$fn"}->{table}   = $tn;
            $self->{fields_info}->{"$tn.$fn"}->{name}    = $fn;
            $self->{fields_info}->{"$tn.$fn"}->{alias}   = $fa;
            $self->{fields_info}->{"$tn.$fn"}->{type}    = $ft;
            $self->{fields_info}->{"$tn.$fn"}->{options} = $fo;
            push( @{ $self->{fields} }, "$tn.$fn" );
        }
    }

    # Set special fields
    push( @{ $self->{special_fields} }, 'Count(*)' );

    return ( $self->{fields}, $self->{special_fields} );
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

2004-11-29

=head1 REVISION <UPLINK>

$Id: DB_Query.pm,v 1.7 2004/11/30 01:43:21 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
