######################
#
# Package to handle Fail related functionalities
#
######################
package alDente::Fail;
######################

#Packages from Perl
use strict;
use Data::Dumper;

#Packages from SDB
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::HTML;

#Packages from RGTools
use RGTools::RGIO;

#Packages from alDente
use alDente::Grp;

use vars qw($testing $Connection);

#############################
#
# A method to fail a set of objects
#
#############################
sub Fail {
    my %args = &filter_input( \@_, -args => 'object,object_type,ids,reason,comments,ignore_set_status' );
    my $dbc               = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $object            = $args{-object};
    my $object_type       = $args{-object_type};
    my @ids               = Cast_List( -list => $args{-ids}, -to => 'array' );
    my $fail_status_field = $args{-fail_status_field};
    my $fail_status_value = $args{-fail_status_value};
    my $reason            = $args{-reason};
    my $comments          = $args{-comments};
    my $ignore_set_status = $args{-ignore_set_status};                                                       # flag to skip updating status field. This is needed in cases like failing a Gel_Lane since Gel_Lane table doesn't have a status field.
    my $quiet             = $args{-quiet};

    my $condition = "WHERE Object_Class='$object'";

    if ($object_type) {
        $condition .= " AND Object_Type='$object_type'";
    }
    else {
        $condition .= " AND (Object_Type IS NULL OR Object_Type='')";
    }

    my $time = &date_time();

    ### Error checking to see if they provided a correct class and type
    my @found_class_id = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', $condition );

    if ( scalar(@found_class_id) != 1 ) {
        Message("Error: Invalid Object Type ($object) and Object Type Class ($object_type)");
        return 0;
    }

    ### Error checking to see if $reason is actually a reason for failling $found_class_id[0] for the current group?
    $condition = '';
    if ( $reason =~ /^\d+$/ ) {
        $condition = "FailReason_ID=$reason";
    }
    else {
        $condition = "FailReason_Name = '$reason'";
    }
    my $groups = $dbc->get_local('group_list');

    ($reason) = $dbc->Table_find( 'FailReason', 'FailReason_ID', "WHERE FK_Object_Class__ID=$found_class_id[0] AND $condition AND FK_Grp__ID IN ($groups)" );

    unless ($reason) {
        Message("Error: Invalid reason '$args{-reason}'");
        return 0;
    }
    my $ids = Cast_List( -list => \@ids, -to => 'String' );
    my @failed_with_same_reason = $dbc->Table_find( 'Fail', 'Object_ID', "WHERE FK_FailReason__ID = $reason and Object_ID IN ($ids)" );
    if (@failed_with_same_reason) {
        my $failed_with_same_reason = Cast_List( -list => \@failed_with_same_reason, -to => 'String' );

        return err ("Objects already failed with the same reason: ($failed_with_same_reason)");
    }
    my $O_ID       = $object . '_ID';
    my $O_COMMENTS = $object . '_Comments';
    my $O_STATUS   = $fail_status_field ? $fail_status_field : $object . '_Status';

    my %inserts;
    my $index       = 0;
    my @fail_fields = qw(Object_ID FK_FailReason__ID DateTime FK_Object_Class__ID);

    my $user_id = $dbc->get_local('user_id');
    if ($user_id) {
        push( @fail_fields, 'FK_Employee__ID' );
    }

    if ($comments) {
        push( @fail_fields, 'Comments' );
    }
    foreach my $id (@ids) {
        my @values = ( $id, $reason, $time, $found_class_id[0] );
        if ($user_id) {
            push( @values, $user_id );
        }
        if ($comments) {
            push( @values, $comments );
        }
        $inserts{ ++$index } = \@values;
    }
    my $newids = $dbc->smart_append( -tables => 'Fail', -fields => \@fail_fields, -values => \%inserts, -autoquote => 1 );
    if ( $newids->{Fail}->{newids} ) {
        my $count = scalar( @{ $newids->{Fail}->{newids} } );
        if ( $count == scalar(@ids) ) {
            Message("Failed $count $object(s)") unless $quiet;

            if ( !$ignore_set_status ) {
                my $object_ids = join( ',', @ids );
                my @fields = ($O_STATUS);
                my @values;
                if   ($fail_status_value) { push @values, $dbc->dbh()->quote($fail_status_value) }
                else                      { push @values, $dbc->dbh()->quote('Failed') }

                ### Check to see if this object has a comments field
                my $dbfield_id = $dbc->Table_find( 'DBField,DBTable', 'DBField_ID', "WHERE DBTable_ID=FK_DBTable__ID AND DBTable_Name='$object' AND Field_Name='$O_COMMENTS'" );

                if ($dbfield_id) {
                    my ($failreason_name) = $dbc->Table_find( 'FailReason', 'FailReason_Name', "WHERE FailReason_ID=$reason" );
                    my $notes = " FailReason: $failreason_name;";
                    $notes .= "($comments)" if $comments;

                    ### quote it
                    $notes = $dbc->dbh()->quote($notes);
                    push( @fields, $O_COMMENTS );
                    push( @values, "CONCAT($O_COMMENTS,$notes)" );
                }
                $dbc->Table_update_array( $object, \@fields, \@values, "WHERE $O_ID IN ($object_ids)" );
            }
            return $newids->{Fail}->{newids};
        }
        else {
            Message("Error: Not all $object(s) were failed") unless $quiet;
            return 0;
        }
    }
}
#############################
#
# A method to retrieve fail reasons based on a given object or group
#
# If a reason_name is specified, only the failreason id is returned.
#
#############################
sub get_reasons {
#################
    my %args = &filter_input( \@_, -args => 'object', -mandatory => 'object' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $object      = $args{-object};
    my $object_type = $args{-object_type};
    my $grps        = $args{-grps};
    my $reason_name = $args{-reason_name};
    my $department  = $args{-department};
    my $condition   = "WHERE 1";

    if ($grps) {
        my $groups = Cast_List( -list => $grps, -to => 'string' );
        $condition .= " AND FK_Grp__ID IN ($groups)";
    }
    elsif ($department) {
        my $groups = alDente::Grp::get_dept_groups( -dept->$department );
        $condition .= " AND FK_Grp__ID IN ($groups)";
    }

    if ($reason_name) {
        $condition .= " AND FailReason_Name = '$reason_name'";
    }

    my $object_class_condition = "Object_Class='$object'";
    if ($object_type) {
        $object_class_condition .= " AND Object_Type='$object_type'";
    }
    my ($class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE $object_class_condition" );
    if ($class_id) {
        $condition .= " AND FK_Object_Class__ID=$class_id";
    }
    else {
        Message("Warning: Invalid Object_Class:Object_Type '$object:$object_type'");
        return {};
    }

    if ($reason_name) {

        my ($reason_id) = $dbc->Table_find( 'FailReason', 'FailReason_ID', $condition );
        unless ($reason_id) {
            Message("Error: Invalid Fail Reason");
        }
        return $reason_id;

    }
    else {

        my %reasons;
        my @reasons = $dbc->Table_find( 'FailReason', 'FailReason_ID,FailReason_Name', $condition );
        unless (@reasons) {
            return {};
        }

        map {
            my ( $id, $name ) = split( ',', $_ );
            $reasons{$id} = $name;
        } @reasons;

        return \%reasons;
    }
}

return 1;

