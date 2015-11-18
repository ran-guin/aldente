#!/usr/local/bin/perl

##########################################################
#
# CVS Revision: $Revision: 1.46 $
##########################################################
#
# This script depends on the SDB modules in order to
# function correctly. The script currently uses a copy
# of these modules in /home/edere/Perl/modules
#
# The name of the URL used to call this script determines
# the functionality of the script. For maintenance
# protocols, the ULR must be named either "maintenance"
# or "maintenance_test". And for plate protocols, it
# should be named "protocol" or "protocol".
#
# Having the "_test" suffix causes the script to use the
# seqtest database rather than the sequence database.
#
# Maintenance protocols require the additional step of
# updating/appending the "Service" table in the database.
#
##########################################################
#
# Notes:
########
#
# When steps are added or deleted, or when entire protocols
# are deleted, the protocol is first archived before any
# changes are made.
#
# As steps are added to the middle of a protocol or are
# deleted, the script will automatically re-index the step
# numbers such that the step numbers are numbered
# consecutively.
#
##########################################################
#
# Things to add:
################
#
# * Currently, the maintenance protocols are generalized
#   to apply to an equipment type. An additional form
#   element could be added to make the protocol apply to
#   individual machines.
#
# * Test the script to make sure that it works with the
#   production copies of the SDB modules.
#
# * Add Rack scanning option for end of protocol step ?
#
##########################################################

use strict;
use CGI qw(:standard);
use DBI;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use URI::Escape;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;

use SDB::DBIO;
use SDB::Transaction;
use SDB::HTML;

use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;
use RGTools::HTML_Table;

use alDente::Form;
use alDente::Help;
use alDente::Tools;
use alDente::SDB_Defaults;
use alDente::Security;
use alDente::Employee;
use alDente::Grp;
use alDente::Web;
use vars qw($login_name $login_pass);
use vars qw($testing $OUTFILE $homefile $homelink $dbase $config_dir $protocols_dir %Std_Parameters %Login $Security $Current_Department $Connection $image_dir $URL_dir_name $html_header $session_id);

my $test      = 0;     # testing mode
my $direction = '';    ### moving step number up or down ?

# Tooltips
my %Tooltips;
$Tooltips{Step_Type}{Standard}    = 'Steps that do not involve creating of new barcodes';
$Tooltips{Step_Type}{Transfer}    = 'Transfer sample from one container to a new container';
$Tooltips{Step_Type}{Aliquot}     = 'Aliquot sample from one container to a new container';
$Tooltips{Step_Type}{'Pre-Print'} = 'Pre-print new container barcode to be used at a later transfer/aliquot step';
$Tooltips{Step_Type}{Pool}        = 'Pool samples from multiple containers into a new container';
$Tooltips{Step_Type}{'Setup'}     = 'Prepare empty plate and transfer the sample later';
my $Disabled_Step_Name = "(Select format from popup menu)";

# determine the URL used to call the script and determine the
# correct database and table to access.

my $TableName;
my $links;
$homefile = $0;

if ( $homefile =~ /\/([\w_]+[.pl]{0,3})$/ ) {
    $homelink = $1;
    $homefile = "./$1";
}
elsif ( $homefile =~ /\/([\w_]+)$/ ) {
    $homelink = $1;
    $homefile = "./$1";
}

######### Get default database from login_file configuration settings ########
#my $CONFIG;
#my $default_dbase='sequence';
my $default_dbase = 'sequence';

#open(CONFIG,"/home/sequence/intranet/config") or Message("Error","can't open");#while (<CONFIG>) {
#    if (/^database:(\w+)/) {$default_dbase=$1;}
#}
#close(CONFIG);

# my @databases = ('sequence','seqlast','seqtest','seqbeta','seqdev','seqrguin','seqechuah','seqjsantos','seqmariol','seqreza');
my $dbase = $default_dbase;
unless ( $0 =~ /\/(SDB|Production)\//i ) {
    $dbase = $Configs{DATABASE};
}
if ( param('Database') ) { $dbase = param('Database'); }

if ( $homefile =~ /maintenance/ ) {
    $TableName = "Maintenance_Protocol";
    $links = { "Protocol" => ["protocol"] };
}
else {
    $TableName = "Protocol_Step";
    $links     = {
        "Chemistry"   => ["chemistry"],
        "Maintenance" => ["maintenance"]
    };
}

my $helplink = "$homelink?";
### Generate the standard GSC webpage
####### Global Variables ####################
if ($testing) {
    Message("Home: $homefile");
    foreach my $name ( param() ) {
        Message( "param($name) = ", param($name) );
    }
}

#&show_parameters();

# Load parameters
#%Std_Parameters = %{alDente::Tools::Load_Parameters(-dbase=>$dbase,-host=>$Defaults{SQL_HOST})};

$login_name = 'labuser';
$login_pass = 'manybases';
my $host = param('Host') || $Defaults{SQL_HOST};
my $dbc = SDB::DBIO->new();
$Connection = $dbc;
$dbc->connect( -dbase => $dbase, -user => $login_name, -password => $login_pass );

#my @EquTypes = get_enum_list($dbc,'Equipment','Equipment_Type');
my @Categories     = $dbc->Table_find( 'Equipment_Category', 'Category',     'ORDER BY Category' -distinct     => 1 );
my @Sub_Categories = $dbc->Table_find( 'Equipment_Category', 'Sub_Category', 'ORDER BY Sub_Category' -distinct => 1 );

my @Equ_Condition = ( '', get_enum_list( $dbc, 'Equipment', 'Equipment_Condition' ) );
my @databases = $dbc->dbh->func("_ListDBs");

my @plate_formats = get_FK_info(
     $dbc, 'FK_Plate_Format__ID',
    -condition => "where Plate_Format_Status = 'Active'",
    -list      => 1
);

# directory where old version of the protocol are saved to
my $dump_dir = "$protocols_dir/OldEdits/";

# Password file that contains the administrative users and their passwords
# The file is comma delimited with the usernames appearing as they appear
# in the Employee table of the database.
my $pass_file = "$config_dir/protocol.passwd";

my $protocol = param('Protocol') || param('Protocol Choice');
$protocol =~ s/\+/ /g;
my $protocol_id;
my $Qprotocol = $dbc->dbh()->quote($protocol);

if ( $TableName =~ /^Maintenance/ ) {
    ($protocol_id) = &Table_find( $dbc, 'Service', 'Service_ID', "where Service_Name like '$protocol'" );
}
else {
    ($protocol_id) = &Table_find( $dbc, 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name like '$protocol'" );
}
my $Qprotocol_id = $dbc->dbh()->quote($protocol_id);

my $admin = param('Admin');
my ( $user_id, $user_name );

if ( param('User ID') ) {
    $user_id = param('User ID');
    ($user_name) = &Table_find( $dbc, 'Employee', 'Employee_Name', "where Employee_ID = $user_id" );

    #  $Connection->set_user_id($user_id);
    $dbc->set_local( 'user_id',   $user_id );
    $dbc->set_local( 'user_name', $user_name );

}

if ( param('Current_Department') ) {
    my $dept = param('Current_Department');
    $Current_Department = URI::Escape::uri_unescape($dept);
}

# Obtain login information
if ( param('User') || param('User Choice') ) {
    my $name = param('User') || param('User Choice');
    ($user_id) = Table_find( $dbc, 'Employee', 'Employee_ID', "where Employee_Name = '$name'" );
}

if ( param('Session') ) {
    my $sess = param('Session');
    require SDB::Session;
    my $Sess = SDB::Session::validate_session($sess);
    $session_id = $Sess->session_id();
    if ( $session_id > 0 ) {
        $user_id = $Sess->{user_id};
    }
}

my $page;
my $topbar;
if ($session_id) {
    $topbar = &alDente::Web::show_topbar(
         $dbc,
        -include  => 'Home',
        -homelink => "barcode.pl?Session=$session_id"
    );
}
else {
    $topbar = &alDente::Web::show_topbar( $dbc, -include => 'Home', -homelink => "Protocol.pl" );
}

print &alDente::Web::Initialize_page( $page, -topbar => $topbar );

if ($user_id) {
    $Security = alDente::Security->new( -dbc => $dbc, -user_id => $user_id, -dbase => $dbase );
    my $employee = alDente::Employee->new( -dbc => $dbc, -id => $user_id );
    $employee->define_User();
    %Login = %{ $Security->login_info() };

}
else {
    &login_home();
    &leave();
}

## Header ##
print h1("LIMS Protocol Admin Page");
print "User: <B><Font color=red>" . $Security->{login}->{user} . "</Font></B>" . &hspace(20);

print "Database: <B>$host.<Font color=red>$dbase</Font></B>";

##############################################

if ($test) {
    testing();
}
if ( param('Online Help') ) {
    my $topic = param('Online Help');
    print &Online_help($topic);
    $dbc->disconnect();
    print &alDente::Web::unInitialize_page($page);
    exit;
}

if ( param('Continue') ) {
    my $user = param('User') || param('User Choice');
    my $passwd = param('Password');
    $admin = validation( $user, $passwd );

    #    print "Attempting to validate password & set user_id... for $user ($passwd) - $admin.";
    #    if ($admin) {
    #	($user_id) = Table_find($dbc,'Employee','Employee_ID',"where Employee_Name = \"$user\"");
    #	my $Security = Security->new(-dbc=>$dbc,-user_id=>$user_id);
    #	%Login = %{$Security->login_info()};
    #    }
}

if ( param('Restrict Access') ) {
    $admin = 0;
}

if ( $admin && $user_id ) {
    print "<H1><span class=mediumyellow>Administrative Access: $dbase</span></H1>";
}
else {
    print "<H1><span class=mediumyellow>Non-administrative Access: $dbase</span></H1>";
}

my @groups;
if ( param('GrpLab_Protocol') ) {
    @groups = param('GrpLab_Protocol');
}
elsif ( param('GrpLab_Protocol Choice') ) {
    @groups = param('GrpLab_Protocol Choice');
}

my $groups_ref = get_FK_ID( $dbc, 'FK_Grp__ID', \@groups );
@groups = @{$groups_ref} if ($groups_ref);

if ( param('View Protocol') ) {
    &view_protocol();

}
elsif ( param('Create New Protocol') ) {
    $protocol = "";
    &new_protocol_prompt();

}
elsif ( param('Edit Protocol Visibility') ) {
    my $protocol = param('Protocol') || param('Protocol Choice');
    edit_home($protocol);
}
elsif ( param('Update Protocol') ) {

    &update_protocol( param('Protocol'), \@groups );
    &view_protocol();

    #    &protocol_home();

}
elsif ( param('Delete Protocol') ) {

    # if the protocol has not been previously restored, archive the
    # protocol and then delete it, otherwise just delete the protocol
    # without archiving the protocol
    &delete_protocol();
    &protocol_home();
}
elsif ( param('Add Step') ) {
    &addstep( param('Edit Step') );
}
elsif ( param('Save New Protocol') ) {
    my $protocol = param('New Protocol Name');
    $protocol =~ s/\+/ /g;
    my $desc = param('Protocol Description');

    &new_protocol( -protocol => $protocol, -description => $desc, -groups => \@groups );

    protocol_home();
}
elsif ( param('Save Step') ) {

    # if entering a new protocol, then there is no protocol to archive
    my $newname = param('New') || param('New Protocol');

    #my $completion_email_list = param('Completion_Email_List');

    if ( &save_step( undef, $newname ) ) {
        &addstep();
    }
    else { &addstep(); }

}
elsif ( param('Delete Step(s)') || param('Delete Step') ) {
    &delete_step();
    &reindex();
    my $date   = today();
    my $values = "$user_id,$date";
    my $field;
    my $datefield;
    if ( $TableName =~ /^Protocol/ ) {
        $field     = "FK_Lab_Protocol__ID";
        $datefield = "Protocol_Step_Changed";
    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {
        $field     = "FK_Service__Name";
        $datefield = "Protocol_Date";
    }

    # record the editor and date of edit for this protocol ?? history needed..?
    #    my $ok = Table_update($dbc,$TableName,"FK_Employee__ID,$datefield",$values,"where $field=$Qprotocol_id",-autoquote=>1);
    &view_protocol();

}
elsif ( param('Home') ) {
    &protocol_home();

}
elsif ( param('Step Details') ) {
    if ( param('Edit Step') ) {
        my $step = param('Edit Step');
        &editstep($step);
    }
    else {
        Message("No Step Selected to View Details.");
        &view_protocol();
    }

}
elsif ( param('Save Changes') ) {
    &save_step('edit');
    &view_protocol();

}
elsif ( param('Next Step') ) {
    &editstep( param('Next') );

}
elsif ( param('Previous Step') ) {
    &editstep( param('Previous') );

}
elsif ( param('View Old Protocol') ) {
    my @protocols;
    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        @protocols = split '\n', `ls $dump_dir/maintenance`;
    }
    elsif ( $TableName =~ /^Protocol/ ) {

        # retrieve a listing of the archived protocols
        my $protocols = `find $dump_dir -group nobody`;
        chop $protocols;
        $protocols =~ s/\n/,/g;
        $protocols =~ s/$dump_dir//g;
        $protocols =~ s/^,|maintenance,//g;
        @protocols = split ',', $protocols;
    }

    print h1("View Old Revisions");

    #    start_barcode_form('protocol'),
    # print start_custom_form('Protocol',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'Protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    print hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Host', -value => $host ), "<TABLE cellspacing=0 border=0><TR>", "<TD width=120 bgcolor=#EEEEFF><BR><H4>Select Protocol: </H4></TD><TD>",

        #popup_menu(-name=>'Protocol', -value=>[@protocols],-default=>$protocol),
        &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'Protocol',
        -name    => 'Protocol',
        -options => \@protocols,
        -default->$protocol,
        -filter => 1,
        -search => 1,
        -mode   => 'Scroll'
        ),

        "</TD></TR></TABLE><BR>", hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'User ', -value => "$user_id" ), hidden( -name => 'Admin', -value => "$admin", -force => 1 ),
        hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 ), submit( -name => 'Retrieve Protocol', -class => 'Std' ), br, submit( -name => 'Home', -class => 'Std' ), end_form;

}
elsif ( param('Retrieve Protocol') ) {
    if ( &restore_protocol() ) {
        &view_protocol();
    }
    else {
        Message("Unable to retrieve old protocol");
    }
}
elsif ( param('Edit Protocol Name') ) {
    my $ok = &edit_protocol_name();
    if   ( $ok == 1 ) { Message(" Protocol Name changed to <B>param('Protocol Name')</B>"); }
    else              { Message("Protocol Name was not affected"); }
    protocol_home();
}
elsif ( param('Save As New Protocol') ) {
    &copy_protocol_home();

}
elsif ( param('Change Status') ) {
    my $state = param('State');
    my $ok = &Table_update_array( $dbc, 'Lab_Protocol', ['Lab_Protocol_Status'], [$state], "where Lab_Protocol_ID=$Qprotocol_id", -autoquote => 1 );
    if   ($ok) { Message("Status Set to <B>$state</B>"); }
    else       { Message("Status was not affected"); }
    &view_protocol();
}
elsif ( param('Confirm Save As New Protocol') ) {
    my $newname = param('New Name');
    my $state = param('Active') || 'Inactive';
    if ( &copy_protocol( $newname, $state ) ) {
        &protocol_home();
    }
    else {
        &protocol_home();
    }

}
else {
    &protocol_home();
}

