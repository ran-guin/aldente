#!/usr/bin/perl
###################################################################################################################################
# RNA_Collection.pm
#
# Brief description
#
###################################################################################################################################
package alDente::RNA_Collection;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

RNA_Collection.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>!/usr/local/bin/perl56<BR>Brief description<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::Library);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::Form;
use alDente::SDB_Defaults;
use alDente::Barcoding;
use alDente::Library;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;

##############################
# global_vars                #
##############################
use vars qw($Current_Department $Connection);

##############################
# modular_vars               #
##############################
# Define security checks (alphabetical order please!)
my %Checks;

# Define items that can be viewed(alphabetical order please!)
my %Views;
$Views{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Views{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define items that can be searched (alphabetical order please!)
my %Searches;
$Searches{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Searches{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define items that can be created (alphabetical order please!)
my %Creates;
$Creates{'-'} = { 'Cap_Seq' => 'Lab', 'Mapping' => 'Lab', 'Lib_Construction' => 'Lab' };
$Creates{Library} = { 'Cap_Seq' => 'Admin', 'Mapping' => 'Admin', 'Lib_Construction' => 'Admin' };

# Define labels (alphabetical order please!)
my %Labels;
%Labels = ( '-' => '--Select--' );
$Labels{Library} = 'RNA Collection';

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

### Global variables

### Modular variables

###########################
# Constructor of the object'table'
###########################
sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;

    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $frozen  = $args{-frozen};
    my $encoded = $args{-encoded};

    my $self = $this->alDente::Library::new(
        -dbc     => $dbc,
        -tables  => [ 'Library', 'Original_Source', 'RNA_Collection' ],
        -frozen  => $frozen,
        -encoded => $encoded
    );

    bless $self, $class;

    if ($frozen) {
        $self->{dbc} = $dbc;
        return $self;
    }

    return $self;
}

##############################
# public_methods             #
##############################

#######################################
# Get RNA Library types
##############################
sub get_library_sub_types {
##############################
    my $self = shift;

    return "";    ### For now there is no library sub types for RNA Library
}

##########################
# Print the library info
##########################
sub library_info {
#####################

    my $self = shift;

    my $dbc     = $self->{dbc};
    my $lib     = shift;
    my $project = shift;

    #my $Ltype = shift;

    my $library_name;

    if ( $lib =~ /(.*):(.*)/ ) { $lib = $1; $library_name = $2; }

    print &Views::Heading("Library Info");

    my $condition = "where FK_Project__ID = Project_ID and Library.Library_Name = RNA_Collection.FK_Library__Name";
    print "<span size=small><B>";
    if ($lib) {
        $condition .= " and Library_Name like \"$lib\"";
        print "Library: $lib. ";
    }

    if ($project) {
        $condition .= " and Project_Name like \"$project\"";
        print "Project: $project. ";
    }

    print "</B></span>";

    if ( param('Order by Library') ) {
        $condition .= " Order by Library_Name";
    }
    else { $condition .= " Order by Project_Name,Library_Name"; }

    my @headers = ( 'Select', 'Project', 'Name', 'Full Name', 'Goals', 'Status', 'Progress' );
    my @field_list = ( 'Project_Name', 'Library_Name', 'Library_FullName', 'Library_Goals as Goals', 'Library_Status as Status' );
    if ( param('Include Description') ) {
        push( @field_list, "Library_Description as Description" );
        push( @headers,    'Description' );
    }
    my %Lib_info = Table_retrieve( $dbc, 'Library,Project,RNA_Collection', \@field_list, $condition );

    my $Table = HTML_Table->new();
    $Table->Set_Class('small');
    $Table->Set_Title("List of $project Libraries ");
    $Table->Set_Headers( \@headers );

    print alDente::Form::start_alDente_form( $dbc, 'LibInfo', undef );

    my $index = 0;
    while ( defined $Lib_info{Library_Name}[$index] ) {
        my $proj   = $Lib_info{'Project_Name'}[$index];
        my $name   = $Lib_info{'Library_Name'}[$index];
        my $fname  = $Lib_info{'Library_FullName'}[$index];
        my $desc   = $Lib_info{'Description'}[$index];
        my $goals  = $Lib_info{'Goals'}[$index];
        my $status = $Lib_info{'Status'}[$index];

        my $Aproj = $proj;
        $Aproj =~ s/\s/+/g;
        my @fields;
        push( @fields, checkbox( -name => 'Library', -label => '', -value => $name ) );
        push( @fields, &Link_To( $dbc->config('homelink'), $proj, "&Info=1&Table=Project&Field=Project_Name&Like=$Aproj", 'blue', ['newwin'] ) );
        my $library_link = &Link_To( $dbc->config('homelink'), $name, "&Search=1&TableName=Library&Search+List=$name", 'blue', ['newwin'] );
        push( @fields, $library_link );
        push( @fields, $fname );
        push( @fields, $goals );
        push( @fields, $status );

        my ($now) = split ' ', &RGTools::RGIO::date_time();
        my $linkProgress = &Link_To( $dbc->config('homelink'), 'View_to-date', "&Info=1&Table=LibraryProgress&Field=FK_Library__Name&Like=$name", 'blue', ['newwin'] ) . "<BR>"
            . &Link_To( $dbc->config('homelink'), 'Add_Note', "&New+Entry=New+LibraryProgress&FK_Library__Name=$name&LibraryProgress_Date=$now", 'red', ['newwin'] );
        push( @fields, $linkProgress );

        $Table->Set_Row( \@fields );

        $index++;
    }
    $Table->Printout("$URL_temp_dir/Libraries.html");
    $Table->Printout();

    print "</FORM>";

    return 1;
}

###################
sub library_main {
###################
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $self->{dbc};
    my $get_layers  = $args{-get_layers};
    my $form_name   = $args{-form_name};
    my $return_html = $args{-return_html};

    # Set security checks
    $dbc->Security->security_checks( \%Checks );

    ##################################################################
    ### Customized for Sequencing Libraries:
    ##################################################################
    my $sub_types = $self->get_library_sub_types();

    ## Continue to main library page ##
    my $add_link = [
        &Link_To( $dbc->config('homelink'), "Search Vector/String for Restriction Site / Primer", "&Search+Vector=1", $Settings{LINK_COLOUR}, ['newwin1'] ),
        &Link_To( $dbc->config('homelink'), "Submit Work Request to Other Group     ", "&Prompt for Submit Work Request=1", $Settings{LINK_COLOUR}, ['newwin1'] ),
    ];

    my @add_objects  = ('Primer');
    my @view_objects = ('Library');
    return $self->SUPER::library_main(
        -add_links    => $add_link,
        -sub_types    => $sub_types,
        -objects      => \@add_objects,
        -view_objects => \@view_objects,
        -labels       => { 'Library' => 'RNA Collection', },
        -get_layers   => $get_layers,
        -form_name    => $form_name,
        -return_html  => $return_html,
    );
}

################
sub old_library_main {
################
    my $self = shift;

    my $merge_form = shift;              ###If specify, that means this routine will return the content and merged into another form.
    my $dbc        = $self->{dbc};
    my $homelink   = $dbc->homelink();

    my $content;
    my $form_name;

    # Set security checks
    $dbc->Security->security_checks( \%Checks );

    if ($merge_form) {
        $form_name = $merge_form;
    }
    else {
        $form_name = 'Library_Main';
        $content = alDente::Form::start_alDente_form( $dbc, $form_name, undef );
        $content .= Views::Heading( "RNA Collection Home Page" . hspace(5) . "<span class=small>" . checkbox( -name => 'NewWin', -label => 'Display results in new window', -checked => 0 ) . "</span>" );
    }

    #    get_enum_list
    my @projects = $dbc->Table_find( 'Library,Project', 'Project_Name', "where Project_ID=FK_Project__ID Order by Project_Name", 'Distinct' );
    my @L_status_types = &SDB::DBIO::get_enum_list( $dbc, 'Library', 'Library_Status' );

    ##################################################################
    ###Libraries Section
    ##################################################################
    my $libraries = $self->_init_table('RNA_Collection');
    my @libraries = @{ $dbc->Security->get_accessible_items( -table => 'Library', -extra_condition => "LENGTH(Library_Name)=6" ) };
    my $tip       = "Generates more concise info when viewing RNA extraction";

    $libraries->Set_Row(
        [   'Criteria:',
            &Views::Table_Print(
                content => [
                    [   "RNA Collection Name:",
                        textfield( -name => 'List search2', -size => 10, -onChange => $MenuSearch )
                            . hidden( -name => 'ForceSearch2', -value => 'Search' )
                            . Show_Tool_Tip( popup_menu( -name => 'Library_Name', -values => [ "", @libraries ], -default => "" ), $tip )
                    ],
                    [   "By Project:",
                        Show_Tool_Tip(
                            RGTools::Web_Form::Popup_Menu( name => 'Project Name', values => [ "", @projects ], default => "", onChange => "SetSelection(document.$form_name,'Library_Name',''); SetSelection(document.$form_name,'Library Type','');" ),
                            $tip )
                            . hidden( -name => 'Table', -value => 'Library', -force => 1 )
                    ]
                ],
                class    => 'small',
                bgcolour => '#d8d8d8',
                print    => 0
            )
        ]
    );

    $libraries->Set_Row(
        [   'View:',
            checkbox( -name => 'Verbose', -label => 'Verbose (for RNA Collection)', -checked => 0, -force => 1 ) 
                . hspace(5)
                . RGTools::Web_Form::Popup_Menu(
                name    => 'Library_View',
                values  => $dbc->Security->generate_popup_choices( \%Views ),
                labels  => \%Labels,
                default => '-',
                force   => 1,
                onClick => "goTo('$homelink',buildAddOns(document.$form_name,'Library_View',this.value),getElementValue(document.$form_name,'NewWin'))"
                )
        ]
    );

    $libraries->Set_Row(
        [   'Search/Edit:',
            checkbox( -name => 'Library_Multi-Record', -label => 'Multi-Record' ) 
                . hspace(5)
                . RGTools::Web_Form::Popup_Menu(
                name    => 'Library_Search_Edit',
                values  => $dbc->Security->generate_popup_choices( \%Searches ),
                labels  => \%Labels,
                default => '-',
                force   => 1,
                onClick => "goTo('$homelink',buildAddOns(document.$form_name,'Library_Search_Edit',this.value),getElementValue(document.$form_name,'NewWin'))"
                )
        ]
    );

    my $access = $dbc->get_local('Access')->{$Current_Department};

    #    if ($dbc->Security->department_access()=~/Admin/i) {
    if ( grep /^(admin|bioinf)/i, @$access ) {

        my $create_new_lib = submit( -name => "Create New Library", -value => "Create New RNA Collection", -class => "Std" );
        my $new_lib_with_orig = alDente::Tools->search_list( -dbc => $dbc, -form => "document.$form_name", -name => 'FK_Original_Source__ID', -default => '', -search => 1, -filter => 1 );

        my $comment = "<B>If this library originates from a source currently defined in the LIMS, please select that source below.</B>";

        $libraries->Set_Row( [ '', hr ] );
        $libraries->Set_Row( [ "", $create_new_lib ] );
        $libraries->Set_Row( [ "", $comment ] );
        $libraries->Set_Row( [ '', "Original Source: " . $new_lib_with_orig ] );
    }

    $libraries->Set_VAlignment('Top');

    ##################################################################
    ###Projects Section
    ##################################################################
    my $projects = $self->_init_table('Projects, Collaborations,Contacts');

    my @choices = ('-');
    my %labels = ( '-' => '--Select--' );

    push( @choices, 'Project' );
    push( @choices, 'Collaboration' );
    push( @choices, 'Contact' );

    $labels{Project}       = 'Projects';
    $labels{Collaboration} = 'Collaborations';
    $labels{Contact}       = 'Contacts';

    @choices = sort(@choices);
    $projects->Set_Row( [ &Link_To( $dbc->config('homelink'), "<B>Projects</B>", "&HomePage=Project" ) ] );
    $projects->Set_Row(
        [   'View:',
            RGTools::Web_Form::Popup_Menu(
                name    => 'Project_View',
                values  => \@choices,
                labels  => \%labels,
                default => '-',
                force   => 1,
                onClick => "goTo('$homelink',buildAddOns(document.$form_name,'Project_View',this.value),getElementValue(document.$form_name,'NewWin'))"
            )
        ]
    );

    $labels{Project}       = 'Project';
    $labels{Collaboration} = 'Collaboration';
    $labels{Contact}       = 'Contact';

    $projects->Set_Row(
        [   'Create New:',
            RGTools::Web_Form::Popup_Menu(
                name    => 'Project_Create',
                values  => \@choices,
                labels  => \%labels,
                default => '-',
                force   => 1,
                onClick => "goTo('$homelink',buildAddOns(document.$form_name,'Project_Create',this.value),getElementValue(document.$form_name,'NewWin'))"
            )
        ]
    );

    $labels{Project}       = 'Projects';
    $labels{Collaboration} = 'Collaborations';
    $labels{Contact}       = 'Contacts';

    $projects->Set_Row(
        [   'Search/Edit:',
            checkbox( -name => 'Project_Multi-Record', -label => 'Multi-Record' ) 
                . hspace(5)
                . RGTools::Web_Form::Popup_Menu(
                name    => 'Project_Search_Edit',
                values  => \@choices,
                labels  => \%labels,
                default => '-',
                force   => 1,
                onClick => "goTo('$homelink',buildAddOns(document.$form_name,'Project_Search_Edit',this.value),getElementValue(document.$form_name,'NewWin'))"
                )
        ]
    );

    $projects->Set_VAlignment('Top');

    my $inner_table;
    $inner_table = &Views::Table_Print( content => [ [ $projects->Printout(0) ] ], print => 0 );

    $content .= &Views::Table_Print( content => [ [ $libraries->Printout(0), $inner_table ] ], print => 0 );

    #$content .= &Views::Table_Print(content=>[[$lib_create_form->Printout(0)]],print=>0);

    # Sequencing library submission
    if ( $Current_Department !~ /Cap_Seq/i ) {

        # Get the list of sequencing libraries

        my $lib_sub = $self->_init_table('Sequencing Library Submissions');

        #	my @seq_lib_formats = ('-','Ligation','Microtiter','Xformed_Cells');
        #	my %labels = ('-'=>'--Select--');
        #	$labels{Microtiter} = 'Microtiter Plates';
        #	$labels{Xformed_Cells} = 'Transformed Cells';

        $lib_sub->Set_Row( [ submit( -name => 'Prompt for Submit Library',      -label => 'Submit New Library',             -class => "Std" ) ] );
        $lib_sub->Set_Row( [ submit( -name => 'Prompt for Resubmit Library',    -label => 'Resubmit Library',               -class => "Std" ) ] );
        $lib_sub->Set_Row( [ submit( -name => 'Prompt for Submit Work Request', -label => 'Submit Sequencing Work Request', -class => "Std" ) ] );

        $content .= &Views::Table_Print( content => [ [ $lib_sub->Printout(0) ] ], print => 0 );
    }

    if ($merge_form) {
        return $content;
    }
    else {
        $content .= "</form>";
        print $content;
    }
}

##############################
# public_functions           #
##############################
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

$Id: RNA_Collection.pm,v 1.4 2004/11/06 01:09:24 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
