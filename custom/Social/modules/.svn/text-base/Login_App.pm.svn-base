###################################################################################################################################
# Social::Login_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package Social::Login_App;

use base alDente::Login_App;

use strict;

## Standard modules ##
use Time::localtime;

use Social::Login_Views;
use LampLite::Bootstrap;
##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
##############################
# global_vars                #
##############################

my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##
############
sub setup {
############
    my $self = shift;

    $self->start_mode('Log In');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
             'Log In'             => 'local_login',
            'Error Notification' => 'error_notification',
            'Search Database'    => 'search_Database',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#######################
sub search_Database {
#######################
    my $self = shift;
    my $q    = $self->query();

    my $dbc = $self->param('dbc');

    $dbc->message('Search Database');

    my $string = $q->param('Sstring');

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'help' );
    $page .= $q->submit( -name => 'Search Database', -style => "background-color:yellow" ) . " containing: " . $q->textfield( -name => 'DB Search String' ) . $q->end_form();

    my $table  = $q->param('Table');
    my $Search = alDente::SDB_Defaults::search_fields();

    my $string = $q->param('DB Search String');

    $page .= "<h3>Looking for '$string' in Database...</h3>";

    #       &Online_help_search_results($string);

    require SDB::DB_Form_Viewer;
    require SDB::HTML;

    #    import SDB::HTML;

    my $matches = alDente::Tools::Search_Database( -dbc => $dbc, -input_string => $string, -search => $Search, -table => $table );
    if ( $matches =~ /^\d+$/ && !$table ) { $page .= vspace(5) . "$matches possible matches.<BR>"; }

    return $page;
}

1;
