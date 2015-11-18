################################################################################
# DB_Form.pm
#
# 
#
##############################################################################################################
# $Id: DB_Form.pm,v 1.82 2004/11/30 01:42:31 rguin Exp $
##############################################################################################################
package SDB::DB_Form;

use base LampLite::Form;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Form.pm -

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use Storable qw(dclone);

#use YAML qw(thaw freeze);
use LampLite::CGI;

##############################
# custom_modules_ref         #
##############################

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::Session;
use SDB::HTML;
use RGTools::Object;
use RGTools::HTML_Table;
use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw(%Field_Info $Sess $testing $Security %Defaults $submission_dir);

my $q = new LampLite::CGI;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
no strict "refs";
my $SPECIFY_MSG  = "Please specify details for the new <CURR_TABLE>.";
my $SKIP_MSG     = "Go to the next form (ignore this form)";
my $CONTINUE_MSG = "Save and go to the next form.";
my $FINISH_MSG   = "Save the current form info and finish.";
my $UPDATE_MSG   = "Press the 'Update <CURR_TABLE>' button to update the information to the database.";
##############################
# constructor                #
##############################

##################
sub new {
##################
    #
    # Constructor of the object
    #
    my $this = shift;

    my %args    = @_;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $frozen  = $args{-frozen} || 0;                                                             # Reference to frozen object if there is any. [Object]
    my $encoded = $args{-encoded} || 0;
    my $groups  = $args{-groups} || 0;
    my $type    = $args{-type};

    my $self = $this->Object::new( -frozen => $frozen, -type => $type, -encoded => $encoded );
    my $class = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;                                                                           # Database handle [ObjectRef]

    if ($frozen) {
        $self->{curr_mode} = '';
        return $self;                                                                              # If frozen then return now with the new dbc handle.
    }

    $self->{quiet}             = $args{-quiet} || 0;
    $self->{start_table}       = $args{-table};                                                    # Database table
    $self->{field_list}        = $args{-fields};                                                   ## alternatively supply list of fields
    $self->{aliases}           = $args{-aliases} || $args{-labels};                                # Field aliases to override Prompt in DBField (optional)
    $self->{-real_table_names} = $args{-real_table_names};                                         ##List of real table names, for fields with alias for table names eg. Source.Source_ID to S1.Source_ID
    $self->{target}            = $args{-target} || 'Database';                                     # Target  (Case Sensitive... 'Database' or 'Submission')
    $self->{parameters}        = $args{-parameters};                                               # Parameters
    $self->{wrap}              = defined $args{-wrap} ? $args{-wrap} : 1;                          # Whether to wrap the form
    $self->{reset}             = $args{ -reset };                                                  #Reset the form to the blank state so it doesn't carry over the values from the previous instance of the form.
    $self->{db_action}         = $args{-db_action} || $args{-action} || 'append';                  # Indicates whethter the form is appending new records (append) or editing existing records (edit), or searching (search (N) or reference search (1))

    $self->{start_form} = $args{-start_form} || $self->{wrap};                                     ## include start of form
    $self->{end_form}   = $args{-end_form}   || $self->{wrap};                                     ## include end of form
    $self->{form_name}  = $args{-form_name}  || $args{-form};                                      ## name of the form

    $self->{curr_mode} = $args{-mode} || '';                                                       # The current mode
    my $add_branch_ref = $args{-add_branch};                                                       # (ArrayRef) Optional: Starting table/s of an insert branch
    $self->{skip_tables}             = $args{-skip_tables};                                        # (ArrayRef) Optional: omit tables from insert
    $self->{append_html}             = $args{-append_html};                                        # (Scalar) Optional: add html elements between the form and the buttons
    $self->{append_hidden_html}      = $args{-append_hidden_html};                                 # (Scalar) Optional: add html elements between the form and the buttons
    $self->{allow_draft}             = $args{-allow_draft};                                        # (Scalar) Optional: disable draft button
    $self->{remove_table_list}       = $args{-remove_table_args} || 0;                             # don't add hidden arguments indicating tables. Used for merging tables together.
    $self->{ignore_db_form}          = $args{-ignore_db_form} || 0;                                # do not follow DB_Form, just use specified table/s. Used for editing submissions.
    $self->{external}                = $args{-external_form} || 0;                                 # The form is used externally. Used to turn off links and other functionality that is not necessary or are security risks.
    $self->{finish_all}              = $args{-finish_all};                                         # (Scalar) Disables optional finishes - must go through all tables
    $self->{ignore_duplicate_tables} = $args{-ignore_duplicate_tables};                            # (Scalar) Flag to ignore duplicate tables. Used for approval.
    $self->{show_table_description}  = $args{-show_table_desc} || 0;                               ## Show the table description in the form
    $self->{submission_id}           = $args{-submission_id};                                      ### Indicated whether this form is part of a submission
    $self->{element_ids_included} = [];    # element ids that have been added to the table ( by add_Section() ). This is useful when we need to check if a dynamically added element has been included in the table already to avoid duplicates

    # embeded for forms for adding supporting records ie, contact, stage (NewLink in DBField)
    #$self->{add_form} = $args{-add_option} ? 1 : 0; # Enables or disables the add option
    my $add_form = $args{-add_option};     # Enables or disables the add option

    if ( ( !defined $add_form ) || $add_form ) {
        $self->{add_form} = 1;             # Enables or disables the add option
    }
    else {
        $self->{add_form} = 0;             # Enables or disables the add option
    }
    my @tables = ();

    # resolve tables if necessary
    if ( ( defined $add_branch_ref ) && ( scalar(@$add_branch_ref) > 0 ) ) {
        foreach my $table (@$add_branch_ref) {
            my $id = $table;
            unless ( $table =~ /^\d+$/ ) {
                ($id) = &Table_find( $self->{dbc}, "DBTable", "DBTable_Name", "WHERE DBTable_Name like '$table'" );
            }
            push( @tables, $id );
        }
    }

    if ( $self->{wrap} && !$self->{start_form} && !$self->{end_form} ) {
        $self->{start_form} = 1;
        $self->{end_form}   = 1;
    }

    $self->{data} = {};    # Stores user input/data [hashref]

    if ( $self->{db_action} =~ /append/i && $self->{curr_mode} ) {
        $self->{multipage} = 1;
    }
    else {
        $self->{multipage} = 0;    # Whether this is a multipage form
    }
    $self->{curr_table}       = '';    # The current table
    $self->{curr_table_title} = '';    # The title of the current table
    $self->{curr_record}      = '';    # The current record number

    $self->{next_table}  = '';
    $self->{next_record} = '';

    if ( scalar(@tables) > 0 ) {
        $self->{additional_tables} = \@tables;
    }
    $self->{extra_branch_conditions} = {};        # Store extra branching conditionst that are not part of standard fields that belonged to a table
    $self->{configs}->{'preset'}     = {};        # specify field values that are preset
    $self->{configs}->{'highlight'}  = ();        # specify field areas to be highlighted
    $self->{configs}->{'autofill'}   = {};        # specify fields that can be autofilled
    $self->{configs}->{'omit'}       = {};        # specify fields to be omitted (fields don't show up in the form but still include in HIDDEN tags)
    $self->{configs}->{'grey'}       = {};        # specify fields to be 'greyed out'
    $self->{configs}->{'list'}       = {};        # specify lists for popup menus
    $self->{configs}->{'condition'}  = {};        # specify condition to filter field options
    $self->{configs}->{'hidden'}     = {};
    $self->{configs}->{'require'}    = {};        # dynamically require fields
    $self->{configs}->{'fk_extra'}   = {};        # Extra value to added to the FK list.
    $self->{configs}->{'include'}    = {};        # include parameters
    $self->{configs}->{'mask'}       = {};        # specify mask for values to be show in popup menu (e.g. if mask is 'Sequencing' then only items that match 'Sequencing' will show)
    $self->{configs}->{'extra'}      = {};        # Extra column to be added for fields in addition to the auto-generated form element
    $self->{configs}->{'filter'}     = {};
    $self->{configs}->{'groups'}     = $groups;

    $self->initialize(%args);                     ## call LampLite::initialize method...
    return $self;
}

##############################
# public_methods             #
##############################

###################################
sub configure_form_element {
###################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $field     = $args{-field};
    my $condition = $args{-condition};
    my $label     = $args{-label};
    my $order     = $args{-order};
    my $preset    = $args{-preset};
    my $default   = $args{-default};

    my $join_table = $args{-join_table};
    my $join_condition = $args{-join_condition} || '1';

    my $dbc = $self->{dbc};

    my ( $ref_table, $ref_field ) = $dbc->foreign_key_check($field);

    if ($join_table) {
        $ref_table .= ",$join_table";
        $condition .= " AND $join_condition";
    }

    ( my $primary ) = $dbc->get_field_info( $ref_table, -type => 'Primary' );
    if ( !$label ) { ($label) = $dbc->Table_find( 'DBField', 'Field_Reference', "WHERE Field_Table = '$ref_table' and Field_Name = '$ref_field'" ) }

    my $fields = [$primary];
    if ($label) { push @$fields, $label }

    my %list = $dbc->Table_retrieve( $ref_table, $fields, "WHERE $condition", -order => $order );

    my $i = 0;
    my ( @options, %labels );
    while ( defined $list{$primary}[$i] ) {
        push @options, $list{$primary}[$i];
        $labels{ $list{$primary}[$i] } = $list{$label}[$i];
        $i++;
    }

    $self->{configs}{options}{$field} = \@options;
    $self->{configs}{labels}{$field}  = \%labels;

    if ($preset)  { $self->{configs}{preset}{$field}  = $preset }
    if ($default) { $self->{configs}{default}{$field} = $default }

    return;
}

##################
#
# A quick easy way to load a particular record into the form.
#  (ie set the defaults as they exist to enable editing)
#
#
####################
sub load_record {
####################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'table,condition', -mandatory => 'table,condition' );
    my $table     = $args{-table};
    my $condition = $args{-condition};

    unless ( $self->{start_table} ) { print "NO table specified"; return 1; }

    my @fields = get_fields( $self->{dbc}, $table );
    my %defaults = &Table_retrieve( $self->{dbc}, $table, \@fields, "$condition LIMIT 1" );

    my %Preset;
    my @keys = keys %defaults;
    foreach my $key ( keys %defaults ) {
        $Preset{$key} = $defaults{$key}[0];
    }
    $self->configure( -preset => \%Preset );

    return 1;
}

