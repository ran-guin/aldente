###############################################################################################################
# MVC_Exceptions
#
# Handle logic for CGI input paramters used for non-MVC logic
#
# This should be minimized, but may be necessary to support custom legacy code
#
# $Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $
##############################################################################################################
package alDente::MVC_exceptions;

use base LampLite::MVC_exceptions;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

=head1 SYNOPSIS <UPLINK>

	Module containing wrapper methods / functions enabling use of non MVC logic (typically old legacy code)

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

use alDente::Form;
use alDente::Info;
use alDente::Web;

use RGTools::RGIO;
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

use LampLite::CGI;
my $q = new LampLite::CGI();

use vars qw($databases $Security %Search_Item $plate_set $current_plates $scanner_mode %Benchmark %Input $plate_id);
##############################################################
# Custom method to handle shortcut run modes not in MVC mode
#
# Ideally, these should be phased out and converted to MVC run modes if possible
#
# Any required methods should be dynamically loaded if possible to simplify main script
#
# Exceptions may exist for certain cases which justify alternative to MVC execution
#
# Return: true if run mode found
########################
sub non_MVC_run_modes {
########################
    my $dbc         = shift;
    my $sid         = shift;
    my $params      = shift;
    my $default_app = shift;
    my $user_id     = $dbc->get_local('user_id');

    my $branched = 0;    ### See if we have found a button to branch to
    if ( $q->param('Home') ) {
        my $home = $q->param('Home') || 'main';
        &main::home($home);
        $branched = 1;
    }
    elsif ( $q->param('App') ) {

    }
    elsif ( $q->param('Re Log-In') ) {
        ## Re Log in ##
        print "\nLog In ";
        $dbc->connect_if_necessary();
        SDB::Errors::log_deprecated_usage('relogin');
        $branched = 1;
    }
    elsif ( $q->param('Help') && $q->param('Search for Help') ) {
        ### Get Help ###
        my $help_topic = $q->param('Help');
        require alDente::Help;    ## dynamic loading ##
        &alDente::Help::SDB_help( $help_topic, -dbc => $dbc );
        $branched = 1;
    }
    elsif ( $q->param('Quick Help') || $q->param('New_Changes') ) {
        my $help_topic = $q->param('Quick Help') || $q->param('New_Changes');
        require alDente::Help;    ## dynamic loading ##
        &alDente::Help::SDB_help($help_topic);
        $branched = 1;
    }

    ### Generate Help Search Prompt ###
    elsif ( $q->param('Online Help') ) {
        require alDente::Help;    ## dynamic loading ##
        print &alDente::Help::Online_help( $q->param('Online Help') );
        $branched = 1;
    }

    if ( $q->param('Remove Message') ) {
        $dbc->connect_if_necessary();
        my $message_list = join ",", $q->param('Message');
        require alDente::Messaging;    ## dynamic loading ##
        my $msg_obj = new alDente::Messaging( -dbc => $dbc );
        foreach my $id ( split ',', $message_list ) {
            $msg_obj->remove_message( -id => $id );
        }
        &main::home('main');
        &main::leave($dbc);
    }
    if ( $q->param("Message Removal Window") ) {
        $dbc->connect_if_necessary();
        require alDente::Messaging;    ## dynamic loading ##
        my $msg_obj = new alDente::Messaging( -dbc => $dbc );
        $msg_obj->show_removal_window( -security_object => $Security );
        $branched = 1;
    }
    ### Search Database
    ## Phased out... in Login_App run mode now...
    elsif ( $q->param('rm') eq 'Search Database' || $q->param('Search Database') ) {
        $dbc->connect_if_necessary();
        ## CONSTRUCTION: phase out usage of Set_Parameters below .. ##
        $dbc->message('search');
        print alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'help' );

        print $q->submit( -name => 'Search Database', -style => "background-color:yellow" ) . " contaiNing: " . $q->textfield( -name => 'DB Search String' ) . $q->end_form();

        my $table  = $q->param('Table');
        my $string = $q->param('DB Search String');
        $dbc->message("Looking for '$string' in Database...");

        #       &Online_help_search_results($string);

        require SDB::DB_Form_Viewer;
        require SDB::HTML;
        import SDB::HTML;

        #my $matches = alDente::Tools::Search_Database( $dbc, $string, \%Search_Item, $table );
        my $Search = alDente::SDB_Defaults::search_fields();
        my $matches = alDente::Tools::Search_Database( -dbc => $dbc, -input_string => $string, -search => $Search, -table => $table );
        if ( $matches =~ /^\d+$/ && !$table ) { print vspace(5) . "$matches possible matches.<BR>"; }
        $branched = 1;
    }

    ### Search for Help ###
    elsif ( $q->param('Search for Instructions') || $q->param('Search for Help') ) {
        $dbc->connect_if_necessary();
        ## CONSTRUCTION: phase out usage of Set_Parameters below .. ##
        print alDente::Form::start_alDente_form( $dbc, 'help', undef );
        print $q->submit( -name => 'Search for Help', -style => "background-color:yellow" ), " containing: ", $q->textfield( -name => 'Help String' ), $q->end_form();

        my $string = $q->param('Help String');
        print h3("Looking for '$string' in online instructions...");
        require alDente::Help;    ## dynamic loading ##
        &alDente::Help::Online_help_search_results( $string, -dbc => $dbc );
        $branched = 1;
    }

    ### Branch to Admin Page ###
    elsif ( $q->param('Admin Page') ) {
        $dbc->connect_if_necessary();
        my $department = $q->param('Admin Page');
        require alDente::Admin;    ## dynamic loading
        &alDente::Admin::Admin_page( -dbc => $dbc, -department => $department );
        $branched = 1;
    }

    ### Generate Command to Re-Analyze Runs ###
    elsif ( $q->param('Re-Analyze Runs') ) {
        $dbc->connect_if_necessary();
        my $run_ids = join ',', $q->param('RunIDs');
        $run_ids = extract_range($run_ids);
        ## CONSTRUCTION: change to dynamic loading... ##
        &ReAnalyzeRuns( $dbc, $run_ids );
        &Admin_page( -dbc => $dbc );
        $branched = 1;
    }

    ### Go to Bugs page ###
    #elsif (param('Bugs')) {#
    #&add_suggestion();
    #$branched = 1;
    #}
    ### Go to Issues page ###
    elsif ( $q->param('Issues_Home') ) {
        $dbc->connect_if_necessary();
        require alDente::Issue;    ## dynamic loading ##
        &alDente::Issue::Issues_Home($dbc);
        $branched = 1;
    }
    elsif ( $q->param('Standard Page') ) {
        my $page = $q->param('Standard Page');
        return &alDente::Info::GoHome( $dbc, 'Standard Page', $page );
    }
    elsif ( $q->param('Continue Prep') ) {

        $dbc->connect_if_necessary();
        my $protocol = $q->param('Protocol');

        my $plate_set ||= $q->param('Plate_Set_Number');
        my $current_plates ||= $q->param('Plate_IDs');

        my $batch_edit = $q->param('Batch_Edit');

        require alDente::Container_Set;
        require alDente::Container;
        if ( $plate_set =~ /new/i ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
            $plate_set = $Set->save_Set( -force => 1 );
        }

        unless ($plate_set) {
            Message("Error: No Plate Sets found.");
            return 1;
        }

        #   print &alDente::Container::Display_Input();  ## automatically included in prompt_user call
        
        require alDente::Prep;
        my $Prep;

        if ( $plate_set && $batch_edit ) {
            $Prep = new alDente::Prep(
                -dbc      => $dbc,
                -user     => $user_id,
                -protocol => $protocol,
                -set      => $plate_set,
                -plates   => $current_plates
            );

            print $Prep->check_Protocol();
            return 1;
        }
        else {

            #       import alDente::Prep;
            #require &alDente::Prep;  ## <CONSTRUCTION> - WHY is this necessary ??
            $Prep = new alDente::Prep(
                -dbc      => $dbc,
                -user     => $user_id,
                -protocol => $protocol,
                -set      => $plate_set,
                -plates   => $current_plates
            );
        }

        if ($plate_set) {
            ## re-post container set options ..
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
            print $Set->Set_home_info( -brief => $scanner_mode );
        }
        return 1;
    }
    elsif ( $q->param('Act on Plate Contents') ) {
        return &alDente::Container::act_on_Plate();
    }
    elsif ( $q->param('Freeze Protocol') ) {
        $dbc->connect_if_necessary();
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );

        require alDente::Prep;    ### <CONSTRUCTION> - Why is this necessary ??
        my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -encoded => $encoded, -input => \%Input );
        $Prep->{Set} = '';

        #Message($plate_set,"$current_plates");

        $plate_set      = $Prep->{set_number};
        $current_plates = $Prep->{plate_ids};

        print &alDente::Container::Display_Input($dbc);

        $Benchmark{new_prep} = new Benchmark;
        my $prompted = $Prep->prompt_User unless $Prep->prompted();

        $Benchmark{deep_freeze} = new Benchmark;
        unless ($prompted) {
            ## return to main plate(s) pages..
            if ($plate_set) {
                my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set, -basic => 1 );
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
        $Benchmark{end_freeze} = new Benchmark;
        return 1;
    }
    else {
        return special_branches( $dbc, $branched );    ## separate section of previous barcode.pm which branched out to call editing methods
    }
    return $branched;
}

