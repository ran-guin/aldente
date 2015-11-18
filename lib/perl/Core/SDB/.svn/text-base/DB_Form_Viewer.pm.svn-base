################################################################################
# $Id: DB_Form_Viewer.pm,v 1.141 2004/12/07 18:33:41 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.141 $
#     CVS Date: $Date: 2004/12/07 18:33:41 $
################################################################################
#
# DB_Form_Viewer.pm
#
# This facilitates automatic viewing in HTML of Database information.
#
# It should be pretty generic requiring only that database be a mySQL database
# (expecting foreign key names to be in the format:
#  FK(\w)_TableName__Suffix  (where TableName.TableName_Suffix is the target field)
#
#
# It also includes form elements, and a routine to branch to functions based
#  on parameters sent from the various forms.
#
# DB_Viewer_Branch should be called while parsing the primary file input parameters
#     to allow the flow to return to the appropriate routines within this module.
#     It will return a 1 if a branch is found.
#     It will return 0 if no branch is found.
#
################################################################################
#
# Global variables required:
#
# $homefile = the name of the primary file, from which the module is accessed.
#
# $homelink = the web link that may be used to reach the primary cgi file.
#             (such that the command <A Href=$homefile> reaches the cgi-file being used.
#
#
package SDB::DB_Form_Viewer;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Form_Viewer.pm - This facilitates automatic viewing in HTML of Database information.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This facilitates automatic viewing in HTML of Database information.<BR>It should be pretty generic requiring only that database be a mySQL database<BR>(expecting foreign key names to be in the format: <BR>FK(\w)_TableName__Suffix  (where TableName.TableName_Suffix is the target field)<BR>It also includes form elements, and a routine to branch to functions based<BR>on parameters sent from the various forms.<BR>DB_Viewer_Branch should be called while parsing the primary file input parameters<BR>to allow the flow to return to the appropriate routines within this module. <BR>It will return a 1 if a branch is found.<BR>It will return 0 if no branch is found. <BR>Global variables required:<BR>$homefile = the name of the primary file, from which the module is accessed.<BR>$homelink = the web link that may be used to reach the primary cgi file.<BR>(such that the command <A Href=$homefile> reaches the cgi-file being used.<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    DB_Viewer_Branch
    Table_Tree
    Table_search
    Table_search_edit
    edit_table_form
    add_record
    append_table_form
    parse_to_table
    view_records
    mark_records
    edit_records
    info_link
    display_search_form
    documentation
);
@EXPORT_OK = qw(
    DB_Viewer_Branch
    Table_Tree
    Table_search
    Table_search_edit
    edit_table_form
    add_record
    append_table_form
    parse_to_table
    view_records
    mark_records
    edit_records
    info_link
    display_search_form
    documentation
);

#############################
# standard_modules_ref       #
##############################

use strict;
use Data::Dumper;
use CGI qw(:standard);
use Storable qw(freeze thaw);
use MIME::Base32;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Validation;
use alDente::Tools;
use alDente::Subscription;

use SDB::CustomSettings;
use SDB::DB_Record;
use SDB::DB_Form;
use SDB::Submission;
use SDB::DBIO;
use SDB::DB_Object;
use SDB::Session;
use RGTools::HTML_Table;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;    #### module used to display Tables in HTML format...
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw(%Field_Info %Form_Searches);
use vars qw(%Primary_fields %Order $SDB_dir $nav $Sess $URL_temp_dir);    ### optional
use vars qw($testing $administrator_email);
use vars qw(@FontClasses);
use vars qw(%Defaults);
use vars qw(%Input);
use vars qw(%Settings);
use vars qw(%Barcode);
use vars qw($dbase $Connection $Security $URL_temp_dir $Multipage_Form);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
# custom calls using Stock.pm, Solutions.pm,
## Required variables (should be set in main program) ##
#
#   homefile = URL for current file.
#   homelink = web link (homefile + default parameters)...
#
use vars qw(
    $q
    $dbc
    $homefile
);
@FontClasses = ( 'vsmall', 'small', 'medium', 'large', 'vlarge' );
$administrator_email = "aldente\@bcgsc.bc.ca";

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

##########################
sub DB_Viewer_Branch {
##########################
    #
    # This routine looks at input parameters and branches to appropriate methods...
    # (it returns 1 if a branch is found) - otherwise, it returns a 0.
    #
    #    my $Records = shift;
    #
    # check for parameters to see if we need to use this module...
    #
    my %args = @_;
    my $dbc = $args{-dbc} || $args{'-dbc'} || $args{'dbc'} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $link    = $args{'link'}    || 0;    #### id to filename storing retrieval info...
    my $input   = $args{'input'}   || 0;
    my $user    = $args{'user'}    || 0;
    my $configs = $args{'configs'} || 0;    # Form configurations (e.g. preset, list, grey, etc)
    my $testflag   = $args{'testing'};
    my $old_return = $args{-old_return};    ## <CONSTRUCTION> - old to support old method of returning..(phase out !)

    $login_name ||= $user || param('User') || 'guest';
    my $output = '';                        #### output to be generated (return as scalar)

    # the following arguments are only valid if there is no $user_id and $Current_Department available (ie for collaborator submissions)
    my $project               = $args{'project'};
    my $collab_id             = $args{'collab_id'};
    my $collab_email          = $args{'collab_email'};
    my $submission_department = $args{'department'};
    my $target_group          = $args{'target_group'};

    my $single_form        = param('Single Form');    ## added to enable bypass of secondary navigational forms if specified...
    my $finish_transaction = 0;

    if ( defined $args{'finish_transaction'} ) {
        $finish_transaction = $args{'finish_transaction'};
    }
    else {
        $finish_transaction = 1;
    }

    # if target group is not defined, default to Public
    if ( !$target_group ) {
        $target_group = 'Public';
    }

    my %Input;
    if ($input) { %Input = %{$input} }

    my $homelink = $dbc->homelink();
    $homelink ||= $link;    #### if not globally specified retrieve as specified.

    my $table = param('Edit Records') || param('TableName') || param('Update_Table') || param('Table');
    if ( param('Update Table') =~ /Update (.*) Table/ ) { $table = $1; }

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {
        $prev_Cond = param('PreviousCondition');
    }
    ################## If Records are currently being checked #############
    my @selected;    ########## Grab selection list (records with checkboxes set)
    my @highlights;
    if ( param('DBTable') || param('DBForm') ) {

        my $append = param('DBAppend');
        my $list   = param('DBList');
        my $view   = param('DBView');
        my $update = param('DBUpdate');
        my $repeat = param('DBRepeat') || 1;
        my $reload = param('DBReload') || 0;

        $dbase ||= param('Database') || '';

        my $target = param('Target') || 'Database';    #For now default the target to Database if nothing specified.
                                                       #my $target = param('Target') || '';
                                                       #unless ($target) { print "No Target Specified (XML or Database) ?"; return "Error"; }

        my $table = param('DBTable');
        my %require;
        if ( param('Require') ) {
            my $required_list = join ',', param('Require');
            foreach my $ensure ( split ',', $required_list ) {
                $require{$ensure} = 1;
            }
        }

        my $regenerate = 0;                            # Flag to indicate whether we are regenerating the form due to a form validation error
        if ($update) {
            my $newTables;
            my $mode;
            if ( $update =~ /Update (.*)/ ) {
                $newTables = param('Update_Table') || $1;
            }
            elsif ( $update =~ /Continue|Finish|Skip|Save Draft/i ) {
                $newTables = param('Update_Table');
                $mode      = $update;
            }
            else { $output .= "unrecognized update ?"; }

            my @new_tables = split ',', $newTables;

            # remove new tables if not in Allowed_Tables
            my $allowed_tables = join ',', param('Allowed_Tables');
            $allowed_tables ||= $table;
            my @allowed_list = ();
            foreach my $new_table (@new_tables) {
                if ( $allowed_tables =~ /\b$new_table\b/i ) {
                    push( @allowed_list, $new_table );
                }
            }
            @new_tables = @allowed_list;

            unless ($mode) { $mode = 'Normal' }

            # validate all entries
            my $msg = '';
            foreach my $newTable (@new_tables) {
                unless ( $mode eq 'Skip' ) {    # Do not validate if skipping form  ## SCOPE problem ! <CONSTRUCTION> ###
                    $msg = &alDente::Validation::Validate_Form_Info( $dbc, $newTable, \%Input );
                }

                if ($msg) {
                    Message("Error: Incomplete or invalid input");
                    $msg = decode_format($msg);
                    $output .= "<B><span class=small>$msg</span></B>";
                    $append     = $table;       ### back to the append page if this returns a failure
                    $regenerate = 1;
                    while ( $msg =~ s/(DBField_Error:)(\S+)\s// ) {
                        push( @highlights, $2 );
                    }
                    last;
                }
            }
            my $form = undef;
            if ( param('Multipage_Form') ) {
                my $frozen = param('Multipage_Form');
                $form = SDB::DB_Form->new( -dbc => $dbc, -frozen => 'Multipage_Form', -encoded => 1 );
            }
            else {
                my $frozen = param('Frozen_Form');
                $form = SDB::DB_Form->new( -dbc => $dbc, -frozen => 'Frozen_Form', -encoded => 1 );
            }

            if ( !$msg ) {
                my @new_records;

                # store the records of the newest table/s
                foreach my $newTable (@new_tables) {
                    unless ( $mode =~ /Skip/i ) {
                        $form->store_data( -table => $newTable, -input => \%Input );
                    }
                }

                # save global
                if ( param('Multipage_Form') ) {
                    $Multipage_Form = $form;
                }

                # update database/file if necessary
                if ( $mode =~ /Normal|Finish|Save Draft/ ) {

                    # Starts transaction
                    $dbc->start_trans('db_form_viewer');
                    eval {
                        foreach my $made ( 1 .. $repeat )
                        {

                            #			    my $delete;
                            #			    ($made == $repeat) ? ($delete = 1) : ($delete = 0); # Delete the form session hash if we are in the last record
                            my $ret;
                            if ( $repeat > 1 ) {    # Repeating records - need to specify which record to update
                                $ret = _update_record(
                                    -dbc          => $dbc,
                                    -target       => $target,
                                    -record       => $made,
                                    -form         => $form,
                                    -project      => $project,
                                    -collab_id    => $collab_id,
                                    -collab_email => $collab_email,
                                    -department   => $submission_department,
                                    -mode         => $mode,
                                    -testing      => $testflag,
                                    -group        => $target_group
                                );
                            }
                            else {
                                $ret = _update_record(
                                    -dbc          => $dbc,
                                    -target       => $target,
                                    -form         => $form,
                                    -project      => $project,
                                    -collab_id    => $collab_id,
                                    -collab_email => $collab_email,
                                    -department   => $submission_department,
                                    -mode         => $mode,
                                    -testing      => $testflag,
                                    -group        => $target_group
                                );
                            }

                            # return IDs of last table to be appended
                            if ( ref($ret) eq 'HASH' ) {
                                foreach my $key ( keys %{$ret} ) {
                                    push( @new_records, $ret->{$key} ) if ( $key =~ /^$table\./ );
                                }
                            }
                            elsif ( $ret =~ /[1-9]/ ) { push( @new_records, $ret ) }
                        }
                    };

                    my %newids = %{ $dbc->{transaction}->newids() };

                    if ($@) {
                        $dbc->finish_trans( 'db_form_viewer', -error => $@ );
                        return;
                    }
                    else {
                        $dbc->finish_trans('db_form_viewer');
                        if ($old_return) {
                            print $output;
                            return join ',', @new_records;
                        }
                        else {
                            return $output;
                        }
                    }
                }
                else {

                    # go to next form

                    if ($old_return) {
                        $form->generate( -next_form => !$single_form );
                        print $output;
                        return ($form);
                    }
                    else {
                        $output .= $form->generate( -next_form => !$single_form, -return_html => 1 );
                        return ( $output, $form );
                    }
                }
            }
            else {    ### If any error messages

                # redisplay current form
                my $configs;
                $configs->{highlight} = \@highlights;
                $form->configure(%$configs);

                if ($old_return) {
                    print $output;
                    $form->generate();
                    return ($form);
                }
                else {
                    $output .= $form->generate( -return_html => 1 );
                    return ( $output, $form );
                }
            }
        }
        if ($append) {
            my $newTable = $append;
            $output .= &Views::Heading("$newTable Submission -> $dbase");
            $output .= &Views::sub_Heading( "Database: $dbase", -2 );

            my %omit_fields;
            my %grey;

            my %include;
            if ( param('Edit_Submission') ) {    #Grab submission related information
                $include{Edit_Submission}   = param('Edit_Submission');
                $include{Submission_Source} = param('Submission_Source');
                $include{Table_Index}       = param('Table_Index');
                $include{Record_Index}      = param('Record_Index');
            }

            ###Grab all the preserve fields and include them as hidden fields....
            foreach my $param ( param() ) {
                if ( $param =~ /^Preserve:(.*)/ ) {
                    $include{$param} = param($param);
                }
            }

            ###Take care of multipage forms as well.
            if ( param('Multipage_Form') ) { $include{Multipage_Form} = param('Multipage_Form') }

            my $mode;
            if ($regenerate) { $mode = param('Mode') }
            ;    # Preserve the previous mode if regenerating

            my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $newTable, -target => $target, -wrap => 1, -mode => $mode );
            $form->configure( -highlight => \@highlights, -omit => \%omit_fields, -grey => \%grey, -preset => \%Input, -require => \%require, -include => \%include );
            $form->configure(%$configs) if $configs;

            if ($old_return) {
                print $output;

                my $form_output = $form->generate( -title => "New $newTable Record", -return_html => 1 );
                print $form_output;

                return 'form';
            }
            else {
                $output .= $form->generate( -next_form => !$single_form, -return_html => 1 );
                return $output;
            }
        }
        elsif ($list) {
            my $field = param('DBList');
            my $title = param('Title') || "$table information";
            my $ids   = param('IDList') || 0;
            my ( $ViewTable, $ViewField ) = foreign_key_check( -dbc => $dbc, -field => $field );
            unless ($ViewTable) { $ViewTable = $table }
            unless ($ViewField) { $ViewField = $field }
            my ($view) = &Table_find( $dbc, 'DBField,DBTable', 'Field_Reference', "where FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$ViewTable' AND Field_Name = '$ViewField'" );
            my ($primary) = get_field_info( $dbc, $table, undef, 'pri' );

            $view ||= $ViewField;
            my @views = ("$view as $ViewTable");

            my $condition;
            if ($ids) {
                $ids =~ s/,/','/g;    ### make generic for either text OR int
                $condition = "WHERE $primary in ('$ids')";
            }

            $output .= &Views::Heading($title);
            if ($old_return) {
                print $output;
                &Table_retrieve_display( $dbc, $ViewTable, \@views, $condition );
                return 'form';
            }
            else {
                $output .= &Table_retrieve_display( $dbc, $ViewTable, \@views, $condition, -print => 0 );
                return $output;
            }
        }
        elsif ($view) {
            my $field     = param('DBView');
            my $ViewList  = param('DBList');
            my $Condition = param('Condition');
            my ( $ViewTable, $ViewField ) = foreign_key_check($field);
            unless ($ViewTable) { $ViewTable = $table }
            unless ($ViewField) { $ViewField = $field }

            $output .= &Views::Heading("$ViewTable Entries");
            $output .= &Views::sub_Heading( "Database: $dbase", -2 );
            $output .= &view_records( $dbc, $ViewTable, $ViewField, $ViewList, $Condition );

            if ($old_return) {
                print $output;
                return 'form';
            }
            else {
                return $output;
            }
        }
        elsif ($reload) {    ## simply reload the same form... ##
            my %Input;
            foreach my $param ( param() ) {
                my $value = join ',', param($param);
                $Input{$param} = $value;
            }

            my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target, -wrap => 1 );
            $form->configure( -input => \%Input, -require => \%require );
            $form->configure(%$configs) if $configs;
            return 'form';
            if ($old_return) {
                print $output;
                $form->generate( -title => "$table Form" );
                return 'form';
            }
            else {
                $output .= $form->generate( -title => "$table Form", -return_html => 1 );
                return $output;
            }
        }
        else {

            #	    print "Unknown request from DBTable"; return "Error";
        }
    }

