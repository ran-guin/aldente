#############################################################################
#
# Button_Options.pm
#
# This module handles specific Button options
#
#########################sw#######################################################
# $Id: Button_Options.pm,v 1.428 2004/12/15 20:19:30 echuah Exp $
################################################################################
package alDente::Button_Options;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK> 

Button_Options.pm - This module handles specific Button options

=head1 SYNOPSIS <UPLINK>

<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles specific Button options<BR>

=cut

##############################
# superclasses               #
##############################

#@ISA = qw(Exporter);
#@ISA = qw(alDente::Prep);

##############################
# system_variables           #
##############################
#require Exporter;
#@EXPORT = qw(
#	     Check_Button_Options
#	     );

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use Benchmark;

#use Storable qw(freeze thaw);
use Data::Dumper;
######## Standard Database Modules #######################
use strict;

my $q = new CGI;
##############################]
# custom_modules_ref         #
##############################

use SDB::DB_Form_Viewer;    #### General Form handluse SDB::DBIO;use alDente::Validation;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form;
use SDB::HTML;
use SDB::DIOU;

use RGTools::RGIO;
use RGTools::Views;         #### HTML_Table generator, Colour Map generator routines
use RGTools::Conversion;

#### Sequencing Database Handling Routines

use Sequencing::SDB_Status;    ### Status page generating routines ('Last 24 Hours')
use Sequencing::Seq_Data;      ### Run Data analysis routines (eg fasta.pl)
use alDente::Info;             ### General information displaying routines
use alDente::Form;             ### Set_Parameters
use alDente::Library;
use alDente::Solution;         ### General routines specific to solution/reagent handling
use alDente::Original_Source;
use alDente::ReArray;
use alDente::Container;
use alDente::Well;
use alDente::Library_Plate;
### Chemistry calculator
use alDente::Chemistry;
use Sequencing::Sequence;      ### routines used in generating Sequence Run Sample Sheets
use alDente::Tube qw(home_tube);
use alDente::Equipment;        ### Equipment handling routines
use alDente::Misc_Item;        ### Handling of Box, Misc_Item entries
use Sequencing::Sequencing_Library;
use Sequencing::Sequencing_Data;
use alDente::Stock;               ### Stock editing routines
use alDente::Prep;                ### Plate Preparation Tracking procedures
use alDente::Process;             ### Preparation Step Processing (called from Prep.pm)
use alDente::Orders;              ### Orders database handling (for Carrie, Steve, Letty)
use alDente::Diagnostics;         ### Diagnostics calculations (correlating Run Quality)
use alDente::Notification;        ### Automatic Notification routines
use alDente::Comments;
use alDente::Help;
use alDente::HelpButtons;
use alDente::ChromatogramHTML;    ### Cleaned up version of Olivers trace viewer
use alDente::SDB_Defaults qw(%Search_Item $mirror_dir $protocol $fasta_dir &get_cascade_tables);
use Sequencing::Sample_Sheet;
use alDente::Admin;
use alDente::Rack;
use alDente::Scanner;
use alDente::Barcoding;
# use alDente::Department;
use alDente::Vector;
use alDente::Container_Set;
use alDente::Special_Branches;
use alDente::Box;
use alDente::Well;
use alDente::Run_Statistics;
use alDente::Messaging;

#use alDente::;
use alDente::Sample;
use alDente::RNA_DNA_Collection;
use alDente::How_To;
use alDente::How_To_Topic;
use alDente::Pipeline;
use Sequencing::Read;
use alDente::QA;
use alDente::Document;
use alDente::UseCase;
use alDente::LibraryApplication;
use Sequencing::Lab_View;    ### Sequencing Lab viewing module (Preparation status)
use Sequencing::ReArray;

use Lib_Construction::GE_View;    ### Lib_Construction Lab viewing module (Preparation status)
use Lib_Construction::Sample_Receiving;

############################## # global_vars # ##############################
#use Lib_Construction::TTR;
#no strict "refs";
use vars qw($barcode $solution_id $equipment $equipment_id $plate_id $bin_home $current_plates $plate_set $sol_mix);
use vars qw(@libraries);
use vars qw($sets);
use vars qw($Current_Department $dbase $testing $dbh $q $login_name $login_pass $trace_level $login_file $Sess);
use vars qw($track_sessions $express $scanner_mode $Security);
use vars qw(%Settings %Std_Parameters);
use vars qw($fasta_dir);
use vars qw(%Input $Connection $Multi_Form);
use vars qw(%Aliases);

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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

