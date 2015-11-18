###############################################################################################################
# MVC.pm
#
# Simple framework for MVC modules
#
# $Id$
##############################################################################################################
package LampLite::MVC;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

MVC.pm - Stores user session

=head1 SYNOPSIS <UPLINK>

	Module containing wrapper methods / functions enabling use of MVC framework 

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

use LampLite::Bootstrap;
use RGTools::RGIO qw(filter_input Call_Stack);

use LampLite::CGI;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();
###########################
# Constructor of the object
###########################
sub new {
##########
    my $this   = shift;
    my %args   = &filter_input( \@_ );
    my $params = $args{-params};
    my $call   = $args{-call};

    my $class = ref($this) || $this;

    my %args = @_;
    ## database connection or connection information required
    my $dbc = $args{-dbc};    # Database handle

    my $self = {};
    $self->{dbc} = $dbc;      # Database handle

    bless $self, $class;      ## re-bless

    if ($params) { $self->{params} = $params }
    
    $ENV{CGI_APP_RETURN_ONLY} = 1;    

    if ($call) { $self->call_run_mode() }

    return $self;
}

##############################
# public_methods             #
##############################

#
# Manages call to standard run mode from within main script
#  (includes optional dbc parameter to methods by default)
#
# Method reads parameters internally including option for 'sub_cgi_application'
#
# Usage example:
#
#   my $page = LampLite::MVC::call_run_mode($dbc);
#
# Return: page output HTML
####################
sub call_run_mode {
####################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'params' );
    my $params = $args{-params} || $self->{params};
    my $dbc     = $args{-dbc}     || $self->{dbc} || $params->{dbc};
    my $App_dir = $args{-App_dir} || $params->{App_dir};
    my $sid     = $args{-sid}     || $params->{sid};
    my $debug   = $args{-debug};

    my $app = $q->param('App');    ## simpified version of calling cgi_application run modes if app_dir supplied
    
    if ( $app && $App_dir ) {
        ## use direct method calls bypassing run() method ##
        my $module = $App_dir . '::' . $app . '_App';
        $q->param( 'cgi_application', $module );
    }

    my @rms      = $q->param('rm');
    my @cgi_apps = $q->param('cgi_application');
    my $sub_call = $q->param('sub_cgi_application');
    
    if (!@cgi_apps) { @cgi_apps = $q->param('cgi_app') }
    
     if (!@cgi_apps) {
        ## check for alternative shortcut using Home page input ##
        my $homepage = $q->param('HomePage');
        my $homepage_id = $q->param('ID');

        if ($homepage && $homepage_id) {             
            my $scope = $q->param('Scope') || 'alDente';
            $homepage =~s/\bPlate\b/Container/;

            my $Object;
            
            if ( (my $Loaded = $dbc->dynamic_require($homepage, -id=>$homepage_id, -construct=>1, -debug=>$debug)) ) {
                ## This should automatically load custom object class if available ##
                $Object = $Loaded;
        
            }
            else {
                ## logic should no longer come here, but left in for legacy reasons in case of problem above ##
                my $class = $scope . '::' . $homepage;            
                if ( RGTools::RGIO::module_defined($class) ) { 
                    $Object = $class->new( -dbc => $dbc, -id => $homepage_id );
                }
                else { 
                    eval "require SDB::DB_Object";
                    $Object = SDB::DB_Object->new(-dbc => $dbc, -table=>$homepage, -id=>$homepage_id);
                 }
            }
            
            
            $self->{output} = $Object->View->std_home_page(-Object=>$Object);
            return 1;
        }
    }
 
    ## Two cases for reloading previous session variables: expired previous session; retrieving session for debugging (Site Admin only)
    my $prev = $q->param('Expired_Session') || $q->param('Full_Session');
    my $lims_session_tracking = $q->param('Full_Session');

    my $guest_user;
    if ( $q->param('User') eq 'Guest' ) { $guest_user = 1 }
    ;    ### load as applicable ... ;

    my ($rm)              = shift @rms;
    my ($cgi_application) = shift @cgi_apps;

    my $output;
    if ( $sub_call ) {
        ## special handling when calling embedded MVC run modes (ie call one run mode from within another - eg view triggered run modes that return to the view) ##
        $self->_call_sub_MVC( -dbc => $dbc );
    }
    elsif ( $cgi_application ) {
        ## standard call to MVC run mode ##    
        my $ok = eval "require $cgi_application"; 
        if ($debug) { print $BS->message("Running $cgi_application run mode: $rm [$ok]") }

 #       $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $webapp = $cgi_application->new( PARAMS => $params );        

        if ($webapp) {
            my $page = $webapp->run();
            $self->{output} = $page;
        }
        else {
            print $BS->warning("$cgi_application run mode: $rm not found");
        }

        #        if ( ! $ENV{CGI_APP_RETURN_ONLY} ) { print $page }
    }
    if ( $rm eq 'Log In' ) {
        my ($rm2)              = shift @rms;
        my ($cgi_application2) = shift @cgi_apps;
        my $Site_Admin         = $dbc->session->param('access');
        my $display_view;
        if ( $rm2 eq 'Display' ) { $display_view = 1 }

        if ( ( $prev || $lims_session_tracking || $guest_user || $display_view ) && $cgi_application2 && $rm2 ) {
            if ($debug) { print $BS->message("Trying to run secondary run mode $cgi_application2 -> $rm2") }
            ### reload MVC parameters if logging in as same user (eg after expired session or during lims_admin session tracking) - or running run mode as guest user ##
            if ($guest_user) {
                ## Executing Run mode as guest user (eg: applying for accounts or resending password) ##
                if ($debug) { print $BS->message("Running app as guest") }
                ## If regenerating input after expired session, reload input parameters previously entered ##
                $self->{reload_cgi_app} = $cgi_application2;
                $self->{reload_rm}      = $rm2;
            }
            else {
                my $user        = $dbc->session->param('user_id');
                my $session_dir = $dbc->session->log_path();
                my $archived_session;

                if ( $user && $session_dir ) { $archived_session = `find $prev.sess` }
                if ( $archived_session =~ m/\/(\d+)\:(\S+)/ ) {
                    my $previous_user = $1;
                    if ( $user && $session_dir & $prev && ( $previous_user == $user ) && !$lims_session_tracking ) {
                        ## reloading expired session ##
                        if ($debug) { print $BS->message("Reloading previous session [$cgi_application2 : $rm2]") }
                        ## If regenerating input after expired session, reload input parameters previously entered ##
                        $self->{reload_cgi_app} = $cgi_application2;
                        $self->{reload_rm}      = $rm2;
                    }
                    elsif ( $user && $session_dir && $lims_session_tracking && ( $Site_Admin =~/Site Admin/ ) ) {
                        ## Admin debugging user sessions ##
                        if ($debug) { print $BS->message("Retrieving Session for User: $previous_user [$cgi_application2 : $rm2]") }
                        ## If regenerating input after expired session, reload input parameters previously entered ##
                        $self->{reload_cgi_app} = $cgi_application2;
                        $self->{reload_rm}      = $rm2;
                    }
                }
                elsif ( $user && $display_view ) {
                    ## reloading linked view
                    if ($debug) { print $BS->message("Reloading view using secondary run mode $cgi_application2 -> $rm2") }
                    ## Reload input parameters previously entered ##
                    $self->{reload_cgi_app} = $cgi_application2;
                    $self->{reload_rm}      = $rm2;
                }
            }
        }
    }

    return 1;
}