$dbc->disconnect();
print &alDente::Web::unInitialize_page($page);
exit;

#######################
sub show_parameters {
###########################
    #
    # View input parameters to cgi script
    #

    foreach my $name ( param() ) {
        my $value = param($name);
        Message("Input: $name = ");
        my $values = join ',', param($name);
        Message("($values)");
    }
    return 1;
}

#################
sub protocol_home {
#################
    #
    # Creates either the maintenance or plate protocol homepage,
    # depending on the URL called.
######################
    my $field;
    my $Ptable = $TableName;

    my @protocols;
    my $tables_list;
    my $condition;

    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        print &Views::Heading("$dbase Database: Maintenance Protocols");
        $Ptable .= " LEFT JOIN Service on FK_Service__Name = Service_Name";
        my $tables_list = $Ptable;
        $field = "FK_Service__Name";
        @protocols = Table_find( $dbc, $tables_list, $field, "$condition Order by $field", 'Distinct' );
    }
    elsif ( $TableName =~ /^Protocol/ ) {

        @protocols = @{
            $Security->get_accessible_items(
                -table           => 'Lab_Protocol',
                -extra_condition => "Lab_Protocol_Status <> 'Old'"
            )
            };

    }
    else {
        @protocols = @{ $Security->get_accessible_items( -table => 'Lab_Protocol' ) };
    }

    $URL_dir_name =~ /SDB_(\w+)/;
    my $developer = $1;

    $protocol ||= param('Protocol') || param('Protocol Choice');
    $protocol =~ s/\+/ /g;

    #    print start_barcode_form('protocol'),
    # print start_custom_form('Protocol',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'Protocol',
        -type => 'start'
    );

    print hidden( -name => 'Session', -value => $session_id );
    print "<h2>Database: $dbase</h2>", hidden( -name => 'Host', -value => $host ), hidden( -name => 'Database', -value => $dbase ),

        #    popup_menu(-name=>'Host', -values=>['limsdev01','lims-dbm'],-default=>$Defaults{SQL_HOST},-force=>1),&hspace(20),
        #    popup_menu(-name=>'Database', -values=>\@databases,-default=>$dbase,-force=>1),&hspace(20),
        submit( -name => 'Home', -value => 'Refresh Protocol List', -class => 'Std' ), &vspace(5), "<h2>Select Protocol: </h2>",
        &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'Protocol',
        -name    => 'Protocol',
        -options => \@protocols,
        -filter  => 1,
        -search  => 1
        ),
        p, br,

        #    popup_menu(-name=>'Protocol', -values=>[@protocols],-default=>$protocol),p,br,
        submit( -name => 'View Protocol', -class => 'Std' ), checkbox( -name => 'Include Instructions', -label => ' Include Instructions' );

    if ( $admin && $user_id ) {
        print hr, h3("Administrative Functions:"), submit( -name => 'Create New Protocol', -class => 'Std' ), submit( -name => 'Delete Protocol', -class => 'Action' ), '<br>' . textfield( -name => 'Protocol Name', -size => 20 ), &hspace(10),
            submit( -name => 'Edit Protocol Name', -class => 'Action' ), '<br>' . submit( -name => 'Edit Protocol Visibility', -class => 'Std' ) . HTML_Comment(" (which groups have access)"),

            #      <CONSTRUCTION> - need to update storage and retrieval of old versions of protocol
            #	'<br>' . submit(-name=>'View Old Protocol',-class=>'Std'),br,hr,
            submit( -name => 'Restrict Access', -class => 'Action' );
    }
    else {
        print submit( -name => 'Administrative Access', -class => 'Std' );
    }

    print hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'User', -value => "$user_name" ), hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 ),
        hidden( -name => 'Admin', -value => "$admin", -force => 1 ), br, end_form;

    return;
}

######################
sub view_protocol {

    #
    # Generates an abbreviated view of the entire protocol in
    # a table.  Information in the table include the step number
    # and the instructions for that step.
######################
    my $condition;
    my $fields;
    my $select;
    my $protocol = param('Protocol') || param('Protocol Choice');
    $protocol =~ s/\+/ /g;
    my $datefield;
    my $instr = param('Include Instructions');

    print h1("Database: $dbase");
    my $step;
    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        print "<H2>Maintenance Protocol: <span class=vdarkpurple>$protocol </span></H1><BR>";
        $fields    = "Step,Maintenance_Step_Name,Maintenance_Protocol_ID,Maintenance_Instructions";
        $datefield = "Protocol_Date";
        $condition = "where FK_Service__Name = $Qprotocol";

        # display the servicing frequency for this protocol
        my ( $interval, $interval_units ) = split ',', ( join ',', Table_find( $dbc, 'Service', 'Service_Interval,Interval_Frequency', "where Service_Name = $Qprotocol" ) );
        print "<span class=vdarkblue><B>Performed once every $interval $interval_units(s).</B></span><p>";
        $step = 'Step';

    }
    elsif ( $TableName =~ /^Protocol/ ) {
        print "<H2>Protocol: <span class=vdarkpurple>$protocol </span></H1><BR>";
        $datefield = "Protocol_Step_Changed";
        $fields    = "Protocol_Step_Number,Protocol_Step_ID,Scanner,Protocol_Step_Name,Input,Protocol_Step_Defaults,Input_Format,Protocol_Step_Message,QC_Condition,Validate";
        if ($instr) { $fields .= ",Protocol_Step_Instructions"; }
        $condition = "where FK_Lab_Protocol__ID=$Qprotocol_id";
        $step      = 'Protocol_Step_Number';
    }

    $select = "select $datefield, Initials from $TableName,Employee";
    my $query = "$select $condition and FK_Employee__ID = Employee_ID ORDER BY $datefield DESC LIMIT 1";

    my $sth = $dbc->dbh()->prepare($query);
    $sth->execute();
    my ( $date, $initials ) = $sth->fetchrow_array;

    my $number_steps = join ',', Table_find( $dbc, $TableName, 'count(*)', $condition );
    print "<span class=vdarksepiatext><B>This protocol has $number_steps Steps.<BR>Last edited by $initials on $date.</B></span>";

    $condition .= " order by $step";

    #my @data = Table_find($dbc,$TableName,$fields,$condition);
    my @fields_arr = split ",", $fields;
    my %data = Table_retrieve( $dbc, $TableName, \@fields_arr, $condition );

    #    print start_barcode_form('protocol'),

    # print start_custom_form('protocol',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'protocol',
        -type => 'start'
    );
    print hidden( -name => 'Database',           -value => $dbase,              -force => 1 );
    print hidden( -name => 'Host',               -value => $host,               -force => 1 );
    print hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 );
    print hidden( -name => 'Session',            -value => $session_id );

    #    <CONSTRUCTOR> rewrite table with html_table </CONSTRUCTOR>
    #    my $table = HTML_Table->new(-width=>'800');
    #    $table->Set_Padding(8);
    #    $table->Set_Spacing(0);
    #    $table->Set_Headers(['Step Number','Scanner','Step Name','Input','Delete']);

    print "\n<TABLE border=0 cellspacing=0 cellpadding=8><TR>\n";
    foreach my $field ( split /,/, $fields ) {
        $field =~ s/Protocol_|Maintenance_|FK_//;
        $field =~ s/_/ /g;
        if ( $field !~ /ID$/ ) {
            if ( $field =~ /Name/ ) {
                print "<TD width=85 class=vdarkblue><H2><span class=vdarkbluebw>$field</span></H2></TD>\n";
            }
            elsif ( $field =~ /Default/ ) {
                next;    ######## include defaults with Input ...
            }
            elsif ( $field =~ /Message/ ) {
                next;    ######## include Nessage with Step Name ...
            }
            elsif ( $field =~ /Format/ ) {
                next;    ######## include Nessage with Step Name ...
            }
            elsif ( ( $field =~ /Instructions/ ) && !$instr ) {
                next;    ######## do not display instructions unless indicated ...
            }
            elsif ( $field =~ /Validate|QC/i ) {
                next;
            }
            else {
                print "<TD width=25 class=vdarkblue><H2><span class=vdarkbluebw>$field</span></H2></TD>\n";
            }
        }
    }
    if ( $admin && $user_id ) {
        print "<TD class=vdarkblue><H2><span class=vdarkbluebw>Delete</span></H2></TD>\n";
    }

    my $colour;

    #foreach my $x (@data) {
    if ( $TableName =~ /^Protocol/ ) {
        my $index = -1;
        while ( defined $data{Protocol_Step_ID}[ ++$index ] ) {
            my $step         = $data{Protocol_Step_Number}[$index];
            my $protocol_id  = $data{Protocol_Step_ID}[$index];
            my $scanner      = $data{Scanner}[$index];
            my $step_name    = $data{Protocol_Step_Name}[$index];
            my $input        = $data{Input}[$index];
            my $defaults     = $data{Protocol_Step_Defaults}[$index];
            my $formats      = $data{Input_Format}[$index];
            my $message      = $data{Protocol_Step_Message}[$index];
            my $QC           = $data{QC_Condition}[$index];
            my $validate     = $data{Validate}[$index];
            my $instructions = $data{Protocol_Step_Instructions}[$index];

            # the instructions must be at the end because we are limiting the splitting
            # because the instructions themselves may have commas in them
            #my ($step,$protocol_id,$scanner,$step_name,$input,$defaults,$formats,$message, $QC,$validate,$instructions) = split ',',$x;  ## ,8 ?
            my $step_link = submit(
                -name    => 'Step Details',
                -value   => $step_name,
                -onClick => "SetSelection(document.protocol,'Edit Step','true',$protocol_id)"
            );

            $colour = toggle($colour);
            print "<TR><TD align=left bgcolor=#EEEEDD><H3><BR>", "<INPUT TYPE=\"radio\" NAME=\"Edit Step\" VALUE=\"$protocol_id\" STYLE=\"background-color:EEEEDD\">", "$step</H3></TD>";
            if ($scanner) {
                print "<TD align=center bgcolor=$colour><IMG src='/$URL_dir_name/$image_dir/checkmark.png'></TD>";
            }
            else {
                print "<TD align=center bgcolor=$colour>&nbsp;</TD>";
            }

            print "<TD align=left bgcolor=$colour><BR><H3>$step_link</H3>$message</TD>";

            ########## display list of input... ###############
            my @formatted_input;
            my @formatted_defaults;
            my @input_formats;
            my $format = "";
            if ($input) {
                @formatted_defaults = split ':', $defaults;
                @formatted_input    = split ':', $input;
                @input_formats      = split ':', $formats;
                $format             = "<UL>";
                my $index = 0;

                foreach my $input (@formatted_input) {
                    my $Iformat = $input_formats[$index];
                    if ( $Iformat =~ /NULL/ ) { $Iformat = ''; }
                    $format .= "<LI>$input ($formatted_defaults[$index]) ($Iformat)";
                    $index++;
                }
                if ( $validate || $QC ) {
                    my $qc = "Attribute check;" if $QC;
                    $qc .= "Validate $validate;" if $validate;
                    $format .= "<LI>" . Show_Tool_Tip( "<B><Font color=red>** QC **", "$qc" );
                }

                $format .= "</UL>";
                $format =~ s/FK_Equipment__ID/Equip/g;
                $format =~ s/Prep_Comments/Comments /g;
                $format =~ s/Prep_/Prep /g;
                $format =~ s/Plate_/Plate /g;
                $format =~ s/FK_Solution__ID/Solution/g;
                $format =~ s/FK_Plate__ID/Plate/g;
                $format =~ s/Solution_Quantity/Sol Qty/g;
                $format =~ s/FK_Rack__ID/Rack/g;
            }
            print "<TD align=left bgcolor=$colour>$format</TD>";
            if ($instr) {
                print "<TD align=left bgcolor=$colour>&nbsp;$instructions</TD>";
            }
            if ( $admin && $user_id ) {
                print "<TD class=vlightred align=center><INPUT TYPE=\"checkbox\" NAME=\"Mark\" VALUE=\"$protocol_id\"></TD>";
            }
            "</TR>";
        }
    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {
        my $index = -1;
        while ( defined $data{Protocol_Step_ID}[ ++$index ] ) {
            my $step         = $data{Step}[$index];
            my $step_name    = $data{Maintenance_Step_Name}[$index];
            my $Qprotocol_id = $data{Maintenance_Protocol_ID}[$index];
            my $instructions = $data{Maintenance_Instructions}[$index];

            # the instructions must be at the end because we are limiting the splitting
            # because the instructions themselves may have commas in them
            #my ($step,$step_name,$Qprotocol_id,$instructions) = split ',',$x,4;
            $colour = toggle($colour);
            print "<TR><TD align=center bgcolor=#EEEEDD><H3><BR>", "<INPUT TYPE=\"radio\" NAME=\"Edit Step\" VALUE=\"$protocol_id\" STYLE=\"background-color:EEEEDD\">", "$step</H3></TD>";
            print "<TD align=left bgcolor=$colour><H3><BR>$step_name</H3></TD>";
            print "<TD align=left bgcolor=$colour>&nbsp;$instructions</TD>";
            if ( $admin && $user_id ) {
                print "<TD class=vlightred align=center><INPUT TYPE=\"checkbox\" NAME=\"Mark\" VALUE=\"$protocol_id\"></TD>";
            }
            print "</TR>";
        }
    }

    #}

    print "</TABLE>", lbr;

    #    $table->Printout();

    print hidden( -name => 'Protocol', -value => $protocol, -force => 1 ), hidden( -name => 'Admin', -value => $admin, -force => 1 ), hidden( -name => 'User ID', -value => $user_id );

    if ( $admin && $user_id ) {
        my ($state) = &Table_find( $dbc, 'Lab_Protocol', 'Lab_Protocol_Status', "where Lab_Protocol_ID=$Qprotocol_id" );
        print submit(
            -name  => 'Step Details',
            -value => 'View / Edit Step Details',
            -class => 'Std'
            )
            . &hspace(10), Show_Tool_Tip( submit( -name => 'Add Step', -class => 'Std' ), "(Will occur before selected step - or at the end if none selected) " ) . &hspace(10), submit( -name => 'Delete Step(s)', -class => 'Action' ), hr,
            submit(
            -name  => 'Edit Protocol Visibility',
            -label => 'Set Groups',
            -class => 'Std'
            ),
            &hspace(10), submit( -name => 'Save As New Protocol', -class => 'Action' ), &vspace(10), textfield( -name => 'Protocol Name', -size => 20 ), &hspace(10), submit( -name => 'Edit Protocol Name', -class => 'Action' ), &vspace(10),

            scrolling_list(
            -name    => 'State',
            -values  => [ 'Active', 'Old', 'Inactive' ],
            -default => $state
            ),
            &hspace(5), submit( -name => 'Change Status', -class => 'Action' ), hr,
            alDente::Grp::display_groups(
            'Lab_Protocol', $protocol_id,
            -output       => 'name',
            -noadd        => 1,
            -child_groups => 'n'
            ),
            hr;
        print submit( -name => 'Restrict Access', -class => 'Action' );
        print submit( -name => 'View Protocol', -class => 'Std' ) . checkbox( -name => 'Include Instructions', -label => ' Include Instructions' );
    }
    else {
        print submit( -name => 'Step Details', -value => 'View Step Details', -class => 'Std' );
    }

    print &vspace(2)
        . submit(
        -name  => 'Back to Home',
        -class => 'Std',
        -label => 'Back to Protocol Admin Page'
        );

    print end_form;
    return;
}