######### import from barcode page .... ##################

    elsif ( param('Info') || param('New View Index') ) {
        my $heading = param('Title') || 'Info';
        $dbase      ||= param('Database');
        $login_name ||= param('User');
        $output .= &Views::Heading($heading);
        my $field     = param('Field');
        my $like      = param('Like');
        my $table     = param('Table') || param('TableName') || param('Object');
        my $condition = param('Condition');
        my $options   = join ',', param('Options');
        my $fields    = join ',', param('Fields');

        if ( $condition =~ /(.*) LIKE (\S+)(.*)/i ) {    ### insert quotes if LIKE String in condition...
            my $c1 = $1;
            my $c2 = $2;
            my $c3 = $3;
            unless ( $c2 =~ /^(\'\")(.*)(\'\")$/ ) {     ### correct if not quoted...
                $c2        = "'$c2'";
                $condition = "$c1 LIKE $c2$c3";
            }
        }

        $output .= view_records( $dbc, $table, $field, $like, $condition, $options, -fields => $fields );

        if (0) { }
#### Custom entry . ###
        elsif ( ( $table eq 'Organization' ) && ( $field eq 'Organization_ID' ) && $like ) {
            $output .= &Link_To( $dbc->config('homelink'), "Contact Information", "&Info=1&Table=Contact&Field=FK_Orgainzation__ID&Like=$like", $Settings{LINK_COLOUR}, ['newwin'] );

            #	    $output .= SDB::DB_Form_Viewer::view_records($dbc,'Contact','FK_Organization__ID',$like,$condition);
        }
        elsif ( ( $table eq 'Standard_Solution' ) && ( $field eq 'Standard_Solution_ID' ) ) {
            ### allow option like bottom of Reagents page.  ###
            ( my $chem ) = &Table_find( $dbc, 'Standard_Solution', 'Standard_Solution_Name', "where Standard_Solution_ID in ($like)" );
            $output .= "<HR>";

            $output .= alDente::Form::start_alDente_form( $dbc, 'New Form' );

            $output .= submit( -name => 'Chemistry_Event', -value => 'Check Chemistry Calculator', -class => "Search" ) . " for " . textfield( -name => 'Wells', -size => 4, -default => '' ) . ' wells (leave blank to edit Formula/Parameters)';
            $output .= hidden( -name => 'Table', -value => 'Standard_Solution', -force => 1 ) . hidden( -name => 'Chemistry', -value => $chem ) . end_form();
        }
        if ($old_return) {
            print $output;
            return 'exit';
        }
        else {
            return $output;
        }
    }    # param('info') ends

    ######### ... if Table Name encapsulated in parameter name #########
    if ( param('New Entry') ) {
        $table = param('New Entry');
        if   ( $table =~ /New (.*)/ ) { $table = $1; }
        else                          { $table = param('New Entry Table'); }
    }
    elsif ( param('Edit Table') ) {

        ( my $table ) = param('Edit Table') || '';
        if ( $table =~ /Edit (.*) Table/i ) { $table = $1; }
        elsif ( param('New Entry Table') ) { ($table) = param('New Entry Table'); }
        elsif ( $table =~ /^(\w*)$/ ) { }
        else                          { print "No Table to search ($table)"; return 0; }

        my $field = param('Field');
        my $value = param('Like');

        my $condition = param('Condition') || $prev_Cond || 1;
        if ( param('Search String') && param('Search String Field') ) {
            my $string = param('Search String');

            #	    $string =~s/\?/_/g;
            #	    $string =~s/\*/%/g;
            $string = convert_to_regexp($string) if $string;

            my $search_fields = join " LIKE '$string' OR ", param('Search String Field');
            $condition .= " AND ($search_fields LIKE '$string')";
            Message("Using condition: $condition");
        }

        my $show = join ',', param('Display');
        my $hide = join ',', param('Hide');

        $output .= &Views::Heading("Editing $table Table");

        if ($old_return) {
            print $output;
            &edit_records( $dbc, $table, $field, $value, $condition, -hide_fields => $hide, -display => $show );
            return 'form';
        }
        else {
            $output .= &edit_records( $dbc, $table, $field, $value, $condition, -hide_fields => $hide, -display => $show, -return_html => 1 );
            return $output;
        }
    }
    elsif ( !$table ) { return 0; }    ### most of routines require a table name...

    ###### another way of selecting records... #####
    if ( param('Mark') ) { @selected = param('Mark'); }

    my @fields = param('Display');
    ################# End of Order Viewing ##############################

    #    if ($table eq 'Library') {
    #	my $cond="where Library_Name like 'AS%'";
    #	my $List = SDB::DB_Record->new($dbc,'Library',$homelink);
    #	$List->List_by_Condition($cond);
    #	return 1;
    #    }
    my $Records = SDB::DB_Record->new( $dbc, $table, $homelink );
    ### if we get this far, check the edit form viewer... ####
    if ( $Records->DB_Record_Viewer() ) {
        if ($old_return) {
            print $output;
            return 'multi-record form';
        }
        else {
            ## <CONSTRUCTION> - return sclar from DB_Record_Viewer...
            return $output;
        }
    }
    ### Deletes below are for mark_records routine..
    if ( param('Confirmed Delete Records') ) {
        my $select_list = param('Confirmed Deletions');
        $dbc->delete_records( $table, $Records->{ID}, $select_list );
        $Records->List_by_Condition($prev_Cond);
    }
    elsif ( param('Delete Record') ) {
        my $select_list = join ',', @selected;
        Confirm_Deletion( $table, $select_list, -dbc => $dbc );
    }

    ##################### Table Searching/Viewing Routines #############################
    elsif ( param('Tree') ) {

        $output .= h1("Table Tree Structure");
        my $multilevel = param('MultiLevel') || 0;
        $output .= Table_Tree( $dbc, $table, multilevel => $multilevel );
    }
    elsif ( param('Search for') ) {
        if ( param('Multi-Record') ) {
            my ($primary) = get_field_info( $dbc, $table, undef, 'pri' );
            my $ordered;
            $ordered = "$primary desc";
            &edit_records( $dbc, $table, undef, undef, -order => $ordered );
        }
        else {
            ## single record search/edit...
            my %args;
            $args{-dbc}    = $dbc;
            $args{-tables} = $table;
            if ( exists $Form_Searches{$table} ) {
                foreach my $setting ( keys %{ $Form_Searches{$table} } ) {
                    my $value = $Form_Searches{$table}->{$setting};
                    $args{"-$setting"} = $value;
                }
            }
            &Table_search(%args);
        }
    }
    elsif ( param('Search') ) {
        my $simple      = param('SimpleSearch');
        my $search_list = param('Search List');
        if ( param('Multi-Record') ) {
            my $primary = get_field_info( $dbc, $table, undef, 'pri' );
            my $ordered;
            if ( defined $Order{$table} ) {
                $ordered = $Order{$table} . " desc";
            }
            else { $ordered = "$primary desc"; }
            &edit_records( $dbc, $table, -primary => $primary, -list => $search_list, -order => $ordered );
        }
        else {
            if ($table) {
                my $table_fields;
                if ( param('table_fields') ) {
                    $table_fields = param('table_fields');
                    $table_fields = Storable::thaw( MIME::Base32::decode($table_fields) );
                }
                unless ( &Table_search_edit( $dbc, $table, $search_list, undef, $table_fields, -simple => $simple ) ) {
                    Message("Normal..?");
                    my %args;
                    $args{-dbc}    = $dbc;
                    $args{-tables} = $table;

                    if ( exists $Form_Searches{$table} ) {
                        foreach my $setting ( keys %{ $Form_Searches{$table} } ) {
                            my $value = $Form_Searches{$table}->{$setting};
                            $args{"-$setting"} = $value;
                        }
                    }
                    Table_search(%args);
                }
            }
        }
    }
    elsif ( param('Next Page') || param('Previous Page') || param('Get Page') ) {
        my $list = param('Search List');
        Table_search_edit( $dbc, $table, $list );
    }
    elsif ( param('Save Changes') ) {
        my $update = param('Save Changes');
        if ( $update =~ /Update (\w+)/i ) {
            $table = $1;
        }
        my $id = param( $table . "_ID" );
        print '<p ></p>' . Link_To( $dbc->{homelink}, "Return to home page for current $table(s)", "&HomePage=$table&ID=$id" ) . '<p ></p>';

        my $list = param('Search List');

        &Table_search_edit( $dbc, $table, $list, 'update' );
    }
    elsif ( param('Save Changes as New') ) {

        my $add_record = param('Save Changes as New');
        if ( $add_record =~ / New (\w+)/ ) {
            $table = $1;
        }

        my $list = param('Search List');
        &Table_search_edit( $dbc, $table, $list, 'append' );
        &Table_search_edit( $dbc, $table, $list );
    }
    elsif ( param('Update Table') ) {

        my $new_record;
        if ( &alDente::Validation::Validate_Form_Info( $dbc, \%Input ) ) {    ### change this to generate message...
            my $target = param('Target') || 'Database';                       #For now default the target to Database if nothing specified.
            my $mode   = param('Mode')   || 'normal';

            # generate form
            my $form = new SDB::DB_Form( -dbc => $dbc );
            $form->store_data( -table => $table, -input => \%Input );
            my $ret = _update_record( -dbc => $dbc, -target => $target, -form => $form, -group => $target_group );
            if ( ref($ret) eq 'HASH' ) {
                foreach my $key ( keys %{$ret} ) {
                    if ( $key =~ /^$table\./ ) { $new_record = $ret->{$key} }
                }
            }

            #$new_record = &update_record($dbc,$table,$target,$mode,\%Input);
        }
        if ($new_record) {
            $output .= &view_records( $dbc, $table, get_field_info( $dbc, $table, undef, 'PRI' ), $new_record );
        }
        else {
            if ($old_return) {
                print $output;
                &add_record( $dbc, $table );
                return 1;
            }
            else {
                $output .= &add_record( $dbc, $table, -return_html => 1 );
                return $output;
            }
        }
        if ( $table eq 'Suggestion' ) {
            my $targets = $administrator_email;
            my $message = param('Suggestion_Text');
            my $name    = param('Requested By');
            $message .= "\n - $name";
            $message .= " - " . param('Priority');

            my $source = &Table_find( $dbc, 'Employee', 'Email_Address', "where Employee_Name = '$name'" );
            $source  .= "\@bcgsc.bc.ca";
            $message .= "\n$homefile?User=Admin&Bugs=1";

            my $ok = alDente::Subscription::send_notification( -dbc => $dbc, -name => "New Suggestion", -from => $source, -subject => 'New Suggestion (from Subscription Module)', -body => $message, -testing => $dbc->test_mode() );

        }
        if ($old_return) {
            print $output;
            return $new_record;
        }
        else {
            return $output;
        }

        #	}
        #	&main::check_last_page();
    }
    else { return 0; }
    return "DBviewer form";    #### branch found (page generated) ########
}

#
# Subroutines - making use of forms to view Database info.
#
############################################################################################
# Beginning of a method to automatically generate useful documentation for database tables.
#
# Allow html or text output, with options for:
#  - including SQL Create table command
#  - displaying local relationships (ie Table Tree structure) HTML only
#
# Return documentation string in specified format
################
sub documentation {
################
    my %args       = @_;
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table      = $args{-table};
    my $format     = $args{'-format'} || 'string';
    my $include    = $args{-include} || '';
    my $table_tree = $args{-table_tree} || 'n';                                                       #flag for Table Tree
    my $mode       = $args{-mode} || 'text';                                                          #HTML or Text mode
    my $document   = '';                                                                              #initialize the text document

    my @display = ( 'Field_Name', 'Field_Default', 'Field_Description', 'Field_Format', 'Field_Options', 'Null_OK' );
    my %fields = &Table_retrieve( $dbc, 'DBField,DBTable', \@display, "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' ORDER BY Field_Order" );
    if ( $mode =~ /\bhtml/ ) {

        #print header("text/html"),start_html(-title=>$table);
        print subsection_heading( $table . " Table" );

        #add Table Descriptions

        if ( $include =~ /\bcreat/i ) {

            #display the create table statement
            my $sth = $dbc->query( -query => "SHOW CREATE TABLE $table", -finish => 0 );
            my $data = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );

            my $string = $data->{'Create Table'};
            $string =~ s/\n/<br>/g;
            print p($string);
            print "<hr>\n";
        }
        if ( $include =~ /\btabledesc/i ) {
            my $sth = $dbc->query( -query => "DESC $table", -finish => 0 );
            my $data = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'AofA' );

            my $table = HTML_Table->new();
            $table->Set_Class('small');
            my @headers = ( 'Field', 'Type', 'Null', 'Key', 'Default', 'Extra' );
            $table->Set_Headers( \@headers );
            foreach my $record ( @{$data} ) {
                $table->Set_Row($record);
            }
            $table->Printout();
        }

        #flag for full description, outputs an HTML Table
        if ( $include =~ /\bdesc/i ) {
            my $html_table = HTML_Table->new( -class => 'small', -border => 1 );
            $html_table->Set_Headers( \@display );
            my $index = 0;
            while ( defined $fields{Field_Name}[$index] ) {
                my @store = ();
                foreach my $fieldvalue (@display) {
                    my $field = $fields{$fieldvalue}[$index] || "&nbsp;";
                    push( @store, $field );
                }
                $html_table->Set_Row( [@store] );
                $index++;
            }
            $html_table->Printout();
            print "<hr>\n";
        }

        #if ($example=~/\by/i){

        #my %fields = &Table_retrieve($dbc,'DBField,DBTable',\@display,
        #			     "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' ORDER BY Field_Order");
        #   my $data = $dbc->retrieve(-sql=>"DESC $table",-format=>'AofA');
        #  my $table = HTML_Table->new();
        # $table->Set_Class('small');
        # my @headers = ('Field','Type','Null','Key','Default','Extra');
        #$table->Set_Headers(\@headers);
        #foreach my $record (@{$data}) {
        #	 $table->Set_Row($record);
        #}
        #$table->Printout();

        #	}
        #display the HTML Table tree, need to set the homelink for the path to be resolved, the links to the foreign key tables will then work
        if ( $table_tree =~ /\by/ ) {
            my $multilevel = 1;
            my $output = Table_Tree( $dbc, $table, -multilevel => $multilevel, -hidelinks => 'y' );
            print $output;
        }

    }
    else {
        print "$table Table\n*************************\n";

        #display the create table Statement
        if ( $include =~ /\bcreat/i ) {
            my $sth = $dbc->query( -query => "SHOW CREATE TABLE $table", -finish => 0 );
            my $data = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );
            my $string = $data->{'Create Table'};
            $document .= "$string\n\n";
        }

        #display the full description in text format
        if ( $include =~ /\bdesc/ ) {
            $document .= sprintf "%-20s\t%-10s\t%-60s\t%-20s\t%-8s\n", @display;
            $document .= sprintf "%-20s\t%-10s\t%-60s\t%-20s\t%-8s\n", "*" x ( length( $display[0] ) ), "*" x ( length( $display[1] ) ), "*" x ( length( $display[2] ) );

            my $index = 0;
            while ( defined $fields{Field_Name}[$index] ) {
                my $name    = $fields{Field_Name}[$index]        || '';
                my $desc    = $fields{Field_Description}[$index] || '';
                my $format  = $fields{Field_Format}[$index]      || '';
                my $default = $fields{Field_Default}[$index]     || '';
                my $nullok  = $fields{Null_OK}[$index]           || '';
                $document .= sprintf "%-20s\t%-20s\t%-60s\t%-20s\t%-8s\n", $name, $default, $desc, $format, $nullok;
                $index++;
            }
        }
    }
    return $document;
}

