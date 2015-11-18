#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use CGI qw(:standard);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/custom";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DB_Form;
use SDB::Session_Views;

### Submission modules
use Submission::Globals;
use Submission::Public;
use Submission::Redirect;

use RGTools::HTML_Table;
use RGTools::RGIO;

use alDente::Session;
use alDente::SDB_Defaults;
use alDente::Web;

use LampLite::Bootstrap;
use SDB::Config;

use vars qw(%Defaults $URL_temp_dir $java_header $html_header $submission_dir %Configs $dbc $homefile);

my $q = new CGI;
my $BS = new Bootstrap;
######################
## Generate Configs ##
######################
use YAML;
my $conf_dir = $FindBin::RealBin . "/../conf";
my $init_config = YAML::LoadFile("$conf_dir/personalize.cfg");

my $custom        = $init_config->{custom};

my $system_config = YAML::LoadFile("$conf_dir/system.cfg");
my $custom_config = YAML::LoadFile("$conf_dir/../custom/$custom/conf/system.cfg");
my $configs       = LampLite::DB::merge_configs( [ \%Configs, $init_config, $system_config, $custom_config] );
SDB::CustomSettings::load_config($configs);

my $timestamp     = &timestamp();
my $driver        = param('DB_Driver') || 'mysql';
my $host          = param('Server') || $Configs{SQL_HOST};
my $dbase         = param('Database') || $Configs{DATABASE};
my $user          = param('Username') || 'viewer';
my $pwd           = param('Pwd') || 'viewer';
my $dept          = param('FK_Department__ID');
my $org           = param('FK_Organization__ID');
my $default_grp   = param('FK_Grp__ID');
my $confirmed     = param('Confirmed');
my $email         = param('email');
my $public        = param('External');
my $admin_contact = param('FKAdmin_Contact__ID');

if ( $email =~ /(.+)\@bcgsc\.ca$/ ) {
    $email = $1;
}

print "Content-type: text/html\n\n";
print $java_header;
print $html_header;

my $session_dir = $configs->{session_dir}        || '/opt/alDente/www/dynamic/sessions';
my $version       = $init_config->{version_name};
my $session = new alDente::Session( 'id:md5', $q, { Directory => "$session_dir/$version/$dbase" } );
my $sid = $session->validate_session();                                                                    ## check for expired session ##
`CHMOD 660 $session_dir/$version/$dbase/cgisess_$sid`;

$dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => 'login', -connect => 1, -config=>$configs, -session=>$session);
$dbc->{homelink} = $homefile;

my $css_path = "/SDB/css";
print $BS->load_css( "$css_path/bootstrap", [ "$css_path/custom_bootstrap.css", "$css_path/custom_" . lc($custom) . '_bootstrap.css' ] );

print "<P><h3>alDente Account Services</H3>";
print "<span class='smaller'>";

my $dept_id;
if ($dept =~/^\d+/) { 
    $dept_id = $dept;
    $dept = $dbc->get_FK_info( 'FK_Department__ID', $dept );
}
elsif ($dept) {
    $dept_id = $dbc->get_FK_ID( 'FK_Department__ID', $dept );
}

