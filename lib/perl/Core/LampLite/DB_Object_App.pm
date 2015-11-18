##############################################################################################
# LampLite::DB_Object_App.pm
#
# Interface generating methods for the DB_Object MVC  (assoc with DB_Object.pm, DB_Object_App.pm)
#
##############################################################################################
package LampLite::DB_Object_App;

use base LampLite::DB_App;

use strict;

use LampLite::DB_Object;
use LampLite::DB_Object_Views;

use RGTools::RGIO;

## still uses SDB::DBIO methods for now .. phase out ##

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Update Links' => 'update_link',
            'Reset Links'  => 'update_link',
            'Add Link'     => 'add_link'
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

####################
sub add_link {
####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->{dbc};

    my $defined      = $q->param('Defined_Record');
    my $id           = $q->param('Defined_ID') || $q->param('ID');
    my $link         = $q->param('Link');
    my $join_table   = $q->param('Join_Table');
    my $extra_fields = $q->param('Extra_Fields');
    my $homepage     = $q->param('HomePage');
 
    my $mode = 'Add';
    my $link_id = $q->param("$mode-$link"); ## , -convert_fk => 1, -dbc=>$dbc);

    my @extra_fields = ();
    @extra_fields = Cast_List( -list => $extra_fields, -to => 'array' ) if ($extra_fields);
    my @fields = ( $link,    $defined );
    my @values = ( $link_id, $id );
    foreach my $field (@extra_fields) {
        my $value = $q->param("$mode-$field");
        if ( defined $value ) {
            push @fields, $field;
            push @values, $value;
        }
    }
        
    my $new_id = $dbc->Table_append_array( $join_table, -fields => \@fields, -values => \@values, -autoquote => 1);
    if ($new_id) { $dbc->message("Added link successfully") }
    else { $dbc->warning("No new link record created") }
    
    my ( $table, $field ) = $dbc->foreign_key_check($defined);
    $dbc->session->homepage("$table=$id");
    
    if ($homepage) {
        return $self->View->home_page(-table=>$homepage, -id=>$id);
    }
    return ;
}

####################
sub update_link {
####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->{dbc};

    my $defined      = $q->param('Defined_Record');
    my $id           = $q->param('Defined_ID') ||  $q->param('ID');
    my $link         = $q->param('Link');
    my $join_table   = $q->param('Join_Table');
    my $no_triggers  = $q->param('No_Triggers');
    my $extra_fields = $q->param('Extra_Fields');
    my $homepage     = $q->param('HomePage');

    my $mode;
    if    ( $q->param('rm') =~ /Update/ ) { $mode = 'Select' }
    elsif ( $q->param('rm') =~ /Reset/ )  { $mode = 'Reset' }
    else                                  { Message("Undefined mode ?") }

    my @extra_fields = ();
    @extra_fields = Cast_List( -list => $extra_fields, -to => 'array' ) if ($extra_fields);

    my @reset_links = $q->param("$mode-$link"); ## $dbc->get_Table_Params( "$mode.$link", -convert_fk => 1 );
    my $reset_links = \@reset_links;

    my @current = $dbc->Table_find( $join_table, $link, "WHERE $defined = '$id'" );

    my ( $intersection, $add, $del ) = RGmath::intersection( $reset_links, \@current, -ignore_quotes => 1 );

    ## ADD = SELECT - CURRENT
    foreach my $add_id (@$add) {
        my @fields = ( $defined, $link );
        my @values = ( $id,      $add_id );
        foreach my $field (@extra_fields) {
            my $value = $q->param("$add_id-$field");
            if ( defined $value ) {
                push @fields, $field;
                push @values, "$value";
            }
        }
        $dbc->Table_append_array( $join_table, \@fields, \@values, -no_triggers => $no_triggers, -autoquote => 1 );
    }

    ## UPDATE = CUREENT
    ## need update only when there are extra fields
    if ($extra_fields) {
        foreach my $update_id (@$intersection) {
            my @fields;
            my @values;
            foreach my $field (@extra_fields) {
                my $value = $q->param("$update_id-$field");
                if ( defined $value ) {
                    push @fields, $field;
                    push @values, "$value";
                }
            }
            if ( int(@fields) ) {
                $dbc->Table_update_array( $join_table, \@fields, \@values, "WHERE $defined = $id and $link = $update_id", -autoquote => 1 );
                $dbc->message("Deleted Link Record");
                
            }
        }
    }

    ## DELETE = COMMON (CURRENT , (ACCESS  - SELECTED))
    if ( @$del && $id ) {
        my $delete_ids = join ',', @$del;

        ## Note: we may wish to only delete records which were originally listed for the specific user (ie provide another parameter with editable list of id links)
        ##  (if so... intersect deletion list with editable/accessible list before generating final deletion list)

        ## delete records ##
        $dbc->delete_record( $join_table, $defined, $id, -condition => "$link IN ($delete_ids)", -quiet => 1 );
        $dbc->message("Deleted Link Record");
    }

    my ( $table, $field ) = $dbc->foreign_key_check($defined);
    $dbc->session->homepage("$table=$id");
    
    if ($homepage) {
        return $self->View->home_page(-table=>$homepage, -id=>$id);
    }

    return;
}

return 1;