###########################
sub Table_Tree {
###########################
    #
    # Generate Tree View for Database
    #
    my $dbc   = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # database
    my $table = shift;                                                                      # top level table
    my %args  = @_;

    my $level      = $args{'level'}      || 0;                                              # level of tree (necessary for recursive nature)
    my $multilevel = $args{'multilevel'} || param('MultiLevel') || param('Levels') || 0;    # flag to display multiple levels of structure (slower)
    my $shown      = $args{'shown'}      || '';
    my $hide_fields = $args{'hide'};                                                        ## exclude details of field names from Table (only relevant for multilevel views)...
    my $hide_links  = $args{'hidelinks'};                                                   ##exclude the Single level and Multilevel links
    $level++;

    my $output      = '';
    my @field_names = &get_fields( $dbc, $table );                                          ### retrieve list of fields

    my $num_fields = scalar(@field_names);

    $shown .= "," . $table;                                                                 ### track list of tables displayed

    my @tree;
    unless ( $hide_links =~ /^y/i ) {
        if ( $level <= 1 ) {
            if ($multilevel) {
                $output .= &Link_To( $dbc->config('homelink'), "Single Level", "&TableName=$table&Tree=ON&MultiLevel=0", 'black', -tooltip => "Only show fields in this table, or referencing this table" );
            }
            else {
                $output .= &Link_To( $dbc->config('homelink'), "<B>Single Level</B>", "&TableName=$table&Tree=ON&MultiLevel=0", 'black', -tooltip => "Only show fields in this table, or referencing this table" );
            }
            $output .= hspace(20);
            if ($multilevel) {
                $output .= &Link_To( $dbc->config('homelink'), "<B>Multi Level</B>", "&TableName=$table&Tree=ON&MultiLevel=1", 'black', -tooltip => "Show list of fields in tables referenced by this table" );
            }
            else {
                $output .= &Link_To( $dbc->config('homelink'), "Multi Level", "&TableName=$table&Tree=ON&MultiLevel=1", 'black', -tooltip => "Show list of fields in tables referenced by this table" );
            }
            $output .= vspace(10);
        }
    }
    my $Tree = HTML_Table->new();
    $Tree->Set_Title($table);
    $Tree->Set_Class('small');
    $Tree->Set_Headers( ['Fields'] );
    $Tree->Set_VAlignment('Top');

    foreach my $name (@field_names) {
        my $label = $name;
        if ( $name =~ /(\w+) as (\w+)/i ) {
            $name  = $1;
            $label = $2;
        }
        if ( my ($f_table) = foreign_key_check( -dbc => $dbc, -field => $name ) ) {
            push( @tree, $f_table );    ### push 'from table' onto tree.
            my $link = &Link_To( $dbc->config('homelink'), "<B>-> $label</B><BR>", "&TableName=$f_table&Tree=ON&MultiLevel=$multilevel", 'black', -tooltip => $name );
            $Tree->Set_Row( [ Show_Tool_Tip( $link, $name ) ] );
        }
        else { $Tree->Set_Row( [ Show_Tool_Tip( $label, $name ) ] ) }
    }

########### Generate table showing fields pointed to by $table ################
    my $Ref;
    my $refs = 0;
    if ( $level < 2 ) {
        my @foreign_keys = &get_fields( $dbc, undef, "FK%$table%" );

        $Ref = HTML_Table->new();
        $Ref->Set_Title("$table References");
        $Ref->Set_Class('small');
        $Ref->Set_Headers( [ 'Table', 'Field' ] );

        foreach my $this_key (@foreign_keys) {
            if ( $this_key =~ /(.*)\.(FK.*)/ ) {
                my $f_table   = $1;
                my $reference = $2;
                my ( $thistable, $f_key ) = foreign_key_check( -dbc => $dbc, -field => $reference );
                unless ( $thistable eq $table ) { next; }

                my $link = &Link_To( $dbc->config('homelink'), "$f_table", "&TableName=$f_table&Tree=ON&MultiLevel=$multilevel", 'black' );
                $Ref->Set_Row( [ Show_Tool_Tip( $link, "references $reference" ) ] );
                $refs++;
            }
        }
    }

    $output .= "<Table><TR><TD valign=top>";
    $output .= $Tree->Printout(0);

    if ( $level < 2 ) {
        $output .= "</TD><TD valign='centre'>";
        $output .= "<Img src='/$image_dir/left_arrow.png'>";
        $output .= "</TD><TD valign=centre>";

        if   ($refs) { $output .= $Ref->Printout(0); }
        else         { $output .= "(no References)"; }
    }
    $output .= "</TD></TR></TAble>";

    if ( !$multilevel ) { return $output; }

################# Continue only if displaying multi-level structure ################

    my $FKeys = HTML_Table->new();
    $FKeys->Set_Title("$table References:");
    $FKeys->Set_Line_Colour('white');

    my @row;
    my @headers;

    my $levels = $multilevel;
    my $morelevels;
    if ( $level > $levels ) {
        $morelevels = 0;
        $output .= '(cutoff at 20th generation)';
    }
    else { $morelevels = 1 }

    if ( !$morelevels ) { return $output }

    my @subtree;
    if ( scalar(@tree) ) {
        $output .= &hspace(40) . "<Img src='/$image_dir/down_arrow.png'>";
        foreach my $name (@tree) {
            if ( my ( $fk_t, $fk_f ) = foreign_key_check( -dbc => $dbc, -field => $name ) ) { push( @subtree, $fk_f ); }
            if ( !list_contains( $shown, $name ) ) {
                $shown .= ",$name";
                push( @row, &Table_Tree( $dbc, $name, level => $level, multilevel => $morelevels, shown => $shown ) );
                push( @headers, $name );
            }
            else {
                push( @row,     "(repeat)" );
                push( @headers, $name );
            }
        }
        $FKeys->Set_Row( \@row );
        $FKeys->Set_Headers( \@headers );
        $FKeys->Set_VAlignment('Top');
        $output .= $FKeys->Printout(0);
    }
    return $output;
}

################################
# Searching a Table for Records
################################

###########################
sub Table_search {
###########################
    #
    # Generate a search on a given table
    #
    # (providing a 'Search' button at the bottom to submit search query)
    #
    my %args = filter_input( \@_, -args => 'dbc,tables,include_fields' );

    my $dbc            = $args{-dbc};               # database handle
    my $tables         = $args{-tables};            # all tables to be serach (for multi-tables search)
    my $include_fields = $args{-include_fields};    # Fields to include in multi-tables serach
    my $exclude_fields = $args{-exclude_fields};    # Fields to exclude in multi-tables search
    my $parameters     = $args{-parameters};        # Form parameters

    my $autosearch           = 1;                   ### automatically search for foreign key fields..
    my $date_field_width     = 15;
    my $datetime_field_width = 25;
    my $int_field_width      = 5;
    my $field_width          = 40;

    my $Table = HTML_Table->new();
    $Table->Toggle_Colour(1);

    my $form_name = 'SearchForm';

    $tables = Cast_List( -list => $tables, -to => 'arrayref' );
    my $primary_table = $tables->[0];               # Set the first table in the list to be the primary table
    my @attr_tables;
    foreach my $tab ( @{$tables} ) {
        my $attribute_table = $tab . "_Attribute";
        if ( grep /^$attribute_table$/, $dbc->DB_tables() ) {
            push( @attr_tables, $tab );
        }
    }
    my $attribute_tables = Cast_List( -list => \@attr_tables, -to => 'string', -autoquote => 1 );
    my $condition = 1;
    $condition .= " AND  Attribute_Class in ($attribute_tables)" if $attribute_tables;
    my %attributes = Table_retrieve( $dbc, "Attribute", ["CONCAT(Attribute_ID,'-',Attribute_Class,'-',Attribute_Name) as Attribute_Info"], "WHERE $condition" ) if $attribute_tables;

    my $attribute_row_colour = '#FFFFCC';
    if ( exists $attributes{Attribute_Info}[0] ) {
        ## enable users to 'OR' or 'AND' Attribute specifications ##
        $Table->Set_Row( [ 'custom attributes:', 'Link attribute conditions using: ' . popup_menu( -name => 'attr_operator', -values => [ 'OR', 'AND' ], -default => 'AND', -force => 1 ) ], "bgcolor=$attribute_row_colour" );

        my @attr_names = @{ $attributes{Attribute_Info} };
        $Table->Set_Row(
            [   alDente::Tools->search_list(
                    -dbc     => $dbc,
                    -form    => $form_name,
                    -name    => "attr_name",
                    -default => '-Select Attribute-',
                    -search  => 0,
                    -filter  => 0,
                    -breaks  => 0,
                    -options => [ "-Select Attribute-", @attr_names ]
                ),
                Show_Tool_Tip( textfield( -name => "attr_value", -size => $field_width ), "Attribute value" )
            ],
            "bgcolor=$attribute_row_colour",
            -repeat => 1
        );
    }
    foreach my $table ( split ',', @$tables ) {
        unless ( %Field_Info && defined $Field_Info{$table} ) { initialize_field_info( $dbc, $table ) }
    }
    my $table = $primary_table;

    my $db_object   = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables, -include_fields => $include_fields, -exclude_fields => $exclude_fields );
    my @fields      = @{ $db_object->fields() };
    my %fields_info = %{ $db_object->fields_info() };

    my @table_prompts;
    my @table_fields;

    foreach my $field (@fields) {
        my ( $rtable, $rfield ) = simple_resolve_field($field);
        if ( $fields_info{$rtable}->{$rfield}->{options} =~ /Hidden/ ) {next}    ## exclude hidden fields from both search and update (unnecessary, and can cause problems)
        push( @table_prompts, $fields_info{$rtable}->{$rfield}->{prompt} );
        push( @table_fields,  $field );
    }

    my @table_types;                                                             ### Generate array of table types to identify sets, enumerated fields.
    foreach my $field (@table_fields) {
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;

            #	    push(@table_prompts,$2);
        }
        else {

            #	    push(@table_prompts,$field);
        }

        my $t = $table;
        my ( $rtable, $rfield ) = simple_resolve_field($field);
        $t = $rtable if ($rtable);

        my @info = &get_field_types( $dbc, $t, $rfield );
        if ( $info[0] =~ /(.*)\t(.*)/ ) {
            push( @table_types, $2 );
        }
    }

    my $fields = scalar(@table_fields) - 1;    ### number of fields to list - 1

    my $output = section_heading("Search Table : $primary_table (with $fields fields)");

    $output .= subsection_heading("(use '%' or '*' as a wildcard)");
    $output .= subsection_heading("(may use '>', '<' or range ('1-4') for numbers)");
    
    my %Parameters;
    if ( $parameters && ref($parameters) eq 'HASH' ) {
        %Parameters = %$parameters;
    }

    $output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => $form_name, -parameters=>\%Parameters);
    $output .= submit( -name => 'Search', -class => "Search" );
    $output .= &hspace(10) . Show_Tool_Tip( checkbox( -name => 'View Only', -label => 'View all search results together', -checked => 1, -force => 1 ), "Unless this is checked, Records are retrieved to edit one at a time" );

    my $forces = 0;

    ### limit length of popup window in case super long
    my $max_length = $Settings{FOREIGN_KEY_POPUP_MAXLENGTH};

    $dbc->Benchmark('call_DB_Form');
    foreach my $table (@$tables) {
        my $Form = new SDB::DB_Form( -dbc => $dbc, -wrap => 0, -table => $table );    #-fields=>\@table_fields);
        $output .= $Form->generate( -return_html => 1, -title => "$table info", -navigator_on => 0, -submit => 0, -action => 'search' );
    }

    #    # Store the searchable fields

    my $frozen = MIME::Base32::encode( Storable::freeze( \@table_fields ), "" );
    $output .= hidden( -name => 'table_fields', -value => $frozen );

    $output .= submit( -name => "Search", -class => "Search" );
    $output .= hidden( -name => 'Table', -value => $table ) .

        #    hidden(-name=>'Search',-force=>1,-value=>$table),
        hidden( -name => 'Page', -force => 1, -value => 1 ) . "\n</Form>";

    ## if returning a value, assume that we are wishing to pass the entire form
    if   ( defined wantarray() ) { return $output }
    else                         { print $output; return; }    ## otherwise, print out the form automatically...
}

###########################
sub join_attributes {
###########################
    #
    # Search/Edit results page from 'Table_search' - updates database
    my %args = &filter_input( \@_, -args => 'cond,tables' );
    my $condition = $args{-cond} || 1;
    my $tables    = $args{-tables};                            # table to edit

    my @attr_value = param('attr_value');
    my $attr_operator = param('attr_operator') || 'AND';
    my $attr_name;
    my $attr_class;
    my $attr_id;
    my $attr_table;

    my @attr_info = param('attr_name');
    if ( !param('attr_name') ) {
        @attr_info = param("attr_name Choice");
    }

    my @local_conditions;
    for ( my $attr = 0; $attr < scalar(@attr_value); $attr++ ) {
        ( $attr_id, $attr_class, $attr_name ) = split( '-', $attr_info[$attr] );

        $attr_table = $attr_class . "_Attribute";
        my $fk_field = "FK_" . $attr_class . "__ID";

        if ( $attr_operator =~ /OR/i ) {
            my $left_join = " LEFT JOIN $attr_table AS $attr_name ON $attr_name.FK_Attribute__ID=$attr_id AND $attr_name.$fk_field=$attr_class" . "_ID";
            $tables .= $left_join unless ( $tables =~ /\b$left_join\b/ );
        }
        else {
            $tables    .= ",$attr_table AS $attr_name";
            $condition .= " AND $attr_name.FK_Attribute__ID=$attr_id";
        }
        push( @local_conditions, "$attr_name.Attribute_Value='$attr_value[$attr]'" );
    }
    my $local_condition = join " $attr_operator ", @local_conditions if @local_conditions;
    $condition = "WHERE $condition AND ($local_condition)" if $local_condition;

    return ( $condition, $tables );
}

