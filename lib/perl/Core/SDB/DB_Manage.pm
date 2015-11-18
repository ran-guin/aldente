###################################################################################################################################
# SDB::DB_Manage.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::DB_Manage;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules

use vars qw( $Connection $homelink %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self = {};

    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

####################
# public functions #
####################

#<snip>
#e.g. my @new_enum_values = add_enum_values(-table=>$table,-field=>$field,-new_values=>\@enum_values);
#</snip>
#####################
sub add_enum_values {
#####################
    my %args   = filter_input( \@_, -args => 'dbc,table,field,values', -mandatory => 'dbc,table,field,values' );
    my $dbc    = $args{-dbc};
    my $table  = $args{-table};
    my $field  = $args{-field};
    my $values = $args{ -values };

    if ( !$values ) {
        Call_Stack();
        Message "Error: No values passed to add_enum_values";
        return;
    }
    my @new_enum_values = @$values;
    my $new_values_list;
    my $first_value = 1;
    foreach my $value (@new_enum_values) {
        if ( !$first_value ) {
            $new_values_list .= ',';
        }
        else {
            $first_value = 0;
        }
        my $quoted_value = "'$value'";
        $new_values_list .= $quoted_value;
    }
    my @old_enum_values = $dbc->get_enum_list( "$table", "$field" );
    my $old_enum_values_list;
    $first_value = 1;
    foreach my $value (@old_enum_values) {
        if ( !$first_value ) {
            $old_enum_values_list .= ',';
        }
        else {
            $first_value = 0;
        }
        my $quoted_value = "'$value'";
        $old_enum_values_list .= "$quoted_value";
    }
    my $all_enum_list;
    if ( $new_values_list && $old_enum_values_list ) {
        $all_enum_list = "$old_enum_values_list,$new_values_list";
    }
    elsif ( $new_values_list && !$old_enum_values_list ) {
        $all_enum_list = "$new_values_list";
    }
    elsif ( $old_enum_values_list && !$new_values_list ) {
        $all_enum_list = "$old_enum_values_list";
    }
    my $new_field_type = "enum($all_enum_list)";
    my %field_info = get_field_info( -dbc => $dbc, -table => $table, -field => $field );
    $field_info{Type} = $new_field_type;
    my $new_field_definition = generate_field_definition( -field_hash => \%field_info );
    my $query                = "ALTER TABLE $table MODIFY $field $new_field_definition";
    my $sth                  = $dbc->dbh()->prepare($query);
    $sth->execute();

    if ( defined $sth->err() ) {
        Message "Error from SQL statement: $query";
        Message "Could not alter table: $table";
        return @old_enum_values;
    }
    my @all_enum_values = ( @old_enum_values, @new_enum_values );

    return @all_enum_values;
}

#<snip>
#e.g. my %field_info = get_field_info_hash($dbc,$table,$field)
#</snip>
#########################
sub get_field_info_hash {
#########################
    my %args  = filter_input( \@_, -args => 'dbc,table,field', -mandatory => 'dbc,table,field' );
    my $dbc   = $args{-dbc};
    my $field = $args{-field};
    my $table = $args{-table};

    my %field_info_hash;
    my $query = "DESC $table";
    my $sth   = $dbc->dbh()->prepare($query);
    $sth->execute();
    while ( my @row = $sth->fetchrow_array() ) {
        if ( $row[0] =~ /^$field$/ ) {
            $field_info_hash{Field}   = "$row[0]";
            $field_info_hash{Type}    = "$row[1]";
            $field_info_hash{Null}    = "$row[2]";
            $field_info_hash{Key}     = "$row[3]";
            $field_info_hash{Default} = "$row[4]";
            $field_info_hash{Extra}   = "$row[5]";
        }
    }

    return %field_info_hash;

}

#<snip>
#e.g. my $table_definition = generate_field_definition(-field_hash=>\%field_info);
#</snip>
###############################
sub generate_field_definition {
###############################
    my %args = filter_input( \@_, -args => 'field_hash', -mandatory => 'field_hash' );
    my $field_hash = $args{-field_hash};

    my $field_definition;

    my $field_name = $field_hash->{Field};
    my $field_type = $field_hash->{Type};
    $field_definition = "$field_name $field_type ";
    if ( $field_hash->{Null} !~ /yes/i ) {
        $field_definition .= "NOT NULL ";
    }
    if ( $field_hash->{Key} =~ /(pri|uni|mul)/i ) {
        $field_definition .= "key ";
    }
    $field_definition .= "DEFAULT '$field_hash->{Default}' " unless ( $field_hash->{Default} =~ /^\s*$/ );
    $field_definition .= "$field_hash->{Extra} ";

    return $field_definition;

}

1;