#
# PHASE OUT !!
#
# Return: old branching logic to generate table editing pages
#######################
sub special_branches {
#######################
    my $dbc      = shift;
    my $branched = shift;

    require alDente::Container;
    print &alDente::Container::Display_Input($dbc);    ## from old code ... used to display current plate status (remove from here and place in applicable run modes as required... )

    require alDente::Special_Branches;                 ## dynamic loading ##

    #    import alDente::Special_Branches;  ## dynamic loading ##
    my $input = alDente::Special_Branches::Pre_DBForm_Skip($dbc);

    if    ( $input eq 'error' ) { 
        $dbc->message("Pre module checker detected error.  Skipping branch detection.<BR>"); 
    }
    elsif ( $input eq 'skip' )  { 
        ### skip the branch checking...
    }                                                                               
    ### special cases in which are handled OUTSIDE of standard DB_Form_Viewer routines ###
    else {
        my $configs = alDente::Special_Branches::DB_Form_Custom_Configs( -dbc => $dbc );

        my $returnval = &SDB::DB_Form_Viewer::DB_Viewer_Branch( -dbc => $dbc, 'input' => $input, 'configs' => $configs, 'finish_transaction' => 0, -old_return => 1 );    ## <CONSTRUCTION> - phase out old_return format...
        if ( $returnval && !( $returnval =~ /Error/i ) ) {                                                                                                                ### routines to run EVEN if Form branched
            my $post = alDente::Special_Branches::Post_DBForm_Skip( $dbc, $returnval );
            if ( $post || ( $returnval =~ /(form|exit)/i ) ) { &main::leave($dbc); }                                                                                      ### if skip specified or branch returned form..

            #       if ( $post || $returnval ) { &main::leave(); }  ### if skip specified or branch returned form..
        }

        #       if ($Transaction) {
        #         $Transaction->finish($@);
        #       }

    }
    $Benchmark{pre_button_options} = new Benchmark;

    return $branched;
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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