#######################
sub addstep {

    #
    # Generates the web-form for creating a new step in the protocol
#######################
    my $id = shift;
    my $new_flag;
    my $number_steps;
    my @fields;

    my ($new_step) = &Table_find( $dbc, 'Protocol_Step', 'Protocol_Step_Number', "WHERE Protocol_Step_ID = $id" ) if $id;

    # print start_custom_form(-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'Protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    print hidden( -name => 'Database', -value => $dbase ) . hidden( -name => 'Host', -value => $host ) . hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 );
    ##### maintenance protocols
    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        my $default_interval;
        my $default_units;

        # if adding a step to an existing protocol...
        if ($protocol) {
            @fields           = qw(Step Maintenance_Step_Name Maintenance_Instructions);
            $default_interval = join ',', Table_find( $dbc, 'Service', 'Service_Interval', "where Service_Name = $Qprotocol" );
            $default_units    = join ',', Table_find( $dbc, 'Service', 'Interval_Frequency', "where Service_Name = $Qprotocol" );
            ($number_steps) = &Table_find( $dbc, 'Maintenance_Step', 'Max(Maintenance_Step_Number)', "where FK_Maintenance_Protocol__ID=$Qprotocol_id" );

            $new_step ||= $number_steps + 1;
            print h1("Adding New Step ($new_step) to '$protocol'");

            # else creating a new protocol
        }
        else {
            @fields = qw(FK_Service__Name Step Maintenance_Step_Name Maintenance_Instructions);
            print h1("Creating New Maintenance Protocol");
            my $fields = join ',', @fields;
            $new_flag = 1;
        }

        ######## plate protocols
    }
    elsif ( $TableName =~ /^Protocol/ ) {
        @fields = qw(FK_Lab_Protocol__ID Protocol_Step_Number Protocol_Step_Name Scanner Protocol_Step_Message Protocol_Step_Instructions Input);

        if ($protocol) {    # if adding a step to an existing protocol
            ($number_steps) = &Table_find( $dbc, 'Protocol_Step', 'Max(Protocol_Step_Number)', "where FK_Lab_Protocol__ID=$Qprotocol_id" );
            if ($new_step) {
                $new_step++;
            }
            $new_step ||= $number_steps + 1;
            print h2("Adding New Step ($new_step) to $protocol");
        }
        else {              # if creating a brand new protocol
            print "First define new protocol - then add steps one at a time.  (or save current protocol under a new name)";
            return 0;
        }
    }

    Protocol_form( 0, \@fields, $new_step, -enable_scanner => 1 );

    print "<H3><span class=mediumredtext>**</span> indicates that the field is required</H3></span>";
    if ( $TableName =~ /^Protocol/ ) {
        print "<H3>NOTE: The 'Step Name' field must be a unique name for any given protocol", "and may be limited by a <a href='http://limsdev01/SDB/cgi-bin/barcode.pl?Online+Help=Protocol+Formats'>Defined format</a></H3><BR>";

        #	    &Link_To($helplink,'Defined format',"&Online+Help=Protocol+Formats",$Settings{LINK_COLOUR},['newwin']) .";
    }

    print hidden( -name => 'Protocol', -value => $protocol, -force => 1 ), hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'Admin', -value => "$admin", -force => 1 );

    if ($new_flag) {
        print hidden( -name => 'New', -value => $protocol );
    }
    print &vspace(5), submit( -name => 'Save Step', -class => 'Action' ), reset( -name => 'Clear Fields', -class => 'Std' ), p,
        submit(
        -name  => 'View Protocol',
        -style => "background-color:$Settings{SEARCH_BUTTON_COLOUR}"
        ),
        checkbox( -name => 'Include Instructions', -label => ' Include Instructions' ), br, submit( -name => 'Home', -class => 'Std', -label => 'Back to Protocol Admin Page' ), br;

    if ( $admin && $user_id ) {
        print hr, submit( -name => 'Restrict Access', -class => 'Action' );
    }
    print end_form;
}

#######################
sub editstep {

    #
    # Displays the details of a particular step. If the user has administrative
    # access, then changes can be made to the step and saved in the database.
#######################
    my $id = shift;

    if ( !$id ) {
        return 0;
    }

    #print start_custom_form(-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'Protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    Protocol_form( $id, -enable_scanner => 1 );
    print hidden( -name => 'ID', -value => "$id", -force => 1 ), hidden( -name => 'Database', -value => "$dbase" ), hidden( -name => 'Host', -value => "$host" ), lbr, hidden( -name => 'Protocol', -value => "$protocol" ),
        hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'Mark', -value => "$id" ), hidden( -name => 'Admin', -value => "$admin", -force => 1 );

    print br,
        submit(
        -name  => 'View Protocol',
        -style => "background-color:$Settings{SEARCH_BUTTON_COLOUR}"
        ),
        checkbox( -name => 'Include Instructions', -label => ' Include Instructions' ), br, submit( -name => 'Home', -class => 'Std', -label => 'Back to Protocol Admin Page' ), br;

    if ( $admin && $user_id ) {
        print hr, h3("Administrative Functions:"),

            #	submit(-name=>'Save MAJOR Changes',-class=>'Action'),
            #	"<span class=darkredtext> eg. Added a new step or changed the protocol defaults.</span><br>",
            submit( -name => 'Save Changes', -class => 'Action' ),

            #	"<span class=darkredtext> eg. Changed the scanner flag or corrected a spelling mistake.</span><br>",
            submit( -name => 'Delete Step', -class => 'Action' ), hr, submit( -name => 'Restrict Access', -class => 'Action' );
    }
    print end_form;
    return 1;
}

