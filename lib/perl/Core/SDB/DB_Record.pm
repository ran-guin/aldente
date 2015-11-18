##############################################
#
# $ID$
#
# CVS Revision: $Revision: 1.38 $
#     CVS Date: $Date: 2004/12/07 18:33:54 $
#
##############################################
#
# This package sets up a multi-line view of Table records
# that may be edited, searched, or deleted...
#
##############################################
# Ran Guin (2001) rguin@bcgsc.bc.ca
package SDB::DB_Record;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Record.pm - $ID$

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
$ID$<BR>This package sets up a multi-line view of Table records<BR>that may be edited, searched, or deleted...<BR>Ran Guin (2001) rguin@bcgsc.bc.ca<BR>

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
#
use CGI qw(:standard);
use DBI;
use strict;
use RGTools::RGIO;
use SDB::HTML;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;
use alDente::SDB_Defaults;

use alDente::Form;

use RGTools::HTML_Table;
use RGTools::Views;
use RGTools::String;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($homefile $testing %Field_Info);    ##### Exported from CustomSettings..
use vars qw(%Primary_fields);
use vars qw(%Settings $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my @FontClasses = ( 'vsmall', 'small', 'medium', 'large', 'vlarge' );

##############################
# constructor                #
##############################

#############
sub new {
#############
    my $this  = shift;
    my $dbc   = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = shift;
    my $link  = shift;                                                                     ### link back to home page...

    my ($class) = ref($this) || $this;
    my ($self) = {};
    if ( $table =~ /(\w+)/ ) { $table = $1; }                                              ## extracting the first table name if more than one table name provided

    $self->{dbc}      = $dbc;
    $self->{HomeLink} = $link || $dbc->homelink();
    $self->{Table}    = $table;

    $self->{Fields}          = [];
    $self->{defined_prompts} = 1;                                                          ##### if prompts are externally defined
    #####  (in $Prompts{$table})
    $self->{Index} = 0;

    my $mode   = param('Form Mode');
    my @listed = param('Display');                                                         ##### list of fields to be displayed (default)

    my @defined_fields = $dbc->get_fields( -table => $table, -defined => 'defined', -include_hidden => 0 );    ## (was get_defined_fields)

    my @fields;
    ######### change names of fields as necessary...
    my @prompts;

    my $index = 0;
    while ( defined $defined_fields[$index] ) {
        my $field      = $defined_fields[$index];
        my $this_Table = $table;
        if ( $field =~ /(\w+)\.(\w+)/ ) {
            $this_Table = $1;
            $field      = $2;
        }

        if ( $field =~ /(.*) as (.*)/i ) {
            $self->{Label}->{$1} = $2;
            push( @fields, $1 );
            push @prompts, $2;
        }
        elsif ( defined $Field_Info{$table} && defined $Field_Info{$table}{$field}{Prompt} ) {    ## get preset prompt value if defined
            my $prompt = $Field_Info{$table}{$field}{Prompt};
            $self->{Label}->{$field} = $field;
            push( @fields, $field );
            push @prompts, $prompt;
        }
        else {
            $self->{Label}->{$field} = $field;
            push( @fields, $field );
            push @prompts, '';
        }

        $index++;
    }

    $self->{ID} = $Primary_fields{$table};
    $self->{ID} ||= join ',', get_field_info( $dbc, $table, undef, 'pri' );

    $self->{IDs} = 1;    ### number of primary keys (limited to 1 for now)

    unless ( grep /^$self->{ID}$/, @fields ) {
        @fields = ( $self->{ID}, @fields );    ### ensure primary key included..
    }

    unless (@listed) {
        @listed = @fields;
    }
    $self->{Fields} = \@fields;                ### all possible fields

    $self->{View}             = param('View') || 'Basic';
    $self->{num_fields}       = int(@fields);
    $self->{displayed_fields} = int(@fields);
    $self->{Display}          = \@fields;                   ### fields to display
    $self->{OrderBy}          = '';                         ### order specification...
    $self->{OrderDir}         = 'ASC';                      ### order Asc or Desc
    $self->{Index}            = 0;                          ### default index to 0
    $self->{Limit}            = 1000;                       ### default limit to list size
    $self->{Title}            = "$table Records";
    $self->{records}          = 0;

    #    $self->{OnOff} = [map {1} (1..$self->{num_fields})];  ### display flags
    $self->{Size}         = {};                                                 ## [map {10} (1..$self->{displayed_fields})];  ### size specs for fields
    $self->{Size_Default} = 10;                                                 ### size specs for fields
    $self->{Links}        = [ map {''} ( 1 .. $self->{displayed_fields} ) ];    ### specify links for filds
    $self->{FType}        = [];
    $self->{showfields}   = 1;                                                  ### flag to allow viewing of other fields...

    #### automatically retrieve date type fields (to allow searching by date)... ###
    my @datefields = get_field_info( $dbc, $table, undef, 'date' );
    $self->{DateFields} = \@datefields;
    $self->{Date_Field} = '';                                                   ### specify active DateField

    $self->{FontSize}     = Extract_Values( [ param('Class'), 1 ] );
    $self->{Copy_Exclude} = [];                                                 ### fields to exclude when copying (eg. unique)
    $self->{Auto_append}  = 1;                                                  ### appends if no records selected for change...
    $self->{Page}         = param('PageName') || 'Main';                        ### give name to page (allow variations..)

    ### Print Options ###
    $self->{Option1}     = '';
    $self->{Option2}     = '';
    $self->{Option3}     = '';
    $self->{BasicOption} = '';                                                  ### option included in basic view as well...

    $self->{Highlight} = {};

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

########################
sub Display_Fields {
########################
    #
    #   Specify List of Fields to Display
    #
    my $self   = shift;
    my $fields = shift;
    my $size   = shift;

    my @list = @$fields;
    my @size_list;
    if ($size) {
        @size_list = @$size;
    }

    my @displayed;
    my @labeled;
    my @sizes;
    for my $index ( 0 .. $#list ) {
        my $field = $list[$index];
        if ( $field =~ /(.*) as (.*)/ ) {
            push( @displayed, $1 );
            push( @labeled,   $2 );
        }
        else {
            push( @labeled,   $field );
            push( @displayed, $field );
        }
        $size_list[$index] ||= 10;
        push( @sizes, $size_list[$index] );
    }

    unless ( grep /^$self->{ID}$/, @displayed ) {
        @displayed = ( $self->{ID}, @displayed );    ### ensure primary key included..
    }
    $self->{Display} = \@displayed;

    my $index = 0;
    foreach my $display (@displayed) {
        $self->{Size}->{ $displayed[$index] } = Extract_Values( [ $sizes[$index], $self->{Size_Default} ] );
        $index++;
    }
    $self->{displayed_fields} = int(@displayed);
    return 1;
}

##################
sub Hide_Fields {
##################
    my $self   = shift;
    my $fields = shift;

    my @list = @$fields;

    my @displayed = @{ $self->{Display} };

    my @new_display = ();
    foreach my $field (@displayed) {
        if   ( grep /^$field$/, @list ) { }                                 ## hide
        else                            { push( @new_display, $field ); }
    }

    $self->{Display} = \@new_display;

    return 1;
}

#######################
sub Set_Title {
#######################
    #
    # Specify a Title
    #
    my $self  = shift;
    my $title = shift;

    $self->{Title} = $title;
    return 1;
}

#######################
sub Set_DateField {
#######################
    #
    # Specify a field that may be used to specify Dates for searching...
    #
    my $self  = shift;
    my $field = shift;

    $self->{DateField} = $field;
    return 1;
}

####################
sub Highlight {
####################
    my $self   = shift;
    my $ids    = shift;
    my $colour = shift || 'red';

    my @id_list = @$ids;
    foreach my $index (@id_list) {
        $self->{Highlight}->{$index} = $colour;
    }
    return 1;
}

##########################
sub Confirm_Delete {
##########################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'selected' );
    my $selected = $args{-selected};
    my $dbc      = $self->{dbc};

    my $select_list = join ',', @$selected;

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {
        $prev_Cond = param('PreviousCondition');
    }
    my $limit_option = param('LIMIT');

    my $id = $self->{ID};

    my $num = int(@$selected);
    &RGTools::RGIO::Message("Are you SURE that you want to delete $num record(s) (highlighted below)?!");

    print alDente::Form::start_alDente_form( $dbc, 'Editing Form', undef ) . hidden( -name => 'LIMIT', -value => $limit_option, -force => 1 ) .

        submit( -name => 'Confirmed Deletions', -value => 'YES', -style => "background-color:red" ), hidden( -name => 'PageName', -value => $self->{Page} ), hidden( -name => 'TableName', -value => $self->{Table} ), &hspace(40),
        submit( -name => 'NO Delete', -value => 'NO', -style => "background-color:yellow" ), hidden( -name => 'PreviousCondition', -value => $prev_Cond, -force => 1 ), hidden( -name => 'Delete List', -value => $select_list ), "\n</FORM>";
    return 1;
}

##############################
# public_functions           #
##############################

##########################
sub DB_Record_Viewer {
##########################
    #
    # check for parameters to see if we need to use this module...
    #
    my $Records = shift;
    my $cond    = shift;

    my @selected = param('Mark');
    my $table    = $Records->{Table};
    my $dbc      = $Records->{dbc};

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {

        $prev_Cond = param('PreviousCondition');
    }
    $cond ||= $prev_Cond;

################### Order Database Viewer ###############################

    if ( param('Search Matching Records') ) {    ##### Look for specified strings

        #	print &Views::Heading("Search Results");
        #	$Records->List_by_Condition($cond); return 1;
        $Records->Search();
    }
    elsif ( param('Set Selected Values') ) {     ##### Update selected records

        #	print &Views::Heading("Set Values");
        #	$Records->List_by_Condition($cond); return 1;
        if ( param('Set Selected Values') eq 'Add Selected Values' ) {
            $Records->Set_Values( \@selected, 'add' );
        }
        else {
            $Records->Set_Values( \@selected, 'set' );
        }
        $Records->{showfields} = 0;
    }
    elsif ( param('Next Set of Records') ) {
        my $limit_index = param('Index');
        my $start_index = 0;
        my $nextindex   = param('Next Set of Records');
        if ( $nextindex =~ /Next (\d+)/ ) { $start_index = $limit_index + $1; }
        $Records->{Index} = $start_index;

        $Records->List_by_Condition($cond);
    }
    elsif ( param('Previous Set of Records') ) {
        my $limit_index = param('Index');
        my $start_index = 0;
        my $nextindex   = param('Next Set of Records');
        if ( $nextindex =~ /Previous (\d+)/ ) { $start_index = $limit_index - $1; }
        if ( $start_index < 0 ) { $start_index = 0; }
        $Records->{Index} = $start_index;
        $Records->List_by_Condition($cond);
    }
    elsif ( param('Refresh') || param('New DBView Index') ) {
        if ( param('New DBView Index') ) {
            my $newindex = param('New DBView Index');
            if ( $newindex =~ /(\d+) - (\d+)/ ) {
                $newindex = $1 - 1;
            }
            $Records->{Index} = $newindex;
        }
        $Records->List_by_Condition($cond);
    }

    #    elsif (param('Add Record')) {
    #	&SDB::DB_Form_Viewer::add_record($dbc,$table);
    #	$Records->List_by_Condition($cond);
    #    }
    elsif ( param('Copy Record') ) {
        $Records->Copy( \@selected );
    }
    elsif ( param('Delete Record') ) {
        $Records->Confirm_Delete( \@selected, -dbc => $dbc );
        $Records->Highlight( \@selected, 'red' );
        $Records->List_by_Condition($cond);
    }
    elsif ( param('NO Delete') ) {
        Message("Aborted Deletion");
        $Records->List_by_Condition($cond);
    }
    elsif ( param('Confirmed Deletions') ) {
        my $select_list = param('Delete List');
        $dbc->delete_records( $Records->{Table}, $Records->{ID}, $select_list, -cascade => get_cascade_tables( $Records->{Table} ) );
        $Records->List_by_Condition($cond);
    }

    #    elsif ($show) {
    #	my $prevCond = $cond;
    #	$Records->List_by_Condition($prevCond);
    #    }
    elsif ( ( param('Edit_Records') =~ /[><]/ ) || ( param('Edit_Records') =~ /Edit/i ) ) {
        $Records->List_by_Condition($cond);
    }
    elsif ( param('PageName') ) {
        $Records->List_by_Condition($cond);
    }

    else { return 0; }
    return 'form';    ### found...
}

#############################
sub Set_Button_Labels {
#############################
    #
    # (initialize buttons) - not used...
    #
    my $Records = shift;

    $Records->{add_button}    = shift;    ## 'Add Selected Orders';
    $Records->{copy_button}   = shift;    ## 'Copy Selected Orders';
    $Records->{delete_button} = shift;    ## 'Delete Selected Orders';
    $Records->{input_button}  = shift;    ## 'Custom Button';

    return 1;
}

####################
sub Set_Option {
####################
    my $Records = shift;
    my $option  = shift;
    my $index   = Extract_Values( [ shift, 1 ] );
    my $always  = shift;

    if ( $index && ( $index < 4 ) ) {
        $Records->{"Option$index"} = $option;
        if ($always) { $Records->{"BasicOption$index"} = $option; }
    }
    else { Message("Only 1-3 options allowed at this time"); }

    return 1;
}

#####################
sub Records_home {
#####################
    #
    # enter without any specified conditions
    #
    my $Records = shift;
    $Records->List_by_Condition( $Records->{Def_Condition} );
    return 1;
}

#####################
sub Get_from_ID {
#####################
    #
    # Get record(s), specifying only ID fields (primary keys)
    #
    my $Records = shift;

    my $ID1 = shift;
    my $ID2 = shift;

    my $dbc = $Records->{dbc};

    my $PID1 = $Records->{ID} . " in (" . $dbc->dbh()->quote($ID1) . ")";

    ################# add second primary ID if exists
    my $PID2 = '';
    if ($ID2) { $PID1 = "AND " . $Records->{ID2} . " in (" . $dbc->dbh()->quote($ID2) . ")"; }

    my $condition = "WHERE $PID1 $PID2";

    my %Info = main::Table_retrieve( $Records->{dbc}, $Records->{Table}, $Records->{Fields}, $condition );

    return 1;
}

##########################
sub check_date_spec {
##########################
    #
    # adjust condition to include specification of DateField Range
    #
    my $condition  = shift;
    my $date_field = shift;

    unless ( $date_field =~ /\w+/ ) {
        print "No Date Field specified";
        return $condition;
    }

### get rid of old date condition... ###
    $condition =~ s/AND [a-zA-Z0-9_]+ \>[=\s]* [\'\"][0-9\-]+[\'\"]/ /ig;
    $condition =~ s/AND [a-zA-Z0-9_]+ \<[=\s]* [\'\"][0-9\-]+[\'\"]/ /ig;

    unless ( param('Any Date') ) {
        my $date;
        if ( param('Since') ) {    ####### specify oldest Order Date to retrieve
            $date = param('Since');

            #	    push(@conditions,"$date_field >= '$date'");
            if ( $condition =~ /WHERE (.+)$/i ) {
                $condition = "WHERE 1 AND $date_field >= '$date' AND $1";    ## if other conditions
            }
            else { $condition = "WHERE 1 AND $date_field >= '$date' $condition"; }    ## if only ORDER/LIMIT..

        }
        if ( param('Until') ) {                                                       ####### specify most recent Order Date to retrieve
            $date = param('Until');

            #	    push(@conditions,"$date_field <= '$date'");
            if ( $condition =~ /WHERE (.+)$/i ) {
                $condition = "WHERE 1 AND $date_field <= '$date' AND $1";             ## if other conditions
            }
            else { $condition = "WHERE 1 AND $date_field <= '$date' $condition"; }    ## if only ORDER/LIMIT..
        }

        #	unless ($date) {push(@conditions,"$date_field <= $since");} ## default
    }
    return $condition;
}

#########################
sub Set_Conditions {
#########################
    #
    # initiate given condition...
    #
    my $Records   = shift;
    my $condition = shift;
    my $view      = shift;

    #### Fix Limit Condition ####
    my $limit;
    if ( $condition =~ s/LIMIT (\d+)/ /ig ) { $limit = $1; }
    if ( param('List Limit') =~ /(\d+)/ ) {
        $limit = $1;    ### override above if specified...
    }

    #### Fix Order Condition ####
    my $order;
    my $order_dir;
    if ( $condition =~ s/ORDER BY (\w+)\s*(Asc|Desc)/ /ig ) {
        $order = "$1 $2";
    }
    elsif ( $condition =~ s/ORDER BY (\w+)/ /ig ) {
        $order = $1;
    }
    if ( param('OrderBy') ) {
        $order     = param('OrderBy');    ### override above if specified...
        $order_dir = param('OrderDir');
    }

    if ($limit) { $Records->{Limit} = $limit; }
    if ( $order =~ /(\w*)\s+(ASC|DESC)/i ) { $order = $1; $order_dir = $2; }
    if ($order) {
        $Records->{OrderBy}  = $order;
        $Records->{OrderDir} = $order_dir;
    }
    elsif ( defined $Order{ $Records->{Table} } ) {
        my $ordered = $Order{ $Records->{Table} };
        if ( $ordered =~ /^(.*) (ASC|DESC)/i ) {
            $Records->{OrderBy}  = $1;
            $Records->{OrderDir} = $2;
        }
        else {
            $Records->{OrderBy}  = $ordered;
            $Records->{OrderDir} = 'ASC';
        }
    }

    if ( $view =~ /advanced/i ) {
################### Replace Types/Fundings with auto-code ################
        my $def_DF = $Records->{DateFields}[0] || '';
        if ($def_DF) {
            if ( param('Search Matching Records') ) {
                $condition = &check_date_spec( $condition, $def_DF );
            }
        }
    }
    return $condition;
}

##############
sub Search {
##############
    my $Records = shift;

    my $dbc = $Records->{dbc};

    my $start_search = param('Start Search');

    #    $check_date = shift;

    my $table = $Records->{Table};
    unless ( %Field_Info && defined $Field_Info{$table} ) { initialize_field_info( $dbc, $table ) }

    #    my $date_field = param('DateField') || $Records->{DateField};

    my @conditions = ( !$start_search );    ### start off conditions (1 is always true...) AND ..

    #    unless (param('Any Date') || !$date_field) {
    #	if (param('Since')) {        ####### specify oldest Order Date to retrieve
    #	    my $date = param('Since');
    #	    push(@conditions,"$date_field >= '$date'");
    #	}
    #	if (param('Until')) {        ####### specify most recent Order Date to retrieve
    #	    my $date = param('Until');
    #	    push(@conditions,"$date_field <= '$date'");
    #	}
    #    }

    foreach my $field ( @{ $Records->{Display} } ) {
        my $label = $field;
        $label =~ s /(.*)\.(.*)/$2/;    ## truncate table prefix if it exists
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;
            $label = $3;
        }

        my ($fk) = foreign_key_check( -dbc => $dbc, -field => $field );    ## keep track of foreign keys ##
        my $type = $Field_Info{ $Records->{Table} }{$field}{Type};

        my $search_field_name = 'SEARCH_FIELD_' . $label;
        if ( param("$search_field_name") =~ /\S/ ) {
            my $value = param("$search_field_name");
            #### Dates require a bit more touchy specification ...(allow > AND quotes)..

            if ( $fk && $value =~ /[a-zA-Z]/ ) {
                my $id_value = get_FK_ID( $dbc, $field, $value, -quiet => 1 );    ### in case FK..  quiet mode if searching ...

                #                if ($id_value) { $value = $dbc->dbh()->quote($id_value) }    ### use retrieved value if applicable
            }
            my $cond = convert_to_condition( $value, -field => $field, -type => $type );
            push( @conditions, $cond );
        }
        elsif ( param("$search_field_name Choice") =~ /\S/ ) {
            my @options = param("$search_field_name Choice");
            my $list = join ',', @options;

            if ($fk) {
                my @ids = map { my $id = get_FK_ID( $dbc, $field, $_ ); $_ = $id; } @options;
                $list = join ',', @ids;
            }

            my $cond = convert_to_condition( $list, -field => $field, -type => $type );
            push( @conditions, $cond );
        }
        elsif ( $type =~ /date/i || $type =~ /time/i ) {
            my $from = param("from_$search_field_name");
            my $to   = param("to_$search_field_name");
            if ( $from && $to ) {
                my $from_value = convert_date( $from, 'SQL' );
                my $to_value   = convert_date( $to,   'SQL' );
                my $cond = convert_to_condition( "$from_value - $to_value", -field => $field, -type => $type );
                push( @conditions, $cond );
            }
        }

        ################# Custom Edit to allow for Specifying Funding in Search... ##################
        if ( param("FUNDING $label") =~ /\S/ ) {
            my $value = param("FUNDING $label");
            if ( $field =~ /FK[a-zA-Z0-9]*_(.*)__(.*)/ ) {
                my $id_value = get_FK_ID( $dbc, $field, $value );    ### in case FK..
                $value = $id_value if $id_value;
            }
            my $cond = convert_to_condition( $value, -field => $field );
            push( @conditions, $cond );
        }
    }

    my $condition = "WHERE " . join ' AND ', @conditions;

    if ( param('SubSearch') =~ /Current/ ) {
        my $id_field = param('ID_Field');

        my %list;    ### ensure list unique...
        foreach my $id ( param('ID_List') ) {
            $list{$id} = 1;
        }

        my @ids = keys %list;
        my $id_list = Cast_List( -list => \@ids, -to => 'string', -autoquote => 1 );

        if ( $id_field && $id_list ) {
            $condition .= " AND $id_field in ($id_list)";
        }
    }

    $Records->List_by_Condition($condition);
    return 1;
}

##############
sub Copy {
##############
    #
    # Copy Selected Records...
    #
    my $Records  = shift;
    my $selected = shift;
    my $table    = $Records->{Table};

    my $dbc = $Records->{dbc};

    my $select_list = join ',', @$selected;
    my $date_field  = $Records->{Date_Field};
    my @exclude     = @{ $Records->{Copy_Exclude} };
    push( @exclude, $Records->{ID} );
    my $ok = main::Table_copy( $dbc, $table, "where $Records->{ID} in ($select_list)", \@exclude, $date_field );
    main::Message("Added record(s) ($ok)");

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {
        $prev_Cond = param('PreviousCondition');
    }

    $Records->List_by_Condition($prev_Cond);
    return 1;
}

###################
sub Set_Values {
###################
    #
    # Append/Edit Record with specified values...
    #
    my $Records     = shift;
    my $select_list = shift;
    my $mode        = shift;

    my $dbc = $Records->{dbc};

    my $error_flag = 0;

    my $table = $Records->{Table};

    unless ( %Field_Info && defined $Field_Info{$table} ) { initialize_field_info( $dbc, $table ) }

    my $prev_Cond;
    if ( param('Mark') && param('Mark_Field') ) {
        my $field = param('Mark_Field');
        my $list = join "\",\"", param('Mark');
        $prev_Cond = "WHERE $field in (\"$list\")";
    }
    elsif ( param('PreviousCondition') ) {
        $prev_Cond = param('PreviousCondition');
    }

    my @selected = @$select_list;
    my @field_list;
    my @value_list;
    my $entered = 0;

    if ( int(@selected) == 0 && $mode eq 'set' ) {
        $dbc->warning("No record is selected for update!");
        $error_flag = 1;
        $Records->List_by_Condition( -condition => $prev_Cond, -error_flag => $error_flag );
        return;
    }

    foreach my $field ( @{ $Records->{Display} } ) {
        my $label = $field;
        $label =~ s /\.(.*)/$1/;    ## truncate table prefix if it exists
        if ( $field =~ /(.*) as (.*)/ ) {
            $field = $1;
            $label = $3;
        }

        my $edit_field_name = 'EDIT_FIELD_' . $label;
        my $value = param("$edit_field_name") || param("$edit_field_name Choice");
        if ( $value =~ /\S/ ) {
            if ( $Field_Info{$table}{$field}{Type} =~ /set/i ) {    ### join in case of set..
                $value = join ',', param("$edit_field_name");
                if ( !$value ) {
                    $value = join ',', param("$edit_field_name Choice");
                }
            }

            if ( $Field_Info{$table}{$field}{Type} =~ /date/i ) {

                #		print "<BR>convert $value..";
                $value = convert_date( $value, 'SQL' );
            }
            elsif ( $Field_Info{$table}{$field}{Type} =~ /time/i ) {

                #		print "<BR>convert $value..";
                $value = convert_time($value);
            }
            push( @field_list, $field );
            if ( $field =~ /FK[a-zA-Z0-9]*_(.*)__(.*)/ ) {
                $value = get_FK_ID( $dbc, $field, $value );
                unless ($value) { $error_flag = 1; last; }    ### cannot set value if not found...
            }
            push( @value_list, $value );
            $entered++;
        }
    }
    $select_list = join ',', map { $dbc->dbh()->quote($_) } @selected;

    if ($error_flag) { }                                      ### do nothing , but go to bottom...
    if ( $select_list && $entered ) {

        #	print "Update: (@field_list)=@value_list.";
        my $ok = $dbc->Table_update_array( $table, \@field_list, \@value_list, "where $Records->{ID} in ($select_list)", -autoquote => 1 );
        if   ($ok) { main::Message("Updated $ok records"); }
        else       { main::Message("No changes noted"); }
########## Custom Insertion for Solution Table ##################
        if ( $table eq 'Solution' ) {
            my $type = param('EDIT_FIELD_Solution_Type');
            if ( $type eq 'Primer' ) {
                &alDente::Solution::update_primer($select_list);
            }
        }
########## End Custom Insertion for Solution Table ##################
    }
    elsif ( $select_list && !$entered ) { Message("Nothing changed"); }
    elsif ( $entered && $Records->{Auto_append} ) {
        my $added = $dbc->Table_append_array( $table, \@field_list, \@value_list, -autoquote => 1 );
        if ($added) {
            main::Message("Added record ($added)");
            $Records->Search();    ### show records with these fields added....
            return 1;
        }
        else {
            main::Message("Nothing Added");
            $error_flag = 1;
        }
########## Custom Insertion for Solution Table ##################
        if ( $table eq 'Solution' ) {
            my $type = param('EDIT_FIELD_Solution_Type');
            if ( $type eq 'Primer' ) {
                &alDente::Solution::update_primer($added);
            }
        }
########## End Custom Insertion for Solution Table ##################
    }
    elsif ( !$Records->{Auto_append} ) {
        main::Message("No Records selected to Edit");
    }
    else { main::Message("Nothing entered"); }

    $Records->List_by_Condition( -condition => $prev_Cond, -error_flag => $error_flag );
    return 1;
}

######################
sub Add_Header {
######################
    #
    # Add Header (advanced view optional) above Record list...
    #
    # 'Cells' are created initially, so that the location of various
    # options may be adjusted within the displayed table easily.
    #
    #
    #
    my %args          = filter_input( \@_, -args => "records,view,display,limit" );
    my $Records       = $args{-records};
    my $view          = $args{-view};
    my $display       = $args{-display};
    my $add_attribute = $args{-add_attribute};
    my $limit_option  = $args{-limit} || param('LIMIT');
    my $option_colour = '';                                                           #  'bgcolor=lightblue';
    my $background    = 'lightgrey';                                                  #  set background colour for options area

    ( my $since ) = split ' ', &date_time('-30d');                                    ### default to last month
    ( my $upto )  = split ' ', &date_time();                                          ### todays date...

    my @fields    = @{ $Records->{Fields} };
    my @displayed = @$display;

    @displayed = $Records->{Display};

########################################################
## First generate the Cells available for the Header ##
########################################################

########## Text_Size option #########
    my $TextSize_Cell
        = "<B><NOBR>Text Size:</NoBR></B>\n"
        . submit( -name => 'Edit_Records', -value => "<", -class => "Search" )
        . submit( -name => 'Edit_Records', -value => ">", -class => 'Search' )
        . " ($FontClasses[$Records->{FontSize}])\n"
        . hidden( -name => 'Class', -value => $Records->{FontSize}, -force => 1 );

######## Extra field specification choice (optional) ###########
    my $extra_choice;
    my $Choice_Cell = $extra_choice;

####### Sorting Fields.. ##########
    my @Possible_sort_fields = @{ $Records->{Fields} };
    my $def_sort             = $Possible_sort_fields[0];

    my $Sort_Cell
        = "\n<B>Sort by: </B>\n"
        . radio_group( -name => 'OrderDir', -value => [ 'ASC', 'DESC' ], -default => $Records->{OrderDir}, -force => 1 )
        . "\n<BR>"
        . popup_menu( -name => 'Order By', -value => [ '', @Possible_sort_fields ], default => $Records->{OrderBy} );

####### Add Fields to View ########
    my @Invisible;    ## Fields not currently shown...
    foreach my $key ( @{ $Records->{hidden} } ) {
        ##### allow user to select other labels to display..
        if ( grep {/^$key$/} @displayed ) {
            next;
        }
        if   ( $Records->{Label}{$key} ) { push @Invisible, $Records->{Label}{$key} }
        else                             { push @Invisible, $key }
    }

    my $Include_Cell = Show_Tool_Tip( 'Add Columns:', 'To Hide fields, deselect checkbox for the column and refresh page' );

    if   ( $#Invisible < 0 ) { $Include_Cell .= "(all selected)"; }
    else                     { $Include_Cell .= scrolling_list( -name => 'Add_Display', -values => \@Invisible, -size => 4, -multiple => 2 ); }

###### DateFields ############
    my $year   = &date_time();
    my $fiscal = &date_time();
    if ( $fiscal =~ /^(\d\d\d\d)-(\d\d)/ ) {
        if   ( $2 > 5 ) { $fiscal = $1 . "-05-01"; }
        else            { $fiscal = $1 - 1 . "-05-01"; }    ### if we are in the beginning of a new year...
    }
    ( my $today )   = split ' ', &date_time('-1d');
    ( my $last7d )  = split ' ', &date_time('-7d');
    ( my $last30d ) = split ' ', &date_time('-30d');

    $year =~ /^(\d\d\d\d)/;
    $year = $1 . "-01-01";

    my @datefields = @{ $Records->{DateFields} };

    #### Copy, Delete buttons... ####
    my $copy_button   = 'Copy Record';
    my $copy_label    = $Records->{copy_button} || $copy_button;
    my $delete_button = 'Delete Record';
    my $delete_label  = $Records->{delete_button} || $delete_button;

    my $element_id = substr( rand(), -8 );
    my $search_id  = 'search' . $element_id;
    my $update_id  = 'update' . $element_id;
    $Records->{search_element_id} = $search_id;
    $Records->{update_element_id} = $update_id;

    my $default_mode = 'Search';
    my $Form_mode = "<B>Toggle between Search & Edit Mode</B> -> " . hidden( -name => 'LIMIT', -value => $limit_option, -force => 1 );

    if ( $limit_option eq 'Search' ) {
        $Form_mode .= radio_group(
            -name    => 'Form Mode',
            -values  => ['Search'],
            -default => $default_mode,
            -onClick => "unHideElement('$search_id','table-row'); HideElement('$update_id','table-row'); unHideElement('$search_id.Opt','table-row'); HideElement('$update_id.Opt');"
        ) . Show_Tool_Tip( ' (X)Edit/Append', 'Editing/ Appending Turned off for these records' );

    }
    elsif ( $limit_option eq 'Edit/Append' ) {
        $Form_mode .= Show_Tool_Tip( ' (X)Search', 'Searching Turned off for these records' )
            . radio_group(
            -name    => 'Form Mode',
            -values  => ['Edit/Append'],
            -default => $default_mode,
            -onClick => "HideElement('$search_id'); unHideElement('$update_id','table-row'); HideElement('$search_id.Opt'); unHideElement('$update_id.Opt','table-row');"
            );

    }
    else {
        $Form_mode .= radio_group(
            -name    => 'Form Mode',
            -values  => ['Search'],
            -default => $default_mode,
            -onClick => "unHideElement('$search_id','table-row'); HideElement('$update_id','table-row'); unHideElement('$search_id.Opt','table-row'); HideElement('$update_id.Opt');"
            )
            . radio_group(
            -name    => 'Form Mode',
            -values  => ['Edit/Append'],
            -default => $default_mode,
            -onClick => "HideElement('$search_id'); unHideElement('$update_id','table-row'); HideElement('$search_id.Opt'); unHideElement('$update_id.Opt','table-row');"
            );
    }

    my $Search_button = submit( -name => 'Search Matching Records', -class => "Search" ) . "\n<BR>" . radio_group( -name => 'SubSearch', -values => [ 'All Records', 'Current List' ], -default => 'All Records' );

    my $Edit_button = Show_Tool_Tip( submit( -name => 'Set Selected Values', -value => 'Set Selected Values', -class => "Action", -onClick => "return validateForm(this.form,0,'edit')" ), 'Update SELECTED RECORDS ONLY with fields as indicated' )
        . "\n<BR>(Selected records only)";

    ## separate append button (for now it is just for the form validator ##A
    my $Append_button
        = Show_Tool_Tip( submit( -name => 'Set Selected Values', -value => 'Add Selected Values', -class => "Action", -onClick => "return validateForm(this.form)" ), 'Add record with fields defined as entered' ) . "\n<BR>(Adds if no selection)";

    my $Copy_button = Show_Tool_Tip( submit( -name => $copy_button, -value => $copy_label, -class => 'Action' ), 'Copy selected records' ) . "\n<BR>(May not work if unique fields)";

    my $Delete_button = Show_Tool_Tip( submit( -name => $delete_button, -value => $delete_label, -class => 'Action' ), 'Delete selected records' ) . "\n<BR>(Selected Record only)";

    my $Refresh_View_Cell = Show_Tool_Tip( submit( -name => 'Refresh', -value => 'Refresh', -force => 1, -class => "Std" ), 'Regenerate Form.  (Deselect columns to hide; Add columns to include as desired)' )
        . "\n<BR>(use to refresh if rows or columns are selected or de-selected)";

########### Custom Option Cells .. ###############

    my $Option1_Cell       = $Records->{Option1};
    my $Option2_Cell       = $Records->{Option2};
    my $Option3_Cell       = $Records->{Option3};
    my $Basic_Option_Cell1 = $Records->{BasicOption1};
    my $Basic_Option_Cell2 = $Records->{BasicOption2};
    my $Basic_Option_Cell3 = $Records->{BasicOption3};

################### Advanced view showing DateField specification, Ordering, etc. #####################

####################################################
## Print Header using 'Cells' generated above ... ##
####################################################

    my $Header = HTML_Table->new();
    if ( $view =~ /Advanced/i ) { $Header->Set_Title('Set Options'); }
    $Header->Set_Width('900');
    $Header->Toggle_Colour('0');
    $Header->Set_Line_Colour( 'white', 'white' );

    #
    # Advanced view should be unnecessary - some features may be moved into basic functionality in a cleaner way
    # Date range specifying can be accomodated with the search / update modes below...
    #
    print '<hr>';
    print $Form_mode . &hspace(30) . $Include_Cell . &hspace(5) . $TextSize_Cell;
    print '<hr>';

    #    $Header->Set_Row([$Include_Cell, $TextSize_Cell]);

    $Header->Set_Row( [ &vspace(20) ] );

    my @search_row = ( $Search_button, $Copy_button, $Delete_button, $add_attribute, $Refresh_View_Cell );
    my @edit_row = ( $Edit_button, $Append_button, $Copy_button, $Delete_button, $add_attribute, $Refresh_View_Cell );

    my ( $default_search, $default_edit ) = ( 'table-row', 'none' );
    if ( $Records->{mode} ne 'Search' ) { $default_search = 'table-row'; $default_edit = 'none' }

    $Header->Set_Row( \@search_row, 'white', -element_id => $Records->{search_element_id} . '.Opt', -spec => "style='display:$default_search'" );
    $Header->Set_Row( \@edit_row,   'white', -element_id => $Records->{update_element_id} . '.Opt', -spec => "style='display:$default_edit'" );

    $Header->Set_VAlignment('top');

    $Header->Printout();
    return 1;
}

###########################
sub List_by_Condition {
###########################
    #
    # This drives the display (calling header, initializing routines)
    #
    # and generates a table showing records as specified.
    #
    my $Records    = shift;
    my %args       = filter_input( \@_, -args => 'condition' );
    my $condition  = $args{-condition};                           ## optional condition string (eg 'WHERE A=B')
    my $conditions = $args{-conditions};                          ## provided array instead of string ['A=B', 'C IN (1,2,3)']##
    my $error_flag = $args{-error_flag};                          ## ?
    my $order      = $args{-order};                               ## eg 'A DESC'
    my $initialize = $args{-initialize};                          ## initialize page only - don't retrieve data ...

    if ( $conditions && $conditions->[0] ) {
        $condition = 'WHERE ' . join ' AND ', @$conditions;
    }
    if ($order) { $condition .= " ORDER BY $order" }

    $Records->{Index} = param('Index') unless ( defined $Records->{Index} );
    $Records->{View} = 'Basic';    ## removing 'Advanced' view...

    my @marked  = param('Mark');
    my $refresh = param('Refresh');
    if ( @marked && $refresh ) {
        my $marked_list = Cast_List( -list => \@marked, -to => 'string', -autoquote => 1 );
        $condition .= " AND $Records->{ID} in ($marked_list)";
    }

    my $showfields = $Records->{showfields};
    my $view       = $Records->{View};

    $condition = $Records->Set_Conditions( $condition, $view );    ### check condition...

    while ( $condition =~ s/AND[\s]+[1][\s]+AND/AND/g ) { }

    if ( ( param('Edit_Records') =~ /\>/ ) && ( $Records->{FontSize} < $#FontClasses ) ) {
        $Records->{FontSize}++;
    }
    if ( ( param('Edit_Records') =~ /\</ ) && $Records->{FontSize} ) {
        $Records->{FontSize}--;
    }

    my $table = $Records->{Table} || '';
    my $dbc   = $Records->{dbc}   || 0;
    my @fields   = @{ $Records->{Fields} };
    my $title    = $Records->{Title} || '';
    my $subtitle = $Records->{subtitle} || '';

    ## Define the mode and the fields to be retrieved ##
    my $mode = param('Form Mode');
    $Records->{mode} = $mode;

    my @display_fields = param('Display');

    ## add fields to display and regenerate order based on original list ##
    my @added = param('Add_Display');
    my ( @hidden, @display );

    foreach my $field (@fields) {
        my $label = $Records->{Label}{$field} || $field;
        if ( grep /^($field|$label)$/, @display_fields ) { push @display, $field }
        elsif ( grep /^$label$/, @added ) { push @display, $field }
        else                              { push @hidden,  $field }
    }

    if ( !@display ) { @display = @hidden; @hidden = (); }

    $Records->Display_Fields( \@display );
    $Records->{hidden} = \@hidden;

    ######

    my $idfield = $Records->{ID};

    if ( $table =~ /(\w+)/ ) { $table = $1; }    ## extracting the first table name if more than one table name provided

####

    my $test = $Records->{Fields}[0];

    my $limit = $Records->{Limit};
    my $limit_cond;
    my $limit_index = $Records->{Index} || 0;
    if ($limit) {
        $limit_cond = "LIMIT " . $Records->{Limit};
        if   ($limit_index) { $limit_cond = "LIMIT $limit_index,$limit"; }
        else                { $limit_cond = "LIMIT $limit"; }
    }

    my $OrderBy = $Records->{OrderBy};
    my $order_cond;
    if ($OrderBy) { $order_cond = "ORDER BY " . $Records->{OrderBy} . " " . $Records->{OrderDir}; }

    #    my $homelink = $Records->{HomeLink} || '';
    my ($total_count) = $dbc->Table_find( $table, 'count(*)', "$condition" );

    print create_tree( -tree => { 'Condition' => $condition } );
    my %List;

    my $too_long = 0;    ## flag indicating list is too long to generate data
    if ($initialize) {
        %List = {};
        $dbc->message("Too many records to default to full record list ($total_count)");
        $too_long = 1;
    }
    else {
        %List = $dbc->Table_retrieve( $table, [ $idfield, @display ], "$condition $order_cond $limit_cond" );
        $dbc->message("Found $total_count records in $table");
    }

    if ($limit_cond) { print "($limit_cond)"; }

    my $DisplayBy = param('Display By') || 'List in Rows';

    #  (leave consistent ... in columns) - comment out below
    #
    #    if (defined $List{$idfield}[3]) {  ## if less than 4 records show in columns...
    #	     $DisplayBy = 'Row';
    #    }

    my %On    = {};    ########## Mark fields to display... ###########
    my %Size  = {};    ########## Pointer to real field names #########
    my %Field = {};    ########## Pointer to real field names #########
    my %Link  = {};

    foreach my $index ( 1 .. $Records->{displayed_fields} ) {
        my $key = $Records->{Display}[ $index - 1 ];
        if ( $key =~ /(.*) as (.*)/ ) {
            $key = $2;
        }
        $Size{$key}  = $Records->{Size}->{$key};
        $Field{$key} = $Records->{Fields}[ $index - 1 ];
        $Link{$key}  = $Records->{Links}[ $index - 1 ];
    }
    ###### Set quick flag for display status...
    foreach my $key (@display) {
        $On{$key} = 1;
    }

#################### Include area for custom specifications... ###################
    print alDente::Form::start_alDente_form( $dbc, 'EditForm' );

    my $set_attribute_button;
    require alDente::Attribute;
    $set_attribute_button = alDente::Attribute_Views::display_attribute_actions_button( -object => "$Records->{Table}", -dbc => $dbc );

    $Records->Add_Header( -records => $Records, -view => $view, -display => \@display, -limit => $limit, -add_attribute => $set_attribute_button );

    print hidden( -name => 'PageName',          -value => $Records->{Page},  -force => 1 )
        . hidden( -name => 'PreviousCondition', -value => $condition,        -force => 1 )
        . hidden( -name => 'TableName',         -value => $Records->{Table}, -force => 1 )
        . hidden( -name => 'Index',             -value => $Records->{Index}, -force => 1 );

    $dbc->Benchmark('wrapper_table');

    print "<Table><TR><TD>";
    my $Record_List = HTML_Table->new( -border => 1 );

    #    $Record_List->Set_Autosort(1);
    #    $Record_List->Set_Autosort_End_Skip(2);

    $Record_List->Set_Title($title);

    my @formatted_display = ();

    foreach my $display (@display) {
        my $thislabel = $Records->{Label}->{$display} || $display;

        my $checkbox = Show_Tool_Tip( checkbox( -name => 'Display', -value => $thislabel, -label => '', -checked => 1, -force => 1 ), 'De-select to hide this column' );
        push( @formatted_display, $checkbox . $thislabel );
    }

    #Get the list of matched IDs.
    my $index = 0;
    my $id_list;
    my $id_key = $Records->{ID};
    while ( defined $List{$id_key}[$index] ) {
        my $id = $List{$id_key}[$index];
        $id_list .= "$id,";
        $index++;
    }
    chop($id_list);

    my $sep;    #### link separator (depends on display type)

    my @search_fields = ();
    my @edit_fields   = ();
    if ( $DisplayBy =~ /Column/i ) {

        #	$Record_List->Set_Headers(['Select',@formatted_display]);
        $Record_List->Set_Column( [ checkbox( -name => 'Toggle', -value => '', -label => '', -onClick => "SetSelection(document.EditForm,'Mark','toggle','$id_list');" ), @formatted_display ] );
        $sep = " ";
    }
    else {
        $Record_List->Set_Headers( [ 'Select', @formatted_display ] );
        $sep = '<BR>';
        push @search_fields, '(Show)<BR>' . checkbox( -name => 'Toggle', -value => '', -label => '', -onClick => "SetSelection(document.EditForm,'Mark','toggle','$id_list');" );
        push @edit_fields,   '(Show)<BR>' . checkbox( -name => 'Toggle', -value => '', -label => '', -onClick => "SetSelection(document.EditForm,'Mark','toggle','$id_list');" );
    }
    $Record_List->Set_Class( $FontClasses[ $Records->{FontSize} ] );

    #    $Record_List->Set_Link('toggle','Toggle','','',"SetSelection(document.EditForm,'Mark','toggle','$id_list');");

    ####### Link to record selections at top of page... ###########
    # my $id_key = $Records->{ID};
    #    if ($DisplayBy=~/Column/i) {
    #	my $index = 0;
    #	while (defined $List{$id_key}[$index]) {
    #	    my $id = $List{$id_key}[$index];
    #	    $Record_List->Set_Link('checkbox_off',"Mark",$id,'');
    #	    $index++;
    #	}
    #    }

    my $num_fields = 0;

    my $testindex = 0;    # just to monitor error with cgi call below..

    #$    my %Size = $Records->{Size};
    $dbc->Benchmark('generate_display');

    foreach my $key (@display) {
        $testindex++;
        print "\n";

        #
        #  for some reason the cgi version below overcalls the script.  (worsening with each call)
        #	print hidden(-name=>'Record Display',-value=>$key);
        print "<INPUT type=\"hidden\" name=\"Record Display\" value=\"$key\">";
        ( my $field ) = grep /^(.*) as $key$/, @fields;
        if ( $field =~ /([\S_]*) as (.*)/i ) {
            $field = $1;
        }
        else { $field = $key; }

        $Field{$key} = $field;

        my $tip;
        my $editable;
        my $mandatory;

        if ( defined $Field_Info{$table} && defined $Field_Info{$table}{$field} ) {
            $tip       = $Field_Info{$table}{$field}{Description};
            $editable  = $Field_Info{$table}{$field}{Editable};
            $mandatory = ( $Field_Info{$table}{$field}{Extra} =~ /Mandatory/i );
        }
        if ( $editable =~ /admin/ ) {
            if   ( $dbc->admin_access() ) { $editable = 'yes' }
            else                          { $editable = 'no' }
        }

        my $default = param($key) || '';
        if ( param('Set Selected Values') && $error_flag ) {    ### leave fields if trying to append...
            $default ||= param("EDIT_FIELD_$key");
        }

        ( my $type, my $values ) = &prompt_cell( $dbc, $table, $field );
        my $param = Extract_Values( [ $Size{$key}, 10 ] );      ### default parameter to text field...

        if ( $type =~ /popup/ ) {
            if ($values) { $param = $values; }
        }

        if ( $type =~ /list/ ) {
            if ($values) { $param = $values; }
        }

        my $onchange;
        ( $default, $onchange ) = &Custom_Defaults( $Records->{Page}, $key, $default );

        if ( $editable =~ /no/i ) { print set_validator( -name => "EDIT_FIELD_$key", -readonly => 1, -prompt => "$key Field cannot be changed" ) }
        if ($mandatory) { print set_validator( -name => "EDIT_FIELD_$key", -mandatory => 1, -prompt => "$key Field is mandatory" ); }

        push @search_fields,
            SDB::DB_Form_Views::get_Element_Output(
            -dbc          => $dbc,
            -field        => $key,
            -table        => $table,
            -default_size => 8,
            -element_name => "SEARCH_FIELD_$key",
            -mode         => 'search',
            );

        push @edit_fields,
            SDB::DB_Form_Views::get_Element_Output(
            -dbc          => $dbc,
            -field        => $key,
            -table        => $table,
            -default_size => 8,
            -element_name => "EDIT_FIELD_$key",
            -mode         => 'edit',
            );

        # HTML_Table::_replace_links( -type => $type, -name => "EDIT FIELD $key", -value => $param, -label => $default, -tip => $tip );

        #	    $Record_List->Set_Link('checkbox_on','Display',$key,'');    ### show/hide flag
        #	    $Record_List->Set_Link($type,"EDIT FIELD $key",$param,$default);          ### set up prompt cell
    }

    $dbc->Benchmark('generate_table');
    print "</TR></Table>\n";

    my $search_id = $Records->{search_element_id};
    my $update_id = $Records->{update_element_id};
    
    if ( $DisplayBy =~ /Column/i ) { $Record_List->Set_Column( \@edit_fields ); }
    else {
        my ( $default_search, $default_edit ) = ( 'table-row', 'none' );
        if ( $Records->{mode} ne 'Search' ) { $default_search = 'table-row'; $default_edit = 'none'; }

        $Record_List->Set_Row( \@search_fields, 'mediumbluebw', -element_id => $search_id, -spec => "style='display:$default_search'");
        $Record_List->Set_Row( \@edit_fields, 'mediumbluebw',   -element_id => $update_id, -spec => "style='display:$default_edit'");
#        $Record_List->Set_sub_header( '<HR>', "bgcolor='#CCCCCC'" );
    }

    print "\n<HR>\n";

    my $linkcolour = $Settings{LINK_COLOUR};

    $index = 0;
    print hidden( -name => 'ID_Field', -value => $id_key );

    my @listed_ids;
    my $legend;    ### show legend if applicable...
    while ( defined $List{$id_key}[$index] ) {
        if ( $index >= $limit ) { $index++; next; }
        my $id = $List{$id_key}[$index];

        #	print hidden(-name=>'ID_List',-value=>$id);
        print "<INPUT type='hidden' name='ID_List' value='$id'>\n";
        push( @listed_ids, $id );
        my @element = checkbox( -name => 'Mark', -value => $id, -label => '', -checked => 0, -force => 1 );
        my $column = 0;
        foreach my $key (@display) {
            my $value = $List{$key}[$index];
            my $field = $Field{$key};
            my $link  = $Link{$key};
            if ( $value eq 'blank' ) { $value = ''; }
            if ( $On{$key} ) {
                my $showval = $value;
                ######## Custom hyper link from Received field to barcode reagent ######
                #		print "KEY: $key";
                if ( my $custom = Custom_Order( $dbc, $id, $Records, $Record_List, \%List, $key, $index, $column ) ) {
                    $showval = $custom;
                }
                elsif ( $field =~ /^Object_ID$/ ) {
                    my $class_id = $List{"FK_Object_Class__ID"}[$index];
                    my $object_class = &get_FK_info( $dbc, "FK_Object_Class__ID", $class_id );
                    $showval = get_FK_info( -dbc => $dbc, -field => "FK_${object_class}__ID", -id => $showval );
                }
                ######## End Custom hyper link from Received field to barcode reagent ######
                elsif ( $field =~ /^FK[a-zA-Z0-9]*_(.*)__(.*)/ ) {    ####### retrieve Foreign Name...

                    #
                    #  ok ?
                    #	if (main::get_FK_info($dbc,$field,$value)=~/:(.*)/) {$value = $1;}
                    if ($value) {
                        $showval = get_FK_info( -dbc => $dbc, -field => $field, -id => $value );
                    }
                    else { $showval = 'undef' }
                }

                ####### set cell colour to red somehow...

                if ( $showval =~ /^\s*$/ ) { $showval = ''; }
                if ( defined $value && ( my ( $ref_table, $ref_field ) = foreign_key_check( -dbc => $dbc, -table => $table, -field => $field ) ) ) {

                    push @element, alDente::Tools::quick_ref( $ref_table, $value, -dbc => $dbc, -brief => 1 );

                    #                    push( @element, &Link_To( -link_url => $homelink, -label => $showval, -param => "&Info=1&Table=$ref_table&Field=$ref_field&Like=$value", -colour => $Settings{LINK_COLOUR}, -window => ['newwin'] ) );

                    #"<A Href=$homelink&Info=1&Table=$ref_table&Field=$ref_field&Like=$value>$showval</A>");
                }
                elsif ( $field eq $idfield ) {

                    #		    push(@element,&Link_To(-link_url=>$homelink,-label=>$showval,-param=>"&Search=1&Table=$table&Search+List=$showval",-colour=>$Settings{LINK_COLOUR},-window=>['newwin']));
                    push( @element, &Link_To( -link_url => $dbc->homelink(), -label => $showval, -param => "&HomePage=$table&ID=$showval", -colour => $Settings{LINK_COLOUR}, -window => ['newwin'], -tooltip => 'Go to this record' ) );
                }

                #		elsif (length($showval)>$max_width) {$showval = substr($showval,0,$max_width)."....."; push(@record,$showval); }
                elsif ( !( $showval =~ /\S/ ) ) { $showval = "-"; push( @element, $showval ); }
                else                            { push( @element, $showval ); }
            }
            $column++;
        }

        if ( $DisplayBy =~ /Column/i ) {
            $Record_List->Set_Column( \@element );
        }
        else {
            my $highlight = $Records->{Highlight}->{$id};
            $Record_List->Set_Row( \@element );
            if ($highlight) {
                for my $col ( 1 .. int(@display) + 1 ) {
                    $Record_List->Set_Cell_Colour( $Record_List->{rows}, $col, 'red' );
                }
            }
        }
        $index++;
    }

    #    print "<BR><span class = vsmall>Conditi12on22: $condition</Span>";
    #    print $Record_List->Printout("$alDente::SDB_Defaults::URL_temp_dir/SrchResults.@{[timestamp()]}.html",$html_header);
    $Record_List->Printout();

    my $firstrecord = $limit_index + 1;
    my $lastrecord  = $limit_index + $limit;
    my $displayed   = "$firstrecord ... $lastrecord";
    if ( $index >= $limit ) {
        print "\n<B> Limited Records displayed to $limit - (Found $total_count)</B>";
        print "<h3>($displayed of $total_count records displayed)</h3>\n";
    }
    else { print "<h3>$index Items Found</h3>\n"; }

    my $current_index = $Records->{Index} + 1;
    my $start_index   = 1;
    my $buttons       = 0;
    my $button_width  = 10;

    if ( !$too_long ) {
        ## will not come here if list is too long to generate (list is empty) ##
        print "<Table><TR>";
        while ( $start_index < $total_count ) {
            my $end_index = $start_index + $limit - 1;
            if ( $end_index > $total_count ) { $end_index = $total_count; }
            if ( $current_index > $end_index ) {    ## previous pages...
                print '<TD>' . submit( -name => 'New DBView Index', -value => "$start_index - $end_index", -class => "Std" ) . '</TD>';
            }
            elsif ( $end_index > $current_index + $limit ) {    ## next pages...
                print '<TD>' . submit( -name => 'New DBView Index', -value => "$start_index - $end_index", -class => "Std" ) . '</TD>';
            }
            else { print "<TD>$start_index .. $end_index</TD>"; }

            $start_index += $limit;
            $buttons++;
            if ( int( $buttons % $button_width ) == 0 ) { print "</TR><TR>"; }
        }
        print "</TR></Table>";
        print "<P>";
    }

    #  print
    #	submit(-name=>'Previous Set of Records',-value=>"Previous $limit",-class=>"Std").
    #	    &hspace(5) .
    #		submit(-name=>'Next Set of Records',-value=>"Next $limit",-class=>"Std") .
    #		    &vspace(5);

    my $def_List = 'List in Rows';    ######## default mode of listing is by Rows
    if ( $DisplayBy =~ /Column/i ) { $def_List = 'List in Columns'; }

    print radio_group( -name => 'Display By', -values => [ 'List in Columns', 'List in Rows' ], -default => $def_List );

    print hspace(20) . "Display Limit: ", textfield( -name => 'List Limit', -size => 5, -default => $limit, -force => 1 ), " (set to 0 for no limit)" . &vspace(5), submit( -name => 'Refresh', -class => "Std" ) . &vspace();

    print "\n</FORM>\n";

    my $string_obj = new String();

    print $Records->{Page} . " Condition: <font size=-1>";
    print $string_obj->split_to_screen( -string => $condition, -width => 100, -separator => '<BR>' );
    print "</Font><HR>";

    my $list       = join ',', @listed_ids;
    my $field_list = join ',', @{ $Records->{Display} };
    print &Link_To( $dbc->config('homelink'), 'Simple View', "&Info=1&Table=$Records->{Table}&Field=$Records->{ID}&Like=$list&Fields=$field_list&Options=Hide" );
    print &hspace(5);
    print &Link_To( $dbc->config('homelink'), ' (with references)', "&Info=1&Table=$Records->{Table}&Field=$Records->{ID}&Like=$list&Fields=$field_list&Options=Hide,References" );

    $dbc->Benchmark('listed');
    return 1;
}

#######################
sub prompt_cell {
#######################
    #
    # Generate a cell to prompt for a value - returns textfield
    #                                       - returns popup for enumerated fields
    #                                       - returns list for sets
    #
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args    = filter_input( \@_, -args => 'table,field,default,value' );
    my $table   = $args{-table};
    my $field   = $args{-field};
    my $default = $args{-default};
    my $value   = $args{-value};

    my $width = Extract_Values( [ $value, 10 ] );

    my $max_options = $Settings{FOREIGN_KEY_POPUP_MAXLENGTH};                                                          ###### maximum size for popup window..
    my $table_data  = $dbc->query( -dbc => $dbc, -query => "show columns from $table like '$field'", -finish => 0 );
    my @fieldinfo   = $table_data->fetchrow_array();
    my $type        = $fieldinfo[1];
    my @values      = ();

    ##### start off with null value
    $dbc->Benchmark('"prompt.$field"');

    if ( $type =~ /enum\((.*)\)/i ) {
        my $list = $1;
        $list =~ s/\'//g;                                                                                              ##### remove quotes
        push( @values, ' ' );
        push( @values, split ',', $list );
        return ( 'popup', \@values );
    }    ##### add list of enumerated values
    elsif ( $type =~ /set\((.*)\)/i ) {
        my $list = $1;
        $list =~ s/\'//g;    ##### remove quotes
        push( @values, split ',', $list );

        #	return ('popup',\@values);
        return ( 'list', \@values );
    }    ##### add list of set possibilities
    elsif ( $field =~ /FK[a-zA-Z1-9]*_(.*)__(.*)/ ) {
        my $sub_table = $1;
        my $sub_field = "$1_$2";

        my ($num_options) = $dbc->Table_find( $sub_table, 'count(*)' );
        if ( ( $num_options > 0 ) && ( $num_options < $max_options ) ) {

            my @options = ( get_FK_info( -dbc => $dbc, -field => $field, -list => 1 ) );

            # add a blank if the first option is not
            if ( $options[0] ne '' ) {
                unshift( @options, '' );
            }
            return ( 'popup', \@options );
        }
        else { return ('text'); }
    }
    else {
        return ('text');
    }
    return;
}

######################
sub Custom_Order {
######################
    my $dbc         = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id          = shift;                                                                     ### value of id field for this record..
    my $Records     = shift;                                                                     #### Record object
    my $Record_List = shift;                                                                     #### current HTML_form
    my $list_index  = shift;                                                                     #### index to Information hash
    my $key         = shift;                                                                     #### field displayed
    my $index       = shift;                                                                     #### index of field
    my $column      = shift;                                                                     #### column displayed

    my %List = %{$list_index};

    my $link_table;
############## Custom Insertion for Orders tables... ###############################
    my $value = $List{$key}[$index];

    if ( ( $key =~ /^Orders_Received|Orders_Quantity$/ ) && ( defined $List{Orders_Received}[$index] ) && ( defined $List{Orders_Quantity}[$index] ) ) {

        my $colour1 = 'lightgreen';                                                              ## nothing received
        my $colour2 = 'yellow';                                                                  ## partially filled
        my $colour3 = 'grey';                                                                    ## filled
        my $colour4 = 'red';                                                                     ## over-filled

        my $colour;
        if    ( $List{Orders_Received}[$index] > $List{Orders_Quantity}[$index] )  { $colour = $colour4; }
        elsif ( $List{Orders_Received}[$index] == $List{Orders_Quantity}[$index] ) { $colour = $colour3; }
        elsif ( $List{Orders_Received}[$index] > 0 )                               { $colour = $colour2; }
        else                                                                       { $colour = $colour1; }

        my $legend
            = "<B>Legend for Stock Received:</B><Table cellspacing=0 cellpadding=5 border=1><TR>"
            . "<TD bgcolor=$colour1><B>Nothing Received</B></TD>"
            . "<TD bgcolor=$colour2><B>Partially Filled</B></TD>"
            . "<TD bgcolor=$colour3><B>Filled</B></TD>"
            . "<TD bgcolor=$colour4><B>Over Filled</B></TD>"
            . "</TD></TR></Table>"
            . hspace(20)
            . "(click on Received number to add stock)"
            . vspace(5);

        if ( $key =~ /^Orders_Received$/ ) {
            ######### Generate parameters for hyperlink #################

            my $account_id = $List{FK_Account__ID}[$index];
            ( my $account ) = &Table_find( $dbc, 'Account', 'Account_Name', "where Account_ID = $account_id" );

            if    ( $account =~ /Equip/i )   { $link_table = 'Equipment'; }
            elsif ( $account =~ /Reagent/i ) { $link_table = 'Reagent'; }
            elsif ( $account =~ /Box/i )     { $link_table = 'Box'; }
            elsif ( $account =~ /Service/i ) { $link_table = 'Service'; }
            else                             { $link_table = 'Misc_Item'; }

            my $lot = $List{Orders_Lot_Number}[$index];
            if ( $lot =~ /\S/ ) { $lot = "&Lot_Number=" . &Hlink_padded($lot); }    ### add Lot specification to hyperlink

            my $cat = $List{Orders_Catalog_Number}[$index];
            if ( $cat =~ /\S/ ) { $cat = "&Stock_Catalog_Number=" . &Hlink_padded($cat); }    ### add Lot specification to hyperlink

            #    else {RGTools::RGIO::Message("Cat: $cat");}

            my $item = $List{Orders_Item}[$index];
            if ( $item =~ /\S/ ) { $item = "&Stock_Name=" . &Hlink_padded($item); }           ### add Lot specification to hyperlink
            $item =~ s/\'//g;
            $item =~ s/\"//g;

            my $bottles;
            my $Number = $List{Orders_Quantity}[$index] - $List{Rcvd}[$index];
            if ( $Number =~ /\S/ ) { $bottles = "&Stock_Number_in_Batch=" . &Hlink_padded($Number); }    ### add Lot specification to hyperlink

            my $units = $List{Size_Units}[$index] || 'pcs';
            if ( $units =~ /\S/ ) { $units = "&Stock_Size_Units=" . &Hlink_padded($units); }             ### add Lot specification to hyperlink

            my $code = $List{FK_Expense__Code}[$index] || '';
            my $Stype;
            if ($code) {
                ($Stype) = &Table_find( $dbc, 'Account', 'Account_Name', "where Account_ID=$code" );
            }
            if ( $Stype =~ /^(.*)s$/i ) { $Stype = $1; }                                                 ### change from plural to singular...
            my $stock_type;
            if ( $Stype =~ /\S/ ) { $stock_type = "&Stock_Type=" . &Hlink_padded($Stype); }              ### add Lot specification to hyperl

            my $cost = $List{Unit_Cost}[$index];
            if ( $cost =~ /\S/ ) { $cost = "&Stock_Cost=" . &Hlink_padded($cost); }                      ##

            my $size = $List{Size}->{$key};
            if ( $size =~ /\S/ ) { $size = "&Stock_Size=" . &Hlink_padded($size); }                      ##

            ( my $rcvd ) = split ' ', &date_time();                                                      ### default received to current day
            $rcvd = "&Stock_Received=" . $rcvd;

            my $manuf = $List{Manufacturer}[$index];
            if ( $manuf =~ /\S/ ) {
                ( my $manuf_id ) = &Table_find( $dbc, 'Organization', 'Organization_ID', "where Organization_Name like '$manuf'" );
                $manuf = "&FK_Organization__ID=" . &Hlink_padded($manuf);
            }

            my $link = "&New+Stock=$link_table$lot$cat$item$size$units$cost$manuf$rcvd$bottles$stock_type$size";

            ############3

            my $link_value = &Link_To( $dbc->config('homelink'), "<B>$value</B>", "&FK_Orders__ID=$id$link", 'blue', ['newwin'] );
            $Record_List->Set_Cell_Colour( $index + 2, $column + 2, $colour );
            if ( $legend && ( $index == 0 ) ) { print $legend; }
            return $link_value;
        }
        elsif ( $key =~ /^Orders_Quantity$/ ) {

            $Record_List->Set_Cell_Colour( $index + 2, $column + 2, $colour );
            return "<B>$value</B>";
        }
    }
    elsif ( $key =~ /^Orders_Item$/ ) {

        #	my $link = &Link_To( $dbc->config('homelink'),"<B>$value</B>","&Table=Orders&Search=1&Search+List=$id",'blue',['newwin']);
        my $link = &Link_To( $dbc->config('homelink'), "<B>$value</B>", "&HomePage=Orders&ID=$id", 'blue', ['newwin'], -tooltip => 'Go to this record' );
        return $link;
    }
    else { return 0; }
}

#########################
sub Custom_Defaults {
#########################
    my $page    = shift;
    my $key     = shift;
    my $default = shift;

    if ( $page =~ /Orders/ ) {
        my $onchange = '';    ##### allow onClick or onChange command...
        if ( ( $page =~ /Received/ ) && ( $key =~ /Rcvd_Date/ ) ) {
            ($default) = split ' ', &date_time();
        }
        elsif ( ( $page =~ /New/ ) && ( $key =~ /Req_Date/ ) ) {
            ($default) = split ' ', &date_time();
        }
        elsif ( ( $page =~ /New/ ) && ( $key =~ /Units/ ) ) {
            $default = '';
        }
        elsif ( ( $key =~ /Unit_Cost/ ) || ( $key =~ /Orders_Quantity/ ) || ( $key =~ /Currency/ ) ) {
            #### add button to allow conversion of total to US dollars.. ###
            if ( $key =~ /Currency/ ) { $default = 'Can'; }
            $onchange = "CalculateTotal(document.EditForm,'EDIT_FIELD_Unit_Cost','EDIT_FIELD_Orders_Quantity','EDIT_FIELD_Orders_Cost',1,'EDIT_FIELD_Currency')";
        }
        return ( $default, $onchange );
    }
    else { return ($default); }
}

##############################
# private_methods            #
##############################
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

$Id: DB_Record.pm,v 1.38 2004/12/07 18:33:54 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