#####################
# given a table loads all possible form branches from DB_Form.
#####################
sub load_branch {
#####################
    my $self          = shift;
    my %args          = &filter_input( \@_, -args => 'table' );
    my $table         = $args{-table};
    my $form_id       = $args{-form_id};
    my $form_tree_ref = $args{-form_tree_ref};
    my $db_forms_ref  = $args{-db_forms_ref};
    my $level         = $args{-level} || 0;
    my $object_class  = $args{-object_class};
    my $dbc           = $self->{dbc};
    my $debug         = $args{-debug};
    my $user_id       = $dbc->get_local('user_id');

    unless ( $table xor $form_id ) {
        print HTML_Dump( $table, $form_id );
        Message("Error: Please specify only 1 of the above!");
        return 0;
    }

    my @tables;
    if ( $table =~ /,/ ) {
        @tables = split( ',', $table );
        $table = shift(@tables);
    }
    if ( $self->{additional_tables} ) {
        push( @tables, @{ $self->{additional_tables} } );
        delete $self->{additional_tables};    ### Clear it out
    }

    my $single_form;
    if ($object_class) {
        ### Object Handeling
        my ($object_class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class='$object_class'" );
        $self->{configs}{grey}{"FK_Object_Class__ID"} = $object_class_id;    ### for forms following it...
    }

    if ($table) {                                                            #init required since it's the first time coming into this method!
        my %db_forms = $dbc->Table_retrieve(
            'DB_Form,DBTable',
            [   'DB_Form_ID',
                "CASE WHEN LENGTH(Class)>0 THEN CONCAT(Form_Table,':',Class) ELSE Form_Table END AS FormFullName",
                'Form_Table AS ThisTableName',
                'Min_Records', 'Max_Records', 'FKParent_DB_Form__ID AS Parent_Form',
                'Parent_Field', 'Parent_Value', 'Finish', 'Class', 'CASE WHEN LENGTH(Class)>0 THEN CONCAT(Class, " ",DBTable_Title) ELSE DBTable_Title END AS Form_Title', 'Form_Order'
            ],
            "WHERE Form_Table=DBTable_Name ORDER BY Form_Order"
        );

        if ( $self->{external} ) {
            ### Disable optional finish for external pages
            delete $db_forms{Finish};
        }

        $db_forms_ref = rekey_hash( \%db_forms, "DB_Form_ID" );

        my $extra_condition = '1';

        if ($object_class) {
            $extra_condition = "Class = '$object_class'";
        }

        ($form_id) = $dbc->Table_find( 'DB_Form', 'DB_Form_ID', "WHERE Form_Table='$table' AND $extra_condition" );

        unless ($form_id) {
            ### This is not a multipage form.... => $form_id = $table
            $form_id                        = $table;
            $single_form                    = 1;
            $form_tree_ref->{original_form} = $form_id;
            my $full_name = $table;
            $full_name = "$table:$object_class" if ($object_class);

            $form_tree_ref->{$form_id} = {
                Parent_Form   => '',
                ThisTableName => $form_id,
                FormFullName  => $full_name,
                Form_Title    => $form_id,
                DB_Form_ID    => -1,
                Max_Records   => 1,
                Min_Records   => 1,
                Parent_Field  => '',
                Parent_Value  => '',
                Finish        => 1
            };
        }

        $form_tree_ref->{original_form} = $form_id;

        if ( $self->{target} =~ /submission/i && ( !$self->{submission_id} || $self->{Limit_Edit} ) ) {
            push( @tables, 'Submission' );
            $form_tree_ref->{'Submission'} = {
                Parent_Form   => '',
                ThisTableName => 'Submission',
                FormFullName  => 'Submission',
                Form_Title    => 'Submission',
                DB_Form_ID    => -1,
                Max_Records   => 1,
                Min_Records   => 1,
                Parent_Field  => '',
                Parent_Value  => '',
                child_form    => []
            };

            my @grey_submission;
            @grey_submission = @{ $self->{Submission}{Grey} } if ( $self->{Submission} && $self->{Submission}{Grey} );
            my @omit_submission;
            @omit_submission = @{ $self->{Submission}{Omit} } if ( $self->{Submission} && $self->{Submission}{Omit} );
            my %preset_submission;
            %preset_submission = %{ $self->{Submission}{Preset} } if ( $self->{Submission} && $self->{Submission}{Preset} );
            my %list_submission;
            %list_submission = %{ $self->{Submission}{List} } if ( $self->{Submission} && $self->{Submission}{List} );

            ## set default submission parameters if not defined ##
            $preset_submission{'Submission_DateTime'} ||= &date_time();
            $preset_submission{'Submission_Status'}   ||= 'Submitted';

            push( @grey_submission, 'Submission_Status',       'Submission_DateTime' );
            push( @omit_submission, 'FKApproved_Employee__ID', 'Approved_DateTime' );

            my @base_groups = sort $dbc->Table_find( 'Department,Grp LEFT JOIN Grp_Relationship ON FKderived_Grp__ID=Grp_ID', 'Grp_Name', "WHERE Access='Guest' AND FK_Department__ID=Department_ID AND Department_Name != 'Site Admin' " );

            $preset_submission{'Table_Name'} = $table;
            $preset_submission{'Key_Value'}  = 'TBD';
            if ( $self->{configs}{submission}{'FKTo_Grp__ID'} ) {
                $preset_submission{'FKTo_Grp__ID'} = $self->{configs}{submission}{'FKTo_Grp__ID'};
                push( @omit_submission, 'FKTo_Grp__ID' );
            }
            else {
                $list_submission{'FKTo_Grp__ID'} = [ 'Site Admin', @base_groups ];
            }

            push( @omit_submission, 'Table_Name', 'Key_Value' );

            if ( $self->{external} ) {
                $preset_submission{'Submission_Source'} = 'External';
                $preset_submission{'FK_Contact__ID'}    = $self->{configs}{submission}{collab_id};    ### Set Collab ID
                $preset_submission{'FKFrom_Grp__ID'}    = 'External';
                push( @omit_submission, 'FKFrom_Grp__ID',    'FKSubmitted_Employee__ID' );
                push( @grey_submission, 'Submission_Source', 'FK_Contact__ID' );
            }
            else {
                $preset_submission{'Submission_Source'} = $self->{Submission}{Preset}{Submission_Source} || 'Internal';
                $preset_submission{'FKSubmitted_Employee__ID'} ||= $user_id;
                $list_submission{'FKFrom_Grp__ID'} = [ 'Public', @base_groups ];
                push( @omit_submission, 'FK_Contact__ID' );
                foreach my $to_be_grey ( 'Submission_Source', 'FKSubmitted_Employee__ID' ) {
                    unless ( grep( /^$to_be_grey$/, @grey_submission ) ) {
                        push( @grey_submission, $to_be_grey );
                    }
                }
            }

            $form_tree_ref->{'Submission'}{Grey} = join ',', @grey_submission;
            $form_tree_ref->{'Submission'}{Omit} = join ',', @omit_submission;
            $form_tree_ref->{'Submission'}{Preset} = \%preset_submission;
            $form_tree_ref->{'Submission'}{List}   = \%list_submission;
        }

        $form_tree_ref->{current_form}          = $form_tree_ref->{original_form};
        $form_tree_ref->{current_form_instance} = 0;
    }

    ### Populate the Grey, Omit & Preset list from both param() & $self->{configs}
    ### Store the Omit & Grey in two strings and their values in the %Preset
    ### For all the values in %Preset, if they are in neither Omit or Grey they will just get presetted
    my ( @grey, @omit );
    my %preset;

    foreach ( keys %{ $self->{configs}{grey} } ) {
        $preset{$_} = $self->{configs}{grey}{$_};
    }
    foreach ( keys %{ $self->{configs}{omit} } ) {
        $preset{$_} = $self->{configs}{omit}{$_};
    }
    foreach ( keys %{ $self->{configs}{hidden} } ) {
        $preset{$_} = $self->{configs}{hidden}{$_};
    }
    foreach ( keys %{ $self->{configs}{preset} } ) {
        $preset{$_} = $self->{configs}{preset}{$_};
    }

    ### Get the list of all the fields for this table
    unless ($table) { $table = $db_forms_ref->{$form_id}{ThisTableName}[0]; }
    my @full_fields = $dbc->get_fields( -table => $table );

    my @all_grey = ( $q->param('Grey'), keys %{ $self->{configs}{grey} } );
    my @all_omit = ( $q->param('Omit'), keys %{ $self->{configs}{omit} }, keys %{ $self->{configs}{hidden} } );

    my %Preset;
    ### Check to see if any of the fields on this table have a preset value
    foreach my $field (@full_fields) {
        $field =~ /^$table\.(\w+) AS .*$/i;
        my $rF = $1;

        my $value = SDB::HTML::get_Table_Param( -dbc => $dbc, -table => $table, -field => $rF ) || $q->param("$rF") || $preset{"$table.$rF"} || $preset{"$rF"};

        my ( $refTable, $refField ) = $dbc->foreign_key_check($field);
        if ( $value !~ /<.*>/ && $refTable && $refField ) {
            $value = $dbc->get_FK_info( $field, $value );
        }

        if ($value) {
            $Preset{$rF} = $value;
        }

        if ( grep( /^($table\.|)$rF$/, @all_grey ) ) {
            push( @grey, $rF );
        }

        if ( grep( /^($table\.|)$rF$/, @all_omit ) ) {
            push( @omit, $rF );
        }
    }

    $form_tree_ref->{$form_id}{Grey} = join ',', @grey;
    $form_tree_ref->{$form_id}{Omit} = join ',', @omit;
    $form_tree_ref->{$form_id}{Preset} = \%Preset;
    $form_tree_ref->{$form_id}{List}   = $self->{configs}{list};

    unless ($single_form) {
        foreach my $key ( keys %{ $db_forms_ref->{$form_id} } ) {
            $form_tree_ref->{$form_id}{$key} = $db_forms_ref->{$form_id}{$key}[0];
        }

        my $form_count = 0;
        foreach my $dbf_id ( sort { $db_forms_ref->{$a}{Form_Order}[0] <=> $db_forms_ref->{$b}{Form_Order}[0] || $a <=> $b } keys %{$db_forms_ref} ) {
            if ( $form_id == $db_forms_ref->{$dbf_id}{Parent_Form}[0] ) {
                my $parent_val   = $db_forms_ref->{$dbf_id}{Parent_Value}[0];
                my $parent_field = $db_forms_ref->{$dbf_id}{Parent_Field}[0];
                ### Look to see if an entry for this branch already exists, if not increment the form_order
                my $form_order;
                for ( my $i = 0; $i < int( @{ $form_tree_ref->{$form_id}{branch_on} } ); $i++ ) {
                    if ( $form_tree_ref->{$form_id}{branch_on}[$i]->{branch_name} eq $parent_field ) {
                        $form_order = $i;
                        last;
                    }
                }
                unless ( defined $form_order ) {
                    $form_order = int( @{ $form_tree_ref->{$form_id}{branch_on} } );
                }

                if ($parent_val) {
                    $form_tree_ref->{has_branches} = 1;
                    my @parent_vals = split( '\|', $parent_val );

                    #Branch...
                    foreach (@parent_vals) {
                        $form_tree_ref->{$form_id}{branch_on}[$form_order]{branch_name} = $parent_field;
                        unless ( $form_tree_ref->{$form_id}{branch_on}[$form_order]{choices}{$_} ) {
                            $form_tree_ref->{$form_id}{branch_on}[$form_order]{choices}{$_} = [];
                        }
                        push( @{ $form_tree_ref->{$form_id}{branch_on}[$form_order]{choices}{$_} }, $dbf_id );
                        my $default;
                        ### Also set the active branch if it's passed in as a preset value
                        if ( $form_tree_ref->{$form_id}{Preset}{$parent_field} ) {
                            $default = $form_tree_ref->{$form_id}{Preset}{$parent_field};
                        }
                        ### A branch can also be preseted using formData
                        ### <CONSTRUCTION> defaulting to the first instance
                        if ( $self->{formData} && $self->{formData}{$form_id} && $self->{formData}{$form_id}{0}{$parent_field} ) {
                            $default = $self->{formData}{$form_id}{0}{$parent_field};
                        }

                        if ($default) {
                            $form_tree_ref->{$form_id}{branch_on}[$form_order]{active} = $default;
                        }
                    }
                }
                else {

                    #Child...
                    if ( !$form_tree_ref->{$form_id}{child_form} ) { $form_tree_ref->{$form_id}{child_form} = []; }    ### Initialize
                    push( @{ $form_tree_ref->{$form_id}{child_form} }, $dbf_id );
                }
                my @ancestors = ( $form_tree_ref->{$form_id}{ThisTableName} );
                if ( $form_tree_ref->{$form_id}{Ancestors} ) {
                    push( @ancestors, split( ',', $form_tree_ref->{$form_id}{Ancestors} ) );
                }
                $form_tree_ref->{$dbf_id}{Ancestors} = join( ',', @ancestors );
                $self->load_branch( -form_id => $dbf_id, -form_tree_ref => $form_tree_ref, -db_forms_ref => $db_forms_ref, -level => ++$level, -object_class => $db_forms_ref->{$dbf_id}{Class}[0] );
            }
        }
    }

    if (@tables) {
        foreach my $extra_table (@tables) {
            if ( !$form_tree_ref->{$form_id}{child_form} ) { $form_tree_ref->{$form_id}{child_form} = []; }    ### Initialize
            my ($dbf_id) = $dbc->Table_find( 'DB_Form', 'DB_Form_ID', "WHERE Form_Table='$extra_table' LIMIT 1" );

            if ($dbf_id) {
                my @ancestors = ( $form_tree_ref->{$form_id}{ThisTableName} );
                if ( $form_tree_ref->{$form_id}{Ancestors} ) {
                    push( @ancestors, split( ',', $form_tree_ref->{$form_id}{Ancestors} ) );
                }
                $form_tree_ref->{$dbf_id}{Ancestors} = join( ',', @ancestors );
                $self->load_branch( -form_id => $dbf_id, -form_tree_ref => $form_tree_ref, -db_forms_ref => $db_forms_ref, -level => ++$level, -object_class => $db_forms_ref->{$dbf_id}{Class}[0] );
            }
            else {
                $dbf_id = $extra_table;
            }
            push( @{ $form_tree_ref->{$form_id}{child_form} }, $dbf_id );
        }
    }
    return $form_tree_ref;
}

##############################
#
# Method to specify:
#
#   preset
#   omit
#   grey
#   list
#
#      options for Submission aspect of form.
#
# Note: supplying either grey and/or omit hashes will set both the grey, omit arrays as well as setting the preset values
#
# Input: hash references for each
#
#
##############################
sub define_Submission {
##############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $grey   = $args{-grey};          ## hash of greyed out fields (along with values)
    my $omit   = $args{-omit};          ## hash of omitted fields (along with values)
    my $preset = $args{-preset};        ## hash of preset values
    my $list   = $args{-list};          ## hash of list elements for this field

    ## extract array of greyed out fields and preset values as required ##
    my @greys;
    if ($grey) {
        foreach my $key ( keys %$grey ) {
            push( @greys, $key );
            $preset->{$key} = $grey->{$key};
        }
    }

    ## extract array of omitted out fields and preset values as required ##
    my @omits;
    if ($omit) {
        foreach my $key ( keys %$omit ) {
            push( @omits, $key );
            $preset->{$key} = $omit->{$key};
        }
    }

    $self->{Submission}{Grey}   = \@greys if @greys;
    $self->{Submission}{Omit}   = \@omits if @omits;
    $self->{Submission}{Preset} = $preset if $preset;
    $self->{Submission}{List}   = $list   if $list;

    return;
}

#####################
# Parses out the data hash returned from Javascript FormNav and returns a standardized version of it
#
#  Sample Input Data Strucutre:
# $VAR1 = {
#          '0' => {
#                   'fields' => {
#                                 'Employee_FullName' => 'John Doe',
#                                 'Employee_Name' => 'John',
#                                 'Initials' => 'JDO',
#                                 'Email_Address' => 'jdo',
#                                 'Machine_Name' => 'jdo01',
#                                 'Position' => 'Bioinformatics',
#                                 'Employee_Status' => [
#                                                        'Active'
#                                                      ],
#                                 'FK_Department__ID' => ''
#                                 'FK_Department__ID Choice' => [
#                                                                 'Sequencing'
#                                                               ],
#                               },
#                   'form_name' => 'Employee'
#                 },
#          '1' => {
#                   'fields' => {
#                                 'GrpEmployee_ID' => '',
#                                 'FK_Employee__ID' => '<Employee.Employee_ID>',
#                                 'FK_Grp__ID' => '',
#                                 'FK_Grp__ID Choice' => [
#                                                          'Sequencing Production'
#                                                        ],
#                               },
#                   'form_name' => 'GrpEmployee'
#                 },
#          '2' => {
#                   'fields' => {
#                                 'GrpEmployee_ID' => '',
#                                 'FK_Employee__ID' => '<Employee.Employee_ID>',
#                                 'FK_Grp__ID' => '',
#                                 'FK_Grp__ID Choice' => [
#                                                          'Mapping Bioinformatics'
#                                                        ],
#                               },
#                   'form_name' => 'GrpEmployee'
#                 }
#        };
#########################################
sub conv_FormNav_to_DBIO_format {
########################################
    my %args = &filter_input( \@_, -args => 'data', -mandatory => 'data' );

    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $data        = $args{-data};
    my $ignore_null = $args{-ignore_null} || 1;
    my $validate    = defined $args{-validate} ? $args{-validate} : 1;                                 ## validate ids on the fly (set to 0 if using for search condition - ie not important)
    my $feedback    = $args{-feedback};

    my %fdata;                                                                                         #formatted data;

    my @data_keys = keys %$data;

    if (0) {
        ##
        ## If data is in standard mode (ie from a single simple table form and NOT from the navigator, the information should still be easily parseable ...)
        ##
        if ( my ($table) = grep /^(\w+[a-zA-Z])\_ID$/i, @data_keys ) {
            ## Hash supplied directly (not via Form Nav) ##
            $table =~ s/\_ID$//;
            foreach my $key ( keys %$data ) {
                $fdata{tables}{$table}{0}{$key} = $data->{$key};
            }
            $fdata{index}{0} = $table;
            return \%fdata;
        }
    }

    ## Otherwise, the submission is derived from the form nav in a specialized format ... ##

    my @formlist;
    foreach my $dbform_id ( keys %{$data} ) {
        my $form_name = $data->{$dbform_id}{0}{'FormFullName'};
        my $form_class;
        if ( $form_name =~ /(\w+):(\w+)/ ) {
            $form_name  = $1;
            $form_class = $2;
        }
        push( @formlist, $form_name ) unless ( grep /^$form_name$/, @formlist );

        my @fields = $dbc->get_fields($form_name);

        @fields = map { $_ =~ /.*\.(\w+)\s.*/; $1; } @fields;
        foreach my $instance ( keys %{ $data->{$dbform_id} } ) {
            my $actual_instance = int( keys %{ $fdata{tables}{$form_name} } );
            foreach my $field (@fields) {
                my $value = $data->{$dbform_id}{$instance}{$field} || $data->{$dbform_id}{$instance}{ $field . ' Choice' };
                if ( length( $data->{$dbform_id}{$instance}{$field} ) > 0 ) {
                    $value = $data->{$dbform_id}{$instance}{$field};
                }
                if ( defined $value && $ignore_null ) {

                    # Arrays can't be FKs

                    if ( ref($value) eq 'ARRAY' ) {
                        $value = join( ',', @{$value} );
                    }
                    if ($value) {
                        my ( $refTable, $refField ) = $dbc->foreign_key_check($field);
                        if ( $refTable && $refField ) {
                            if ( $value !~ /<$refTable.$refField>/i ) {
                                $value = $dbc->get_FK_ID( $field, $value, -validate => $validate );
                            }
                        }
                        elsif ( $field eq 'Object_ID' ) {
                            my ($primary_id) = $dbc->get_field_info( $form_class, undef, 'Primary' );
                            if ( $value !~ /<$form_class.$primary_id>/i ) {
                                $value = $dbc->get_FK_ID( $field, $value, -class => $form_class, -validate => $validate );
                            }
                        }

                        $value =~ s/^\'//;    # at the biginning of the new value
                        $value =~ s/\'$//;    # at the end of the new value
                    }
                    $fdata{tables}{$form_name}{$actual_instance}{$field} = $value;
                }
            }
        }
    }

    # fix indecies here...
    foreach ( my $i = 0; $i < scalar(@formlist); $i++ ) {
        $fdata{index}{ $i + 1 } = $formlist[$i];
    }

    return \%fdata;
}

#####################
# Return the configs
#####################
sub configs {
#####################
    my $self    = shift;
    my $configs = shift;

    if ($configs) {
        $self->{configs} = $configs;
    }

    return $self->{configs};

}

#
# Generate the form
#
##################
sub generate {
##################
    my $self              = shift;
    my %args              = @_;
    my $mode              = $args{-mode} || $self->{curr_mode};
    my $title             = $args{-title};
    my $action            = $args{-action} || $self->{db_action} || 'append';           # this switch indicates that the form is being updated ('edit', or 'search', 'reference search')...
    my $form              = $args{-form} || $args{-form_name} || $self->{form_name};    ## pass on name of form.
    my $line_colour       = $args{-line_colour};
    my $next_form         = $args{-next_form} || 0;                                     # Whether we are retrieving the next form for a multipage form
    my $multi_record_mode = $args{-multi_record_mode};                                  # Whether we want to generate the form in multi-record mode
    my $multi_record_num  = $args{-multi_record};                                       # The number of records for multi-record mode
    my $append_Table      = $args{-append};
    my $freeze            = defined $args{-freeze} ? $args{-freeze} : 1;                ## freeze object unless specified not to.
    my $return_html       = $args{-return_html};
    my $submit            = defined $args{-submit} ? $args{-submit} : 1;
    my $navigator_on      = defined $args{-navigator_on} ? $args{-navigator_on} : 1;
    my $attribute_tables  = $args{-attribute_tables};
    my $attribute_default = $args{-attribute_default};
    my $attributes        = $args{-attributes};
    my $attribute_order   = $args{-attribute_order};
    my $object_class      = $args{-object_class};
    my $filter_by_dept    = $args{-filter_by_dept};
    my $roadmap           = $args{-roadmap};
    my $found             = 0;
    my $repeat            = $args{-repeat};                                             ## useful if entering multiple records at the same time
    my $button            = $args{-button};                                             ## override button name/value pair (eg -button=>{'rm'=>'update record'} )

    my $dbc = $self->{dbc};

    if ($repeat) {
        ## used for repeating same fields on multiple rows ##
        $self->{repeat} = $repeat;
    }

    if ($next_form) {

        # Go to the next form
        # Figure out the next form
        $found = $self->get_next_form();
    }
    elsif ($multi_record_mode) {

        # Same form - we are just switching modes
        $self->{curr_table_multi_record_mode} = $multi_record_mode;
        $self->{curr_table_multi_record_num}  = $multi_record_num;

        #		$self->_message($SPECIFY_MSG);
    }
    else {

        # Initialize the form
        $self->_initialize();
    }

    unless ($mode) {
        $mode = $self->{curr_mode} || 'Normal';
    }

    #    unless ($title) {$title = "Add $self->{curr_table_title} Record.."}

    # determine if there are additional tables
    if ( $self->{additional_tables} && ( int( @{ $self->{additional_tables} } ) > 0 ) ) {

        if ( $mode =~ /Normal/i ) { $mode = 'Continue'; }
        else                      { $mode .= ',Continue'; }

        $self->{multipage} = 1;
    }

    my %configs;

    if ($navigator_on) {

        #my $frozen = &RGTools::RGIO::Safe_Freeze(-name=>'Multipage_Form',-format=>'array',-value=>$self,-encode=>1);
        #$configs{include}->{Multipage_Form} = $frozen if $freeze;
        if ( $self->{target} =~ /submission/i ) {
            $self->{configs}{submission}{Table_Name} = $self->{curr_table};
        }

        my %default_params;

        my $submit_url;
        if ( my $homelink = $dbc->homelink() ) {

            # a home link with some parameters at the end
            $homelink =~ /([^\?]*)(.*)?/;
            $submit_url = $1;
            my $pars = $2;

            $pars =~ s/^\??//;
            foreach ( split '&', $pars ) {
                my ( $name, $value ) = split( '=', $_ );
                $default_params{$name} = $value;
            }
        }
        $default_params{Tables}   = $self->{curr_table};
        $default_params{External} = $self->{external};
        $default_params{Database} = $self->{dbc}{dbase};
        $default_params{Session}  = $self->{dbc}{session}{session_id};
        $default_params{User}     = $self->{dbc}{session}{user};

        my %submit_params;
        if ( $self->{configs}{include} ) {
            %submit_params = %{ $self->{configs}{include} };
        }

        $submit_params{Submission_ID} = $self->{submission_id} if ( $self->{submission_id} );

        my $formData = {};
        if ( $self->{formData} ) {
            $formData = $self->{formData};
        }

        require JSON;
        my ($default_params, $submit_params);
        if (JSON->VERSION =~/^1/) { 
            $default_params = JSON::objToJson(\%default_params);
            $submit_params = JSON::objToJson(\%submit_params);
            $formData = JSON::objToJson($formData);
        }
        else { 
            $default_params = JSON::to_json(\%default_params);
            $submit_params = JSON::to_json(\%submit_params);
            $formData = JSON::to_json($formData);
        }
        
        ### $roadmap is already in JSON format, if it doesn't exist, load it and convert it
        my $map = $self->load_branch( -table => $self->{curr_table}, -object_class => $object_class );
        my $temp;
        if ($roadmap) {
            ##### GOTTA COMBINE ROADMAP and map
            if (JSON->VERSION =~/^1/) { $temp = JSON::jsonToObj($roadmap) }
            else { $temp = JSON::from_json($roadmap) }

            my %file = %$map;
            my %road = %$temp;
            for my $key ( keys %road ) {
                if ( $file{$key} =~ /^hash/i && $road{$key} =~ /^hash/i ) {
                    $road{$key}{Grey} = $file{$key}{Grey};
                    $road{$key}{Omit} = $file{$key}{Omit};
                }
            }
        }
        else {
            $temp = $map;
        }

        my $js_object;
        if (JSON->VERSION =~/^1/) { $js_object = JSON::objToJson($temp) }
        else { $js_object = JSON::to_json($temp) }

        my $output = '';
        $output .= "<table id='formNavigator' class='formNavigator' border=1>";

        if ( $self->{append_html} ) {
            $output .= "<TR><td id='navRoadMap' class='navRoadMap' valign='top'></td><TD id='FormNavExtraHTML'>$self->{append_html}</TD></TR>";
        }
        if ( $self->{append_hidden_html} ) {
            $output .= "$self->{append_hidden_html}";
        }
        
        my $db_user = $dbc->config('db_user');
        
        $output .= "<tr><td id='navRoadMap' class='navRoadMap' valign='top'></td><td id='formPlaceHolder'><!-- Form goes here --></td>
        </tr></table>";
        $output .= "<script language='javascript'>
        var formStruct  = {};
        var formData    = eval($formData); 
        var roadMapObj  = eval($js_object);
        var formConfigs = {
            'default_parameters':$default_params,
            'submit_parameters':$submit_params,
            'submitpage':'$submit_url',
            'submitsingle': '/$URL_dir_name/cgi-bin/ajax/storeobject.pl',
            'formgen': '/$URL_dir_name/cgi-bin/ajax/formgen.pl',
            'uniquecheck': '/$URL_dir_name/cgi-bin/ajax/unique_check.pl',
            'db_user': '$db_user',
            'database':'$self->{dbc}{dbase}',
            'database_host':'$self->{dbc}{host}',
            'allowSaveDraft':'$self->{allow_draft}',
            'DisableCompletion':'$self->{DisableCompletion}',
            'SubmissionID':'$self->{submission_id}',
            'target':'$self->{target}',
            'displayBranches':'none'
        };
        navDraw();
        </script>";

        if ($return_html) {
            return $output;
        }
        else {
            print $output;
            return 1;
        }
    }
    else {

        #        my $frozen = &RGTools::RGIO::Safe_Freeze(-name=>'Frozen_Form',-format=>'array',-value=>$self,-encode=>1);
        #        $configs{include}->{Frozen_Form} = $frozen if $freeze;
    }

    foreach my $config ( keys %{ $self->{configs} } ) {

        if ( $config =~ /highlight/i ) {
            foreach my $element ( @{ $self->{configs}->{$config} } ) {
                my $table;
                my $field;

                if ( $element =~ /(\w+)\.(\w+)/ ) {
                    $table = $1;
                    $field = $2;
                }
                elsif ( $element =~ /(\w+)/ ) {
                    $field = $1;
                }

                if ( !$table || ( $table eq $self->{curr_table} ) ) {
                    push( @{ $configs{$config} }, $field );
                }
            }
        }
        else {
            foreach my $key ( keys %{ $self->{configs}->{$config} } ) {
                my $table;
                my $field;
                my $record;

                if ( $key =~ /^(\w+)\.(\w+)\:?(\d*)/ ) {    # Table provided
                    $table  = $1;
                    $field  = $2;
                    $record = $3;
                }
                elsif ( $key =~ /^(\w+)\:?(\d*)/ ) {        # No table provided
                    $field  = $1;
                    $record = $2;
                }

                #print "KEY=$key;TABLE=$table;FIELD=$field;RECORD=$record<br>";
                if ( !$table || ( $table eq $self->{curr_table} ) ) {

                    if ( !$record || ( $record eq $self->{curr_record} ) ) {

                        #print "CONFIG: $config; T: $table; F: $field; VALUE=$self->{configs}->{$config}->{$key}<br>";
                        $configs{$config}->{$field} = $self->{configs}->{$config}->{$key};
                    }
                }
            }
        }
    }

    my $force = 0;
    unless ($navigator_on) {
        my ($has_child) = $self->_has_child( $self->{curr_table} );

        if ( $next_form && !$found && !$has_child ) {
            ## if the next form to be generated is not found, then generate what we have thus far (set -force=>1)##
            # Message("No more forms to fill in.  Click Finish to submit data entered thus far");
            # remove skip flags

            my @end_form_mode = ();
            if ( $mode =~ /Continue/ ) {
                push( @end_form_mode, 'Continue' );
            }

            if ( $mode =~ /Finish/ ) {
                push( @end_form_mode, 'Finish' );
            }

            if ( $mode =~ /Skip_and_Finish/ ) {
                push( @end_form_mode, 'Skip_and_Finish' );
            }

            $mode = join( ',', @end_form_mode );
            $force = 1;
        }
    }
    else {
        $force = 1;
    }

    return $self->_generate_form(
        -title             => $title,
        -preset            => $configs{preset},
        -highlight         => $configs{highlight},
        -omit              => $configs{omit},
        -grey              => $configs{grey},
        -list              => $configs{list},
        -condition         => $configs{condition},
        -require           => $configs{require},
        -fk_extra          => $configs{fk_extra},
        -filter            => $configs{filter},
        -mask              => $configs{mask},
        -include           => $configs{include},
        -extra             => $configs{extra},
        -mode              => $mode,
        -action            => $action,
        -groups            => $self->{configs}{groups},
        -form              => $form,
        -line_colour       => $line_colour,
        -return_html       => $return_html,
        -submit            => $submit,
        -force             => $force,
        -navigator_on      => $navigator_on,
        -attribute_tables  => $attribute_tables,
        -attribute_default => $attribute_default,
        -attributes        => $attributes,
        -attribute_order   => $attribute_order,
        -filter_by_dept    => $filter_by_dept,
        %args
    );
}

############################################################
# -Converts arrays of fields and values to $data{tables}->{Library}->{1}->{Library_Name} = 'CN001'.
# RETURN: The converted hash
############################################################
sub convert_arrays {
#####################

    my $self = shift;
    my %args = @_;

    my $table      = $args{-table};        # Table that contains the fields [String]
    my $fields_ref = $args{-fields};       # A list of fields to be used [ArrayRef]
    my $values_ref = $args{ -values };     # A list of values to be used [ArrayRef]
    my $index      = $args{ -index };      # Record index
    my $append_to  = $args{-append_to};    # Reference to an existing hash to append more data to [HashRef]

    my $dbc = $self->{dbc};

    my %data;
    if ( defined $append_to ) { %data = %{$append_to} }

    # Figure out the index if not provided
    unless ($index) {
        if (%data) {
            $index = () = keys %{ $data{tables}->{$table} };
            $index += 1;
        }
        else {
            $index = 1;
        }
    }

    my $array_index = 0;
    foreach my $field ( @{$fields_ref} ) {
        $data{tables}->{$table}->{$index}->{$field} = $values_ref->[$array_index];
        $array_index++;
    }

    # See if there are FK fields that are not specified (because they will be pointing to new primary IDs and don't know what they will be at this point yet)
    my %all_fields = &Table_retrieve( $dbc, 'DBTable,DBField', [ 'DBField_ID', 'DBTable_Name', 'Field_Name' ], "where DBTable_ID=FK_DBTable__ID and DBTable_Name = '$table'" );
    my $i = 0;

    while ( defined $all_fields{DBField_ID}[$i] ) {
        my $f = $all_fields{Field_Name}[$i];
        unless ( grep /\b$f\b/, @{$fields_ref} ) {
            if ( ( my $ref_table, my $ref_field ) = $dbc->foreign_key_check($f) ) {
                if ( defined $append_to and exists $data{tables}{$ref_table} ) {
                    $data{tables}->{$table}->{$index}->{$f} = "<$ref_table.$ref_field>";
                }
            }
        }

        $i++;
    }

    if ( $index == 1 ) {
        my $max_table_index = keys %{ $data{index} };
        $data{index}->{ $max_table_index + 1 } = $table;
    }

    return \%data;
}

################################
sub store_data {
################################
    my $self = shift;
    my %args = @_;

    my $table    = $args{-table};
    my $input    = $args{-input};
    my $data_ref = $args{-data};

    my $dbc = $self->{dbc};

    my $fields_ref = [];
    my $values_ref = [];

    $input = SDB::HTML::cleanse_input($input);

    my %data;
    if ($data_ref) { %data = %$data_ref }
    else {
        ( $fields_ref, $values_ref ) = $self->_generate_record( $dbc, $table, $input );
        my $index;
        if ( $self->{data} && keys %{ $self->{data} } ) {    # We have existing data
            %data = %{ $self->{data} };
        }

        #Determine whether we are dealing with the 1st,2nd,3rd,.....nth insert record of this table.
        $index = keys( %{ $data{tables}->{$table} } ) + 1;

        %data = %{ $self->convert_arrays( -table => $table, -fields => $fields_ref, -values => $values_ref, -index => $index, -append_to => \%data ) };
    }

    # overwrite add_tables list if it is not there yet
    if ( $self->{'data'}{'add_tables'} ) {
        $data{'add_tables'} = $self->{data}{add_tables};
    }
    else {
        my @add_tables = @{ $self->{'additional_tables'} };
        $data{'add_tables'} = \@add_tables;
    }

    # save the first table as well
    if ( $self->{'data'}{'curr_table'} ) {
        $data{'curr_table'} = $self->{'data'}{'curr_table'};
    }
    else {
        my $curr_table = $self->{'curr_table'};
        $data{'curr_table'} = $curr_table;
    }

    # save submission_dir and the external flag
    $data{'submission_dir'} = $self->{submission_dir};
    $data{'external'}       = $self->{external};

    # save configs
    my %configs = %{ $self->{'configs'} };
    $data{'configs'} = \%configs;

    $self->{data} = dclone( \%data );

    return %data;
}

#############################
sub retrieve_data {
#############################
    my $self = shift;
    my %args = @_;

    my $record = $args{-record};           # Which record to retrieve (By default retrieves all records)
    my $delete = $args{ -delete } || 0;    # Whether to delete the form session file after retrieval.

    my %data;

    %data = %{ $self->{data} };

    if ($record) {                         # Only retrieve specify record
        foreach my $table ( keys %{ $data{tables} } ) {
            foreach my $index ( sort { $a <=> $b } keys %{ $data{tables}{$table} } ) {
                if ( $index != $record ) {
                    delete $data{tables}{$table}{$index};    # Remove the records that we don't want
                }
            }
        }
    }

    return %data;
}

#########################
# Get/Set current table
#########################
sub curr_table {
####################
    my $self  = shift;
    my $value = shift;

    if ($value) {    # Set
        $self->{curr_table} = $value;
        ( $self->{curr_table_title} ) = $self->{dbc}->Table_find( 'DBTable', 'DBTable_Title', "where DBTable_Name='$self->{curr_table}'" );
    }

    return $self->{curr_table};
}

#########################
# Get/Set current mode
#########################
sub curr_mode {
    my $self  = shift;
    my $value = shift;

    if ($value) {    # Set
        $self->{curr_mode} = $value;
    }

    return $self->{curr_mode};
}

################################
# Get/Set extra branch conditions
################################
sub extra_branch_conditions {
    my $self  = shift;
    my $value = shift;

    if ($value) { $self->{extra_branch_conditions} = $value }
    return $self->{extra_branch_conditions};
}

################################
# Get/Set form data
################################
sub data {
    my $self  = shift;
    my $value = shift;

    if ($value) { $self->{data} = $value }

    return $self->{data};
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

###########################
sub _message {
###########################
    my $self = shift;
    my $msg  = shift;

    $msg =~ s/<CURR_TABLE>/$self->{curr_table_title}/g;
    Message($msg) unless $self->{quiet};
    return;
}

###########################
sub _get_formdata_file {
###########################
    my $self = shift;

    my $user_id = $self->{dbc}->get_local('user_id');
    my $cmd     = "ls -t $URL_temp_dir/$user_id:*.formdata";
    my $fback   = try_system_command($cmd);
    my $count   = 1;
    my $formdata_file;

    foreach my $file ( split /\n/, $fback ) {
        if ( -f $file ) {
            if ( $count == 1 ) {    #Only retrieve info from the most recent session.
                $formdata_file = $file;
            }
            else {                  #Delete all other old/obsolete session files if there are any.
                unlink $file;
            }
        }
        $count++;
    }
    return $formdata_file;
}

####################
sub _initialize {
####################
    #
    # Various initializations
    #
    my $self = shift;

    # Remove existing formdata file of the current user
    my $file = $self->_get_formdata_file();
    if ( $file && $self->{curr_mode} =~ /Normal|Start/i ) {
        Message("Removing existing form data file '$file'.");
        unlink $file;
    }
    $self->curr_table( $self->{start_table} );
    $self->{curr_record} = 1;

    ## Gotta add condition to make sure the form is chaning the database somehow
    if ( $self->{db_action} =~ /append|edit/ ) {
        my @read_only = $self->{dbc}->Table_find( 'DBField', "Field_Name", "WHERE Field_Options LIKE '%ReadOnly%' and Field_Table = '$self->{curr_table}'" );
        for my $item (@read_only) {
            my $qualified = $self->{curr_table} . '.' . $item;
            if ( $self->{configs}{preset}{$qualified} || $self->{configs}{preset}{$item} ) {
                $self->{configs}{grey}{$qualified} = $self->{configs}{preset}{$qualified};
            }
            elsif ( $self->{configs}{grey}{$qualified} || $self->{configs}{grey}{$item} ) { }
            elsif ( !$self->{configs}{omit}{$qualified} || !$self->{configs}{omit}{$item} ) {
                $self->{configs}{omit}{$qualified} = '';
            }
        }
    }

    #   $self->_message($SPECIFY_MSG);
    my $nextTable = '';
    ($nextTable) = Table_find( $self->{dbc}, 'DB_Form As C, DB_Form As P', 'C.Form_Table', "where P.DB_Form_ID = C.FKParent_DB_Form__ID and P.Form_Table = '$self->{curr_table}'" );

    #$self->{next_table} ||= $nextTable;
    if ($nextTable) {    # See if it is multipage form
        $self->{curr_mode} = 'Start';
        if   ( $self->{db_action} =~ /append/i ) { $self->{multipage} = 1 }
        else                                     { $self->{multipage} = 0 }

        #		$self->_message($CONTINUE_MSG . " ($nextTable)");

        # 		check if ok to optional_finish
        my ($can_finish) = &Table_find( $self->{dbc}, "DB_Form", "Finish", "WHERE Form_Table='$self->{curr_table}'" );
        if ( $can_finish && !$self->{finish_all} ) {

            #	      	$self->_message($UPDATE_MSG);
            $self->{curr_mode} = 'Continue,Finish';
        }

    }
    else {

        #    	  $self->_message($UPDATE_MSG);
    }
}
####################################
# Set the next form (if applicable)
#
# Return: anything if there is another form expected (or 0)
#######################
sub get_next_form {
#######################
    #
    # Get the next table in the sequence
    #
    my $self = shift;
    my %args = @_;
    my $stop = $args{-stop} || 6;
    my $next_table;
    my $dbc = $self->{dbc};

    if ( !$stop ) {
        Message("Possible recursive method problem, please notify LIMS admin");
    }

    my @mode            = ();
    my $prev_mode       = $q->param('DBUpdate');
    my $curr_db_form_id = '';

    # if ignoring DB_Form, just grab next additional table
    if ( $self->{ignore_db_form} ) {
        if ( @{ $self->{additional_tables} } ) {
            my $next_table_names = shift( @{ $self->{additional_tables} } );
            my $names;
            $names = Cast_List( -list => $next_table_names, -to => 'string', -autoquote => 1 ) if $next_table_names;
            my @next_tables;
            @next_tables = &Table_find( $dbc, "DBTable", "DBTable_Name", "WHERE DBTable_Name IN ('$names')" ) if $names;
            $self->curr_table( $next_tables[0] ) if @next_tables;
            foreach my $i ( 1 .. $#next_tables ) {
                push @{ $self->{additional_tables} }, $next_tables[$i];
            }

            $self->{curr_record} = $self->{next_record};
            $self->{next_record}++;

            # check if there are more tables
            if ( @{ $self->{additional_tables} } ) {
                @mode = ('Continue');
            }
            else {
                @mode = ('Finish');
            }
        }
        else {

            # end, set mode to finish
            @mode = ('Finish');
        }
    }
    else {

        # figure out which table to display
        # If not skipped, check if the current table has children
        #    If it does, grab the 'correct' child
        #    If it doesn't, get something from the additional_tables list
        # If skipped, grab the next table from the additional_tables list

        # process which table is the next table
        my ( $has_child, $optional_finish ) = $self->_has_child( $self->{curr_table} );

        if ( ( $prev_mode =~ /Skip/i ) && !($has_child) ) {

            # grab next additional table
            if ( scalar( @{ $self->{additional_tables} } ) > 0 ) {
                my $next_table_names = shift( @{ $self->{additional_tables} } );
                my $names;
                $names = Cast_List( -list => $next_table_names, -to => 'string', -autoquote => 1 ) if $next_table_names;
                my @next_tables;
                @next_tables = &Table_find( $self->{dbc}, "DBTable", "DBTable_Name", "WHERE DBTable_ID IN ('$names')" ) if $names;
                $next_table = $next_tables[0] if @next_tables;
                foreach my $i ( 1 .. $#next_tables ) {
                    push @{ $self->{additional_tables} }, $next_tables[$i];
                }
            }
        }
        else {

            # first, check if the previous table could be inserted more than once
            # if it can, then check if the record has gone over the maximum
            # if record has gone over, then fall through and look for the children
            # if record has not gone over, use the same table

            if ( ( $prev_mode !~ /Skip/i ) && ( ( $self->{curr_record} < $self->{curr_table_max} ) || ( $self->{curr_table_max} == -1 ) ) ) {
                $next_table = $self->{curr_table};
            }
            else {
                if ($has_child) {
                    my $form_condition;
                    if ( $self->{curr_db_form_id} ) {
                        $form_condition = "P.DB_Form_ID = $self->{curr_db_form_id}";
                    }
                    elsif ( $self->{curr_table} ) {
                        $form_condition = "P.Form_Table = '$self->{curr_table}'";
                    }
                    my $prev_table_name = $self->{curr_table};
                    my %info            = Table_retrieve(
                        $self->{dbc},
                        'DB_Form As C, DB_Form As P',
                        [ 'C.DB_Form_ID', 'P.Form_Table As Parent', 'C.Form_Table', 'C.Parent_Field', 'C.Parent_Value' ],
                        "where P.DB_Form_ID = C.FKParent_DB_Form__ID and $form_condition order by C.Form_Order"
                    );
                    my $i = 0;
                    while ( defined $info{DB_Form_ID}[$i] ) {
                        my $id     = $info{DB_Form_ID}[$i];
                        my $parent = $info{Parent}[$i];
                        my $table  = $info{Form_Table}[$i];
                        my $pf     = $info{Parent_Field}[$i];
                        my $pv     = $info{Parent_Value}[$i];

                        if ( $self->_check_branch( -parent_table => $parent, -parent_field => $pf, -parent_value => $pv ) ) {
                            if ($next_table) {
                                push @{ $self->{additional_tables} }, $table;
                            }
                            else {
                                $next_table = $table;
                            }

                            $self->{curr_db_form_id} = $id;
                        }
                        $i++;
                    }

                    if ( ( $prev_table_name eq $next_table ) && ( $self->{ignore_duplicate_tables} ) ) {
                        if ( $stop-- ) {
                            return $self->get_next_form( -stop => $stop );
                        }
                    }
                }
                else {
                    $self->{curr_db_form_id} = '';
                }

                if ( !$next_table ) {

                    # grab next additional table
                    if ( scalar( @{ $self->{additional_tables} } ) > 0 ) {
                        my $tablename = shift( @{ $self->{additional_tables} } );
                        $next_table = $tablename;
                    }

                }
            }
        }
        unless ($next_table) {
            return;
        }
        $curr_db_form_id = $self->{curr_db_form_id};
        ### Next table is known

        # grab all fields of the table
        my %fields;
        %fields = &Table_retrieve( $dbc, "DBTable,DBField", [ "Field_Name", "Foreign_Key", "Field_Options" ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name like '$next_table'" ) if $next_table;

        # check if all the fields of the next table are hidden, greyed, or inherited FKs
        # if it is, then fill in the values using store_data a=>hnd move to the next table

        my $can_skip;
        if ( $fields{'Field_Name'}[0] ) {    ## do not do this if field is not found in DB Table for some reason.
            $can_skip = 1;
        }
        else {
            $can_skip = 0;
        }
        my $index = 0;
        while ( exists $fields{'Field_Name'}[$index] ) {
            my $field_name    = $fields{'Field_Name'}[$index];
            my $foreign_key   = $fields{'Foreign_Key'}[$index];
            my $field_options = $fields{'Field_Options'}[$index];

            if ( ( exists $self->{configs}{omit}{"$next_table.$field_name"} || exists $self->{configs}{omit}{"$field_name"} ) || ( exists $self->{configs}{grey}{"$next_table.$field_name"} || exists $self->{configs}{grey}{"$field_name"} ) ) {

                # check if the field is hidden or greyed - ignore in this case...

            }

            # check if field is an inherited FK that has been defined
            elsif ($foreign_key) {
                my ( $foreign_table, undef, undef ) = $dbc->foreign_key_check($field_name);
                my @prev_tables = keys %{ $self->{data}{tables} };
                if ( grep( /^$foreign_table$/, @prev_tables ) ) {

                    #		    $can_skip = 0;  ## <CONSTRUCTION> - added this to prevent endless loop (grp_std_sol + continue) (?)
                    #		    last;
                }
                else {
                    $can_skip = 0;
                    last;
                }
            }
            else {

                # if the field is primary or hidden, then it is ok to skip anyway
                if ( $field_options !~ /Primary|Hidden|Obsolete|Removed/i ) {
                    $can_skip = 0;
                    last;
                }
                else {

                }
            }
            $index++;
        }

        # get min and max records, mode, force_finish
        my $prev_table   = $self->{curr_table};
        my $record_count = $self->{curr_record};
        my $table_max    = '';
        my $table_min    = '';

        $has_child       = 0;
        $optional_finish = 0;
        my $force_finish = 0;

        # if it is still the same table, just increment the curr_record count, otherwise reset
        if ( $prev_table eq $next_table ) {
            $record_count++;
        }
        else {
            $record_count = 1;
        }

        # determine if the table has children
        ( $has_child, $optional_finish ) = $self->_has_child($next_table);

        # if it doesn't have a child and there are no more additional tables, it is not skippable
        if ( ( !$has_child ) && ( scalar( @{ $self->{additional_tables} } ) == 0 ) ) {
            $can_skip = 0;
        }

        # check if the table is ok to finish
        if ($next_table) {
            ($force_finish) = &Table_find( $dbc, "DB_Form", "Finish", "WHERE Form_Table='$next_table'" );
        }
        else {
            $force_finish = 1;    ## force end here if next table not found ##
        }

        # if user can finish on a particular form that form should NOT be skipped
        # if the following line is removed the system crashes when inserting RNA_DNA_Collections because the last form has no editable fields and system tries to skip it
        $can_skip = 0 if $force_finish;

        # if it is on the last form of the series, then don't allow the system to skip
        if ($can_skip) {

            # if can be skipped, record values in grey and move to next table
            $self->store_data( -table => $next_table );
            if ( $stop-- ) { return $self->get_next_form( -stop => $stop ); }
        }

        # get minimum and maximum record counts
        my $maxmin_condition = "Form_Table='$next_table'";
        if ($curr_db_form_id) {
            $maxmin_condition = "DB_Form_ID = $curr_db_form_id";
        }

        my @maxmin = &Table_find( $dbc, "DB_Form", "Min_Records,Max_Records", "WHERE $maxmin_condition" );
        ( $table_min, $table_max ) = split ',', $maxmin[0];

        @mode = $self->_get_mode( -record => $record_count, -min => $table_min, -max => $table_max, -has_child => $has_child, -optional_finish => $optional_finish, -force_finish => $force_finish );

        $self->{next_table} = $next_table;
        $self->curr_table($next_table);
        $self->{curr_record}    = $record_count;
        $self->{curr_table_min} = $table_min;
        $self->{curr_table_max} = $table_max;
    }
    $self->{curr_table_multi_record_mode} = 'single';    ### Default to single record per form
    $self->{curr_mode} = join( ",", @mode );

    # <CONSTRUCTION> this method should have a return statement !! .. added
    return int( @{ $self->{additional_tables} } );
}

##################
# Returns preset values based upon data in source objects
#
# Input:
#   - tables in target form
#   - primary list of ids
#   - primary field which ids belong to
#
#
# Return hash of preset values (keyed on fields)
#################
sub merge_data {
#################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables       = $args{-tables} || $args{-table};
    my @sources      = Cast_List( -list => $args{-primary_list}, -to => 'array' );
    my $source_field = $args{-primary_field};
    my $preset       = $args{-preset};
    my @skip_list    = Cast_List( -list => $args{-skip_list}, -to => 'array' );

    my @fields = $dbc->get_fields( $tables, '', 'defined', -debug => 0 );
    my @primary_fields = $dbc->get_field_info( $tables, -type => 'Primary' );

    @fields = map { $a = $_; $a =~ s/ AS .*//i; $a; } @fields;
    my %Data;

    my $join_condition = $dbc->get_join_condition( -tables => $tables );
    $join_condition ||= 1;
    foreach my $id (@sources) {
        $Data{$id} = { $dbc->Table_retrieve( "$tables", \@fields, "WHERE $join_condition AND $source_field = $id", -debug => 0 ) };
    }
    my @deletes;
    foreach my $field (@fields) {

        $field =~ s/^\w+\.(\w+)/$1/gi;

        if ( grep( /^$field$/i, @skip_list ) ) {next}
        if ( grep /^$field$/, @primary_fields ) {next}

        ### for each field see if there is a consistently set field already in the sources ##
        foreach my $source ( keys %Data ) {
            if ( defined $Data{$source}{$field}[0] ) {
                my $value = $Data{$source}{$field}[0];
                if ( defined $preset->{$field} ) {
                    unless ( $value eq $preset->{$field} ) {
                        push( @deletes, $field );
                    }
                }
                else {
                    $preset->{$field} = $value;
                }
            }
        }
    }
    foreach (@deletes) {
        delete $preset->{$_};
    }
    return $preset;
}

##############################
# Add object attributes to the DB_Form preset hash
###############################
sub preset_fields {
###############################
    my %args     = @_;
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle [ObjectRef]
    my $preset   = $args{-preset};
    my $class    = $args{-class};                                                                    # Attribute class
    my $class_id = $args{-class_id};
    my $object   = $args{-object};

    my @fields          = @{ $object->{fields_list} };
    my $attribute_table = $class . "_Attribute";

    my %attr_info;
    if ( grep /^$attribute_table$/, $dbc->DB_tables() ) {
        %attr_info = Table_retrieve( $dbc, "$attribute_table,Field_Map", [ 'FKTarget_DBField__ID', 'Attribute_Value' ], "WHERE " . $class . "_Attribute.FK_Attribute__ID=Field_Map.FK_Attribute__ID AND FK_" . $class . "__ID= $class_id" );
    }

    my %field_info = Table_retrieve( $dbc, "DBField,Field_Map", [ 'Field_Name', 'Field_Table', 'FKTarget_DBField__ID' ], "WHERE Field_Map.FKSource_DBField__ID=DBField_ID" );

    if ( exists $field_info{FKTarget_DBField__ID}[0] ) {
        my @field_id   = @{ $field_info{FKTarget_DBField__ID} };
        my @field_name = @{ $field_info{Field_Name} };
        my @table_name = @{ $field_info{Field_Table} };

        for ( my $i = 0; $i < scalar(@field_id); $i++ ) {
            my $source_field_name = "$table_name[$i].$field_name[$i]";
            my ($target_field_name) = $dbc->Table_find( "DBField", "Field_Name", "WHERE DBField_ID = $field_id[$i]" );
            if ( grep /^$source_field_name$/, @fields ) {
                $preset->{"$target_field_name"} = $object->get_data($source_field_name);
            }
        }
    }

    if ( exists $attr_info{FKTarget_DBField__ID}[0] ) {
        my @field_id = @{ $attr_info{FKTarget_DBField__ID} };
        my @attr_val = @{ $attr_info{Attribute_Value} };

        for ( my $i = 0; $i < scalar(@field_id); $i++ ) {
            my ($field_name) = $dbc->Table_find( "DBField", "Field_Name", "WHERE DBField_ID = $field_id[$i]" );
            my $value = $attr_val[$i];
            $preset->{"$field_name"} = "$value";
        }
    }
    return;
}

#
# Standard addition of record from form input
# (NOT reliant upon normal form navigator)
#
#
##############################
sub add_Record_from_Form {
##############################
    my %args  = filter_input( \@_ );
    my $table = $args{-table};
    my $quiet = $args{-quiet};
    my $dbc   = $args{-dbc};

    my @fields = $dbc->get_fields( -table => $table );
    my ( @append_fields, @values );
    foreach my $field (@fields) {
        $field =~ s/ AS .*//;
        my ( $t, $f ) = split /\./, $field;
        my $value = SDB::HTML::get_Table_Param( -field => $f, -table => $t, -dbc => $dbc );

        if ( ( $field =~ /^FK.+\_/ || $field =~ /\.FK.+\_/ ) && $value !~ /^\d+$/ && $value ) {
            $value = $dbc->get_FK_ID( $field, $value );
        }

        if ( length($value) ) {
            push @append_fields, $f;
            push @values,        $value;
        }
    }

    my $id = $dbc->Table_append_array( $table, \@append_fields, \@values, -autoquote => 1 );

    if ( !$quiet ) { $dbc->message( "Added $table record: " . $dbc->display_value($table, $id) ) }

    return $id;
}

#########################
sub _generate_record {
#########################
    #
    # Generate the record to a pair of arrays
    #

    my $self  = shift;
    my $dbc   = shift;
    my $table = shift;
    my $input = shift;    ### optional extra parameteers...

    my %Input;
    if ($input) {
        %Input = %{$input};
    }

    my $class_key;        ## for dynamic FKs
    my @table_prompts = getprompts( $dbc, $table );
    my @table_fields = map {
        my $f = $_;
        if ( $f =~ /(.*) as (.*)/i )    { $f         = $1; }
        if ( $f =~ /Object_Class__ID/ ) { $class_key = $f; }
        $_ = $f;
    } &get_fields( $dbc, $table, undef, 'defined' );    ### (was get_defined_fields) ##

    my @ret = &get_fields( $dbc, $table, undef, 'defined', -test => 1 );

    #    foreach my $table (split ',', $TableName) {
    unless ( %Field_Info && defined $Field_Info{$table} ) { initialize_field_info( $dbc, $table ) }

    #    }

    my $fields       = int(@table_fields);
    my @added_fields = ();
    my @added_values = ();

    for my $index ( 1 .. $fields ) {
        my $field = $table_fields[ $index - 1 ];
        my $table = '';
        ( $table, $field ) = simple_resolve_field($field);

        my $class;
        if ($class_key) {
            ## If there is a dynamic foreign key, find the referenced object class ##
            ## put inside the loop to allow for more than one of these in a multi-page form ##
                   $class = SDB::HTML::get_Table_Param( -table => $table, -field => 'FK_Object_Class__ID', -dbc => $dbc )
                || $Input{'FK_Object_Class__ID'}
                || $Input{"$table.FK_Object_Class__ID"}
                || $self->{configs}{grey}{"$table.FK_Object_Class__ID"}
                || $self->{configs}{hidden}{"$table.FK_Object_Class__ID"};
        }

        my $param;
        if ( $Field_Info{$table}{$field}{Type} =~ /set/ ) {
            if ( $Input{$field} ) {
                $param = $Input{$field};
            }
            elsif ( $q->param($field) ) {
                $param = join ",", $q->param($field);
            }
        }
        else {
            $param = &SDB::HTML::get_Table_Param( $table, $field, \%Input, -dbc => $dbc );

            # override for the value (if not set)
            unless ( defined $param ) {
                if ( defined $self->{configs}{grey}{"$table.$field"} ) {
                    $param = $self->{configs}{grey}{"$table.$field"};
                }
                if ( defined $self->{configs}{grey}{$field} ) {
                    $param = $self->{configs}{grey}{$field};
                }
                if ( defined $self->{configs}{omit}{"$table.$field"} ) {
                    $param = $self->{configs}{omit}{"$table.$field"};
                }
                if ( defined $self->{configs}{omit}{$field} ) {
                    $param = $self->{configs}{omit}{$field};
                }
                if ( defined $self->{configs}{hidden}{"$table.$field"} ) {
                    $param = $self->{configs}{hidden}{"$table.$field"};
                }
                if ( defined $self->{configs}{hidden}{$field} ) {
                    $param = $self->{configs}{hidden}{$field};
                }
            }
        }

        if ( !( defined $param ) ) {next}

        my $newvalue = $param;

        #
        # Foreign Keys ...
        #
        ( my $fk ) = $dbc->foreign_key_check( $field, -class => $class );
        if ($fk) {
            my $save = $newvalue;
            $newvalue = &get_FK_ID( $dbc, $field, $newvalue, -class => $class );
            if ( $newvalue =~ /(\d+):/ ) { $newvalue = $1; }
            elsif ( $newvalue =~ /^[\"\']*(\d+)[\"\']*$/ ) { $newvalue = $1; }
            if ( !$newvalue && $class && $field eq "Object_ID" ) {
                my ($class_primary_key) = get_field_info( $dbc, $class, undef, 'Primary' );
                $newvalue = "<$class.$class_primary_key>";
            }    ### enable new record references to be auto-filled by Batch_append ###
            if ( !$newvalue && $save =~ /\w+/ ) { $newvalue = $save; }    #This is for cases like library name.
        }
        if ( $field =~ /Quantity|Size$/ ) {                               ### convert 500m to 0.5
            ($newvalue) = &get_number($newvalue);
        }

        push( @added_fields, $field );
        push( @added_values, $newvalue );
    }

    # <CUSTOM> custom handling for LibraryAttribute table
    if ( $table eq 'LibraryApplication' ) {

        # find the object class
        # do an FK_ID check for Object_ID
        my $value_index     = '';
        my $object_class_id = '';
        foreach my $i ( 1 .. $#added_fields + 1 ) {
            my $field = $added_fields[ $i - 1 ];
            if ( $field eq 'FK_Object_Class__ID' ) {
                $object_class_id = $added_values[ $i - 1 ];
            }
            if ( $field eq 'Object_ID' ) {
                $value_index = $i - 1;
            }
        }
        if ($object_class_id) {
            my ($class) = &Table_find( $dbc, "Object_Class", "Object_Class", "WHERE Object_Class_ID=$object_class_id" );
            $added_values[$value_index] = $dbc->get_FK_ID( "Object_ID", $added_values[$value_index], -class => $class );
        }
    }

    return ( \@added_fields, \@added_values );
}

###################
sub _has_child {
###################
    #
    # See if the current table has a child table
    #
    my $self  = shift;
    my $table = shift;

    my $optional_finish = 1;    # Whether the current table can be the finish point of the series.  This happens if ALL the direct child tables has min records of 0
    my $has_child       = 0;

    # my ($has_child,$min_records) = Table_find($self->{dbc},'DB_Form As C, DB_Form As P','C.DB_Form_ID,C.Min_Records',"where P.DB_Form_ID = C.FKParent_DB_Form__ID and P.Form_Table = '$table'");
    my $form_condition = "P.Form_Table = '$table'";
    if ( $self->{curr_db_form_id} ) {
        $form_condition = "P.DB_Form_ID = $self->{curr_db_form_id}";
    }

    my %info = Table_retrieve( $self->{dbc}, 'DB_Form As C, DB_Form As P', [ 'C.DB_Form_ID', 'C.Form_Table', 'C.Min_Records' ], "where P.DB_Form_ID = C.FKParent_DB_Form__ID and $form_condition" );

    my $i = 0;
    if (%info) {
        while ( defined $info{DB_Form_ID}[$i] ) {
            my $form_id     = $info{DB_Form_ID}[$i];
            my $form        = $info{Form_Table}[$i];
            my $min_records = $info{Min_Records}[$i];
            $has_child = 1;
            if   ( $self->{db_action} =~ /append/i ) { $self->{multipage} = 1 }
            else                                     { $self->{multipage} = 0 }
            if ( $min_records == 0 ) {    # Now lets check the children
                my %child_info = Table_retrieve( $self->{dbc}, 'DB_Form As C, DB_Form As P', [ 'C.DB_Form_ID', 'C.Form_Table', 'C.Min_Records' ], "where P.DB_Form_ID = C.FKParent_DB_Form__ID and P.Form_Table = '$form'" );
                if (%child_info) {
                    my $child_min_records = $child_info{Min_Records};
                    if ( $child_min_records && ( int( @{$child_min_records} ) ) ) {
                        my $sum = 0;
                        foreach my $min ( @{$child_min_records} ) {
                            $sum += $min;
                        }
                        if ( $sum > 0 ) {
                            $optional_finish = 0;
                            last;
                        }
                    }
                }
            }
            else {
                $optional_finish = 0;
                last;
            }

            $i++;
        }
    }
    return ( $has_child, $optional_finish );
}

###################
sub _get_mode {
###################
    my $self = shift;
    my %args = @_;

    my $record          = $args{-record};
    my $min             = $args{-min};
    my $max             = $args{-max};
    my $has_child       = $args{-has_child};
    my $optional_finish = $args{-optional_finish};
    my $force_finish    = $args{-force_finish};

    my $prompt;

    if ( $max == -1 ) {
        $prompt = "a minimum of $min record(s)";
    }
    else {
        if ( $min == $max ) {
            $prompt = "$min record(s)";
        }
        else {
            $prompt = "$min to $max records";
        }
    }

    #    Message("Please enter $prompt (current: $record records)");

    my @mode;
    my $msg;

    if ($force_finish) { push( @mode, 'Finish' ) }
    if ( $min == 0 )   { push( @mode, 'Skip' ) }
    if ( ( $optional_finish && ( !$self->{finish_all} ) ) && ( $record >= $min || $max == -1 ) && ( int( @{ $self->{additional_tables} } ) == 0 ) ) {
        push( @mode, 'Finish' );
    }
    if ( $has_child || ( int( @{ $self->{additional_tables} } ) > 0 ) ) {
        if ( ( $min == 0 ) || ( ( $record > 1 ) && ( $record <= $max ) ) ) {

            push( @mode, 'Skip' );
        }
        push( @mode, 'Continue' );
    }
    else {
        if ( ( $min == 0 ) || ( ( $record > 1 ) && ( $record <= $max ) ) ) {
            push( @mode, 'Skip_and_Finish' );
        }
        if ( $record >= $min ) { push( @mode, 'Finish' ) }
        if ( $max == -1 )      { push( @mode, 'Finish' ) }

        if ( $max && $record && ( $record < $max ) ) { push( @mode, 'Continue' ) }
    }

    # if the finish all flag is on and there are still possible children, remove finish if it exists
    if ( $self->{finish_all} && ( $has_child || ( int( @{ $self->{additional_tables} } ) > 0 ) ) ) {
        @mode = map { $_ if ( $_ !~ /Finish/ ) } @mode;
    }
    return @mode;
}

######################
sub _check_branch {
######################
    #
    # Returns whether the current child is the appropiate branch
    #
    my $self = shift;
    my %args = @_;

    my $pt = $args{-parent_table};
    my $pf = $args{-parent_field};
    my $pv = $args{-parent_value};

    my $retval = 0;

    my @parent_fields = split /,/, $pf;
    my @parent_values = split /,/, $pv;

    if ( @parent_fields && @parent_values ) {    # If parent field and value specified, then only append if the value matched the user input in the parent form.
        my %data = $self->retrieve_data();

        for ( my $i = 0; $i <= $#parent_fields; $i++ ) {
            my $pf = $parent_fields[$i];
            my $pv = $parent_values[$i];

            #print "PT=$pt;PF=$pf;PV=$pv<br>";
            my @pvs = split /\|/, $pv;
            if ( exists $data{tables}->{$pt}->{1}->{$pf} ) {
                my $specified_value = $data{tables}->{$pt}->{1}->{$pf};
                if ( grep /^$specified_value$/, @pvs ) {
                    $retval = 1;
                }
                elsif ( wildcard_match( $specified_value, \@pvs ) ) {
                    ## check for wildcards in parent value if applicable ##
                    $retval = 1;
                }
                else {
                    $retval = 0;    # If more than ONE field specified, then all values must be satifised
                    last;
                }
            }
            elsif ( exists $self->{extra_branch_conditions}{$pf} ) {
                my $specified_value = $self->{extra_branch_conditions}{$pf};
                if ( grep /^$specified_value$/, @pvs ) {
                    $retval = 1;
                }
                else {
                    $retval = 0;    # If more than ONE field specified, then all values must be satifised
                    last;
                }
            }
        }
    }
    elsif ( !@parent_fields && !@parent_values ) {    # No parent field and value specified.  Always append.
        $retval = 1;
    }

    #print "RETURN=$retval<Br>";

    return $retval;
}

####################################
sub _build_attribute_row {
###################################
    my $self = shift;

    my %args = @_;

    my $dbc               = $self->{dbc};
    my $attribute         = $args{-attribute};
    my $attribute_options = $args{-attribute_options};
    my $Form              = $args{-form};
    my $action            = $args{-action} || $self->{db_action};
    my $filter_by_dept    = $args{filter_by_dept};

    my $field_width          = 20;
    my $int_field_width      = 5;
    my $attribute_row_colour = '#FFFFCC';

    my ( $table, $field );
    if ( $attribute =~ /(\w+)\.(\w+)/ ) {
        $table = $1;
        $field = $2;
    }
    else {
        $field = $attribute;
    }

    my $type       = $attribute_options->{type};
    my $defaultset = $attribute_options->{value};
    my $prompt;

    if ( $attribute_options->{alias} ) {
        $prompt = $attribute_options->{alias};
    }
    else {
        $prompt = $field;
    }

    my $default;
    if ( ref $defaultset eq 'ARRAY' and scalar @$defaultset == 1 ) {
        $default = $defaultset->[0];
    }

    my $element_name = $field;
    $element_name =~s/\./\-/g;
        
    my $form_elem;
    my $onChange;
    my ( $extralink, $highlight );

    if ( $type =~ /^enum\((.+)\)/i ) {
        my @enum_list = split /,/, $1;
        @enum_list = map {
            if (/^[\'\"](.*)[\'\"]$/) { $_ = $1 }
        } @enum_list;

    eval "require alDente::Tools";

        $form_elem = alDente::Tools::search_list(
            -dbc            => $dbc,
            -name           => $field,
            -element_name   => $element_name,
            -options        => \@enum_list,
            -default        => $defaultset,
            -breaks         => 1,
            -filter_by_dept => $filter_by_dept,
            -id             => "$table.$field",
            -structname     => "$table.$field",
            -mode           => 'checkbox',
            -action         => $action,
        );
    }
    elsif ( $type =~ /^int/i ) {
        my $form_elem = &Show_Tool_Tip( $q->textfield( -name => $element_name, -size => $int_field_width, -default => $default, -force => 1, -structname => "$table.$field" ), "Attribute value" );
    }
    elsif ( $type =~ /^FK/i ) {

        $form_elem = alDente::Tools::search_list(
            -dbc            => $dbc,
            -field          => $type,
            -element_name   => $element_name,
            -default        => $default,
            -search         => 1,
            -filter         => 1,
            -filter_by_dept => $filter_by_dept,
            -breaks         => 1,
            -id             => "$table.$field",
            -mode           => 'scroll',
            -action         => $action,
        );
    }
    else {
        $form_elem = &Show_Tool_Tip(
            $q->textfield(
                -name       => $element_name,
                -size       => $field_width,
                -default    => $default,
                -onChange   => $onChange,
                -force      => 1,
                -id         => "$table.$field",
                -structname => "$table.$field"
            ),
            "Attribute value"
        );
    }

    $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight );

}

###################################
sub _generate_form {
###################################
    #
    # Generic form generated in HTML format.
    # (assumes form ALREADY initialized)
    #
    # Input:
    #   preset => {hash of values to be preset} - sets default values for textfields/popdowns etc.
    #   highlight =`> (array of field names to be highlighted) - useful if some fields fail validation check
    #   omit => {hash of fields to be omitted} - fields to be omitted from form (values set as indicated) (eg. {Date=>'2001-01-01'}
    #   grey => {hash of fields to be greyed out} - values are set as above, and appear in form, but with no input option ('greyed' out)
    #   target => xml or database - where the output of the form should go (into the database or into an xml file).
    #
    # <snip>
    # Example :
    #
    #  (use $Form->configure to access this method - do NOT access this method directly - see example below)
    #
    #  my $Form = SDB::DB_Form->new(-dbc=>$dbc,-table=>$table,-target=>'Database',-form=>$FormName);
    #  $Form->configure(-preset=>{$field1=>$value1,$field2=>$value2),-grey=>{$field3=>$value3});
    #  $Form->generate();                     ## calls _configure method applying applicable configuration settings.
    #
    # </snip>
##############################################
    my $self = shift;
    my %args = @_;

    #   my $Href = $args{-highlight} || 0;  ### specify field areas to be highlighted
    my $preset = $args{-preset}    || 0;    ### specify field values that are preset
    my $Oref   = $args{-omit}      || 0;    ### specify fields to be omitted (fields don't show up in the form but still include in HIDDEN tags)
    my $Gref   = $args{-grey}      || 0;    ### specify fields to be 'greyed out'
    my $Lref   = $args{-list}      || 0;    ### specify lists for popup menus
    my $Cref   = $args{-condition} || 0;    ### specify condition to filter popup menu list
    my $Rref   = $args{ -require } || 0;    ### dynamically require fields
    my $Fref   = $args{-fk_extra}  || 0;    ### Extra value to added to the FK list.
    my $Sref   = $args{-skip}      || 0;    ### specify fields to be skipped (fields don't show up in the form and won't be included in HIDDEN tags)
    my $Mref   = $args{-mask}      || 0;    ### specify mask for values to be show in popup menu (e.g. if mask is 'Sequencing' then only items that match 'Sequencing' will show)
    my $Eref   = $args{-extra}     || 0;    ### specify extra column for fields in addition to the auto-generated form element

    my $form_name = $args{-form}    || $self->{form_name} || 'AutoForm';
    my $include   = $args{-include} || 0;                                  ### include parameters
    my $mode      = $args{-mode}    || $self->{curr_mode};                 # Mode can be either Normal,Start,Continue,Finish,
    my $append_Table = $args{-append};

    my $filter = $args{-filter};                                           ## <CONSTRUCTION> (same as mask ?)

    my $dbc              = $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table            = $self->{curr_table};                                                              ## supply single table
    my $fields           = $self->{field_list};                                                              ## alternatively use supplied list of FULLY QUALIFIED fields ##
    my $aliases          = $self->{aliases};                                                                 ## List of field aliases to overwrite Prompt in DBField
    my $real_table_names = $self->{-real_table_names};                                                       ##List of real table names, for fields with alias for table names eg. Source.Source_ID to S1.Source_ID
    my $target           = $self->{target};                                                                  ## specify write to database or xml...
    my $parameters       = $self->{parameters};                                                              # specify parameters to pass to form initialization.
    my $toggle           = $args{-toggle} || 'on';

    my $title         = $args{-title};
    my $action        = $args{-action} || $self->{db_action} || 'edit';                                      # this switch indicates that the form is being updated ('edit', or 'search', 'reference search')...
    my $return_html   = $args{-return_html};
    my $element_names = $args{-element_names};                                                               # allow overriding of element names (defaults to field name)

    my $reset = $args{ -reset } || $self->{reset};                                                           # Reset the form to the blank state so it doesn't carry over the values from the previous instance of the form.
    if ($reset) { $self->{reset} = 1 }

    #   my $wrap = $args{-wrap} || $self->{wrap};            ### wrap form with 'start_form' and end_form
    my $start_form = $args{-start_form} || $self->{start_form};
    my $end_form   = $args{-end_form}   || $self->{end_form};
    my $submit       = defined $args{-submit} ? $args{-submit} : 1;                                          ## whether to include the submit, reset buttons and the form session elements
    my $line_colour  = $args{-line_colour};
    my $force        = $args{-force};
    my $navigator_on = $args{-navigator_on};

    my $attribute_tables  = $args{-attribute_tables};
    my $attribute_default = $args{-attribute_default};
    my $attributes        = $args{-attributes};
    my $attribute_order   = $args{-attribute_order};

    my $filter_by_dept = $args{-filter_by_dept};
    my $repeats        = $self->{repeat} || 0;                                                               ## indicate whether repeat rows are included (affects form validator)
    my $button         = $args{-button};                                                                     ## override button name/value pair (eg -button=>{'rm'=>'update record'} )
    my $select         = $args{ -select };                                                                   ## indicate whether 1st column should be a selectable checkbox.

    my $user_id = $dbc->get_local('user_id');

    if ( defined $select ) { $self->{selectable} = $select }

    my $target_display = 'Database';
    if ( $target =~ /xml|hash|stor|submi/i ) {
        $target_display = 'Submission';
    }

    my $multi_record_mode = $self->{curr_table_multi_record_mode};
    my $multi_record_num  = $self->{curr_table_multi_record_num};
    my %filter_list;

    my $extralink;
    $self->{prefix} = '';

    if ($start_form) {
        my %Parameters;
        if ($parameters) { %Parameters = %{$parameters} }

        my $form = new LampLite::Form( -dbc => $dbc );
        $self->{prefix} .= $form->generate( -open => 1 );

        $self->{prefix} .= $q->hidden( -name => 'DBTable', -value => $table, -force => 1 ) . "\n" . $q->hidden( -name => 'TableName', -value => $table, -force => 1 ) . "\n" . $q->hidden( -name => 'Target', -value => $target, -force => 1 ) . "\n";
    }

    $self->{prefix} .= $q->hidden( -name => 'DBForm', -value => $table, -force => 1 ) . "\n";

    # variable for table list
    # usually just one table
    # add 1 for each field with an add link

    unshift @{ $self->{all_table_list} }, ($table);
    if ($filter) {
        %filter_list = %{$filter};
    }
    ## ensure current user has permission to edit database (otherwise mark target as Storable) ##
    unless ( !$self->{dbc} || $self->{dbc}->check_permissions( $user_id, $table, $action, -groups => $self->{configs}{groups} ) ) {
        unless ( $action =~ /search/i ) {
            my $warning_msg1 = "Warning: $user does not have permission to $action $table records directly.";
            my $warning_msg2 = 'You may continue, but forms will be submitted to Lab Administrators rather than appended to the database.';
            if ( $dbc->session->message->{multipage} ) {
                $dbc->message("$warning_msg1<br>$warning_msg2");
            }
            else {
                $dbc->message("$warning_msg1\n$warning_msg2");
            }
        }
        $target = 'submission';
    }

    my $dbtitle;
    my $dbdesc;
    if ($table) {
        unless ( %Field_Info && defined $Field_Info{$table} ) { initialize_field_info( $dbc, $table ) }    ## populate field info from DB_Field.
        my %dbtable_info = $dbc->Table_retrieve( 'DBTable', [ 'DBTable_Title', 'DBTable_Description' ], "WHERE DBTable_Name='$table'" );
        $dbtitle = $dbtable_info{DBTable_Title}[0];
        $dbdesc  = $dbtable_info{DBTable_Description}[0];
    }
    
    ## set title to description for this table ##
    unless ($title) {
        $title = $dbtitle ? $dbtitle : $table;
    }

    my $Form;
    if ($append_Table) {
        $Form = $append_Table;
        $Form->Set_sub_header( $title, 'vdarkbluebw' ) if $title;
    }
    else {
        $Form = HTML_Table->new();
        $Form->Set_Class('small');
        $Form->Set_Title($title);
        my $subheader;
        $subheader = $dbdesc if ($dbdesc);
        $Form->Set_sub_header( "$subheader (Mouse over fields for tooltips)", 'vlightbluebw' );
        $Form->Toggle_Colour($toggle);
    }

    if ( defined $self->{selectable} ) {
        my $toggle = $q->checkbox( -name => 'All / None', -value => 'toggle', -onclick => "ToggleNamedCheckBoxes(this.form,'Toggle','Select');" );
        $Form->Set_sub_header($toggle);
    }

    ## Omitted fields ##
    $self->{Omit} = {};
    my $omitlist;
    if ($Oref) {
        $self->{Omit} = $Oref;
    }
    elsif ( $q->param('Omit') ) {
        $omitlist = join ',', $q->param('Omit');
        foreach my $Ofield ( split ',', $omitlist ) {
            my $Ovalue = $q->param($Ofield);
            my $value = get_FK_info( $dbc, $Ofield, $Ovalue );
            $self->{Omit}{$Ofield} = $value || '';
        }
    }

    ## Specify contents of Dropdown menu lists ##
    $self->{List} = {};
    my $listparam;
    if ($Lref) {
        $self->{List} = $Lref;
    }

    if ($Cref) {
        $self->{Condition} = $Cref;
    }

    ## Greyed out fields ##
    $self->{Grey} = {};
    my $greylist;
    if ( $Gref && keys %{$Gref} ) {
        $self->{Grey} = $Gref;
        $greylist = join ',', keys %{$Gref};
    }
    elsif ( $q->param('Grey') ) {
        $greylist = join ',', $q->param('Grey');

        foreach my $Gfield ( split ',', $greylist ) {
            my $Gvalue = $q->param($Gfield);
            my $value  = get_FK_info( $dbc, $Gfield, $Gvalue );
            my @found  = $q->param($Gfield);
            $self->{Grey}{$Gfield} = $value if defined $value;
        }
    }

    ## Included additional parameters ##
    $self->{Include} = {};
    if ($include) {
        $self->{Include} = $include;
    }

    ## Preset parameters ##
    $self->{Preset} = {};
    if ($preset) {
        $self->{Preset} = $preset;
    }

    ## Specify Masking of FK lists (only including fields with specified text) ##
    $self->{Mask} = {};
    if ($Mref) { $self->{Mask} = $Mref }

    ## Specify extra text to be supplied after a given field prompt ##
    $self->{Extras} = {};
    my $extra_list;
    if ($Eref) { $self->{Extras} = $Eref }
    elsif ( $q->param('Extra') ) {
        $extra_list = join ',', $q->param('Extra');
        foreach my $Efield ( split ',', $extra_list ) {
            my $Evalue = $q->param($Efield);
            my $value = get_FK_info( $dbc, $Efield, $Evalue );
            $self->{prefix} = $q->hidden( -name => $Efield, -value => $Evalue );

            #	    $Form->Set_Row([$Efield,$Evalue]);
            $self->add_Section( $Form, $Efield, $Evalue );
        }
    }

    ## Specified required fields (above and beyond established Mandatory fields) ##
    $self->{Require} = {};
    if ( $Rref && ref $Rref eq 'HASH' ) {
        $self->{Require} = $Rref;
        my $required = join ',', keys %{ $self->{Require} };
        $self->{prefix} .= $q->hidden( -name => 'Require', -value => $required, -force => 1 ) . "\n";
    }

    ## Extra info/options for fields ##
    $self->{FK_extra} = {};
    my @fk_extra_list = $q->param('fk_extra');
    if ($Fref) {
        $self->{fk_extra} = $Fref;
    }
    elsif (@fk_extra_list) {
        foreach my $pair (@fk_extra_list) {

            #Pair is FIELD:VALUE
            $pair =~ /^(.+):(.+)$/;
            $self->{fk_extra}{$1} = $2;
        }
    }

    ## Skip fields ##
    $self->{Skip} = {};
    if ( $self->{start_form} ) {
        if ($Sref) {
            $self->{Skip} = $Sref;
            my $skipped = join ',', keys %{$Sref};
            $self->{prefix} .= $q->hidden( -name => 'Skip', -value => $skipped, -force => 1 ) . "\n";
        }
        else {
            $self->{prefix} .= $q->hidden( -name => 'Skip', -value => '', -force => 1 ) . "\n";
        }
    }

    ( my $today ) = split ' ', &RGTools::RGIO::date_time();

    my $DBtables  = "DBField,DBTable";
    my $condition = "FK_DBTable__ID=DBTable_ID";
    my $order     = "ORDER BY Field_Order";
    my @temp_field;

    if ($table) {
        ### get applicable fields for current table ###
        $condition .= " AND DBTable_Name = '$table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'";
        $order = "ORDER BY Field_Order";
    }
    elsif ($fields) {
        $fields = [ @$fields, 'Original_Source_Attribute.Biological_Condition' ];    ############### WTF ???????!!!!!!!! ##############

        if ( defined $real_table_names ) {

            #duplicate fields into temp_field but with real table names to get field information eg. Prompt, description, etc...
            foreach my $field (@$fields) {
                my $temp_field = $field;
                if ( $field =~ /(\w+)\.(\w+)/i ) {
                    my $table           = $1;
                    my $real_table_name = $real_table_names->{$table};               #get table name from table alias

                    if ($real_table_name) {
                        $temp_field = "$real_table_name.$2";
                    }
                }
                else {
                    $temp_field = $field;
                }

                push @temp_field, $temp_field;
            }
        }
        else {
            @temp_field = @{$fields};
        }

        ## get table info for supplied list of fields ###
        my $field_list = Cast_List( -list => \@temp_field, -to => 'string', -autoquote => 1 );
        $field_list ||= "''";    ## in case of empty field list ##

        $condition .= " AND CONCAT(DBTable_Name,'.',Field_Name) IN ($field_list)";
    }

    my %temp_Table_info
        = Table_retrieve( $dbc, $DBtables, [ 'DBField_ID', 'Field_Name', 'Prompt', 'Field_Description', 'Field_Default', 'Field_Type', 'Field_Options', 'Field_Alias', 'Field_Format', 'Editable', 'Tracked', 'DBTable_Name' ], "WHERE $condition $order" );
    my @headers = &Table_find( $dbc, $DBtables, 'Field_Alias', "where $condition $order" );    # @{ $Table_info{Field_Alias} };

    my $records = $#{ $temp_Table_info{Field_Name} };
    my @indices;

    my %Table_info;
    if ($fields) {
        my $field_counter = 0;
        ## if field list is supplied, track order of indices within Table_info hash ##
        foreach my $field (@$fields) {
            foreach my $index ( 0 .. $records ) {
                if ( $temp_field[$field_counter] eq "$temp_Table_info{DBTable_Name}[$index].$temp_Table_info{Field_Name}[$index]" ) {

                    foreach my $field_info ( keys %temp_Table_info ) {
                        ## eg $Table_info{Prompt}[$i] = $temp_Table_info{Prompt}[$i]
                        $Table_info{$field_info}[$field_counter] = $temp_Table_info{$field_info}[$index];
                    }

                    if ( exists $aliases->{$field} ) {
                        $Table_info{Prompt}[$field_counter] = $aliases->{$field};
                    }

                    if ( defined $real_table_names && $field =~ /(\w+)\.(\w+)/i ) {
                        $Table_info{DBTable_Alias}[$field_counter] = $1;
                    }

                    push( @indices, $field_counter );
                }
            }
            $field_counter++;
        }
    }
    else {
        @indices    = 0 .. $records;
        %Table_info = %temp_Table_info;
    }
    undef @temp_field;
    undef %temp_Table_info;

    # <CUSTOM>
    # check if any fields reference Object_Class_ID. If it does, replace the object class with the assigned class in DB_Form, and fill in Object_ID with
    # a popup menu with the class' get_FK_info.
    my $object_class      = '';
    my @object_class_list = ();

    if ( defined $self->{Grey}{'FK_Object_Class__ID'} || defined $self->{Grey}{'LibraryApplication.FK_Object_Class__ID'} ) {
        my $class_id = $self->{Grey}{'FK_Object_Class__ID'} || $self->{Grey}{'LibraryApplication.FK_Object_Class__ID'};
        $object_class = &get_FK_info( $dbc, "FK_Object_Class__ID", $class_id );
        @object_class_list = &get_FK_info_list( -dbc => $dbc, -field => "FK_Object_Class__ID", -class => $object_class );
    }
    elsif ( defined $self->{Preset}{"FK_Object_Class__ID"} && length( $self->{Preset}{'FK_Object_Class__ID'} ) > 0 ) {
        my @values = ();
        if ( ref( $self->{Preset}{'FK_Object_Class__ID'} ) eq 'ARRAY' ) {
            @values = @{ $self->{Preset}{'FK_Object_Class__ID'} };
        }
        else {
            @values = ( $self->{Preset}{'FK_Object_Class__ID'} );
        }

        # allow for multiple preset records for the same table
        my $class_id = $values[ $self->{curr_record} - 1 ];
        if ($class_id) {
            $object_class = &get_FK_info( $dbc, "FK_Object_Class__ID", $class_id );
            @object_class_list = &get_FK_info_list( -dbc => $dbc, -field => "FK_Object_Class__ID", -class => $object_class );
        }
    }
    elsif ( $self->{curr_db_form_id} && ( grep ( /^FK_Object_Class__ID$/, @{ $Table_info{"Field_Name"} } ) ) ) {
        ($object_class) = &Table_find( $dbc, "DB_Form", "Class", "WHERE DB_Form_ID = $self->{curr_db_form_id}" );
        @object_class_list = &get_FK_info_list( -dbc => $dbc, -field => "FK_Object_Class__ID", -class => $object_class );
    }
    elsif ( grep ( /^FK_Object_Class__ID$/, @{ $Table_info{"Field_Name"} } ) ) {
        ($object_class) = &Table_find( $dbc, "DB_Form", "Class", "WHERE Form_Table = '$table'" );
        @object_class_list = &get_FK_info_list( -dbc => $dbc, -field => "FK_Object_Class__ID", -class => $object_class );
    }

    my %data = $self->retrieve_data();

    $self->{input_fields} = 0;
    my $primary_field;
    ($primary_field) = get_field_info( $dbc, $table, undef, 'Primary' ) unless $fields;

    my $primary_default = $q->param($primary_field) || $self->{Grey}{$primary_field} || $self->{Preset}{$primary_field};
    my $update = 0;
    if ($primary_default) {

        # replaced the above line with this more elegant line
        $self->{ $self->{curr_table} }{primary_value} = $primary_default;
        $self->{prefix} .= $q->hidden( -name => "primary_value", -value => $primary_default, -force => 1 ) . "\n";
        $update = 1;
    }

    my @random_ids;

    for my $index (@indices) {
        ## separate logic for generation of each row ##
        my $element_name;
        if ( defined $element_names ) {
            ## allow input element_names to override default (field_name by default) ##
            if ( defined $element_names->{ $Table_info{Field_Name}[$index] } ) { $element_name = $element_names->{ $Table_info{Field_Name}[$index] } }
        }
        my $ok = $self->_build_row(
             $index,
            -data              => \%data,
            -info              => \%Table_info,
            -form              => $Form,
            -form_name         => $form_name,
            -object_class      => $object_class,
            -object_class_list => \@object_class_list,
            -target_display    => $target_display,
            -update            => $update,
            -action            => $action,
            -filter_by_dept    => $filter_by_dept,
            -navigator_on      => $navigator_on,
            -element_name      => $element_name,
            -row_index         => $index,
        );
    }

    if ( $attributes and ref $attributes eq 'HASH' and $attribute_order and ref $attribute_order eq 'ARRAY' ) {
        foreach my $attr (@$attribute_order) {
            $self->_build_attribute_row(
                -attribute         => $attr,
                -attribute_options => $attributes->{$attr},
                -form              => $Form,
                -action            => $action,
                -filter_by_dept    => $filter_by_dept
            );
        }
    }

    #  No longer necessary ??
    #
    if ( !$self->{input_fields} ) {

        #	if ($table eq $self->{start_table}) {
        #	    $self->store_data(-table=>$table);
        #	}
        #	return $self->generate(-next_form=>1) unless $force;
        #	$Form->Set_Row(["(No information required)"]);
        $self->add_Section( $Form, "No information required" );
    }
    ## if nothing here to update or edit .. skip to next form...

    foreach my $key ( keys %{ $self->{Include} } ) {
        my $value = $self->{Include}{$key};
        my $ref   = ref $value;
        if ( $ref eq 'ARRAY' ) {
            ### if an array is passed in, separate it into separate hidden parameters ##
            foreach my $part (@$value) {
                $self->{prefix} .= $q->hidden( -name => $key, -value => $part, -force => 1 ) . "\n";
            }
        }
        else {
            $self->{prefix} .= $q->hidden( -name => $key, -value => $value, -force => 1 ) . "\n";
        }
    }

    $Form->Set_Prefix( $Form->{prefix} . $self->{prefix} );
    $self->{form} = $Form;

    $Form->Set_Line_Colour($line_colour) if $line_colour;

    # retrieve attributes and add them to the display_Record table
    if ( defined $self->{Preset}{ $table . "_ID" } && $self->{Preset}{ $table . "_ID" } ) {
        my $id         = $self->{Preset}{ $table . "_ID" };
        my $db_object  = SDB::DB_Object->new( -dbc => $dbc );
        my @attributes = sort @{ $db_object->get_attributes( -table => $table, -id => $id ) };

        my $attributes = join '<BR>', @attributes;
        if ( scalar(@attributes) > 0 ) {
            $Form->Set_sub_header( "<B>Attributes (for information purposes only)</B>", 'bgcolor="#FFFFCC"' );
            $Form->Set_sub_header( "$attributes",                                       'bgcolor="#FFFFCC"' );
        }
    }

    my $output = $Form->Printout(0);

    if ($submit) {
        if ( $self->{append_html} ) {
            $output .= "<BR>\n";
            $output .= $self->{append_html};
            $output .= "<BR>\n";
        }
        if ( $self->{append_hidden_html} ) {
            $output .= $self->{append_hidden_html};
        }

        my $next_table;
        $next_table = $self->{additional_tables}[0] if $self->{additional_tables};
        my $submit_button = Show_Tool_Tip( $q->submit( -name => 'DBUpdate', -force => 1, -value => "Continue to $next_table form", -class => "Std", -onClick => "return validateForm(this.form,$repeats)" ), "$CONTINUE_MSG :" . $next_table );

        my $button_name;
        my $button_value;

        if ($button) {
            ## specified button ({name=>value}) ##
            ($button_name) = keys %{$button};    ## should only be one key at this stage ... may adapt to enable multiple buttons ...
            $button_value = $button->{$button_name};
        }
        else {
            $button_name = 'DBUpdate';           ## default to DBUpdate
        }

        my $msg;
        my $form_session;
        my $color;

        if ( $mode =~ /Normal/i ) {

            # Just update the database as usual.
            $button_value ||= "Update $table";
            $color = $Settings{EXECUTE_BUTTON_COLOUR};
        }
        elsif ( $mode =~ /Start/i ) {

            # Start a new form session.  Instead of update database right the way, the form data is saved.
            $form_session = "$user_id:" . localtime();
            $form_session =~ s/ /_/g;
            $button_value ||= "Continue";
            $msg   = "$CONTINUE_MSG : " . $next_table;    ## $self->{next_table};
            $color = $Settings{STD_BUTTON_COLOUR};
        }
        elsif ( $mode =~ /Continue/i && $mode =~ /Finish/i ) {

            #Allow user to choose either to continue gather more data or update database now.
            $form_session = $q->param('Form_Session');
            $output .= $submit_button;

            #	    $output .= Show_Tool_Tip( $q->submit(-name=>$button_name,-force=>1,-value=>'Continue',-class=>"Std"),
            #				     "$CONTINUE_MSG :" . $self->{next_table} );
            $button_value ||= "Finish";
            $msg   = $FINISH_MSG;
            $color = $Settings{EXECUTE_BUTTON_COLOUR};

            #	} elsif ($mode =~ /Continue/i && $mode =~ /Skip/i) { #Allow user to choose either to continue gather more data or skip gathering data from current form.
            #	    $form_session = $q->param('Form_Session');
            #	    $output .= $submit_button;
            #	    $output .= Show_Tool_Tip( $q->submit(-name=>$button_name,-force=>1,-value=>'Continue',-class=>"Std"),
            #				     "$CONTINUE_MSG : " . $self->{next_table} );
            #	    $button_value ||= "Skip";
            #	    $msg = $SKIP_MSG;

        }
        elsif ( $mode =~ /Continue/i ) {

            #Continue to gather more form data.
            $form_session = $q->param('Form_Session');
            $button_value ||= "Continue";

            $msg   = "$CONTINUE_MSG : " . $next_table;    ## $self->{next_table};
            $color = $Settings{STD_BUTTON_COLOUR};
        }
        elsif ( $mode =~ /Finish/i ) {

            #Update database with all the form data gathered.
            $form_session = $q->param('Form_Session');
            $button_value ||= "Finish";
            $msg   = $FINISH_MSG;
            $color = $Settings{EXECUTE_BUTTON_COLOUR};
        }
        ## these parameters ONLY get sent when print option is set on (by default)

        $output .= $q->hidden( -name => 'Form_Session', -value => $form_session, -force => 1 ) . "\n";
        $output .= $q->hidden( -name => 'Mode',         -value => $mode,         -force => 1 ) . "\n";

        if ( $action =~ /search/ ) {
            ## generate search button (?)...
        }
        elsif ( $mode =~ /no button/i ) { }
        else {
            if ( $mode =~ /Continue/i && $mode =~ /\bSkip\b/i ) {
                $output .= Show_Tool_Tip( $q->submit( -name => $button_name, -force => 1, -value => "Skip", -class => "Std" ), "Move on to next form" );
            }
            elsif ( $mode =~ /Skip_and_Finish/i ) {
                $output .= Show_Tool_Tip( $q->submit( -name => $button_name, -force => 1, -value => "Skip_and_Finish", -label => 'Skip and Finish', -class => 'Action' ), "Skip this form and Finish" );
            }

            unless ( $button_value =~ /^Skip/ ) {
                $output .= Show_Tool_Tip( $q->submit( -name => $button_name, -force => 1, -value => $button_value, -class => 'Action', -onClick => "return validateForm(this.form,$repeats)" ), $msg );
            }
        }

        $output .= &vspace(5);

        if ( $repeats && keys %{ $self->{configs}{autofill} } ) {

            ## Need to go through and fix places where elements use '.' in names and ids
            ## '.' is javascript class selector - shouldn't be used in ids/names
            my $formatted_fields = Cast_List( -list => $self->{field_list}, -to => 'string' );
            $formatted_fields =~ s/\./\-/g;
            my $indices = Cast_List( -list => [ 1 .. $repeats + 1 ], -to => 'string' );

            ## autofill function below was changed, so this will need to be adjusted since it will not work in this format... #
            SDB::Errors::log_deprecated_usage('autofill');    ## log use of this call so that it can be tested and corrected - remove this line once call to autofill below has been fixed ##
            ## include Clear/Reset Form button - CGI reset doesn't work with dropdown plugin
            $output .= CGI::button( -name => 'Reset Form', -value => 'Reset Form', -onClick => "clearForm(this.form, '$formatted_fields', '$indices')",    -class => "Std" );
            $output .= CGI::button( -name => 'AutoFill',   -value => 'AutoFill',   -onClick => "autofillForm(this.form, '$formatted_fields', '$indices')", -class => "Std" );
        }
    }

    unless ( $self->{remove_table_list} ) {
        my $all_table_str = join( ',', @{ $self->{all_table_list} } );

        # list of all tables that could possibly be inserted (in correct order)
        $output .= $q->hidden( -name => 'Update_Table', -value => $all_table_str, -force => 1 );

        # list of all tables that are allowed to be inserted (not in correct order - need to depend on Update_Table
        $output .= $q->hidden( -name => 'Allowed_Tables', -value => $table, -force => 1 ) . "\n";
    }

    # if DBRepeat is set, propagate it to the next form
    if ( $q->param("DBRepeat") ) {
        my $repeat_value = $q->param("DBRepeat") || 1;
        $output .= $q->hidden( -name => 'DBRepeat', -value => $repeat_value );
    }

    if ( $self->{js_on_load} ) {
        $output .= "\n<script type='text/javascript' onload = \"$self->{js_on_load}\">\n</script>\n";
    }

    if ($end_form) {
        $output .= $q->end_form();
    }

    if ($return_html) {
        return $output;
    }
    else {
        return $Form;
    }
}

#######################################
#
# generate row for given field
#
#
###################
sub _build_row {
###################
    my $self           = shift;
    my %args           = &filter_input( \@_, -args => 'index' );
    my $index          = $args{ -index };
    my $target         = $args{-target};
    my $Form           = $args{-form};
    my $form_name      = $args{-form_name};
    my $object_class   = $args{-object_class};
    my $target_display = $args{-target_display};
    my $update         = $args{-update} || 0;                               # this switch indicates that the form is being updated
    my $action         = $args{-action} || $self->{db_action} || 'edit';    # this switch indicates that the form is being updated ('edit', or 'search', 'reference search')...
    my $navigator_on   = $args{-navigator_on};
    my $filter_by_dept = $args{-filter_by_dept};
    my $element_name   = $args{-element_name};                              # override name of element (defaults to field name)
    
    eval "require alDente::Tools";
                                                                            #    my $row_index          = $args{-row_index} || 'row';
    my $dbc            = $self->{dbc};
    my $user_id        = $dbc->get_local('user_id');

    my %data;
    %data = %{ $args{ -data } } if $args{ -data };

    my %Table_info;
    %Table_info = %{ $args{-info} } if $args{-info};
    my @highlights;
    @highlights = @{ $args{-highlight} } if $args{-highlight};
    my @object_class_list;
    @object_class_list = @{ $args{-object_class_list} } if $args{-object_class_list};
    my $SL_size    = 4;                      ## default size (length of Scrolling List)
    my $clear_form = $q->param('Clear Form');    ## allow link to clear form of defaults ##

    my $search_mode = 'popup';
    my $search_help;

    if ( $action eq 'search' ) {
        ## this should EXCLUDE the 'reference search' action type...
        $search_mode = 'scroll';
        $clear_form  = 1;                    ## do not set defaults if searching

        my $search_tip = "Search options:\n" . SDB::HTML::wildcard_search_tip();
        $search_help = SDB::HTML::help_icon($search_tip);
    }

    my $reset = $self->{reset};

    use vars qw(%data $form);

    ## Initialize variables ##
    #my $searchable_length_threshold     = 10;
    my $date_field_width     = 15;
    my $field_width          = 20;
    my $datetime_field_width = 25;
    my $large_field_width    = 80;
    my $search               = $action =~ /search/;    ## either 'search' or 'reference search' (reference search used to specify single option)
    my $int_field_width      = 5;
    my $min_list             = 10;                     ## if > min_list use scrolling_list - otherwise use radio or checkboxes
    my $forces               = 1;

    my $prompt = $Table_info{Prompt}[$index];
    my $field  = $Table_info{Field_Name}[$index];

    my $table       = $Table_info{DBTable_Name}[$index];
    my $table_alias = $Table_info{DBTable_Alias}[$index];
    my $field_id    = $Table_info{DBField_ID}[$index];
    my $type        = $Table_info{Field_Type}[$index];
    my $desc        = $Table_info{Field_Description}[$index];
    my $options     = $Table_info{Field_Options}[$index];
    my $default     = $Table_info{Field_Default}[$index] || '';
    my $format      = $Table_info{Field_Format}[$index] || '';
    my $editable    = $Table_info{Editable}[$index] || '';
    my $tracked     = $Table_info{Tracked}[$index] || '';
    my $null_ok     = $Table_info{NULL_ok}[$index];

    $format =~s/^NULL$//;
    
    if ( $editable eq 'admin' ) {
        if   ( $dbc->admin_access() ) { $editable = 'yes' }
        else                          { $editable = 'no' }
    }

    my $boldcolor = 'red';    ### highlight for mandatory fields...
    my $id_randappend;
    my $extralink;
    my $highlight = '';
    if ( $search || $action =~ /edit/i ) { $default = '' }    ## do not use field default value for search forms

    ### Adjust in case of Attribute fields - simulate type as required ###
    my $full_field_name;
    if ($table_alias) {
        $full_field_name = "$table_alias.$field";
    }
    else {
        $full_field_name = "$field";
    }

    # Settings for most form elements, override at specific form elements below if needed]
    
    if (!$element_name) {
        $element_name = $full_field_name;
        $element_name =~s/\./\-/g;
    }
    
    my $id         = "$table.$field";
    my $structname = "$table.$field";
    my $element_id = "$table-$field";

    ## show parent fields
    my $parents = $self->get_parent_field( -dbc => $dbc, -dbfield_id => $Table_info{DBField_ID}[$index] );
    foreach my $parent (@$parents) {

        # check if the parent field is included in the same form already
        my $included = grep {/^$element_id$/} @{ $self->{element_ids_included} };
        if ( !$included ) {    # add the parent field to the form
                               # build row for the parent field
            my %parent_Table_info = Table_retrieve(
                $dbc, 'DBField',
                [ 'DBField_ID', 'Field_Table AS DBTable_Name', 'Field_Name', 'Prompt', 'Field_Description', 'Field_Default', 'Field_Type', 'Field_Options', 'Field_Alias', 'Field_Format', 'Editable', 'Tracked' ],
                "WHERE DBField_ID = $parent"
            );
            my $parent_table_index = 0;

            # preset parent field value if editing
            if ( defined $self->{Preset}{$element_name} && length( $self->{Preset}{$element_name} ) > 0 ) {
                my $value        = $self->{Preset}{$element_name};
                my $parent_table = $parent_Table_info{DBTable_Name}[0];
                my $parent_field = $parent_Table_info{Field_Name}[0];
                my ($primary_field) = $dbc->get_field_info( -table => $parent_table, -type => 'Primary' );
                my ($parent_value) = $dbc->Table_find( "$table, $parent_table", "$parent_field", "WHERE $table.$field = $primary_field AND $table.$field = '$value'" );
                if ($parent_value) { $self->{'Preset'}{$parent_field} = $parent_value }
            }

            $self->_build_row(
                 $parent_table_index,
                -info           => \%parent_Table_info,
                -form           => $Form,
                -form_name      => $form_name,
                -target_display => $target_display,
                -update         => $update,
                -action         => $action,
                -filter_by_dept => $filter_by_dept,
                -navigator_on   => $navigator_on,
            );
        }
    }

    if ( grep /^$field$/, @highlights ) {
        $highlight = 'class=lightredbw';
        $boldcolor = 'black';
    }
    my $class_id;
    if ( $self->{Preset} && $self->{Preset}{FK_Object_Class__ID} ) {
        $class_id = $self->{Preset}{FK_Object_Class__ID}->[ $self->{curr_record} - 1 ];
    }
    my ( $refTable, $refField ) = $dbc->foreign_key_check( $field, $class_id );

    ## Set Default ##
    if ( defined $q->param($field) && ( !$reset ) ) { $default = $q->param($field); }    ## allow defined fields to be included as well (eg '0');

    # custom code for Object_Class
    if ($object_class) {
        if ( $field =~ /^Object_ID$/ ) {
            $prompt = $object_class;
            my $test = $q->param('FK_Primer__Name');
            $default ||= &SDB::HTML::get_Table_Param( -field => "FK_" . $object_class . "__Name", -dbc => $dbc );

            if ( $default && ( $default !~ /^(undef|null)$/i ) ) {
                ## grey out option if recovered ##
                $self->{Grey}{$field} = $default;
            }
            else {
                ## leave as list of options if not defined ##
                unless ( $self->{List}{$field} ) {
                    $self->{List}{$field} = [ get_FK_info( $dbc, "Object_ID", -class => $object_class, -list => 1 ) ];
                }
            }
        }
        elsif ( $field =~ /FK_Object_Class__ID$/ ) {
            $prompt = 'Class';
        }
    }

    my $required = $options =~ /Required/ || $self->{Require}{$field} || $self->{Require}{ $table . '.' . $field };
    my $mandatory = $options =~ /Mandatory/;

    if ( $action =~ /search/i ) { }
    elsif ( $required || $mandatory ) {
        ## Required = Mandatory conditional upon applicability if parent field defined ##
        $self->{prefix} .= set_validator( -name => $field, -format => $format, -mandatory => $mandatory, -required => $required, -alias => $prompt, -type => $type );

        $prompt = "<B><Font color=$boldcolor>$prompt</Font></B>";
    }
    elsif ($format) {
        $self->{prefix} .= set_validator( -name => $field, -format => $format, -alias => $prompt );
    }
    ## Autofill fields ##
    if ( defined $self->{configs}{autofill}{$field} || $self->{configs}{autofill}{ $table . '.' . $field } ) {
        $self->{prefix} .= "<autofill  name=\"$field\"> </autofill>";
    }

    ## Preset fields ##
    if ( defined $self->{Preset}{$element_name} && length( $self->{Preset}{$element_name} ) > 0 ) {
        my $value;
        my $Presets = $self->{Preset}{$element_name};
        if ( ref $Presets eq 'ARRAY' ) {
            ## if Presets is an array, get the current_record element of the array ##
            $value = $Presets->[ $self->{curr_record} - 1 ];
        }
        else {
            ## Presets is simple scalar (multiple records MUST be in array format - otherwise commas in text affect splitting ##
            $value = $Presets;
        }

        # check if the field is an FK
        if ( $field =~ /Object_ID/i ) {
            if ( $refTable or $refField ) {
                $object_class = $refTable;

                # if it is, translate to human readable form
                $value = &get_FK_info( -dbc => $dbc, -field => $field, -id => $value, -class => $class_id );
            }
        }
        else {
            if ( $refTable or $refField ) {

                # if it is, translate to human readable form
                $value = &get_FK_info( -dbc => $dbc, -field => $field, -id => $value );
            }
        }
        $default = $value;
    }

    ## Special Tag Defaults ##
    if ( $default =~ /<TODAY>/ ) {
        $default = convert_date( &today(), 'SQL' );
    }
    elsif ( $default =~ /<NOW>/ ) {
        $default = convert_date( &now(), 'SQL' );
    }
    elsif ( $default =~ /<USER>/ ) {
        $default = $dbc->get_local('user_id');
    }
    elsif ( $default =~ /<(.*)>/ ) {
        ## check for standard defaults ##
        $default = &get_FK_info( $dbc, $field, $Defaults{$1} ) if defined $Defaults{$1};
    }

    ### Hidden fields
    if ( !$search && ( $options =~ /Hidden/i ) ) {
        $self->{prefix} .= $q->hidden( -name => $field, -value => $default, -force => 1, -structname => $structname ) . "\n";
        return;
    }

    ## Omitted fields ##
    if ( defined $self->{Omit}{$field} ) {
        $default = $self->{Omit}{$field};
        $self->{prefix} .= $q->hidden( -name => $field, -value => $default, -force => 1, -structname => $structname ) . "\n";
        return;
    }

    ## set filter triggers if it has dependency
    my ( $trigger, $command, $on_load );
    my $child = $self->get_child_field( -dbc => $dbc, -dbfield_id => $Table_info{DBField_ID}[$index] );
    if ( int(@$child) ) {
        ( $trigger, $command, $on_load ) = $self->get_dependent_trigger( -table => $table, -field => $field );

        #print HTML_Dump "trigger=$trigger";
        #print HTML_Dump "command=$command";
        #print HTML_Dump "on_load=$on_load";
        if ( !$trigger ) { $trigger = 'OnClick' }
        if ( !$command ) { $command = '' }
    }

    my $tip;

    if ( $action =~ /search/ ) { $tip = $desc if $desc }
    elsif ( $tracked =~ /yes/i ) { $tip = "Check History of changes for this field" }
    $tip ||= "Check settings for this field";

    if ( $self->{external} ) {
        $prompt = Show_Tool_Tip( $prompt, $desc );
    }
    else {
        $prompt = &Link_To( $dbc->{homelink}, $prompt, "&Change+History=1&field_id=$field_id&field_name=$field&primary=$self->{$self->{curr_table}}{primary_value}", $Settings{LINK_BLACK}, ['newwin'], -tooltip => $tip );
    }

    ## Greyed out fields ##
    if ( defined $self->{Grey}{$field} || $options =~ /Hidden/i ) {
        $default = $self->{Grey}{$field};
        $self->{prefix} .= $q->hidden( -name => $field, -value => $default, -force => 1, -structname => $structname ) . "\n";

        # check if the field is an FK
        my $value;
        if   ( ref $default eq 'ARRAY' && !$self->{repeat} ) { $value = $default->[0] }
        else                                                 { $value = $default }

        if ( $refTable or $refField ) {
            if ( $value eq '<' . $refTable . '.' . $refField . '>' ) {
                $value = 'TBD';
            }
            else {

                # if it is, translate to human readable form
                $value = &get_FK_info( $dbc, $field, $value );
            }
        }

        $self->add_Section( $Form, $prompt, $value, -element_id => "$element_id". '-row' );
        return;
    }

    ## Skipped fields ##
    if ( defined $self->{Skip}{$field} ) {
        return;
    }

    my $extra_field = '';
    if ( defined $self->{Extras}{$field} ) {
        $extra_field = $self->{Extras}{$field};
    }
 
    ######## Automatic grey out field if it FK to a primary field of previous table in a multipage form
    ### <CONSTRUCTION> This is not needed in the new DB_Forms with FormNav
    if ( $refTable && $refField ) {
        if ( exists $data{tables}->{$refTable} ) {
            my $value;
            if ( $field =~ /\w+_ID$/ ) {
                $self->{prefix} .= $q->hidden( -name => $field, -value => "<$refTable.$refField>", -force => 1, -structname => $structname ) . "\n";
                $value = "(tbd)";
            }
            else {
                my $preset_already = $q->param($refField);
                $value = defined $preset_already ? $preset_already : $data{tables}->{$refTable}->{1}->{$refField};
                $self->{prefix} .= $q->hidden( -name => $field, -value => $value, -force => 1, -structname => $structname ) . "\n";
            }

            #	    $Form->Set_Row([$prompt, $value]);
            $self->add_Section( $Form, $prompt, $value, -element_id => $element_id . '-row' );
            return;
        }
    }
    $extralink = '';    ## optional element that may appear to the right of the current element (eg links to Add new records, help etc)
    if ($extra_field) { $extralink = $extra_field }

    if ( $options =~ /NewLink/ && !$self->{external} ) {
        ## provide access to create new object for lookup table ##
        my $sub_table = $refTable;

        my $pass_table_perm;
        if ( $target_display =~ /Database/i ) {
            $pass_table_perm = !$self->{dbc} || $self->{dbc}->check_permissions( $user_id, $sub_table, $action, -groups => $self->{configs}{groups} );
        }
        elsif ( $target_display =~ /Submission/i ) {
            $pass_table_perm = 1;
        }

        if ( $sub_table && $self->{add_form} && $pass_table_perm && !$navigator_on ) {
            if (1) {
                if ( $target_display =~ /Database/i ) {
                    ### the bare word '.Choice' has to match whatever it is in alDente::Tools::search_list();
                    my $homelink = $dbc->homelink();
                    $extralink .= qq(<a href="javascript:formAddNew('$sub_table','$table.$field', '$homelink&DBTable=$table&DBAppend=$sub_table&Target=$target_display')">(add new)</a>);
                }
                elsif ( $target_display eq 'Submission' ) {
                    ### Not supported yet...
                }
            }
            else {
                ### Obsolete.....
                # generate a DB_Form table (hidden), with an addlink opener
                my $subform = SDB::DB_Form->new(
                    -dbc               => $self->{dbc},
                    -form_name         => $form_name,
                    -table             => $sub_table,
                    -target            => $target,
                    -parameters        => $self->{parameters},
                    -quiet             => 1,
                    -wrap              => 0,
                    -start_form        => 0,
                    -end_form          => 0,
                    -submit            => 0,
                    -remove_table_args => 1
                );
                $subform->configure( %{ $self->{configs} } );
                my $subform_table = $subform->generate( -line_colour => 'lightgrey', -return_html => 1 );

                # hide using tree and add/remove from Allowed_Tables list as necessary (add when clicked, remove when clicked again)
                # also, add that field to the skip list (it doesn't need to be filled in - it will be autofilled)
                my $subform_tree = create_tree(
                     { "Add" => $subform_table },
                    -disable_if_collapsed => 1,
                    -block_name           => $sub_table,
                    -onClick              => "
                    if (document.$form_name.$field.disabled) {
                    ToggleNamedElements($form_name,'$field',1);
                    document.$form_name.Allowed_Tables.value=document.$form_name.Allowed_Tables.value.replace(/,?$sub_table(\$|,)/g,',').replace(/,,/,',');
                    document.$form_name.Skip.value=document.$form_name.Skip.value.replace(/,?$field(\$|,)/g,',').replace(/,,/,',');
                    }
                    else {
                    ToggleNamedElements($form_name,'$field',2);
                    document.$form_name.Allowed_Tables.value=document.$form_name.Allowed_Tables.value + ',$sub_table';
                    document.$form_name.Skip.value=document.$form_name.Skip.value + ',$field';
                    }
                    "
                );
                $extralink .= $subform_tree;

                # add to all_table_list - note that it is added BEFORE the main table
                # this is because of the main table's dependency on the 'add' table
                #if (!grep /\b$sub_table\b/, @all_table_list) {unshift (@all_table_list,$sub_table)};
                unshift( @{ $self->{all_table_list} }, $sub_table );

                #$extralink .= &Link_To($homelink,"Add","&DBTable=$table&DBAppend=$sub_table&Target=$target",$Settings{LINK_COLOUR},['newwin']) . ' ';
            }
        }
        else {
            ## allow specification for new item in text field
            #$newtext = 1;
        }
    }

    if ( $options =~ /ViewLink/ ) { $extralink .= &Link_To( $dbc->homelink(), "View", "&DBTable=$table&DBView=$field&Target=$target", $Settings{LINK_COLOUR}, ['newwin'] ) . ' '; }
    if ( $options =~ /ListLink/ ) { $extralink .= &Link_To( $dbc->homelink(), "List", "&DBTable=$table&DBList=$field&Target=$target", $Settings{LINK_COLOUR}, ['newwin'] ) . ' '; }

    if ( !$self->{external} ) {
        ## Change history section
        if ($update) {
            ## If user is a Site_admin make all fields editable
            if ( $Security && !$Security->Site_admin() ) {
                if ( $editable =~ /no/i ) {
                    if ( !$default ) {
                        my $form_elem = &Show_Tool_Tip( $q->textfield( -name => $element_name, -size => $field_width, -default => $default, -force => 1, -structname => $structname ), $desc );

                        #			$Form->Set_Row([$prompt,$form_elem],undef,$highlight);
                        $self->add_Section( $Form, $prompt, $form_elem, -highlight => $highlight, -element_id => $element_id . '-row');

                        $self->{input_fields}++;
                    }
                    else {

                        #			    $Form->Set_Row([$prompt,$default],undef,$highlight);
                        $self->add_Section( $Form, $prompt, $default, -highlight => $highlight, -element_id => $element_id . '-row');
                        $self->{prefix} .= $q->hidden( -name => $field, -value => $default, -force => 1, -structname => $structname ) . "\n";
                    }
                    return;
                }
            }
        }
    }    # end of check for editable fields

    # set up search on fields automatically (specify list of fields ?)
   
    if ( $field =~ /\b$table[_]ID/ ) {
        ## do not allow entry of auto_incremented ID field ###
        if ( $action =~ /search/i ) {
            ### unless search mode
            my $form_elem = &Show_Tool_Tip( $q->textfield( -name => $element_name, -size => $int_field_width, -default => $default, -force => 1, -structname => $structname ), "$desc" ) . $search_help;

            #	$Form->Set_Row([$prompt,$form_elem,$extralink],undef,$highlight);
            $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
        }
        else {
            $self->{prefix} .= $q->hidden( -name => $field, -value => $default, -force => 1 ) . "\n";
        }

    }
    elsif ( $self->{Condition}{$field} or $self->{Condition}{"$table.$field"} ) {
        my $ConditionRef   = $self->{Condition}{$field} or $self->{Condition}{"$table.$field"};
        my $condition      = $ConditionRef->{condition};
        my $join_tables    = $ConditionRef->{join_tables};
        my $join_condition = $ConditionRef->{join_condition};

        if ( $options =~ /Searchable/i || $search ) {
            my %tip;
            $tip{List} = $desc;
            my $new = 0;
            if ( ( !$self->{external} ) && ( $field =~ /\bStock_Catalog_Name\b/ ) && ( $Security && $Security->department_access() =~ /Admin/i ) ) {
                $new = 1;    ## this is not possible for FK dropdowns anyways.. (?)
            }
            if ( $action =~ /search/i ) {

                $self->add_Section(
                    $Form, $prompt,
                    alDente::Tools::search_list(
                        -dbc            => $dbc,
                        -name           => $field,
                        -element_id     => $element_id,
                        -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                        -default        => '',
                        -search         => 1,
                        -filter         => 1,
                        -filter_by_dept => $filter_by_dept,
                        -breaks         => 1,
                        -condition      => $condition,
                        -join_tables    => $join_tables,
                        -join_condition => $join_condition,
                        -tip            => \%tip,
                        -new            => $new,
                        -new_ok         => $new,
                        -structname     => $structname,
                        -id             => $id,
                        -mode           => $search_mode,
                        -action         => $action,
                    ),
                    $extralink,
                    -highlight  => $highlight,
                    -element_id => $element_id . '-row'
                );

            }

            else {

                ## <CONSTRUCTION> Hardcoded removal of temporary rack as option
                $default =~ s/Rac1: Temporary Rack//;
                my $search_list = alDente::Tools::search_list(
                    -dbc            => $dbc,
                    -name           => $field,
                    -element_id     => $element_id,
                    -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                    -default        => $default,
                    -search         => 1,
                    -filter         => 1,
                    -filter_by_dept => $filter_by_dept,
                    -breaks         => 1,
                    -condition      => $condition,
                    -join_tables    => $join_tables,
                    -join_condition => $join_condition,
                    -tip            => \%tip,
                    -new            => $new,
                    -new_ok         => $new,
                    -structname     => $structname,
                    -id             => $id,
                    -mode           => $search_mode,
                    -action         => $action,
                );

                $self->add_Section( $Form, $prompt, $search_list, $extralink, -highlight => $highlight, -element_id => $element_id . '-row' );
            }
        }
        $self->{input_fields}++;

    }

    elsif ( $self->{List}{$field} || $self->{List}{"$table.$field"} ) {
        ## Populate dropdown menu lists ##
        my @List = ();
        if ( $self->{List} ) {
            my $ListRef = $self->{List}{$field} || $self->{List}{"$table.$field"};
            @List = @{$ListRef};
        }

        if ( @List == 1 ) { $default = $List[0] }    ## preset if only one option...

        #<CONSTRUCTION> remove the forced search by making specific fields Searchable (add special case for stock name)
        if ( $options =~ /Searchable/i || $search ) {
            my %tip;
            $tip{List} = $desc;
            my $new = 0;
            if ( ( !$self->{external} ) && ( $field =~ /\bStock_Catalog_Name\b/ ) && ( $Security && $Security->department_access() =~ /Admin/i ) ) {
                $new = 1;                            ## this is not possible for FK dropdowns anyways.. (?)
            }
            if ( $action =~ /search/i ) {
                $self->add_Section(
                    $Form,
                    $prompt,
                    ## cleared defaults in search mode ##
                    alDente::Tools::search_list(
                        -dbc            => $dbc,
                        -name           => $field,
                        -element_id     => $element_id,
                        -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                        -default        => '',
                        -search         => 1,
                        -filter         => 1,
                        -filter_by_dept => $filter_by_dept,
                        -breaks         => 1,
                        -options        => \@List,
                        -tip            => \%tip,
                        -new            => $new,
                        -new_ok         => $new,
                        -structname     => $structname,
                        -id             => $id,
                        -mode           => $search_mode,
                        -action         => $action,
                    ),
                    $extralink,
                    -highlight  => $highlight,
                    -element_id => $element_id . '-row'
                );
            }
            else {

                #$Form->Set_Row([
                $self->add_Section(
                    $Form, $prompt,
                    alDente::Tools::search_list(
                        -dbc            => $dbc,
                        -name           => $field,
                        -element_id     => $element_id,
                        -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                        -default        => $default,
                        -search         => 1,
                        -filter         => 1,
                        -filter_by_dept => $filter_by_dept,
                        -breaks         => 1,
                        -options        => \@List,
                        -tip            => \%tip,
                        -new            => $new,
                        -new_ok         => $new,
                        -structname     => $structname,
                        -id             => $id,
                        -mode           => $search_mode,
                        -action         => $action,
                    ),
                    $extralink,

                    #],
                    -highlight  => $highlight,
                    -element_id => $element_id . '-row'
                );
            }

            $self->{input_fields}++;

        }
        else {
            my $form_elem = &Show_Tool_Tip( $q->popup_menu( -name => $element_name, -id => $id, -values => [ '', @List ], -default => $default, -force => 1, -width => 200, -structname => $structname ), $desc );

            #	    $Form->Set_Row([$prompt,$form_elem,$extralink],undef,$highlight);
            $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
            $self->{input_fields}++;
        }
    }
    elsif ( $object_class && $field =~ /^Object_ID$/ ) {
        ## special handling of dynamic foreign keys - foreign table reference ##
        my %tip;
        $tip{List} = $desc;

        #	$Form->Set_Row([
        $self->add_Section(
            $Form,
            $object_class,
            &alDente::Tools::search_list(
                -dbc            => $dbc,
                -name           => $field,
                -element_name   => $element_name,         ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -default        => $default,
                -search         => 1,
                -filter         => 1,
                -filter_by_dept => $filter_by_dept,
                -breaks         => 1,
                -options        => \@object_class_list,
                -structname     => $structname,
                -tip            => \%tip,
                -id             => $id,
                -mode           => $search_mode,
                -action         => $action,
            ),
            $extralink,

            #],
            -highlight  => $highlight,
            -element_id => $element_id . '-row'
        );
    }
    elsif ( $object_class && $field =~ /^FK_Object_Class__ID$/ ) {
        ## special handling of dynamic foreign keys - class indicator field ##
        #	$Form->Set_Row([$prompt,$object_class]);
        $self->add_Section( $Form, $prompt, $object_class, -element_id => $element_id . '-row');

        $self->{prefix} .= $q->hidden( -name => $field, -value => $object_class, -force => 1 ) . "\n";
    }
    elsif ( $refTable && $refField ) {
        ## Foreign keys ##
        my $FKnote;
        
        if ( $dbc->barcode_prefix($refTable) ) {
            $FKnote = "<B>Scan</B>";
        }

        #elsif ($field =~/id/i) {$FKnote = "<B>Foreign key values only!</B>";}

        if ( $default && $default =~ /^\d+$/ ) {
            $default = $dbc->get_FK_info( $field, $default );    ### expand default to verbose value
        }

        if ( $q->param($refField) && ( $field !~ /Parent/i ) && !$default ) { $default = $q->param($refField) }

        ####Add extra fk value to the list.  This is the case if the desired fk value is not in the DB yet. (e.g. from a storable)
        if ( defined $self->{fk_extra}{$field} ) {
            $self->{prefix} .= $q->hidden( -name => 'fk_extra', -value => "$field:" . $self->{fk_extra}{$field}, -force => 1 ) . "\n";
        }

        #       if ($options =~/\bSearchable\b/i)  # Allow searching with popupmenu
        my %tip;
        $tip{List} = $desc;

        if ( $action =~ /search/i ) {
            my $searchlist = alDente::Tools::search_list(
                -dbc            => $dbc,
                -field          => $field,
                -element_name   => $element_name,                    ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -table          => $table,
                -default        => $self->{Preset}{$element_name},
                -search         => 1,
                -filter         => 1,
                -filter_by_dept => $filter_by_dept,
                -breaks         => 1,
                -mask           => $self->{Mask}{$field},
                -fk_extra       => $self->{fk_extra}{$field},
                -tip            => \%tip,
                -id             => $id,
                -mode           => $search_mode,
                -smart_sort     => 1,
                -action         => $action,
                "-onClick"      => $command
            );
 
            if ($on_load) {
                ## run all of these trigger commands automatically when the form first loads.... ##
                $self->{js_on_load} .= $on_load;
                $searchlist         .= "<script language='javascript'>$on_load</script>\n";
            }
            $self->add_Section(
                $Form, $prompt,
                $searchlist
                    . $extralink,
                -element_id => $element_id . '-row'

            );
        }
        else {

            ## Add context if editing an existing record ##

            my $searchlist = alDente::Tools::search_list(
                -dbc            => $dbc,
                -field          => $field,
                -element_name   => $element_name,                                   ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -table          => $table,
                -default        => $default,
                -search         => 1,
                -filter         => 1,
                -filter_by_dept => $filter_by_dept,
                -breaks         => 1,
                -mask           => $self->{Mask}{$field},
                -fk_extra       => $self->{fk_extra}{$field},
                -tip            => \%tip,
                -id             => $id,
                -mode           => $search_mode,
                -record         => $self->{ $self->{curr_table} }{primary_value},
                -action         => $action,
                "-onClick"      => $command
            );
            if ( ( $table eq 'Work_Request' ) && ( $field eq 'FK_Goal__ID' ) ) {
                $searchlist =~ s/<option value="Bi-directional 96-well plates to sequence">Bi-directional 96-well plates to sequence<\/option>//;
            }
            if ($on_load) {
                ## run all of these trigger commands automatically when the form first loads.... ##
                $self->{js_on_load} .= $on_load;
                $searchlist         .= "<script language='javascript'>$on_load</script>\n";
            }

### Check to see if random number appears in objectid. Pass that number through to the javascript, to be appended to the Element ID. This is to avoid a TypeError: target has no properties that occurs when the random part of object id is not accounted for
### There may be other cases when the TypeError appears

            $searchlist =~ /$table\.$field(\d+)\.SearchList/;
            $id_randappend = $1;

            $extralink =~ s/Target=$target_display\'\)/Target=Database\'\,\'$id_randappend\'\)/;

            $self->add_Section(
                $Form,
                $prompt,

                $searchlist . $extralink, -element_id => $element_id . '-row'
            );

        }

        $self->{input_fields}++;
        $forces++;

    }
    elsif ( $type =~ /^set/ ) {
        $self->{input_fields}++;
        my @defaultset = ();
        if ($default) {    ### set possible defaults...
            if ( $default =~ /,/ ) {
                @defaultset = split ',', $default;
            }
            elsif ( ref $self->{Preset}{$element_name} eq 'ARRAY' ) {
                @defaultset = @{ $self->{Preset}{$element_name} };
            }
            else {
                push( @defaultset, $default );
            }
        }
        my @set_list = get_enum_list( $dbc, $table, $field, $self->{Mask}{$field} );

#        unless ( grep /^\s*$/, @set_list ) { @set_list = ( '', @set_list ); }

        my $form_elem = alDente::Tools::search_list(
            -dbc            => $dbc,
            -name           => $field,
            -element_name   => $element_name,       ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
            -options        => [ @set_list ],
#            -default        => \@defaultset,
            -breaks         => 1,
            -filter_by_dept => $filter_by_dept,
            -tip            => $desc,
            -id             => $id,
            -structname     => $structname,

            #-mode=>'checkbox', leaving this out, since it breaks the navigator
            -mode       => 'set',
            -smart_sort => 1,
            -action     => $action,
        );

        #	$Form->Set_Row(["$prompt",$form_elem,$extralink],undef,$highlight);
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
    }
    elsif ( ( $action =~ /search/i ) && ( $type =~ /^enum/i ) ) {
        my @defaultset = ();

        if ( $default && !$clear_form ) {    ### set possible defaults...
            if ( $default =~ /,/ ) {
                @defaultset = split ',', $default;
            }
            elsif ( ref $self->{Preset}{$element_name} eq 'ARRAY' ) {
                @defaultset = @{ $self->{Preset}{$element_name} };
            }
            else {
                push( @defaultset, $default );
            }
        }
        elsif ( ref $self->{Preset}{$element_name} eq 'ARRAY' ) {
            ## allow presets if explicit
            @defaultset = @{ $self->{Preset}{$element_name} };
        }
        my @enum_list = get_enum_list( $dbc, $table, $field, $self->{Mask}{$field} );
        $self->{input_fields}++;
 #       unshift( @enum_list, '' );  No need to add blank option if in search mode (multiselect works okay without blank default option)

        my $form_elem;
        if ( @enum_list > $min_list ) {
            $form_elem = &Show_Tool_Tip(
                $q->scrolling_list(
                    -name       => $element_name,
                    -values     => [@enum_list],
                    -defaults   => [@defaultset],
                    -force      => 1,
                    -multiple   => 2,
                    -structname => $structname,
                    -size       => $SL_size
                ),
                $desc
            );
        }
        else {
            $form_elem = alDente::Tools::search_list(
                -dbc            => $dbc,
                -name           => $field,
                -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -options        => \@enum_list,
                -default        => \@defaultset,
                -breaks         => 1,
                -filter_by_dept => $filter_by_dept,
                -tip            => $desc,
                -id             => $id,
                -structname     => $structname,
                -mode           => 'checkbox',
                -action         => $action,
            );
        }

        #	$Form->Set_Row(["$prompt",$form_elem,$extralink],undef,$highlight);
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
    }
    elsif ( $type =~ /^enum/i ) {
        my @enum_list = get_enum_list( $dbc, $table, $field, $self->{Mask}{$field} );
        $self->{input_fields}++;
        unshift( @enum_list, '' );

        my $form_elem;
        if (1) {    ##   (@enum_list > $min_list) {   ### breaks navigator - leave for now..
            my ( $trigger, $command, $on_load ) = $self->get_js_trigger( -table => $table, -field => $field );
 
            $form_elem = &Show_Tool_Tip( $q->popup_menu( -name => $element_name, -id => $id, -values => \@enum_list, -default => $default, -force => 1, -width => 200, -structname => $structname, "-$trigger" => $command ), $desc );

            if ($on_load) {
                ## run all of these trigger commands automatically when the form first loads.... ##
                $self->{js_on_load} .= $on_load;
                $form_elem          .= "<script language='javascript'>$on_load</script>\n";
            }
        }
        else {
            $form_elem = alDente::Tools::search_list(
                -dbc            => $dbc,
                -name           => $field,
                -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -options        => \@enum_list,
                -default        => $default,
                -breaks         => 1,
                -filter_by_dept => $filter_by_dept,
                -tip            => $desc,
                -id             => $id,
                -structname     => $structname,
                -mode           => 'radio',
                -action         => $action,
            );

        }

        #        $Form->Set_Row(["$prompt",$form_elem,$extralink],undef,$highlight);
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
    }
    elsif ( ( $action =~ /search/i ) && ( $type =~ /(time|date)/i ) ) {
        ### allow search range for date fields if in search mode ###
        ### parse possible default and default_to
        my $default_from = '';    ## date_time('-1mo');  ## do NOT default to 1 month...
        my $default_to;
        if ( $default =~ /(.*)<=>(.*)/ ) {
            $default_from = $1;
            $default_to   = $2;
        }

        my $form_elem = &Show_Tool_Tip(
            &display_date_field(
                -field_name   => $field,
                -element_name => $element_name,
                -type         => $type,

                # -element_name => $element_name, ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                -quick_link => [ 'today', '1 day', '1 month', '1 year', 'any' ],
                -range      => 1,
                -linefeed   => 2,
                -form_name  => $form_name,
                -default    => substr( $default_from, 0, 10 ),
                -default_to => substr( $default_to,   0, 10 )
            ),

            $desc
        );

        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
        $self->{input_fields}++;
        ########### Custom Insertion to specify types of input for various fields... ##############
    }
    elsif ( $type =~ /^date/i ) {
        my $form_elem = &Show_Tool_Tip(
            &display_date_field(
                -field_name   => $field,
                -element_name => $element_name,
                -type         => $type,
                -form_name    => $form_name,
                -default      => $default,
                -element_id   => $element_id,
            ),

            $desc
        );
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row' );

        $self->{input_fields}++;

    }
    elsif ( $type =~ /time/i ) {
        my $form_elem = &Show_Tool_Tip( $q->textfield( -name => $element_name, -size => $date_field_width, -default => $default, -force => 1, -structname => $structname ) . ' (HH:MM or Min.Sec)', $desc );
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');
        $self->{input_fields}++;

    }
    elsif ( $field =~ /(_?(Instructions|Description|Run|Comments|Sequence|Note[s]|Text)$)|(^RNA_DNA_Extraction$)/ ) {
        my $form_elem = &Show_Tool_Tip( $q->textarea( -name => $element_name, -rows => 5, -cols => $large_field_width, -default => $default, -force => 1, -wrap => 'virtual', -structname => $structname ), $desc );

        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');

        #	$Form->Set_Row([$prompt,$form_elem,$extralink],undef,$highlight);
        $self->{input_fields}++;

    }
    elsif ( $type =~ /^int/ ) {
        my $form_elem = &Show_Tool_Tip( $q->textfield( -name => $element_name, -size => $int_field_width, -default => $default, -force => 1, -structname => $structname ), "$desc" ) . $search_help;
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row');

        #	$Form->Set_Row([$prompt,$form_elem,$extralink],undef,$highlight);
        $self->{input_fields}++;
        ########### End Custom Insertion #############################
    }
    elsif ( ( !$self->{external} ) && $options =~ /\bSearchable\b/i && ( $Security && $Security->Site_admin() ) ) {

        # Allow searching with popupmenu
        my $name = "$table.$field";
        ## Search list requires fully qualified field
        my %tip;
        $tip{List} = $desc;
        if ( $action =~ /search/i ) {

            $self->add_Section(
                $Form, $prompt,
                &alDente::Tools::search_list(
                    -dbc            => $dbc,
                    -name           => $name,
                    -element_id   => $element_id,  
                    -element_name   => $element_name,                    ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                    -default        => $self->{Preset}{$element_name},
                    -search         => 1,
                    -filter         => 1,
                    -filter_by_dept => $filter_by_dept,
                    -new            => 1,
                    -breaks         => 1,
                    -tip            => \%tip,
                    -id             => $id,
                    -structname     => $structname,
                    -mode           => $search_mode,
                    -action         => $action,
                )
            );
        }
        else {
            $self->add_Section(
                $Form, $prompt,
                &alDente::Tools::search_list(
                    -dbc            => $dbc,
                    -name           => $name,
                    -element_id   => $element_id,  
                    -element_name   => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
                    -default        => $default,
                    -search         => 1,
                    -filter         => 1,
                    -filter_by_dept => $filter_by_dept,
                    -new            => 1,
                    -breaks         => 1,
                    -tip            => \%tip,
                    -id             => $id,
                    -structname     => $structname,
                    -mode           => $search_mode,
                    -action         => $action,
                ),
                -element_id => $element_id . '-row'
            );
        }
        $self->{input_fields}++;
    }
    else {
        my $onChange;
        if ( $options =~ /Unique/ ) {
            $onChange = "formUniqueCheck('$table','$field',this,'$Table_info{Prompt}[$index]')";
        }

        my $form_elem = &Show_Tool_Tip(
            $q->textfield(
                -name       => $element_name,
                -size       => $field_width,
                -default    => $default,
                -onChange   => $onChange,
                -force      => 1,
                -id         => $id,
                -structname => $structname,
            ),
            "$desc"
        ) . $search_help;

        #	$Form->Set_Row([$prompt,$form_elem,"$extralink"],undef,$highlight);
        $self->add_Section( $Form, $prompt, $form_elem, $extralink, -highlight => $highlight, -element_id => $element_id . '-row' );

        #	    $Form->Set_Link('text',$field,$field_width,$default,undef,$desc);
        $self->{input_fields}++;
    }
    return $element_id;
}

###########################
sub get_js_trigger {
###########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $table = $args{-table};
    my $field = $args{-field};

    my $dbc        = $self->{dbc};
    my $trigger_on = 'onClick';
    my ( $js, $js_load );

    ## first check visibility based upon parent fields ##
    my %Dep = $dbc->Table_retrieve(
        'DBField, DBField as Parent',
        [ "Concat(DBField.Field_Table,'.',DBField.Field_Name,'.row') as Dependency", 'DBField.Parent_Value as Show_if' ],
        "WHERE DBField.FKParent_DBField__ID=Parent.DBField_ID AND Parent.Field_Table = '$table' AND Parent.Field_Name = '$field' AND Length(DBField.Parent_Value) > 0"
    );
    my ( @fields, @options );
    my $i = 0;
    while ( defined $Dep{Dependency}[ $i++ ] ) {
        my $my_field = $Dep{Dependency}[ $i - 1 ];
        my $show_if  = $Dep{Show_if}[ $i - 1 ];
        push @fields, $my_field;
        if ( !grep /^$show_if$/, @options ) { push @options, $show_if }
        if ( $show_if ne $self->{configs}{preset}{$field} ) {
            push @{ $self->{init_hidden} }, $my_field;
        }
    }

    if (@fields) {
        my $dependencies = join ',', @fields;
        my $show_if      = join ',', @options;

        $js .= "controlVisibility('$dependencies','$table.$field','$show_if'); ";

        ## run trigger when form loads as well ##
        my $on_load = $js;
        $on_load =~ s/,this,/,\'$table\.$field\',/;

        $js_load .= $on_load;
    }

    ## also check for fields dependent upon this field ##
    %Dep = $dbc->Table_retrieve( 'DBField', [ "CONCAT(DBField.Field_Table,'.',DBField.Field_Name) as Filtered", 'DBField.List_Condition' ], "WHERE DBField.List_Condition like '<$table.$field>%'", );

    ## look for List_Condition LIKE '<$table.$field>%' indicating dynamic dependency... ##

    $i = 0;
    while ( defined $Dep{Filtered}[ $i++ ] ) {
        my $filtered       = $Dep{Filtered}[ $i - 1 ];
        my $list_condition = $Dep{List_Condition}[ $i - 1 ];

        if ( $list_condition =~ /^<([\w\.]+)>\s?=\s?([\w\.]+)(.*)/ ) {
            ## eg dependency format is: <Dynamically_Monitored_Field> = Lookup.Field (eg '<Original_Source.Original_Source_Type> = Anatomic_Site_Type )
            my $ref_lookup      = MIME::Base32::encode($2);
            my $extra_condition = $3;
            if ($extra_condition) {
                ## encode extra condition if applicable ##
                $extra_condition =~ s/^\s?AND //;    # clear AND condition
                $extra_condition ||= 1;
                $extra_condition = MIME::Base32::encode($extra_condition);
            }
            my $filter_url = "/$URL_dir_name/cgi-bin/ajax/query.pl" . "?Database_Mode=$dbc->{mode}&Field=$filtered&Reference_Field=$ref_lookup&Condition=$extra_condition";
            my $on_change  = "dependentFilter('$table.$field','$filter_url','$filtered', 0); ";

            ## run trigger when form loads as well ##
            my $on_load = $on_change;
            $on_load =~ s/,this,/,\'$table\.$field\',/;
            $js      .= $on_change;
            $js_load .= $on_load;
        }
        else {
            Message("Unrecognized List condition for dependent field");
        }
    }

    if ( !$js ) {return}

    return ( $trigger_on, $js, $js_load );
}

##
#
# This just centralizes the code that adds the actual element to the current form
#
# (it is particularly useful to take repeat options into account... also potentially cloned rows)
#
##################
sub add_Section {
##################
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'Table,header,element,extra,highlight', -mandatory => 'Table,element' );
    my $Form       = $args{-Table};
    my $header     = $args{-header};
    my $element    = $args{-element};
    my $extra      = $args{-extra};
    my $highlight  = $args{-highlight};
    my $element_id = $args{-element_id};
    my $spec       = $args{-spec};
    my $indexed    = $args{ -index };                                                                                        ## index multiple elements with .$i suffix

    if ( grep /^$element_id$/, @{ $self->{init_hidden} } ) {
        $spec = "style=display:none";
    }

    my $default = "''";

    my $repeat = $self->{repeat};

    if ($repeat) { $indexed = 1 }

    my $secondary_element = $element;

    my $id = 0;
    if ($repeat) {
        if ( $element =~ /selected=\"selected\" value=\"\"><\/option>/ ) {
            ## default popup menu
            $secondary_element =~ s/selected=\"selected\" value=\"\"><\/option>/value=\"\"><\/option>\n<option selected=\"selected\" value=\"$default\">$default<\/option>/;
        }
        elsif ( $element =~ /<option value=\"\">(.*)<\/option>/ ) {

            ## for popup menu too, a little more non specific
            $secondary_element =~ s/<option value=\"\">$1<\/option>/<option selected=\"selected\" value=\"$default\">$default<\/option>/;
        }
        elsif ( $element =~ /<input type=\"text\"/ ) {
            ## default text field
            $secondary_element =~ s /(<input type=\"text\")/$1 value=\"$default\" force=\"1\"/;
        }

        if ( $repeat && $indexed ) {
            if ( $secondary_element =~ / id=[\"\'](\S+?)[\"\']/ ) {
                my $prefix = $1;
                $secondary_element = _replace_indexed_element_id( -prefix => $prefix, -element => $secondary_element );
                $id = 1;
            }
        }
        elsif ( $element =~ / id=[\"\']([\w\.]*?)(\d+)[\"\']/ ) {
            ## replace ID if required ##
            my $prefix = $1;
            $id = $2;
            my $id_length = length($id);
            if ( $id_length > 7 ) {
                ## prefer to do this whenever the prefix is separated by . rather than length requirement...
                ## only do this if the id suffix is a reasonably length integer - ensuring it is unique ##
                $secondary_element =~ s /$id/<REPLACEID>/g;
            }
        }
    }

    my @cells;
    if ($repeat) {
        my @elements;
        if ( $secondary_element =~ /ARRAY/ ) {

            my @temp_array = @$secondary_element;
            for my $temp_index ( 0 .. $repeat ) {
                my $new_secondary_element = $temp_array[$temp_index];
                if ( $id || $indexed ) {
                    ## create unique id for subsequent elements ##
                    my $nextid = $id + $temp_index;
                    $new_secondary_element =~ s /<REPLACEID>/$nextid/g;
                }
                push @elements, $new_secondary_element;
            }
        }
        else {
            foreach my $index ( 0 .. $repeat ) {
                if ($indexed) {
                    my $new_secondary_element = $secondary_element;
                    if ( $id || $indexed ) {
                        ## create unique id for subsequent elements ##
                        my $nextid = $id + $index;
                        $new_secondary_element =~ s /<REPLACEID>/$nextid/g;
                    }
                    push @elements, $new_secondary_element;
                }
                else { push @elements, $element }
            }
        }

        # $next =~s /name=\"(\w\.+)\"/name=\"$1.$index\"/;  ## not necessary (?) - just read in array of values...
        @cells = ( $header, $extra, @elements );
        $Form->Set_Column( \@cells, -skip_rows => 2 );
        $Form->Set_Border(1);
    }
    else {
        if ( defined $self->{selectable} ) {
            my $name;
            if    ( $header =~ /\&field_name=(\w+)\&/ ) { $name = $1 }
            elsif ( $header =~ /\>(\w+)\</ )            { $name = $1 }

            push @cells, $q->checkbox( -name => 'Select', -value => $name, -checked => $self->{selectable} - 1, -label => '' );
        }
        push @cells, ( $header, $element, $extra );
        $Form->Set_Row( \@cells, -highlight => $highlight, -element_id => $element_id, -spec => $spec );
    }

    push @{ $self->{element_ids_included} }, $element_id if ($element_id);

    return;
}

#############################
#
# preset rows based on special configuration settings
#
# Options:
#   omit field
#   grey out field
#   preset field
#   ...
#
# Return (prompt, form_element, default);
#############################
sub preset_from_configs {
#############################
    my $sel     = shift;
    my $DBField = shift;

    my ( $prompt, $form_element, $default );

    return ( $prompt, $form_element, $default );
}

###############################
# Description:
#	- This method retrieves the direct parent fields for a given field
#
# <snip>
#	Usage example:
#		my @dependents = @{get_parent_field( -dbc => $dbc, -field => $field, -table => $table )};
#		my @dependents = @{get_parent_field( -dbc => $dbc, -dbfield_id => $dbfield_id )};
#	Return:
#		 Array ref of the parent fields
# </snip>
###############################
sub get_parent_field {
###############################
    my %args       = filter_input( \@_, -args => 'dbc,field,table,dbfield_id' );
    my $dbc        = $args{-dbc};
    my $field      = $args{-field};                                                # the field name
    my $table      = $args{-table};                                                # the table name of the field
    my $dbfield_id = $args{-dbfield_id};                                           # the DBField_ID
    my $debug      = $args{-debug};
    my $quiet      = $args{-quiet} || '1';

    if ( !$dbc->table_loaded('DBField_Relationship') ) { return [] }

    ## get DBField_ID if only $field and $table are given
    if ( !$dbfield_id ) {
        ($dbfield_id) = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE Field_Table = '$table' AND Field_Name = '$field'" );
    }
    if ( !$dbfield_id ) {
        $dbc->message("No valid DBField_ID") if ( !$quiet );
        return;
    }

    ## get the parent fields from DBField_Relationship table
    my @parents = $dbc->Table_find( 'DBField_Relationship', 'FKParent_DBField__ID', "WHERE FKChild_DBField__ID = $dbfield_id" );
    return \@parents;
}

###############################
# Description:
#	- This method retrieves the direct child fields for a given field
#
# <snip>
#	Usage example:
#		my @children = @{get_child_field( -dbc => $dbc, -field => $field, -table => $table )};
#		my @children = @{get_child_field( -dbc => $dbc, -dbfield_id => $dbfield_id )};
#	Return:
#		 Array ref of the child fields
# </snip>
###############################
sub get_child_field {
###############################
    my %args       = filter_input( \@_, -args => 'dbc,field,table,dbfield_id' );
    my $dbc        = $args{-dbc};
    my $field      = $args{-field};                                                # the field name
    my $table      = $args{-table};                                                # the table name of the field
    my $dbfield_id = $args{-dbfield_id};                                           # the DBField_ID
    my $debug      = $args{-debug};
    my $quiet      = $args{-quiet} || '1';

    if ( !$dbc->table_loaded('DBField_Relationship') ) { return [] }

    ## get DBField_ID if only $field and $table are given
    if ( !$dbfield_id ) {
        ($dbfield_id) = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE Field_Table = '$table' AND Field_Name = '$field'" );
    }
    if ( !$dbfield_id ) {
        $dbc->message("No valid DBField_ID") if ( !$quiet );
        return;
    }

    ## get the child fields from DBField_Relationship table
    my @children = $dbc->Table_find( 'DBField_Relationship', 'FKChild_DBField__ID', "WHERE FKParent_DBField__ID = $dbfield_id" );
    return \@children;
}

###############################
# Description:
#	- This method generates java scripts for controlling the dependent fields
#
# <snip>
#	Usage example:
#       my ( $trigger, $command, $on_load ) = $self->get_dependent_trigger( -table => $table, -field => $field );
#	Return:
#		 Array.
#			First element	- the trigger event (e.g. 'OnClick')
#			Second element	- the javascript to call for the event
#			Third element	- the javascript to call when the form is first loaded
# </snip>
###############################
sub get_dependent_trigger {
###############################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $table = $args{-table};
    my $field = $args{-field};
    my $debug = $args{-debug};
    my $quiet = $args{-quiet} || '1';

    my $dbc        = $self->{dbc};
    my $trigger_on = 'onClick';
    my ( $js, $js_load );
    my $dbfield_id;

    if ( !$dbc->table_loaded('DBField_Relationship') ) { return; }

    if ( $table && $field ) {    ## get DBField_ID
        ($dbfield_id) = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE Field_Table = '$table' AND Field_Name = '$field'" );
    }
    if ( !$dbfield_id ) {
        $dbc->message("No valid DBField_ID") if ( !$quiet );
        return;
    }

    ## check for fields dependent upon this field ##
    my %Dep = $dbc->Table_retrieve( 'DBField_Relationship,DBField', ["Concat(DBField.Field_Table,'.',DBField.Field_Name) as Filtered"],
        "WHERE DBField_Relationship.FKChild_DBField__ID = DBField_ID and DBField_Relationship.FKParent_DBField__ID = $dbfield_id" );

    my $field_reference;
    my $join_table;
    my $join_condition;
    my $i = 0;
    while ( defined $Dep{Filtered}[$i] ) {
        my $filtered = $Dep{Filtered}[$i];
        if ( !$field_reference ) {
            $field_reference = "$table.$field";
            if ( $field =~ /^FK\w+__ID$/xms ) {    # foreign key
                my ($foreign_key) = $dbc->Table_find( 'DBField', 'Foreign_Key', "WHERE DBField_ID = $dbfield_id" );
                my ( $ftable, $ffield ) = split '\.', $foreign_key;
                if ( $ftable && $ffield ) {
                    my ($reference) = $dbc->Table_find( 'DBField', 'Field_Reference', "WHERE Field_Table = '$ftable' and Field_Name = '$ffield'" );
                    if ($reference) {              # only use DBField.Field_Reference when the DBField.Field_Reference is set
                        $reference =~ s/\[/\\\[/g;    # escape '['
                        $reference =~ s/\]/\\\]/g;    # escape ']'
                        $field_reference = MIME::Base32::encode($reference);
                    }

                    ## if the join table is included in $searchTable already, shouldn't join again
                    my ( $Vtable, $view, $order_view, $Vtab, $Vcondition ) = $dbc->get_view( 'Work_Request', 'Plate.FK_Work_Request__ID', 'Work_Request_ID', '0' );
                    if ( $Vtable !~ /\b$ftable\b/xms ) {
                        $join_table     = $ftable;
                        $join_condition = MIME::Base32::encode("$table.$field=$ftable.$ffield");
                    }
                }
            }
        }
        my $extra_condition = '';
        my $filter_url      = "/$URL_dir_name/cgi-bin/ajax/query.pl" . "?Database_Mode=$dbc->{mode}&Field=$filtered&Reference_Field=$field_reference&Join_Tables=$join_table&Join_Condition=$join_condition&Condition=$extra_condition";

        #print HTML_Dump "filter_url for $table.$field: $filter_url";
        my $on_change = "dependentFilter('$table.$field.Choice','$filter_url','$filtered', 0, 1); ";

        ## Don't run this trigger when form loads since it will cause the default value to be lost ##
        #my $on_load = $on_change;
        #$on_load =~ s/,this,/,\'$table\.$field\',/;
        $js .= $on_change;

        #$js_load .= $on_load;
        $i++;
    }

    if ( !$js ) {return}

    return ( $trigger_on, $js, $js_load );
}

################################
#
# Replace indexed element id
#
################################
sub _replace_indexed_element_id {
################################
    my %args    = filter_input( \@_ );
    my $element = $args{-element};
    my $prefix  = $args{-prefix};

    $prefix =~ s/\.SearchList//;    ## truncate if we have found the searchlist element...

    ## Need to go through and fix places where elements use '.' in names and ids
    my $formatted_prefix = $prefix;
    $formatted_prefix =~ s/\./\-/g;    # replace '.' with '-' ('.' is used for javascript class selectors)

    $element =~ s/ id=([\"\'])$prefix\b/ id=$1$formatted_prefix\-<REPLACEID>/g;

    ## We may need to re-write this
    $element =~ s/(jQuery\([\"\']#$prefix)([\'\"])/$1\-<REPLACEID>$2/g;

    $element =~ s/ id=([\"\'])indicator_$prefix\[\'\"]/ id=$1indicator_$formatted_prefix\-<REPLACEID>$2/g;    ## replace autocomplete indicator as well

    return $element;
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

$Id: DB_Form.pm,v 1.82 2004/11/30 01:42:31 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