######################
sub Protocol_form {
######################

    my %args = &filter_input( \@_, -args => 'id,field_ref,step_num' );

    my $id             = $args{-id};
    my $field_ref      = $args{-field_ref};
    my $step_num       = $args{-step_num};
    my $enable_scanner = $args{-enable_scanner} || 1;
    my $previous_step_id;
    my $next_step_id;
    my $number_steps;
    my $instructions;
    my @fields = @$field_ref if $field_ref;

    my @plate_attributes = Table_find( $dbc, 'Attribute', 'Attribute_Name', "Where Attribute_Class='Plate'" );
    unshift( @plate_attributes, '' );
    my $D_plateattr = '';
    my $definePlateAttribute_link = &Link_To( "barcode.pl?", 'Define New', "Database=$dbase&Define+Attribute=Plate", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => "Please reload the page after defining a new attribute" );

    my $Page = HTML_Table->new( -colour => 'white', -border => 1 );
    ##### maintenance protocols
    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        @fields = qw(Step Maintenance_Step_Name Maintenance_Instructions);
        my $temp = join ',', Table_find( $dbc, 'Maintenance_Protocol', join( ',', @fields ), "where Maintenance_Protocol_ID = $id" );
        my @data = split ',', $temp, scalar(@fields);
        my $instructions = $data[$#data];

        $number_steps = join ',', Table_find( $dbc, 'Maintenance_Protocol', 'count(*)', "where FK_Service__Name = $Qprotocol" );
        my $index;
        my @interval_units = qw(Year Month Day Week);

        #		my @type = Table_find($dbc,'Equipment','Equipment_Type',undef,'Distinct');
        my $default_type = join ',', Table_find( $dbc, 'Service', 'FK_Equipment__Type', "where FK_Service__Name = $Qprotocol" );

        my $interval      = join ',', Table_find( $dbc, 'Service', 'Service_Interval',   "where Service_Name = $Qprotocol", "limit 1" );
        my $default_units = join ',', Table_find( $dbc, 'Service', 'Interval_Frequency', "where Service_Name = $Qprotocol", "limit 1" );

        my $count = 0;
        ( $previous_step_id, $next_step_id ) = &next_previous( $dbc, 'Maintenance_Protocol', $protocol, $id );

        print hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Host', -value => $host ), hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 ), "<TABLE border=0 cellpadding=0>";
        foreach my $field_name (@fields) {
            $field_name =~ s/Maintenance_//;
            $field_name =~ s/_/ /g;

            if ( $field_name =~ /Step/ ) {
                $Page->Set_Row(
                    [   "<H4>$field_name:</H4>",
                        textfield(
                            -name  => $field_name,
                            -size  => 40,
                            -value => 'Something',
                            -force => 1
                        )
                    ]
                );
                if ( $field_name =~ /Name/ ) {
                    $Page->Set_Row(
                        [   "<H4>Equipment Type:</H4>",
                            popup_menu(
                                -name    => 'Type',
                                -values  => [ '', '--- Categories ---', @Categories, '--- Sub_Categories ---', @Sub_Categories ],
                                -default => "$default_type"
                            ),
                            popup_menu(
                                -name    => 'Interval',
                                -values  => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
                                -default => "$interval"
                                )
                                . popup_menu(
                                -name    => 'Interval Units',
                                -values  => [@interval_units],
                                -default => "$default_units"
                                )
                        ]
                    );
                }

            }
            elsif ( $field_name =~ /Instruction/ ) {
                $Page->Set_Row(
                    [   "<H4>$field_name:</H4>",
                        textarea(
                            -name => $field_name,
                            -cols => 80,
                            -rows => 5,
                            -wrap => 'virtual'
                        )
                    ]
                );
            }
            $index++;
        }

#### plate protocols
    }
    elsif ( $TableName =~ /^Protocol/ ) {
        my $scanner = 0;
        if ($enable_scanner) { $scanner = 1; }
        my @inputs;
        my @defaults;
        my @formats;
        my $mix;
        my $quant_pos;
        my @prepattr_pos;
        my @plateattr_pos;
        my $time_pos;
        my $sol_pos;      ### add index for position of solution in list of inputs..
        my $equ_pos;      ### add index for position of equipment in list of inputs..
        my $rack_pos;     ### add index for rack condition list...
        my $split_pos;    ### add index for split x default
        my $track_pos;    ### index for Track_Transfer
        my $label_pos;

        print h1("Protocol: $protocol");
        my @field1 = qw(Protocol_Step_Number Protocol_Step_Name Scanner FKQC_Attribute__ID QC_Condition Validate);
        my @field2 = qw(Protocol_Step_Message Protocol_Step_Instructions Input);

        # retrieve the step details from the database
        my $message = join /,/, Table_find( $dbc, $TableName, 'Protocol_Step_Message', "where Protocol_Step_ID = $id" );
        $instructions = join /,/, Table_find( $dbc, $TableName, 'Protocol_Step_Instructions', "where Protocol_Step_ID = $id" );

        my $fields = join ',', @field1;
        my $temp_data = join ',', Table_find( $dbc, $TableName, $fields, "where Protocol_Step_ID = $id" );
        my @data = split ',', $temp_data, scalar(@fields);

        if ( $data[$#data] ) {
            $scanner = 1;
        }

        @inputs   = split( ':', join( ',', ( Table_find( $dbc, $TableName, 'Input',                  "where Protocol_Step_ID = $id" ) ) ) );
        @defaults = split( ':', join( ',', ( Table_find( $dbc, $TableName, 'Protocol_Step_Defaults', "where Protocol_Step_ID = $id" ) ) ) );
        @formats  = split( ':', join( ',', ( Table_find( $dbc, $TableName, 'Input_Format',           "where Protocol_Step_ID = $id" ) ) ) );

        for my $count ( 0 .. $#inputs ) {
            if ( $inputs[$count] =~ /Mixture\((\d+)\)/ ) {
                $mix = $1;    # the number of mixture of reagents
            }
            elsif ( $inputs[$count] =~ /Solution_Quantity/ ) {
                $quant_pos = $count;

                #} elsif ($inputs[$count] =~ /Time/) {
                #	$time_pos = $count;
            }
            elsif ( $inputs[$count] =~ /FK_Equipment__ID/ ) {
                $equ_pos = $count;
            }
            elsif ( $inputs[$count] =~ /FK_Solution__ID/ ) {
                $sol_pos = $count;
            }
            elsif ( $inputs[$count] =~ /FK_Rack__ID/ ) {
                $rack_pos = $count;
            }
            elsif ( $inputs[$count] =~ /Track_Transfer/ ) {
                $track_pos = $count;
            }
            elsif ( $inputs[$count] =~ /Plate_Label/ ) {
                $label_pos = $count;
            }
            elsif ( $inputs[$count] =~ /Split/ ) {
                $split_pos = $count;
            }
            elsif ( $inputs[$count] =~ /Plate_Attribute/ ) {
                push( @plateattr_pos, $count );
            }
            elsif ( $inputs[$count] =~ /Prep_Attribute/ ) {
                push( @prepattr_pos, $count );
            }
        }
        @fields = ( @field1, @field2 );

        ($number_steps) = &Table_find( $dbc, $TableName, 'count(*)', "where FK_Lab_Protocol__ID=$Qprotocol_id" );

        # determine the previous and next step in the protocol
        ( $previous_step_id, $next_step_id ) = next_previous( $dbc, $TableName, $protocol, $id );

        my $index = 0;
        print hidden(
            -name  => 'Current_Department',
            -value => $Current_Department,
            -force => 1
            ),
            hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Host', -value => $host );

        # display all the step details in a web-form
        foreach my $field_name (@fields) {
            $field_name =~ s/Protocol_//;
            $field_name =~ s/_/ /g;

            if ( $field_name =~ /Step.Name/ ) {
                my $default_type      = 'Standard';
                my $step_name         = $data[$index];
                my $new_sample        = 0;
                my $new_sample_type   = '';
                my $plate_format      = '';
                my $create_new_sample = 0;
                my $sample_check      = 0;
                $field_name = 'Step_Name';

                #if ($step_name =~ /(Transfer|Aliquot|Extract)\s+(\w*)\s*to\s*(.*)(\(Track New Sample\))?$/i) {#
                if ($step_name =~ /^
                        (Transfer|Aliquot|Extract)\s+     ## special cases
                         (\#\d+\s)?                           ## optional for multiple steps with similar name (eg Transfer #2 to ..)
                        ([\s\w\-]*)\s*                             ## optional new extraction type
                        to\s+                                ## ... to .. (type)
                        ([\s\w\.\-]+)                        ## mandatory target type
                        (.*)              ## special cases for suffixes (optional)
                        $/xi
                    )
                {

                    #if ($step_name =~ /(.*)\s*(\(Track New Sample\))?$/i) {
                    $default_type = $1;
                    $plate_format = chomp_edge_whitespace($4);
                    if ($3) {
                        $new_sample      = 1;
                        $new_sample_type = chomp_edge_whitespace($3);
                    }

                    if ( $5 =~ /Track New Sample\)/ ) {
                        $sample_check = 1;
                    }
                }
                elsif ( $step_name =~ /^(Pre-Print)\s+to\s+(.*)/i || $step_name =~ /^(Pool)\s+to\s+(.*)/i || $step_name =~ /^(Setup)\s+to\s+(.*)/i ) {
                    $default_type = $1;
                    $plate_format = $2;
                }

                my @sample_types = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE 1" );

                my $Step = HTML_Table->new( -colour => 'lightyellow' );
                $Step->Set_Row(
                    [   Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Standard' onClick="document.thisform.$field_name.value=''; document.thisform.$field_name.disabled = 0; document.thisform.Step_Format.value = ''; document.thisform.Step_Format.disabled = 1; document.thisform.New_Sample_Type.value = ''; document.thisform.New_Sample_Type.disabled = 1;" @{[($default_type eq 'Standard') ? 'checked' : 0]}>Standard</input>},
                            $Tooltips{Step_Type}{Standard}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Transfer'  onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Transfer') ? 'checked' : 0]}>Transfer</input>},
                            $Tooltips{Step_Type}{Transfer}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Aliquot'   onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Aliquot') ? 'checked' : 0]}>Aliquot</input>},
                            $Tooltips{Step_Type}{Aliquot}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Extract'   onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Extract') ? 'checked' : 0]}>Extract</input>},
                            $Tooltips{Step_Type}{Extract}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Pool'      onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Pool') ? 'checked' : 0]}>Pool</input>},
                            $Tooltips{Step_Type}{Pool}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Pre-Print' onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Pre-Print') ? 'checked' : 0]}>Pre-Print</input>},
                            $Tooltips{Step_Type}{'Pre-Print'}
                            )
                            . hspace(5)
                            . Show_Tool_Tip(
                            qq{<input type='radio' name='Step_Type' value='Setup' onClick="document.thisform.$field_name.value='$Disabled_Step_Name'; document.thisform.$field_name.disabled = 1; document.thisform.Step_Format.disabled = 0; document.thisform.New_Sample_Type.disabled = 0;" @{[($default_type eq 'Setup') ? 'checked' : 0]}>Setup</input>},
                            $Tooltips{Step_Type}{'Setup'}
                            )
                    ]
                );
                $Step->Set_Row(
                    [   Show_Tool_Tip(
                            textfield(
                                -name  => $field_name,
                                -size  => 30,
                                -value => $data[$index],
                                -force => 1
                            ),
                            "Brief (Unique) name for this step."
                            )
                            . "(Keep BRIEF)"
                    ]
                );

                $Step->Set_Row(
                    [   'Extract Type: '
                            . Show_Tool_Tip(
                            popup_menu(
                                -name    => 'New_Sample_Type',
                                -values  => [ '', @sample_types ],
                                -default => $new_sample_type
                            ),
                            "ONLY select if the sample type is CHANGING during this step."
                            )
                            . ' <i>(if extracting new type)</i>'
                            . Show_Tool_Tip(
                            checkbox(
                                -name    => 'Create_New_Sample',
                                -value   => 'Create_New_Sample',
                                -label   => 'Track New Sample',
                                -checked => $sample_check,
                                -force   => 1
                            )
                            )
                    ]
                );
                $Step->Set_Row(
                    [   ' Target Type: '
                            . Show_Tool_Tip(
                            popup_menu(
                                -name    => 'Step_Format',
                                -values  => [ '', @plate_formats ],
                                -default => $plate_format,
                                -force   => 1
                            ),
                            "Choose target type when tracking sample transfers"
                            )
                    ]
                );

                $Page->Set_Row( [ "<H4><A Href='$helplink&User=$user_name&Online+Help=Protocol+Formats'>$field_name</A><span class=mediumredtext>**</span>: </H4>", $Step->Printout(0) ] );

            }
            elsif ( $field_name =~ /Step.Number/ ) {
                my $Def_num = $step_num || $data[$index] || $number_steps;
                $Page->Set_Row(
                    [   "<H4>$field_name<span class=mediumredtext>**</span>: </H4>",
                        textfield(
                            -name  => 'Step Number',
                            -size  => 5,
                            -value => $Def_num,
                            -force => 1
                        )
                    ]
                );
            }
            elsif ( $field_name =~ /Instruction/ ) {
                $Page->Set_Row(
                    [   "<H4>$field_name</H4>",
                        Show_Tool_Tip(
                            textarea(
                                -name  => "$field_name",
                                -value => "$instructions",
                                -force => 1,
                                -cols  => 80,
                                -rows  => 5,
                                -wrap  => 'virtual'
                            ),
                            "More detailed instructions available to user only if requested"
                        )
                    ]
                );
            }
            elsif ( $field_name =~ /Message/ ) {
                $Page->Set_Row(
                    [   "<H4>$field_name:<BR>(concise)</H4>",
                        Show_Tool_Tip(
                            textfield(
                                -name  => 'Message',
                                -value => "$message",
                                -force => 1,
                                -size  => 40
                            ),
                            "Concise message - will be displayed on handheld scanners"
                        )
                    ]
                );

            }
            elsif ( $field_name =~ /Input/ ) {
                my $input = join( ',', @inputs );

                ### Table for Input options ###
                my $Input = HTML_Table->new( -border => 1, -width => '100%' );

                $Input->Set_Headers( [ 'Input', 'Mandatory', 'Format', 'Default' ], 'lightbluebw' );

                ## Equipment ##
                my $E_check = ( $input =~ /FK_Equipment__ID/ );    ## currently set to checked
                my @E_format = '';
                if ($E_check) {
                    @E_format = split( '\|', $formats[$equ_pos] );
                }
                my $mand_fk_equ = ( $input =~ /Mandatory_Equipment/ );

                my $mandatory_equ_check = checkbox(
                    -name    => 'Input',
                    -value   => 'Mandatory_Equipment',
                    -checked => $mand_fk_equ,
                    -force   => 1,
                    -label   => ''
                );
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'FK_Equipment__ID',
                                -label   => 'Equipment',
                                -checked => $E_check,
                                -force   => 1
                            ),
                            "Prompt user for equipment used for this step"
                        ),
                        $mandatory_equ_check,
                        Show_Tool_Tip(
                            scrolling_list(
                                -name     => 'MFormat',
                                -values   => [ '', '--- Categories ---', @Categories, '--- Sub_Categories ---', @Sub_Categories ],
                                -default  => \@E_format,
                                -force    => 1,
                                -multiple => 1,
                                -size     => 5
                            ),
                            "Specify Equipment Category to validate for<BR>* Hold down the Control key to select multiple<BR>* Specific Sub_Categories are listed after main Categories below"
                        ),
                        '&nbsp'
                    ]
                );
                my @plates_unit_list = &get_enum_list( $dbc, 'Plate', 'Current_Volume_Units' );

                ## Solutions ##
                my $S_check = ( $input =~ /FK_Solution__ID/ );    ## currently set to checked
                my ( $Qty_default, $Qty_units ) = ( '', 'mL' );
                my $S_format = '';
                if ($S_check) {
                    ( $Qty_default, $Qty_units ) = RGTools::Conversion::get_amount_units( lc $defaults[$quant_pos] );
                    $S_format = $formats[$sol_pos];
                }
                my $mand_fk_sol = ( $input =~ /Mandatory_Solution/ );

                my $mandatory_sol_check = checkbox(
                    -name    => 'Input',
                    -value   => 'Mandatory_Solution',
                    -checked => $mand_fk_sol,
                    -force   => 1,
                    -label   => ''
                );
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'FK_Solution__ID',
                                -label   => 'Solution',
                                -checked => $S_check,
                                -force   => 1
                            ),
                            "Prompt user for reagent/solution used for this step"
                        ),
                        $mandatory_sol_check,
                        Show_Tool_Tip(
                            textfield(
                                -name    => 'SFormat',
                                -default => $S_format,
                                -size    => 15,
                                -force   => 1
                            ),
                            "Specify name pattern of solution required.  Stock used must CONTAIN this string.  (use | for multiple possibilities ..eg. 'H20|Water')"
                            )
                            . '<font size=-2> (optional)</font>',
                        "Qty: "
                            . textfield(
                            -name  => 'Quantity',
                            -value => $Qty_default,
                            -size  => 8,
                            -force => 1
                            )
                            . popup_menu(
                            -name    => "Quantity_Units",
                            -values  => \@plates_unit_list,
                            -default => $Qty_units
                            )
                    ]
                );

                ###my $Sample_check = ($input=~/Create_New_Sample/);
                ###$Input->Set_Row([Show_Tool_Tip(checkbox(-name=>'Input',-value=>'Create_New_Sample',-label=>'Track New Sample',-checked=>$Sample_check,-force=>1),
                ###				  "")
                ###		    ]);
                ## Transfer ##
                my $T_check = ( $input =~ /Track_Transfer/ );
                my ( $T_qty, $T_units ) = ( '', 'mL' );
                if ($T_check) {
                    ( $T_qty, $T_units ) = RGTools::Conversion::get_amount_units( lc $defaults[$track_pos] );
                }
                my $split_check = ( $input =~ /Split/ );
                my $split_value = 0;
                if ($split_check) {

                    #$split_value = $split_pos;
                    $split_value = $defaults[$split_pos];
                }
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'Track_Transfer',
                                -label   => 'Track Transfer Qty',
                                -checked => $T_check,
                                -force   => 1
                            ),
                            "For Transfer/Aliquot/Pool steps only:  Prompt user to supply volume to transfer between containers (if applicable)"
                            )
                            . "<font size =-2> (required for splitting)</font>",
                        "&nbsp", "&nbsp",
                        "Qty: "
                            . textfield(
                            -name  => "Transfer_Quantity",
                            -size  => 8,
                            -value => $T_qty,
                            -force => 1
                            )
                            . ' '
                            . popup_menu(
                            -name    => "Transfer_Quantity_Units",
                            -values  => \@plates_unit_list,
                            -default => $T_units,
                            -force   => 1
                            )
                    ]
                );
                $Input->Set_Row(
                    [   checkbox(
                            -name    => 'Input',
                            -value   => 'Split',
                            -label   => 'Split',
                            -checked => $split_check,
                            -force   => 1
                        ),
                        "&nbsp", "&nbsp",
                        "Split:"
                            . textfield(
                            -name  => "Split_X",
                            -size  => 8,
                            -value => $split_value,
                            -force => 1
                            )
                    ]
                );

                ## Rack ##
                my $R_check         = ( $input =~ /Rack/ );
                my $PrepAttr_check  = ( $input =~ /Prep_Attribute/ );
                my $PlateAttr_check = ( $input =~ /Plate_Attribute/ );
                my $Time_check      = ( $input =~ /Time/ );
                my $Comments_check  = ( $input =~ /Comments/ );
                my $Inherited_check = ( $input =~ /Comments/ );

                my $D_rack = $formats[$rack_pos] if $R_check;

                my $mand_rack = ( $input =~ /Mandatory_Rack/ );
                my $mandatory_rack_check = checkbox(
                    -name    => 'Input',
                    -value   => 'Mandatory_Rack',
                    -checked => $mand_rack,
                    -force   => 1,
                    -label   => ''
                );
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'FK_Rack__ID',
                                -label   => 'Location',
                                -checked => $R_check,
                                -force   => 1
                            ),
                            "Prompt user for rack on which to place target plates"
                        ),
                        $mandatory_rack_check,
                        Show_Tool_Tip(
                            popup_menu(
                                -name    => 'Equipment_Condition',
                                -values  => \@Equ_Condition,
                                -default => $D_rack,
                                -force   => 1
                            ),
                            "Specify conditions for target rack (optional)"
                        ),
                        '&nbsp'
                    ]
                );

                ## Prep Conditions ##
                my @prep_attributes = Table_find( $dbc, 'Attribute', 'Attribute_Name', "Where Attribute_Class='Prep'" );
                unshift( @prep_attributes, '' );
                my $D_prepattr = '';
                my $definePrepAttribute_link = &Link_To( "barcode.pl?", 'Define New', "Database=$dbase&Define+Attribute=Prep", $Settings{LINK_COLOUR}, ['newwin'], -tooltip => "Please reload the page after defining a new attribute" );

                if ( scalar(@prepattr_pos) > 0 ) {
                    my $clone_index;
                    foreach my $prepattr_pos (@prepattr_pos) {
                        my ( $attr_class, $attr_name ) = split( '=', $inputs[$prepattr_pos] );
                        $D_prepattr = $defaults[$prepattr_pos] if $PrepAttr_check;
                        $Input->Set_Row(
                            [   Show_Tool_Tip(
                                    checkbox(
                                        -name    => 'Input',
                                        -value   => 'Prep_Attribute',
                                        -label   => 'Prep Attribute',
                                        -checked => $PrepAttr_check,
                                        -force   => 1
                                    ),
                                    "Prompt user to supply Prep Attribute"
                                    )
                                    . &hspace(5)
                                    . Show_Tool_Tip(
                                    popup_menu(
                                        -name    => 'Prep Attributes',
                                        -values  => \@prep_attributes,
                                        -default => $attr_name,
                                        -force   => 1
                                        )
                                        . "<BR>"
                                        . $definePrepAttribute_link,
                                    "Prompt user to supply preparation conditions"
                                    ),
                                "&nbsp", "&nbsp",
                                textfield(
                                    -name    => 'Prep_Attribute_Def',
                                    -size    => 15,
                                    -default => $D_prepattr,
                                    -force   => 1
                                ),
                            ],
                            -repeat      => 1,
                            -clone_index => $clone_index
                        );
                        $clone_index = $Input->{clone_index}{ $Input->rows() };
                    }
                }
                else {
                    $Input->Set_Row(
                        [   Show_Tool_Tip(
                                checkbox(
                                    -name    => 'Input',
                                    -value   => 'Prep_Attribute',
                                    -label   => 'Prep Attribute',
                                    -checked => $PrepAttr_check,
                                    -force   => 1
                                ),
                                "Prompt user to supply Prep Attribute"
                                )
                                . &hspace(5)
                                . Show_Tool_Tip(
                                popup_menu(
                                    -name    => 'Prep Attributes',
                                    -values  => \@prep_attributes,
                                    -default => '',
                                    -force   => 1
                                    )
                                    . "<BR>"
                                    . $definePrepAttribute_link,
                                "Prompt user to supply preparation conditions"
                                ),
                            "&nbsp", "&nbsp",
                            textfield(
                                -name    => 'Prep_Attribute_Def',
                                -size    => 15,
                                -default => $D_prepattr,
                                -force   => 1
                            ),
                        ],
                        -repeat => 1
                    );
                }

                ## Plate attributes##

                if ( scalar(@plateattr_pos) > 0 ) {
                    my $clone_index;
                    foreach my $plateattr_pos (@plateattr_pos) {
                        my ( $attr_class, $attr_name ) = split( '=', $inputs[$plateattr_pos] );
                        $D_plateattr = $defaults[$plateattr_pos] if $PlateAttr_check;
                        $Input->Set_Row(
                            [   Show_Tool_Tip(
                                    checkbox(
                                        -name    => 'Input',
                                        -value   => 'Plate_Attribute',
                                        -label   => 'Plate Attribute',
                                        -checked => $PlateAttr_check,
                                        -force   => 1
                                    ),
                                    "Prompt user to supply Plate Attribute"
                                    )
                                    . &hspace(5)
                                    . Show_Tool_Tip(
                                    popup_menu(
                                        -name    => 'Plate Attributes',
                                        -values  => \@plate_attributes,
                                        -default => $attr_name,
                                        -force   => 1
                                    )
                                    )
                                    . lbr
                                    . $definePlateAttribute_link,
                                '&nbsp;', '&nbsp;',
                                textfield(
                                    -name    => 'Plate_Attribute_Def',
                                    -size    => 15,
                                    -default => $D_plateattr,
                                    -force   => 1
                                )
                            ],
                            -repeat      => 1,
                            -clone_index => $clone_index
                        );

                        $clone_index = $Input->{clone_index}{ $Input->rows() };
                    }
                }
                else {
                    $Input->Set_Row(
                        [   Show_Tool_Tip(
                                checkbox(
                                    -name    => 'Input',
                                    -value   => 'Plate_Attribute',
                                    -label   => 'Plate Attribute',
                                    -checked => $PlateAttr_check,
                                    -force   => 1
                                ),
                                "Prompt user to supply Plate Attribute"
                                )
                                . &hspace(5)
                                . Show_Tool_Tip(
                                popup_menu(
                                    -name    => 'Plate Attributes',
                                    -values  => \@plate_attributes,
                                    -default => '',
                                    -force   => 1
                                    )
                                    . "<BR>"
                                    . $definePlateAttribute_link,
                                "Specify attribute you want to record"
                                ),
                            "&nbsp", "&nbsp",
                            textfield(
                                -name    => 'Plate_Attribute_Def',
                                -size    => 15,
                                -default => $D_plateattr,
                                -force   => 1
                            )
                        ],
                        -repeat => 1
                    );
                }

                ## Time ##

