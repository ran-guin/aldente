###################################################################################################################################
# LampLite::Login.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package UTM::Login;

use base LampLite::Login;

use CGI;
my $q = new CGI;
###########
sub init {
###########
    my $self = shift;
    my $dbc = $self->dbc();
   
	$self->SUPER::init();
	
	my $id = $self->dbc->config('user_id');
	
    if ($id && $dbc->{connected}) {
        my $access = $self->dbc->get_db_value(-sql=>"SELECT User_Access FROM User where User_ID = $id");
        $self->dbc->session->param('utm_access', 'Admin');
     }
     
     if (my $mode = $q->param('Access') ) {
            ## reset current mode ##
            $self->dbc->session->param('utm_access_mode', $mode);
     }
	
	return;
}

return 1;