###########################
sub Table_search_edit {
###########################
    #
    # Search/Edit results page from 'Table_search' - updates database
    #
    # (enters with possible search_results list carried over from search)
    # update flag indicates whether this is an update or append action...
    #
    # Buttons at the bottom of the page allow:
    #  New Search
    #  Save Changes as New Record
    #  Save Changes (Editing current record)
    #
    #  Re-Print $table Barcode - this enables printouts of labels if applicable...
    #

    my %args = &filter_input( \@_, -args => 'dbc,table,search_list,update,table_fields_ref,configs_ref,simple,add_option' );

    my $dbc              = $args{-dbc};
    my $table            = $args{-table};               # table to edit
    my $search_list      = $args{-search_list};         # list of search results generated from search
    my $update           = $args{-update};              # Update existing record or append NEW record
    my $table_fields_ref = $args{-table_fields_ref};    # List of searchable fields predefined
    my $configs_ref      = $args{-configs_ref};         # Reference to form configurations
    my $simple           = $args{-simple};              # simple view - remove extraneous messages
    my $add_option       = $args{-add_option};          # removed addlinks
    my $return_html      = $args{-return_html};

    my $date = &date_time();

    my $param;

    my $no_copy = $simple || param('No Copy');

    my $table_id = $alDente::SDB_Defaults::Primary_fields{$table};
    $table_id ||= join ',', get_field_info( $dbc, $table, undef, 'Primary' );
    if ( $Sess && !$table_id ) { $dbc->warning("No Primary Field(s) found for $table (see admin)"); }
    my $tables = $table;

    my $output = '';

    # don't print this out if just updating/appending
    if ( !$update && !$simple ) {
        $output .= &Views::Heading("Search/Edit $table");
    }

    my $append;
    if ( $update =~ /update/i ) { $append = 0; }
    elsif ( $update =~ /append/i ) { $append = 1; $update = 0; }

    my @table_fields;
    if ($table_fields_ref) {
        @table_fields = @{$table_fields_ref};
    }
    else {
        @table_fields = map {
            my $input = $_;
            if   ( $input =~ /(.*) as (.*)/i ) { $_ = $1; }
            else                               { $_ = $input; }
        } get_fields( $dbc, $table, undef, 'defined' );    ### (was get_defined_fields) ##
    }
    my $fields = $#table_fields;
    my @table_types;                                       ### array of field types to identify enumerated fields, and sets.
    foreach my $field (@table_fields) {
        my ( $rtable, $rfield ) = simple_resolve_field($field);
        my @info = get_field_types( $dbc, $rtable, $rfield );
        if ( $info[0] =~ /(.*)\t(.*)/ ) {
            push( @table_types, $2 );
        }
    }
    my $condition = "WHERE 1";
#    ############################## Do the search if it hasn't been done yet ###################
#    my $db = SDB::DBIO->new( -dbc => $dbc );

    if ( !$search_list ) {                                 #1
        my $index = 0;
        foreach my $field (@table_fields) {                #2
                                                           #print ++$j . "<br>";
            my $this_condition;
            my $thisfield = $field;

            my ( $rtable, $rfield ) = simple_resolve_field($field);

            my @params = @{ get_Table_Params( -table => $rtable, -field => $rfield, -dbc => $dbc ) };    ## param($field) || param($rfield);
            if ( $table_types[$index] =~ /date/ ) {
                my $from = get_Table_Param( -table => $rtable, -field => 'from_' . $rfield, -dbc => $dbc );
                if ( $from =~ /^\d+-\d+-\d+$/ ) { $from .= " 00:00:00" }                                 # fix for date without exact time
                $condition .= " AND $rtable.$rfield >= '$from'" if $from;

                my $to = get_Table_Param( -table => $rtable, -field => 'to_' . $rfield, -dbc => $dbc );
                if ( $to =~ /^\d+-\d+-\d+$/ ) { $to .= " 23:59:59" }                                     # fix for date without exact time
                $condition .= " AND $rtable.$rfield <= '$to'" if $to;
            }
            my @parsed_params;
            foreach my $prm (@params) {

                if ( my ($fk) = foreign_key_check( -dbc => $dbc, -field => $field ) ) {
                    my $id_value = get_FK_ID( $dbc, $field, $prm );                                      ### in case FK..
                                                                                                         #if ($id_value) { $param=$dbc->dbh()->quote($id_value) }  ### removed because it double quotes values
                    if ($id_value) { $prm = $id_value }                                                  ### use retrieved value if applicable
                }
                push @parsed_params, $prm;

            }
            $param = join '|', @parsed_params;

            #	    ## if param($field) is blank, try the $field Choice parameter
            #	    $param ||= param("$field Choice") || param("$rfield Choice");
            #            $param = get_Table_Params(-table=>$rtable,-field=>$rfield);

            my $foreign_table;
            if ( $thisfield =~ /(\w+)\.(\w+)/ ) {
                $foreign_table = $1;
                my $foreign_field = $2;

                unless ( $tables =~ /\b$foreign_table\b/ ) {
                    $tables .= ", $foreign_table";
                }
            }    #end for #2

            my $ffield;
            if ( $param =~ /\S/ ) {
                if ( grep /$rfield/, $dbc->get_field_info( -table => $table, -type => 'Primary' ) && ( grep /$rfield/, $dbc->get_field_info( -table => $table, -type => 'int' ) ) ) {
                    $param = RGTools::Conversion::extract_range($param);
                }
                my $cond = convert_to_condition( $param, -field => $field, -type => $Field_Info{$rtable}{$rfield}{Type} );

                #print "F: $field   C: $cond\n";
                $condition .= " AND $cond" if $cond;
            }
            $index++;
        }    #!searchlistends #1
        if ( param('attr_value') ) {
            ( $condition, $tables ) = &join_attributes( -cond => $condition, -tables => $tables );
        }

        # Finally join all the tables
        my $tables_count = int( my @list = split /\s*,\s*/, $tables );
        if ( $tables_count > 1 ) {
            my $extra_condition = $dbc->get_join_condition($tables);
            $condition .= " AND $extra_condition" if $extra_condition;
        }

        $search_list = join ',', Table_find_array( $dbc, $tables, [$table_id], $condition, );    #-debug => 1
                                                                                                 #  Message("Search Condition: $condition");
    }    #?

    if ( $search_list && !$update && !$append && !$simple ) {
        $output .= &Link_To( $dbc->config('homelink'), "View/Edit Multiple Records at one time", "&Edit+Table=$table&Field=$table_id&Like=$search_list" );
    }

    my $list_page;

    my @split_list = split ',', $search_list;

    my $page = param('Page');
    $page ||= 1;

    my $pages = scalar(@split_list);

    unless ($pages) {
        Message( "No Records found matching condition:", $condition );
        return 0;
    }

    ################## allow specific page selections to be accessed ####################
    if ( param("Next Page") ) {
        $page++;
        if ( $page > $pages ) { $page = $pages; }
    }
    elsif ( param("Previous Page") ) {
        $page--;
        if ( $page < 1 ) { $page = 1; }
    }
    elsif ( param("Get Page") ) {
        my $thispage = join ',', param('Get Page');
        my $this_id = get_FK_ID( $dbc, $table_id, $thispage );

        my $index;

        ### allow flexible display option if the previous one didn't work...
        if ( !$this_id && ( param("Get Page") =~ /(.*):/ ) ) {
            $this_id = $1;
        }
        $index = 1;
        foreach my $list_item (@split_list) {
            if ( $list_item eq $this_id ) { $page = $index; last; }
            $index++;
        }
    }

    my $id = $split_list[ $page - 1 ];
    if ( $id eq 'NULL' ) { Message("Nothing found"); return 0; }
    if ( $table_id =~ /Name/ ) { $id = "\"$id\""; }

    my $join_condition = $dbc->get_join_condition($tables);
    my %Current_Settings;

    if ($join_condition) {
        %Current_Settings = &Table_retrieve( $dbc, $tables, \@table_fields, "WHERE $table_id = $id AND $join_condition" );
    }
    else {
        %Current_Settings = &Table_retrieve( $dbc, $table, \@table_fields, "WHERE $table_id = $id" );
    }

    ################ Unless updating or appending ... ########################
    if ( !$update && !$append ) {

        $output .= alDente::Form::start_alDente_form( $dbc, 'SearchEdit' );

        if ( !$simple ) {
            $output .= h3("Search results for $table");
        }

        my $title = section_heading("$table $id ($page / $pages)");
        if ( ( param('Search_Target') eq 'Info' ) || param('View Only') ) {
            my ($primary) = get_field_info( $dbc, $table, undef, 'PRI' );
            $output .= view_records( $dbc, $table, $primary, $search_list );
        }
        else {

            #$output .= &edit_table_form($dbc,$table,$id,$title,\@split_list,'references','details',$configs_ref,$simple,-return_html=>$return_html);
            $output .= &edit_table_form( $dbc, $table, $id, $title, \@split_list, 'references', 'details', $configs_ref, $simple, -return_html => 1, -add_option => $add_option );
            $output .= submit( -name => "Save Changes", -value => "Update $table", -class => 'Action', -onClick => 'return validateForm(this.form)' ) . vspace() . lbr;

            my $prefix = $dbc->barcode_prefix($table);
            my $barcode;
            $barcode = $prefix . $id if ( $prefix && $id );

            if ( $page < $pages ) {
                $output .= submit( -name => "Next Page", -value => 'Next', -class => "Std" ) . " ";
            }
            if ( $page > 1 ) {
                $output .= submit( -name => "Previous Page", -value => 'Previous', -class => "Std" ) . " ";
            }

            if ( !$simple ) {
                $output .= submit( -name => "Search for", -value => 'New Search', -class => "Std" ) . &hspace(10) . checkbox( -name => 'Multi-Record' ) . &vspace();
            }

            if ( $Barcode{$table} ) {
                $output .= submit( -name => 'Barcode_Event', -value => "Re-Print $table Barcode", -class => "Std" ) . vspace();
            }
            $output .= hidden( -name => 'Search List', -value => $search_list ) .

                #	    hidden(-name=>'Page',-force=>1,-value=>$page) .
                #	    hidden(-name=>'Table',-force=>1,-value=>$table) .
                #	    hidden(-name=>'Barcode',-force=>1,-value=>$barcode) .
                hidden( -name => $table . "_ID", -value => $id, -force => 1 );
            if ( !$no_copy ) {
                $output .= submit( -name => "Save Changes as New", -value => "Save as New $table Record", -class => 'Action', -onClick => 'return validateForm(this.form)' ) . vspace();
            }
            $output .= Link_To( $dbc->{homelink}, "Return to home page for current $table(s)", "&HomePage=$table&ID=$id" ) . vspace();
            $output .= end_form();
        }
    }

    ################################# if updating or appending ... ####################
    elsif ( $update || $append ) {
        my @new_fields = ();
        my @new_values = ();

        for my $index ( 0 .. $fields ) {
            my ( $table, $field ) = simple_resolve_field( $table_fields[$index] );

            #            my $table_id = $table_id;
            # #           ## just in case there are more than one table ##
            #           if ( $table_id =~ /,/ ) {
            #               my $table_id = $alDente::SDB_Defaults::Primary_fields{$table};
            my $primary_field ||= join ',', get_field_info( $dbc, $table, undef, 'Primary' );

            #           }

            #	    if ($table_types[$index]=~/^enum/) {$field = $1;}         ### why ??
            #	    elsif ($table_types[$index]=~/^set/) {$field = $1;}       ### commented out...
            ## if param($field) is blank, try the $field Choice parameter

            if ( $table_types[$index] =~ /set/ ) {
                ## retrieve array of values ##
                $param = join ',', @{ get_Table_Params( -table => $table, -field => $field, -dbc => $dbc ) };
            }
            else {
                ## retrieve single value (first non-empty if more than one) ##
                $param = get_Table_Param( -table => $table, -field => $field, -dbc => $dbc );
            }
            $index++;

            my $newvalue = $param;
            my $current  = $Current_Settings{$field}[0];

            if ( $update && ( $newvalue =~ /^\Q$current\E$/ ) ) {
                next;
            }

            #
            # Foreign Keys ...
            #
            if ($field) { RGTools::RGIO::Test_Message( "Converting $field", $testing ); }
            if ( my ($fk) = foreign_key_check( -dbc => $dbc, -field => $field ) ) {

                my $check_id = get_FK_ID( $dbc, $field, $newvalue );
                if ($check_id) { $newvalue = $check_id; }
                elsif ( !$newvalue || $newvalue =~ /undef/i ) { }    ### allow null values or zeros...
                #### Custom Insertion #######
                elsif ( $newvalue =~ /Pla0:/ ) { }                   ### allow Blank original plate..
                #### End Custom Insertion ###
                else {
                    $dbc->message( "Error: Invalid FK value", "$newvalue. (NOT CHANGED)" );
                    next;
                }
            }    #end if 1561
            if ($update) {    #1573
                if ( ( $primary_field eq $field ) && $newvalue =~ /^$id$/ ) {next}
                elsif ( $Current_Settings{$field}[0] =~ /^\Q$newvalue\E$/ ) {next}    ## no change ##
                $Sess->reset_homepage( { $table => $id } ) if ( $Sess && $Sess->{session_id} );
                my $ok = $dbc->Table_update_array( $table, [$field], [$newvalue], "where $primary_field=$id", -autoquote => 1 );
                if ($ok) {
                    if ( my ( $refTable, $refField ) = &foreign_key_check( -dbc => $dbc, -field => $field ) ) {
                        $current  = $dbc->get_FK_info( $field, $current );
                        $newvalue = $dbc->get_FK_info( $field, $newvalue );
                    }
                    $dbc->message("$field changed from '$current'  to  '$newvalue' for $primary_field $id");
                }
                else { RGTools::RGIO::Test_Message( "$field not changed", $testing ); }
            }    #1573 ends
            elsif ($append) {

                ############# Custom Insertion (convert some units) ##########
                if ( $field =~ /Quantity|Size$/ ) { ($newvalue) = get_number($newvalue); }
                ############# End Custom Insertion (convert some units) ##########

                if ( !( ( $primary_field eq $field ) && ( $newvalue =~ /^$id$/ ) ) ) {
                    ## exclude primary key when appending new record ##
                    push @new_fields, $field;
                    push( @new_values, $newvalue );
                }
            }

            #	    Message("$index: @new_fields : @new_values");
        }    #1527 for loop
        if ($append) {
            my $ok = $dbc->Table_append_array( $table, \@new_fields, \@new_values, -autoquote => 1 );
            if ($ok) {
                $dbc->message("New $table added");

                ########### CUSTOM #########################################
                ########### if Library update 'library_list' ###############
                if ( $table eq 'Library' ) {
                    &update_library_list( param('Library_Name') );
                }
            }
            else {
                $dbc->message("Error: $DBI::errstr");
            }
        }    # 1596 append ends
    }    # 1522 ends

    unless ($return_html) { print $output }
    return $output;

}