#my $D_time = $defaults[$time_pos] if $Time_check;
#$Input->Set_Row([Show_Tool_Tip(checkbox(-name=>'Input',-value=>'Prep_Time',-label=>'Prep Time',-checked=>$Time_check,-force=>1), "Prompt user to supply time used for this step (eg. 30 minutes)"), "&nbsp", textfield(-name=>'Time',-size=>15,-default=>$D_time,-force=>1)]);

                ## Plate Label ##
                my $label_check = ( $input =~ /Plate_Label/ );
                my $plate_label_def = "";
                $plate_label_def = $defaults[$label_pos] if $defaults[$label_pos];
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'Plate_Label',
                                -label   => 'Target Label',
                                -checked => $label_check,
                                -force   => 1
                            ),
                            "Prompt user to supply a label for Target Plate(s) - (only applicable for transfer steps)"
                        ),
                        '&nbsp', '&nbsp',
                        textfield(
                            -name  => "Plate_Label_def",
                            -size  => 15,
                            -value => $plate_label_def,
                            -force => 1
                        ),
                    ]
                );
                ## Comments ##
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'Prep_Comments',
                                -label   => 'Comments',
                                -checked => $Comments_check,
                                -force   => 1
                            ),
                            "Prompt user to supply comments as required for this step"
                        ),
                        '&nbsp', '&nbsp', "&nbsp",
                    ]
                );

                ## Plates ##  (for reordering or to only use subset of plate set)

                my $P_check = ( $input =~ /FK_Plate__ID/ );
                $Input->Set_Row(
                    [   Show_Tool_Tip(
                            checkbox(
                                -name    => 'Input',
                                -value   => 'FK_Plate__ID',
                                -label   => 'Plate',
                                -checked => $P_check,
                                -force   => 1
                            ),
                            "Allow users to scan plates to indicate revised usage order; or to use only a subset of the plate_set"
                        ),
                        '&nbsp',
                        '&nbsp'

                    ]
                );

                $Page->Set_Row( [ "<H4>$field_name:</H4>", $Input->Printout(0) ] );

            }
            elsif ( $field_name eq "Scanner" ) {
                $Page->Set_Row(
                    [   "<H4>$field_name:</H4>",
                        Show_Tool_Tip(
                            checkbox(
                                -name    => 'Scanner',
                                -checked => $scanner,
                                -force   => 1,
                                -label   => 'Scanner View enabled',
                                -force   => 1
                            ),
                            "Prompt user to indicate when this step is completed"
                        )
                    ]
                );

            }
            elsif ( $field_name =~ /Validate/ ) {
                my @validation_options = ( 'Primer', 'Enzyme', 'Antibiotic' );
                my $validate = $data[$index] if $data[$index];
                $Page->Set_Row(
                    [   "<H4>Validate:</H4>",
                        Show_Tool_Tip(
                            popup_menu(
                                -name    => 'Validate',
                                -values  => [ '', @validation_options ],
                                -default => $validate,
                                -force   => 1
                            ),
                            "Perform real-time validation of associated reagents (eg Enzymes, Primers, Antibiotics)"
                            )

                            #				&hspace(5) . " <B>MUST BE: </B> " .
                            #				Show_Tool_Tip(
                            #					      textfield(-name=>'QC_Condition',-size=>15,-default=>$qc_condition,-force=>1),
                            #					      "ALL Samples in protocol must have Attribute set to this value to continue <BR>(may enter range or single value.  eg 'YES', '>5', '5-400')"
                            #					      ) . br .
                            #			 	$definePlateAttribute_link
                    ]
                );

            }
            elsif ( $field_name =~ /QC Attribute/ ) {
                my $qc_attr = get_FK_info( $dbc, 'FKQC_Attribute__ID', $data[$index] ) if $data[$index];
                my $qc_condition = $data[ ++$index ];

                $Page->Set_Row(
                    [   "<H4>Quality  Control:</H4>",
                        'Attribute: '
                            . Show_Tool_Tip(
                            popup_menu(
                                -name    => 'QC_Attribute',
                                -values  => \@plate_attributes,
                                -default => $qc_attr,
                                -force   => 1
                            ),
                            "Select a plate attribute used for QA/QC"
                            )
                            . &hspace(5)
                            . " <B>MUST BE: </B> "
                            . Show_Tool_Tip(
                            textfield(
                                -name    => 'QC_Condition',
                                -size    => 15,
                                -default => $qc_condition,
                                -force   => 1
                            ),
                            "ALL Samples in protocol must have Attribute set to this value to continue <BR>(may enter range or single value.  eg 'YES', '>5', '5-400')"
                            )
                            . br
                            . $definePlateAttribute_link
                    ]
                );
            }
            elsif ( $field_name =~ /QC Condition/ ) {
                next;    ## already handled...
            }
            elsif ( $field_name =~ /Defaults/ ) {
                $Page->Set_Row( [ "<H4>$field_name:</H4>", textfield( -name => $field_name, -size => 40 ) ] );

            }
            else {
                $Page->Set_Row( [ "<H4>$field_name:</H4>", '', '', textfield( -name => $field_name, -size => 40, -value => 'Something' ) ] );
            }

            $index++;
        }
    }
    $Page->Set_Column_Colour( 1, 'lightblue' );
    $Page->Set_Column_Colour( 2, 'lightyellow' );

    if ($previous_step_id) {

        # if there is a previous step...
        print hidden( -name => 'Previous', -value => "$previous_step_id", -force => 1 ), submit( -name => 'Previous Step', -class => 'Std' );
    }
    if ($next_step_id) {

        # if there is a next step...
        print hidden( -name => 'Next', -value => "$next_step_id", -force => 1 ), submit( -name => 'Next Step', -class => 'Std' );
    }
    $Page->Printout();
    return;
}