if ( $q->param('FormNav') ) {
    ## load config file
    my $jsstring = param('FormData');
    use JSON;
    my $obj  = jsonToObj($jsstring);

    my $data = &SDB::DB_Form::conv_FormNav_to_DBIO_format(
        -dbc      => $dbc,
        -data     => $obj,
        -type     => 'Database',
        -feedback => 'hidden'
    );

    my $result = $dbc->Batch_Append( -data => $data, -quiet => 1 );
    
    my $submission_id = $result->{'Submission.Submission_ID'};
    if ($submission_id) { 
        print $BS->message("Submitted Account Request Successfully [$submission_id]");
    }
    else {
        print $BS->error("Error submitting account request");
    }
#    my $redirected = &Submission::Redirect::redirect( -dbc => $dbc, -config => \%Configs, -message => "Administrator needs to approve the account before the account is set to active. Please wait for confirmation." );
}
elsif ( param('reset_password') ) {

    my $session_view = new SDB::Session_Views();
    if ($confirmed) {
        my $new_password = param('New_Pwd');
        my $sec_password = param('Confirm_Pwd');
        my $encryption   = param('encryption');
        my $passed       = $dbc->Table_find( 'Employee', "Employee_ID", "WHERE password('$encryption') = Password and Email_Address='$email'" );

        if ( !$passed ) {
            Message "Warning: Incorrect Password";
            print change_password_box( -encryption => $encryption );
        }
        elsif ( $new_password && $new_password eq $sec_password ) {
            $dbc->Table_update_array( 'Employee', ['Password'], ["password('$new_password')"], "WHERE Email_Address='$email'" );
            print Link_To( 'barcode.pl', 'Continue', "", $Settings{LINK_COLOUR} );
        }
        elsif ($new_password) {
            Message "Warning: The two passwords did not match";
            print change_password_box( -encryption => $encryption );
        }
        else {
            print change_password_box( -encryption => $encryption );
        }

    }
    elsif ($email) {
        my %user_info = $dbc->Table_retrieve( 'Employee', [ 'Employee_Name', 'Email_Address', 'Employee_Status' ], "WHERE Email_Address LIKE '$email%' " );
        my $count = int( @{ $user_info{Employee_Name} } ) if $user_info{Employee_Name};

        if ( $count > 1 ) { Message "Warning: There is more than one account assocated with this email please contact LIMS." }
        elsif ($count) {
            my $status = $user_info{Employee_Status}[0];
            if ( $status eq 'Active' ) {

                if ( param('reset_password') eq 'Email Username' ) {
                    send_notification( -target => $user_info{Email_Address}[0], -user_name => $user_info{Employee_Name}[0], -dbc => $dbc );
                    Message "Your info has been sent to your email account.";
                }
                else {
                    my $temp_password = set_temp_password( -user_name => $user_info{Employee_Name}[0], -dbc => $dbc );
                    send_notification( -target => $user_info{Email_Address}[0], -user_name => $user_info{Employee_Name}[0], -dbc => $dbc, -new_password => $temp_password );
                    Message "A link has been sent to your email account.  Please follow the link to reset your password.";
                }
            }
            else { Message "Warning: Your account status is $status. Please concat LIMS to activate this account." }
        }
        else {
            Message "Warning: There is no account assocated with this email please apply for a new account.";
            print 'Entering the default GSC domain "@bcgsc.bc.ca" is also valid' . vspace();
            print $session_view ->reset_unknown_password( -dbc => $dbc );

        }
    }
    else {
        print $session_view ->reset_unknown_password( -dbc => $dbc );
    }

}
elsif ($public) {
    my %grey;
    my %preset;
    my %list;
    my %omit;
    my ($guest_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Guest'" );
    $omit{'contact_status'}      = 'Active';
    $omit{'Contact_Fax'}         = '';
    $omit{'Contact_Type'}        = 'Collaborator';
    $omit{'Canonical_Name'}      = '';
    $omit{'Collaboration_Type'}  = 'Standard';
    $grey{'FK_Organization__ID'} = $dbc->get_FK_info( 'Organization', $org );

    my $Form = new SDB::DB_Form(
        -dbc    => $dbc,
        -target => 'Submission',
        -table  => 'Contact',
    );
    my $admin_id = $dbc->get_FK_info( 'FK_Contact__ID', $admin_contact );

    $Form->configure( -grey => \%grey, -omit => \%omit, -preset => \%preset, -list => \%list );
    $Form->define_Submission(
        -grey => {
            'Submission_Source'   => 'External',
            'Submission_Comments' => 'New Collaborator Account',
            'FKAdmin_Contact__ID' => $admin_id,
        },
        -omit => {
            'Reference_Code'           => 'GSC-0001',
            'FKSubmitted_Employee__ID' => $dbc->get_FK_info( 'FK_Employee__ID', $guest_id ),
            'FKTo_Grp__ID'             => 'Public',
            'FKFrom_Grp__ID'           => 'External',
            }

    );
    print $Form->generate( -title => 'Employee Info', -navigator_on => 1, -return_html => 1 );    # -fields=>['Employee_Name','Employee_FullName']);
}
elsif ( !$dept ) {
    ## Require users to choose department that they are applying to - this presets their groups and dictates who is sent the submission to approve ##
    print "<h3>Choose primary department with which to be associated:</h3>(access to other departments may be added later)<p>";
    print "<UL>";
    foreach my $dept ( $dbc->Table_find( 'Department', 'Department_Name,Department_ID', ' Order by Department_Name' ) ) {
        my ( $dept_name, $dept_id ) = split ',', $dept;
        my ($grp)
            = $dbc->Table_find( 'Department,Grp left join GrpEmployee on FK_Grp__ID=Grp_ID', 'Grp_ID,Count(*) as Num',
            "WHERE FK_Department__ID=Department_ID AND Department_ID=$dept_id GROUP BY Department_ID,Grp_ID ORDER BY Department_ID,Num desc LIMIT 1" );
        ($default_grp) = split ',', $grp;

        print "\n<LI>" . Link_To( "$Configs{URL_domain}/$Configs{URL_dir_name}/cgi-bin/new_account_request.pl", $dept_name, "?FK_Department__ID=$dept_id&FK_Grp__ID=$default_grp" );
    }
    print "</uL>\n";
}
elsif ( $q->param('rm') eq 'Apply for Account') {
    require LampLite::MVC;
    my $MVC = new LampLite::MVC( -dbc => $dbc, -params => { dbc => $dbc }, -call => 1 );  
    print $MVC->{output};
}
elsif (1) {
    ## preset or grey out most of the fields before loading form ##
    my %grey;
    my %preset;
    my %list;
    
    $dept = 13; ## $dbc->get_FK_ID($dept, 'FK_Department__ID');
    
    my @grp_list = $dbc->get_FK_info_list( 'FK_Grp__ID', "WHERE FK_Department__ID = $dept" );
    $list{FK_Grp__ID} = \@grp_list;
    my ($guest_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Guest'" );
    $preset{FK_Grp__ID} = $dbc->get_FK_info( 'FK_Grp__ID', $default_grp );
    ( $preset{FK_Employee__ID} ) = $guest_id;
    $grey{FK_Department__ID} = $dbc->get_FK_info( 'FK_Department__ID', $dept );
    my %omit;
    $omit{'Machine_Name'}    = '';
    $omit{'Employee_Status'} = 'Active';

    ## load form
    my $Form = new SDB::DB_Form(
        -dbc    => $dbc,
        -target => 'Submission',
        -table  => 'Employee',

        # -fields=>['Employee.Employee_Name','Employee.Employee_FullName','Employee.Employee_Start_Date as Start_Date','Employee.Email_Address','Employee.Position','Employee.FK_Department__ID as Dept'],
    );

    $Form->configure( -grey => \%grey, -omit => \%omit, -preset => \%preset, -list => \%list );
    $Form->define_Submission(
        -grey => {
            'FKSubmitted_Employee__ID' => $dbc->get_FK_info( 'FK_Employee__ID', $guest_id ),
            'FKTo_Grp__ID'             => $dbc->get_FK_info( 'FK_Grp__ID',      $default_grp ),
            'FKFrom_Grp__ID'           => 'Public',
            'Submission_Comments'      => 'New Employee Account',
        },
        -omit => { 'Reference_Code' => 'GSC-0001' }

    );

    print $Form->generate( -title => 'Employee Info', -navigator_on => 1, -return_html => 1 );    # -fields=>['Employee_Name','Employee_FullName']);
    ## Enter as submission for Approval ##
}
else {
    ## Generate form for Employees to fill in themselves - most fields are preset or hidden ##

    ## preset or grey out most of the fields before loading form ##
    my %grey;
    my %preset;
    my %list;

    my @grp_list = $dbc->get_FK_info_list( 'FK_Grp__ID', "WHERE FK_Department__ID = $dept_id" );

    $list{FK_Grp__ID} = \@grp_list;
    my ($guest_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Guest'" );
    $preset{FK_Grp__ID} = $dbc->get_FK_info( 'FK_Grp__ID', $default_grp );
    ( $preset{FK_Employee__ID} ) = $guest_id;
    $grey{FK_Department__ID} = $dbc->get_FK_info( 'FK_Department__ID', $dept );

    my %hidden;
    $hidden{'Machine_Name'}    = '';
    $hidden{'Employee_Status'} = 'Active';
    $hidden{'Password'} = "Password('Pwd')";
    
    use LampLite::DB_Views;
    my $domain        = $init_config->{URL_domain};
    my $path          = "SDB";
    $dbc->homelink("$domain/$path/cgi-bin/new_account_request.pl");
    
    my $dbview = new LampLite::DB_Views(-dbc=>$dbc);
    
    print $dbview->add_Record(-table=>'Employee', -grey=>\%grey, -hidden=>\%hidden, -preset=>\%preset, -app=>'alDente::Submission_App', -rm => 'Apply for Account');

    ## Enter as submission for Approval ##
}

print "</span>";
print &alDente::Web::unInitialize_page($page);

exit;

############################
sub set_temp_password {
############################
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $user_name     = $args{-user_name};
    my $range         = 100000;
    my $random_number = int( rand($range) );
    my $new_pass      = 'C' . $random_number . 'kP';
    $dbc->Table_update_array( 'Employee', ['Password'], ["password('$new_pass')"], "WHERE Employee_Name='$user_name'" );
    return $new_pass;
}

############################
sub change_password_box {
############################
    my %args       = &filter_input( \@_ );
    my $encryption = $args{-encryption};

    my $page
        = &alDente::Form::start_alDente_form()
        . hidden( -name => 'encryption', -value => $encryption, -size => 20 )
        . 'New password:      '
        . password_field( -name => 'New_Pwd', -size => 20 )
        . vspace()
        . 'Confirm  pass:  '
        . password_field( -name => 'Confirm_Pwd', -size => 20 )
        . vspace()
        . submit( -name => 'Save new password', -value => "Save new password", -force => 1, -class => "Action" )
        . hidden( -name => 'reset_password', -value => 1,      -force => 1 )
        . hidden( -name => 'Confirmed',      -value => 1,      -force => 1 )
        . hidden( -name => 'email',          -value => $email, -force => 1 )
        . end_form();
    return $page;
}

############################
sub send_notification {
############################
    my %args      = &filter_input( \@_ );
    my $target    = $args{-target};
    my $user_name = $args{-user_name};
    my $dbc       = $args{-dbc};
    my $temp_pass = $args{-new_password};

    my $subject = 'LIMS Account Information';

    my $link = Link_To( $homefile, 'Reset Your Password', "&Confirmed=1&reset_password=1&email=$target&encryption=$temp_pass", $Settings{LINK_COLOUR} );
    my $body
        = " Hi $user_name,"
        . vspace(2)
        . "You are receiving this email because you have requested to change your LIMS password or needed to know your username."
        . vspace()
        . "Username: $user_name"
        . vspace()
        . "Alternate Username: $target"
        . vspace(2)
        . "Thank you,"
        . vspace(2) . "LIMS.";

    if ($temp_pass) {
        $body .= vspace(2) . "To change your password please follow the link below and reset your password.  " . vspace(2) . "Link:  " . "$link";
    }

    require alDente::Notification;
    $target .= '@bcgsc.ca';
    alDente::Notification::Email_Notification( -to => $target, -subject => $subject, -body => $body, -content_type => 'html' );

    #print $body;
}