#########################
sub edit_table_form {
#########################
    my %args = &filter_input( \@_, -args => "dbc,table,id,title,list,include_references,include_details,configs_ref,simple,add_option" );

    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table              = $args{-table};
    my $id                 = $args{-id};                                                                      ### optional..
    my $title              = $args{-title};
    my $list               = $args{-list};
    my $include_references = $args{-include_references} ? 1 : 0;                                              ## leave on for now, but include button later
    my $include_details    = ( $args{-include_details} ? 1 : 0 ) || $include_references;                      ## include details by default (generally needed)
    my $configs_ref        = $args{-configs_ref};
    my $simple             = $args{-simple};
    my $add_option         = $args{-add_option};
    my $return_html        = $args{-return_html};

    my $field_width          = 40;
    my $date_field_width     = 15;
    my $datetime_field_width = 25;
    my $int_field_width      = 5;
    my $output               = '';

    my $target = param('Target') || 'Database';

    my %grey;
    my %preset;

    if ( $configs_ref && exists $configs_ref->{'grey'} ) { %grey = %{ $configs_ref->{'grey'} } }

    if ( $id =~ /^\'(.*)\'$/ ) { $id = $1; }    ## get rid of quotes if included...
    if ( $id =~ /^\"(.*)\"$/ ) { $id = $1; }    ## get rid of quotes if included...

    my @split_list    = @$list;
    my @table_prompts = $dbc->getprompts($table);
    my @table_fields  = $dbc->get_fields( $table, undef, 'defined' );     ### (was get_defined_fields) ##
    my $table_id      = $alDente::SDB_Defaults::Primary_fields{$table};
    $table_id ||= join ',', $dbc->get_field_info( $table, undef, 'Primary' );

    my @actual_fields = ();
    my @table_types;                                                      ### array of field types to identify enumerated fields, and sets.
    foreach my $field (@table_fields) {
        if ( $field =~ /^(.*) as (.*)$/i ) {
            $field = $1;

            #	    push(@table_prompts,$2);
        }
        else {

            #	    push(@table_prompts,$field);
        }
        push( @actual_fields, $field );
        my @info = $dbc->get_field_types( $table, $field );
        if ( $info[0] =~ /(.*)\t(.*)/ ) {
            push( @table_types, $2 );
        }
    }

    my ($fk) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Reference = '$table_id'" );
    my $list_item = 1;
    foreach my $item_found (@split_list) {
        ( my $show_item ) = $dbc->get_FK_info( $fk, $item_found );
        $show_item ||= $item_found;    ## default to simple id if not foreign key.

        if ( !$simple ) {
            $output .= submit( -name => "Get Page", -value => $show_item, -class => "Search" ) . " ";
        }
        $list_item++;
    }
    my %Preset;
    if ($id) {

        my %values = $dbc->Table_retrieve( $table, \@actual_fields, "where $table_id = '$id'", -date_format => 'SQL' );
        my (@field_info) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Reference = '$table_id'" );

        foreach my $key ( keys %values ) {
            my $value = $values{$key}[0];
            if ( $value && $Field_Info{$table}{$key}{Editable} =~ /no/ ) {
                ## grey out fields which are not editable ##
                $grey{$key} = $value;
            }
            elsif ( $value && $Field_Info{$table}{$key}{Editable} =~ /admin/ && !$dbc->admin_access() ) {
                ## grey out fields which are not editable ##
                $grey{$key} = $value;
            }
            else {
                $Preset{$key} = $value;
            }
        }
    }

    my %require;
    if ( param('Require') ) {
        my $required = join ',', param('Require');    ## either comma-delim or array
        foreach my $ensure ( split ',', $required ) {
            $require{$ensure} = 1;
        }
    }
    my $primary_value = param('Search List');
    if ( !$simple ) {
        &Link_To( $dbc->config('homelink'), "(Edit History)", "&Change+History+All=1&primary=$primary_value", $Settings{LINK_LIGHT}, ['newwin'] );
    }

    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target, -wrap => 0, -db_action => 'edit', -add_option => $add_option);

    $form->configure( -preset => \%Preset, -require => \%require, -grey => \%grey );
    $form->configure(%$configs_ref) if $configs_ref;

    $output .= $form->generate( -title => "Edit $table Form ", -submit => 0, -end_form => 0, -start_form => 0, -form => 'SearchEdit', -return_html => 1, -navigator_on => 0 );    ### no start or end_form (so we need to supply form name)
    if ( $id && $include_references && !$simple ) {
        my ( $ref_list, $detail_list ) = $dbc->get_references( $table, { $table_id => $id } );

        if ($ref_list) {
            $output .= "Referenced By: " . $ref_list . '<P>';
        }
        else {
            $output .= "Referenced By: (nothing)<P>";
            if ( !$Security or ( grep /^D|O$/i, @{ $Security->get_table_permissions( -table => $table ) } ) ) {                                                                   # Allow delete if user has Delete (D) or Owner (O) permission on this table
                $output .= hidden( -name => 'Mark', -value => $id ) . hidden( -name => 'Mark_Field', -value => $table_id ) . submit( -name => 'Delete Record', -value => 'Delete Record', -class => 'Action' ) . "<p ></p>";
            }
        }

        $output .= "Details: " . $detail_list . '<P>' if $detail_list;
    }

    unless ($return_html) { print $output }
    return $output;
}

############################
# Adding a Database Records
############################

##################
sub add_record {
##################
    #
    # Add record to existing table
    #
    my %args = &filter_input( \@_, -args => 'dbc,table,parameters,configs,groups' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table       = $args{-table};                                                                   # table to add to
    my $parameters  = $args{-parameters};
    my $configs     = $args{-configs};                                                                 # Form configurations (e.g. preset, list, grey, etc)
    my $groups      = $args{-groups};                                                                  ## specify groups to allow easier permission parsing.
    my $return_html = $args{-return_html};                                                             ##
    my $user_id     = $dbc->get_local('user_id');

    my $target = param('Target');

    #    my $last_page = param('Last Page');      ### fix (necessary ?)

    unless ($table) { Message("Require Table Name"); return 0; }

    #    my $output = subsection_heading("Add $table Record");
    my $output;

    if ( param('Show Current List if') ) {
        ### include option to show current list above new entry form ### (condition supplied in 'Show Current List if' parameter) ###
        my $condition = param('Show Current List if');
        $output .= Table_retrieve_display( $dbc, $table, ['*'], "WHERE $condition", -title => "Current applicable $table records", -return_html => 1 );
    }

    my $form = new LampLite::Form( -dbc => $dbc );

    my %require;
    if ( param('Require') ) {
        my $required = join ',', param('Require');    ## either comma-delim or array
        foreach my $ensure ( split ',', $required ) {
            $require{$ensure} = 1;
        }
    }

    ## form is automatically wrapped with form tags ##
    unless ($target) {
        if ( $dbc->check_permissions( $user_id, $table, 'add' ) ) {
            $target = 'Database';
        }
        else {
            $target = 'Submission';
        }
    }

    my $object_class = param('Object_Class');
    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target, -groups => $groups );

    if ($configs) { $form->configure(%$configs) }

    $output .= $form->generate( -action => 'add', -return_html => 1, -object_class => $object_class );

    unless ($return_html) { print $output }
    return $output;
}

###########################
sub append_table_form {
###########################
    my $dbc        = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table      = shift;                                                                     # table to add to
    my $parameters = shift;

    my $field_width          = 40;
    my $wide_field_width     = 80;
    my $date_field_width     = 15;
    my $datetime_field_width = 25;
    my $int_field_width      = 5;

    my $search = 1;                                                                             # set up search on fields automatically (specify list of fields ?)
    my %P;
    if ($parameters) { %P = %{$parameters}; }

    my @table_prompts = getprompts( $dbc, $table );
    my @table_fields = get_fields( $dbc, $table, undef, 'defined' );                            ## (was get_defined_fields ) ##
    my $fields = scalar(@table_fields) - 1;
    my @table_types;
    foreach my $field (@table_fields) {
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;

            #	    push(@table_prompts,$2);
        }
        else {

            #	    push(@table_prompts,$field);
        }
        my @info = &get_field_types( $dbc, $table, $field );
        if ( $info[0] =~ /(.*)\t(.*)/ ) {
            push( @table_types, $2 );
        }
    }

    my $Append = HTML_Table->new();

    my $forces = 0;    ### index of forced Search fields..

    for my $index ( 0 .. $fields ) {
        my $prompt = $table_prompts[$index];
        my $field  = $table_fields[$index];
        my $default;
        if   ( defined $P{$field} ) { $default = $P{$field}; }
        else                        { $default = ''; }

        if ( param($field) ) { $default = param($field); }    ### set possible defaults...
        ############ don't supply textfield for autoincremented ID field... #########
        if ( $field =~ /$table[_]ID/ ) {

            #$Append->Set_Row([$prompt,'(autoincremented)']);
        }
        elsif ( my ( $ref_table, $ref_field ) = foreign_key_check( -dbc => $dbc, -field => $field ) ) {
            my $FKnote;
            if ( $dbc->barcode_prefix($ref_table) ) { $FKnote = "<B>Scan field</B>"; }

            #else {$FKnote = "<B>Foreign key values only!</B>";}
            $default = get_FK_info( $dbc, $field, $default );

            if ( $field =~ /Plate__ID/ ) {
                $Append->Set_Row( [ $prompt, "LINK <font size=-2>$FKnote</Font>" ] );

                # ?		    $Append->Set_Row([$prompt,'LINK']);
                $Append->Set_Link( 'text', $field, $field_width, $default );    #### NO Menu Search for initial search
            }
            else {
## allow menu sear
                my @fk_list = get_FK_info( $dbc, $field, -list => 1 );          ### was list

                ##### Custom Insertion (reduct options) ####################################
                if ( $field =~ /FK_Primer__Name/ || $field =~ /FK_Primer__ID/ ) {
                    @fk_list = &Table_find( $dbc, 'Primer', 'Primer_Name', "where Primer_Type IN ('Standard','Adapter') AND Primer_Status <> 'Inactive'" );
                }

                ##### End Custom Insertion (reduct options) ####################################

                ######## get default value from view list or from ID #########
                if ( $default && ( $#fk_list > 0 ) ) {
                    ( my $newdefault ) = grep /^$default/, @fk_list;
                    if ($newdefault) { $default = $newdefault; }
                    else             { ($default) = get_FK_info( $dbc, $field, $default ); }
                }

                ### if list is too long leave as textfield
                my $max = $Settings{FOREIGN_KEY_POPUP_MAXLENGTH};
                if ( $#fk_list > $max ) {
                    $Append->Set_Row( [ $prompt, "LINK <font size=-2>($FKnote)</font>" ] );
                    $Append->Set_Link( 'text', $field, $field_width, $default );
                }
                #### if Prefix defined (barcodable items... ####
                elsif ( $search && ( $#fk_list > 0 ) && ( $dbc->barcode_prefix($ref_table) ) ) {
                    $Append->Set_Row( [ $prompt, "LINK <font size=-2>$FKnote</font> LINK<BR>LINK" ] );
                    $Append->Set_Link( 'text', 'SearchString', 10, '', "MenuSearch(document.Append,0)" );
                    $Append->Set_Link( 'hidden', "ForceSearch$forces", 'Search' );
                    $Append->Set_Link( 'popup', $field, [ '', @fk_list ], $default );
                }
                elsif ( $#fk_list > 0 ) {
                    $Append->Set_Row( [ $prompt, 'LINK' ] );
                    $Append->Set_Link( 'popup', $field, [ '', @fk_list ], $default );
                }
                else {
                    $Append->Set_Row( [ $prompt, "LINK <font size=-2>($FKnote)</font>" ] );
                    $Append->Set_Link( 'text', $field, $field_width, $default );
                }
                $forces++;
            }
        }
        elsif ( $table_types[$index] =~ /^set/ ) {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            if ( param($field) ) { $default = param($field); }    ### set possible defaults...
            my @enum_list = get_enum_list( $dbc, $table, $field );
            $Append->Set_Link( 'list', $field, [ "", @enum_list ], $default );

            #	    $Append->Set_Link('text',$field,$field_width);
        }
        elsif ( $table_types[$index] =~ /^enum/ ) {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            if ( param($field) ) { $default = param($field); }    ### set possible defaults...
            my @set_list = get_enum_list( $dbc, $table, $field );

            #	    $Append->Set_Link('popup',$field,["",@set_list]);
            $Append->Set_Link( 'popup', $field, [@set_list], $default );
        }
        ########### Custom Insertion to specify types of input for various fields... ##############
        elsif ( $Field_Info{$table}{$field}{Type} =~ /datetime/i ) {
            $Append->Set_Row( [ $prompt, 'LINK <font size=-2>(YYYY-MM-DD HH:MM)</font>' ] );
            $Append->Set_Link( 'text', $field, $datetime_field_width, convert_date( &now(), 'Simple' ) );
        }
        elsif ( $Field_Info{$table}{$field}{Type} =~ /date/i ) {
            $Append->Set_Row( [ $prompt, 'LINK <font size=-2>(YYYY-MM-DD) or (Mon-DD-YYYY)</font>' ] );
            $Append->Set_Link( 'text', $field, $date_field_width, convert_date( &today(), 'Simple' ) );
        }
        elsif ( $Field_Info{$table}{$field}{Type} =~ /time/i ) {
            $Append->Set_Row( [ $prompt, 'LINK <font size=-2>HH:MM or Min.Sec</font>' ] );
            $Append->Set_Link( 'text', $field, $date_field_width, '', 'Simple' );
        }
        elsif ( $field =~ /_(Description|Notes|Comments|Instructions)/ ) {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            $Append->Set_Link( 'box', $field, "4x$field_width", $default );
        }
        elsif ( $field =~ /_Text/ ) {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            $Append->Set_Link( 'box', $field, "2x$field_width", $default );
        }
        elsif ( $table_types[$index] =~ /^int/ ) {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            $Append->Set_Link( 'text', $field, $int_field_width, $default );
        }

        ########### End Custom Insertion #############################
        else {
            $Append->Set_Row( [ $prompt, 'LINK' ] );
            $Append->Set_Link( 'text', $field, $field_width, $default );
        }
    }

    if ( $table =~ /(.*)_Batch/ ) {
        $Append->Set_Row( [ "Number in Batch: ", 'LINK' ] );
        $Append->Set_Link( 'text', "Number in Batch", $int_field_width, 1 );
    }

    $Append->Printout();
    return 1;
}

############################
sub parse_to_table {
############################
    #
    #  ADD textfield as optional fill in field...
    #

    my $dbc   = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = shift;
    my $file  = shift;

    my @fields = &get_fields( $dbc, $table );

    open( PARSE, "$file" ) or print "Cannot open";

    my $field_width = 20;

    my $firstline  = <PARSE>;
    my $secondline = <PARSE>;
    my $index      = 1;
    print subsection_heading("First Line in File: "), '<BR>';

    print "\n<Table width = 80%>\n<TR>\n<TD bgcolor = $Settings{STD_BUTTON_COLOUR}>";
    print subsection_heading("FIELDS");
    foreach my $column ( split '\t', $firstline ) {
        print "$index: $column", '<BR>';
        $index++;
    }

    print "</TD>\n<TD bgcolor = lightyellow>";

    $index = 1;
    print subsection_heading("DATA");
    foreach my $column ( split '\t', $secondline ) {
        print "$index: $column", '<BR>';
        $index++;
    }
    print "</TD></TR></Table>";

    print "Parse into ...";

    print alDente::Form::start_alDente_form( $dbc);

    print "Position in File: (leave blank if not included)", '<BR>';
    foreach my $thisfield (@fields) {
        print textfield( -name => "FP:$thisfield", -size => 3, -force => 1, -default => "" ), " $thisfield", " (or set to:", textfield( -name => "Fix:$thisfield", -size => $field_width, -force => 1, -default => "" ), " )", '<BR>';
    }

    print "Header Lines: ", textfield( -name => 'Header Lines', -size => 3, -default => '1' );
    print submit( -name => 'Parse File' ), ": ";
    print hidden( -name => 'FileName',  -value => $file );
    print hidden( -name => 'TableName', -value => $table );
    print "\n</Form>";
    return 1;
}

#########################
sub get_references_old {
#########################
    #
    #  Find other tables that point to this table...
    #
    #
    my $dbc    = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table  = shift;
    my $hash   = shift;                                                                     ## optionally specify 'field=>id'  (allows reference to specific record(s) to be returned)
    my $detail = shift;

    #    my $idfield = shift;   ### old method...
    #    my $index = shift;   ## optionally return specific id value to check for..

    my %Specs;
    if ($hash) { %Specs = %$hash; }

    my @checks = &Table_find( $dbc, 'DBField,DBTable', 'DBTable_Name,Field_Name,Foreign_Key,DBTable_Type', "where FK_DBTable__ID=DBTable_ID AND Foreign_Key like '$table.%'" );
    my @conditions = (1);    ### fill list of conditions (generally only one like 'FK_Employee__ID = 25')

    if ($hash) {
        foreach my $key ( keys %Specs ) {
            my $value = $Specs{$key};
            push( @conditions, "$key = '$value'" );
        }
    }
    my $condition = join ' AND ', @conditions;

    my %Ref;
    my %Type;
    foreach my $check (@checks) {
        my ( $Rtable, $Rfield, $fkname, $type ) = split ',', $check;
        my $tables = "$table,$Rtable";
        if ( $Rtable eq $table ) { $tables = $table; }    #### dont list table twice if it the same one...(checking recursive references)

        if ($hash) {
            my $condition = "WHERE $Rtable.$Rfield=$fkname and Length($fkname) > 0 AND $fkname IS NOT NULL AND $condition";
            my @found = &Table_find( $dbc, "$tables", $fkname, $condition );
            if ( @found && ( $found[0] =~ /[1-9a-zA-Z]/ ) ) { push( @{ $Ref{"$Rtable:$Rfield"} }, @found ); }
        }
        else { push( @{ $Ref{"$Rtable:$Rfield"} }, $fkname ) }
        $Type{"$Rtable:$Rfield"} = $type;
    }
    my @ref_list;
    my @detail_list;
    foreach my $key ( keys %Ref ) {
        my ( $ref_tab, $ref_fld ) = split ':', $key;
        my $ref_id = join ',', @{ unique_items( $Ref{$key} ) };

        my $reference = &Link_To( $dbc->config('homelink'), "$ref_tab", "&Database_Mode=$dbc->{mode}&Info=1&Table=$ref_tab&Field=$ref_fld&Like=$ref_id", $Settings{LINK_COLOUR}, ['newwin'] );
        if ( $Type{$key} =~ /Detail/i ) {
            push( @detail_list, $reference );
        }
        else {
            push( @ref_list, $reference );
        }
    }
    my $refs    = join ',', @ref_list;
    my $details = join ',', @detail_list;
    my @returnvals = ( $refs, $details );
    return @returnvals;
}

##########################
# Table Viewing routines
##########################

#####################
sub view_records {
#####################
    # CHANGE to arguments for parameters
    #
    # provide view of records in given table given (field = value)
    #

    my %args = &filter_input( \@_, -args => 'dbc,table,field,value,condition,options' );
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table              = $args{-table};
    my $field              = $args{-field};
    my $value              = $args{-value};
    my $original_condition = $args{-condition} || 1;
    my $option_list        = $args{-options};                                                                 #### allow options ('hide','rows','columns','add_new') 'expand' (include conn. tables)
    my $fields             = $args{-fields};

    my $homelink = $dbc->homelink();

    my $stamp  = timestamp();
    my $file   = $dbc->config('tmp_web_dir') . "/view.$stamp.html";
    my $header = $html_header;

    my @options            = split ',', $option_list;
    my $include_references = 0;                                                                               ## faster if excluded...
    if ( $value && ( $value !~ /,/ ) ) { $include_references = 1 }                                            ## include if only one record being displayed...
    if ( grep /references/i, @options ) {
        $include_references = 1;
    }

    my $def_Orientation = param('Display By');
    if ( grep /rows/,    @options ) { $def_Orientation = "List in Rows"; }
    if ( grep /columns/, @options ) { $def_Orientation = "List in Columns"; }

    unless ($table) { Message("No Table specified"); return 0; }

    my $FKeys = param('FKeys') || 0;
    my $limit = param('List Limit') || $Settings{RETRIEVE_LIST_LIMIT} || 200;
    my $limit_index = param('Index');
    if ( param('New View Index') ) {
        my $newindex = param('New View Index');
        if ( $newindex =~ /(\d+) - (\d+)/ ) {
            $limit_index = $1 - 1;
        }
    }
    
    my $order = param('Order By') || '';
    if ($order) { print "Ordering by $order<BR>"; }

    my @tables = split ',', $table;
    my $main_table = $tables[0];

    my $condition;
    if ( $original_condition =~ /^where /i ) {
        $condition = $original_condition;
    }
    else {
        $condition = "WHERE $original_condition";
    }

###### Get Fields #########
    my @table_fields;
    if ($fields) { @table_fields = &Cast_List( -list => $fields, -to => 'array' ) }
    else         { @table_fields = get_fields( $dbc, $table, undef, 'defined' ) }    ##

    unless ( int(@table_fields) ) { Message("$table Fields not found"); return; }

###### Get Field Labels #########

    my $IDfield = $Primary_fields{$table};
    unless ( $IDfield =~ /\S/ ) {
        ($IDfield) = &get_field_info( $dbc, $main_table, undef, 'Primary' );
    }

    ### custom setting.. ###
    if ( $main_table =~ /Clone_Sequence/ ) {
        $IDfield ||= "concat(FK_Run__ID,':',Well)";
    }

    my $IDlabel = $IDfield;

    my $add_id = 1;                       ### add id field to displayed fields...
    my $list = join ',', @table_fields;

    my $max_columns = 2;                  ### auto-set to rows if number of columns > max_columns..

    my %row_array;
    my @value_list = split ',', $value;
    my @qvalue_list = map { $dbc->dbh()->quote($_) } @value_list;
    my $quoted_value = join ',', @qvalue_list;

    my $tables = $table;

    my @extra_headers = ();
    ## Custom Insertion (values included in retrieve) ##
    #if ($main_table eq 'Project') {
    #	push(@table_fields,'Organization_ID');
    #	push(@extra_headers,'Collaborators:');
    #	$tables .= " left join Collaboration on FK_Project__ID=Project_ID left join Organization on FK_Organization__ID=Organization_ID";
    #    }

    my ( $references, $details );

    if ($include_references) {
        ( $references, $details ) = $dbc->get_references($table);

        push( @extra_headers, 'Details->' );
        push( @extra_headers, 'Ref_By->' );
    }

    my $search_list;
    if ( param('Search List') ) {
        $search_list = param('Search List');
    }

    #    if ($search_list) {$condition .= " and $IDfield in ($search_list)"; }

    if ( $value =~ /%/ ) {
        $condition .= " AND $table.$field LIKE $quoted_value";
    }
    elsif ( $field && $value ) {
        $condition .= " AND $table.$field in ($quoted_value)";
    }

    my $limit_condition = "";
    if ( $limit =~ /\d+/ ) {
        if   ($limit_index) { $limit_condition = "LIMIT $limit_index,$limit"; }
        else                { $limit_condition = "LIMIT $limit"; }
    }

    my $order_condition = "";
    if ($order) { $order_condition = "ORDER BY $order"; }

    my @finds = &Table_find( $dbc, $tables, $IDfield, "$condition" );

    my $total_count = int(@finds);
    $search_list = join ',', @finds;

    if ( $total_count > 1 ) { print "Found $total_count" }    ## don't print this out for standard data printouts..
    unless ($total_count) { Message("No records found matching specifications"); return; }
    my @headers = @table_fields;
    map {
        my $input     = $_;
        my $realfield = $input;
        my $label;
        my $tip;
        if ( $input =~ /(.*) as (.*)/i ) {
            $realfield = $1;
            $label     = $2;
        }
        else {
            my ( $this_table, $this_field ) = simple_resolve_field($input);
            my ( $ref_table, $ref_field, $desc ) = foreign_key_check( -dbc => $dbc, -field => $this_field ) if $this_field;

            if ( defined $Field_Info{$this_table} && defined $Field_Info{$this_table}{$this_field} ) {
                $tip   = $Field_Info{$this_table}{$this_field}{Description};
                $label = $Field_Info{$this_table}{$this_field}{Prompt};
            }
            elsif ($ref_table) {
                $desc .= ' ' if $desc;    ## add space if desc included
                $label = $desc . $ref_table;
            }
            else {
                $label = $input;
            }
        }

        my $neworder = $order;
        if ( $order =~ /$realfield ASC/ ) {
            $neworder = "$realfield+DESC";
        }
        else { $neworder = "$realfield+ASC"; }

        if ( $total_count > 1 ) {
            my @keys = keys %{ $Field_Info{Issue}{'FKSubmitted_Employee__ID'} };

            $_ = &Link_To( $dbc->config('homelink'), $label, "&Info=1&Table=$table&Field=$IDfield&Like=$search_list&Order+By=$neworder", 'black', -tooltip => $tip );
        }
        else { $_ = $label }    ## don't bother re-ordering if only one record...
    } @headers;    ##  get_fields($dbc,$table,undef,'defined'); ## (was get_defined_fields ) ##

    push( @headers, @extra_headers );
    if ( ( my $ID ) = grep /^($main_table\.|)$IDfield/, @table_fields ) {
        if ( $ID =~ /(.*) as (.*)/i ) { $IDfield = $1; $IDlabel = $2; }

    }
    else {
        @table_fields = ( $IDfield, @table_fields );
        my $thisheader = $IDfield;
        if ( $IDfield =~ /$table[_](.*)/ ) { $thisheader = $1; }    ### omit Table name from field heading...
        @headers = ( $thisheader, @headers );
    }
    %row_array = &Table_retrieve( $dbc, $tables, \@table_fields, "$condition $order_condition $limit_condition" );

    $testing = 0;
    if ( defined $row_array{$IDlabel}[$max_columns] ) {
        $def_Orientation ||= "List in Rows";                        ### default if many records..
    }
    else {
        $def_Orientation ||= "List in Columns";
    }

    if ( $total_count > 1 ) {
        print ' ' . &Link_To( $dbc->config('homelink'), '(Edit these records)', "&Edit+Table=$table&Field=$IDfield&Like=$search_list", $Settings{LINK_COLOUR}, ['newwin'] ) . br;
    }
    else {
        print ' '
            . &Link_To( $dbc->config('homelink'), 'Edit this record', "&Search=1&Table=$table&Search+List=$search_list", $Settings{LINK_COLOUR}, ['newwin'] )
            . hspace(20)
            . Link_To( $dbc->config('homelink'), 'View Edits', "&cgi_application=SDB::DB_Object_App&rm=View+Changes&Table=$table&ID=$search_list" );
    }

    my $Info = HTML_Table->new();
    $Info->Set_Class('small');
    $Info->Set_Title("<B>$table Information</B>");

    if ( $def_Orientation =~ /Column/i ) {
        $Info->Set_Column( [@headers] );
    }
    else {
        $Info->Set_Headers( [@headers] );
    }
    my $cols  = scalar(@table_fields);
    my $index = 0;

    my $start;
    if ( $row_array{$IDlabel}[$index] ) { $start = $row_array{$IDlabel}[$index]; }

    my @keys = keys %row_array;
    my @ids;
    my $max_width = 100;
    my %IDs       = {};

    my @include_tables = ();    ### used if Batch field referenced
    my @include_ids    = ();    ### batch id

    my $ref_list;               ### keep outside, so it can be checked if only 1...
    my $detail_list;
    my %prev_values;

    #forcing records to be display in the order of value that entered
    #by getting a hash that has order and acutal index in the data array
    my @value = split( ",", $value );
    my %index_value = map { $_ => { "sort_order" => $index++ }; } grep {$_} @value;
    $index = 0;

    #Going through the data array and get its index
    while ( defined $row_array{$IDlabel}[$index] ) {
        my $id = $row_array{$IDlabel}[$index];
        unless ($id) { $index++; next; }
        $index_value{$id}{sort_index} = $index;
        $index++;
    }

    #while ( defined $row_array{$IDlabel}[$index] ) {
    for my $key ( sort { $index_value{$a}{sort_order} <=> $index_value{$b}{sort_order} } keys %index_value ) {
        $index = $index_value{$key}{sort_index};
        if ( !defined $index ) {next}
        my $id = $row_array{$IDlabel}[$index];

        #unless ($id) { $index++; next; }
        my @record;
        my $thisfield;
        my $thislabel;
        foreach my $col ( 1 .. $cols ) {
            my $Tfield = $table_fields[ $col - 1 ];
            if   ( $Tfield =~ /(.*) as (.*)/i ) { $thisfield = $1;      $thislabel = $2; }
            else                                { $thisfield = $Tfield; $thislabel = $Tfield; }
            if ( $thislabel =~ /(\w+)\.(\w+)/ ) { $thislabel = $2; }    ## extract specific field if table included <CONSTRUCTION> added
            my $val = $row_array{$thislabel}[$index];
            my ( $sub_table, $Sfield ) = foreign_key_check( -dbc => $dbc, -field => $thisfield );
            my $FKval;
            if ( $sub_table && $Sfield ) {

                if ( !exists $prev_values{$thisfield}{$val} ) {
                    $val ||= '';
                    ($FKval) = get_FK_info( -dbc => $dbc, -field => $thisfield, -id => $val );
                    $prev_values{$thisfield}{$val} = $FKval;
                }
                else {
                    $FKval = $prev_values{$thisfield}{$val};
                }
            }

            if ( $thisfield =~ /Object_ID$/ ) {
                my $class_id = $row_array{'Object_Class__ID'}[$index];
                my $object_class = &get_FK_info( $dbc, "FK_Object_Class__ID", $class_id );
                $val = get_FK_info( -dbc => $dbc, -field => "FK_${object_class}__ID", -id => $val );
            }

            if ( $thislabel eq $IDlabel ) {
                push( @record, &Link_To( -link_url => $homelink, -label => $val, -param => "&HomePage=$table&ID=$id", -colour => $Settings{LINK_COLOUR}, -window => ['newwin'] ) );
            }
            elsif ( $sub_table && ( $FKval =~ /[a-zA-Z0-9]/ ) ) {
                $val =~ s/\s/+/g;

                if ( $FKval =~ /undef/ ) {
                    push( @record, $FKval );
                }
                else {
                    $thisfield =~ /(^|_)([a-zA-Z]+)$/;

                    #my $unique_identifier = $2 . "=$val";
                    #<CONSTRUCTION> always use ID if FK is defined. need to test if works for all non-fk_id field (e.g., FK_Branch__Code)
                    my $unique_identifier = "ID=$val";
                    my $link = &Link_To( -link_url => $homelink, -label => $FKval, -param => "&HomePage=$sub_table&$unique_identifier", -colour => $Settings{LINK_COLOUR}, -window => ['newwin'] );
                    push( @record, $link );
                }
            }
            elsif ( length($val) > $max_width ) {
                $val = substr( $val, 0, $max_width ) . ".....";
                push( @record, $val );
            }
            elsif ( !( $val =~ /\S/ ) ) { $val = "-"; push( @record, $val ); }
            else                        { push( @record, $val ); }

            if ( $thislabel =~ /$IDlabel/ ) {
                push( @{ $IDs{$main_table} }, $val );
            }
        }

        ###### Check for other tables pointing to these records... ###########
        #	if ($FKeys || $total_count < 3) {

        if ($include_references) {
            ( $ref_list, $detail_list ) = $dbc->get_references( $table, { $IDfield => $id } );

            if ($detail_list) {    ## references to this record
                push( @record, $detail_list );
            }
            elsif ($details) { push( @record, 'none' ); }    ## push blank field if details may exist
            else             { push( @record, '' ); }        ## push 'n/a' if no details defined

            if ($ref_list) {                                 ## references to this record
                push( @record, $ref_list );
            }
            elsif ($references) { push( @record, 'none' ); }    ## push blank field if references may exist
            else                { push( @record, '' ); }        ## push 'n/a' if no references defined
        }

        if ( $def_Orientation =~ /column/i ) {
            $Info->Set_Column( \@record );
        }
        else {
            $Info->Set_Row( \@record );
        }

        #$index++;
        #$start = $row_array{$IDfield}[$index];
        push( @ids, $id );
    }

    unless ( $#ids >= 0 ) {
        my $output .= "<B>No $table Data Found ($condition)</B>";
        if ( grep /add_new/, @options ) {
            $output .= alDente::Form::start_alDente_form( $dbc);
            $output .= submit( -name => 'New Entry', -value => "New $table", -class => "Search" ) . "</FORM>";
        }
        return $output;
    }

    my $output = $Info->Printout( $file, $header );
    $output .= $Info->Printout(0);
    $output .= &vspace(2);

    ### include link to show references if desired ###
    if ($include_references) {
    }
    else {
        my $params = "&Info=1&Table=$table&Condition=$original_condition&Options=$option_list,References";
        if ($fields) { $params .= "&Fields=" . join ',', @table_fields }    ## add list of fields if supplied
        if ($field)  { $params .= "&Field=$field" }
        if ($value)  { $params .= "&Like=$value" }
        $output .= &Link_To( $dbc->config('homelink'), 'Show References', $params, $Settings{LINK_COLOUR}, ['newwin'] );
        $output .= " (references must be checked before deletion option is possible)";
    }
    $output .= &vspace(3);

    ### include link to home page
    my $ids = join ',', @ids;
    $output .= &Link_To( $dbc->config('homelink'), 'Home Page', SDB::HTML::home_URL( $table, $ids ), $Settings{LINK_COLOUR} );
    $output .= &vspace(3);

    my $found = $#ids + 1;
    if ( $total_count >= $limit ) {
        $output .= "Only displaying $limit records at a time (of $total_count)";
    }
    elsif ( $total_count > 1 ) { $output .= "<B>Found $total_count Record(s)</B>"; }

    ############# Custom Insertion (values appended to info) ####################

    my $print_label;
    if ( $Barcode{$table} && ( $total_count == 1 ) ) {
        my $id = $row_array{$IDlabel}[0];
        $print_label = alDente::Form::start_alDente_form( $dbc ) . hidden( -name => $table . "_ID", -value => $id ) . submit( -name => 'Barcode_Event', -value => "Re-Print $table Barcode", -class => "Std" ) . end_form();
    }

    ## <CONSTRUCTION> - remove hardcoded customization ...
#    if (($main_table eq 'Sequencing_Library') && $found==1) {
#	 my $Vprimers = join ',', &Table_find($dbc,'Library,LibraryVector,Primer,Vector_TypePrimer','Primer_Name',$condition,'distinct');
#	 if ($Vprimers) {$output .= "<BR><B>Valid Primers: $Vprimers </B>";}
#
#	 my $Sprimers = join ',', &Table_find($dbc,'Sequencing_Library left join LibraryPrimer on Sequencing_Library.FK_Library__Name=LibraryPrimer.FK_Library__Name left join Primer on FK_Primer__Name=Primer_Name','Primer_Name',$condition,'distinct');
#	 $Sprimers=~s/[,]+/,/g;
#	 if ($Sprimers) {$output .= "<BR><B>Suggested Primers: $Sprimers </B>";}
#    }
#    elsif (($main_table eq 'Solution') && ($found==1)) {
#	my $Reagents = join ',', &Table_find($dbc,'Mixture,Solution','FKUsed_Solution__ID',"$condition AND FKMade_Solution__ID=Solution_ID");
#	if ($Reagents) {
#	    &Table_retrieve_display($dbc,'Solution,Stock,Mixture',['FK_Stock__ID as Stock','Mixture.Quantity_Used as Used','Units_Used as Units'],"where FK_Stock__ID=Stock_ID AND FKMade_Solution__ID=$ids[0] AND Solution_ID=FKUsed_Solution__ID",undef,'Components of Solution');
#	    print "(click on 'Mixture' link below for more info)";
#	    print &vspace(10);
#	}
#    }
    ############# End Custom Insertion ####################

    my $id_list;
    if ( $IDs{$main_table} ) { $id_list = join ',', @{ $IDs{$main_table} }; }    ### main id

    unless ( grep /hide/i, @options ) {                                          ###
        $output .= "\n" . &vspace(5) . "<Table>";

        foreach my $thistable ( split ',', $table ) {
            my $id_list;
            if ( $IDs{$thistable} ) { $id_list = join ',', @{ $IDs{$thistable} }; }

            my $edit_form = "Search";                                            ### nicer form for multiple entries..
            if ( $id_list =~ /,/ ) { $edit_form = "Edit_Records"; }
            elsif ( !$id_list ) { $edit_form = "Search for"; }

            $output .= "<TR><TD>";

            $output .= alDente::Form::start_alDente_form( $dbc);

            if ($nav) {                                                          
                ### only if navigation functionality set (On for most internal users)
                $output .= submit( -name => 'New Entry', -value => "New $thistable", -class => "Search" ) . "</TD><TD>" .

                    #			submit(-name=>$edit_form,-value=>"Edit $thistable",-class=>"Search").
                    #			    "</TD><TD>".
                    submit( -name => 'Search for', -value => 'Search', -class => "Search" ) . "</TD><TD>" . checkbox( -name => 'Multi-Record', label => 'Multi-Record' );

                #### if only one record shown, allow Deletion if not referenced...
                if ( $include_references && !( $id_list =~ /,/ ) ) {
                    $output .= "</TD></TR><TR><TD colspan=2>";
                    if ($ref_list) { $output .= "<Font color=red> Cannot Delete (FKeys)</Font>"; }
                    else {
                        $output .= hidden( -name => 'Mark', -value => $id_list ) . submit( -name => 'Delete Record', -value => 'Delete Record', -style => "background-color:red" );
                    }
                }
            }

            $output
                .= hidden( -name => 'Table',       -value => $thistable, -force => 1 )
                . hidden( -name  => 'Field',       -value => $field,     -force => 1 )
                . hidden( -name  => 'Like',        -value => $value,     -force => 1 )
                . hidden( -name  => 'Search List', -value => $id_list,   -force => 1 )
                . hidden( -name => 'PreviousCondition', -value => "$condition" )
                . "</TD></TR>"
                . "</Form>";
        }
        $output .= "</Table>";

        $output .= alDente::Form::start_alDente_form( $dbc ) .
            hidden( -name   => 'Table',    -value => $main_table,  -force => 1 )
            . hidden( -name => 'Field',    -value => $field,       -force => 1 )
            . hidden( -name => 'Like',     -value => $value,       -force => 1 )
            . hidden( -name => 'Order By', -value => $order,       -force => 1 )
            . hidden( -name => 'Index',    -value => $limit_index, -force => 1 )
            . hidden( -name => 'Search List', -value => $id_list );
        if ( $total_count > 1 ) {
            $output .= submit( -name => 'Info', -value => 'ReFresh Display', -class => "Std" ) . ' ' . radio_group( -name => 'Display By', -values => [ 'List in Columns', 'List in Rows' ], -default => $def_Orientation );

            #	if ($#ids>=$limit-1) {

            $output .= &vspace(2) . "Display Limit: " . textfield( -name => 'List Limit', -size => 5, -default => $limit, -force => 1 ) . &hspace(20);

            $output .= checkbox( -name => 'FKeys', -label => "Show FKeys-> Records", -checked => $FKeys ) . " (slower to reload)" . &vspace(2);
        }

        ## loop for each group... ##

        my $start_index   = 1;
        my $current_index = $limit_index + 1;
        my $buttons       = 0;
        my $button_width  = 10;

        while ( $start_index < $total_count ) {
            my $end_index = $start_index + $limit - 1;
            if ( $end_index > $total_count ) { $end_index = $total_count; }
            if ( $current_index > $end_index ) {    ## previous pages...
                $output .= submit( -name => 'New View Index', -value => "$start_index - $end_index", -class => "Std" ) . &hspace(2);
            }
            elsif ( $end_index > ( $current_index + $limit ) ) {    ## next pages...
                $output .= submit( -name => 'New View Index', -value => "$start_index - $end_index", -class => "Std" ) . &hspace(2);
            }
            else { $output .= "$start_index .. $end_index" . &hspace(2); }

            $start_index += $limit;
            $buttons++;
            if ( int( $buttons % $button_width ) == 0 ) { print "<BR>"; }
        }
        $output .= &vspace() . "\n</Form>";
    }

    $index = 0;
    foreach $index ( 0 .. $#include_tables ) {
        ( my $idfield ) = &get_field_info( $dbc, $include_tables[$index], undef, 'Primary' );
        $output .= &view_records( $dbc, $include_tables[$index], $idfield, $include_ids[$index] );
        $index++;
    }
    if ($print_label) { $output .= $print_label; }

    return $output;
}

###################
sub view_table {
################### (TEMPORARY to allow old code to access routine..
    my $dbc       = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables    = shift;                                                                     ## only primary table used for marks... (first in list)
    my $list      = shift;                                                                     ## optional field list (defaults to all)
    my $condition = shift;                                                                     ## SQL condition for generated list
    my $run_modes = shift;                                                                     ## optional arguments to mark other records (comma-delimited)
    return mark_records( $dbc, $tables, $list, $condition, $run_modes );
}

######################
# Display search form
#############################
sub display_search_form {
#############################
    my %args  = @_;
    my $table = $args{-table};

    my $form_searches_ref = $args{-form_searches};
    my $dbc               = $args{-dbc};
    my $homelink          = $dbc->homelink();

    my %form_searches;
    if ( ref($form_searches_ref) eq 'HASH' ) {
        %form_searches = %$form_searches_ref;
    }
    else {
        return;
    }

    my %parameters;
    $parameters{'url'}           = $homelink;
    $parameters{'Search_Target'} = "Info";

    $args{"-dbc"} ||= $Connection;
    $args{"-parameters"} = \%parameters;
    foreach my $setting ( keys %{ $form_searches{$table} } ) {
        my $value = $form_searches{$table}{$setting};
        $args{"-$setting"} = $value;
    }

    &Table_search(%args);
}

######################
sub mark_records {
######################
    #
    # Generate View of Table
    # (allowing viewer to Delete/Mark individual records
    #
    # The $run_modes variable allows the user to add custom buttons at the bottom of the page
    # (eg. if $run_modes = ['Fail Plate','Plate Note']
    #   - 'Fail Plate' and 'Plate Note' submit buttons will be added to the page.
    #
    # The form will also return:
    #   'Mark'. - (containing an array of primary fields selected)
    #   'ID Field' - the primary field used to generate the selected list (in 'Mark').
    #   'Mark Note' - text entered into the textfield at the bottom.
    #
    # (as well as standard parameters: User,
    #
    # <CONSTRUCTION> - use filter input with ref check for mark ..
    my %args = filter_input( \@_, -args => 'dbc,tables,list,condition,run_modes,include_references,add_html,onclick_hash' );

    my $dbc                = $args{-dbc};
    my $tables             = $args{-tables};                     ## only primary table used for marks... (first in list)
    my $list               = $args{-list};                       ## optional field list (defaults to all)
    my $condition          = $args{-condition};                  ## SQL condition for generated list
    my $run_modes          = $args{-run_modes};                  ## optional arguments to mark other records (comma-delimited)
    my $include_references = $args{-include_references} || 1;    ## leave on for now, but include button later
    my $add_html           = $args{-add_html};                   # additional html elements after the table and mark buttons.
    my $onclick_hash       = $args{-onclick_hash};               # (HashRef)[Optional] Optional onclick javascript for mark buttons
    my $application        = $args{-application};                # use run_modes as CGI_Application run modes
    my $preset             = $args{-preset};
    my $return_html        = $args{-return_html};
    my $final_output;
    my $std_buttons = $args{-std_buttons};                       # std options for delete, notes, edit (just include string including any of these)

    my $homelink = $dbc->homelink();

    my $edit   = ( $std_buttons =~ /edit/i );
    my $delete = ( $std_buttons =~ /delete/i );
    my $notes  = ( $std_buttons =~ /notes/i );

    my @headers;
    my @field_list;

    my $table = $tables;

    ### if more than one, get info from first listed...
    if    ( $tables =~ /^(\w+)\s*,/ )          { $table = $1; }
    elsif ( $tables =~ /^(\w+)\s*LEFT JOIN/i ) { $table = $1; }

    my @field_names;
    if   ($list) { @field_names = @$list; }
    else         { @field_names = get_fields( $dbc, $table ); }

    if ( $list =~ /\*/ ) {
        ### in case called as 'select * from ..'
        #	@headers = &getprompts($dbc,$table);
        @field_names = &get_fields( $dbc, $table, undef, 'defined' );    ## (was get_defined_fields ) ##
    }

    my $fieldref = $Primary_fields{$table} || join ',', &get_field_info( $dbc, $table, undef, 'Primary' );

    my $ref_included = 0;
    foreach my $thisfield (@field_names) {
        unless ($thisfield) {next}

        # if ($thisfield=~/(.+)\.(.+)/) {$thisfield = $2;}  # eliminate table name.
        if ( $thisfield =~ /(.*) as (.*)/i ) {
            push( @headers, $2 );
            my $original_field = $1;
            if ( $original_field =~ /(.*)\.(.*)/ ) { $original_field = $1; }
            if ( $original_field =~ /^$fieldref$/ ) { $ref_included++; }
            push( @field_list, $original_field );
        }
        elsif ( ( my $refTable, my $refField ) = foreign_key_check( -dbc => $dbc, -field => $thisfield ) ) {
            push @headers,    $refTable;
            push @field_list, $thisfield;
            if ( $thisfield =~ /^$fieldref$/ ) { $ref_included++; }
        }
        else {
            my $thisheader;
            if   ( $thisfield =~ /$table[_](.*)/ ) { $thisheader = $1; }
            else                                   { $thisheader = $thisfield; }
            push( @headers,    $thisheader );
            push( @field_list, $thisfield );
            if ( $thisfield =~ /^$fieldref$/ ) { $ref_included++; }
        }
    }

    unless ($ref_included) {
        push( @headers,     'ID' );
        push( @field_names, $fieldref );
        push( @field_list,  $fieldref );
    }

    ## TODO: need to understand why '' gets into the array sometimes
    @field_names = grep { $_ ne '' } @field_names;

    my %Retrieved = &Table_retrieve( $dbc, $tables, \@field_names, $condition );

    unless ( defined $Retrieved{ $field_names[0] } ) {
        Message( "No Records found matching search condition:", $condition );
        RGTools::RGIO::Test_Message( "Query: $condition", $testing );
    }

    #    $final_output .= "found primary field for $table: $fieldref";

    $final_output .= alDente::Form::start_alDente_form( $dbc, 'Mark_Records' );

    $final_output .= hidden( -name => 'TableName', -value => "$table" );

    #   hidden(-name=>'DB',-value=>"$dbc");
    my $colour;

    my $View = HTML_Table->new();
    $View->Set_Class('small');
    $View->Set_Title("Selected $table records");

    my $toggleBoxes = "ToggleNamedCheckBoxes(document.Mark_Records,'ToggleAll','Mark');return 0;";

    my $select = "select" . checkbox( -name => "ToggleAll", -label => '', -onClick => $toggleBoxes );    # select header
    my @set_headers = ( $select, @headers );
    my ( $references, $details );
    if ($include_references) {
        ( $references, $details ) = $dbc->get_references($table);                                        ## general for table..

        if ($details) {
            push( @set_headers, 'Details->' );
        }
        if ($references) {
            push( @set_headers, 'FKeys->' );
        }
    }
    $View->Set_Headers( \@set_headers );

    $final_output .= hidden( -name => 'Mark_Field', -value => $fieldref );                               ## indicate which field is being referenced by Mark values below
    my @primary_values = ();
    my $index          = 1;
    while ( defined $Retrieved{$fieldref}[ $index - 1 ] ) {
        $colour = toggle_colour($colour);
        my $dvalue = $Retrieved{$fieldref}[ $index - 1 ];
        push( @primary_values, $dvalue ) unless ( grep /^$dvalue/, @primary_values );

        my @nextrow = ( checkbox( -name => 'Mark', -value => $dvalue, -label => $index, -checked => $preset, -force => 1 ) );
        my $Findex = 0;
        foreach my $field (@field_names) {
            if ( $field =~ /(.*?)\.(.*)/ )  { $field = $2; }
            if ( $field =~ /(.*) as (.*)/ ) { $field = $2; }
            my $thisval = $Retrieved{$field}[ $index - 1 ];
            my $showval = $thisval;
            #### check original field_name for foreign key type...

            if ( ( my $refTable, my $refField ) = $dbc->foreign_key_check( $field_list[$Findex] ) ) {
                ($showval) = &get_FK_info( -dbc => $dbc, -field => $field_list[$Findex], -id => "$thisval" );

                #if ($showval=~/:(.*)/) {$showval = $1;}
                ###### set up link to foreign table.. ####
                if ($showval) {

                    #$showval = &Link_To( $dbc->config('homelink'),$showval,"&Info=1&Table=$refTable&Field=$refField&Like=$thisval",$Settings{LINK_COLOUR},['newwin']);
                    $showval = &Link_To( -link_url => $homelink, -label => $showval, -param => "&Info=1&Table=$refTable&Field=$refField&Like=$thisval", -colour => $Settings{LINK_COLOUR}, -window => ['newwin'] );
                }
                else { $showval = '-'; }
            }
            unless ($showval) { $showval = '-'; }
            push( @nextrow, $showval );
            $Findex++;
        }
        ###### Check for other tables pointing to these records... ###########
        my %Retrieve;

        if ($include_references) {
            my ( $ref_list, $detail_list ) = $dbc->get_references( $table, { $fieldref => $Retrieved{$fieldref}[ $index - 1 ] } );

            # &Link_To( $dbc->config('homelink'),"Find","&FKeys=1&Table=$table",'blue',['newwin2']);
            # $dbc->get_references($table,\%Retrieved,$index-1);

            if ($detail_list) {
                chop $detail_list;
                push( @nextrow, $detail_list );
            }
            elsif ($details) {
                push( @nextrow, 'none' );
            }

            if ($ref_list) {
                chop $ref_list;
                push( @nextrow, $ref_list );
            }
            elsif ($references) {
                push( @nextrow, 'none' );
            }
        }

        $View->Set_Row( \@nextrow );
        $index++;
    }

    #    $table_data->finish();

    $final_output .= $View->Printout(0);

    #    print hidden(-name=>'ID Field',-value=>$fieldref);
    #    print br . submit(-name=>'Delete Record',-value=>"Delete Record(s)",-style=>"background-color:red");

    my @mark_actions = Cast_List( -list => $run_modes, -to => 'array' );
    if ($run_modes) {
        $final_output .= " ";
        foreach my $thismark (@mark_actions) {
            my $onClick_str = '';
            if ( $onclick_hash && $onclick_hash->{$thismark} ) {
                $onClick_str = $onclick_hash->{$thismark};
            }

            my ( $name, $value );
            ## enable encoded buttons where 'name:value' strings are decoupled
            if ( $thismark =~ /^(.+)\:(.+)$/ ) { $name = $1; $value = $2; }
            elsif ($application) {
                ## cgi_application - list is run modes ##
                $name  = 'rm';
                $value = $thismark;
            }
            else { $name = $thismark; $value = $thismark; }

            $final_output .= submit( -name => $name, -value => $value, -style => "background-color:red", -onClick => $onClick_str ), ' ';
        }
    }
    if ($application) {
        $final_output .= hidden( -name => 'cgi_application', -value => $application );
    }
    $final_output .= &vspace(5);

    $final_output .= "\n$add_html\n" if ($add_html);
    ### final standard options for notes, edit, delete ###

    if ( !$application ) {
        ## Standard Buttons CANNOT be combined with application run modes (code will go to application default)
        if ($notes) {
            $final_output .= "<br>Notes: ";
            $final_output .= textfield( -name => 'Mark Note', -size => 20 );
        }

        if ( $edit || $delete ) { $final_output .= '<HR>' }

        if ($edit) {
            $final_output .= <BR>;
            $final_output .= submit( -name => 'Edit_Records', -value => 'Edit Records', -class => "Std" );
            $final_output .= hspace(20);
        }

        if ($delete) {
            $final_output .= <BR>;
            $final_output .= submit( -name => 'Delete Record', -value => 'Delete Record(s)', -class => "Action" );
            $final_output .= hspace(20);
        }
    }

    if ( $Input{User} ) { $final_output .= hidden( -name => 'User', -value => $Input{User} ); }

    my $primary_list = join "\",\"", @primary_values;
    $final_output .= hidden( -name => 'PreviousCondition', -value => "$fieldref in (\"$primary_list\")" ) . "\n</Form>";

    unless ($return_html) {
        print $final_output;
        RGTools::RGIO::Test_Message( "$condition", $testing );
        return;
    }
    return $final_output;
}

#################
sub info_view {
#################  (TEMPORARY - to allow access to old name
    my $dbc         = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table       = shift;
    my $field       = shift;
    my $value       = shift;
    my $condition   = shift || '';
    my $hide_fields = shift;

    return edit_records( $dbc, $table, $field, $value, $condition, $hide_fields );
}

#######################
sub edit_records {
#######################
    #
    # A view in rows allowing quick editing of fields in multiple records at the same time...
    #
    #
    my %args = filter_input(
         \@_,
        -args      => [ 'dbc', 'table', 'field', 'value', 'condition', 'hide_fields', 'display' ],
        -mandatory => 'table'
    );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table       = $args{-table};
    my $field       = $args{-field};
    my $value       = $args{-value};
    my $condition   = $args{-condition} || 1;
    my $hide_fields = $args{-hide_fields};
    my $display     = $args{-display};
    my $order       = $args{-order};
    my $initialize  = $args{-initialize};                                                              ## flag to suppress query for now...

    my $max_default = 1000;                                                                            ## maximum records to display by default if no conditions supplied ...
    
    my @fields = split ',', $display;

    my @hidden = split ',', $hide_fields;

    ##### set condition.. #####
    my @value_list = split ',', $value;
    my @qvalue_list = map { $dbc->dbh()->quote($_) } @value_list;
    my $quoted_value = join ',', @qvalue_list;

    my @conditions;
    if ( $condition =~ /^WHERE (.*)/ ) { push @conditions, $1 }
    elsif ($condition) { push @conditions, $condition }

    if ( $value =~ /%/ ) {
        push @conditions, "$field LIKE $quoted_value";
    }
    elsif ( !$field || !$value ) {

        #	$condition=~s/and/where/i;          ##### only condition...
    }
    else {
        push @conditions, "$field in ($quoted_value)";
    }

    my $conditions = join ' AND ', @conditions;

    #### Redirect to Table_search_edit page if only 1 record (that page is more user friendly)
    my ($total_count) = $dbc->Table_find( $table, 'count(*)', "WHERE $conditions" );

    if ( $total_count == 1 ) {
        my ($primary_field) = $dbc->get_field_info( $table, undef, 'Primary' );
        my ($search_list) = $dbc->Table_find( $table, $primary_field, "WHERE $condition" );
        Table_search_edit( $dbc, $table, $search_list, undef );
        return 1;
    }
    elsif ( $total_count > $max_default ) {
        ## skip search ##
        $initialize = 1;
    }
    #### End Redirect to Table_search_edit page if only 1 record

    #### Custom Insertion (special forms for new tables... ) ###
    if ( $table eq 'Solution' ) {
        Message("Set to Buffer/Primer/Matrix if applicable");
    }
    #### End Custom Insertion (special forms for new tables... ) ###

    my $List = SDB::DB_Record->new( $dbc, $table, $dbc->homelink() );
    if ( int(@fields) ) { $List->Display_Fields( \@fields ) }
    if ( int(@hidden) ) { $List->Hide_Fields( \@hidden ) }
    if ($hide_fields) { $List->{showfields} = 0; }
    $List->List_by_Condition( -conditions => \@conditions, -order => $order, -initialize => $initialize );

    return 1;
}

#####################
sub info_link {
#####################
    #
    # generate html command for hyperlink to display general info for $field = $id in $table
    #
    my %args   = filter_input( \@_, -args => 'id,field,table' );
    my $dbc    = $args{-dbc};
    my $id     = $args{-id};
    my $field  = $args{-field};
    my $table  = $args{-table};
    my $colour = $args{-colour} || $Settings{LINK_COLOUR};
    my $newwin = $args{-new_window} || [];

    return &Link_To( $dbc->config('homelink'), "<B>$id</B>", "&Info=1&Table=$table&Field=$field&Like=$id", $colour, $newwin );

    #    return "<A Href='$homelink&Info=1&Table=$table&Field=$field&Like=$id'><B>$id</B></A>";
}

##########################
sub Confirm_Deletion {
##########################
    my %args     = filter_input( \@_, -args => 'table,selected' );
    my $dbc      = $args{-dbc};
    my $table    = $args{-table};
    my $selected = $args{-selected};

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {
        $prev_Cond = param('PreviousCondition');
    }

    &RGTools::RGIO::Message("Are you SURE you want to delete these records ?!");

    print alDente::Form::start_alDente_form( $dbc, 'Editing Form') .
        submit( -name => 'Confirmed Delete Records', -value => 'YES', -style => "background-color:red" ), hidden( -name => 'TableName', -value => $table ), &hspace(40), submit( -name => 'NO Delete', -value => 'NO', -class => "Search" ),
        hidden( -name => 'Confirmed Deletions', -value => $selected ), hidden( -name => 'PreviousCondition', -value => $prev_Cond ), "\n</FORM>";

    return 1;
}

########################
sub decode_format {
########################
    #
    # rephrases regexp format to readable text
    #

    my $format = shift;

    $format =~ s/(\\S|\.|\\d|\[a\-zA\-Z\]|\[1\-9\]){(\d+),(\d+)}/$2-$3 $1s/g;
    $format =~ s/(\\S|\.|\\d|\[a\-zA\-Z\]|\[1\-9\]){(\d+)}/$2 $1s/g;
    $format =~ s/(\\S|\.|\\d|\[a\-zA\-Z\]|\[1\-9\])\+/at least 1 $1/g;
    $format =~ s/(\\S|\.|\\d|\[a\-zA\-Z\]|\[1\-9\])\*/any number of $1s/g;

    $format =~ s /\\S/non-space character/g;
    $format =~ s /\[a\-zA\-Z\]/letter/g;
    $format =~ s /\[1\-9\]/non-zero/g;
    $format =~ s /\./character/g;
    $format =~ s /\\d/digit/g;
    $format =~ s /\|/ OR /g;

    return $format;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

#############################
sub _update_record {
#############################]
    #
    # Updates the record either into a submission file or database
    #
    my %args = @_;

    my $dbc                   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $target                = $args{-target};
    my $record                = $args{-record};                                                                  # Which record to update (Index is ONE-BASED).  By default retrieves all records
    my $form                  = $args{-form};                                                                    # has to be passed a form object
    my $project               = $args{-project};
    my $collab_id             = $args{-collab_id};
    my $collab_email          = $args{-collab_email};
    my $submission_department = $args{-department};
    my $mode                  = $args{-mode};                                                                    # Save submission as draft if mode is Draft, otherwise insert
    my $testflag              = $args{-testing};
    my $target_group          = $args{-group};

    # retrieve data hash from the form
    my %data     = $form->retrieve_data();                                                                       ## pass record attribute in the future... (?)..
    my $external = $form->{external};

    my $submission_dir = $form->{submission_dir};

    # if storable, save to submission
    # else, fall through to batch append
    if ( $target =~ /xml|storable|hash/i ) {                                                                     #Save the info to the submission file.
        if ( param('Edit_Submission') ) {                                                                        #Modify existing submission.
            my $finish = 0;
            if ( $mode =~ /Finish|Normal/ ) {
                $finish = 1;
            }
            &SDB::Submission::Modify_Submission( $dbc, param('Edit_Submission'), param('Submission_Source'), 'modified', \%data, $finish );
            my $sid    = param('Edit_Submission');
            my $source = param('Submission_Source');
            if ( $submission_dir && !$finish ) {

                # if this is an external submission, ask the user to change the draft to submitted status
                Message( "Submission ID ", "<B><Font color=red>$sid</Font> modified.</B>" );
                Message("Note that you still have not finished this submission!");
                print br();
                Message("The page will reflect your changes in a few minutes...");
            }
            elsif ( $submission_dir && $finish ) {

                # do nothing, submission has been submitted
            }
            else {
                Message( "Subm58ission ID ", "<B><Font color=red>$sid</Font> modified.</B>" );
                Message("Note that the submission still needs to be approved in order to save the submission to the database.");
                print vspace(5);
                print &Link_To( $dbc->config('homelink'), "View submission ID $sid", "&View_Submission=$sid&Submission_Source=$source", 'blue' );
            }
        }
        else {    #Generate new submission.
            my $draft  = 0;
            my $source = 'Internal';
            if ( $mode =~ /Draft/i ) {
                $draft = 1;
            }
            if ($external) {
                $source = 'External';
            }
            &SDB::Submission::Generate_Submission(
                -dbc            => $dbc,
                -source         => $source,
                -data_ref       => \%data,
                -project        => $project,
                -collab_id      => $collab_id,
                -collab_email   => $collab_email,
                -department     => $submission_department,
                -submission_dir => $submission_dir,
                -draft          => $draft,
                -testing        => $testflag,
                -target_group   => $target_group
            );
        }
        return 1;    #Do not update the database;
    }
    else {

        # fall through - update database
    }

    # Batch updates the database and return a hash of new ids

    $dbc->{transaction}->{batch_append} = \%data if $dbc->{transaction};    ## why is this here... ?

    my $ok = $dbc->Batch_Append( -data => \%data );

    return 0;                                                               ## changed from $ok since we want to view home page if applicable after the update
}

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

$Id: DB_Form_Viewer.pm,v 1.141 2004/12/07 18:33:41 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