#######################
sub save_step {
#################
    #
    # Saves the step information into the database after first
    # checking that the required fields have been filled out
    # correctly.
    #
    # Maintenance protocols require a corresponding entry in the
    # Service table.
#######################
    my $edit = shift;
    my $new  = shift;

    my $type                  = 'major';    ## Default to major change.... save editor and the last time changed
    my $completion_email_list = shift;

    my $id = param('ID');
    if ($new) { $protocol = $new; }

    if ($new) {                             #### Add to Protocol_List ####
        $protocol = $new;

        # Create the new lab protocol
        print "first create new protocol..";

    }
    elsif ( !$protocol ) { Message("NO Protocol Name established"); }

    my @new_value;
    my @fields;
    my $condition;

    my $ok;

    if ( $TableName =~ /^Protocol/ ) {
        my $new_step = param('Step') || param('Step Number');
        my $new_step_name;
        my $step_type         = param('Step_Type');
        my $format            = param('Step_Format') || '';
        my $new_sample_type   = param('New_Sample_Type') || '';
        my $create_new_sample = param('Create_New_Sample') || '';

        if ($new_sample_type) { $new_sample_type = " $new_sample_type" }    ## add leading space
        if ($create_new_sample) {
            $create_new_sample = " (Track New Sample)";
        }
        if ( $step_type =~ /Transfer/ ) {
            $new_step_name = "$step_type$new_sample_type to $format $create_new_sample";
        }
        elsif ( $step_type =~ /Aliquot/ ) {
            $new_step_name = "$step_type$new_sample_type to $format $create_new_sample";
        }
        elsif ( $step_type =~ /Extract/ ) {
            $new_step_name = "$step_type$new_sample_type to $format $create_new_sample";
        }
        elsif ( $step_type =~ /Pre-Print/ ) {
            $new_step_name = "$step_type to $format";
        }
        elsif ( $step_type =~ /Pool/ ) {
            $new_step_name = "$step_type to $format";
        }
        elsif ( $step_type =~ /Setup/ ) {
            $new_step_name = "$step_type to $format";
        }
        else { $new_step_name = param('Step_Name'); }

        my $new_scanner;
        if ( param('Scanner') ) {
            $new_scanner = 1;
        }
        else {
            $new_scanner = 0;
        }
        my $new_message      = param('Message');
        my $new_instructions = param('Step Instructions');
        my $new_qc_attribute = param('QC_Attribute');
        my $validate         = param('Validate');
        my $new_qc_attr_id   = get_FK_ID( $dbc, 'FKQC_Attribute__ID', $new_qc_attribute ) if $new_qc_attribute;
        my $new_qc_condition = param('QC_Condition');
##############
        my $key_condition = "WHERE FK_Lab_Protocol__ID=$Qprotocol_id AND Protocol_Step_name=\"$new_step_name\"";

        if ( $edit eq "edit" ) {
            $key_condition .= " AND Protocol_Step_ID != $id";
        }
        my ($existing_name) = Table_find( $dbc, 'Protocol_Step', 'Protocol_Step_ID', $key_condition );
        if ($existing_name) {
            Message( "Error: '$new_step_name' already exists as an step in this Protocol. Please use a different name or change that" );
            Message("Warning: Database not updated");
            return 0;
        }
##############
        # check the values in the web-form
        my $check;
        if ( $edit =~ /edit/ ) {
            $check = &check_parameters();
        }
        else {
            $check = &check_parameters( 'append', $new );
        }

        # the check failed...
        if ( !$check ) {
            &addstep();
            return 0;
        }

        my $previous_step;
        if ($id) {
            ($previous_step) = Table_find( $dbc, $TableName, 'Protocol_Step_Number', "where Protocol_Step_ID=$id" );
        }

        my ($number_steps) = Table_find( $dbc, $TableName, 'count(*)', "where FK_Lab_Protocol__ID=$Qprotocol_id" );
        @fields = ( 'Protocol_Step_Number', 'Protocol_Step_Name', 'Scanner', 'Protocol_Step_Message', 'Protocol_Step_Instructions', 'FKQC_Attribute__ID', 'QC_Condition', 'Validate' );
        @new_value = ( $new_step, $new_step_name, $new_scanner, $new_message, $new_instructions, $new_qc_attr_id, $new_qc_condition, $validate );

        if    ( $new_step > $previous_step ) { $direction = 'up'; }
        elsif ( $new_step < $previous_step ) { $direction = 'down'; }

        my @Input;
        my @Defaults;
        my @Formats;

        # the inputs and defaults must be formatted correctly in order for them to
        # be visualized on the barcode scanners
        if ( my @list = param('Reagents') ) {
            $list[$#list] =~ /(\d+)/;
            my $reagents = $1;
            push( @Input, $list[$#list] );
            foreach my $x ( 1 .. $reagents ) {
                my $quant = param("Quantity $x") || '';
                push( @Input,    '' );
                push( @Defaults, $quant );
                push( @Formats,  '' );
            }
        }
        my @extra_inputs    = param('Input');
        my @prep_attr_def   = param('Prep_Attribute_Def');
        my @prep_attr_name  = param('Prep Attributes');
        my @plate_attr_def  = param('Plate_Attribute_Def');
        my @plate_attr_name = param('Plate Attributes');

        my @unique_prep_attr_names  = @{ unique_items( \@prep_attr_name ) };
        my @unique_plate_attr_names = @{ unique_items( \@plate_attr_name ) };

        if ( @unique_prep_attr_names != @prep_attr_name ) {
            Message("Error: Can not specify duplicate Prep attributes for a given step");
            return 0;
        }
        elsif ( @unique_plate_attr_names != @plate_attr_name ) {
            Message("Error: Can not specify duplicate Plate attributes for a given step");
            return 0;
        }

        foreach my $input (@extra_inputs) {
            my $default = '';
            my $format  = '';

            # Equipment
            if ( $input =~ /(FK_Equipment__ID)/ ) {
                my @formats_chosen = param('MFormat');    ## allow for multiple selections
                $format = join '|', @formats_chosen;
                $format ||= '';
            }

            # Plate
            elsif ( $input =~ /FK_Plate__ID/ ) {

            }

            # Rack
            elsif ( $input =~ /(FK_Rack__ID)/ ) {
                $format = param('Equipment_Conditions') || '';
            }

            # Solution Quantity
            elsif ( $input =~ s/(FK_Solution__ID)/$1:Solution_Quantity/ ) {
                my $quantity = param('Quantity')       || '';
                my $units    = param('Quantity_Units') || '';
                push( @Defaults, $default );
                $format = param('SFormat') || '';
                push( @Formats, $format );
                $default = "$quantity$units";
                $format  = '';                  #resetting format for quantity

            }

            # Prep Attributes
            elsif ( $input =~ /Prep_Attribute/ ) {
                $input   = "$input=" . shift @prep_attr_name;
                $default = shift @prep_attr_def;
            }

            # Plate Attributes
            elsif ( $input =~ /Plate_Attribute/ ) {
                $input   = "$input=" . shift @plate_attr_name;
                $default = shift @plate_attr_def;
            }

            # Track transfers
            elsif ( $input =~ /Track_Transfer/ ) {
                my $quantity = param('Transfer_Quantity')       || '';
                my $units    = param('Transfer_Quantity_Units') || 'ml';
                $default = "$quantity$units";
            }

            #split
            elsif ( $input =~ /Split/ ) {
                $default = param('Split_X');
            }

            #Plate_Label
            elsif ( $input =~ /Plate_Label/ ) {
                $default = param('Plate_Label_def');
            }
            push( @Input,    $input );
            push( @Formats,  $format );
            push( @Defaults, $default );
        }

        my $defaults = join ':', @Defaults;
        my $formats  = join ':', @Formats;
        my $inputs   = join ':', @Input;

        # re-index the step numbers if the new step number is in the
        # middle of the protocol
        if ( !$edit && $new_step <= $number_steps ) {
            &shuffle( $new_step, $number_steps );
        }

        my $user_id = param('User ID');
        my $date    = today();

        # if editting a step...
        if ( $edit eq "edit" ) {
            @new_value = ( $inputs, $defaults, $formats, @new_value );
            @fields = ( 'Input', 'Protocol_Step_Defaults', 'Input_Format', @fields );

            # for major changes, want to record the date of the changes and the editor
            if ( $type eq "major" ) {
                @new_value = ( $user_id, $date, @new_value );
                @fields = ( 'FK_Employee__ID', 'Protocol_Step_Changed', @fields );
            }
            $condition = "where Protocol_Step_ID=$id";

            $ok = Table_update_array( $dbc, 'Protocol_Step', \@fields, \@new_value, $condition, -autoquote => 1 );

            if ($ok) {

                #&reindex();
                return 1;
            }
            else {
                Message( "Error 1: ", $DBI::errstr );
                return 0;
            }

            # adding a new step...
        }
        else {
            @fields = ( 'Input', 'Protocol_Step_Defaults', 'Input_Format', 'FK_Employee__ID', 'Protocol_Step_Changed', 'FK_Lab_Protocol__ID', @fields );
            @new_value = ( $inputs, $defaults, $formats, $user_id, $date, $protocol_id, @new_value );
            $id = &Table_append_array(
                 $dbc, 'Protocol_Step', \@fields, \@new_value,
                -autoquote => 1,
                -quiet     => 1
            );
            if ($id) {
                Message("Added step $new_step_name to '$protocol' ($protocol_id)");
                return 1;
            }
            else {
                return 0;
            }
        }

##### maintenance protocols
    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {
        my $new_step         = param('Step');
        my $new_step_name    = param('Step_Name');
        my $new_instructions = param('Step Instructions');
        my $equip_type       = param('Type');
        my $interval         = param('Interval');
        my $interval_units   = param('Interval Units');

        my $service_fields = "Service_Name,FK_Equipment__Type,Service_Interval,Interval_Frequency";

        #	my $service_values = "$protocol,\"$equip_type\",$interval,\"$interval_units\"";
        my $service_values = "$protocol,$equip_type,$interval,$interval_units";

        #	$new_value = "$new_step,\"$new_step_name\",\"$new_instructions\"";
        @new_value = ( $new_step, $new_step_name, $new_instructions );
        @fields = ( 'Step', 'Maintenance_Step_Name', 'Maintenance_Instructions' );

        my $user_id = param('User ID');
        my $date    = today();

        my $number_steps = join ',', Table_find( $dbc, $TableName, 'count(*)', "where FK_Service__Name = $Qprotocol" );
        my $check;

        # if editting a step...
        if ( $edit eq "edit" ) {

            # check parameters
            $check = &check_parameters();
            if ( !$check ) {
                &addstep();
                return 0;
            }

            # re-shuffle the step numbers
            if ( $new_step <= $number_steps ) {
                &shuffle( $new_step, $number_steps );
            }

            # if major changes...
            if ( $type eq "major" ) {
                my $id = param('ID');
                $condition = "where Maintenance_Protocol_ID = $id";
                @fields    = ( 'FK_Employee__ID', 'Protocol_Date', @fields );
                @new_value = ( $user_id, $date, @new_value );

                # update both the Service and Maintenance tables
                $ok = Table_update( $dbc, 'Service', $service_fields, $service_values, "where Service_Name = $Qprotocol", -autoquote => 1 );
                $ok = Table_update_array( $dbc, 'Maintenance_Protocol', \@fields, \@new_value, $condition, -autoquote => 1 );
            }

            if ($ok) {

                #&reindex();
                Message("Changes to the Protocol Step have been saved");
                return 1;
            }
            else {
                return 0;
            }

            # if adding a new step...
        }
        else {
            @fields = ( 'FK_Service__Name', 'FK_Employee__ID', 'Protocol_Date', @fields );

            #	    $new_value = "$Qprotocol,$user_id,\"$date\",$new_value";
            @new_value = ( $protocol, $user_id, $date, @new_value );

            # check to see if there is a record in the Service table
            my $service_entry = join ',', Table_find( $dbc, 'Service', 'count(*)', "where Service_Name = $Qprotocol" );

            # either append or update the Service table
            if ( ( $service_entry > 0 ) && ( !$new ) ) {
                $ok = Table_update( $dbc, 'Service', $service_fields, $service_values, "where Service_Name = $Qprotocol", -autoquote => 1 );
            }
            else {
                $ok = Table_append( $dbc, 'Service', $service_fields, $service_values, "where Service_Name = $Qprotocol", -autoquote => 1 );
            }

            # check the parameters
            $check = &check_parameters( 'append', $new );
            if ( !$check ) {
                &addstep();
                return 0;
            }

            # re-shuffle the step numbers
            if ( $new_step <= $number_steps ) {
                &shuffle( $new_step, $number_steps );
            }

            # add new record to the Maintenance table
            $ok = Table_append_array( $dbc, 'Maintenance_Protocol', \@fields, \@new_value, -autoquote => 1 );
            if ($ok) {
                &reindex();
                Message("New Step Added to Protocol");
                return 1;
            }
            else {
                return 0;
            }
        }
    }
}

#######################
sub next_previous {

    #
    # Determines the id of the next and previous steps.
    # a return value of 0 indicates that there is either no
    # next or previous step.
#######################
    my $id = shift;

    my $next_id;
    my $previous_id;
    my $condition;

    if ( $TableName =~ /^(Maintenance_Protocol)/ ) {
        $condition = "where FK_Service__Name = $Qprotocol order by Step";
    }
    elsif ( $TableName =~ /^(Protocol)/ ) {
        $condition = "where FK_Lab_Protocol__ID=$Qprotocol_id order by Protocol_Step_Number";
    }
    my $field    = "$TableName" . "_ID";
    my $count    = 0;
    my @step_ids = Table_find( $dbc, $TableName, $field, $condition );

    foreach my $curr_id (@step_ids) {
        if ( $id == $curr_id ) {
            if ( !$count ) {
                $previous_id = 0;
            }
            else {
                $previous_id = $step_ids[ $count - 1 ];
            }
            if ( $count == $#step_ids ) {
                $next_id = 0;
            }
            else {
                $next_id = $step_ids[ $count + 1 ];
            }
            last;
        }
        $count++;
    }

    return ( $previous_id, $next_id );
}

#######################
sub toggle {

    #
    # Toggles the colour between each row of the html table
#######################
    my $colour  = shift;
    my $colour1 = "#EEEEFF";
    my $colour2 = "#DDDDFF";

    if ( $colour =~ /$colour1/ ) {
        $colour = $colour2;
    }
    else {
        $colour = $colour1;
    }
    return $colour;
}

########################
sub shuffle {
########################
    #
    # Shuffles the step number by +1 beginning from the $new_step
    # to the $last_step.
    # Called when a new step is inserted in the middle of a protocol.
    #
########################
    my $new_step  = shift;
    my $last_step = shift;

    my $i;
    my $field_name;

    my $step;
    if ( $TableName =~ /^(Maintenance_Protocol)/ ) {
        $field_name = "FK_Service__Name";
        $step       = 'Step';
    }
    elsif ( $TableName =~ /^(Protocol)/ ) {
        $field_name = "FK_Lab_Protocol__ID";
        $step       = "Protocol_Step_Number";
    }

    for ( $i = $last_step; $i >= $new_step; $i-- ) {
        my $value     = $i + 1;
        my $condition = "where $field_name=$Qprotocol_id and $step=$i";
        my $ok        = Table_update(
             $dbc, $TableName, $step, $value, $condition,
            -autoquote => 1,
            -quiet     => 1
        );
    }
}

########################
sub reindex {

    #
    # Re-indexes step numbers after steps are deleted.
########################
    my $field_name;
    my $condition;

    my $dir;
    if ( $direction eq 'up' ) {    ### When moving to an bigger number
        $dir = 'Asc';
    }
    elsif ( $direction eq 'down' ) {
        $dir = 'Desc';
    }
    if ($dir) { print "<B>moving step number $direction</B>"; }

    my $step;
    my $field_id;
    my $id = param('ID');
    if ( $TableName =~ /^(Maintenance_Protocol)/ ) {
        $condition  = "where FK_Service__Name = $Qprotocol order by Step";
        $field_name = "FK_Service__Name";
        $field_id   = "Service_ID";
        $step       = 'Step';
    }
    elsif ( $TableName =~ /^(Protocol)/ ) {
        $condition  = "where FK_Lab_Protocol__ID=$Qprotocol_id order by Protocol_Step_Number,Protocol_Step_Changed $dir";
        $field_name = "FK_Lab_Protocol__ID";
        $field_id   = "Protocol_Step_ID";
        $step       = 'Protocol_Step_Number';
    }
    my @ids = Table_find( $dbc, $TableName, $field_id, $condition );
    my $number = scalar(@ids);

    for ( my $index = 1; $index <= $number; $index++ ) {
        my $value;
        my $ok = Table_update( $dbc, $TableName, $step, $index, "where $field_id = $ids[$index-1]", -autoquote => 1 );
    }
}

#######################
sub restore_protocol {

    #
    # Restores the protocol to the database for viewing.
#######################
    my $fields;
    my $field;
    my $filename;
    my $service_file;
    my $datefield;
    my $Ptable = $TableName;

    if ( $TableName =~ /^(Maintenance_Protocol)/ ) {
        $fields    = "Step,Maintenance_Step_Name,Maintenance_Instructions,FK_Service__Name";
        $field     = "FK_Service__Name";
        $filename  = "$dump_dir" . "maintenance/$protocol";
        $filename  = "$dump_dir$protocol";
        $datefield = "Protocol_Date";
        $protocol =~ /^(\w+)\.(.*)/;
        $service_file = "$dump_dir$1.Service.$2";

    }
    elsif ( $TableName =~ /^(Protocol)/ ) {
        $fields    = "Step,Protocol_Step_Name,Protocol_Step_Instructions,Protocol_Step_Defaults,Input_Format,Input,Scanner,Protocol_Step_Message";
        $Ptable    = "Lab_Protocol";
        $datefield = "Lab_Protocol_VersionDate";
        $field     = "Lab_Protocol_Name";
        $filename  = "$dump_dir$protocol";
    }

    open( INFILE, "$filename" ) or die "Dead";
    my $insert;

    while (<INFILE>) {
        if ( !eof(INFILE) ) {
            s/\t/,/g;
            s/\n//;
            $insert = "insert into $TableName ($fields) values ($_,$Qprotocol)";    ### Step_ID ?
            my $sth = $dbc->dbh()->prepare($insert);
            $sth->execute();
        }
    }
    close(INFILE);

    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        open( INFILE, "$service_file" ) or die "Dead";
        while (<INFILE>) {
            if ( !eof(INFILE) ) {
                s/undef/\'\'/g;
                s/\t/,/g;
                s/\n//;
                $insert = "insert into Service (FK_Equipment__ID,FK_Equipment__Type,Service_Interval,Interval_Frequency,Service_Name) values ($_,$Qprotocol)";
                my $sth = $dbc->dbh()->prepare($insert);
                $sth->execute();
            }
        }
        close(INFILE);
    }

    $protocol =~ /(\w+)\.(\w*)\.(.*)/;
    my $initials  = $2;
    my $edit_date = $3;

    my $editor = join ',', Table_find( $dbc, 'Employee', 'Employee_ID', "where Initials = '$initials'" );
    my $ok = Table_update( $dbc, $TableName, 'FK_Employee__ID,$datefield', "$editor,$edit_date", "where $field = $Qprotocol", -autoquote => 1 );

    return 1;
}

########################
sub delete_step {

    #
    # Deletes protocol steps
########################
    my $field;

    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        $field = "Maintenance_Protocol_ID";
    }
    elsif ( $TableName =~ /^Protocol/ ) {
        $field = "Protocol_Step_ID";
    }

    my @marks = param('Mark');
    my $ids = Cast_List( -list => \@marks, -to => 'string' );

    my $ok = &delete_records(
         $dbc, $TableName, 'Protocol_Step_ID',
        -id_list   => $ids,
        -autoquote => 1
    ) if ($ids);
}

########################
sub login_home {

    #
########################
    my @users = Table_find( $dbc, 'Employee,GrpEmployee,Grp,Department',
        'Employee_Name', "where Employee_ID = FK_Employee__ID and Grp_ID = FK_Grp__ID and Department_ID = Grp.FK_Department__ID and Department_Name in ('Cap_Seq','Mapping','Lib_Construction','LIMS Admin') and Access like '%A%' ORDER BY Employee_Name",
        'Distinct' );

    print h1("Login Page for Accessing Protocols");

    #    start_barcode_form('protocol'),

    my $dept = param('Current_Department');
    if ( !grep /^$dbase$/, @databases ) { push @databases, $dbase; }

    # print start_custom_form('login',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'login', -type => 'start' );
    print hidden( -name => 'Session', -value => $session_id );

    #    print hidden(-name=>'Database',-value=>$dbase),
    print hidden( -name => 'Host', -value => $host ), hidden( -name => 'Protocol', -value => $protocol ), "<TABLE cellspacing=1 border=0>", "<TR>", "<TD width=120 bgcolor=#EEEEFF><BR><H4>Select User: </H4></TD><TD>",
        &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'login',
        -name    => 'User',
        -options => \@users,
        -default => '',
        -filter  => 1,
        -search  => 1
        ),

        #    popup_menu(-name=>'User',-value=>[@users],-default=>'',-force=>1),
        "</TD></TR>", "<TR>", "<TD width=120 bgcolor=#EEEEFF><BR><H4>Database: </H4></TD><TD>",

        popup_menu(
        -name    => 'Database',
        -value   => [@databases],
        -default => $dbase,
        -force   => 1
        ),
        "</TD></TR>", "<TR><TD width=120 bgcolor=#EEEEFF><BR><H4>Password: </H4></TD><TD>", password_field( -name => 'Password', -force => 1, -size => 15 ), "</TD></TR></TABLE><BR>", submit( -name => 'Continue', -class => 'Std' ),
        hidden( -name => 'Current_Department', -value => $dept, -force => 1 ), end_form;

    return;
}

########################
sub validation {

    #
    # Validates the user for administrative access against the password file.
########################
    my $user     = shift;
    my $password = shift;

    my ($pass) = &Table_find( $dbc, 'Employee', "Password,Password('$password')", "WHERE Employee_Name = '$user'" );
    my ( $pass1, $pass2 ) = split ',', $pass;

    my ($result) = &Table_find( $dbc, 'Employee', 'Employee_ID', "WHERE Employee_Name in ('$user','Admin') and password(lcase('$password')) = Password" );

    if ($result) { return 1 }
    else {
        my ($admin_pass) = &Table_find( $dbc, 'Employee', "Password", "WHERE Employee_Name = 'Admin'" );
        if ( $pass2 eq $admin_pass ) { return 1 }
        else {
            print "<H1><span class=mediumred>Administrative Access Denied</span></H1>";
            print "Limited access to view protocols available";
            return 0;
        }
    }

}

#########################
sub update_protocol {

    #
    # Administrative Function:
    #
    # Updates the selected Protocol.
    # Checks to see if the new protocol name already exists.
############################
    my $new_protocol          = shift;
    my $groups                = shift;
    my $completion_email_list = shift;
    my $field;
    my $message;
    my $table = $TableName;
    my $ok;    ### success flag...

    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        $table .= " left join Service on FK_Service__Name = Service_Name";
        $field   = "FK_Service__Name";
        $message = "Service Name";
    }
    elsif ( $TableName =~ /^Protocol/ ) {
        $table   = 'Lab_Protocol';
        $field   = "Lab_Protocol_Name";
        $message = "Lab Protocol Name";
    }

    if ( !$new_protocol || ( $new_protocol =~ /^\s+$/ ) ) {
        print "<H1><span class=lightyellow>Enter a $message</span></H1>";
        edit_home($protocol);
        return 0;
    }
    else {
        my @protocols = Table_find( $dbc, $table, $field, "WHERE Lab_Protocol_Name <> '$new_protocol'", 'Distinct' );
        my $flag = 0;
        foreach my $x (@protocols) {
            if ( $x eq $new_protocol ) {
                $flag = 1;
                last;
            }
        }

        if ( !$flag ) {
            if ( $TableName =~ /^(Maintenance_Protocol)/ ) {
                my $service_entry = join ',', Table_find( $dbc, 'Service', 'count(*)', "where Service_Name = $Qprotocol" );
                $ok;

                if ( $service_entry > 0 ) {
                    $ok = Table_update( $dbc, 'Service', 'Service_Name', "$new_protocol", "where Service_Name = $Qprotocol", 'auotquote' );
                }
                else {
                    $ok = Table_append( $dbc, 'Service', 'Service_Name', "$new_protocol", -autoquote => 1 );
                }

                if ( !$ok ) {
                    Message("Unable to update the Service Name");
                }
                $ok = Table_update( $dbc, $table, $field, $new_protocol, "where $field = $Qprotocol", -autoquote => 1 );
            }
            else {

                #		Table_update_array($dbc,$table,[$field],[$new_protocol],"where $field = $Qprotocol",-autoquote=>1);
                my ($protocol_id) = Table_find( $dbc, 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name = '$new_protocol'" );

                # Update association with groups
                $dbc->start_trans( -name => 'Delete_GrpLab_Protocol' );
                $dbc->delete_record( 'GrpLab_Protocol', 'FK_Lab_Protocol__ID', $protocol_id );

                my @group_ids = @{$groups} if ($groups);

                foreach my $group (@group_ids) {
                    $ok = Table_append_array(
                        $dbc, 'GrpLab_Protocol', [ 'FK_Lab_Protocol__ID', 'FK_Grp__ID' ],
                        [ $protocol_id, $group ],
                        -autoquote => 1,
                        -quiet     => 1
                    );
                }
                $dbc->finish_trans( -name => 'Delete_GrpLab_Protocol' );
            }
            if ($ok) {
                Message("The Protocol has been updated.");
                return 1;
            }
            else {
                Message("Unable to Update Protocol ?!");
                return 0;
            }

        }
        else {
            Message("There is already a protocol named '$new_protocol'!");
            return 0;
        }
    }
}

#######################
sub edit_home {

    #
#######################
    my $protocol = shift;

    # Get currently associated groups
    my ( $values, $labels ) = _get_groups_info();

    my @defaults = Table_find( $dbc, 'Lab_Protocol,GrpLab_Protocol', 'FK_Grp__ID', "WHERE Lab_Protocol_ID=FK_Lab_Protocol__ID AND Lab_Protocol_Name = '$protocol'" );

    my ( $values, $labels, $defaults ) = _get_groups_info();
    my @group_list = sort { $a <=> $b } values %{$labels};

    print h1("Editing Protocol $protocol");

    # print start_custom_form('edit_protocol',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'edit_protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    print &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'edit_protocol',
        -name    => 'GrpLab_Protocol',
        -options => \@group_list,
        -default => '',
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
        ),
        lbr, hidden( -name => 'Name', -value => $protocol ), hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Host', -value => $host ), hidden( -name => 'Protocol', -value => "$protocol" ),
        hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'Admin', -value => "$admin", -force => 1 ), hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 ),
        submit( -name => 'Update Protocol', -value => 'Update', -class => 'Action' ), br, submit( -name => 'Restrict Access', -class => 'Action' ), end_form;
}