##############################
# private_functions          #
##############################

#
# Manages call to embedded run modes (eg generating run mode output from 'view' trigger, and returning to view)
#
# Return: page output HTML
####################
sub _call_sub_MVC {
####################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $sub_cgi = $args{-sub_cgi};
    my $rm      = $args{-rm};
    my $debug   = $args{-debug};

    my $run_cgi_app          = $args{-run_cgi_app} || $q->param('RUN_CGI_APP');
    my $display_sub_cgi_page = $args{-display}     || $q->param('DISPLAY_SUB_CGI_PAGE');

    use CGI ':cgi-lib';
    my %params = Vars();

    foreach my $key ( keys %params ) {
        my @arr = split( '\0', $params{$key} );
        $params{$key} = \@arr;    # if( @arr > 1 );
    }

    my ( @sub_cgi_apps, @rms );
    if ( $sub_cgi && $rm ) {
        @sub_cgi_apps = ($sub_cgi);
        @rms          = ($rm);
    }
    else {
        @sub_cgi_apps = @{ $params{sub_cgi_application} };
        @rms          = @{ $params{rm} };
    }

    my $sub_cgi_number = @sub_cgi_apps;
    my $rm_number      = @rms;

    my ( $i, $j, $output );
    for ( $i = $sub_cgi_number - 1, $j = $rm_number - 1; $i >= 0 && $j >= 0; $i--, $j-- ) {
        my $cgi_application = $sub_cgi_apps[$i];
        my $rm              = $rms[$j];

        my $ok = eval "require $cgi_application";

        if ($debug) { $dbc->message("Run $cgi_application (rm = $rm) [$ok]") }

        my $new_q = new CGI;
        $new_q->param( 'rm'              => $rm );
        $new_q->param( 'cgi_application' => $cgi_application );

        my $webapp = $cgi_application->new( PARAMS => { dbc => $dbc }, QUERY => $new_q );

        my $page = $webapp->run($rm);

        if ($display_sub_cgi_page) {
            $output .= $page;
        }
    }    # END for i j

    if ( $run_cgi_app eq 'AFTER' && $j >= 0 ) {
        my $rm = $rms[$j];
        my $cgi_application = param('cgi_application') || param('cgi_app');
        eval "require $cgi_application";
        my $webapp = $cgi_application->new( PARAMS => { dbc => $dbc } );

        ## $ENV{CGI_APP_RETURN_ONLY} = 1;   ## returns output rather than printing it ##
        my $page = $webapp->run($rm);
        $output .= $page;
    }
    $self->{secondary_output} = $output;
    return $output;
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