###############################
sub Check_Button_Options {
###############################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $user_id     = $dbc->get_local('user_id');

    $dbc->Benchmark('CBO_start');
    ### Determine type of objects to use based on current department
    my $Lib_Type = 'Library';
    if ( $Current_Department =~ /(Cap_Seq|Mapping)/i ) {
        $Lib_Type = 'Sequencing_Library';
    }
    elsif ( $Current_Department =~ /Lib_Construction/i ) {
        $Lib_Type = 'RNA_DNA_Collection';
    }

    ### set up Objects if they exist.. ##

    my $Plate;
    my $Set;

    if ( $plate_set || $plate_id || $current_plates ) {

        ## Pre-Define Plate Objects ##
        if ($plate_id) { $Plate = alDente::Container->new( -dbc => $dbc, -id => $plate_id ) }
        elsif ( $current_plates =~ /(\d+)/ ) { $Plate = alDente::Container->new( -dbc => $dbc, -id => $1 ) }

        ## Pre-Define Set Objects ##
        if ($plate_set) { $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set ) }
        elsif ( $current_plates =~ /(\d+)/ ) { $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates ) }
    }

    ## first priority is standard escape routes to common forms ..##
    if ( param('quick_view') ) {
        my $id    = param('quick_view');
        my $well  = param('Well');
        my $fback = try_system_command("/home/rguin/public/quick_view -R $id -W $well");
    }
    elsif ( param('Table Info') ) {
        my $table = param('Table Info');
        &table_info($table);
    }
    elsif ( param('Use') ) {
        use_object( $barcode, $user );
    }
    elsif ( param('New Entry') ) {
        my $table = param('New Entry');
        if ( $table =~ /^New (.*)/i ) { $table = $1; }
        elsif ( param('New Entry Table') ) { $table = param('New Entry Table') }

        my $configs;
        if ( param('DB_Form_Configs') ) { $configs = Safe_Thaw( -name => 'DB_Form_Configs', -thaw => 1, -encoded => 1 ) }
        if ($table) {
            &SDB::DB_Form_Viewer::add_record( $dbc, $table, undef, $configs, -groups => $dbc->get_local('group_list') );
            return 1;
        }
        else { Message("No table specified"); }
    }
    elsif ( param('Standard Page') ) {

        my $page = param('Standard Page');
        return &alDente::Info::GoHome( $dbc, 'Standard Page', $page, -lib_type => $Lib_Type );
    }
    elsif ( param('Chemistry_Event') ) {
        ## Intercept Chemistry Events ##
        my $event = param('Chemistry_Event');
        return alDente::Chemistry::request_broker( -dbc => $dbc, -event => $event );
    }
    elsif ( param('Barcode_Event') ) {
        
        ## Intercept Barcode Events ##
        my $event = param('Barcode_Event');
        return alDente::Barcoding::request_broker( $dbc, $event );
    }
    elsif ( param('List Entries') ) {

        my $table = param('Table') || param('TableName');
        my $condition = param('Condition');
        if ($table) {
            Message("Listing $table entries");
            print SDB::DB_Form_Viewer::view_records( $dbc, $table, undef, undef, $condition );
        }

        #    else {&check_last_page();}
    }
    elsif ( param('List Libraries') ) {

        if ( param('Verbose') ) {
            if ( get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) ) {
                my $lib = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
                $lib =~ /^(.{5,6})/;
                $lib = $1;
                print SDB::DB_Form_Viewer::view_records( $dbc, 'Library', 'Library_Name', $lib );
            }
            elsif ( get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc ) ) {
                my $proj_name = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc );
                my $projects = join ',', $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name like '$proj_name'" );
                print SDB::DB_Form_Viewer::view_records( $dbc, 'Library', 'FK_Project__ID', $projects );
            }
            elsif ( get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc ) ) {
                my $type = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc );
                print SDB::DB_Form_Viewer::view_records( $dbc, 'Library', 'Library_Type', $type );
            }
            else {
                print SDB::DB_Form_Viewer::view_records( $dbc, 'Library' );
            }
        }
        else {
            my $lib;
            if ( $Lib_Type =~ /RNA\/DNA/ ) {
                $lib = alDente::RNA_DNA_Collection->new( -dbc => $dbc );
            }
            else {
                $lib = Sequencing::Sequencing_Library->new( -dbc => $dbc );
            }
            my $lib_name     = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) || param('Library_Name');
            my $project_name = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc );
            my $lib_type     = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc );

            $lib->library_info( $lib_name, $project_name, $lib_type );
        }
    }
    elsif ( param('List Projects') ) {

        print SDB::DB_Form_Viewer::view_records( $dbc, 'Project' );
    }
    elsif ( param('List Vectors') ) {

        my $all = param('Include All Vectors');                                                                                                                                                             ### allow viewing of unused vectors
        my $active_vectors = join ',', $dbc->Table_find( 'Vector,LibraryVector,Vector_Type', 'Vector_Type_Name', "WHERE LibraryVector.FK_Vector__ID=Vector_ID and FK_Vector_Type__ID = Vector_Type_ID" );
        print SDB::DB_Form_Viewer::view_records( $dbc, 'Vector_Type', 'Vector_Type_Name', $active_vectors );
    }
    elsif ( param('List Antibiotics') ) {

        print SDB::DB_Form_Viewer::view_records( $dbc, 'Antibiotic' );
    }
    elsif ( param('View LibraryApplication') ) {

        my $object_class = param('Object_Class');
        my $libs;
        if ( get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) ) {
            $libs = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
        }
        elsif ( my $type = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc ) ) {
            $libs = join ',', $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Type like '$type'" );
        }
        elsif ( my $proj = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc ) ) {
            $libs = join ',', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$proj'" );
        }
        else { $libs = join ',', @libraries; }
        my $library_application = alDente::LibraryApplication->new( -dbc => $dbc );
        $library_application->view_application( -library => $libs, -object_class => $object_class );
    }
    elsif ( param('Library/Antibiotics') ) {

        my $libs;
        if ( get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) ) {
            $libs = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
        }
        elsif ( my $type = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc ) ) {
            $libs = join '\',\'', $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Type like '$type'" );
        }
        elsif ( my $proj = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc ) ) {
            $libs = join '\',\'', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$proj'" );
        }
        else { $libs = join '\',\'', @libraries; }

        unless ( param('Antibiotics Only') ) {
            Message("These are the specified Primers ALLOWED for the given Libraries");

            #    print &SDB::DB_Form_Viewer::view_records($dbc,'LibraryPrimer','FK_Library__Name',$lib);
            &SDB::DB_Form_Viewer::mark_records( $dbc, 'LibraryPrimer', [ 'FK_Library__Name', 'FK_Primer__Name', 'Direction' ], "WHERE FK_Library__Name in ('$libs')", -run_modes => ['Delete Record'] );
        }
        my %ABs = &Table_retrieve_display(
            $dbc,
            'Vector_Based_Library,Vector left join Library_Source on Vector_Based_Library.FK_Library__Name=Library_Source.FK_Library__Name left join Transposon_Pool on Library_Source.FK_Source__ID=Transposon_Pool.FK_Source__ID left join Transposon on FK_Transposon__ID=Transposon_ID',
            [ 'Vector_Based_Library.FK_Library__Name as Library', 'Vector.Antibiotic_Marker as Antibiotic', 'Transposon.Antibiotic_Marker as Transposon_Antibiotic' ],
            "WHERE FK_Vector__ID=Vector_ID AND Vector_Based_Library.FK_Library__Name in ('$libs')"
        );
    }
    elsif ( param('List Chemistry Options') ) {

        Message("Phased out - converted to branch views");
        Call_Stack();
    }
    elsif ( param('Search Vector') ) {
        ### Search Vector for Restriction Sites/Primers...

        print &Views::Heading("Search Vector / String for Restriction Sites and/or Primers");
        my $Vector = alDente::Vector->new( -dbc => $dbc );
        $Vector->initiate_Search( -text => 1 );
    }
    elsif ( param('Search Vector for String') ) {

        my $sequence = param('String');
        my $vector   = param('Vector');
        my $Vector   = alDente::Vector->new( name => $vector, sequence => $sequence, -dbc => $dbc );
        $Vector->load_Sequence();    ## in case it is undefined...
        my $search = join ',', param('Search For');
        my $indexed = param('Include Line Indexes');

        # $Vector->search_Vector(search=>$search,print=>1,indexed=>$indexed);
        $Vector->initiate_Search( -text => 0 );    ##
        my %layers;
        my @order;
        my $default;
        if ( $search =~ /primers/i ) {
            $layers{Primers} = $Vector->search_Vector( search => 'Primers', print => 1, indexed => $indexed, -quiet => 0 );
            push @order, 'Primers';
            $default = 'Primers';
        }
        if ( $search =~ /restriction/i ) {
            $layers{'Restriction Sites'} = $Vector->search_Vector( search => 'Restriction Sites', print => 1, indexed => $indexed, -quiet => 0 );
            push @order, 'Restriction Sites';
            $default = 'Restriction Sites';
        }
        if ( $search =~ /primers/i && $search =~ /restriction/i ) {
            $layers{Combined} = $Vector->search_Vector( search => 'Primers,Restriction Sites', print => 1, indexed => $indexed, -quiet => 1 );
            push @order, 'Combined';
            $default = 'Combined';
        }

        print define_Layers( -layers => \%layers, -order => \@order, -default => $default );

        #	        'Combined' => $Vector->search_Vector(search=>['Primers','Restriction Sites',print=>1,indexed=>$indexed),
        return 1;
    }
    elsif ( param('View Primers for Vectors') ) {

        my $libs;
        if ( get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) ) {
            $libs = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
        }
        elsif ( my $type = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc ) ) {
            $libs = join '\',\'', $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Type like '$type'" );
        }
        elsif ( my $proj = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc ) ) {
            $libs = join '\',\'', $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$proj'" );
        }
        else { $libs = join '\',\'', @libraries; }

        Message("Specified Vector Primer Combinations");

        my $vectors = join ',', $dbc->Table_find( 'LibraryVector,Vector', 'FK_Vector_Type__ID', "WHERE FK_Vector__ID=Vector_ID AND FK_Library__Name in ('$libs')" );

        &SDB::DB_Form_Viewer::edit_records( $dbc, 'Vector_TypePrimer', 'FK_Vector_Type__ID', $vectors );
    }
    elsif ( param('LibraryApplication') ) {

        my $object_class        = param('Object_Class');
        my $library             = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) || param('FK_Library__Name');
        my $library_application = alDente::LibraryApplication->new( -dbc => $dbc );

        # $library_application->home_page(-library=>'SKL01', -object_class=>'Vector_Type', -valid_object=>'Vector_Type');
        #	   $Sess->homepage("LibraryApplication=$library");
        $library_application->home_page( -library => $library, -object_class => $object_class, -valid_object => 'Vector', -filter_table => "Vector$object_class" );
    }
    elsif ( param('List Contacts') ) {
        my $contact = $q->param('FK_Contact__ID') || get_Table_Param(-field=>'FK_Contact__ID', -convert_fk => 1, -dbc=>$dbc);
        if ($contact) {
            my $Contact = new alDente::Contact( -dbc => $dbc, -id => $contact );
            print $Contact->std_home_page();
        }
        elsif ( param('Organization Name') ) {
            my $org_name = param('Organization Name');
            my $orgs = join ',', $dbc->Table_find( 'Organization', 'Organization_ID', "WHERE Organization_Name = '$org_name'" );
            print &SDB::DB_Form_Viewer::view_records( $dbc, 'Contact', 'FK_Organization__ID', $orgs );
        }
        elsif ( param('Organization Type') ) {
            my $org_type = param('Organization Type');
            my $orgs = join ',', $dbc->Table_find( 'Organization', 'Organization_ID', "WHERE Organization_Type = '$org_type'" );
            print &SDB::DB_Form_Viewer::view_records( $dbc, 'Contact', 'FK_Organization__ID', $orgs );
        }
        elsif ( param('Contact Type') ) {
            my $type = param('Contact Type');
            print &SDB::DB_Form_Viewer::view_records( $dbc, 'Contact', 'Contact_Type', $type );
        }
        else {
            print &SDB::DB_Form_Viewer::view_records( $dbc, 'Contact' );
        }

        #    else {print &SDB::DB_Form_Viewer::view_records($dbc,'Contact');}

        #	&contact_info(undef,param('Organization Name'));
    }
    elsif ( param('List Organizations') ) {

        if    ( param('Organization Name') ) { print &SDB::DB_Form_Viewer::view_records( $dbc, 'Organization', 'Organization_Name', param('Organization Name') ); }
        elsif ( param('Organization Type') ) { print &SDB::DB_Form_Viewer::view_records( $dbc, 'Organization', 'Organization_Type', param('Organization Type') ); }
        else                                 { print &SDB::DB_Form_Viewer::view_records( $dbc, 'Organization' ); }

        #    &organization_info(undef,$org);
    }
    elsif ( param('List Funding Grants') ) {

        if ( param('Funding Name') ) { print &SDB::DB_Form_Viewer::view_records( $dbc, 'Funding', 'Funding_Name', param('Funding Name') ); }

        #elsif (param('Organization Type')) {print &SDB::DB_Form_Viewer::view_records($dbc,'Organization','Organization_Type',param('Organization Type'));}
        else { print &SDB::DB_Form_Viewer::view_records( $dbc, 'Funding' ); }

        #    &organization_info(undef,$org);
    }
    elsif ( param('Respond') ) {

        my $suggestion = param('Respond');
        if ( $suggestion =~ /Respond to (\d+)/ ) {
            my $id = $1;
            Message("Respond to $id");
            &Table_search_edit( $dbc, 'Suggestion', $id );
        }
    }
    elsif ( param('New How To Guide') ) {

        my %grey = ();
        my %list = ();

        # Create How To form
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'How_To_Object', -target => 'Database' );
        $form->configure( -list => \%list, -grey => \%grey );
        $form->generate( -title => "New How To Guide" );

    }
    elsif ( param('View How To Guide') ) {

        my $how_to = param('How_To');

        # find the ID from the name
        my ($how_to_id) = $dbc->Table_find( 'How_To_Object', 'How_To_Object_ID', "WHERE How_To_Object_Name = '$how_to'" );

        #  Go to the How To home page
        my $how_to_obj = alDente::How_To->new( -dbc => $dbc, -id => $how_to_id );
        $how_to_obj->home_page();

    }
    elsif ( param('Delete How To Guide') ) {

        # <CONSTRUCTION> need to add delete functionality

    }
    elsif ( param('Add How To Topic') ) {

        my $how_to_obj_id = param('How To Object ID');
        my %grey          = ();
        my %list          = ();
        my %preset        = ();
        $grey{FK_How_To_Object__ID}   = $how_to_obj_id;
        $preset{FK_How_To_Object__ID} = $how_to_obj_id;
        $grey{Topic_Number}           = '';

        #print $original_source_id;
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'How_To_Topic', -target => 'Database' );
        $form->configure( -list => \%list, -grey => \%grey, -preset => \%preset );
        $form->generate( -title => "New Topic" );

    }
    elsif ( param('View How To Topic') ) {

        my $topic_id = param('Edit Topic');
        my $topic_obj = alDente::How_To_Topic->new( -dbc => $dbc, -id => $topic_id );
        $topic_obj->homepage();

    }
    elsif ( param('Edit How To Topic') ) {

        my $topic_id = param('Edit Topic');
        SDB::DB_Form_Viewer::view_records( $dbc, 'How_To_Topic', 'How_To_Topic_ID', $topic_id );

    }
    elsif ( param('Add How To Step') ) {

        my $topic_id = param('Edit Topic');
        my %grey     = ();
        my %list     = ();
        my %preset   = ();
        $grey{FK_How_To_Topic__ID}    = $topic_id;
        $preset{FK_How_To_Object__ID} = $topic_id;
        $grey{How_To_Step_Number}     = '';

        #print $original_source_id;
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'How_To_Step', -target => 'Database' );
        $form->configure( -list => \%list, -grey => \%grey, -preset => \%preset );
        $form->generate( -title => "New Step" );
    }
    elsif ( param('Add Document') ) {

        my %grey   = ();
        my %hidden = ();
        $hidden{Document_ID}       = '';
        $hidden{Document_Created}  = &date_time();
        $hidden{Document_Modified} = &date_time();

        # Create How To form
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Document', -target => 'Database' );
        $form->configure( -grey => \%grey, -omit => \%hidden );
        $form->generate( -title => "New Document" );

    }
    elsif ( param('Documents Home') ) {

        &alDente::Document::home_page( -dbc => $dbc );

    }
    elsif ( param('Delete Document') ) {

        # <CONSTRUCTION> need to add delete functionality

    }
    elsif ( param('View Document') ) {
        my $doc_id = 0;
        if ( param('Select Document') ) {
            $doc_id = param('Select Document');
        }
        elsif ( param('Document Name') ) {
            my $doc_name = param('Document Name');
            ($doc_id) = $dbc->Table_find( "Document", "Document_ID", "WHERE Document_Name = '$doc_name'" );
        }
        my $document = alDente::Document->new( -dbc => $dbc, -id => $doc_id );
        $document->view();

    }
    elsif ( param('Add Step') ) {

        my $doc_id = param('Document ID');
        my ($step_no) = $dbc->Table_find( 'Document_Step', 'max(Document_Step_Number)', "WHERE FK_Document__ID = $doc_id" );
        my %hidden    = ();
        my %preset    = ();
        $hidden{FK_Document__ID}            = $doc_id;
        $hidden{FKParent_Document_Step__ID} = 'NULL';
        $preset{Document_Step_Number}       = ( $step_no + 1 );
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Document_Step', -target => 'Database' );
        $form->configure( -omit => \%hidden, -preset => \%preset );
        $form->generate( -title => "New Step" );
    }
    elsif ( param('Add UseCase') ) {

        my %grey   = ();
        my %hidden = ();
        $hidden{UseCase_ID}       = '';
        $hidden{UseCase_Created}  = &date_time();
        $hidden{UseCase_Modified} = &date_time();

        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'UseCase', -target => 'Database' );
        $form->configure( -grey => \%grey, -omit => \%hidden );
        $form->generate( -title => "New UseCase" );

    }
    elsif ( param('UseCase Home') ) {

        &alDente::UseCase::home_page( -dbc => $dbc );

    }
    elsif ( param('Delete UseCase Step') ) {

        my $step_id = param('Delete UseCase Step');
        &alDente::UseCase::delete_step( -dbc => $dbc, -step_id => $step_id );

    }
    elsif ( param('Delete UseCase') ) {

        my $case_id = param('Select UseCase');
        &alDente::UseCase::delete_step( -dbc => $dbc, -case_id => $case_id );

    }
    elsif ( param('View UseCase') || param('Select UseCase') ) {
        my $case_id = 0;
        if ( param('Select UseCase') ) {
            $case_id = param('Select UseCase');
        }
        elsif ( param('UseCase Name') ) {
            my $case_name = param('UseCase Name');
            ($case_id) = $dbc->Table_find( "UseCase", "UseCase_ID", "WHERE UseCase_Name= '$case_name'" );
        }
        my $admin_view = param('Admin_View');

        my $usecase = alDente::UseCase->new( -dbc => $dbc, -case_id => $case_id );
        print $usecase->view( -admin_view => $admin_view );

    }
    elsif ( param('Add UseCase Step') || param('Add Branch Step') ) {

        my $case_id    = param('UseCase ID');
        my $step_id    = 0;
        my $form_title = '';
        my %hidden     = ();
        my %preset     = ();
        my %grey       = ();
        my $form;

        if ( param('Add UseCase Step') ) {
            $step_id = param('Add UseCase Step');

            if ( param('First Step') ) {
                $step_id = 0;
            }
            $form_title = "New UseCase Step";
            $hidden{UseCase_Step_Branch} = '0';

        }
        else {
            $step_id    = param('Add Branch Step');
            $form_title = "Branch details";
        }

        my ($branch_info) = $dbc->Table_find( "UseCase_Step", 'UseCase_Step_Title,UseCase_Step_Branch', "WHERE UseCase_Step_ID=$step_id" );
        my ( $branch_name, $branch ) = split( ',', $branch_info );

        if ( $step_id > 0 ) {
            $hidden{FKParent_UseCase_Step__ID} = $step_id;
        }
        else {
            $hidden{FKParent_UseCase_Step__ID} = 0;
        }

        $hidden{FKParent_UseCase_Step__ID}   = $step_id;
        $hidden{FKOriginal_UseCase_Step__ID} = 'NULL';

        if ( param('Add Branch Step') && $branch ) {
            $form_title                 = "Branch details <SPAN class=small>($branch_name)</SPAN>";
            $grey{FKParent_UseCase__ID} = $case_id;
            $grey{FK_UseCase_Step__ID}  = $step_id;

            my $caseform = SDB::DB_Form->new( -dbc => $dbc, -table => 'UseCase', -target => 'Database' );
            $caseform->configure( -omit => \%hidden, -preset => \%preset, -grey => \%grey );
            $caseform->generate( -title => $form_title );

        }
        elsif ( param('Add Branch Step') ) {
            $form_title                  = "Branch condition details";
            $hidden{UseCase_Step_Branch} = '1';
            $grey{FK_UseCase_Step__ID}   = $step_id;
            $grey{FK_UseCase__ID}        = $case_id;
            my $stepform = SDB::DB_Form->new( -dbc => $dbc, -table => 'UseCase_Step', -target => 'Database' );
            $stepform->configure( -omit => \%hidden, -preset => \%preset, -grey => \%grey );
            $stepform->generate( -title => $form_title );

            #<CONSTRUCTION> must create a new UseCase record and assign all of the parents

        }
        else {
            $hidden{FK_UseCase__ID} = $case_id;

            my $stepform = SDB::DB_Form->new( -dbc => $dbc, -table => 'UseCase_Step', -target => 'Database' );
            $stepform->configure( -omit => \%hidden, -preset => \%preset, -grey => \%grey );
            $stepform->generate( -title => $form_title );
        }
    }
    elsif ( param('Quick_Action_List') ) {
        my $action = param('Quick_Action_List');
        if ( $action eq 'Plate Set' ) {

            $plate_set = param('Quick_Action_Value');
            if ( $plate_set =~ /^\d+$/ ) {
                $current_plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number=$plate_set ORDER BY Plate_Set_ID" );
            }
            unless ( $current_plates =~ /\d+/ ) {
                Message("Invalid Plate Set (?) ");
                $plate_set = '';
                return $plate_set;
            }
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $action eq 'Search' ) {
            print alDente::Form::start_alDente_form( $dbc, 'help', undef ), $q->submit( -name => 'Search Database', -style => "background-color:yellow" ), " containinG: ", $q->textfield( -name => 'DB Search String' ), $q->end_form();
            my $table  = param('Table');
            my $string = param('Quick_Action_Value');
            print h3("Looking for '$string' in Database...");

            #my $matches = alDente::Tools::Search_Database( $dbc, $string, \%Search_Item, $table );

            my $Search = alDente::SDB_Defaults::search_fields();
            my $matches = alDente::Tools::Search_Database( -dbc => $dbc, -input_string => $string, -search => $Search, -table => $table );
            unless ($table) { print vspace(5) . "$matches possible matches.<BR>"; }
        }
        elsif ( $action eq 'Help' ) {
            my $help_topic = param('Quick_Action_Value');
            &SDB_help( $help_topic, -dbc => $dbc );
        }
        elsif ( $action eq 'Table_retrieve_display' ) {
            my $TableName = param('Table');
            my $Pfields   = param('Fields');
            my @Pfields   = split ',', $Pfields;    # list of fields to extract
            my $condition = param('Condition');     # 'where' condition,'Order by' or 'Limit' specifications
            my $distinct  = param('Distinct');      # flag to return only distinct fields
            my $title     = param('Title');
            my $order_by  = param('Order_By');

            my $display = &Table_retrieve_display( $dbc, $TableName, \@Pfields, $condition, $distinct, $title, -order_by => $order_by );

        }
    }
    elsif ( param('Sample Sheets') ) {

        if ( param('SS Plate') ) {
            unless ( preparess( $dbc, param('SS Plate') ) ) { &sequence_home(); }
        }
        elsif ( param('SS Plate Number') ) {
            unless ( preparess( $dbc, param('SS Plate') ) ) { &sequence_home(); }
        }
        else { &sequence_home(); }
    }
    elsif ( param('test submission') ) {

        require SDB::DIOU;
        &SDB::DIOU::edit_submission_file(
            -mandatory_fields => ['Library_Name'],
            -tables           => "Original_Source,Source,Library,RNA_DNA_Collection"
        );
    }
    elsif ( param('Edit Batch Submission') ) {

        require SDB::DIOU;
        my $filename = param("Filename");
        my @fields   = param("FieldList");
        my @values;
        foreach my $field (@fields) {

            my @value_array = param("$field");
            $field =~ s/_Field$//;
            if ( @value_array && int(@value_array) > 0 ) {
                push( @values, \@value_array );
            }
            else {
                push( @values, [] );
            }

        }

        &SDB::DIOU::add_values_to_submission( -fields => \@fields, -values => \@values, -file => $filename );
    }
    elsif ( param("Add Batch Submission") ) {

        my $sid = param("Submission ID");
        require alDente::Submission;
        &alDente::Submission::insert_submission_file( -sid => $sid );
    }
    elsif ( param('Check Submissions') ) {
        $dbc->error("This option is phased out ... please see LIMS to redirect request through the appropriate run mode ");

    }
    elsif ( param('Prepare 384 well SS') ) {

        if ( param('SS Plate') ) {
            unless ( &preparess( $dbc, param('SS Plate') ) ) { &sequence_home(); }
        }
        else {
            unless ( &preparess($dbc) ) { &sequence_home(); }
        }
    }
    elsif ( param('Prepare Sample Sheet') ) {

        if ( param('SS Plate') ) {
            unless ( &preparess( $dbc, param('SS Plate') ) ) { &sequence_home(); }
        }
        elsif ( param('SS Plate Number') ) {
            my $lib = param('Library.Library_Name');
            my $num = param('SS Plate Number');
            if ( $num > 0 && $lib ) {
                my $Lib = alDente::Library->new( -dbc => $dbc, -id => $lib );
                my @lib_plate_info = $Lib->library_plates( $lib, $num );
                print "<B>Valid $lib $num Plates:</B><BR>";
                foreach my $plate (@lib_plate_info) {
                    if ( $plate =~ /Pla(\d+)/ ) {
                        my $id = $1;
                        my $link = &Link_To( $dbc->config('homelink'), "$plate", "&HomePage=Plate&ID=$id", $Settings{LINK_COLOUR}, ['newwin'] );
                        print "$link<BR>";
                    }
                    else { print "$plate<BR>"; }
                }
            }
            &sequence_home();
        }
        else {
            Message("To Prepare Sample Sheets please scan applicable Plates along with Sequencer");
            &sequence_home();
        }
    }
    elsif ( param('Generate Sample Sheet') ) {

        my $plates = param('SS Plate');     #### may want to check if all 4 plates are used AND allow 3
        my $format = param('Run Format');

        # check permissions for Run and RunBatch - need to have write permissions, otherwise fail out
        my $seq_perm   = $dbc->check_permissions( -user_id => $user_id, -table => "Run",      -type => "append" );
        my $batch_perm = $dbc->check_permissions( -user_id => $user_id, -table => "RunBatch", -type => "append" );
        my $quadrants = join ',', param('Quadrants_Used');
        my $equipment_id = param('Equipment_ID');
        if ( ( $seq_perm != 1 ) || ( $batch_perm != 1 ) ) {
            Message("Cannot generate sample_sheet: permission to write to database denied (S:$seq_perm;B:$batch_perm)");
        }
        else {
            unless ( &genss( -dbc => $dbc, -plate_id => $plates, -equipment_id => $equipment_id, -quadrants => $quadrants ) ) {
                unless ( &preparess( $dbc, $plates ) ) { return 0 }
            }
        }
    }
    elsif ( param('Remove Run Request') ) {

        my $search = param('Search String');
        my $condition;
        if ($search) { $condition = "and Run_Directory like '%$search%'"; }
        unless ( param('All Users') ) { $condition .= " AND RunBatch.FK_Employee__ID = $user_id"; }
        Message("Condition: $condition");
        my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Test_Status', 'RunBatch.FK_Equipment__ID as Machine', 'RunBatch.FK_Employee__ID as User' );
        &SDB::DB_Form_Viewer::mark_records(
            $dbc, 'Run,RunBatch', \@fields,
            "WHERE FK_RunBatch__ID=RunBatch_ID AND Run_Status in ('Initiated', 'Not Applicable','In Process','Expired') $condition ORDER BY Run_DateTime desc",
            -run_modes => [ 'Aborted', 'Delete Record' ]
        );
    }
    elsif ( param('Mark Failed Runs') ) {

        my $search = param('Search String');
        $search ||= "";
        my $condition;
        if ($search) { $condition = "and Run_Directory like \"%$search%\""; }
        unless ( param('All Users') ) { $condition .= " AND FK_Employee__ID = $user_id"; }

        my $limit = 20;
        my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Status', 'Run_Test_Status', 'FK_Equipment__ID', 'FK_Employee__ID' );

        &SDB::DB_Form_Viewer::mark_records( $dbc, 'Run,RunBatch', \@fields, "WHERE FK_RunBatch__ID=RunBatch_ID $condition ORDER BY Run_DateTime desc,Run_Directory Limit $limit", -run_modes => [ 'Delete Record', "Set to Failed" ] );
    }
    elsif ( param('Annotate Run Comments') ) {

        my $search = param('Search String');
        $search ||= "";
        my $condition;
        if   ($search) { $condition = "Run_Directory like \"%$search%\""; }
        else           { $condition = '1'; }

        unless ( param('All Users') ) { $condition .= " AND FK_Employee__ID = $user_id"; }
        my $limit = 20;
        my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Test_Status', 'FK_Equipment__ID', 'FK_Employee__ID' );

        &SDB::DB_Form_Viewer::mark_records( $dbc, 'Run,RunBatch', \@fields, "WHERE FK_RunBatch__ID=RunBatch_ID AND $condition ORDER BY Run_DateTime desc,Run_Directory Limit $limit", -run_modes => [ 'Delete Record', "Annotate Run_Comments" ] );
    }
    elsif ( param('Delete Record') ) {

        my $ids = join ',', param('Mark');

#### if sequence removed... remove from SampleSheets Subdirectory ###

        my $table = param('TableName');
        print &Views::Heading("Delete $table record");

        ########## in some cases another Table record must be deleted first... ##############
        if ( !( $ids =~ /[1-9]/ ) ) { Message("No records marked"); }
        elsif ( $table eq 'Run' ) {
            ###### remove sample sheet ############
            my $multi_ids = join ',', $dbc->Table_find( 'MultiPlate_Run', 'FK_Run__ID', "Where FK_Run__ID in ($ids)" );

            #if ($multi_ids=~/[1-9]/) {
            #	my $ok = &SDB::DBIO::delete_records($dbc,'MultiPlate_Run','FK_Run__ID',$multi_ids);
            #	Test_Message("<B>MultiPlate_Run association deletedif applicable</B>",$testing);
            #    }
            my $deleted = $dbc->delete_records( $table, 'Run_ID', $ids, -cascade => get_cascade_tables('Run') );
            print br();
            $dbc->message("Deleted runs: $ids ($deleted Records deleted)");
        }
        elsif ( $table eq 'Solution' ) {
            if ( &SDB::DBIO::check_permissions( $dbc, $user_id, 'Solution', 'delete', 'Solution_ID', $ids ) ) {
                my $ok = delete_records( $dbc, 'Mixture', 'FKMade_Solution__ID', $ids, -override => 1 );
                Test_Message( "Deleted $ok from Mixture table first (in cases of solutions) - " . Get_DBI_Error(), 1 - $scanner_mode );
                my $deleted;
                if ($ok) { $deleted = &delete_records( $dbc, $table, undef, $ids ); }
                Test_Message( "Deleted $deleted records from $table table - " . Get_DBI_Error(), 1 - $scanner_mode );
            }
        }
        elsif ( $table eq 'Plate' ) {

            my $confirm = param("Continue");
            &alDente::Container::Delete_Container( -dbc => $dbc, -ids => $ids, -confirm => $confirm );
        }
        else {
            my $deleted = $dbc->delete_records( $table, undef, $ids );
        }
        return 0;
    }
    elsif ( param("RunCapPlateView") ) {

        require Sequencing::Views;
        my $run_id = param("RunCapPlateView");
        &Sequencing::Views::RunPlate( $dbc, -run_id => $run_id );
        return 1;
    }
    elsif ( param("StatsHistView") ) {

        require Sequencing::Views;
        my $run_id = param("StatsHistView");
        &Sequencing::Views::StatsPlate( $dbc, -run_id => $run_id );
        return 1;
    }
    elsif ( param("DisplaySequence") ) {

        require Sequencing::Views;
        my $run_id = param("DisplaySequence");
        my $well   = param("Well");
        $well = &format_well($well);
        &Sequencing::Views::DisplaySequence( $dbc, -run_id => $run_id, -well => $well );
        return 1;
    }
    elsif ( param("upload_file") ) {

        my $input_file_name  = param("input_file_name");
        my $output_file_name = param("output_file_name") || '';
        my $deltr            = param("deltr") || 'tab';
        my $ok               = SDB::DIOU::parse_delimited_file( -dbc => $dbc, -input => $input_file_name, -output => $output_file_name, -deltr => $deltr );

        #	    my $ok = SDB::DIOU::preview(-dbc=>$dbc,-input_file_name=>$input_file_name,-output_file_name=>$output_file_name,-deltr=>$deltr);

    }
    elsif ( param("preview") ) {
        my $output_file_name = param("output_file_name");
        my $input_file_name  = param("input_file_name");
        my $table            = param("table_name");
        my $deltr            = param("deltr");
        my $type             = param("upload_type");
        my $ref_field        = param("ref_field");

        my $data = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'input_data' );

        # get the column headers
        my @headers = @{ SDB::DIOU::get_data_headers( -data => $data, -delim => $deltr ) };

        # determine which columns were selected
        my %selected_headers = %{ SDB::DIOU::get_selected_headers( -headers => \@headers ) };

        my $ok = SDB::DIOU::preview(
            -data             => $data,
            -input_file_name  => $input_file_name,
            -output_file_name => $output_file_name,
            -table            => $table,
            -deltr            => $deltr,
            -upload_type      => $type,
            -ref_field        => $ref_field,
            -columns          => \%selected_headers,
            -html             => 1
        );

    }
    elsif ( param("write_to_db") ) {

        my $table_name       = param("table_name");
        my $deltr            = param("deltr");
        my $type             = param("type");
        my $input_file_name  = param("input_file_name");
        my $output_file_name = param("output_file_name");
        my $ref_field        = param("ref_field");
        my $input_data       = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'input_data' );
        my $ok               = SDB::DIOU::write_to_db( -dbc => $dbc, -input_file_name => $input_file_name, -input_data => $input_data, -output => $output_file_name, -table => $table_name, -deltr => $deltr, -type => $type, -ref_field => $ref_field );
        return 0;    ## continue to generate normal page...
    }
    elsif ( param("Configure GCOS Config") ) {

        require Lib_Construction::GCOS_SS;
        my $id = param("Configure ID");

        if ( $id =~ /^\d+$/ ) {
            &Lib_Construction::GCOS_SS::configure_gcos_config( -config_id => $id );
        }
        else {
            Message("ERROR: Does not match a GCOS Config");
            return 0;
        }
    }
    elsif ( param("Set GCOS Config") ) {

        require Lib_Construction::GCOS_SS;
        my $id = param("GCOS_Config_ID");

        my @attribute_name    = param('Attribute_Name');
        my @attribute_type    = param('Attribute_Type');
        my @attribute_field   = param('Attribute_Field');
        my @attribute_default = param('Attribute_Default');

        my %config_info;
        $config_info{'Name'}    = \@attribute_name;
        $config_info{'Type'}    = \@attribute_type;
        $config_info{'Field'}   = \@attribute_field;
        $config_info{'Default'} = \@attribute_default;

        &Lib_Construction::GCOS_SS::set_gcos_config( -config_id => $id, -info => \%config_info );
    }
    elsif ( param("Generate GCOS SS") ) {

        require Lib_Construction::GCOS_SS;
        my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );

        # grab Plate ID and Equipment ID
        my @comments_array      = param("Genechip_Comments");
        my @exp_config_id_array = param("Experiment_Template_ID");
        my @spl_config_id_array = param("Sample_Template_ID");
        my @ext_barcode_array   = param("Genechip_Barcode");
        my @plate_id_array      = param("Plate_ID");
        my @test_status_array   = param("Test_Status");
        my @xml_hash_array      = ();

        my $equ_id = param("Equipment_ID");
        my $rescan = param("Rescan");
        foreach my $plate_id (@plate_id_array) {

            # thaw XML hash
            my $xml_hash = &Safe_Thaw( -name => "xml_hash_${plate_id}", -thaw => 1, -encoded => 1 );
            push( @xml_hash_array, $xml_hash );
        }
        $ss->gen_sheet(
            -plate_id      => \@plate_id_array,
            -test_status   => \@test_status_array,
            -equipment_id  => $equ_id,
            -xml_hash      => \@xml_hash_array,
            -comments      => \@comments_array,
            -exp_config_id => \@exp_config_id_array,
            -spl_config_id => \@spl_config_id_array,
            -barcode       => \@ext_barcode_array,
            -rescan        => $rescan
        );
    }
    elsif ( param("Preview GCOS SS") ) {

        require Lib_Construction::GCOS_SS;
        my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );

        # grab Plate ID and Equipment ID
        my @plate_ids     = param("Plate_ID");
        my @comments      = param("Genechip_Comments");
        my @ext_barcode   = param("Genechip_Barcode");
        my @spl_config_id = param("Sample_Template_ID");
        my @exp_config_id = param("Experiment_Template_ID");
        my @test_status   = param("Test_Status");
        my $equ_id        = param("Equipment_ID");

        $ss->create_sheet( -equipment_id => $equ_id, -plate_id => \@plate_ids, -comments => \@comments, -spl_config_id => \@spl_config_id, -exp_config_id => \@exp_config_id, -barcode => \@ext_barcode, -test_status => \@test_status );
    }
    elsif ( param('Set to Failed') ) {

        print &Views::Heading("Failing Runs");
        my $notes = param('Mark Note');
        fail_runs( $dbc, $notes );
        &sequence_home();
    }
    elsif ( param('Annotate Run_Comments') ) {

        print &Views::Heading("Annotating Comments");
        my $notes = param('Mark Note');
        &add_comments_to_runs( $dbc, $notes );
        &sequence_home();
    }
    elsif ( param('Aborted') ) {

        print &Views::Heading("Aborting Runs");
        my $notes = param('Mark Note');
        my @ids   = param('Mark');
        Sequencing::Sequence::run_state_swap( -dbc => $dbc, -search => 'Initiated|In Process', -replace => 'Aborted', -notes => $notes, -ids => \@ids );
        &sequence_home();
    }
    elsif ( param('Change Matrix') ) {

        my $equip = param('Equipment');
        my $mb    = param('Matrix');
        change_matrix( $equip, $mb );
        &sequence_home;
    }
    elsif ( param('Run Completed') ) {

        print "\nChecking sequence ";
        prepare_post_sequence();
    }
    elsif ( param('Check Run Data') ) {

        print "\nChecking sequence ";
        check_post_sequence();
    }
    elsif ( param('Post_Sequence_OK') ) {
        Message( "Note", "Run info passed check" );
        my $added = post_sequence();
        Message( "Added: ", "$added records" );

    }
    elsif ( param('Finished Run') ) {

        finished_sequence();
    }
    elsif ( param('Sequencing Status') ) {

        if ( $Current_Department =~ /Cap_Seq/i ) {
            status_home( $dbc, param('Lib Status'), param('Plate Number') );
        }
        elsif ( $Current_Department =~ /mapping/i ) {
            require alDente::View;
            alDente::View::request_broker( -dbc => $dbc, -title => 'Mapping Statistics' );
        }
        $dbc->Benchmark('here');
    }
    elsif ( param('ReGenerate Menus') ) {

        status_home( $dbc, param('Lib Status'), param('Plate Number') );
    }
    elsif ( param('Reads Summary') ) {

        unless ( all_lib_status( param('Machine') ) ) { &status_home( $dbc, param('Lib Status'), param('Plate Number') ); }
    }
    elsif ( param('Capillary Stats') ) {

        # deactiveated
        capillary_status();
    }
    elsif ( param('Monthly Histograms') ) {
        my $year  = param('Year');
        my $month = param('Month');
        print &alDente::Data_Images::monthly_histograms( -year => $year, -month => $month );
    }
    elsif ( param("Generate Run Hist") ) {

        my $run_ids = param("Run IDs");
        $run_ids = &resolve_range($run_ids);
        require Sequencing::Run_Histogram;
        &Sequencing::Run_Histogram::generate_run_hist( -run_ids => $run_ids );
    }
    elsif ( param('Set Employee Groups') ) {

        my $emp_id    = param('Employee_ID');
        my @grp_array = param('Add_Group_List');
        my @grp_ids   = ();
        foreach my $id (@grp_array) {
            push( @grp_ids, get_FK_ID( $dbc, "FK_Grp__ID", $id ) );
        }
        require alDente::Security;
        my $so = new alDente::Security( -dbc => $dbc );
        $so->set_groups( -emp_id => $emp_id, -group_ids => \@grp_ids );
        $so->display_set_groups( -emp_id => $emp_id );
    }
    elsif ( param('Prompt Create Transposon Pool') ) {

        my $newlib = param('New Transposon Library');
        require alDente::Transposon_Pool;
        my $tpo = new alDente::Transposon_Pool( -dbc => $dbc );
        print $tpo->prompt_create_transposon_pool( -new_library => $newlib, -plate_ids => $current_plates );
    }
    elsif ( param('Create Transposon Pool') ) {

        # initialize transposon_pool object
        require alDente::Transposon_Pool;
        my $tpo = new alDente::Transposon_Pool( -dbc => $dbc );

        # get wells assigned for each plate
        my $platestr = param('Platelist');
        my @plates = split ',', $platestr;
        my %pool_wells;
        my @plate_list    = ();
        my @well_list     = ();
        my @quantity_list = ();
        my @unit_list     = ();
        foreach my $plate_id (@plates) {
            my $wells = param("WellsForPlate$plate_id");
            my @well_array = split ',', $wells;
            push( @plate_list, map {$plate_id} @well_array );
            push( @well_list, @well_array );

            # set sample quantities to 0 (can be updated later)
            push( @quantity_list, map {'0'} @well_array );
            push( @unit_list,     map {'mL'} @well_array );
        }

        my $form_data = '';

        ## process DBForm entries if it exists
        if ( param('HasForm') ) {
            my $form = new SDB::DB_Form( -dbc => $dbc );
            $form->store_data( -table => 'Library' );
            $form->store_data( -table => 'Vector_Based_Library' );
            $form->store_data( -table => 'Transposon_Library' );
            $form->store_data( -table => 'LibraryVector' );
            $form_data = $form->{data};
        }

        # get values from parameters
        my $name             = param('Library_Name') || param('Library_Name Choice');
        my $goals            = param('Library_Goals');
        my $status           = 'Ready for Pooling';
        my $comments         = param('Pool_Comments');
        my $pool_description = param('Pool_Description');
        my $contact_id       = param('Contact_ID') || param('Contact_ID Choice');
        my $reads_required   = param('Reads_Required');
        my $pipeline         = param('Transposon_Pipeline');
        my $transposon       = param('Transposon');
        my $test_status      = param('Test_Status');

        # if library is defined already, append to the library
        my $append_to_library = 0;
        if ( grep /^$name$/, @libraries ) {
            $append_to_library = 1;
            Message("Appending pool to library $name");
        }

        # set arguments to create transposon pool
        my %args;

        # mandatory fields
        $args{-name}       = $name;
        $args{-plate_id}   = \@plate_list;
        $args{-wells}      = \@well_list;
        $args{-quantity}   = \@quantity_list;
        $args{-units}      = \@unit_list;
        $args{-contact_id} = &get_FK_ID( $dbc, "Contact_ID", $contact_id );

        # optional fields
        $args{-pool_description} = $pool_description;
        $args{-status}           = $status || "Ready for Pooling";
        $args{-test_status}      = $test_status || "Production";
        $args{-comments}         = $comments;
        $args{-goals}            = $goals;
        $args{-reads_required}   = $reads_required;
        $args{-pipeline}         = $pipeline || "Standard";

        # mandatory transposon pool fields
        $args{-transposon} = $transposon;
        $args{-append}     = !param('HasForm');
        $args{-emp}        = $user_id;
        $args{-quiet}      = 1;

        # form data for library
        $args{-library_form_data} = $form_data;

        Message("Creating Transposon Pool...");
        my $pool_id = $tpo->create_transposon_pool( -dbc => $dbc, %args );
        if ($pool_id) {
            Message("Created Transposon Pool $pool_id");
        }
        else {
            my @errors = $tpo->errors();
            print HTML_Dump \@errors;
        }
    }

    #    elsif ( param('Prep Summary') ) {
    #     ...
    #    }
    #    elsif ( param('Protocol Summary') ) {
    #     ...
    #    }
    elsif ( param('Seq_Data_Totals') ) {

        &Sequencing::SDB_Status::Seq_Data_Totals($dbc);
    }
    elsif ( param('List Consumables') ) {

        my $lib = substr( param('Library Status'), 0, 5 );
        if ( !$lib ) { Message("Please choose Library Name"); library_main(); }
        else {
            if ( param('Entire Project') ) {
                ( my $project ) = $dbc->Table_find( 'Library', 'FK_Project__ID', "WHERE Library_Name='$lib'" );
                library_consumables( undef, $project );
            }
            else { library_consumables($lib); }
        }
    }
    elsif ( param('Custom Data') ) {
        &custom_data();
    }
    elsif ( param('Project Info') ) {

        my $project_id = param('Project_ID');
        my $Proj = Project->new( -dbc => $dbc, -project_id => $project_id );
        $Proj->home_info();
    }
    elsif ( param('Project Stats') || param('Date Range Summary') ) {
        my $project_totals     = 0;                                                                                                                   # display totals for projects listed.. (good if only 1 project displayed)
        my $accumulated_totals = 1;                                                                                                                   # display accumulated totals for entire table... (good for multiple projects)
        my $proj_list          = join ',', param('Project_ID');
        my $name_list          = join "','", param('Project.Project_Name Choice');                                                                    ## available via popdown menu
        my $library            = join ',', param('Library_Name');
        my $pipelines          = get_Table_Params( -table => 'Plate', -field => 'FK_Pipeline__ID', -ref_field => 'FK_Pipeline__ID', -dbc => $dbc );
        my $pipeline           = join ',', @$pipelines if $pipelines;

        if ($name_list) {
            $proj_list = join ',', $dbc->Table_find( 'Project', 'Project_ID', "where Project_Name in ('$name_list')" );
        }
        my $lib_type = get_Table_Param( -table => 'Library', -field => 'Library_Type', -dbc => $dbc );
        $accumulated_totals = !$name_list;                                                                                                            ## not sure why, but based on previous logic... (?)
        my $include_runs = join ',', param('Include Runs');
        my $group_by = param('Group By');
        if ( $library && !$group_by ) { $group_by = 'Library_Name' }
        my $details     = param('Include Details');
        my $remove_zero = param('Remove Zero');
        my $order       = param('Order By') || 'Name';                                                                                                ## retrieve libraries by name...

        if ( param('Date Range Summary') ) {
            ### just get summary for list of runs.. ###

            my $since = param('Since') || param('from_date_range');
            my $until = param('Until') || param('to_date_range');
            my $condition = "Run_Status='Analyzed'";

            print define_Layers(
                -layers => {
                    "Selected Projects" => &Sequencing::Sequencing_Data::show_Project_info(
                        -dbc                => $dbc,
                        -project_id         => $proj_list,
                        -pipeline           => $pipeline,
                        -stats              => 1,
                        -condition          => $condition,
                        -group_by           => $group_by,
                        -order_by           => $order,
                        -project_totals     => $project_totals,
                        -accumulated_totals => $accumulated_totals,
                        -details            => $details,
                        -include            => $include_runs,
                        -remove_zero        => $remove_zero,
                        -include_summary    => 1,
                        -lib_type           => $lib_type,
                        -since              => $since,
                        -until              => $until
                    ),
                    "All Projects" => &Sequencing::Sequencing_Data::Project_overview( -title => "Overview for All Project Data to date", -name => "AllProjects", -pipeline => $pipeline, -since => $since, -until => $until )
                },
                -order   => 'Selected Projects,All Projects',
                -default => 'Selected Projects'
            );
        }
        else {
            print &Project_Stats( -id => $proj_list, -group_by => $group_by, -library => $library, -pipeline => $pipeline );
        }
    }
    elsif ( param('Sequencer Stats') || param('Sequencer Status') ) {
        my $equipment_barcode = param('Barcode');
        my $equipment_id = get_aldente_id( $dbc, $equipment_barcode, 'Equipment' );
        &sequencer_stats( -equipment_barcode => $equipment_id );
    }
    elsif ( param('Index Warning') ) {

        my $lib = param('Lib Status') || param('Library');
        &index_warnings( $lib, param('Limit') );
    }
    elsif ( param('List Warnings') ) {

        &Table_retrieve_display( $dbc, 'Note', [ 'Note_Text as Warning', 'Note_Description as Explanation' ] );
    }
    elsif ( param('Run Status') ) {

        #	my %Plates;
        #	my %Libs;
        my %Runs;
        foreach my $name ( param() ) {
            if ( $name =~ /Plate(.{5})(\d+)/ ) {

                #		$Plates{$2}=1;
                #		$Libs{$1}=1;
                $Runs{"$1$2"} = 1;
            }
        }

        #	my @nums = keys %Plates;
        #	my @libs = keys %Libs;
        my @runs      = keys %Runs;
        my $runs_like = join "','", @runs;
        my $get_runs  = join ',', $dbc->Table_find( 'Run,Plate', 'Run_ID', "where FK_Plate__ID=Plate_ID AND concat(FK_Library__Name,Plate_Number) in ('$runs_like')" );

        #	my $numbers = param('Plate Number') || join ',', @nums;
        #	my $libs = param('Lib Status') || join ',', @libs;
        #	my $runs = "$libs
        if ( param('Cancel') eq 'Cancel' ) {
            return;
        }
        my $SequenceAnalysis = alDente::Run_Statistics->new( -dbc => $dbc );
        print $SequenceAnalysis->sequence_status( undef, undef, $get_runs );
    }
    elsif ( param('Stock Used') ) {

        my $reagent_list = param('Include Reagent List') || 0;
        my $proj = get_Table_Param( -table => 'Project', -field => 'Project_Name', -dbc => $dbc ) || param('Project.Project_Name Choice') || '';
        my $lib = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) || param('Library Status') || '';
        $lib = substr( $lib, 0, 5 );

        &stock_used( $proj, $lib, $reagent_list );

    }
    elsif ( param('ReAnalyze') ) {
        my $default_list  = join ',', param('Last IDs');
        my $selected_list = join ',', param('SelectRun');

        my $fulllist = $selected_list || $default_list || 0;    ### use full list of runs if none selected

        my @list = split ',', $fulllist;

        if ( param('List Runs') ) {
            Table_retrieve_display( $dbc, 'Run', 'Run_ID,Run_Directory,Run_DateTime,SequenceAnalysis_DateTime as Analyzed,Run_Status,Run_Test_Status', "where Run_ID in ($fulllist)" );
            &leave;
        }

        my $options = " -f";
        my $command = "update_sequence.pl -A All";

        open( REANALYZE, ">>$mirror_dir/analysis.request" ) || print "ERROR opening $mirror_dir/analysis.request<BR>";
        print REANALYZE "$command : $options\n";
        print REANALYZE join "\n", @list;
        print REANALYZE "\n";
        close(REANALYZE);
        try_system_command("chmod 666 $mirror_dir/analysis.request");

        print "Sent Request to Re-Analyze the following runs:<P><UL><LI>";
        print join "<LI>", @list;
        print "</ul>";
        return 1;
    }
    elsif ( param('ReMirror') ) {
        print "Remirror..";
        my $only = param('ReMirror Only');

        my %Sequencers = $dbc->Table_retrieve(
            'Equipment,Machine_Default,Stock,Stock_Catalog,Equipment_Category',
            [ 'Equipment_Name', 'Host', 'Sharename', 'Local_Data_Dir' ],
            "where FK_Equipment__ID=Equipment_ID AND FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID AND Category = 'Sequencer' AND Sub_Category IN (3100,3730) AND Equipment_Status like 'In Use'"
        );

        my $lasttype;
        my $machines = int( @{ $Sequencers{Equipment_Name} } ) - 1;
        print "$machines found..";
        foreach my $index ( 0 .. $machines ) {
            my $name = $Sequencers{Equipment_Name}[$index];
            if ( $only && $name ne $only ) {next}    ## skip if only one chosen...

            my $host      = $Sequencers{Host}[$index];
            my $data_dir  = $Sequencers{Local_Data_Dir}[$index];
            my $sharename = $Sequencers{Sharename}[$index];
            $data_dir =~ /(.*?)\//;
            my $type = $1;

            $name =~ /(.*\D)(\d+)$/;
            my $prefix  = $1;
            my $machine = $2;
            my $dir     = $sharename;

            my $target = "$mirror_dir/request.$type.$machine.$dir";
            my $fback  = `echo request > $target`;
            `chmod 666 $target`;

            print "<P>Forced mirror of <B>$name</B>..<BR>$fback";
        }
        return 1;
    }

    #    elsif ( param('Last 24 Hours') ) {
    #           ... Moved to SequenceRun::Run_App
    #   }
    #    elsif ( param('Set Validation Status') ) {
    #			... Moved to SequenceRun::Run_App rm 'Set Validation Status'
    #    }
    #    elsif ( param('Set Billable Status') ) {
    #			... Moved to SequenceRun::Run_App rm 'Set Billable Status'
    #    }
    #    elsif ( param('Set as Failed') ) {
    #			... Moved to SequenceRun::Run_App rm 'Set as Failed'
    #    }
    elsif ( param('Annotate Runs') ) {
        my @ids;
        if ( param('SelectRun') ) {
            @ids = param('SelectRun');
        }
        elsif ( param('run_id') ) {
            @ids = param('run_id');
        }

        my $Last_ids = join ',', param('Last IDs');
        $Last_ids ||= 0;
        my $ids = join ',', @ids;
        my $comments = param('Comments');

        if ($ids) {
            my $update = &alDente::Run::annotate_runs( -run_ids => $ids, -comments => $comments );
            Message("Updated $update record(s)");
        }
        else {
            Message("Warning: No Run IDs specified");
        }

        if ( $Current_Department eq 'Cap_Seq' ) {
            &Sequencing::SDB_Status::Latest_Runs_Conditions( $dbc, $Last_ids, -filter_by_dept => 0 );
        }
    }
    elsif ( param('Get Sample Info') ) {

        my $well = param('Well');
        my $plate = param('Sample Plate') || $current_plates;

        $well = &extract_range( -list => $well );
        unless ($Plate) {
            $Plate = alDente::Container->new( -dbc => $dbc, -id => $plate );
        }
        $Plate->get_Sample( -id => $plate, -well => $well );
        if ( param('SeqRun_View') ) {
            ### and clone_sequence info... ###
            my $id       = param('SeqRun_View');
            my $view     = param('View Well Info');
            my $clone    = param('Plate_Name');
            my $trimming = param('Trimming');
            print Sequencing::Sequence::clone_sequence_status( -dbc => $dbc, -name => $clone, -id => $id, -well_info => $view, -trimming => $trimming );
        }
    }
    elsif ( param('Define Sample Alias') ) {
        my $sample_fh = param('Sample Alias File');
        my $plate     = param('Current Plates');
        unless ($sample_fh) {
            $dbc->warning("Must specify a file with sample aliases");
            return 0;
        }

        my $samples = &alDente::Sample::get_sample_alias( -dbc => $dbc, -file => $sample_fh, -plate => $plate );
        my @sample_list = Cast_List( -list => $samples, -to => 'Array' );

        #print Dumper @sample_list;

        ## <CONSTRUCTION>  ... This should allow a user to enter a single alias (if no file supplied),
        ##                - or a file.  (and should be available for all plate types) + add tooltip to browse button.

        print &alDente::Form::start_alDente_form( $dbc, );

        #Display the table of Sample Aliases to be added from the file

        my $sample_table = HTML_Table->new();
        my @sample_header = ( 'Well', 'Alias Type', 'Alias' );
        $sample_table->Set_Title("Sample Alias File Contents");
        $sample_table->Set_Class('small');
        $sample_table->Set_Border(1);
        $sample_table->Set_Headers( \@sample_header );

        for my $sample_id ( 0 .. $#sample_list ) {
            $sample_table->Set_Row( [ $sample_list[$sample_id]{'Well'}, $sample_list[$sample_id]{'Alias_Type'}, $sample_list[$sample_id]{'Alias'} ] );
        }
        $sample_table->Printout();
        print "<BR>Are you sure you want to upload the Sample Alias file? <BR>";
        print submit( -name => 'Upload Sample Alias file', -class => "Std" );
        print hidden( -name => 'plate_id', -value => $plate );
        my $frozen_sample = Safe_Freeze( -name => "Sample_Alias", -value => \@sample_list, -format => 'hidden', -encode => 1 );
        print $frozen_sample;

    }
    elsif ( param('Upload Sample Alias file') ) {

        #Display the contents of the file and prompt user to confirm the upload
        #	my $sample_fh = param('Upload File');
        my $plate_id      = param('plate_id');
        my $thawed_sample = Safe_Thaw( -name => 'Sample_Alias', -thaw => 1, -encoded => 1 );
        my @sample_list   = Cast_List( -list => $thawed_sample, -to => 'Array' );

        #find the original plate ID
        my $orig_plate;
        ($orig_plate) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$plate_id" );

        my @plate_sample_rows = $dbc->Table_find( 'Plate_Sample', 'FK_Sample__ID,Well', "WHERE FKOriginal_Plate__ID=$orig_plate" );
        my %sample_well;

        my $index = 1;

        foreach my $row (@plate_sample_rows) {
            my ( $sample_id, $well ) = split ',', $row;

            # fill in plate sample information
            $sample_well{$well} = $sample_id;
            print "$well, $sample_id<br>";
            $index++;
        }
        my %sample_alias;
        my $sample_index = 1;

        for my $sample ( 0 .. $#sample_list ) {
            $sample_alias{$sample_index} = [ $sample_well{ chomp_edge_whitespace( $sample_list[$sample]{'Well'} ) }, chomp_edge_whitespace( $sample_list[$sample]{'Alias_Type'} ), chomp_edge_whitespace( $sample_list[$sample]{'Alias'} ) ];

            $sample_index++;
        }

        my $ok1 = $dbc->smart_append( -tables => 'Sample_Alias', -fields => [ 'FK_Sample__ID', 'Alias_Type', 'Alias' ], -values => \%sample_alias, -autoquote => 1 );

        if ($ok1) {
            Message("Sample Aliases added for plate");
        }
    }
    elsif ( param('Add Attribute') ) {
        my $now  = &date_time();
        my $type = param('Add Attribute');

        my $group_list = $dbc->get_local('group_list');
        my %grey;
        my %hidden;
        my $id = param( 'FK_' . $type . "__ID" ) || param( $type . "_ID" ) || param($type);
        $grey{ 'FK_' . $type . '__ID' } = $id;
        $hidden{'FK_Employee__ID'}      = $user_id;
        $hidden{'Set_DateTime'}         = $now;

        my %list;
        my @attributes = &get_FK_info( $dbc, 'FK_Attribute__ID', -condition => "WHERE FK_Grp__ID in ($group_list) AND Attribute_Class = '$type'", -list => 1 );
        $list{'FK_Attribute__ID'} = \@attributes;
        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $type . '_Attribute', -target => 'Database', -mode => 'Normal' );
        $form->configure( -grey => \%grey, -omit => \%hidden, -list => \%list );
        $form->generate( -title => "Add $type attribute" );

    }
    elsif ( param('Define Attribute') ) {
        my $type = param('Define Attribute');

        my $group_list = $dbc->get_local('group_list');

        my %grey;
        my %hidden;
        my %preset;
        $hidden{Attribute_Type}   = 'Text';
        $hidden{Attribute_Format} = 'NULL';
        $grey{Attribute_Class}    = $type;
        my @groups = $dbc->get_FK_info( 'FK_Grp__ID', -condition => "WHERE Grp_ID in ($group_list)", -list => 1 );
        my %list;
        $list{'FK_Grp__ID'} = \@groups;

        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Attribute', -target => 'Database', -mode => 'Normal' );
        $form->configure( -grey => \%grey, -omit => \%hidden, -preset => \%preset, -list => \%list );
        $form->generate( -title => "Define a new $type attribute" );

    }
    elsif ( param('Home_GelRun') ) {

        ## Create GelRun Object , go to gel home
        my $gelrun = alDente::GelRun->new( -dbc => $dbc );
        $gelrun->GelRun_Home();

    }
    elsif ( param('Analyzed Plate Info') ) {

        my $runs = param('Run');

        &Table_retrieve_display(
            $dbc,
            'Plate,Run,SequenceRun,RunBatch,Equipment,Solution,Stock,Stock_Catalog',
            [ 'Plate_ID', 'concat(Plate_Number,Plate.Parent_Quadrant) as Plate', 'Equipment_Name as Machine', 'Stock_Catalog_Name as Primer', 'Run_Test_Status as Status', 'Run_DateTime as RunTime', 'RunBatch_RequestDateTime as Requested' ],
            "WHERE Run.FK_Plate__ID=Plate_ID AND FK_RunBatch__ID=RunBatch_ID AND RunBatch.FK_Equipment__ID=Equipment_ID AND FKPrimer_Solution__ID=Solution_ID AND Solution.FK_Stock__ID=Stock_ID AND SequenceRun_ID=FK_SequenceRun__ID AND Run_ID in ($runs) AND FK_Stock_Catalog__ID = Stock_Catalog_ID"
        );
    }
    elsif ( param('DNA Quantitation Info') ) {

        my $plate = param('Sample Plate');
        my $well  = param('Well');
        if ($well) { $well = &extract_range($well); }
        &alDente::Library_Plate::show_DNA_info( -dbc => $dbc, -plate_id => $plate, -title => "DNA Quantitation Info", -well => $well );
        if ( param('SeqRun_View') ) {
            ### and clone_sequence info... ###
            my $clone    = param('Plate_Name');
            my $view     = param('View Well Info');
            my $id       = param('PlateView');        ## param('RunID');
            my $trimming = param('Trimming');
            print Sequencing::Sequence::clone_sequence_status( -dbc => $dbc, -name => $clone, -id => $id, -well_info => $view, -trimming => $trimming );
        }
    }
    elsif ( param('Generate Fasta File for Run') ) {

        my $run     = param('Run');
        my $Options = {};

        my $suffix = '';
        if ( param('Include All Wells') ) { $Options->{include_NG}   = 1 }
        if ( param('Columnate') )         { $Options->{column_width} = param('Columnate'); }
        if ( param('Force Case') =~ /Upper/i ) { $Options->{upper} = 1; }
        if ( param('Force Case') =~ /Lower/i ) { $Options->{lower} = 1; $suffix .= ".all"; }
        if ( param('Trim Quality') ) { $Options->{qtrim} = 1; }
        else                         { $suffix .= ".Wpoor"; }
        if ( param('Trim Vector') ) { $Options->{vtrim} = 1; }
        else                        { $suffix .= ".Wvector"; }
        if ( param('Include Test Runs') || ( grep /(everything|test)/, ( param('Include Runs') ) ) ) { $Options->{all} = 1; $suffix .= ".all"; }
        $suffix .= ".dump";

        if ( param('Include Redundancies') ) { $Options->{include_redundancies} = 1; $suffix .= '.mult'; }

        print "<span class=small>";
        print "<Pre>";
        my %sequences = &Sequencing::Seq_Data::get_run_sequences( $dbc, $run, "$fasta_dir/Run$run$suffix.fasta", $Options );
        print "</pre>";

        if ( param('Dump to Screen') ) {
            my @output = split "\n", try_system_command("cat $fasta_dir/Run$run$suffix.fasta");
            my $output_text = join '<BR>', @output;
            print &Views::Heading("Fasta file for Run $run");
            print $output_text;
        }
        print "</span>";
        my $lib  = param('Library')      || '';
        my $pnum = param('Plate Number') || '';
        my $run_obj = new alDente::Run_Statistics( -dbc => $dbc );
        print $run_obj->sequence_status( $lib, $pnum, $run );
    }
    elsif ( param('SeqRun_View') ) {

        my $clone       = param('Plate_Name');
        my $view        = param('View Well Info');
        my $id          = param('SeqRun_View');
        my $trimming    = param('Trimming');
        my $phred_score = param('Phred Score');

        print Sequencing::Sequence::clone_sequence_status( -dbc => $dbc, -name => $clone, -id => $id, -well_info => $view, -trimming => $trimming, -phred_score => $phred_score );
    }
    elsif ( param('Well Info') ) {
        print &Views::Heading("Well Info");
        &well_info( param('Run_ID'), param('Well') );
    }
    elsif ( param('Interleave View') ) {

        my $ids = param('Interleave View');
        my $phred = param('Phred Score') || 20;
        &interleaved_run_view( $ids, $phred, -dbc => $dbc );
    }
    elsif ( param('Generate Fasta File for Library') ) {
        my $Options = {};
        my $include_test_runs = param('Include Test Runs') || ( grep /(everything|test)/, ( param('Include Runs') ) );
        my $whole_sequence;
        my $vector;

        my $ext = '';
        if ($include_test_runs) {
            $include_test_runs = " -A";
            $ext .= '.all';
        }
        if ( param('Include Vector') ) {
            $vector = " -V";
            $ext .= '.vector';
        }
        if ( param('Include Poor Quality') ) {
            $whole_sequence = " -W";
            $ext .= '.wpoor';
        }

        $Options->{all}    = $include_test_runs;
        $Options->{whole}  = $whole_sequence;
        $Options->{vector} = $vector;

        my @libraries = param('Library');

        Message( "Generating fasta file for " . join ',', @libraries );
        foreach my $library (@libraries) {
            unless ($library) { next; }
            print &Views::Heading("Generating Fasta file for $library");

            my $command = "$bin_home/fasta.pl -L $library $include_test_runs $vector $whole_sequence -o $fasta_dir/$library.fasta";
            my $fback   = try_system_command("$command");
            $fback =~ s/\n/<BR>/g;
            Message( "$command", $fback );

            print h2("Placed in: $fasta_dir/$library.fasta");

        }

        &library_main();
    }
    elsif ( param("Receive Sample") ) {

        my $sample_id = param("Sample_ID");

        # if TTR ID is not sent, return to tube homepage
        if ($sample_id) {

            # verify that TTR file has been received. If it hasn't been received, print an error message
            my $sro = new Sample_Receiving( -dbc => $dbc );
            $sro->receive_sample( -sample_id => $sample_id );
        }
        else {
            $dbc->warning("Need External Sample ID to continue");
            &Tube::home_tube();
        }
    }
    elsif ( param('Change Submission to Resubmission') ) {

        my $submission_source = param('Submission_Source');
        my $submission_status = param('Submission_Status');
        my $sid               = param('SID');
        my $library           = param('Library_Name');
        &SDB::Submission::Load_Submission( -dbc => $dbc, -sid => $sid, -source => $submission_source, -action => 'edit', -status => $submission_status, -resubmit => 'Library', -library => $library );

        #print "<li>" . &Link_To($dbc->homelink(),'Edit submission as a re-submission',"&Edit_Resubmission=$sid&Submission_Source=$source&Submission_Status=$status&Resubmit=Library",'blue') . br;
    }
    elsif ( param('Submit Work Request') ) {

        my $lib = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
        my $lo = new Sequencing::Sequencing_Library( -dbc => $dbc );
        print $lo->submit_work_request( -library => $lib );
    }
    elsif ( param('Submit Library') ) {
        my $type       = param('Submit Library');
        my $contact    = param('FK_Contact__ID');
        my $project_id = param('FK_Project__ID');

        if ( $type && $contact && $project_id ) {
            my %Parameters;    # = Set_Parameters();
            my %Preset;
            my %Grey;
            my %Omit;

            $Grey{'FK_Contact__ID'} = get_FK_info( $dbc, 'FK_Contact__ID', $contact );
            $Grey{'Library_Type'} = $type;

            if ( $type =~ /SAGE/i ) {

                $Omit{'Source_RNA_DNA'}      = 'N/A';
                $Grey{'BlueWhite_Selection'} = 'No';
            }
            elsif ( $type =~ /Mapping/i ) {
                $Grey{'BlueWhite_Selection'} = 'No';
                $Omit{'Source_RNA_DNA'}      = 'N/A';
            }

            my %Include;
            $Include{FK_Contact__ID} = $contact;

            my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Library', -target => 'Storable', -wrap => 1 );
            $form->configure( -include => \%Include, -preset => \%Preset, -grey => \%Grey, -omit => \%Omit );
            $form->generate( -title => 'Library Submission Form' );
        }
        else { Message("Insufficient information"); }
        return 1;
    }
    elsif ( param('Kill Process') ) {
        my $pid = param('PID') || param('Kill Process');
        `kill -9 $pid`;
        Message("Error: Tried to kill PID: $pid");
        return 1;
    }
    elsif ( param('View Event') ) {
        require alDente::View;
        alDente::View::request_broker();
    }
    elsif ( param('Generate View') ) {
        my $generate_view = param('Generate View');
        my $frozen        = param('Frozen_Config');
        my $class         = param('Class');
        require alDente::View_Generator;
        alDente::View_Generator::request_broker( -dbc => $dbc, -generate_view => $generate_view, -frozen => $frozen, -class => $class );
    }
    elsif ( param('Update Library') ) {
        my $new_lib;
        if ($new_lib) {
            Message( "Note", "New Library $new_lib Created" );
            &update_library_list;

            #	    &alDente::Plate::original_plate($new_lib);
        }
    }
    elsif ( param('Pipeline Summary') ) {
        alDente::Pipeline::request_broker( -dbc => $dbc );

    }
    elsif ( param('Procedure') ) {

        my $procedure = param('Procedure');

        #	my $object = param('Object');
        #	my $object_id = param('Id');
        #	my $object_display = param('Display');
        my @library = param('Library_Name Choice')   || param('Library_Name');     # || param('FK_Library__Name');
        my @project = param('FK_Project__ID Choice') || param('FK_Project__ID');
        my $ready   = param('Ready');

        my $in_process = param('In Process');
        my $next_proc  = param('Ready For Next Protocol');

        if ( ( int(@library) == 1 ) && ( $library[0] eq '' ) ) {
            @library = ();
        }
        if ( ( int(@project) == 1 ) && ( $project[0] eq '' ) ) {
            @project = ();
        }

        &alDente::Pipeline::procedure_summary( -dbc => $dbc, -procedure => $procedure, -library => \@library, -project => \@project, -ready => $ready, -in_process => $in_process, -next_proc => $next_proc );
    }
    elsif ( param('New Library Page') ) {
        my $target = param('Target');
        &alDente::Library::initialize_library( -dbc => $dbc, -target => $target );
    }
    elsif ( param('Create New Library') ) {

        my $lib;    ## Not defined??

        if ( param('Re-Pool') ) {    ##<CONSTRUCTION - add to main library_initialize page..
            my $configs;
            if ( param('DB_Form_Configs') ) { $configs = Safe_Thaw( -name => 'DB_Form_Configs', -thaw => 1, -encoded => 1 ) }
            my $pool_lib = param('Pool_Library');
            $lib->new_pool( -pool_lib => $pool_lib, -lib_type => $Lib_Type, -configs => $configs );
        }
        else {
            my $target = param('Target');

            # call library module to create new library
            my $orig_source_id = get_Table_Param( -field => 'FK_Original_Source__ID', -dbc => $dbc );
            $orig_source_id = $dbc->get_FK_ID( 'FK_Original_Source__ID', $orig_source_id );
            my $scanned_id = param('Scanned ID');

            my $source_tracking = param('Source Tracking');

            #    	    &alDente::Library::create_new_library(-dbc=>$dbc,-orig_source_id=>$orig_source_id,-scan_id=>$scanned_id,-target=>$target,-source_tracking=>$source_tracking);
            require alDente::Submission_App;
            my $diagnostics_app = alDente::Submission_App->new( PARAMS => { dbc => $dbc } );
            my $output = $diagnostics_app->create_new_library( -dbc => $dbc, -orig_source_id => $orig_source_id, -scan_id => $scanned_id, -target => $target, -source_tracking => $source_tracking );

        }
    }
    elsif ( param('Create Library') ) {
        my $new_lib;

        my $lib;
        if ( $Lib_Type =~ /RNA\/DNA/ ) {
            $lib = alDente::RNA_DNA_Collection->new( -dbc => $dbc );
        }
        else {
            $lib = Sequencing::Sequencing_Library->new( -dbc => $dbc );
        }
        if ( param('Re-Pool') ) {
###<CONSTRUCTION> This code is never used....
            ####### Get parameters #########
            my $pool_date       = param('Pool Date')  || now();
            my $pooled_plate_id = param('Pool Plate') || param('Pool Plate Choice');
            if ( $pooled_plate_id =~ /Pla(\d+)/i ) { $pooled_plate_id = $1; }

            my $lib = join ',', $dbc->Table_find( 'Plate', 'FK_Library__Name', "where Plate_ID = $plate_id" );

            Message("Library:  $lib");

            my $lib_source = "BCGSC";
            my $lib_type   = "Transposon";
            my $lib_sname  = "";
            my $Pcomments  = param('Pool Comments');
            my $Lcomments  = param('Lib Description');
            my $pipeline   = param('Pipeline');
            my $comments;

            my $lib_Fname  = param('Library FullName');
            my $lib_status = param('Library Status');
            my $lib_goals  = param('Library Goals');

### ONLY For creating new transposon records...
            my $Tname      = param('Transposon');
            my $Tsource    = param('Transposon Source');
            my $Tdesc      = param('Transposon Description');
            my $Tseq       = param('Transposon Run');
            my $Tsource_id = param('Source ID');
            my $TAB        = param('Transposon_Antibiotic');
            my $wells      = param('Pool Wells');
##############
            my $transposon_id;
            if ($Tname) { ($transposon_id) = $dbc->Table_find( 'Transposon', 'Transposon_ID', "WHERE Transposon_Name = '$Tname'" ) }

            $new_lib = Sequencing::Sequencing_API::define_Pool(
                -dbc           => $dbc,
                -date          => $pool_date,
                -plate_id      => $pooled_plate_id,
                -source        => 'BCGSC',
                -type          => 'Transposon',
                -comments      => $Pcomments,
                -desc          => $Lcomments,
                -pipeline      => $pipeline,
                -fullname      => $lib_Fname,
                -status        => $lib_status,
                -goals         => $lib_goals,
                -transposon_id => $transposon_id,
                -wells         => $wells
            );

            #	    $new_lib = $lib->create_pool();
            if ($new_lib) { Message( "Note", "New Pool Created" ); }
            else          { Message("New Pool not created"); }
        }

        #else {
        #    $new_lib = &create_library($dbh);
        #
        #    if ($new_lib) {
        #	 Message("Note","New Library $new_lib Created");
        #	 &update_library_list;
        #	#	 &alDente::Plate::original_plate($new_lib);
        #    }
        #    else {Message("Library not created");}
        #}

        if ($new_lib) { &alDente::Library::get_Library_specs($new_lib); }

        return 1;
    }
    elsif ( param('Resubmit_Sequencing_Library') ) {

        my $lib_format = param('Resubmit_Sequencing_Library');
        my $lib        = param('Library_Name') || param('Library_Name Choice');
        my $scanned_id = param('Scanned ID');

        my $source_id = 0;
        my $plate_id  = 0;

        if ( $scanned_id =~ /pla/ ) {
            $scanned_id =~ s/pla//;
            $plate_id = get_aldente_id( $dbc, $scanned_id, "Plate" );
            $plate_id = $scanned_id;
        }
        elsif ( $scanned_id =~ /src/ ) {
            $scanned_id =~ s/src//;
            $source_id = get_aldente_id( $dbc, $scanned_id, "Source" );
            $source_id = $scanned_id;
        }

        # get the original source
        my ($orig_src_id) = $dbc->Table_find( "Library", "FK_Original_Source__ID", "WHERE Library_Name = '$lib'" );

        my $lo = new alDente::Library( -dbc => $dbc );
        if ($source_id) {
            $lo->resubmit_library( -lib_format => $lib_format, -library => $lib, -source_id => $source_id );
        }
        elsif ($plate_id) {

            # call create source function with -submit=>1
            $lo->resubmit_library( -lib_format => $lib_format, -library => $lib, -original_source_id => $orig_src_id, -plate_id => $plate_id );

            #&alDente::Source::make_into_source(-dbc=>$dbc,-id=>$plate_id,-type=>$lib_format,-submission=>$lib,-orig_src_id=>$orig_src_id);
            #  &alDente::Source::make_into_source(-dbc=>$dbc,-id=>$plate_id,-type=>$lib_format,-submission=>$lib);
        }
        else {
            $lo->resubmit_library( -lib_format => $lib_format, -library => $lib, -original_source_id => $orig_src_id );
        }
    }
    elsif ( param('Find_Source') ) {

        #Connect to DB in case we haven't yet.
        my $equ_condition = join( ",", param('Equipment_Condition') );    # || param('Equipment_Condition Choice'));
                                                                          #my $group_by = join("-",param('Group_By'));
        $equ_condition = Cast_List( -list => $equ_condition, -to => 'String', -autoquote => 1 ) if $equ_condition;
        my @group_by = param('Group_By');                                 # || param ('Group_By Choice');

        unless (@group_by) {
            @group_by = ( 'Equipment_Condition', 'Equipment', 'Rack_ID', 'FK_Stock__ID', 'Solution_ID' );
        }
        my @equip = param('Equipment_Name') || param('Equipment_Name Choice');

        my $equip     = Cast_List( -list => \@equip, -to => 'String', -autoquote => 1 ) if (@equip);
        my $show_null = param('Show_Null_Racks');
        my $show_TBD  = param('Show_TBD');
        my $rack_id;
        if    ( param('FK_Rack__ID') =~ /Rac(\d+)/ ) { $rack_id = $1; }
        elsif ( param('FK_Rack__ID') =~ /(\d+)/ )    { $rack_id = param('FK_Rack__ID'); }
        my $search_child_racks = param('Search_Child_Racks');

        my $since;
        my $until;
        my $orig_src        = param('Orig_Src_Name');
        my $source_number   = param('Source_Number');
        my $sample_type     = param('Sample_Type');
        my $source_received = param('Source_Received');

        #        my $tissue          = param('Tis sue');            # needs to be modified to use the new Ti ssue table
        my $strain = param('FK_Strain__ID');
        my $sex    = param('Sex');
        my $host   = param('Host');
        my $found  = &alDente::Rack_Views::find(
            -dbc                 => $dbc,
            -equipment           => $equip,
            -rack_id             => $rack_id,
            -search_child_racks  => $search_child_racks,
            -since               => $since,
            -until               => $until,
            -equipment_condition => $equ_condition,
            -group_by            => \@group_by,
            -show_null           => $show_null,
            -show_TBD            => $show_TBD,
            -original_source     => $orig_src,
            -source_number       => $source_number,
            -sample_type         => $sample_type,
            -source_received     => $source_received,

            #        -tissue              => $tissue,
            -strain => $strain,
            -sex    => $sex,
            $host   => $host,
            -find   => 'Source'
        );
    }
    elsif ( param('Reset Pipeline') ) {
        ## LEFT IN ONLY for access from Protocol.pl ##
        my @plate_ids = param('Move_Plate_IDs') || param('FK_Plate__ID');

        #param('Move_Plate_IDs') is for the reset pipeline button in Container.pm and param('FK_Plate__ID') is for the reset pipeline button in Protocol.pm

        my $pipeline = param('FK_Pipeline__ID Choice');
        if ( @plate_ids && $pipeline ) {
            my $container = alDente::Container->new( -dbc => $dbc );
            my $updated = $container->set_pipeline( -dbc => $dbc, -plate_id => \@plate_ids, -pipeline => $pipeline );
            Message("Updated pipeline to $pipeline for $updated records");
        }
        return;
    }
    elsif ( param('Move_Lab_Object') ) {

        my @barcode = param('Barcode');
        my $barcode = join ',', @barcode;

        my $rack_id = param('FK_Rack__ID Choice') || param('FK_Rack__ID');
        $rack_id = get_FK_ID( $dbc, 'FK_Rack__ID', $rack_id );
        unless ($rack_id) {
            $dbc->error("Rack must be supplied");
            return;
        }
        &Rack_home( $dbc, -barcode => $barcode, -rack_id => $rack_id );
    }
    elsif ( param('Display_Lab_Object') ) {

        my $type = param('Type');
        my $ids = Safe_Thaw( -name => 'IDs', -thaw => 1, -encoded => 1 );
        alDente::Rack::display_object_in_rack( -dbc => $dbc, -ids => $$ids, -type => $type );

    }
    elsif ( param('Clear Plate Set') ) {

        #&alDente::Container_Set::clear_plate_set();
        &alDente::Container::clear_plate_set();
        return 0;
    }
    elsif ( param('Save Plate Set') || param('Force Plate Set') ) {

        my @plates = param('FK_Plate__ID');
        my $plates = Cast_List( -list => \@plates, -to => 'String' ) || $current_plates;
        unless ($plates) {
            $dbc->error("No plates specified");
            return 0;
        }
        my $Set              = alDente::Container_Set->new( -dbc => $dbc, -ids => $plates );
        my $force            = param('Force Plate Set');
        my $default_protocol = param('Lab_Protocol');
        $Set->save_Set( -force => $force );
        print $Set->Set_home_info( -brief => $scanner_mode, -default_protocol => $default_protocol );
    }
    elsif ( param('Make into source') ) {

        #my @srcs  	    = param('Source_IDS');
        my $plate_id        = param('plate_id');
        my $tables          = param('Tables');
        my $keep_orig       = param('Keep_Orig');
        my $submission_flag = param('Library Submission');
        my $type            = param('Type');

        my $submission = 0;
        print alDente::Form::start_alDente_form( $dbc, );

        my $pool_obj = alDente::Source->new( -dbc => $dbc, -tables => $tables );

        if ($submission_flag) {
            $submission = 1;
        }
        $pool_obj->load_object_from_form( -insert => !$submission );

        if ( !$submission ) {

            #$pool_obj->make_source(-id=>$plate_id,-submission=>$submission_flag, -keep_orig=>$keep_orig,-tables=>$tables);
            my $source = alDente::Source->new( -id => $pool_obj->{newids}->{Source}[0] );
            $source->home_page();
        }
        if ( $submission_flag == 1 ) {
            my $lo = new alDente::Library( -dbc => $dbc );
            &alDente::Library::create_new_library( -lib_format => $type, -library_type => 'Sequencing', -source_id => $pool_obj->primary_value( -table => 'Source' ), -submission => $submission_flag );
        }
        elsif ( $submission_flag =~ /\w+/ && $submission_flag ) {
            my $lo = new alDente::Library( -dbc => $dbc );
            $lo->resubmit_library( -lib_format => $type, -source_id => $pool_obj->primary_value( -table => 'Source' ), -library => $submission_flag );
        }
    }
    elsif ( param('Change History') ) {
        require alDente::Field;

        my $field_id   = param('field_id');
        my $field_name = param('field_name');
        my $primary    = param('primary');
        my $table_name = param('table_name');
        my $history    = &alDente::Field::home_page( $field_id, $field_name, $primary, $table_name );

    }
    elsif ( param('Change Field Details') ) {
        require alDente::Field;
        my $field_desc   = param('field_description');
        my $field_edit   = param('field_editable');
        my $field_track  = param('field_tracked');
        my $field_id     = param('field_id');
        my @options      = param('field_options');
        my $options_list = Cast_List( -list => \@options, -to => 'string' );

        my $update_ok = $dbc->Table_update_array( "DBField", [ 'Field_Description', 'Editable', 'Tracked', 'Field_Options' ], [ $field_desc, $field_edit, $field_track, $options_list ], "WHERE DBField_ID=$field_id", -autoquote => 1 );
        return;
    }
    elsif ( param('Change History All') ) {
        require alDente::Field;

        my $primary = param('primary');
        my $history = &alDente::Field::view_history_for_all( $dbc, $primary );
    }
    elsif ( param('QA Report') ) {
        require alDente::QA;

        my $qa = &alDente::QA::get_info($dbc);
    }
    elsif ( param('Create container') || param('Associate Library') ) {

        my $source_id     = param('Source_ID') || param('src_id');
        my $status        = param('Source_Status');
        my $split_type    = param('split_type');
        my $repeat_factor = param('DBRepeat');
        my $amount        = param('amount');
        my $units         = param('units');
        my $fk_lib_name   = param('FK_Library__Name') || get_Table_Param( -table => 'Library', -field => 'FK_Library__Name', -dbc => $dbc );
        my $lib_name      = get_FK_ID( $dbc, "FK_Library__Name", $fk_lib_name );

        if ( param('Create container') ) {
            my $src = alDente::Source->new( -source_id => $source_id, -dbc => $dbc );
            $src->create_source_container( -library_name => $fk_lib_name );
        }
        elsif ( param('Associate Library') ) {
            my $src = alDente::Source->new( -source_id => $source_id, -dbc => $dbc );
            $src->associate_library( -library_name => $lib_name );
        }

    }
    elsif ( param('Create New Source') ) {
        require alDente::Submission_App;
        my $plate_id      = param("Scanned ID");
        my $sample_origin = param('Sample_Origin');

        my $diagnostics_app = alDente::Submission_App->new( PARAMS => { dbc => $dbc } );
        my $output = $diagnostics_app->create_new_source( -dbc => $dbc, -plate_id => $plate_id, -sample_origin => $sample_origin );

=begin
    	my $library = get_Table_Param(-table=>'Library',-field=>'Library_Name');
	    $library = &get_FK_ID($dbc,"FK_Library__Name",$library) if $library;
    	$plate_id = &get_aldente_id($dbc,$plate_id,"Plate") if $plate_id;

    	my $original_source_id = get_Table_Param(-table=>'Original_Source',-field=>'Original_Source_ID') || param('Sample_Origin');
	    my %grey = ();
    	my %list = ();
	    my %omit = ();
    	my %preset = ();
	    $preset{'Source.Received_Date'} = &today();

    	if ($plate_id) {
	        $grey{'Source.FKSource_Plate__ID'} = $plate_id;
    	}
	    if ($library) {
	        $grey{'Library_Source.FK_Library__Name'} = $library;
    	    ($original_source_id) = $dbc->Table_find("Library","FK_Original_Source__ID","WHERE Library_Name='$library'");
	    }
        if($original_source_id) {
            $grey{'Source.FK_Original_Source__ID'} = $original_source_id;
        }
    	$grey{'FKReceived_Employee__ID'} = $user_id; 
	    $omit{'Source_Number'} = 'TBD';
    	$omit{'FKParent_Source__ID'} = 0;
	    $omit{'Source_Status'}  = 'Active';
    	$omit{'Current_Amount'} = '';
	    my %extra;

    	my @rack_options = &get_FK_info($dbc,'FK_Rack__ID',-condition=>"WHERE Rack_Type <> 'Slot' ORDER BY Rack_Alias",-list=>1);
	    $list{'Source.FK_Rack__ID'} =\@rack_options;
    	$preset{'Source.FK_Rack__ID'} =''; 
	    $extra{'Source.FK_Rack__ID'} = "Slot: " . textfield(-name=>'Rack_Slot',-size=>3);
    	my $form = SDB::DB_Form->new(-dbc=>$dbc,-table=>'Source',-add_branch=>['Library_Source'],-target=>'Database');
	    $form->configure(-list=>\%list,-grey=>\%grey, -omit=>\%omit,-preset=>\%preset,-extra=>\%extra);
    	$form->generate(-navigator_on=>1,-title=>"Receive New Source");
=cut

    }
    elsif ( param('New Library Source') ) {
        my %parameters;    # = Set_Parameters();

        my $library = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
        my $source_id = param("Scanned ID");
        $source_id = &get_aldente_id( $dbc, $source_id, "Source" ) if $source_id;
        my %grey = ();
        my %list = ();

        ## determine the list of sources available for association with this library
        my @sources = ();

        if ($source_id) {
            @sources = ($source_id);
        }
        elsif ($library) {
            my $sources = &alDente::Source::get_Original_Sources( -dbc => $dbc, -lib => $library, -frmt => 1 );
            my $org_srcs = join ',', @{$sources} if $sources;
            @sources = $dbc->Table_find( "Source LEFT JOIN Library_Source ON FK_Source__ID=Source_ID AND FK_Library__Name='$library'", 'Source_ID', "where FK_Original_Source__ID IN ($org_srcs) AND FK_Library__Name IS NULL" );
            Message("Only available options include other sources from same original source which have NOT already been associated to this Library");
            unless (@sources) { Message("No applicable sources available that are not already associated with this library"); return 1; }
        }
        else {
            Message("associate from source itself or library");
            return 1;
        }

        my @source_names;
        foreach my $source (@sources) {
            push( @source_names, get_FK_info( $dbc, "FK_Source__ID", $source ) );
        }

        $grey{'Library_Source.FK_Library__Name'} = $library;
        $list{'Library_Source.FK_Source__ID'}    = \@source_names;

        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Library_Source', -target => 'Database', -mode => 'Normal' );
        $form->configure( -list => \%list, -grey => \%grey );
        $form->generate( -title => "Associate Library with a Source" );
    }
    elsif ( param('Receive New Source for Library') ) {
        ##grey out the appropriate fields
        my $library = param('Library.Library_Name');
        my %grey    = ();
        my %preset  = ();
        $grey{FKReceived_Employee__ID} = $user_id;
        $preset{Source_Number}         = 'TBD';
        ## preset the appropriate fields
        $preset{FK_Library__Name} = $library;
        $grey{FK_Library__Name}   = $library;
        ## Generate a source form
        my $source_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -target => 'Database' );
        $source_form->configure( -grey => \%grey, -preset => \%preset );
        $source_form->generate();

    }
    elsif ( param('Transform to Agar') ) {

        my $plate_format = param('Target Plate Format');
        if ($plate_format) {
            if ( $plate_format =~ /^(\d+):(.*)\s/ ) { $plate_format = $1; }
            Message("Transforming to $plate_format");

            #    my $plate_size = param('Daughter Size');
            #    Message("Note","New Plate Added to Database and Barcode generated");
            $current_plates = param('Single Well Plate');

            #    Message("Current: $current_plates");
            my $quadrants = param('Daughters');
            &alDente::Plate::transform_plates( $current_plates, $plate_format );
        }
        else { $dbc->warning("No Target Plate Format specified"); }

        my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
        print $Set->Set_home_info( -brief => $scanner_mode );

        #	&alDente::Plate::homeplateset_footer();
    }
    elsif ( param('Re-Set Available Quadrants') ) {

        my $daughters = param('Daughters');
        my $sub_qs    = param('Sub Quadrants');
        my $plates    = param('384 Well Plate') || $current_plates;
        my $type      = param('Plate_Type');

        ### use new DB_Object to reset values.. ###
        #print "Reset values (not written up yet... )";
        Message("Sub-quadrants reset to '$sub_qs'<BR>");
        if ( $plates && $type =~ /library/i ) {
            my $Library_Plate = new alDente::Library_Plate( -dbc => $dbc, -plate_id => $plates );
            $Library_Plate->reset_SubQuadrants( -quadrants => $sub_qs, -plate_id => $plates );
            print $Library_Plate->home_page( -brief => $scanner_mode );
        }
        else {
            print "Plate not defined";
        }
    }
    elsif ( param('Transfer Plate') ) {

        my $plate_format = param('Transfer Plate');
        my $plate_type   = param('Plate_Type');

        #    my $plate_size = param('Daughter Size');
        if ( param('Parent Plate') ) { $current_plates = &get_aldente_id( $dbc, param('Parent Plate'), 'Plate' ); }
        my $rack = Extract_Values( [ param('FK_Rack__ID'), param('FK_Rack__ID Choice'), param('Location'), param('Location Choice') ] );
        if ( $plate_format && $current_plates ) {
            my $transfers = Extract_Values( [ param('TransferX'), 1 ] );
            my $quadrants = '';
            if ( param('Quadrant') ) {
                $quadrants = extract_range( param('Quadrant') );
            }
            my $source_plate = $current_plates;
            foreach my $index ( 1 .. $transfers ) {
                my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
                my $transferred = $Set->transfer( -plate_type => $plate_type, -format => $plate_format, -quadrants => $quadrants, -rack => $rack );
                $current_plates = $Set->{ids};

                #		&alDente::Plate::transfer_plate($source_plate,$plate_format,$quadrants,$rack);
            }

            #	&transfer_plate($current_plates,$plate_format,undef,$rack);
            Message("Transferred $transfers");
        }
        ## return to main plate(s) pages..
        if ($plate_set) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $current_plates =~ /,/ ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $plate_id || $current_plates ) {
            my $id = $current_plates || $plate_id;
            my $Plate = alDente::Container->new( -dbc => $dbc, -id => $id );
            my $type = $Plate->value('Plate.Plate_Type') || 'Container';
            $type = 'alDente::' . $type;
            my $object = $type->new( -dbc => $dbc, -plate_id => $plate_id );
            $object->home_info( -brief => $scanner_mode );

            #	    if ($Plate && $Plate->{type}=~/library/i) {
            #		my $Library_Plate = Library_Plate->new(-dbc=>$dbc,-plate_id=>$id);
            #		$Library_Plate->LP_home_info(-brief=>$scanner_mode);
            #	    } elsif ($Plate && $Plate->{type}=~/tube/i) {
            #		my $Tube = Tube->new(-dbc=>$dbc,-plate_id=>$id);
            #		$Tube->Tube_home_info(-brief=>$scanner_mode);
            #	    }
        }
        else {
            print "no current plates or plate sets";
            return 0;
        }

    }
    elsif ( param('Transfer Plates To') ) {

        my $plate_format = param('Target Plate Format') || param('FK_Plate_Format__ID');
        my $plate_type   = param('Plate_Type');
        my $rack         = Extract_Values( [ param('FK_Rack__ID'), param('FK_Rack__ID Choice'), param('Location'), param('Location Choice') ] );
        if ($plate_format) {
            my $plate = param('Parent Plate') || param('Parent List');
            if ($plate) { $current_plates = &get_aldente_id( $dbc, $plate, 'Plate' ); }

            #   my $plate_size = param('Daughter Size');
            my $quadrants;
            if ( param('Quadrant') ) {
                $quadrants = extract_range( param('Quadrant') );
            }
            my $transfers = Extract_Values( [ param('TransferX'), 1 ] );
            my $source_plate = $current_plates;
            foreach my $index ( 1 .. $transfers ) {
                my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
                my $transferred = $Set->transfer( -plate_type => $plate_type, -format => $plate_format, -quadrants => $quadrants, -rack => $rack );
                $current_plates = $Set->{ids};

                #		&alDente::Plate::transfer_plate($source_plate,$plate_format,$quadrants,$rack);
            }
        }
        else { $dbc->warning("No Target Plate Format specified"); }

        ## return to main plate(s) pages..
        if ($plate_set) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $current_plates =~ /,/ ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $plate_id || $current_plates ) {
            my $id = $current_plates || $plate_id;
            my $Plate = alDente::Plate->new( -dbc => $dbc, -id => $id );
            my $type = $Plate->value('Plate.Plate_Type') || 'Container';
            $type = 'alDente::' . $type;
            my $object = $type->new( -dbc => $dbc, -plate_id => $plate_id );
            $object->home_info( -brief => $scanner_mode );
        }
        else {
            print "no current plates or plate sets";
            return 0;
        }

    }
    elsif ( param('Store Plate') ) {
        ## Old?
        my $rack = param('Rack') || alDente::Rack::get_rack_parameter( 'FK_Rack__ID', -dbc => $dbc );    ## get_Table_Param(-field=>'FK_Rack__ID');
        if ($rack) {
            if ( $rack =~ /^Rac\d/i ) { $rack = alDente::Validation::get_aldente_id( $dbc, $rack, 'Rack' ) }    ## convert if scanned ..
            my $rack_id = get_FK_ID( $dbc, 'FK_Rack__ID', $rack );
            alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => $current_plates, -rack => $rack_id, -confirmed => 1 );
        }
        else {
            Message("Error: Invalid rack id");
        }

        #	alDente::Container::store($current_plates,param('Rack'));
        return 0;

        #    } elsif (param('Throw Away Plate')) {
        #
        #	my $confirmed = param('Confirmed');
        #	alDente::Container::throw_away(-dbc=>$dbc,-ids=>$current_plates,-confirmed=>$confirmed);
        #	$current_plates='';
        #	return 0;
    }
    elsif ( param('Reagent Applications') ) {
        ### Get list of containers to which reagent has been applied.

        my $reagent  = join ',', param('Solution_ID');
        my $protocol = join ',', param('Protocol_ID');
        my $since = param('AppliedSince');

        print alDente::Form::start_alDente_form( $dbc, 'Applications' );
        print &show_applications( -dbc => $dbc, -solution_id => $reagent, -protocol_id => $protocol, -include_reagents => 1, -since => $since, -form => 'Applications' );

        print submit( -name => 'Last 24 Hours', -value => 'Downstream Cap Seq Summaries', -class => 'Search', -onclick => "SetSelection(this.form,'cgi_application','');" );

        ## add additional link for Illumina using MVC (Last 24 Hours link above still needs to be removed from Button_Options) ##
        print &hspace(5);
        print submit( -name => 'Solexa Runs', -value => 'Downstream Solexa Summaries', -class => 'Search', -onclick => "SetSelection(this.form,'cgi_application','Illumina::Solexa_Summary_App');" );
        ## parameters below only applicable for Illumina run mode at this time ##
        print hidden( -name => 'rm', -value => 'Results', -force => 1 );
        print hidden( -name => 'cgi_application', -value => '', -force => 1 );

        #print hidden(-name=>'Plate_ID',-value=>'0');
        print hidden( -name => 'Any Date', -value => 1 );

        print end_form();
    }
    elsif ( param('Compare Histories') ) {

        my $plate1 = param('Compare 1');
        my $plate2 = param('Compare 2');
        &compare_plate_histories( $dbc, $plate1, $plate2 );
    }

    #    elsif ( param('Sequence Run Diagnostics') ) {
    #			... Moved to SequenceRun::Run_App rm 'Sequence Run Diagnostics'
    #    }
    elsif ( param('Well Colour Map') ) {

        my $LP = new alDente::Library_Plate( -dbc => $dbc );
        $LP->show_Map;
    }
    elsif ( param('Convert_Wells') ) {

        my $source_wells  = param('Source_Wells');
        my $input_format  = param('Input_Format');
        my $output_format = param('Convert_Format');

        #        my $LP = new alDente::Library_Plate(-dbc=>$dbc);
        #	if ($source_wells) {
        alDente::Container_Views::convert_wells( -dbc => $dbc, -source_wells => $source_wells, -input_format => $input_format, -output_format => $output_format );

        #	}
        #	else {
        #	    Message("Please specify wells to convert.");
        #	    $LP->show_well_conversion_tool(-wrap=>1);
        #	}
    }
    elsif ( param('Set Wells from Rearray Sources') ) {

        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        my $plate_id = param('Plate ID');
        $seq_rearray_obj->assign_grows_from_parents( -target_plate => $plate_id );

        #	&alDente::Library_Plate::select_wells('No Grows');
        alDente::Container_Views::select_wells( -dbc => $dbc, -type => 'No Grows' );
    }
    elsif ( param('Transfer to Tube from Plate') ) {
        my @wells           = param('Wells');
        my $parent_plate_id = param('Current Plates');
        my $quantity        = param('Transfer_Quantity');
        my $quantity_units  = param('Transfer_Quantity_Units');
        my $rack            = param('Rack_ID');
        my $new_format_id   = param('New Format');
        my $material_type   = param('FK_Sample_Type__ID');

        &alDente::Container_Set::create_tube_from_plate(
            -wells           => \@wells,
            -parent_plate_id => $parent_plate_id,
            -quantity        => $quantity,
            -units           => $quantity_units,
            -rack            => $rack,
            -new_format_id   => $new_format_id,
            -dbc             => $dbc,
            -material_type   => $material_type
        );

    }
    elsif ( param('Confirm Create Tube from Plate Transfer') ) {

        #print alDente::Form::start_alDente_form($dbc,);

        &alDente::Container_Set::confirm_tube_to_plate_transfer( -dbc => $dbc );
    }
    elsif ( param('ReArray To Plate from Tube') || param('Transfer To Plate from Tube') ) {

        my $type = 'ReArray';
        if ( param('Transfer To Plate from Tube') ) { $type = 'Tray' }

        my @source_plates_selection = param("Source Plates");
        my $plate_format            = param("Plate_Format");
        my $rack                    = param("Rack");
        my $app                     = param('Plate Application');
        my $library                 = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
        my $pipeline_id             = param("Pipeline_ID");

        my @target_wells  = ();
        my @source_plates = ();

        # hash for keeping track of well duplicates
        my %wells_count;
        my $duplicate_wells = 0;
        foreach my $source_plate (@source_plates_selection) {
            my $targetwell_str = param("WellsForPlate${source_plate}");
            foreach my $well ( split( ',', $targetwell_str ) ) {
                if ( defined $wells_count{$well} ) {
                    Message("$well double-defined");
                    $duplicate_wells = 1;
                }
                $wells_count{$well}++;
                push( @source_plates, $source_plate );
                push( @target_wells,  $well );
            }
        }

        # if there are well duplicates, prompt them for wells again
        if ($duplicate_wells) {
            Message("Duplicate wells have been selected. Please reselect wells.");
            my @unique_sources = @{ &unique_items( \@source_plates_selection ) };
            &alDente::Container_Set::tube_transfer_to_plate( -plate_id => join( ',', @unique_sources ), -lib => $library, -rack => $rack, -format => $plate_format, -application => $app, -pipeline_id => $pipeline_id );
            return 1;
        }

        &alDente::Container_Set::create_plate_from_tube(
            -target_wells  => \@target_wells,
            -source_plates => \@source_plates,
            -format        => $plate_format,
            -rack          => $rack,
            -library       => $library,
            -application   => $app,
            -pipeline_id   => $pipeline_id,
            -type          => $type,
            -dbc           => $dbc
        );
    }
    elsif ( param('Transfer Tube To FlowCell_Lane') ) {
        my $application = param('Plate Application');
        my $pipeline    = param('Pipeline_ID');
        my $format      = param('Plate_Format');
        my $action      = param('Action');

        my @plates = param('SourcePlate');

        my %positions;
        my %comments;
        my %loading_conc;
        foreach my $plate_id (@plates) {
            my @positions    = param( 'PlatePosition' . $plate_id );
            my @comments     = param( 'Comments' . $plate_id );
            my @loading_conc = param( 'Scheduled_Concentration' . $plate_id );
            map { $positions{$_} = $plate_id } @positions;

            my $index = 0;
            foreach my $position (@positions) {
                $comments{$position}     = $comments[$index];
                $loading_conc{$position} = $loading_conc[$index];
                $index++;
            }

        }
        my @ordered_plates;
        my @ordered_comments;
        my @ordered_loading_conc;
        foreach ( sort keys %positions ) {
            push @ordered_plates,       $positions{$_};
            push @ordered_comments,     $comments{$_};
            push @ordered_loading_conc, $loading_conc{$_};
        }
        unless ( int(@plates) == int(@ordered_plates) ) {
            Message("Error: Can not store two different samples on the same position of the Flow Cell");
            return;
        }

        my $ordered_plate_list = join ',', @ordered_plates;

        $dbc->start_trans('load_flowcell');
        my $set = alDente::Container_Set->new( -dbc => $dbc, -ids => $ordered_plate_list );
        $set->transfer(
            -type           => $action,
            -format         => $format,
            -pipeline_id    => $pipeline,
            -application    => $application,
            -new_plate_size => '1-well'
        );

        my $Prep = alDente::Prep->new( -dbc => $dbc );
        $Prep->Record( -ids => $ordered_plate_list, -protocol => 'Standard', -step => 'Load to Flowcell', -change_location => 0 );
        $current_plates = $set->{ids};

        ## record the comments on the daughter plates
        my @new_ids       = Cast_List( -list => $set->{ids}, -to => 'Array' );
        my $i             = 0;
        my $container_obj = alDente::Container->new( -dbc => $dbc );
        my %attributes;
        foreach my $id (@new_ids) {
            $container_obj->add_Note( -plate_id => $id, -notes => $ordered_comments[$i], -dbc => $dbc );
            $attributes{$id} = $ordered_loading_conc[$i];
            $i++;
        }

        ## record the suggested loading concentration
        my $API = alDente::alDente_API->new( -dbc => $dbc );

        my $set_loading_conc = $API->set_attribute( -object => 'Plate', -attribute => 'Scheduled_Concentration', -list => \%attributes );

        $dbc->finish_trans('load_flowcell');
        require alDente::Library_Plate;
        my $first_plate = [ split( ',', $current_plates ) ]->[0];
        my $object = alDente::Library_Plate->new( -dbc => $dbc, -plate_id => $first_plate );
        $object->home_page( -brief => $scanner_mode );

    }
    elsif ( param('Confirm Transfer To Plate from Tube') ) {
        &alDente::Container_Set::confirm_create_plate_from_tube( -dbc => $dbc );
    }
    elsif ( param("Rearray Home") ) {

        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        $seq_rearray_obj->sequencing_rearray_home();
    }
    elsif ( param('Submit Modifications') ) {

        # grab parameters for the source plate, keyed by target well
        my $numwells = param("NumWells");
        my %platehash;
        my $prev_plate = "";
        foreach my $count ( 1 .. $numwells ) {

            # resolve '' as 'same as previous'
            if ( param("sourceplate$count") == "''" ) {
                $platehash{ param("targetwell$count") } = $prev_plate;
            }
            else {
                $platehash{ param("targetwell$count") } = param("sourceplate$count");
                $prev_plate = param("sourceplate$count");
            }
        }

        my $request_id      = param('ReArray ID');
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        my $ok              = $seq_rearray_obj->assign_source_plates( -rearray_id => $request_id, -targetwell_to_sourceplate_hash => \%platehash );
        my ($status) = $dbc->Table_find( "ReArray_Request,Status", "Status_Name", "WHERE FK_Status__ID=Status_ID AND ReArray_Request_ID=$request_id" );
        if ($ok) {
            if ( $status eq "Waiting for Primers" ) {
                $seq_rearray_obj->assign_oligo_order( -rearray_id => param('ReArray ID'), -order_num => param('Oligo Order Number'), -sol_id => param('Solution_ID') );
            }
            elsif ( $status eq "Waiting for Preps" ) {
                $seq_rearray_obj->autoset_primer_rearray_status( -rearray_ids => [ param('ReArray ID') ] );
            }
        }
        else {
            Message("FAILED to assign source plates");
        }
        $seq_rearray_obj->seq_view_single_rearray( -request => param('ReArray ID'), -order => 'Order by Target_Well' );
    }
    elsif ( param("Regenerate Primer Order From Primer Plate") ) {

        my @primer_list = param("PlateRow");
        require Sequencing::Primer;
        my $po = new Sequencing::Primer( -dbc => $dbc );
        $po->display_primer_order( -primer_plate_range => join( ',', @primer_list ) );
    }
    elsif ( param("Send Primer Email") ) {

        my $primer_ids = param("Primer Plate ID");
        my $po_number  = param("PO");
        my $split      = param("Split");
        my $type       = param("Filetype");
        require Sequencing::Primer;
        my $po = new Sequencing::Primer( -dbc => $dbc );
        $po->send_primer_email( -primer_plate_ids => $primer_ids, -po_number => $po_number, -split => $split, -type => $type );
        return 0;
    }
    elsif ( param("Generate Multiprobe") ) {

        require Sequencing::Multiprobe;

        my $rearray_ids      = param("Rearray ID");
        my $primer_plate_ids = param("Primer Plate ID");
        my $type             = param("Multiprobe Type");
        my $limit            = param("SourceLimit");

        if ($rearray_ids) {
            foreach my $rearray_id ( split( ',', $rearray_ids ) ) {
                &Sequencing::Multiprobe::write_multiprobe_file( -dbc => $dbc, -rearray_id => $rearray_id, -type => $type, -plate_limit => $limit );
            }
        }
        elsif ($primer_plate_ids) {
            foreach my $primer_plate_id ( split( ',', $primer_plate_ids ) ) {
                &Sequencing::Multiprobe::write_multiprobe_file( -dbc => $dbc, -primer_plate_id => $primer_plate_id, -type => $type, -plate_limit => $limit );
            }
        }
        else {
            Message("ERROR: No Rearray or Primer Plate IDs defined");
        }

        return 0;
    }
    elsif ( param("Mark Primer Plates as Ordered") ) {

        my @primer_list = param("PlateRow");
        my $po = new alDente::Primer( -dbc => $dbc );
        $po->mark_plates_as_ordered( -primer_ids => join( ',', @primer_list ) );
    }
    elsif ( param('Upload Yield Report') ) {

        my $report_fh       = param('Yield Report');
        my $report_type     = param('Yield Report Type');
        my $suppress_print  = param('Suppress_Print');
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        $seq_rearray_obj->process_yield_report( -fh => $report_fh, -type => $report_type, -suppress_print => $suppress_print );
    }
    elsif ( param('Set Primer_Plate Well Status') ) {
        require alDente::Primer;
        my $solutions  = param('Primer Plate Solution ID');
        my $sol_ids    = Cast_List( -list => get_aldente_id( $dbc, $solutions, 'Solution' ), -to => 'string' );
        my $primer_obj = new alDente::Primer( -dbc => $dbc );
        $primer_obj->display_primer_wells( -primer_plate_solution => $sol_ids, -dbc => $dbc );
    }
    elsif ( param('Update_Primer_Well_Status') ) {
        require alDente::Primer;
        my $well_status     = param('Primer_Well_Check');
        my @wells           = param('Wells');
        my $solutions       = param('Primer Plate Solution ID');
        my $set_other_wells = param('Toggle_Primer_Well');

        my $sol_ids = Cast_List( -list => get_aldente_id( $dbc, $solutions, 'Solution' ), -to => 'string' );
        my $wells = Cast_List( -list => \@wells, -to => 'String' );
        my $primer_plate_id = param('Primer_Plates');
        my $primer_obj = new alDente::Primer( -dbc => $dbc );

        $primer_obj->update_primer_well_status( -dbc => $dbc, -primer_plate_id => $primer_plate_id, -wells => $wells, -primer_plate_well_status => $well_status );
        if ($set_other_wells) {
            if ( $well_status eq 'Passed' ) {
                $well_status = 'Failed';
            }
            else {
                $well_status = 'Passed';
            }
            my $padded_wells = Cast_List( -list => [ map { format_well($_) } @wells ], -to => "String", -autoquote => 1 );
            my @toggled_wells = $dbc->Table_find( 'Well_Lookup', 'Plate_96', "WHERE Quadrant = 'a' and Plate_96 NOT IN ($padded_wells)" );
            my $toggled_wells = Cast_List( -list => \@toggled_wells, -to => "String" );
            $primer_obj->update_primer_well_status( -dbc => $dbc, -primer_plate_id => $primer_plate_id, -wells => $toggled_wells, -primer_plate_well_status => $well_status );

        }
        $primer_obj->display_primer_wells( -dbc => $dbc, -primer_plate_solution => $sol_ids );
    }
    elsif ( param('Pick From Qpix') ) {

        my $rearray_obj = new alDente::ReArray( -dbc => $dbc );
        my $target_plate = param('Qpix_Target_plate') || '';
        $target_plate = &get_aldente_id( $dbc, $target_plate, 'Plate' );
        $rearray_obj->pick_from_qpix_log( -target_plate => $target_plate );
    }
    elsif ( param('Confirm Qpix Log') ) {

        my $target_plate  = param('Target_Plate');
        my @source_plates = param('Source_Plates');
        my @source_wells  = param('Source_Wells');
        my @target_wells  = param('Target_Wells');
        my @logfiles      = param('Logfiles');
        my $rearray_obj   = new alDente::ReArray( -dbc => $dbc );
        $rearray_obj->confirm_qpix_log_rearray( -target_plate => $target_plate, -source_plates => \@source_plates, -source_wells => \@source_wells, -target_wells => \@target_wells, -logfiles => \@logfiles );
    }
    elsif ( param("Make") ) {
        my $id             = param('id');                                                       ### Plate ID
        my $type           = param('type');
        my $make_type      = param('Make');
        my $plate_id       = param('Plate ID') || param('Plate_ID') || param('Parent Plate');
        my $check_original = '';
        my $orig_src_id;
        if ( $make_type =~ /Define New/i ) {
            $check_original = 0;
        }
        elsif ( $make_type =~ /new Source/i && $plate_id ) {
            ($orig_src_id) = $dbc->Table_find( 'Plate,Library', 'FK_Original_Source__ID', "WHERE FK_Library__Name=Library_Name and Plate_ID IN ($plate_id)" );
            $check_original = 0;
        }
        elsif ( $make_type =~ /Use Current Sample_Origin/i ) {
            $orig_src_id    = param('Original_Source_ID');
            $check_original = 0;
        }
        else { $check_original = 1; }

        ## check to see if a Hybrid Plate Source exists already
        #my @existing_orig_srcs = $dbc->Table_find('Hybrid_Plate_Source', 'FKChild_Original_Source__ID', "WHERE FKParent_Plate__ID = $id");
        #	alDente::Source::make_into_source(-dbc=>$dbc,-id=>$id,-type=>$type);

        alDente::Source::make_into_source( -dbc => $dbc, -plate_id => $id, -type => $type, -check_original => $check_original, -orig_src_id => $orig_src_id );
    }
    elsif ( param('OS Selection') ) {
        Message " Should be Obsolete. Contact LIMS if you see this page";
        my $selection    = param('HOS_name');                                                                                 # if a HOS has been selected
        my $common_OS_id = param('common_OS_id');                                                                             # if SRCs being pooled come from the same OS
        my @pool_ids     = param('Pool_Source_IDS');
        my $type         = param('type');
        my $form_name    = param('form_name');
        my $pool_all     = param('all');
        my @presets      = ( 'FK_Taxonomy__ID', 'FK_Strain__ID', 'Sex', 'Host', 'FK_Contact__ID', 'FK_Barcode_Label__ID' );
        my %pool_info;
        my $sth = $dbc->query( -query => "SHOW TABLES LIKE '$type'", -finish => 0 );
        my @type_table = $sth->fetchrow_array;

        unless (@type_table) {
            $type = '';
        }

        # extract the amounts and units for each SRC to be pooled
        for ( my $i = 0; $i < scalar(@pool_ids); $i++ ) {
            my $src_id = $pool_ids[$i];
            push( @{ $pool_info{src_ids} }, $src_id );
            my ( $src_curr_amnt, $curr_amnt_unit ) = split( ',', param("curr_amnt $i") );
            my $src_pool_amnt = param("pool_amnt $i") || $src_curr_amnt;
            my $src_pool_unit = param("pool_unit $i") || $curr_amnt_unit;

            # populate the hash with information for all sources being pooled
            if ($pool_all) {
                $pool_info{$src_id}{amnt} = $src_curr_amnt;
                $pool_info{$src_id}{unit} = $curr_amnt_unit;
            }
            else {
                $pool_info{$src_id}{amnt} = $src_pool_amnt;
                $pool_info{$src_id}{unit} = $src_pool_unit;
            }
        }

        if ( $selection eq "New Sample_Origin" || $selection eq "Select" ) {
            $pool_info{HOS_lib}{lib_name} = '';
            &alDente::Source::display_source_form( -dbc => $dbc, -tables => "Original_Source,Source,$type", -type => $type, -presets => \@presets, -pool_info => \%pool_info, -form_name => $form_name, -show => 1 );

        }
        elsif ($common_OS_id) {

            # if Sources being pooled come from the same OS (not a HOS)
            $pool_info{os_id} = $common_OS_id;
            &alDente::Source::display_source_form( -dbc => $dbc, -tables => "Source,$type", -type => $type, -pool_info => \%pool_info, -OS_id => $common_OS_id, -form_name => $form_name, -show => 1 );
        }
        else {

            # if user selected a pre-existing HOS
            my ( $HOS_id,         $HOS_name ) = split( ':',  $selection );
            my ( $HOS_identifier, $lib_name ) = split( '--', $selection );

            # store the name of the Library associated with the HOS in the hash for later
            $pool_info{HOS_lib}{lib_name} = $lib_name;
            &alDente::Source::display_source_form( -dbc => $dbc, -tables => "Source,$type", -type => $type, -pool_info => \%pool_info, -OS_id => $HOS_id, -form_name => $form_name, -show => 1 );
        }

    }
    elsif ( param("View Primer Plate") ) {

        require alDente::Primer;
        my $primer_obj = new alDente::Primer( -dbc => $dbc );
        $primer_obj->view_primer_plate( -primer_plate_id => param("Primer Plate ID") );
    }
    elsif ( param('View Primer Plates') ) {

        require alDente::Primer;
        my $primer_status    = param("Primer Plate Status");
        my $from_date        = param("Primer From Date");
        my $notes            = param("Primer Notes");
        my $primer_type      = param("Primer Types");
        my $primer_plate_ids = param("Primer Plate ID");
        my $primer_obj       = new alDente::Primer( -dbc => $dbc );
        $primer_obj->view_primer_plates( -primer_plate_ids => $primer_plate_ids, -primer_status => $primer_status, -from_order_date => $from_date, -notes => $notes, -type => $primer_type );
    }
    elsif ( param('View rearray source plates in one table') ) {

        my $rearray_ids = join ',', param('Rearray IDs');
        my $ro = new alDente::ReArray( -dbc => $dbc );
        $ro->view_rearray_loc( -request => $rearray_ids, -group_all => 1 );
    }
    elsif ( param('View ReArray') ) {

        my $targets          = join ',', param('Target Plates');
        my $rearray_ids      = param("Request IDs");
        my $emp              = param("Employee");
        my $target_libraries = param("Target Library String") || param("Target Library");
        my $from_date        = param("From");
        my $to_date          = param("To");
        my $rearray_type     = param("ReArray Type");
        my $platenum         = param("Plate Number");
        if ( $emp eq "-" ) {
            $emp = 0;
        }
        my ($emp_id) = $dbc->Table_find( "Employee", "Employee_ID", "WHERE Employee_Name like '$emp'" );

        $rearray_ids = &resolve_range($rearray_ids);
        $platenum    = &resolve_range($platenum);
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        my $plate_targets = &get_aldente_id( $dbc, $targets, 'Plate' ) if $targets;
        my $rearray_status = param('ReArray Status');
        $seq_rearray_obj->seq_rearray_status(
            -plate          => $plate_targets,
            -status         => $rearray_status,
            -request_ids    => $rearray_ids,
            -emp_id         => $emp_id,
            -target_library => $target_libraries,
            -from_date      => $from_date,
            -to_date        => $to_date,
            -type           => $rearray_type,
            -platenum       => $platenum
        );
    }
    elsif ( param('Set Up ReArray') ) {

        my $target_plate              = param('Plate ID');
        my $plate_list                = param("Rearray Plates");
        my $target_plate_nomenclature = param('Target Well Nomenclature');
        alDente::ReArray::manually_rearray_plate( -plate => $target_plate, -plate_list => $plate_list, -target_plate_nomenclature => $target_plate_nomenclature );
    }
    elsif ( param('Rearray Summary') ) {

        my $since_date          = param("Rearray From Date") || &date_time('-30d');
        my $library             = param('Summary Library');
        my $exclude_library     = param('Exclude Summary Library');
        my $filter_nonsequenced = param("Remove Nonsequenced Transfers");
        my $sro                 = new Sequencing::ReArray( -dbc => $dbc );
        $sro->seq_rearray_summary( -since_date => $since_date, -library => $library, -exclude_library => $exclude_library, -remove_transfers => $filter_nonsequenced );
    }
    elsif ( param('Expand ReArray View') ) {

        my $rearray_req = param('Request_ID');
        my $order       = '';
        if ( param("Order") ) {
            $order = "Order by " . param("Order");
        }
        else {
            $order = "Order by Target_Well";
        }
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        $seq_rearray_obj->seq_view_single_rearray( -request => $rearray_req, -order => $order );
    }
    elsif ( param('Generate Custom Primer Multiprobe') ) {

        my @primer_ids = param('PlateRow');

        # get unique items
        @primer_ids = @{ &unique_items( \@primer_ids ) };

        # check if all the primer ids are remapped
        require Sequencing::Multiprobe;

        &Sequencing::Multiprobe::prompt_multiprobe_limit( -dbc => $dbc, -primer_plate_id => join( ',', @primer_ids ), -type => "Primer" );

    }
    elsif ( param('Show Remap Summary') ) {

        my @primer_ids = param('PlateRow');

        # get unique items
        @primer_ids = @{ &unique_items( \@primer_ids ) };

        require Sequencing::Primer;
        my $po = new Sequencing::Primer( -dbc => $dbc );
        $po->view_source_remap_primer_plates( -primer_plate_ids => \@primer_ids );
    }
    elsif ( param('Rearray Action') ) {

        my @rearray_reqs = param('Request_ID');

        # get unique items
        @rearray_reqs = @{ &unique_items( \@rearray_reqs ) };
        my $option = param("Rearray View Options");
        my $sro = new Sequencing::ReArray( -dbc => $dbc );

        # error check
        # ALL REARRAYS: Locations, Abort ReArrays
        # Clone ReArrays: Regenerate QPIX File, Show QPIX rack
        # Oligo ReArrays: Regenerate Primer Order File, Generate DNA Multiprobe,Generate Custom Primer Multiprobe,Create Remapped Custom Primer Plate
        # Reserved Rearrays: Apply rearray
        # Assigned: Re-Assign Rearray
        # grab rearray types and status
        my @status_list = $dbc->Table_find( "ReArray_Request,Status", "Status_Name as ReArray_Status", "WHERE FK_Status__ID=Status_ID AND ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
        my @type_list = $dbc->Table_find( "ReArray_Request", "ReArray_Type", "WHERE ReArray_Request_ID in (" . join( ',', @rearray_reqs ) . ")" );
        @status_list = @{ &unique_items( \@status_list ) };
        @type_list   = @{ &unique_items( \@type_list ) };

        if ( $option eq "Locations" ) {
            $sro->view_rearray_loc( -request => join( ',', @rearray_reqs ) );
        }
        elsif ( $option eq "Generate ReArray Span-8 csv" ) {
            $sro->display_rearray_link( -request_ids => \@rearray_reqs );
        }
        elsif ( $option eq "View Rearrays" ) {
            $sro->seq_view_single_rearray( -request => join( ',', @rearray_reqs ), -order => "Order by Target_Well" );
        }
        elsif ( $option eq "Group into Lab Request" ) {
            $sro->add_to_lab_request( -request_ids => join( ',', @rearray_reqs ), -employee_id => $user_id );
        }
        elsif ( $option eq 'Regenerate Primer Order File' ) {
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                my $primer_plates = $sro->get_primer_plates( -request_range => join( ',', @rearray_reqs ) );
                require Sequencing::Primer;
                my $po = new Sequencing::Primer( -dbc => $dbc );
                $po->display_primer_order( -primer_plate_range => join( ',', @$primer_plates ) );
            }
            else {
                Message('Can only generate primer orders for Reaction rearrays');
            }
        }
        elsif ( $option eq "Regenerate QPIX File" ) {
            if ( !( ( scalar(@type_list) == 1 ) && ( $type_list[0] =~ /Clone/ ) ) ) {
                Message('Can only generate QPIX control files for Clone rearrays');
            }
            else {
                my $rearray_ids = join( ',', @rearray_reqs );

                # check if the rearrays all exist, and they are all clone rearrays.
                # if they are, generate the qpix layout. Otherwise, go back to original qpix
                my @resultset = $dbc->Table_find( "ReArray_Request", "ReArray_Request_ID,ReArray_Type", "WHERE ReArray_Request_ID in ($rearray_ids)" );
                my $ok_to_generate = 1;
                foreach my $row (@resultset) {
                    my ( $id, $type ) = split ',', $row;
                    if ( $type !~ /Clone/ ) {
                        Message("ReArray Request $id is not a Clone rearray");
                        $ok_to_generate = 0;
                        last;
                    }
                }
                if ($ok_to_generate) {
                    require Sequencing::QPIX;
                    &Sequencing::QPIX::prompt_qpix_options( -dbc => $dbc, -request => $rearray_ids );
                }
            }
        }
        elsif ( $option eq "Show QPIX Rack" ) {
            unless ( ( scalar(@type_list) == 1 ) && ( $type_list[0] =~ /Clone/ ) ) {
                Message('Can only view QPIX racks for Clone rearrays');
            }
            my $rearray_ids = join( ',', @rearray_reqs );
            my $split_quad = param("Split Quadrant");
            require Sequencing::QPIX;
            &Sequencing::QPIX::view_qpix_rack( -dbc => $dbc, -request => $rearray_ids, -split_quadrant => $split_quad );
        }
        elsif ( ( $option eq "Apply Rearrays" ) || ( $option eq "Re-Assign Rearray" ) ) {
            if ( !( ( scalar(@status_list) == 1 ) && ( ( $status_list[0] eq 'Ready for Application' ) || ( $status_list[0] eq 'Barcoded' ) ) ) ) {
                Message('Can only apply Ready or Barcoded rearrays');
            }
            else {
                my $rearray_ids = join( ',', @rearray_reqs );

                # if format is undefined, show an error and return to main rearray page
                # if rack is undefined, show an error and return to main rearray page
                my $rack_id = get_Table_Param( -field => 'FK_Rack__ID', -dbc => $dbc );

                # parse out parameters
                my $plate_size   = param('Plate_Size');
                my $plate_format = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
                my $rack         = '';
                my $status       = param('Plate Status') || 'Active';
                my $application  = param('Plate Application') || 'Sequencing';
                my $quadrant     = param('Quadrant');
                my $library      = get_Table_Param( -field => "FK_Library__Name", -dbc => $dbc );
                my $created      = param("Plate_Created");
                my $location     = param("Location");
                my $pipeline     = get_Table_Param( -field => 'FK_Pipeline__ID', -dbc => $dbc );

                # error check for applying rearrays
                if ( $pipeline !~ /.+/ ) {
                    $dbc->error("Pipeline Not Defined!");
                    return;
                }

                $rack     = get_FK_ID( $dbc, "FK_Rack__ID",     $rack_id );
                $pipeline = get_FK_ID( $dbc, "FK_Pipeline__ID", $pipeline );
                if ( $plate_format !~ /.+/ ) {
                    $dbc->error("Plate Format Not Defined!");
                    return;
                }
                elsif ( $rack_id !~ /.+/ ) {
                    $dbc->error("Plate Location Not Defined!");
                    return;
                }

                # all rearrays must be of the same type
                if ( scalar(@status_list) != 1 ) {
                    $dbc->error("Cannot apply a set of mixed status Rearrays");
                    return;
                }

                # if the option is Apply Rearrays, check to see if all status is Ready for Application
                if ( ( $option eq "Apply Rearrays" ) && ( !( $status_list[0] eq 'Ready for Application' ) ) ) {
                    $dbc->error("Cannot apply non-ready rearrays");
                    return;
                }

                # if the option is Reassign Rearrays, check to see if all status is aborted
                if ( ( $option eq "Re-Assign Rearray" ) && ( ( $status_list[0] eq 'Aborted' ) ) ) {
                    $dbc->error("Cannot reassign aborted rearrays");
                    return;
                }

                $sro->apply_rearrays(
                    -request_ids  => $rearray_ids,
                    -size         => $plate_size,
                    -format       => $plate_format,
                    -rack         => $rack,
                    -status       => $status,
                    -application  => $application,
                    -quadrant     => $quadrant,
                    -library      => $library,
                    -created_date => $created,
                    -location     => $location,
                    -pipeline     => $pipeline
                );

                # custom for Sequencing
                if ( $Current_Department =~ /Cap_Seq/i ) {
                    foreach (@rearray_reqs) {
                        $sro->assign_grows_from_parents( -request_id => $_ );
                    }
                }
            }
        }
        elsif ( $option eq "Generate DNA Multiprobe" ) {
            require Sequencing::Multiprobe;
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                my $id_list = join( ',', @rearray_reqs );
                &Sequencing::Multiprobe::prompt_multiprobe_limit( -dbc => $dbc, -rearray_id => $id_list, -type => "DNA" );
            }
            else {
                Message('Can only generate Multiprobe control files for Reaction rearrays');
            }
        }
        elsif ( $option eq "Generate Custom Primer Multiprobe" ) {
            require Sequencing::Multiprobe;
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                my $id_list = join( ',', @rearray_reqs );
                &Sequencing::Multiprobe::prompt_multiprobe_limit( -dbc => $dbc, -rearray_id => $id_list, -type => "Primer" );
            }
            else {
                Message('Can only generate Multiprobe control files for Oligo rearrays');
            }

        }
        elsif ( $option eq "Create Remapped Custom Primer Plate" ) {
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                my $confirm = param('Confirm');
                if ( !($confirm) ) {
                    $sro->confirm_remap_primer_plate( -rearray_ids => \@rearray_reqs );
                }
                else {
                    foreach my $id (@rearray_reqs) {
                        my $primer_plate_name = param("Primer_Plate_Name_${id}");
                        my $notes             = param("Notes_${id}");
                        $sro->remap_primer_plate_from_rearray( -rearray_id => $id, -primer_plate_name => $primer_plate_name, -notes => $notes );
                    }
                }
            }
            else {
                Message('Can only remap Reaction rearrays');
            }
        }
        elsif ( $option eq "Primer Plate Summary" ) {
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                $sro->seq_view_rearray_primer_plates( -rearray_ids => \@rearray_reqs );
            }
            else {
                Message('Can only generate summary for Reaction rearrays');
            }
        }
        elsif ( $option eq "Source Plate Count" ) {
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                $sro->seq_view_source_plate_count( -rearray_ids => \@rearray_reqs );
            }
            else {
                Message('Can only generate summary for Reaction rearrays');
            }
        }
        elsif ( $option eq "Source Primer Plate Count" ) {
            if ( ( scalar(@type_list) == 1 ) && ( $type_list[0] eq 'Reaction Rearray' ) ) {
                $sro->seq_view_primer_plate_count( -rearray_ids => \@rearray_reqs );
            }
            else {
                Message('Can only generate summary for Reaction rearrays');
            }
        }
        elsif ( $option eq "Abort Rearrays" ) {
            my $rearray_ids = join( ',', @rearray_reqs );
            my ($status_id) = $dbc->Table_find( "Status", "Status_ID", "WHERE Status_Name like 'Aborted'" );
            $dbc->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID in ($rearray_ids)" );
            Message("Aborted Rearrays ($rearray_ids)");
        }
        elsif ( $option eq "Move to Completed" ) {
            if ( !( ( scalar(@status_list) == 1 ) && ( $status_list[0] eq 'Barcoded' || $status_list[0] eq 'Ready for Application' ) ) ) {
                Message('Can only complete Assigned rearrays');
            }
            else {
                my $rearray_ids = join( ',', @rearray_reqs );
                my ($status_id) = $dbc->Table_find( "Status", "Status_ID", "WHERE Status_Name like 'Completed'" );
                $dbc->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID in ($rearray_ids)" );
                Message("Completed Rearrays ($rearray_ids)");
            }
        }
    }
    elsif ( param('Display Link Rearray Plates') ) {

        my $req_ids         = param("Request IDs");                      # the rearray to link
        my @request_ids     = split ',', $req_ids;
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        $seq_rearray_obj->display_rearray_link( -request_ids => \@request_ids );
    }
    elsif ( param('Link Rearray Plates') ) {

        my @request_ids = param("Request_ID");
        my $plate_str   = param("Plate_ID");

        # resolve barcodes
        my @plate_ids = split( ',', &get_aldente_id( $dbc, $plate_str, 'Plate' ) );
        @plate_ids = @{ &unique_items( \@plate_ids ) };
        my $seq_rearray_obj = new Sequencing::ReArray( -dbc => $dbc );
        $seq_rearray_obj->match_source_plates( -request_ids => \@request_ids, -plate_ids => \@plate_ids );
    }
    elsif ( param('Write to File') ) {
        my $dbc                = $Connection;
        my @rearrays           = param('Request_ID');
        my $split_files        = param('Split Files');
        my $filetype           = param("Filetype");
        my $split_quad         = param("Split Quadrant");
        my $split_source_plate = param('Number_Of_Source_Plates');

        my $filename = "";
        require Sequencing::QPIX;

        foreach my $rearray_req (@rearrays) {

            &Sequencing::QPIX::write_qpix_to_disk( -dbc => $dbc, -plate_limit => $split_source_plate, -type => $filetype, -rearray_ids => $rearray_req, -split_quadrant => $split_quad, -split_files => $split_files );
            &Sequencing::QPIX::view_qpix_rack( -dbc => $dbc, -request => $rearray_req, -split_quadrant => $split_quad, -plate_limit => $split_source_plate );
        }

        return 0;
    }
    elsif ( param('Edit ReArray Row') ) {

        my %configs;

        # get information to be filled out
        my $id = param('ReArray_ID');
        my @info = $dbc->Table_find( 'ReArray', 'Source_Well,Target_Well,FK_Clone__ID,FK_ReArray_Request__ID', "WHERE ReArray_ID=$id" );
        my ( $source_well, $target_well, $clone_id, $request_id ) = split ',', $info[0];
        $configs{grey}{Source_Well}            = $source_well;
        $configs{grey}{Target_Well}            = $target_well;
        $configs{grey}{FK_Clone__ID}           = $clone_id;
        $configs{grey}{FK_ReArray_Request__ID} = $request_id;
        &SDB::DB_Form_Viewer::Table_search_edit( $dbc, 'ReArray', $id, undef, undef, \%configs );
    }
    elsif ( param('Specify ReArray Wells') ) {

        my $plate_size          = param('Plate Size');
        my $rearray_size_format = param('ReArray Well Nomenclature');
        my $target_plate        = param('Plate ID');
        my $source_plates       = param('ReArrayed From');
        my $include_primers     = param('Specify Primers');
        my $dbc                 = $Connection;
        if ( $source_plates =~ /pla/i ) {

            # parse source plates if they have pla prefixes
            # remove leading zeros
            $source_plates =~ s/pla[0]+/pla/gi;

            # replace pla with ,
            $source_plates =~ s/pla/,/gi;
            $source_plates =~ s/-,/-/g;

            # remove leading comma
            $source_plates =~ s/^,//;
            $source_plates = &extract_range($source_plates);
        }
        else {
            $source_plates = &extract_range($source_plates);
        }

        # get the total number of wells that the source plates have if ReArray Total is not defined
        my $number = 96;

        # get the maximum target number
        my $max_number = 384;
        if ( $plate_size =~ /(\d+).*/ ) {
            $max_number = $1;
        }

        my $min_source_size = '96-well';
        if ( param('ReArray Total') ) {
            if ( param('ReArray Total') <= $max_number ) {
                $number = param('ReArray Total');
            }
            else {
                $number = $max_number;
            }
        }
        else {
            $number = 0;
            my @sizes = $dbc->Table_find_array( 'Plate', ['Plate_Size'], "where Plate_ID in ($source_plates)" );
            foreach my $size (@sizes) {
                if ( $size =~ /(\d+).*/ ) {
                    $number += $1;
                }
            }
            $number = $max_number if ( $number > $max_number );
            if ( scalar( grep {/384/} @sizes ) ) {
                $min_source_size = '384-well';
            }
        }

        # see if the source plates are all 96-well plates. If they are, then the range should be 96-well
        my $source_wells = &extract_range( param('From Wells'), ",", "H" );

        alDente::ReArray::specify_rearray_wells( $dbc, $number, $source_plates, $source_wells, $rearray_size_format, $plate_size, $include_primers );
    }
    elsif ( param('Save ReArray Details') ) {

        # extract all information to create a plate
        # parse out parameters
        #my $actual_plate_size = param('Size');
        my $plate_format = get_Table_Param( -field => 'FK_Plate_Format__ID', -dbc => $dbc );
        my $rack         = get_Table_Param( -field => 'FK_Rack__ID',         -dbc => $dbc );
        my $status      = param('Plate Status')      || 'Active';
        my $application = param('Plate Application') || 'Sequencing';
        my $quadrant    = param('Quadrant');
        my $library = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
        $library = get_FK_ID( $dbc, 'FK_Library__Name', $library );
        my $created        = param("Created");
        my $rearray_format = param('ReArray Format');
        my $double_print   = param("Print Two Labels");
        my $pipeline       = get_Table_Param( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc );
        $pipeline = get_FK_ID( $dbc, "FK_Pipeline__ID", $pipeline );
        my $specify_primers = param('ReArray Primer 1');
        my $rearray_obj = new alDente::ReArray( -dbc => $dbc );

        my $target_plate;
        if ( param('Target Plate') ) {
            my $target = param('Target Plate');
            $target_plate = get_aldente_id( $dbc, $target, 'Plate' );
            Message("Got $target_plate ($target)");
        }
        else {
            $target_plate = $rearray_obj->create_rearray_plate(
                -size         => $rearray_format,
                -format       => $plate_format,
                -rack         => $rack,
                -quadrant     => $quadrant,
                -created      => $created,
                -library      => $library,
                -format       => $plate_format,
                -double_print => $double_print,
                -pipeline     => $pipeline
            );    ##### first create the blank plate ....
        }

        #	my $number = param('ReArray Total');

        my @target_wells = ();

        my $plate_size = param('Actual Plate Size');

        my $number;
        foreach my $name ( param() ) {
            if ( $name =~ /ReArray Plate (\d+)/ ) {
                my $index = $1;
                if   ( param("Ignore $index") ) { next; }
                else                            { $number++; }
            }
        }

        # get all the wells and their quadrant if necessary
        my $prev_quad = '';
        for ( my $index = 1; $index <= $number; $index++ ) {
            my $target_well = param("Target Well $index");
            $target_well = uc( format_well($target_well) );

            # if quadrant is specified, convert to 384-well notation
            if ( ( $plate_size =~ /384.*/ ) && ( $rearray_format =~ /96.*/ ) ) {
                my $target_quad = param("Target Quadrant $index");
                if ( $index == 1 ) {
                    $prev_quad = $target_quad;
                }
                elsif ( $target_quad eq "''" ) {
                    $target_quad = $prev_quad;
                }
                my $wells = &alDente::Well::well_convert( -dbc => $dbc, -wells => "$target_well", -quadrant => $target_quad, -source_size => '96', -target_size => '384' );
                ($target_well) = split ',', $wells;
                $target_well = uc( format_well($target_well) );
                $prev_quad   = $target_quad;
            }
            push( @target_wells, $target_well );
        }
        my $newid = alDente::ReArray::save_rearray_info( $dbc, $target_plate, $rearray_format, \@target_wells, -include_primers => $specify_primers );
        $rearray_obj->update_plate_sample_from_rearray( -request_id => $newid );
    }
    elsif ( param('Continue Process') ) {

        if ($protocol) { plate_next_step( $current_plates, $plate_set ); }
        else           { Message("No Protocol Specified"); }
        $plate_set ||= param('Plate_Set_Number');
        if ($plate_set) {

            #    &alDente::Plate::homeplateset_footer();
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
    }
    elsif ( param('Skip Step') ) {

        my $step  = param('Step Name');
        my $notes = param('Mark Note');
        skip_step( $step, $notes );
    }
    elsif ( 0 && param('Continue Prep') ) {

        $protocol = param('Protocol');
        $plate_set ||= param('Plate_Set_Number');
        if ( $plate_set =~ /new/i ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
            $plate_set = $Set->save_Set( -force => 1 );
        }

        my $batch_edit = param('Batch_Edit');
        if ( $plate_set && $batch_edit ) {

            my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -plates => $current_plates );
            $Prep->check_Protocol();
        }
        else {
            use alDente::Prep;

            #require &alDente::Prep;  ## <CONSTRUCTION> - WHY is this necessary ??
            my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -plates => $current_plates );

            print $Prep->prompt_User();
        }
        if ($plate_set) {    ## re-post container set options ..
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        return 1;
    }

    elsif ( param('Freeze Protocol') ) {
        $dbc->Benchmark('starta_freeze');

        Message("Un freezing");
        $dbc->Benchmark('start_freeze');

        #my $encoded = param('Freeze Protocol');
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        ## <CONSTRUCTION>  ..?? ##
        #	if (UNIVERSAL::isa('Prep','can')) { print "YES"; } else { print "NO"; }

        my $Prep2 = HTML_Table->new();

        use alDente::Prep;    ### <CONSTRUCTION> - Why is this necessary ??
        my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -encoded => $encoded, -input => \%Input );
        $dbc->Benchmark('new_prep');
        my $prompted = $Prep->prompt_User unless $Prep->prompted();

        $dbc->Benchmark('deep_freeze');
        unless ($prompted) {
            ## return to main plate(s) pages..
            if ($plate_set) {
                my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
                print $Set->Set_home_info( -brief => $scanner_mode );
            }
            elsif ( $current_plates =~ /,/ ) {
                my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
                print $Set->Set_home_info( -brief => $scanner_mode );
            }
            elsif ( $plate_id || $current_plates ) {
                my $id = $current_plates || $plate_id;
                my $Plate = alDente::Container->new( -dbc => $dbc, -id => $id );
                my $type = $Plate->value('Plate.Plate_Type') || 'Container';
                $type = 'alDente::' . $type;
                my $object = $type->new( -dbc => $dbc, -plate_id => $plate_id );
                $object->home_page( -brief => $scanner_mode );
            }
            else {
                print "no current plates or plate sets";
                return 0;
            }
        }
        $dbc->Benchmark('end_freeze');
        return 1;
    }
    elsif ( param('New Primer Stock') ) {

        my $primer_name = param('Standard Primer Name');
        if ( $primer_name eq '- Select Primer -' ) {
            Message("Please select a primer name");

            #  &solution_main;
            return;
        }
        &alDente::Stock::ReceiveStock( -dbc => $dbc, name => $primer_name, type => 'Reagent', subtype => 'Primer', fix_name => 1 );
    }
    elsif ( param('Prep Solution') ) {

        &prep_solution;
    }
    elsif ( param('Transfer Solution') || param('Aliquot Solution') || param('Decant Solution') ) {

        my $id         = param('Solution_ID') || $solution_id;
        my $quantity   = param('Dispense Qty');
        my $units      = param('Dispense Units');
        my $containers = param('Containers');
        my $location   = param('FK_Rack__ID') || param('FK_Rack__ID Choice');

        #	my $no_barcode = param('No Barcode');
        my $empty  = param('Transfer Solution');
        my $decant = param('Decant Solution');
        my $label  = param('FK_Barcode_Label__ID') || param('FK_Barcode_Label__ID Choice');

        if ( $label && $quantity && $label !~ /Select/i ) {
            ($quantity) = &convert_to_mils( $quantity, $units );
            dispense_solution( -dbc => $dbc, -sol_id => $id, -total => $quantity * $containers, -bottles => $containers, -decant => $decant, -empty => $empty, -store => $location, -label => $label );
        }
        else {
            $dbc->error("Barcode Label or Quantity is mandatory");
        }
        return;
    }
    elsif ( param('Receive BoxSamples') ) {

        my $boxes = join ',', param('Box_ID');
        $boxes ||= param('Box ID') || param("FK_Box__ID");

        foreach my $box_id ( split ',', $boxes ) {

            # open box if not opened yet.
            &alDente::Box::open_box( -dbc => $dbc, -box_id => $box_id );
            my $search_by = param('Stock_Search_By');
            my $samples = join ',', param('BoxSample');
            Message("Extracting Items from Box $box_id..");
            foreach my $sample ( split ',', $samples ) {
                unless ( $sample =~ /[1-9]/ ) {next}
                my $lot        = param("Lot$sample");
                my $number     = param("NinB$sample");
                my $obtained   = param("Rcvd$sample") || &today();
                my $expired    = param("Expy$sample");
                my $rack       = param("Rack$sample") || param("Rack$sample Choice") || 0;
                my $cost       = param("Cost$sample") || 0;
                my $label      = param("Label$sample") || 0;
                my $catalog_id = param("catalog_id$sample");

                my $grpName = param("Grp$sample");
                my $grp = get_FK_ID( $dbc, 'FK_Grp__ID', $grpName ) || 0;

                my $org = param("Org$sample") || 0;
                if ( $number && $rack ) {
                    alDente::Stock::ReceiveBoxItems(
                        -dbc        => $dbc,
                        -box        => $box_id,
                        -employee   => $user_id,
                        -date       => $obtained,
                        -sample     => $sample,
                        -lot        => $lot,
                        -number     => $number,
                        -rack       => $rack,
                        -cost       => $cost,
                        -label      => $label,
                        -grp        => $grp,
                        -expired    => $expired,
                        -catalog_id => $catalog_id
                    );
                }
                else {
                    Message("Error: Require Rack, Lot Number and Number Received");
                }
            }
        }
        my $bo = new alDente::Box( -dbc => $dbc, -id => $boxes );
        $bo->home_page();
    }
    elsif ( param('BoxSample') ) {

        my $search_by = param('Stock_Search_By');
        my $cat       = param('Catalog_Number');
        my $name      = param('Stock_Catalog_Name');
        if ( !$cat && !$name ) {
            if ( $search_by =~ /By_Cat_Num/i ) {
                $cat = param('Stock_Search_String');
            }
            elsif ( $search_by =~ /By_Name/i ) {
                $name = param('Stock_Search_String');
            }
        }
        my $samples = join ',', param('BoxSample');
        foreach my $sample ( split ',', $samples ) {
            &ReceiveStock( -dbc => $dbc, cat => $cat, name => $name, sample => $sample );
        }
    }
    elsif ( param('Incoming') ) {

        my $search_by = param('Stock_Search_By');
        my $cat       = param('Catalog_Number');
        my $name      = param('Stock_Catalog_Name');
        my $fix_name  = param('Fix_Name');

        if ( !$cat && !$name ) {
            if ( $search_by =~ /By_Cat_Num/i ) {
                $cat = param('Stock_Search_String');
            }
            elsif ( $search_by =~ /By_Name/i ) {
                $name = param('Stock_Search_String');
            }
        }
        my $sample = param('Sample');
        &ReceiveStock( -dbc => $dbc, cat => $cat, name => $name, sample => $sample, fix_name => $fix_name );
    }
    elsif ( param('List Equipment Names') ) {

        my $type = param('Equipment_ Type');
        my @names = $dbc->Table_find( 'Equipment', 'Equipment_ID,Equipment_Name', "where Equipment _Type = '$type' Order by Equipment_Name", 'Distinct' );
        print "<B>Current $type records:</B><BR>";
        foreach my $equip (@names) {
            if ( $equip =~ /(\d+),(.*)/ ) {
                my $id   = $1;
                my $name = $2;
                print &Link_To( $dbc->config('homelink'), $name, "&Info=1&Table=Equipment&Field=Equipment_Name&Like=$name", 'blue', ['newwin'] ) . " (<Span size=small>" . get_FK_info( $dbc, 'FK_Equipment__ID', $id ) . "</span>)<BR>";
            }
            else { print "Fail $equip.<BR>"; }
        }

    }
    elsif ( param('Save Original Stock') ) {

        my $type     = param('Stock_Type') || param('Misc Item Type');
        my $stock    = param('Stock ID')   || param('Stock_ID');
        my $group_id = param('FK_Grp__ID') || param('FK_Grp__ID Choice');
        unless ( save_original_stock( $type, $stock, $group_id ) ) { original_stock( $type, $stock ); }
    }
    elsif ( param('Save Original Solution') ) {

        unless ( save_original_solution( param('Solution_ID') ) ) {
            print "Saving...";
            original_solution( param('Solution_ID') );
        }
    }
    elsif ( param('Save Original Box') ) {

        unless ( save_original_box( param('Box ID') ) ) { original_box( param('Box ID') ); }
    }
    elsif ( param('Save Original Misc_Item') ) {

        my $sample = param('Misc_Item ID');
        my $type   = param('Misc Item Type');
        unless ( save_original_misc_item( $type, $sample ) ) { original_misc_item($sample); }
    }
    elsif ( param('Save Another Solution') ) {

        original_solution();
    }
    elsif ( param('Add Solution') ) {

        my $mixed_ok = 1;

        #    $mixed_ok = mix_solution(param('Solution_ID'),param('Quantity'),"mL");
        my $sol1 = param('Solution1 Added');
        my $qty1 = param('Quantity1') || 0;
        $mixed_ok *= mix_solution( get_aldente_id( $dbc, $sol1, 'Solution' ), $qty1, "mL" );
        my $Sol = alDente::Solution->new( -id => $sol_mix );
        $Sol->more_solution_info;

        #	print &solution_footer($sol_mix);
    }
    elsif ( param('Use Std Solution') ) {

        my $blocks  = param('Blocks');
        my $blocksX = param('BlocksX');
        my $samples = param('Samples');
        if ( $blocksX && $blocks ) { $samples = $blocks * $blocksX }
        my $type = param('Make Std Solution') || param('Last Solution');
        &make_Solution( $type, $samples, -blocks => $blocks, -block_samples => $blocksX );
    }
    elsif ( param('Mix Solution') ) {

        my $blocks  = param('Blocks');
        my $blocksX = param('BlocksX');
        my $samples = param('Samples');
        if ( $blocksX && $blocks ) { $samples = $blocks * $blocksX }

        #    my $type = param('Make Std Solution') || param('Last Solution');
        my $num = param('Number of Reagents');

        if ( $num =~ /[^\d\s]/ ) {
            $num = 2;
        }

        &make_Solution( undef, $samples, $num );
    }
    elsif ( param('Batch Dilute') ) {

        my $diluted_solutions = param("Diluted Solutions");
        my $water_solution    = param("Water Solution");

        &alDente::Solution::prompt_batch_dilute( -dbc => $dbc, -sol_ids => $diluted_solutions, -water_id => $water_solution );
    }
    elsif ( param('Save Batch Dilute') ) {

        my $diluted_solutions = param("Diluted Solutions");
        my $water_solution    = param("Water Solution");
        my $solution_volume   = param("Solution Volume");
        my $water_volume      = param("Water Volume");
        my @sol_ids           = split( ',', $diluted_solutions );
        my @water_id          = split( ',', $water_solution );

        my $expiry     = param('Expiry');
        my $source     = param('Stock Source');
        my $rack       = param("FK_Rack__ID") || param("FK_Rack__ID Choice");
        my $stock_name = param("Stock_Catalog_Name") || param("Stock_Catalog_Name Choice");
        my $type       = param("Stock_Type Choice");
        my $group      = param("FK_Grp__ID");
        my $barcode_id = param("FK_Barcode_Label__ID");

        $rack = &get_FK_ID( $dbc, "Rack_ID", $rack );
        unless ($rack) {
            ($rack) = $Connection->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name = 'Temporary'" );
        }
        $group      = &get_FK_ID( $dbc, "Grp_ID",           $group );
        $barcode_id = &get_FK_ID( $dbc, "Barcode_Label_ID", $barcode_id );

        &alDente::Solution::batch_dilute(
            -dbc             => $dbc,
            -expiry          => $expiry,
            -sol_ids         => \@sol_ids,
            -water_id        => \@water_id,
            -name            => $stock_name,
            -rack_id         => $rack,
            -type            => $type,
            -group_id        => $group,
            -label_id        => $barcode_id,
            -solution_volume => $solution_volume,
            -solution_unit   => 'uL',
            -water_volume    => $water_volume,
            -water_unit      => 'mL'
        );
    }
    elsif ( param('Apply Solution') ) {

        identify_mixture($sol_mix);
        print h3("Apply to $barcode");
    }
    elsif ( param('Confirm Re-Open') ) {
        my $solution = param('Solution_ID');
        my $rack_id  = param('Rack_ID');
        return alDente::Solution::activate_Solution( -dbc => $dbc, -ids => $solution, -confirm => 1, -rack_id => $rack_id );
    }
    elsif ( param('Store Solution') ) {

        if ( param('Sol Mix') ) {
            store_solution($sol_mix);
        }
        else {
            my $location = param('Location') || param('Location Choice') || param('FK_Rack__ID') || param('FK_Rack__ID Choice');
            store_solution( $solution_id, $location );
        }
        print h3("Storing..");
        return 0;
    }
    elsif ( param('Save Mixture') ) {

        my $name   = param('Name');
        my $expiry = param('Expiry');
        my $loc    = param('Location') || param('Location Choice');
        my $instr  = param('Instructions');
        my $type   = param('Type');
        my $sol_id = save_mixture( $name, $expiry, $loc, $instr, $type );
        if ( !$sol_id ) { Message("Error Saving Mixture"); }

        #    &check_last_page();
    }
    elsif ( param('Save Standard Mixture') ) {

        my $sol_id = &save_standard_mixture();
        if ($sol_id) {

            # print filled out chemistry barcodes
            my $sol = Safe_Thaw( -name => 'Sol_Information', -thaw => 1, -encoded => 1 );
            my @sol_ids = param('Solution Included');
            $sol->{'Solution_ID'} = \@sol_ids;
            my @std_quantities = param('Std_Quantities');
            my @quantities     = ();
            my @units          = ();
            foreach my $qty (@std_quantities) {
                my $unit = 'mL';
                if ( $qty =~ /([\.\d]*)\s*([a-zA-Z]+)/ ) {
                    $qty  = $1;
                    $unit = $2;
                }
                ( $qty, $unit ) = &Get_Best_Units( -amount => $qty, -units => $unit );
                push( @quantities, $qty );
                push( @units,      $unit );
            }
            $sol->{'quantities'}    = \@quantities;
            $sol->{'units'}         = \@units;
            $sol->{'new solutions'} = $sol_id;

            &alDente::Chemistry::print_chemistry_sheet( -sol => $sol );

            return 0;
        }    #### Go home if solution saved ########
        else {
            Message("Error Saving Mixture");
            my $blocks  = param('Blocks');
            my $blocksX = param('BlocksX');
            my $samples = param('Samples');
            if ( $blocksX && $blocks ) { $samples = $blocks * $blocksX }
            my $type = param('Make Std Solution')   || param('Last Solution');
            my $num  = param('Number of Solutions') || 0;
            my $ids  = param('Solution IDs')        || '';
            &make_Solution( $type, $samples, $num, $ids, -suppress => 1 );    ## return to same page...
        }
    }
    elsif ( param('Bottle It') ) {

        &bottle_solution();
    }
    elsif ( param('Empty') ) {

        my $empty_date = param('Empty Date') || param('Bottle Handling Date');
        my @solution;
        if ( param('Solutions') ) {
            @solution = param('Solutions');
        }
        elsif ( param('Barcode') ) {
            @solution = param('Barcode');
        }
        elsif ( param('Solution_ID') ) {
            @solution = param('Solution_ID');
        }
        else {
            @solution = $solution_id;
        }

        my $solution = Cast_List( -list => \@solution, -to => 'String' );
        $solution = &get_aldente_id( $dbc, $solution, 'Solution' );
        &empty( $solution, $empty_date );
        return 0;
    }
    elsif ( param('Open') ) {

        my $open_date = param('Open Date') || param('Bottle Handling Date');
        &open_bottle( $solution_id, $open_date );
        my $Sol = alDente::Solution->new( -dbc => $dbc, -id => $solution_id );
        $Sol->home_page($solution_id);
        return 0;
    }
    elsif ( param('UnOpen') ) {

        my $unopen_date = param('Unopen Date') || param('Bottle Handling Date');
        &unopen( $solution_id, $unopen_date );
        return 0;
    }
    elsif ( param('Empty Bottles') ) {

        my @bottles;
        foreach my $name ( param() ) {
            if ( $name =~ /Select Sol(\d+)/i ) { push( @bottles, $1 ); }
        }
        my $empty_date = param('Empty Date') || param('Bottle Handling Date');

        my $list = join ',', @bottles;
        if ($list) {
            empty( $list, $empty_date );
        }
        else {
            Message("No items selected");
        }
        my $grp     = param('Group') || param('Search Group');
        my $search  = param('Search String');
        my $grp_ids = &get_FK_ID( $dbc, 'FK_Grp__ID', $grp );
        my $date_condition .= " AND DATE_SUB(CURDATE(),INTERVAL 30 DAY) <= Stock_Received";

        my $stock_obj = new alDente::Stock( -dbc => $dbc );
        my $Stock_Info = $stock_obj->find_Stock( -dbc => $dbc, -type => 'solution', -cat_name => $search, -group => $grp_ids, -title => "Finding Reagents/Solutions", -condition => $date_condition );
        print alDente::Stock_Views::display_stock_inventory( -dbc => $dbc, -info => $Stock_Info, -type => 'Solution', -search => $search, -group => $grp_ids );

    }
    elsif ( param('Open Bottles') ) {

        my @bottles;
        foreach my $name ( param() ) {
            if ( $name =~ /Select Sol(\d+)/i ) { push( @bottles, $1 ); }
        }
        my $open_date = param('Open Date') || param('Bottle Handling Date');
        my $list = join ',', @bottles;
        if ($list) {
            &open_bottle( $list, $open_date );
        }
        else {
            Message("No items selected");
        }
        my $grp     = param('Group') || param('Search Group');
        my $search  = param('Search String');
        my $grp_ids = &get_FK_ID( $dbc, 'FK_Grp__ID', $grp );
        my $date_condition .= " AND DATE_SUB(CURDATE(),INTERVAL 30 DAY) <= Stock_Received";
        my $stock_obj = new alDente::Stock( -dbc => $dbc );
        my $Stock_Info = $stock_obj->find_Stock( -dbc => $dbc, -type => 'solution', -cat_name => $search, -group => $grp_ids, -title => "Finding Reagents/Solutions", -condition => $date_condition );
        print alDente::Stock_Views::display_stock_inventory( -dbc => $dbc, -info => $Stock_Info, -type => 'Solution', -search => $search, -group => $grp_ids );

    }
    elsif ( param('Unopen Bottles') ) {

        my @bottles;
        foreach my $name ( param() ) {
            if ( $name =~ /Select Sol(\d+)/i ) { push( @bottles, $1 ); }
        }
        my $unopen_date = param('Unopen Date') || param('Bottle Handling Date');

        my $list = join ',', @bottles;
        if ($list) {
            &unopen( $list, $unopen_date );
        }
        else {
            Message("No items selected");
        }

        my $grp     = param('Group') || param('Search Group');
        my $search  = param('Search String');
        my $grp_ids = &get_FK_ID( $dbc, 'FK_Grp__ID', $grp );
        my $date_condition .= " AND DATE_SUB(CURDATE(),INTERVAL 30 DAY) <= Stock_Received";
        my $stock_obj = new alDente::Stock( -dbc => $dbc );
        my $Stock_Info = $stock_obj->find_Stock( -dbc => $dbc, -type => 'solution', -cat_name => $search, -group => $grp_ids, -title => "Finding Reagents/Solutions", -condition => $date_condition );
        print alDente::Stock_Views::display_stock_inventory( -dbc => $dbc, -info => $Stock_Info, -type => 'Solution', -search => $search, -group => $grp_ids );

    }
    elsif ( param('Save Original Primer') ) {

        save_original_primer();
    }
    elsif ( param('New Kit') ) {

        &SDB::DB_Form_Viewer::add_record( $dbc, 'Box' -groups => $dbc->get_local('group_list') );
    }
    elsif ( param('New Kit') ) {

        &new_box();
    }
    elsif ( param('Edit') ) {

        my $table = param('Edit');

        #    my $prefix = join ',',$dbc->Table_find('Barcode','Prefix',"WHERE Table_Name=\"$table\"");
        &Table_search_edit( $dbc, $table, &get_aldente_id( $dbc, $barcode, $table ) );
    }
    elsif ( param('Add Rack') ) {

        my $racks = param('New Racks')        || 1;
        my $equip = param('FK_Equipment__ID') || param('Equipment');
        my $parent      = param('FKParent_Rack__ID');
        my $cond        = param('Conditions');
        my $type        = param('Rack_Type') || param('Rack_Types') || 'Shelf';
        my $rack_number = param('Rack_Number') || 0;
        my $max_row     = param('Max_Rack_Row') || 0;
        my $max_col     = param('Max_Rack_Col') || 0;

        my $specified_prefix = param('Rack_Prefix') || '';

        $equip = get_aldente_id( $dbc, $equip, 'Equipment' );
        my ($new_rack_id) = &add_rack(
            -dbc              => $dbc,
            -equipment_id     => $equip,
            -conditions       => $cond,
            -number           => $racks,
            -type             => $type,
            -parent           => $parent,
            -specified_prefix => $specified_prefix,
            -rack_number      => $rack_number,
            -max_rack_row     => $max_row,
            -max_rack_col     => $max_col
        );

        if ($parent) {
            Rack_home( $dbc, $new_rack_id );
        }
        else {
            my $object = alDente::Equipment->new( -dbc => $dbc );
            $object->home_info( $equip, $barcode );
        }

        #    &home_equipment($equip,$barcode);
    }
    elsif ( param('Show_Rack_Contents') ) {
        my $rack_id   = param('Rack_ID');
        my $recursive = param('Recursive');

        print Show_Rack_Contents( -dbc => $dbc, -rack_id => $rack_id, -level => 1, -printable => 1, -recursive => $recursive );
    }
    elsif ( param('New Stock') ) {

        my $table = param('New Stock');
        if ( $table =~ /New (.*)/ ) { $table = $1 }

## <CONSTRUCTION>
        ## copy over from DB_Form_viewer for now... put in Stock module ?

        #### Custom Insertion (special forms for new tables... ) ###
        ## <CONSTRUCTION> remove dependency... ##
        #	if ($table=~/^Solution/) { alDente::Solution::original_solution(undef,'Solution'); return 1;}
        #	if ($table=~/^Reagent/) { alDente::Solution::original_solution(undef,'Reagent'); return 1;}
        if ( $table =~ /^Solution/ ) {
            alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Solution', subtype => param('Solution_Type') );
            return 1;
        }
        elsif ( $table =~ /^Reagent/ ) {
            $table = 'Solution';
            &alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Reagent', subtype => param('Solution_Type') );
            return 1;
        }
        elsif ( $table =~ /^Kit/ ) {
            $table = 'Box';
            &alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Kit', subtype => param('Box_Type') );
            return 1;
        }
        elsif ( $table =~ /^Box/ ) {
            &alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Box', subtype => param('Box_Type') );
            return 1;
        }
        elsif ( $table =~ /^Primer$/ ) {
            alDente::Solution::new_primer();
            return 1;
        }
        elsif ( $table =~ /^Equipment/ ) {
            alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Equipment', subtype => param('Equipment_Type') );
            return 1;
        }
        elsif ( $table =~ /^Microarray/ ) {
            alDente::Stock::ReceiveStock( -dbc => $dbc, type => 'Microarray', subtype => param('Array_Type') );
            return 1;
        }
        #### End Custom Insertion (special forms for new tables... ) ###
        else {
            if    ( $table =~ /^Reagent/ ) { $table = 'Solution'; }
            elsif ( $table =~ /^Kit/ )     { $table = 'Box'; }
            &add_record( $dbc, $table, -groups => $dbc->get_local('group_list') );
            return 1;
        }

        #
        # Is original_stock phased out ?? or should we get there from here.. ?
        #
    }
    elsif ( param('Show Equipment Contents') ) {
        my $id = param('Equipment');
        print alDente::Equipment::display_equipment_contents( -id => $id );
        return 1;
    }
    elsif ( param('Machine History') ) {

        my $machine = param('Equipment') || param('Equipment_ID') || param('FK_Equipment__ID');
        my $since          = param('History Since') if param('Go Back Only');
        my $include_matrix = param('Include Matrix Changes');
        my $include_buffer = param('Include Buffer Changes');
        my $include;
        if ($include_matrix) { $include .= "matrix;" }
        if ($include_buffer) { $include .= "buffer;" }

        &alDente::Equipment_Views::equipment_stats( -dbc => $dbc, -find => $machine, -since => $since, -include => $include );
    }
    elsif ( param('Maintenance History') ) {

        my $ids = join ',', $dbc->Table_find( 'Equipment', 'Equipment_ID' );

        ### allow specification of specific piece of equipment ###
        my $Equip_list = join ',', param('Equipment History');
        my $barcode = param('Barcode');
        if ($Equip_list) { $ids = join ',', $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name in ($Equip_list)" ); }
        elsif ($barcode) { $ids = get_aldente_id( $dbc, $barcode, 'Equipment' ); }

        my $since = param('Since') || 0;
        unless ($Equip_list) {
            $since = &date_time( -offset => '-30d' );
        }

        my $include_matrix = param('Include Matrix Changes');
        my $include_buffer = param('Include Buffer Changes');
        my $include;
        if ($include_matrix) { $include .= "matrix;" }
        if ($include_buffer) { $include .= "buffer;" }

        &equipment_stats( -dbc => $dbc, -ids => $ids, -since => $since, -include => $include );    ## only show stats since specified date...
    }
    elsif ( param('List Equipment') ) {
        my $type = param('Equip Type');
        &alDente::Equipment::equipment_list( -type => $type );
    }
    elsif ( param('View Scheduled Maintenance') ) {
        my $type = param('Equip Type');
        my $html = alDente::Equipment::get_scheduled_maintenance( -dbc => $dbc );
        print $html;
        return 1;
    }
    elsif ( param('Edit Equipment') ) {
        print h3("Edit ? equip");
    }
    elsif ( param('Maintenance') ) {

        #    add_record($dbc,'Maintenance');

        my $equip = param('Equipment') || param('Barcode') || $equipment_id;
        $equip = get_FK_ID( $dbc, 'FK_Equipment__ID', $equip );
        &maintenance_home( $dbc, $equip );
    }
    elsif ( param('Change MB') ) {

        my $equip = param('Equipment');
        my $mb    = param('MatrixBuffer');
        &change_MatrixBuffer( $equip, $mb );
        my $equipment = alDente::Equipment->new( -dbc => $dbc );
        $equipment->home_info( $equip, $barcode );
    }
    elsif ( param('Maintenance Update') ) {

        &save_maintenance_procedure();
        return 0;
    }
    elsif ( param('Configure SS Event') ) {

        my %Parameters = (
            'USERNAME'      => 'DUANE',
            'AUTOCOMMENT'   => '1/4 (1079023a.B7) Add extra comments here',
            'COMMENTSTRING' => '',
            'CHEMISTRYCODE' => 'B7',
            'VERSION'       => '',
            'RUNFORMAT'     => '96x4 well',
            'Target'        => 'screen',
            'PLATENAME'     => '1079023a',
            'PLATEID'       => 'MUL01954',
        );
        my $seq_type = param('Sequencer_Type');
        my ($equipment_id) = $dbc->Table_find( 'Machine_Default,Sequencer_Type', 'FK_Equipment__ID', "where FK_Sequencer_Type__ID=Sequencer_Type_ID AND Sequencer_Type_Name like '$seq_type'" );
        my $fback = generate_ss( $dbc, $dbase, '30312', $equipment_id, \%Parameters );
    }
    elsif ( param('Edit_Orphan_FKs') ) {
        &SDB::DB_Form_Viewer::edit_records( $dbc, param('Table'), undef, undef, "where " . param('Field') . " in (" . param('Orphan_FKs') . ")", undef );
    }
    elsif ( param('SendEmail') ) {
        my @depts      = param('email_depts');
        my @access     = param('email_access');
        my $depts      = Cast_List( -list => \@depts, -to => 'string', -autoquote => 1 );
        my $access     = Cast_List( -list => \@access, -to => 'string', -autoquote => 1 );
        my $from       = param('email_from');
        my $cc_address = param('email_cc');
        my $subject    = param('email_subject');
        my $body       = param('email_body');

        $body =~ s/\n/<br>/g;
        my $to_address = join ',',
            $dbc->Table_find(
            'Employee,GrpEmployee,Grp,Department',
            'Email_Address',
            "WHERE Department_ID=Grp.FK_Department__ID AND Grp_ID=FK_Grp__ID AND Employee_ID=FK_Employee__ID AND Department_Name IN ($depts) AND Access IN($access) AND Employee_Status='Active' ORDER BY Employee_Name",
            -distinct => 1
            );
        my ($from_email) = $dbc->Table_find( 'Employee', 'Email_Address', "WHERE Employee_Name='$from'" );
        alDente::Notification::Email_Notification(
            -to_address   => $to_address,
            -from_address => "$from <$from_email" . '@bcgsc.ca>',
            -subject      => $subject,
            -body_message => $body,
            -cc_address   => $cc_address,
            -content_type => 'html',
            -testing      => $dbc->test_mode()
        );
        print h4("Sent email <b>To: </b>$to_address, <b>Cc: </b>$cc_address");

    }
    elsif ( param('Inventory_Home') ) {
        ## dynamically load inventorys
        require alDente::Inventory;
        alDente::Inventory::Inventory_Home();
    }
    elsif ( defined param('GelRun_Request') ) {
        require alDente::GelRun;
        alDente::GelRun::request_broker( -dbc => $dbc );
    }
    elsif ( defined param('GE_Genechip_Run') ) {
        require Lib_Construction::GenechipRun;
        Lib_Construction::GenechipRun::request_broker();
    }
    elsif ( param('Spect_Summary') ) {
        require Lib_Construction::Spect_Summary;
        my $spect_summary = Lib_Construction::Spect_Summary->new();
        print $spect_summary->home_page( -generate_view => 1 );
    }
    elsif ( param('Bioanalyzer_Summary') ) {
        require alDente::View;
        alDente::View::request_broker( -title => 'Bioanalyzer Summary', -dbc => $dbc );
    }
    elsif ( param('Genechip Expression Summary') ) {
        require alDente::View;
        alDente::View::request_broker( -title => 'Genechip Expression Summary' );
    }
    elsif ( param('Genechip Mapping Summary') ) {
        require alDente::View;
        alDente::View::request_broker( -title => 'Genechip Mapping Summary' );
    }
    elsif ( param('Sequencing_Summary') ) {
        require Sequencing::Sequencing_Summary;
        my $seq_summary = Sequencing::Sequencing_Summary->new( -analysis_type => 'Sequencing' );
        Message("Seq custom");
        print $seq_summary->home_page( -generate_view => 1, -dbc => $dbc );
    }
    elsif ( param('Mapping_Summary') ) {

        require alDente::View;
        alDente::View::request_broker( -title => 'Mapping Summary', -filter_by_dept => 1 );

    }
    elsif ( param('Bioanalyzer Summary') ) {

        require alDente::View;
        alDente::View::request_broker( -title => 'Bioanalyzer Summary' );

    }
    elsif ( param('Solexa Summary') ) {

        require alDente::View;
        alDente::View::request_broker( -title => 'Solexa Summary', -filter_by_dept => 1 );

    }
    elsif ( param('Generate Results') ) {

        require alDente::View;
        alDente::View->request_broker( -dbc => $dbc );

    }
    elsif ( param('Project_Statistics') ) {

        require alDente::View;
        alDente::View::request_broker( -title => 'Genechip Statistics' );

    }
    elsif ( param('SolexaRun') ) {
        require Sequencing::SolexaRun;
        Sequencing::SolexaRun::request_broker( -dbc => $dbc );
    }
    elsif ( param('SOLIDRun') ) {
        require SOLID::SOLIDRun;
        SOLID::SOLIDRun::request_broker( -dbc => $dbc );
    }
    elsif ( param('Project_Statistics') ) {

        require alDente::Statistics;

        #my $stat_summary = alDente::Statistics->new();
        my $stat = alDente::Statistics->new( -dbc => $dbc, -type => 'Run' );
        $stat->home_page( -display_page => 1 );
    }
    elsif ( param('Barcode_Event') ) {
        my $event = param('Barcode_Event');
        require alDente::Barcoding;
        return alDente::Barcoding::catch_Barcode_events($event);
    }
    elsif ( param('Parse_ReArray_Wells') ) {

        if ( param('Display_ReArray_Wells') ) {
            alDente::Library_Plate::parse_rearray_options();

        }
        elsif ( param('Display_Transfer_Wells') ) {
            alDente::Library_Plate::parse_transfer_options();

        }
        elsif ( param('ReArray_Wells') ) {
            alDente::Library_Plate::parse_rearray_wells();

        }
        elsif ( param('Create_Rearray') ) {
            alDente::Library_Plate::parse_create_rearray();
        }
    }
    elsif ( param('Transfer_Wells') ) {
        alDente::Library_Plate::parse_transfer_wells();
    }
    elsif ( defined param('Lib_Construction_SpectRun') ) {
        require alDente::SpectRun;
        alDente::SpectRun::request_broker();
    }
    elsif ( defined param('Lib_Construction_BioanalyzerRun') ) {
        require alDente::BioanalyzerRun;
        alDente::BioanalyzerRun::request_broker();
    }
    elsif ( param('Test') ) {
        _test($dbc);
        return 1;
    }
    elsif ( param('AddNewLocation') ) {
        require alDente::Rack;
        print alDente::Rack::add_new_export_locations( -dbc => $dbc );
    }
    elsif ( 0 && param('FormNav') ) {

        ### THIS SHOULD BE MOVED TO A RUN MODE - it is not obvious where this is generated, but this should be investigated so that the logic can be handled through standard MVC processes #####

        my $jsstring = param('FormData');
        require JSON;
        my $obj;
        if (JSON->VERSION =~/^1/) { $obj = JSON::jsonToObj($jsstring) }
        else { $obj = JSON::from_json($jsstring) }
        
        my $data = &SDB::DB_Form::conv_FormNav_to_DBIO_format( -data => $obj, -dbc => $dbc );

        #	$data->{tables}{Branch_Condition}{0}{Object_ID} = '<Primer.Primer_ID>';  ## this fixes the problem of Primer not being retrieved from other form...
        my $sid = param('Submission_ID');

        my $target  = param('FormType');
        my $repeat  = param('DBRepeat');
        my $roadmap = param('roadMap');
        $repeat ||= 1;

        if ( $target =~ /^database$/i ) {
            $dbc->start_trans( -name => 'Form' );
            eval {
                foreach ( 1 .. $repeat )
                {
                    $dbc->Batch_Append( -data => $data );
                }
            };
            $dbc->finish_trans( 'Form', -error => $@ );

            if ( $dbc->transaction()->error() ) {
                my $table = param('Tables');
                my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target );
                $form->{formData} = $obj;
                $form->generate( -roadmap => $roadmap, -navigator_on => 1 );
                return 1;
            }
            else {
                return 0;
            }
        }
        elsif ( $target =~ /^draft$|^submission$/i ) {
            require SDB::Submission;
            require alDente::Submission_Views;
            my $S_View = new alDente::Submission_Views( -dbc => $dbc );

            ### Just like the code in Submission::Redirect @ if(param('FormNav'))
            ### <CONSTRUCTION>

            if ($sid) {
                &SDB::Submission::Modify_Submission( -dbc => $dbc, -data_ref => $obj, -sid => $sid, -roadmap => $roadmap );
                if ( $target eq 'Submission' ) {
                    &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Submitted' );
                    $dbc->message("Submission $sid has been submitted.");
                }
                else {
                    $dbc->warning("Submission $sid has been updated but not submitted yet.");
                }
            }
            else {
                my $draft = $target eq 'Draft' ? 1 : 0;

                my $sid = &SDB::Submission::Generate_Submission( -dbc => $dbc, -data_ref => $obj, -draft => $draft, -roadmap => $roadmap );

                $dbc->message("Submission $sid created.");
            }
            print $S_View ->display_submission_search_form();
            return $S_View->display_submission_search_form();
        }
        elsif ($sid) {
            require SDB::Submission;
            if ( $target =~ /^UpdateSubmission$/i ) {
                return &SDB::Submission::Modify_Submission( -dbc => $dbc, -data_ref => $obj, -sid => $sid, -roadmap => $roadmap );
            }
            elsif ( $target =~ /^ApproveSubmission$/i ) {
                return &SDB::Submission::Load_Submission( -dbc => $dbc, -sid => $sid, -action => 'approve' );
            }
        }
    }
    elsif ( param('Plate Set Number') ) {

        my $plate_set = param('Plate Set Number');

        #   &alDente::Plate::homeplateset_footer();
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
        print $Set->Set_home_info( -brief => $scanner_mode );
    }

#############
    # Home
#############
    elsif ($express) { return 1; }
    else             { return 0; }    ##### no branches... #########
    $dbc->Benchmark('endelse');
    return 1;
}

##############################
# private_methods            #
##############################

#############
#
# Enter custom code to test here
#
#
# (add parameters: &Test=1 after Session parameter in URL to run )
#############
sub _test {
#############
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

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

$Id: Button_Options.pm,v 1.428 2004/12/15 20:19:30 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