##########################
sub copy_protocol_home {

    #
##########################
    print h1("Saving Current Protocol as a New Protocol"), br;

    #    start_barcode_form('protocol'),
    #print start_custom_form(-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'copy_protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    print hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Host', -value => $host ), "<TABLE cellspacing=0 cellpadding=0><TR><TD colspan=150 valign=top bgcolor=#EEEEFF><H4><BR>New Protocol Name: </H4></TD><TD>",
        textfield( -name => 'New Name', -size => 20 ), "</TD></TR></TABLE>", hidden( -name => 'Protocol', -value => "$protocol", -force => 1 ), hidden( -name => 'User ID', -value => "$user_id" ),
        hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 ), hidden( -name => 'Admin', -value => "$admin", -force => 1 ), br, checkbox( -name => 'Active' ), br,
        submit(
        -name  => 'Confirm Save As New Protocol',
        -value => 'Save New Protocol',
        -class => 'Action'
        ),
        br, textfield( -name => 'Protocol Name', -size => 20 ), br, submit( -name => 'Edit Protocol Name', -class => 'Action' ), br, end_form;
}

#####################
sub new_protocol_prompt {
#####################

    print h1("Creating New Protocol");
    print "<h2>New Protocol Name:</h2>";

    # print start_custom_form('New_protocol',-parameters=>{&Set_Parameters('start')});
    print alDente::Form::start_alDente_form(
        -dbc  => $dbc,
        -name => 'New_protocol',
        -type => 'start'
    );
    print hidden( -name => 'Session', -value => $session_id );
    print hidden( -name => 'Database', -value => $dbc->{dbase} ), hidden( -name => 'Host', -value => $host ), hidden( -name => 'User ID', -value => "$user_id" ), hidden( -name => 'User ', -value => "$user_id" ),
        hidden( -name => 'Admin', -value => "$admin", -force => 1 ), hidden( -name => 'Current_Department', -value => $Current_Department, -force => 1 );

    print textfield( -name => 'New Protocol Name', -size => 40, -default => '', -force => 1 );

    print "<h2>New Protocol Description:</h2>",
        textarea(
        -name  => 'Protocol Description',
        -rows  => 2,
        -cols  => 60,
        -value => '',
        -force => 1
        );

    # Allow user to specify which group the protocol belongs to.
    my ( $values, $labels, $defaults ) = _get_groups_info();
    my @group_list = sort { $a <=> $b } values %{$labels};

    print "<H4>Groups: </H4>";
    print &alDente::Tools::search_list(
        -dbc     => $dbc,
        -form    => 'New_protocol',
        -name    => 'GrpLab_Protocol',
        -options => \@group_list,
        -default => $defaults,
        -filter  => 1,
        -search  => 1,
        -mode    => 'Scroll',
        -sort    => 1
    );
    print set_validator( -name => "GrpLab_Protocol Choice", -mandatory => 1 );
    print set_validator( -name => "New Protocol Name",      -mandatory => 1 );

    print '<P>'
        . submit(
        -name    => 'Save New Protocol',
        -class   => 'Std',
        -onClick => "return validateForm(this.form)"
        );

    print end_form();
    return 1;
}

###############
sub new_protocol {
###############
    my %args        = &filter_input( \@_, -args => 'protocol,status,description' );
    my $protocol    = $args{-protocol};
    my $status      = $args{-status} || 'Active';
    my $description = $args{-description} || '';
    my @groups      = @{ $args{-groups} } if ( $args{-groups} );

    eval {
        my $description = param('Protocol Description') || '';
        my $newid = Table_append_array( $dbc, 'Lab_Protocol', [ 'Lab_Protocol_Name', 'FK_Employee__ID', 'Lab_Protocol_Status', 'Lab_Protocol_Description' ], [ $protocol, $user_id, $status, $description ], -autoquote => 1 );

        die("ERROR: Failed to add new protocol '$protocol'.") unless $newid;
        $protocol_id  = $newid;
        $Qprotocol_id = $protocol_id;
        my %values;

        # Associate protocol to user groups
        my $i;
        foreach my $group (@groups) {
            $values{ ++$i } = [ $group, $newid ];
        }
        my $new_ids = $dbc->smart_append(
            -tables    => 'GrpLab_Protocol',
            -fields    => [ 'FK_Grp__ID', 'FK_Lab_Protocol__ID' ],
            -values    => \%values,
            -autoquote => 1
        );
        die("ERROR: Failed to associate new protocol '$protocol' to groups.") unless $newid;
        Message("Added new Protocol: $protocol (Status: Active).");
    };

    Message($@) if $@;
    return $protocol_id;
}

#######################
sub copy_protocol {

    #
    # Subroutine to save an existing protocol as a new protocol.
#######################
    my $new_protocol = shift;
    my $active       = shift;

    my $status = 'Inactive';
    if ($active) { $status = 'Active'; }

    my $field;
    my $fields;
    my $instruction_field;
    my $Ptable = $TableName;

    if ( $TableName =~ /^Maintenance_Protocol/ ) {
        $TableName .= " left join Service on FK_Service__Name = Service_Name";
        $field             = "FK_Service__Name";
        $fields            = "Step,Maintenance_Step_Name,Maintenance_Instructions";
        $instruction_field = "Maintenance_Instructions";
    }
    elsif ( $TableName =~ /^Protocol/ ) {
        $field             = "Lab_Protocol_Name";
        $Ptable            = "Lab_Protocol";
        $fields            = "Step,Protocol_Step_Name,Scanner,Protocol_Step_Message,Input,Input_Format";
        $instruction_field = "Protocol_Step_Instructions";
    }

    my @protocols = Table_find( $dbc, $Ptable, $field, undef, 'Distinct' );
    my $flag;

    foreach my $x (@protocols) {
        if ( $x eq $new_protocol ) {
            $flag = 1;
            last;
        }
    }

    # If a new protocol name has not been entered...
    if ( !$new_protocol || ( $new_protocol =~ /^\s+$/ ) ) {
        print "<H1><span class=lightyellow>Go back and enter a Protocol Name</span></H1>";
        return 0;

        # If the new protocol name already exists...
    }
    elsif ($flag) {
        print "<H1><span class=lightyellow>Protocol $new_protocol already exists.<br>", "Go back and enter a different Protocol Name.</span></H1>";
        return 0;
    }
    elsif ( !$protocol_id ) {
        ## Simply add new protocol name (not a copy) ##
        print "<H1><span class=lightyellow>Defining New Protocol: $new_protocol</H1>";
        my $description = param('Protocol Description');
        my @values      = ( $dbc->get_local('user_id'), $new_protocol, $status, $description );
        my @fields      = ( 'FK_Employee__ID', 'Lab_Protocol_Name', 'Lab_Protocol_Status', 'Lab_Protocol_Description' );
        my $ok          = &Table_append_array( $dbc, 'Lab_Protocol', \@fields, \@values, -autoquote => 1 );
        return $ok;

        # Copy the selected protocol...
    }
    else {
        my @values;
        my @defaults;
        my $index = 0;

        if ( $TableName =~ /^Protocol/ ) {
            eval {

                #@defaults = Table_find($dbc,$TableName,'Protocol_Step_Defaults', "where $field = $Qprotocol Order by Protocol_Step_Number");
                my $status = 'Inactive';
                if ( param('Active') ) { $status = 'Active' }
                my ($protocol_id) = Table_find( $dbc, 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = '$protocol'" );

                #First copy the protocol table
                ( my $copied ) = &Table_copy( $dbc, 'Lab_Protocol', "where Lab_Protocol_ID = $protocol_id", [ 'Lab_Protocol_ID', 'Lab_Protocol_Name', 'Lab_Protocol_Status' ], undef, [ undef, $new_protocol, $status ], -no_merge => 1 );
                die("Problem copying protocol.") unless $copied;
                Message("Added new $new_protocol Protocol (Status: $status).");
                my $new_id = $copied;

                #Now copy the GrpLab_Protocol record
                ( my $copied ) = &Table_copy( $dbc, 'GrpLab_Protocol', "where FK_Lab_Protocol__ID = $protocol_id", [ 'GrpLab_Protocol_ID', 'FK_Lab_Protocol__ID' ], undef, [ undef, $new_id ], -no_merge => 1 );
                die("Problem copying group permissions of protocol.") unless $copied;
                Message("Group permissions of protocol copied.");

                #Now also copy the protocol steps
                ( my $copied ) = &Table_copy( $dbc, 'Protocol_Step', "where FK_Lab_Protocol__ID = $protocol_id", [ 'Protocol_Step_ID', 'FK_Lab_Protocol__ID' ], undef, [ undef, $new_id ], -no_merge => 1 );
                die("Problem copying protocol steps") unless $copied;
                Message("Protocol steps copied.");

            };
            Message($@) if $@;
        }
        elsif ( $TableName =~ /^(Maintenance_Protocol)/ ) {
            $TableName = $1;
            my $lastid = &Table_find( $dbc, $TableName, "Max($TableName" . "_ID)" );
            my $condition = "where $TableName" . "_Name='$protocol'", "$TableName" . "_Name";
            ( my $copied ) = &Table_copy( $dbc, $TableName, $condition, [ $TableName . "_ID", $TableName . "_Name" ], undef, [ undef, $new_protocol ], -no_merge => 1 );
            if ($copied) {
                &Table_update_array( $dbc, $TableName, [ $TableName . "_Name" ], [$new_protocol], "where $TableName" . "_ID in ($copied)", -autoquote => 1 );
                print "copied $TableName ($protocol to $new_protocol)";

                ######### Activate if applic ##########
                my $ok = &Table_append_array( $dbc, 'Lab_Protocol', [ 'Lab_Protocol_Name', 'FK_Employee__ID', 'Lab_Protocol_Status' ], [ $user_id, $status ], -autoquote => 1 );
                Message("Added $ok new $new_protocol Protocol (Status: $status).");
            }
            else { "Problem copying protocol"; }
        }
    }
    return 1;
}

########################
sub testing {
########################

    foreach my $name ( param() ) {
        if ( $name =~ /Input|Reagents|Quantity/ ) {
            foreach my $value ( param($name) ) {
                print h4("$name : $value.");
            }
        }
        else {
            my $value = param($name);
            print h4("$name : $value.");
        }
    }

}

############################
sub check_parameters {

    #
    # Determine if the required fields were filled out on the
    # web form with the proper types.
    # If the 'edit' parameter is not used, then the subroutine
    # checks for steps in the protocol with the same Step_ID.
############################
    my $append = shift;
    my $new    = shift;

    my $step_num = param('Step') || param('Step Number');
    my $new_step_name;
    my $step_type       = param('Step_Type');
    my $format          = param('Step_Format') || '';
    my $new_sample_type = param('New_Sample_Type') || '';
    if ($new_sample_type) { $new_sample_type = " $new_sample_type" }

    my $step_name;
    if ( $step_type =~ /^Transfer/ ) {
        $step_name = "$step_type$new_sample_type to $format";
    }
    elsif ( $step_type =~ /^Aliquot/ ) {
        $step_name = "$step_type$new_sample_type to $format";
    }
    elsif ( $step_type =~ /^Extract/ ) {
        $step_name = "$step_type$new_sample_type to $format";
    }
    elsif ( $step_type =~ /^Setup/ ) {
        $step_name = "$step_type to $format";
    }
    elsif ( $step_type =~ /^Pre-Print/ ) {
        $step_name = "$step_type to $format";
    }
    elsif ( $step_type =~ /^Pool/ ) {
        $step_name = "$step_type to $format";
    }
    else { $step_name = param('Step_Name'); }

    my @fields;
    my @values;
    my @Qvalues;
    my $field;
    my $Ptable = $TableName;

    if ( $TableName =~ /^Protocol/ ) {
        $Ptable = "Lab_Protocol";
        $field  = "Lab_Protocol_Name";
        if ( $step_num !~ /^\d+$/ ) {
            Message("Step must be an integer value!");
            return 0;
        }

        @fields = ( 'FK_Lab_Protocol__ID', 'Protocol_Step_Number', 'Protocol_Step_Name' );
        @values = ( $protocol_id, $step_num, $step_name );
    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {
        $field  = "FK_Service__Name";
        @fields = ( 'FK_Service__Name', 'Step', 'Maintenance_Step_Name' );
        @values = ( $protocol, $step_num, $step_name );
    }
    my $ok;

    if ( $new =~ /new/ ) {
        my $exist = join ',', Table_find( $dbc, $Ptable, 'count(*)', "where $field = $Qprotocol" );
        if ( $exist > 0 ) {
            Message("'$protocol' already exists.  Choose another name.");
            $protocol = "";
            return 0;
        }
    }
    my @quoted_values = map { $dbc->dbh()->quote($_) } @values;
    return \@quoted_values;

}

#######################
sub delete_protocol {

    #
#######################
    my $delete1;
    my $delete2;

    # unless trans already started, start one and finish at the end
    $dbc->start_trans( -name => 'Delete Protocol' );
    if ( $TableName =~ /^Protocol/ ) {
        my ($P_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = $Qprotocol" );
        ## DELETE Grp Entry
        $dbc->delete_record( 'GrpLab_Protocol', 'FK_Lab_Protocol__ID', $P_id, -trans => $Transaction );

        ## DELETE PROTOCOL STEPS ##
        $delete1 = $dbc->delete_record( 'Protocol_Step', 'FK_Lab_Protocol__ID', $P_id, -trans => $Transaction );
        ## DELETE LAB PROTOCOL ##
        $delete2 = $dbc->delete_record( 'Lab_Protocol', 'Lab_Protocol_Name', $Qprotocol, -trans => $Transaction );

    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {
        $delete1 = $dbc->delete_record( 'Service', 'Service_Name', $Qprotocol, -trans => $Transaction );
        $delete2 = $dbc->delete_record( 'Maintenance_Protocol', 'FK_Service__Name', $Qprotocol, -trans => $Transaction );

    }

    $dbc->finish_trans( -name => 'Delete Protocol' );
    return $delete2;
}

##############################
# Get groups related info
##############################
sub _get_groups_info {
    my @values;
    my @defaults;
    my %labels;

    if ( %Login->{LIMS_admin} ) {
        foreach my $group ( keys %{ %Std_Parameters->{Group_Name} } ) {
            my $group_name = %Std_Parameters->{Group_Name}->{$group};
            push( @values, $group );
            %labels->{$group} = $group_name;
        }
    }
    else {
        ###foreach my $department_name (@{$Security->departments()}) {#
        ###
        ###    if ($Security->department_access($department_name)=~/\bAdmin\b/i) { # If user has admin access to this department than get all the groups
        ###
        ###	   my $department_id = $Std_Parameters{Department_ID}{$department_name};
        ###	   foreach my $group_id (@{$Std_Parameters{Department_Group}{$department_id}}) {#
        ###	       my $group_name = $Std_Parameters{Group_Name}{$group_id};
        ###	       push(@values,$group_id);
        ###	       $labels{$group_id} = $group_name;
        ###	       if ($group_name =~ /\bLab\b/) {push(@defaults,$group_id)} # By cefault the protocol is assign to the 'Lab' group of the department
        ###	   }
        ###    }
        ###}

        ## <Construction>

        @values = split ',', $dbc->get_local('group_list');
        foreach my $group_id (@values) {
            my $group_name = $Std_Parameters{Group_Name}{$group_id};
            $labels{$group_id} = $group_name;
            if ( $group_name =~ /\bLab\b/ ) {
                push( @defaults, $group_id );
            }    # By default the protocol is assign to the 'Lab' group of the department
        }

        #foreach my $group (keys %{%Login->{groups}}) {
        #    my $group_name = %Login->{groups}->{$group}->{name};
        #    push(@values,$group);
        #    %labels->{$group} = $group_name;
        #    if ($group_name =~ /\bLab\b/) {push(@defaults,$group)} # By cefault the protocol is assign to the 'Lab' group of the department
        #}
    }

    return ( \@values, \%labels, \@defaults );
}

##############################
sub leave {
##############################
    $dbc->disconnect() if $dbc;
    print &alDente::Web::unInitialize_page($page);
    exit;
}

##############################
sub edit_protocol_name {
##############################

    my $result            = -1;
    my $new_protocol_name = $dbc->dbh()->quote( param('Protocol Name') );
    if ( $new_protocol_name eq "" ) {
        Message("The new Lab Protocol name can't be empty.");
        return $result;
    }
    my ($LP_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = $new_protocol_name", -debug => 0 );
    if ($LP_id) {
        Message("There is already another Lab Protocol with the new name you specified");
        return $result;
    }

    # unless trans already started, start one and finish at the end
    $dbc->start_trans( -name => 'Edit Protocol Name' );
    if ( $TableName =~ /^Protocol/ ) {
        my ($P_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = $Qprotocol", -debug => 0 );
        ## Update Protocol_Name

        $result = $dbc->Table_update(
            'Lab_Protocol', 'Lab_Protocol_Name', $new_protocol_name,
            -condition => "where lab_protocol_id = $P_id",
            -debug     => 0
        );
    }
    elsif ( $TableName =~ /^Maintenance_Protocol/ ) {

        #	$delete1 = $dbc->delete_record('Service','Service_Name',$Qprotocol,-trans=>$Transaction);
        #	$delete2 = $dbc->delete_record('Maintenance_Protocol','FK_Service__Name',$Qprotocol,-trans=>$Transaction);
        Message("Can't edit Maintenance_Protocol Name");
        return $result;
    }

    $dbc->finish_trans( -name => 'Edit Protocol Name' );
    return $result;

}

