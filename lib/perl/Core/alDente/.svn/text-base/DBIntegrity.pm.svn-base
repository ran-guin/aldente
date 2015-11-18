package alDente::DBIntegrity;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DBIntegrity.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(perform_cmd_indexcheck print_fk_tables perform_fk_checks print_errchks perform_cmdchks show_errchk_details perform_refchks describe_table show_tables $Mode $Home $dbase $host $thislink $Connection);

##############################
# standard_modules_ref       #
##############################
use DBI;
use strict;
use CGI qw(:standard);
use URI::Escape;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use RGTools::HTML_Table;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::HTML;
use RGTools::Conversion;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";    # add the local directory to the lib search path

use alDente::Notification;
use alDente::SDB_Defaults;

##############################
# global_vars                #
##############################
use vars qw($Mode $Home $dbase $user $host $thislink);
use vars qw($password $task $java_header $testing %Configs);

$Mode = "cmd";                                  #< CONSTRUCTION> Should remove this global it seems only cgi-bin/DBIntegrity.pl use this global

my $FROM_EMAIL           = 'DBIntegrity Monitor <aldente@bcgsc.ca>';
my $to_email             = 'aldente@bcgsc.ca';
my $fk_check_html        = "/DBIntegrity_fk_check.html";
my $err_check_html       = "/DBIntegrity_err_check.html";
my $enum_check_html      = "/DBIntegrity_enum_check.html";
my $attribute_check_html = "/DBIntegrity_attribute_check.html";
my $qty_units_check_html = "/DBIntegrity_qty_units_check.html";
my $url_root             = $Configs{URL_domain} . '/' . $Configs{URL_dir_name} . "/dynamic/tmp/";

##############################
# modular_vars               #
##############################
my $check_name = '';
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

#
# Start the command line mode.
#
# get the command-line arguments
##############################
sub _start_cmdline_mode {
##############################
    my %args          = filter_input( \@_ );
    my $host          = $args{-host};
    my $dbase         = $args{-dbase};
    my $user          = $args{-user};
    my $password      = $args{-pass};
    my $index_check   = $args{-indexcheck};
    my $tables        = $args{-tables};
    my $err_chk_ids   = $args{-err_chk};
    my $enum_chk      = $args{-enum_chk};
    my $qty_units_chk = $args{-qty_units_chk};
    my $clear_report  = $args{-clear_report};
    my $to_emails     = $args{-to_emails};
    my $logfile       = $args{ -log };
    my $field         = $args{-field};
    my $values        = $args{ -values };
    my $options       = $args{-options};                                  #options stored in an array
    my @options       = Cast_List( -list => $options, -to => 'Array' );
    my $ignore        = $args{-ignore};                                   #tables to ignore during Integrity check
    my @ignore        = Cast_List( -list => $ignore, -to => 'Array' );
    my $Report        = $args{-report};
    my $report_file   = $args{-file} || 'DBIntegrity_Report.html';
    my $daily_report  = $args{-daily_report} || $report_file;
    my $errors_found  = 0;
    my $html_table;
    my $logfile_note;
    my $ignored_tables = scalar(@ignore);

    my $file              = "/home/sequence/alDente/share/$report_file";
    my $daily_report_file = "$Configs{URL_temp_dir}/$daily_report";

    if ($clear_report) {

        open my $FILE, '>', $file or $Report->set_Warning("Cannot write to the File: $file");
        print $FILE 'DB Integrity Check Report<br>';
        close $FILE;
    }

    if ($logfile) {    # redirect console output to log file.
        open( STDOUT, ">$logfile" ) or $Report->set_Warning("Cannot write to the File: $logfile");

        $logfile_note = "<br><u>Log file location</u>: $logfile";

    }

    # OPEN Report HTML file
    open my $FILE, '+>>', $file or $Report->set_Warning("Cannot write to the File: $file");
    open my $DAILY_LOG_FILE, '+>>', $daily_report_file or $Report->set_Warning("Cannot write to the File: $daily_report_file");

    my $addr;

    print $FILE "The following checks are performed on: " . &convert_date( date_time(),           'Simple' ) . "<br>";
    print $DAILY_LOG_FILE "The following checks are performed on: " . &convert_date( date_time(), 'Simple' ) . "<br>";

    my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $user, -password => $password, -connect => 1 );
    my @check_tables;

    #First see which task we are performing.
    if ($index_check) {    #check foreign keys for indexes

        my $log_string  = '';
        my $omit_non_fk = undef;
        my $add_index   = undef;

        if ( grep /^fk_only/, @options ) {
            $omit_non_fk = 1;
            print "NON FK";
        }
        if ( grep /^add_index/, @options ) {
            $add_index = 1;
            print "ADD IND";
        }
        if ($ignored_tables) {
            my $all_tables = [ show_tables($dbc) ];
            foreach my $table (@$all_tables) {
                unless ( grep /^\s*$table\s*$/, @ignore ) { push( @check_tables, $table ); }
            }
            $log_string = perform_cmd_indexcheck( $dbc, \@check_tables, $omit_non_fk, $add_index, $Report );
        }
        elsif ( $tables =~ /All/i ) {    #Performing checks on all tables.
            $log_string = perform_cmd_indexcheck( $dbc, [ show_tables($dbc) ], $omit_non_fk, $add_index, $Report );
        }
        elsif ($tables) {                #Performing checks on the tables included in the comma-delimited  list.
            $log_string = perform_cmd_indexcheck( $dbc, [ split( /,/, $tables ) ], $omit_non_fk, $add_index, $Report );
        }
        else {
            print("No tables specified for the -t switch.\n");
        }

    }
    elsif ($tables) {                    #foreign key checks
        if ($enum_chk) {
            $check_name = "DBIntegrity_enum_check";
            if ( $tables =~ /All/i ) {
                ( $errors_found, $html_table ) = perform_enum_checks( -dbc => $dbc, -tables => [ show_tables($dbc) ], -report => $Report . -file => $FILE, -daily_log => $DAILY_LOG_FILE );
            }
            elsif ($tables) {
                print "we are in enum_chk,tables\n";

                ( $errors_found, $html_table ) = perform_enum_checks( -dbc => $dbc, -tables => [ split( /,/, $tables ), -report => $Report ], -file => $FILE, -daily_log => $DAILY_LOG_FILE );
            }

            #$Report->set_Message("Tested enum checks: ". $errors_found . " errors found");

        }
        else {
            if ($qty_units_chk) {
                $check_name = "DBIntegrity_qty_units_check";
                if ( $tables =~ /All/i ) {
                    ( $errors_found, $html_table ) = perform_qty_units_checks( -dbc => $dbc, -tables => [ show_tables($dbc) ], -report => $Report, -file => $FILE, -daily_log => $DAILY_LOG_FILE );
                }
                elsif ($tables) {
                    ( $errors_found, $html_table ) = perform_qty_units_checks( -dbc => $dbc, -tables => [ split( /,/, $tables ), -report => $Report ], -file => $FILE, -daily_log => $DAILY_LOG_FILE );
                }
            }
            else {
                $check_name = "DBIntegrity_FK_check";

                #Parse the options.
                my $include_nulls = grep /^nulls$/i,    @options;
                my $show_no_errs  = grep /^no_errs$/i,  @options;
                my $gen_list      = grep /^gen_list$/i, @options;

                if ($ignored_tables) {
                    my $all_tables = [ show_tables($dbc) ];
                    foreach my $table (@$all_tables) {
                        unless ( grep /^\s*$table\s*$/, @ignore ) { push( @check_tables, $table ); }
                    }
                    ( $errors_found, $html_table ) = perform_fk_checks( $dbc, \@check_tables, $include_nulls, $show_no_errs, $gen_list, $Report, $FILE, $DAILY_LOG_FILE );
                }
                elsif ( $tables =~ /All/i ) {    #Performing checks on all tables.
                    ( $errors_found, $html_table ) = perform_fk_checks( $dbc, [ show_tables($dbc) ], $include_nulls, $show_no_errs, $gen_list, $Report, $FILE, $DAILY_LOG_FILE );
                }
                elsif ($tables) {                #Performing checks on the tables included in the comma-delimited  list.
                    ( $errors_found, $html_table ) = perform_fk_checks( $dbc, [ split( /,/, $tables ) ], $include_nulls, $show_no_errs, $gen_list, $Report, $FILE, $DAILY_LOG_FILE );
                }
                else {
                    print("No tables specified for the -t switch.\n");
                }

                if ( $errors_found && $to_emails ) {    #we are sending email notifications if errors found.

                    #####################################
                    # necessary to populate the Cron summary email notification
                    my $link = "<a href=$Home><b>Go to DBIntegrity login page</b></a><br><br>";
                    $Report->set_Message($link);
                    $Report->create_HTML_page( $html_table->Printout(0) );
                }
            }

        }    # if qty_unit_chk ends
    }
    elsif ($err_chk_ids) {    #error checks
                              #Parse the options;

        $check_name = "DBIntegrity_Error_check";
        my $show_no_errs = grep /^no_errs$/i,      @options;
        my $force_notify = grep /^force_notify$/i, @options;    #Force to send notification emails even if Notice_Sent is less than (today - Notice_Frequency).
        my $gen_list     = grep /^gen_list$/i,     @options;

        my @notify_ids;

        if ( $err_chk_ids =~ /All/i ) {                         #Performing all error checks defined by all users.
            my @ids = $dbc->Table_find( 'Error_Check', 'Error_Check_ID', 'order by Error_Check_ID' );
            ( $errors_found, $html_table, @notify_ids ) = perform_cmdchks( $dbc, [@ids], $show_no_errs, $to_emails, $force_notify, $gen_list, $Report, $FILE, -daily_log => $DAILY_LOG_FILE );

            #$Report->set_Message("Tested Error_Checks: " . join(',',@ids) . ", ". $errors_found . " errors found");
        }
        elsif ( $err_chk_ids =~ /Me/i ) {                       #Performing all error checks defined by the current user.
            my @ids = $dbc->Table_find( 'Error_Check', 'Error_Check_ID', "where Username = '$user' order by Error_Check_ID" );

            if (@ids) {
                ( $errors_found, $html_table, @notify_ids ) = perform_cmdchks( $dbc, \@ids, $show_no_errs, $to_emails, $force_notify, $gen_list, $Report, $FILE, -daily_log => $DAILY_LOG_FILE );

                # $Report->set_Message("Tested Error_Checks: " . join(',',@ids) . ", ". $errors_found . " errors found");
            }
            else {
                print("You have not defined any error checks.\n");
            }
        }
        elsif ($err_chk_ids) {                                  #Performing specified error checks..
            ( $errors_found, $html_table, @notify_ids ) = perform_cmdchks( $dbc, [ split( /,/, $err_chk_ids ) ], $show_no_errs, $to_emails, $force_notify, $gen_list, $Report, $FILE, -daily_log => $DAILY_LOG_FILE );
        }
        else {
            print("No error checks specified for the -e switch.\n");
        }
        if ( @notify_ids && $to_emails ) {                      #we are sending email notifications if errors found.
            #####################################
            # necessary to populate the Cron summary email notification
            my $link = "<a href=$Home><b>Go to DBIntegrity login page</b></a><br><br>";
            $Report->set_Message($link);
            $Report->create_HTML_page( $html_table->Printout(0) );
            ######################################
            my $send_date = &today();

            ## do the update on the master database ##
            if ( $dbc->{host} eq $Configs{BACKUP_HOST} && $dbc->{dbase} eq $Configs{BACKUP_DATABASE} ) {
                my $m_dbc = new SDB::DBIO(
                    -host    => $Configs{PRODUCTION_HOST},
                    -dbase   => $Configs{PRODUCTION_DATABASE},
                    -user    => $dbc->{login_name},
                    -connect => 1,
                );
                if ($m_dbc) {
                    my $fback = $dbc->Table_update_array( 'Error_Check', ['Notice_Sent'], [$send_date], "where Error_Check_ID in (" . join( ",", @notify_ids ) . ")", -autoquote => 1 );
                }
                else {
                    $Report->set_Error("Error while trying to connect to $Configs{PRODUCTION_HOST}:$Configs{PRODUCTION_DATABASE} as $dbc->{login_name} to update the Error_Check table");
                    my $error_check_ids = join ',', @notify_ids;
                    $Report->set_Error("No db connection, Table update failed: Table_update_array( 'Error_Check', ['Notice_Sent'], [$send_date], 'where Error_Check_ID in ($error_check_ids)', -autoquote => 1 )");
                }
            }
        }
    }
    elsif ($field) {    #reference checks
                        #parse the options
        my $gen_list;
        my $recursive;
        if ($values) {
            $gen_list  = grep /^gen_list$/i,  @options;
            $recursive = grep /^recursive$/i, @options;
        }

        print "\n*************************************************************************************************************************************\n";
        if ($values) {
            print "In the '$dbase' database, the following fields reference the field '$field' and contain the value(s) '$values':\n";
        }
        else {
            print "In the '$dbase' database, the following fields reference the field '$field':\n";
        }
        print "*************************************************************************************************************************************\n";

        perform_refchks( $dbc, $field, $values, $gen_list, $recursive, 0 );
    }
    else {    #didn't specify any task to perform
        print("No task specified.\n");
    }
    close $FILE;
    close $DAILY_LOG_FILE;
}

########################
sub _start_web_mode {
#########################
    #
    #Start the web interface mode.
    #

    ###First deal with password stuff......
    my $Report = shift;

    my $password_cookie;

    $dbase = param('Database') || $Configs{BACKUP_DATABASE} || $Configs{PRODUCTION_DATABASE};
    $host  = param('Host')     || $Configs{BACKUP_HOST}     || $Configs{PRODUCTION_HOST};
    $task  = param('Task');

    if ( param('Pwd') ) {
        $password = param('Pwd');
    }

    if ( param('Username') ) { $user = param('Username'); }
    my $Huser = $user;
    $Huser =~ s/ /+/g;
    my $Htask = $task;
    $Htask =~ s/ /+/g;

    #$thislink = "$homefile?Username=$Huser&Pwd_Key=$Hpassword_key&Database=$dbase&Task=$Htask"; #link to the DBIntegrity page
    $thislink = "$homefile?Username=$Huser&Pwd=$password&Database=$dbase&Task=$Htask";    #link to the DBIntegrity page
                                                                                          #$homelink = "$URL_address/barcode.pl?User=Auto&Database=$dbase";                      #link to the alDente home page

    ###Now start the web page......
    my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $user, -password => $password, -connect => 1 );
    print &alDente::Web::Initialize_page( $dbc, $page );

    if ( param('Change User') || !param('Username') ) {                                   #either re-login or first time through the page.
        print _start_form( 'start', 'Login Page' );
        &_print_login_form();
        print "\n</TD></TR></Table>";
        print end_form();
        print &alDente::Web::unInitialize_page($page);
    }
    elsif ( param('Username') ) {

        #Login to database.
        if ( $dbc && $dbc->ping( -debug => 1 ) ) {                                        # login successful
            _print_task_page( $dbc, $Report );
        }
        else {                                                                            #login fail
            print "<H1><font color='red'>Incorrect Username ($user) or Password ($password) for $host.$dbase host</font></H1>\n";
            print _start_form( 'start', 'Login Page' ), "\n";
            &_print_login_form();
            print end_form();
            &alDente::Web::unInitialize_page($page);
        }
    }
    return;

}

#############################
sub _start_form {
#############################
    #
    #Generic routine for starting a form with all the necessary hidden fields.
    #
    my $version   = shift;
    my $form_name = shift;

    my $method = 'GET';
    $form_name ||= 'thisform';

    my $form = "\n<Form name=$form_name Action='$homefile' Method='$method' enctype='multipart/form-data'>";

    if ( $version =~ /^start/i ) { return $form; }

    $form .= "\n" . hidden( -name => 'Username', -value => $user,     -force => 1 );
    $form .= "\n" . hidden( -name => 'Pwd',      -value => $password, -force => 1 );

    #$form .= "\n".hidden(-name=>'Pwd_Key', -value=>$password_key, -force=>1);
    $form .= "\n" . hidden( -name => 'Database', -value => $dbase, -force => 1 );
    $form .= "\n" . hidden( -name => 'Task',     -value => $task,  -force => 1 );

    if ( !param('Login') && !param('Re-Load') && !param('Link') ) {
        if ( param('Username') ) {
            my $username = param('Username');
            $form .= "\n" . hidden( -name => 'Username', -value => $username );
        }
        if ( param('Error_Check_ID') ) {
            my $error_check_ids = param('Error_Check_ID');
            $form .= "\n" . hidden( -name => 'Error_Check_ID', -default => $error_check_ids );
        }
    }

    return $form;
}

#############################
sub _print_task_page {
#############################
    #
    #Prints the HTML page after a task have been selected.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $Report = shift;

    my $include_nulls;
    my $show_no_errs;
    my $gen_list;

    ###Now print the body of the page.....
    # Main Menu Bar at top of page...
    print "<Table cellspacing=0 cellpadding =3 border=0><TR align=center><TD>";
    print "\n<A Href=$thislink&Change+User=1>Re-login</A></TD><TD>";

    if ( param('Task') eq "task2" ) {
        my $error_check_link = $thislink . "&Link=1";
        if ( param('Error_Check_ID') ) {
            my $error_check_ids = param('Error_Check_ID');
            $error_check_link .= "&Error_Check_ID=$error_check_ids";
        }
        $error_check_link =~ s/\s/+/g;

        print "\n<A Href=$error_check_link>Error_Check Table</A></TD><TD>";
    }

    print "</TR></Table>";
    print "\n<HR>";

    ##################################################################################
    print "\n";
    print _start_form( '', 'Check_DBase_Integrity' );
    print "\n";

    ############ Parse Options... ##########################
    if ( param('Task') ) {
        my $task1 = "Check Foreign Keys i.e. ensure that links between tables are not broken";

        #my $task2 = "Perform Checks Using the Error_Check Table";
        my $task2 = "Perform Checks Using tailored commands";
        my $task3 = "Perform enum field check";
        my $task4 = "Perform Quantity unit field check";

        if ( param('Include_Nulls') ) {
            $include_nulls = 1;
        }
        if ( param('Show_No_Errs') ) {
            $show_no_errs = 1;
        }
        if ( param('Gen_List') ) {
            $gen_list = 1;
        }

        if ( param('Task') eq "task1" ) {
            if ( param("Perform Check") || param("Check All") ) {
                my @tables = param('Table');
                perform_fk_checks( $dbc, [ param('Table') ], $include_nulls, $show_no_errs, $gen_list, $Report );

            }
            elsif ( param('Info') ) {
                print SDB::DB_Form_Viewer::view_records( $dbc, param('Table'), param('Field'), param('Like'), param('Condition') );
            }
            else {
                print_fk_tables($dbc);
            }
        }

        if ( param('Task') eq "task2" ) {
            if ( param('Perform_Check') ) {
                perform_cmdchks( $dbc, [ param('Error_Check_ID') ], $show_no_errs, $Report );
            }
            elsif ( param('Show_Errchk_Details') ) {
                my $error_check_id = param('Error_Check_ID');
                my $cmd_str = param('Cmd_Str') || undef;
                ($cmd_str) = $dbc->Table_find( "Error_Check", "Command_String", "where Error_Check_ID = $error_check_id" );
                show_errchk_details( $dbc, param('Table'), param('Field'), param('Primary'), param('Cmd_Type'), $cmd_str, param('Gen_List'), $error_check_id, $Report );
            }
            elsif ( param('Info') ) {
                print SDB::DB_Form_Viewer::view_records( $dbc, param('Table'), param('Field'), param('Like'), param('Condition') );
            }
            else {

                #Need to filter on Error Check ID that are defined by the current user login UNLESS want to look at errors defined by all users.
                my $condition;
                if ( param('Me_Only') && param('Username') ) {
                    $condition = "where Username = '" . param('Username') . "'";
                }

                print_errchks( $dbc, $condition );
            }
        }

        if ( param('Task') eq 'task3' ) {
            if ( param("Perform Check") || param("Check All") ) {
                my @tables = param('Table');
                perform_enum_checks( -dbc => $dbc, -tables => [ param('Table') ], -show_no_errs => $show_no_errs, -gen_list => $gen_list, -report => $Report );

            }
            elsif ( param('Info') ) {
                print SDB::DB_Form_Viewer::view_records( $dbc, param('Table'), param('Field'), param('Like'), param('Condition') );
            }
            else {
                print_enum_tables($dbc);
            }
        }

        if ( param('Task') eq 'task4' ) {
            if ( param("Perform Check") || param("Check All") ) {
                my @tables = param('Table');
                perform_value_checks( -dbc => $dbc, -tables => [ param('Table') ], -show_no_errs => $show_no_errs, -gen_list => $gen_list, -report => $Report );

            }
            elsif ( param('Info') ) {
                print SDB::DB_Form_Viewer::view_records( $dbc, param('Table'), param('Field'), param('Like'), param('Condition') );
            }
            else {
                print_enum_tables($dbc);
            }
        }

        if ( !param('Task') ) {
            print "no task specified<BR>\n";
        }

        print "\n</TD></TR></Table>";
        &alDente::Web::unInitialize_page($page);
    }

    print "\n";
    print end_form();
}

##########################
sub _print_login_form {
##########################
    #
    #Prints the fields on the login form.
    #
    my $width = 500;
    print qq{<table border=0 cellpadding=0 cellspacing=0><tr><td bgcolor="lightgrey">\n};
    print qq{<Table cellpadding=10 cellspacing=0 border=0 width=$width><TR class='vvlightprodblue'>}, "<TD colspan=2>", submit( -name => 'Login', -value => 'LOGIN', -style => "background-color:red" ), "</TD></TR><TR><TD bgcolor='lightgrey' colspan=2>";

    #Username and Password....
    print "</TD></TR><TR class=vvlightpurple><TD colspan =2>";
    print "</TD></TR><TR class=vvlightpurple><TD>", "<B><Font color=blue Style='font-size: 120%'>mySQL Username:</Font></B>", "</TD><TD>", textfield( -name => 'Username', -value => 'guest', -size => '15' );
    print "</TD></TR><TR class=vvlightpurple><TD>", "<B><Font color=blue Style='font-size: 120%'>mySQL Password:</Font></B>", "</TD><TD>", password_field( -name => 'Pwd', -value => 'aldente', -size => '15' );
    print "</TD></TR><TR bgcolor='lightgrey'><TD colspan=2><HR>\n\n";

    #Select Tasks....
    print "</TD></TR><TR bgcolor=aaaaaa><TD colspan=2>", "<B><Font color=blue>Task:</Font></B><p ></p>";
    my %tasks;
    my $task1 = "Check foreign keys i.e. ensure that links between tables are not broken";
    my $task2 = "Perform checks using tailored commands";
    my $task3 = "Perform enum field check";
    my $task4 = "Perform Quantity unit field check";
    $tasks{"task1"} = $task1;
    $tasks{"task2"} = $task2;
    $tasks{"task3"} = $task3;
    $tasks{"task4"} = $task4;

    my $default_task = param('Task') || 'task1';
    print "</TD></TR><TR bgcolor=aaaaaa><TD colspan=2>", radio_group( -name => 'Task', -value => [ 'task1', 'task2', 'task3' ], -labels => \%tasks, -default => $default_task, -linebreak => 1 ),
        "<br>&nbsp;&nbsp;&nbsp;" . checkbox( -name => 'Me_Only', label => 'Perform checks defined by me only', -checked => '0' ), "<TR bgcolor=aaaaaa><TD colspan=2>", "<HR>";

    #Select Database....
    my @databases = qw(sequence seqdev seqtest);
    if ( $URL_dir_name =~ /SDB_(\w+)/ ) {    # Add own developer version
        push( @databases, "seq$1" );
    }

    print "</TD></TR><TR bgcolor=aaaaaa><TD>", "<B><Font color=blue>Database:</Font></B>", "</TD><TD>", popup_menu( -name => 'Database', -value => [@databases], -force => 1, -default => 'sequence' ), "<BR>";
    print "</TD></TR></Table>";
    print qq{</td></tr></table>\n\n};

    return 1;
}

########################
sub print_fk_tables {
########################
    #
    #Prints out a list of tables as options to perform foreign key checks on.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sth;
    my @ary;

    my $dbase  = $dbc->{dbase};
    my @tables = show_tables($dbc);

    print "<H1 align=center><Font size=5> $dbase Database </Font></H1>\n";

    print checkbox( -name => 'Include_Nulls', label => 'Include null, blank and zero values during foreign key checks.', -checked => '0' ) . br;
    print checkbox( -name => 'Show_No_Errs',  label => 'Display results with no errors as well.',                        -checked => '1' ) . br;
    print checkbox( -name => 'Gen_List',      label => 'Generate a comma-delimited list of orphan foreign keys.',        -checked => '0' ) . br . br;
    print submit( -name => 'Perform Check', -value => '1', -label => 'Perform Check', -style => 'background-color:yellow' );

    #print submit(-name=>'Check All', -value=>'1', -label=>'Check All', -style=>'background-color:yellow');

    my $dbase_table = HTML_Table->new();
    $dbase_table->Set_Headers( [ "Options", "Tables" ] );
    $dbase_table->Set_Border(1);
    $dbase_table->Set_Alignment("center");

    print checkbox( -name => 'Toggle', -onclick => "ToggleCheckBoxes(document.Check_DBase_Integrity,'Select_All')" );

    foreach my $table (@tables) {
        $dbase_table->Set_Row( [ checkbox( -name => 'Table', -value => $table, -label => "" ), $table ] );
    }

    $dbase_table->Set_Class('small');
    $dbase_table->Printout();
}

##########################
sub perform_enum_checks {
##########################

    my %args         = @_;
    my $dbc          = $args{-dbc};
    my $tables       = $args{-tables};
    my $show_no_errs = $args{-show_no_errs};
    my $gen_list     = $args{-gen_list};
    my $Report       = $args{-report};
    my $FILE         = $args{-file};
    my $DAILY_LOG    = $args{-daily_log};
    my $link;

    if ( $Mode eq 'web' ) {
        $link = $thislink;
    }
    elsif ( $Mode eq 'cmd' ) {
        $link = $Home . "?Username=viewer&Pwd=viewer&Database=$dbase&Task=task3";
    }

    my $errors_found = 0;    #indicate whether errors were found.

    my @all_tables = Cast_List( -list => $tables, -to => 'array' );

    if ( param("Check All") ) {
        @all_tables = show_tables($dbc);
    }

    #put all tables in a hash for easy searching.
    my %all_tables;
    foreach my $table (@all_tables) {
        $all_tables{$table} = 1;
    }

    my $table_name_printed = 0;
    my $html_table;
    my $date = &today();
    $html_table = HTML_Table->new();
    $html_table->Set_Title( _adjust_font( "Results from enum checks ($date)", undef, undef, 'bold,underline' ) );
    $html_table->Set_Header_Colour('white');
    $html_table->Set_Class('Small');
    $html_table->Toggle_Colour('off');

    my $dbase = $dbc->{dbase};

    if ( $Mode eq 'cmd' ) {
        print "\n********************************************************************************************\n";
        print "Results from enum checks: (Database = $dbase)\n";
        print "********************************************************************************************\n";
    }

    my $total_errors = 0;
    my $table_count  = 0;
    my $field_count  = 0;

    foreach my $enum_table_name (@all_tables) {
        my @enum_field_names = describe_table( $dbc, $enum_table_name );
        my $enum_field_found = 0;
        $table_name_printed = 0;

        foreach my $enum_field_name (@enum_field_names) {
            my ($field_type) = $dbc->Table_find( "DBTable, DBField",
                "Field_Type", "where FK_DBTable__ID = DBTable_ID and DBTable_Name = '$enum_table_name' and Field_Name = '$enum_field_name' and Field_Options not like '%Obsolete%' and Field_Options not like '%Removed%'" );
            if ( $field_type =~ /^enum/ ) {
                $Report->succeeded() if ($Report);
                my $err_found;
                my $invalid_count;
                my $field_name;
                my $table_name;

                #Message("$enum_table_name: $enum_field_name");
                ( $err_found, $table_name_printed, $field_name, $table_name ) = _check_enum_field( $dbc, $enum_table_name, $enum_field_name, $html_table, \%all_tables, $table_name_printed, $show_no_errs, $Report );

                if ($err_found) {
                    $field_count++;
                    $errors_found = 1;
                    $total_errors += $err_found;
                }
                $enum_field_found = 1;
            }
        }

        if ( !$enum_field_found && $show_no_errs ) {
            $table_name_printed = _print_table_name_header( $enum_table_name, $table_name_printed, $html_table );
            $html_table->Set_Row( [ _adjust_font( "No enum field found", 2, undef, undef ) ] );
            if ( $Mode eq 'cmd' ) {
                print "No enum field found.\n";
            }
        }
        if ($table_name_printed) {
            $table_count++;
            $html_table->Set_Row( [''], 'vvvlightgrey' );    #Make a blank row to separate the database tables for easier viewing.
        }
    }

    my $scope = $dbc->config('host') . '.' . $dbc->config('dbase');

    if ( $Mode eq 'web' ) {
        $html_table->Printout();
    }
    else {

        $html_table->Printout( $Configs{URL_temp_dir} . $enum_check_html );
        my $body = "<P>" . &Link_To( $url_root . $enum_check_html, 'Link to Cron Summary in alDente' );
        my $subject = "DBIntegrity: Enum Check Report ($scope : $table_count tables, $field_count fields, $total_errors errors found)";
    }

    if ($Report) {
        $Report->set_Message( "Tested enum checks: " . $table_count . " tables, " . $field_count . " fields, " . $total_errors . " errors found" );

    }

    if ($FILE) {
        print $FILE "<p ></p><a href=\"../tmp/DBIntegrity_enum_check.html\">DBIntegrity Enum Field Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";
    }

    if ($DAILY_LOG) {
        print $DAILY_LOG "<p ></p><a href=\"../tmp/DBIntegrity_enum_check.html\">DBIntegrity Enum Field Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";
    }

    return ( $errors_found, $html_table );
}

##########################
sub perform_attribute_FK_checks {
##########################
    my %args         = @_;
    my $dbc          = $args{-dbc};
    my $tables       = $args{-tables};
    my $show_no_errs = $args{-show_no_errs};
    my $gen_list     = $args{-gen_list};
    my $Report       = $args{-report};
    my $FILE         = $args{-file};
    my $DAILY_LOG    = $args{-daily_log};

    my $html_table;
    my $date = &today();

    my $dbase = $dbc->{dbase};

    Message "********************************************************************************************";
    Message "Results from attribute foriegn key checks: (Database = $dbase)";
    Message "********************************************************************************************";

    my %attributes = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_ID', 'Attribute_Type', 'Attribute_Class' ], "WHERE Attribute_Type LIKE 'FK%\_%\_\_%'" );
    require SDB::HTML;

    for my $index ( 0 .. int @{ $attributes{Attribute_ID} } - 1 ) {
        my $table;
        if ( $attributes{Attribute_Type}[$index] =~ /FK\_(.+)\_\_/ ) {
            $table = $1;
        }
        unless ($table) { next; }
        my $attribute_table = $attributes{Attribute_Class}[$index] . '_Attribute';
        my ($primary_field) = $dbc->get_field_info( -table => $table, -type => 'PRI' );
        my ($class_fk_field) = $dbc->foreign_key( -table => $attributes{Attribute_Class}[$index] );
        my %result = $dbc->Table_retrieve( "$attribute_table LEFT JOIN $table ON Attribute_Value = $primary_field", [ $class_fk_field, 'Attribute_Value' ], " WHERE FK_Attribute__ID = $attributes{Attribute_ID}[$index] AND $primary_field IS NULL" );

        if ( $result{Attribute_Value} ) {
            my $error_count = @{ $result{Attribute_Value} };
            my $line        = "$attributes{Attribute_Type}[$index]: $error_count records have invalid foriegn keys ";
            $Report->set_Error( "** INVALID Attribute Foreign_Key! $attributes{Attribute_Class}[$index]" . " has $error_count $attributes{Attribute_Type}[$index] invalid foreign key attributes" );
        }
    }

    return;

}

##########################
sub perform_fk_checks {
##########################
    #
    #Perform the foreign key checks
    #
    my $dbc            = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $fk_table_names = shift;
    my $include_nulls  = shift;
    my $show_no_errs   = shift;
    my $gen_list       = shift;
    my $Report         = shift;
    my $FILE           = shift;
    my $DAILY_LOG      = shift;

    my $link;
    if ( $Mode eq 'web' ) {
        $link = $thislink;
    }
    elsif ( $Mode eq 'cmd' ) {
        $link = $Home . "?Username=viewer&Pwd=viewer&Database=$dbase&Task=task1";
    }

    my $errors_found = 0;    #indicate whether errors were found.

    my @all_tables = Cast_List( -list => $fk_table_names, -to => 'array' );

    if ( param("Check All") ) {
        @all_tables = show_tables($dbc);
    }

    #put all tables in a hash for easy searching.
    my %all_tables;
    foreach my $table (@all_tables) {
        $all_tables{$table} = 1;
    }

    my $table_name_printed = 0;
    my $html_table;
    my $date = &today();
    $html_table = HTML_Table->new();
    $html_table->Set_Title( _adjust_font( "Results from foreign key checks ($date)", undef, undef, 'bold,underline' ) );
    $html_table->Set_Header_Colour('white');
    $html_table->Set_Class('Small');
    $html_table->Toggle_Colour('off');

    my $dbase = $dbc->{dbase};

    if ( $Mode eq 'cmd' ) {
        print "\n********************************************************************************************\n";
        print "Results from foreign key checks: (Database = $dbase)\n";
        print "********************************************************************************************\n";
    }

    my $total_errors = 0;
    my $table_count  = 0;
    my $field_count  = 0;

    foreach my $fk_table_name (@all_tables) {
        my @fk_field_names = describe_table( $dbc, $fk_table_name );
        my $fk_field_found = 0;
        $table_name_printed = 0;

        foreach my $fk_field_name (@fk_field_names) {
            if ( $fk_field_name =~ /FK([a-zA-Z0-9]*)_(.*)__(.*)/ ) {
                $Report->succeeded() if ($Report);
                my $err_found;
                my $orphan_count;
                my $field_name;
                my $table_name;

                ( $err_found, $table_name_printed, $field_name, $table_name ) = _check_fk_field( $dbc, $fk_table_name, $fk_field_name, $html_table, \%all_tables, $table_name_printed, $include_nulls, $show_no_errs, $Report );

                if ($err_found) {
                    $errors_found = 1;
                    $total_errors += $err_found;
                    $field_count++;
                }
                $fk_field_found = 1;
            }
        }

        if ( !$fk_field_found && $show_no_errs ) {
            $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );
            $html_table->Set_Row( [ _adjust_font( "No foreign key fields found", 2, undef, undef ) ] );
            if ( $Mode eq 'cmd' ) {
                print "No foreign key fields found.\n";
            }
        }
        if ($table_name_printed) {
            $table_count++;
            $html_table->Set_Row( [''], 'vvvlightgrey' );    #Make a blank row to separate the database tables for easier viewing.
        }
    }

    my $scope = $dbc->config('host') . '.' . $dbc->config('dbase');

    if ( $Mode eq 'web' ) {
        $html_table->Printout();
    }
    else {
        $html_table->Printout( $Configs{URL_temp_dir} . $fk_check_html );
        my $body = "<P>" . &Link_To( $url_root . $fk_check_html, 'Link to Cron Summary in alDente' );
        my $subject = "DBIntegrity: Foreign Key Check Report ($scope : $table_count tables, $field_count fields, $total_errors errors found)";

        if ($total_errors) {
            alDente::Notification::Email_Notification( -to_address => $to_email, -from_address => $FROM_EMAIL, -subject => $subject, -body => $body, -content_type => "html" );
        }
    }

    if ($Report) {
        $Report->set_Message( "Tested fk checks: " . $table_count . " tables, " . $field_count . " fields, " . $total_errors . " errors found" );

    }
    if ($FILE) {

        print $FILE "<p ></p><a href=\"../tmp/DBIntegrity_fk_check.html\">DBIntegrity Foreign Key Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";
    }

    if ($DAILY_LOG) {
        print $DAILY_LOG "<p ></p><a href=\"../tmp/DBIntegrity_fk_check.html\">DBIntegrity Foreign Key Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";
    }

    return ( $errors_found, $html_table );
}

######################
sub print_errchks {
######################
    #
    #Prints the error check page.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $condition = shift;

    my %info = Table_retrieve( $dbc, 'Error_Check', [ 'Error_Check_ID', 'Table_Name', 'Field_Name', 'Username', 'Command_Type', 'Command_String', 'Comments', 'Description', 'Action', 'Priority' ], $condition );

    print checkbox( -name => 'Show_No_Errs', label => 'Display results with no errors as well.', -checked => '0' ) . br . br;
    print checkbox( -name => 'Gen_List', label => 'Generate a comma-delimited list of IDs of match records.', -checked => '0' ) . br . br;
    print submit( -name => "Perform_Check", -label => 'Perform check on selected items', -class => "Std" ) . hspace(5);
    print &Link_To( $dbc->config('homelink'), "Add/Edit Error Checks", "&Edit+Table=Error_Check", 'blue', ['newwin'] );

    my $table = HTML_Table->new();
    $table->Set_Class('Small');
    $table->Set_Headers(
        [   checkbox( -name => 'Select_All', -label => '', -onClick => "ToggleCheckBoxes(document.Check_DBase_Integrity,'Select_All');" ),
            'Error_Check_ID', 'Username', 'Table_Name', 'Field_Name', 'Command_Type', 'Command_String', 'Description', 'Action', 'Comments', 'Priority'
        ]
    );

    my $i = 0;
    while ( defined $info{Error_Check_ID}[$i] ) {
        $table->Set_Row(
            [   checkbox( -name => 'Error_Check_ID', -value => $info{Error_Check_ID}[$i], -label => '' ),
                $info{Error_Check_ID}[$i],
                $info{Username}[$i],
                $info{Table_Name}[$i],
                $info{Field_Name}[$i],
                $info{Command_Type}[$i],
                $info{Command_String}[$i],
                $info{Description}[$i],
                $info{Action}[$i],
                $info{Comments}[$i],
                $info{Priority}[$i]
            ]
        );
        $i++;
    }

    $table->Printout();
}

#################################
sub perform_cmd_indexcheck {
#################################
    my $dbc        = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables_ref = shift;                                                                     # arrayref of tables to be checked for indexes
    my $fks_only   = shift;                                                                     # flag to suppress listing of non-fk fields
    my $add_index  = shift;
    my $Report     = shift;
    my $verbose    = shift;

    foreach my $table ( @{$tables_ref} ) {
        my @index_info = &get_field_info( $dbc, $table, "", "ind" );
        push( @index_info, &get_field_info( $dbc, $table, "", "uni" ) );
        push( @index_info, &get_field_info( $dbc, $table, "", "pri" ) );
        my @fields = &get_field_info( $dbc, $table );

        my %seen;
        my @non_indexed_fields = ();
        my @indexed_fields     = ();
        foreach ( @fields, @index_info ) {
            $seen{$_}++;
        }
        foreach ( keys %seen ) {
            if ( $seen{$_} == 1 ) {
                push( @non_indexed_fields, $_ );
            }
            else {
                push( @indexed_fields, $_ );
            }
        }

        # data output
        if ($verbose) {
            print "\n**** Summary for table $table ****\n";
            print "-> Indexed columns for table $table\n";
            foreach (@indexed_fields) {
                print "    indexed field $_\n";
            }
            unless ($fks_only) {
                print "-> Non-indexed columns for table $table\n";
            }
            foreach (@non_indexed_fields) {
                if ( $_ =~ /^FK/ ) {
                    $Report->set_Warning("** MISSING INDEX ! $_ is a foreign key of $table and must be indexed");
                    if ($add_index) {
                        my $cmdstr = "CREATE INDEX $_ ON $table($_)";
                        print $cmdstr . "\n";
                        $Report->set_Message($cmdstr);
                        $dbc->execute_command( -command => $cmdstr, -feedback => 2 );
                    }
                }
                elsif ( !$fks_only ) {
                    print "    non-indexed field $_\n";
                }
            }
        }
    }
    my $count = @{$tables_ref};
    print "* Performed Index Check on $count tables\n";
    return;
}

########################
sub perform_cmdchks {
########################
    #
    # Perform check based on command strings from the Error_Check table.
    #
    my $dbc             = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $error_check_ids = shift;
    my $show_no_errs    = shift;
    my $email_request   = shift;
    my $force_notify    = shift;
    my $gen_list        = shift;
    my $Report          = shift;
    my $FILE            = shift;
    my $DAILY_LOG       = shift;
    my $debug           = shift;
    my @notify_ids;    #Consist of a list of Error_Check_IDs where actual errors are found and to be notified.
    my $html_table;

    my $link;
    if ( $Mode eq 'web' ) {
        $link = $thislink;
    }
    elsif ( $Mode eq 'cmd' ) {
        $link = $homefile . "?Username=viewer&Pwd=viewer&Database=$dbase&Task=task2";
    }
    my $error_type_count = 0;
    my $errors_found     = 0;
    my $date             = &today();
    $html_table = HTML_Table->new();
    $html_table->Set_Title( _adjust_font( "Results from Error_Check checks ($date)", undef, undef, 'bold,underline' ) );
    $html_table->Set_Class('Small');

    #$html_table->Set_Headers(['Error_Check_ID','Table_Name','Field_Name','Command_Type','Description','Action','Comments','Priority','Results']);
    $html_table->Set_Headers( [ 'Error_Check_ID', 'Table_Name', 'Field_Name', 'Comments', 'Action', 'Results', 'Graphs', 'Priority', 'Email_List' ] );

    my $dbase = $dbc->{dbase};

    if ( $Mode eq 'cmd' ) {
        print "\n********************************************************************************************\n";
        print "Results from error checks: (Database = $dbase)\n";
        print "********************************************************************************************\n";
    }

    my $total_count = 0;

    #Perform check on each items pass in...
    foreach my $id ( @{$error_check_ids} ) {

        #First query for the command string.
        my %info = Table_retrieve(
            $dbc, 'Error_Check',
            [ 'Error_Check_ID', 'Table_Name', 'Field_Name', 'Command_Type', 'Command_String', 'Notice_Sent As Sent', 'Notice_Frequency As Freq', 'Description', 'Action', 'Comments', 'Priority', 'Email_List' ],
            "where Error_Check_ID = $id",
            -debug => $debug
        );
        my $i     = 0;
        my $count = 0;
        my $errors;    ###Reference to the hash of error records.
        my $errstr;    # An error string

        my %id_list;
        while ( defined $info{Error_Check_ID}[$i] ) {
            my $id          = $info{Error_Check_ID}[$i];
            my $table_name  = $info{Table_Name}[$i];                    #can consist of a comma-delimited list of multiple tables
            my $field_name  = $info{Field_Name}[$i];                    #can consist of a comma-delimited list of multiple fields
            my $cmd_type    = $info{Command_Type}[$i];
            my $sent        = convert_date( $info{Sent}[$i], 'SQL' );
            my $freq        = $info{Freq}[$i] || 7;
            my $cmd_str     = $info{Command_String}[$i];
            my $comments    = $info{Comments}[$i];
            my $description = $info{Description}[$i];
            my $action      = $info{Action}[$i];
            my $priority    = $info{Priority}[$i];
            my $email_list  = $info{Email_List}[$i];

            my $do_not_notify = 0;                                      #Indicate whether to send notification regarding an Error_Check_ID.
            if ($email_request) {
                my $timecheck = &today("-$freq");

                #if (($sent gt $timecheck) || ($freq == 0)) {$do_not_notify = 1;} # May 2/05 - Mario - disabled to allow for email notification any time
            }

            my @tables = split( /,/, $table_name );                     #convert to an array.
                                                                        #my @fields = split(/,/, $field_name); #convert to an array.
            my @primary_keys;

            #Get the primary key fields.
            foreach my $table (@tables) {
                my ($primary) = get_field_info( $dbc, $table, undef, 'Primary' );
                push( @primary_keys, $primary );
            }

            $count = _execute_cmd_str(
                -dbc          => $dbc,
                -table_name   => $table_name,
                -field_name   => $field_name,
                -cmd_type     => $cmd_type,
                -cmd_str      => $cmd_str,
                -primary_keys => join( ",", @primary_keys ),
                -report       => $Report,
                -options      => ['count_only'],
                -err_check_id => $id,
                -debug        => $debug
            );

            if ($count) {
                $Report->set_Error("Errors found for $count $table_name.$field_name records (Error_Check ID: $id)") if $Report;
                if ( $cmd_type eq 'Perl' ) {
                    $html_table->Set_Row(
                        [   _adjust_font( $id,         2, undef, undef ),
                            _adjust_font( $table_name, 2, undef, undef ),
                            _adjust_font( $field_name, 2, undef, undef ),
                            _adjust_font( $comments,   2, undef, undef ),
                            _adjust_font( $action,     2, undef, undef ),
                            &Link_To(
                                $link,
                                "<b>" . _adjust_font( "Errors found for $count records.", 2, undef, undef ) . "</b>",
                                "&Show_Errchk_Details=1&Gen_List=" . param('Gen_List') . "&Table=$table_name&Field=$field_name&Primary=" . join( ",", @primary_keys ) . "&Cmd_Type=$cmd_type&Error_Check_ID=$id",
                                'red', ['newwin']
                            ),
                            "<IMG SRC='" . $Report->error_graph( -subtitle => "Err$id", -format => 'URL' ) . "'>",
                            $priority,
                            $email_list
                        ]
                    );
                }
                else {
                    $html_table->Set_Row(
                        [   _adjust_font( $id,         2, undef, undef ),
                            _adjust_font( $table_name, 2, undef, undef ),
                            _adjust_font( $field_name, 2, undef, undef ),
                            _adjust_font( $comments,   2, undef, undef ),
                            _adjust_font( $action,     2, undef, undef ),
                            &Link_To(
                                $link,
                                "<b>" . _adjust_font( "Errors found for $count records.", 2, undef, undef ) . "</b>",
                                "&Show_Errchk_Details=1&Gen_List=" . param('Gen_List') . "&Table=$table_name&Field=$field_name&Primary=" . join( ",", @primary_keys ) . "&Cmd_Type=$cmd_type&Error_Check_ID=$id&Cmd_Str=" . uri_escape( $cmd_str, "\'\+" ),
                                'red', ['newwin']
                            ),
                            "<IMG SRC='" . $Report->error_graph( -subtitle => "Err$id", -format => 'URL' ) . "'>",
                            $priority,
                            $email_list

                        ]
                    );

                    if ($email_list) {
                        my $date      = today();
                        my $timecheck = &today("-$freq");
                        if ( $timecheck gt $sent ) {
                            my $email_title = "Custom Error Report: Error Number $id ($table_name: $field_name )";
                            my $email_body  = "Custom Error Report: Error Number $id ($table_name: $field_name )" 
                                . vspace() 
                                . " $description  " 
                                . vspace() 
                                . "Priority : $priority " 
                                . vspace() 
                                . "To view details use the following link: "
                                . &Link_To(
                                $link,
                                "<b>" . _adjust_font( "Errors found for $count records.", 2, undef, undef ) . "</b>",
                                "&Show_Errchk_Details=1&Gen_List=" . param('Gen_List') . "&Table=$table_name&Field=$field_name&Primary=" . join( ",", @primary_keys ) . "&Cmd_Type=$cmd_type&Error_Check_ID=$id&Cmd_Str=" . uri_escape( $cmd_str, "\'\+" ),
                                'red', ['newwin']
                                );
                            alDente::Notification::Email_Notification( -to_address => $email_list, -from_address => $FROM_EMAIL, -subject => $email_title, -body => $email_body, -content_type => "html" );
                            $dbc->Table_update_array( 'Error_Check', ['Notice_Sent'], [$date], "where Error_Check_ID = $id", -autoquote => 1 );
                        }

                    }
                }
            }
            elsif ($show_no_errs) {
                $html_table->Set_Row(
                    [   _adjust_font( $id,          2, undef, undef ),
                        _adjust_font( $table_name,  2, undef, undef ),
                        _adjust_font( $field_name,  2, undef, undef ),
                        _adjust_font( $cmd_type,    2, undef, undef ),
                        _adjust_font( $description, 2, undef, undef ),
                        _adjust_font( $comments,    2, undef, undef ),
                        _adjust_font( "OK.",        2, undef, undef )
                    ]
                );
            }

            $Report->_write_to_stats_file( $count, -subtitle => "Err$id", -quiet => 1 );
            my $graph = $Report->generate_stats_graphs( -subtitle => "Err$id" );

            if ( $Mode eq 'cmd' ) {
                my $errors;
                ( $count, $errors, $errstr )
                    = _execute_cmd_str( -dbc => $dbc, -table_name => $table_name, -field_name => $field_name, -cmd_type => $cmd_type, -cmd_str => $cmd_str, -primary_keys => join( ",", @primary_keys ), -report => $Report, -err_check_id => $id );

                if ( $count || $show_no_errs ) {
                    print "\n********************************************************************************************\n";
                    print "Error_Check_ID: $id\n";
                    print "Table: $table_name\n";
                    print "Field: $field_name\n";
                    print "Command Type: $cmd_type\n";
                    print "Command String: $cmd_str\n";
                    print "--------------------------------------------------------------------------------------------\n";
                }

                if ($count) {
                    $error_type_count++;
                    $total_count += $count;
                    $errors_found = 1;
                    print "Errors found for $count records:\n";

                    if ( $cmd_type eq 'RegExp' || $cmd_type eq 'SQL' ) {
                        my @fields = _combine_fields( join( ",", @primary_keys ), $field_name );    #Fields to be displayed in the table.

                        my $j = 0;
                        while ( defined $errors->{ $primary_keys[0] }[$j] ) {
                            my $output = "===";
                            foreach my $field (@fields) {
                                $output .= $field . "(" . $errors->{$field}[$j] . "); ";
                                if ( $field =~ /^([a-zA-Z0-9]*)[_]ID$/ && $gen_list ) {

                                    #Store the IDs if we are generating a list.
                                    push( @{ $id_list{$field} }, $errors->{$field}[$j] );
                                }
                            }
                            print "$output\n";
                            $j++;
                        }
                    }

                    #don't want to look at the primary keys since whatever fields we are retrieving/displaying should be speicify in the Field_Name and Command_String fields.
                    elsif ( $cmd_type eq 'FullSQL' ) {
                        my @fields = split( /,/, $field_name );    #convert to an array.

                        my $j = 0;
                        while ( defined $errors->{ $fields[0] }[$j] ) {
                            my $output = "===";
                            foreach my $field (@fields) {
                                $output .= $field . "(" . $errors->{$field}[$j] . "); ";
                                if ( $field =~ /^([a-zA-Z0-9]*)[_]ID$/ && $gen_list ) {

                                    #Store the IDs if we are generating a list.
                                    push( @{ $id_list{$field} }, $errors->{$field}[$j] );
                                }
                            }
                            print "$output\n";
                            $j++;
                        }
                    }
                    elsif ( $cmd_type eq 'Perl' ) {
                        $errstr =~ s/<br>/\n/g;
                        print "$errstr\n";
                    }
                    if ( $force_notify || !$do_not_notify ) {
                        push( @notify_ids, $id );    #Keep track of all Error_Check_IDs to be notified to the user.
                    }
                }
                elsif ($show_no_errs) {
                    print "==>OK.\n";
                    if ( $force_notify || !$do_not_notify ) {
                        push( @notify_ids, $id );    #Keep track of all Error_Check_IDs to be notified to the user.
                    }
                }
            }
            $i++;
        }
        if ($gen_list) {
            print "--------------------------------------------------------------------------------------------\n";
            foreach my $field ( keys %id_list ) {
                print "-->$field: " . join( ",", @{ $id_list{$field} } ) . "\n";
            }
            print "--------------------------------------------------------------------------------------------\n";
        }
    }

    my $scope = $dbc->config('host') . '.' . $dbc->config('dbase');

    if ( $Mode eq 'web' ) {
        $html_table->Printout();
    }
    else {
        $html_table->Printout( $Configs{URL_temp_dir} . $err_check_html );
        my $body = "<P>" . &Link_To( $url_root . $err_check_html, 'Link to Cron Summary in alDente' );
        my $subject = "DBIntegrity: Error Check Report ($scope : $total_count errors found)";
        if ($total_count) {
            alDente::Notification::Email_Notification( -to_address => $to_email, -from_address => $FROM_EMAIL, -subject => $subject, -body => $body, -content_type => "html" );
        }
    }
    if ($Report) {
        $Report->set_Message( "Tested " . scalar( @{$error_check_ids} ) . " Error Check IDs: " . $total_count . " errors found" );
    }

    if ($FILE) {
        print $FILE "<p ></p><a href=\"../tmp/DBIntegrity_err_check.html\">DBIntegrity Error Check Report  ($error_type_count types, $total_count errors found)/a></p>";
    }

    if ($DAILY_LOG) {
        print $DAILY_LOG "<p ></p><a href=\"../tmp/DBIntegrity_err_check.html\">DBIntegrity Error Check Report ($error_type_count types, $total_count errors found)</a></p>";
    }

    return ( $total_count, $html_table, @notify_ids );
}

#############################
sub show_errchk_details {
#############################
    #
    #Show the records that are found to have errors during error check.
    #
    my $dbc            = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table_name     = shift;
    my $field_name     = shift;
    my $primary_keys   = shift;
    my $cmd_type       = shift;
    my $cmd_str        = shift;
    my $gen_list       = shift;
    my $error_check_id = shift;
    my $Report         = shift;

    my $link;
    if ( $Mode eq 'web' ) {
        $link = $thislink;
    }
    elsif ( $Mode eq 'cmd' ) {
        $link = $Home . "?Username=viewer&Pwd=viewer&Database=$dbase&Task=task2";
    }

    if ( $cmd_type eq 'Perl' ) {
        my %info = Table_retrieve( $dbc, 'Error_Check', [ 'Error_Check_ID', 'Table_Name', 'Field_Name', 'Command_Type', 'Command_String' ], "where Error_Check_ID = $error_check_id" );
        my $i = 0;
        while ( defined $info{Error_Check_ID}[$i] ) {
            $table_name = $info{Table_Name}[$i];       #can consist of a comma-delimited list of multiple tables
            $field_name = $info{Field_Name}[$i];       #can consist of a comma-delimited list of multiple fields
            $cmd_type   = $info{Command_Type}[$i];
            $cmd_str    = $info{Command_String}[$i];
            $i++;
        }
    }

    #$errors is a pointer to a hash of error records.
    my ( $count, $errors, $errstr )
        = _execute_cmd_str( -dbc => $dbc, -table_name => $table_name, -field_name => $field_name, -cmd_type => $cmd_type, -cmd_str => $cmd_str, -primary_keys => $primary_keys, -report => $Report, -err_check_id => $error_check_id );

    $cmd_str =~ s/\n/<br>/g;
    $cmd_str = "<br><br><span class='small'>$cmd_str</span><br>";

    print "Table: $table_name" . br;
    print "Field: $field_name" . br;
    print "Command Type: $cmd_type" . br;
    print "Command String: $cmd_str" . br;
    print "Errors found for $count records." . br;
    $Report->set_Error("Found $count errors for $table_name.$field_name (Error_Check ID: $error_check_id)") if $Report;

    my $table = HTML_Table->new();
    $table->Set_Class('Small');

    my @fields;
    if ( $cmd_type eq 'RegExp' || $cmd_type eq 'SQL' ) {
        @fields = _combine_fields( $primary_keys, $field_name );    #Fields to be displayed in the table.
    }
    elsif ( $cmd_type eq 'FullSQL' ) {                              #We don't want to automatically include the primary keys in the fields displayed if we are doing a "FullSQL"
        @fields = split( /,\s*/, $field_name );
    }
    elsif ( $cmd_type eq 'Perl' ) {
        $$errstr =~ s/\n/<br>/g;
        print "<p ></p>$$errstr<br>";
        return;
    }

    $table->Set_Headers( \@fields );

    my $i = 0;
    my %id_list;                                                    #hash for storing list of IDs.
    while ( defined $errors->{ $fields[0] }[$i] ) {
        my @results;
        foreach my $field (@fields) {
            my $value = $errors->{$field}[$i];

            if ($value) {
                if ( $field =~ /FK([a-zA-Z0-9]*)_(.*)__(.*)/ ) {    #### hyperlink to FKeys..
                    my $sub_table = $2;
                    my $sub_field = "$2" . "_$3";
                    my $showvalue = get_FK_info( $dbc, $field, $value );
                    $value = &Link_To( $dbc->config('homelink'), $showvalue, "&Info=1&Table=$sub_table&Field=$sub_field&Like=$value", 'blue', ['newwin'] );
                }
                elsif ( $field =~ /^([a-zA-Z0-9]*)[_]ID$/ ) {

                    #Store the IDs if we are generating a list.
                    if ($gen_list) {
                        push( @{ $id_list{$field} }, $value );
                    }

                    # Mario - Oct. 6/05
                    # The following links have been changed to go directly to the objects homepage rather than to the info table
                    $value = &Link_To( $dbc->config('homelink'), $value, "&HomePage=$1&ID=$value", 'blue', ['newwin'] );
                }
                elsif ( $field =~ /^([a-zA-Z0-9]*)[_]Name$/ ) {
                    $value = &Link_To( $dbc->config('homelink'), $value, "&HomePage=$1&ID=$value", 'blue', ['newwin'] );
                }
            }

            push( @results, $value );
        }
        $table->Set_Row( \@results );
        $i++;
    }

    $table->Printout();

    if ($gen_list) {
        foreach my $field ( keys %id_list ) {
            print "$field: " . join( ",", @{ $id_list{$field} } ) . br;
        }
    }
}

###############################
sub perform_refchks {
###############################
    #
    #Perform reference checks.
    #
    my $dbc         = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $checkfield  = shift;
    my $checkvalues = shift;
    my $gen_list    = shift;
    my $recursive   = shift;
    my $rec_lvl     = shift;                                                                     #recursive level

    my $found;
    my $indent = "---" x $rec_lvl;                                                               #Indentation for recursive finds.

    ### Get the Object_Class_ID for this Object if it exists
    $checkfield =~ /(\w+)_ID/i;
    my $object_name = $1;
    my $object_class_id = join ',', $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class='$object_name'" );

    my @tables = show_tables($dbc);
    foreach my $table (@tables) {
        my ($primary) = &get_field_info( $dbc, $table, undef, 'Primary' );                       #Get the primary key field.
                                                                                                 #my $sth = $dbc->query(-query=>"DESC $table",-finish=>0);
                                                                                                 #my $fields_ar = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'CA');
                                                                                                 #my @fields = @$fields_ar;
        my @fields = describe_table( $dbc, $table );
        foreach my $field (@fields) {
            if ( $field =~ /FK([a-zA-Z0-9]*)_(.*)__(.*)/ ) {                                     #if the field is a foreign key field....

                #Remove the FK characteristics of the FK field and compare.
                my $matchfield;
                ( undef, $matchfield ) = _split_fk_field_name($field);

                if ( $matchfield eq $checkfield ) {
                    if ($checkvalues) {

                        #Query to see if the FK field contains the check values.
                        foreach my $checkvalue ( split( /,/, $checkvalues ) ) {
                            my @row3;

                            if ($gen_list) {
                                @row3 = $dbc->Table_find( $table, $primary, "WHERE $field = '$checkvalue' order by $primary" );
                            }
                            else {
                                @row3 = $dbc->Table_find( $table, "count(*)", "WHERE $field = '$checkvalue'" );
                            }

                            my $count = 0;
                            my $ref_list;
                            foreach my $result (@row3) {

                                if ($result) {
                                    if ($gen_list) {
                                        if ($ref_list) {
                                            $ref_list .= ",$result";
                                        }
                                        else {
                                            $ref_list .= $result;
                                        }
                                        $count++;
                                    }
                                    else {
                                        $count = $result;
                                    }
                                    $found = 1;
                                }
                            }
                            if ( $found && $count ) {
                                print "$indent$table.$field -> '$checkvalue' ($count records)";
                                if ( $gen_list && $ref_list ) {
                                    print "\n$indent" . "[$table.$primary = ($ref_list)]\n";
                                    if ($recursive) {
                                        ###Recursively find references.
                                        perform_refchks( $dbc, $primary, $ref_list, $gen_list, $recursive, $rec_lvl + 1 );
                                    }
                                }
                                print "\n";
                            }
                        }
                    }
                    else {
                        print "$table.$field\n";
                        $found = 1;
                    }
                }
                elsif ( ( $field eq 'FK_Object_Class__ID' ) && $object_class_id ) {
                    ### Needs more work....

                    ### Check to see if $table has Object_ID as a column...
                    my $object_column_exists = &get_field_info( $dbc, $table, 'Object_ID' );    #Get the primary key field.

                    if ($object_column_exists) {
                        my @values;
                        if ($gen_list) {
                            @values = $dbc->Table_find( $table, $primary, "WHERE Object_ID IN ($checkvalues) ORDER BY $primary" );
                        }
                        else {
                            @values = $dbc->Table_find( $table, "count($primary)", "WHERE Object_ID IN ($checkvalues)" );
                        }
                        if ($gen_list) {
                            print "\n$indent" . "[$table.$primary = (" . join( ',', @values ) . ")\n";
                        }
                        elsif ( $values[0] > 0 ) {
                            my $count = $values[0];
                            print "$indent$table.$field -> 'Object_Class:$object_class_id Object_ID: $checkvalues' ($count records)\n";
                        }
                    }
                }

            }
        }
    }

    if ( !$found && $rec_lvl == 0 ) {
        print $indent . "Nothing found.";
    }
    print "\n";
}

#######################
sub describe_table {
#######################
    #
    #Describe the table and return the fields into an array.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table_name = shift;

    #my $sth = $dbc->query(-query=>"DESC $table_name",-finish=>0);
    #my $b =  &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'CA');
    my @b = $dbc->Table_find( "DBTable, DBField", "Field_Name", "where FK_DBTable__ID = DBTable_ID and DBTable_Name = '$table_name'", -distinct => 1 );
    return @b;
}

#######################
sub show_tables {
#######################
    #
    #Retrieve all the table names in the database into an array.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    #my $sth = $dbc->query(-query=>"SHOW TABLES",-finish=>0);
    #my $tables = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'CA');
    my @tables = $dbc->Table_find( "DBTable", "DBTable_Name", "where 1", -distinct => 1 );

    return @tables;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

########################
sub _check_fk_field {
########################
    #
    #Checks whether there are orphan records.
    #
    my $dbc                = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $fk_table_name      = shift;
    my $fk_field_name      = shift;
    my $html_table         = shift;
    my $all_tables_ref     = shift;
    my $table_name_printed = shift;
    my $include_nulls      = shift;
    my $show_no_errs       = shift;
    my $Report             = shift;

    my %info;
    my @orphan_count;
    my @FK_ref_value;

    my $total_errors = 0;

    my ( $table_name, $field_name ) = _split_fk_field_name($fk_field_name);
    unless ( $table_name && $field_name ) {
        $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );
        $html_table->Set_Row( [ _adjust_font( "There is an error in the form of the FK_Table__Field_Name: $fk_field_name in $fk_table_name table.", 2, 'red', undef ) ], 'lightredbw' );
        if ( $Mode eq 'cmd' ) {
            print "===There is an error in the form of the FK_Table__Field_Name: $fk_field_name in $fk_table_name table\n";
        }
        return ( 1, undef, $table_name_printed );    #Return value of 1 indicates errors was found.
    }
    my %ref_all_tables;
    my @t = show_tables($dbc);

    map { $ref_all_tables{$_} = 1 } @t;

    #First retrieve distinct fk field values.
    #if (exists $all_tables_ref->{$table_name}) {
    if ( exists $ref_all_tables{$table_name} ) {

        if ( $fk_table_name eq $table_name ) {
            %info = Table_retrieve(
                $dbc,
                "$fk_table_name AS child LEFT JOIN $table_name AS parent ON child.$fk_field_name = parent.$field_name",
                [ "Count(*) AS Count", "child.$fk_field_name" ],
                "WHERE parent.$field_name IS NULL AND child.$fk_field_name NOT IN (0,'') GROUP BY child.$fk_field_name"
            );
        }
        else {
            %info = Table_retrieve(
                $dbc,
                "$fk_table_name AS child LEFT JOIN $table_name AS parent ON child.$fk_field_name = parent.$field_name",
                [ "Count(*) AS Count", "child.$fk_field_name" ],
                "WHERE parent.$field_name IS NULL AND child.$fk_field_name NOT IN (0,'') GROUP BY child.$fk_field_name"
            );
        }
    }
    else {
        $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );
        $html_table->Set_Row( [ _adjust_font( "$fk_field_name references the $table_name table which does not exist in the database", 2, 'red', undef ) ], 'lightredbw' );
        if ( $Mode eq 'cmd' ) {
            print "===$fk_table_name.$fk_field_name references $table_name which does not exist in the database.\n";
        }
        return 1;    #Return value of 1 indicates errors was found but .
    }

    if ( exists $info{Count}[0] ) {
        @orphan_count = @{ $info{Count} };
        my $fk_fld = $fk_field_name;
        $fk_fld =~ s/\.(.*)/$1/;
        @FK_ref_value = @{ $info{$fk_fld} };
        $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );

        if ( $Mode eq 'cmd' ) {
            print "**************************\n";
            print "$fk_field_name\n";
            print "**************************\n";
        }
    }
    elsif ($show_no_errs) {
        $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );
        $html_table->Set_Row( [ _adjust_font( "$fk_field_name : no errors", 2, undef, undef ) ] );
    }
    my $defined = 0;    ## initialize error found
    ### CHECK TO SEE IF THE FIELD IS MANDATORY
    my @mandatory_list  = ();                        #@{mandatory_field_check(-dbc=>$dbc,-table=>$fk_table_name,-field=>$fk_field_name)};
    my $mandatory_count = scalar(@mandatory_list);
    if ( exists $info{Count}[0] || $mandatory_count > 0 ) {
        unless ($table_name_printed) {
            $table_name_printed = _print_table_name_header( $fk_table_name, $table_name_printed, $html_table );
        }
        $html_table->Set_sub_header( "$fk_field_name", 'black' );
    }

    #Now retrieve distinct parent field values.
    #First see if the table referring to actually exist or not...
    for ( my $i = 0; $i < scalar(@FK_ref_value); $i++ ) {

        my $orphan_count = $orphan_count[$i];
        my $FK_ref_value = $FK_ref_value[$i];

        $total_errors += $orphan_count;
        if ( $orphan_count > 0 ) {

            # if more than 20 records with missing distinct FK_values just display the summary info rather that listing them all
            if ( scalar(@orphan_count) < 20 ) {
                $html_table->Set_Row( [ _adjust_font( "$orphan_count \t$fk_table_name.$fk_field_name reference(s) to non-existing $field_name ($FK_ref_value)", 2, 'red', undef ) ], 'lightredbw' );

                #Call_Stack();
                $Report->set_Error("$orphan_count \t$fk_table_name.$fk_field_name reference(s) to non-existing $field_name ($FK_ref_value)") if $Report;

                #                if ( $Mode eq 'cmd' ) {#
                #                    print "=== $orphan_count \t$fk_table_name.$fk_field_name reference(s) to non-existing $field_name ($FK_ref_value)\n";
                #                }
            }
            else {
                $html_table->Set_Row( [ _adjust_font( scalar(@orphan_count) . " $fk_field_name reference(s) to distinct, non-existing $field_name", 2, 'red', undef ) ], 'lightredbw' );
                $Report->set_Error("$fk_field_name reference(s) to distinct, non-existing $field_name") if $Report;

                #                if ( $Mode eq 'cmd' ) {#
                #                    print "=== " . scalar(@orphan_count) . " $fk_field_name reference(s) to distinct, non-existing $field_name\n";
                #                }
                last;
            }
        }
    }

    if ( $mandatory_count > 0 ) {
        $defined = 1;

        if ( $Mode eq 'cmd' ) {
            print "Mandatory Field Check: \n";
            print "$mandatory_count record(s) have NULL, '', or 0 for table '$fk_table_name', mandatory field '$fk_field_name' \n";

        }
        else {

            $html_table->Set_Row( [ _adjust_font( "$mandatory_count record(s) have NULL, '', or 0 for table '$fk_table_name', mandatory field '$fk_field_name'", 2, 'red', undef ) ], 'lightyellow' );
            $Report->set_Error("$mandatory_count record(s) have NULL, '', or 0 for table '$fk_table_name', mandatory field '$fk_field_name'") if $Report;
        }
    }
    if (%info) { $defined = 1 }

    return ( $total_errors, $table_name_printed, $field_name, $table_name );    #Returns number of errors found (0 = not found)
}

##############################
sub _split_fk_field_name {
##############################
    #
    #Takes the FK_Field_Name and returns an array with the Table Name and Field Name
    #
    my ($fk_field_name) = @_;

    my @split_FK_Field_Name = split( /_/, $fk_field_name );
    my $place_of_empty_string;
    my $split_FK_Field_Name_length = @split_FK_Field_Name;
    my $table_name;
    my $field_name;

    for ( my $i = 0; $i < $split_FK_Field_Name_length; $i++ ) {
        if ( $split_FK_Field_Name[$i] eq "" ) {
            $place_of_empty_string = $i;    #find the placement of the empty string that corresponds to '__'
        }
    }

    if ( $place_of_empty_string > 1 ) {
        $table_name = $split_FK_Field_Name[1];
        for ( my $i = 2; $i < $place_of_empty_string; $i++ ) {
            $table_name = $table_name . "_" . $split_FK_Field_Name[$i];    #extract the Table Name from the form FK_Table__FieldName
        }
        $field_name = $table_name;
        for ( my $i = $place_of_empty_string + 1; $i < $split_FK_Field_Name_length; $i++ ) {    #extract the Field Name from the form FK_Table__FieldName
            $field_name = $field_name . "_" . $split_FK_Field_Name[$i];                         #Note that the Field Name is actually equal to the combination of Table_FieldName
        }
    }
    else {
        return 0;
    }
    return ( $table_name, $field_name );
}

########################
sub _check_enum_field {
########################
    #
    #Checks whether there are orphan records.
    #
    my $dbc                = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $enum_table_name    = shift;
    my $enum_field_name    = shift;
    my $html_table         = shift;
    my $all_tables_ref     = shift;
    my $table_name_printed = shift;
    my $show_no_errs       = shift;
    my $Report             = shift;

    my @enum_list = $dbc->get_enum_list( -table => $enum_table_name, -field => $enum_field_name );

    my %enum_list_hash;
    map { $enum_list_hash{$_} = 1 } @enum_list;

    my ($null_ok) = $dbc->Table_find( "DBTable, DBField", "NULL_ok", "where DBTable_Name = '$enum_table_name' and FK_DBTable__ID = DBTable_ID and Field_Name = '$enum_field_name'" );
    if ( $null_ok =~ /no/i ) {
        $null_ok = 0;
    }
    else {
        $null_ok = 1;
    }

    my %info = Table_retrieve( $dbc, "$enum_table_name", [ "Count(*) AS Count", "$enum_field_name" ], "WHERE 1 GROUP BY $enum_field_name" );

    my $index = 0;
    my %invalid_count;
    while ( $info{Count}->[$index] ) {
        my $value = $info{$enum_field_name}->[$index];
        my $count = $info{Count}->[$index];

        if ( !exists $enum_list_hash{$value} ) {
            if ( $null_ok && ( !defined $value ) ) {
            }
            else {
                $invalid_count{$value} = $count;
            }
        }
        $index++;
    }

    if ( scalar( keys %invalid_count ) > 0 ) {

        $table_name_printed = _print_table_name_header( $enum_table_name, $table_name_printed, $html_table );

        if ( $Mode eq 'cmd' ) {
            print "**************************\n";
            print "$enum_field_name\n";
            print "**************************\n";
        }
    }
    elsif ($show_no_errs) {
        $table_name_printed = _print_table_name_header( $enum_table_name, $table_name_printed, $html_table );
        $html_table->Set_Row( [ _adjust_font( "$enum_field_name : no errors", 2, undef, undef ) ] );
    }

    my $defined = 0;    ## initialize error found

    # get primary field of this table
    my ($primary) = $dbc->Table_find( "DBTable,DBField", "Field_Name", "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$enum_table_name' AND Field_Options like '%Primary%'" );

    my $total_errors = 0;

    foreach my $key ( keys %invalid_count ) {
        $defined = 1;
        my $values_count = $invalid_count{$key};
        $total_errors += $values_count;

        #my @ids = $dbc->Table_find("$enum_table_name", "$primary", "where $enum_field_name = '$key'");

        if ( $values_count > 0 ) {

            $html_table->Set_Row( [ _adjust_font( "$enum_field_name: <b>$values_count</b> records have invalid value '$key'", 2, 'red', undef ) ], 'lightredbw' );
            $Report->set_Warning("$enum_field_name: $values_count records have invalid value \'$key\'") if $Report;

            #            if ( $Mode eq 'cmd' ) {#
            #                print "=== " . "$enum_field_name: $values_count records have invalid value \'$key\'\n";
            #            }
            last;
        }

    }

    return ( $total_errors, $table_name_printed, $enum_field_name, $enum_table_name );    #Returns number of errors were found (0 = not found)
}

#################################
sub _print_table_name_header {
#################################
    #
    #Used by foreign key checks to print table name headers.
    #
    my $fk_table_name      = shift;
    my $table_name_printed = shift;
    my $html_table         = shift;

    unless ($table_name_printed) {
        $html_table->Set_sub_header( '<B>' . $fk_table_name . '</B>' );
        if ( $Mode eq 'cmd' ) {
            print "\n********************************************************************************************\n";
            print "Table: $fk_table_name  TIME: " . &RGTools::RGIO::now() . "\n";
            print "--------------------------------------------------------------------------------------------\n";
        }
        $table_name_printed = 1;
    }

    return $table_name_printed;
}

#########################
sub _execute_cmd_str {
#########################
    #
    #This is the guts of the command string system. This function perform the
    #checking by executing the command string and returns the result in an array
    #of 2 elements: The count of the error records found, and a hash reference
    #containing all the error records found
    #
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $table_name   = $args{-table_name};
    my $field_name   = $args{-field_name};
    my $cmd_type     = $args{-cmd_type};
    my $cmd_str      = $args{-cmd_str};
    my $primary_keys = $args{-primary_keys};
    my $Report       = $args{-report};
    my @options      = Cast_List( -list => $args{-options}, -to => 'array' );    ###optional
    my $err_check_id = $args{-err_check_id};
    my $debug        = $args{-debug};

    my $count_only = grep /^count_only$/, @options;                              ###Whether we are only interested in retrieve the count.

    my $count = 0;
    my $i     = 0;

    my %errors;
    my $errstr;

    my $negation;

    #See if the command string is a negation...
    if ( $cmd_str =~ /^!(.*)/ ) {
        $negation = 1;
        $cmd_str  = $1;
    }
    else {
        $negation = 0;
    }

    my @fields   = split( /,/, $field_name );
    my @primarys = split( /,/, $primary_keys );

    # The command string is in a regular expression format....
    if ( $cmd_type eq 'RegExp' ) {
        my %full_list = $dbc->Table_retrieve( $table_name, [ $primary_keys, $field_name ] );

        my @problematic_ids;
        while ( defined $full_list{ $primarys[0] }[$i] ) {
            if ( ( !$negation && ( $full_list{$field_name}[$i] =~ /$cmd_str/ ) ) || ( $negation && !( $full_list{$field_name}[$i] =~ /$cmd_str/ ) ) ) {
                $count++;
                push( @problematic_ids, $full_list{ $primarys[0] }[$i] );
            }
            $i++;
        }
        if (@problematic_ids) {
            my $error_ids = join( ',', @problematic_ids );
            %errors = $dbc->Table_retrieve( $table_name, [ $primary_keys, $field_name ], "WHERE $primarys[0] in ($error_ids)" );
            if ($DBI::errstr) {
                $Report->set_Error("$DBI::errstr (Error_Check ID: $err_check_id)") if $Report;
            }
        }
        else {
            $Report->succeeded();
            $Report->set_Message("Passed $cmd_type check for: $cmd_str");
        }
    }
    #The command string is a where clause....
    elsif ( $cmd_type eq 'SQL' || $cmd_type eq 'FullSQL' ) {
        #build and execute the query.
        my $sql;
        my $sth;
        if ( $cmd_type eq 'SQL' ) {
            $sql = "select $primary_keys,$field_name from $table_name where $cmd_str order by $primary_keys";
            Message("$sql") if $debug;
            $sth = $dbc->dbh()->prepare(qq{$sql});
        }
        elsif ( $cmd_type eq 'FullSQL' ) {
            $sth = $dbc->dbh()->prepare(qq{$cmd_str});
        }
        $sth->execute();

        if ($DBI::errstr) {
            $Report->set_Error("$DBI::errstr (Error_Check ID: $err_check_id)") if $Report;
        }

        my $hashref;
        while ( $hashref = $sth->fetchrow_hashref() ) {
            unless ($count_only) {
                foreach my $key ( keys( %{$hashref} ) ) {
                    $errors{$key}[$count] = $hashref->{$key};
                }
            }
            $count++;
        }
        
        if (!$count) { 
            $Report->succeeded();
            $Report->set_Message("Passed $cmd_type check for: $cmd_str");
        }
    }

    #The command string is a snip of Perl code....
    elsif ( $cmd_type eq 'Perl' ) {
        ( $count, $errstr ) = eval($cmd_str);
        if (!$count) { 
            $Report->succeeded();
            $Report->set_Message("Passed $cmd_type check for: $cmd_str");
        }        
    }

    if ($count_only) {
        return $count;
    }
    else {
        return ( $count, \%errors, \$errstr );
    }
}

###############################
sub _combine_fields {
###############################
    #
    #Combines the primary key fields and other fields into a single array.
    #
    my $primary_keys = shift;
    my $field_name   = shift;

    my @fields;

    foreach my $field ( split( /,/, $primary_keys ) ) {    #First take care of the primary keys.
        push( @fields, $field );
    }

    foreach my $field ( split( /,/, $field_name ) ) {      #Now take care of the query fields
        push( @fields, $field );
    }

    return @fields;
}

#############################
sub _adjust_font {
#############################
    #
    #Adjust the font face, size and color to be displayed in the email notification
    #
    my $msg   = shift;
    my $size  = shift;    #size to be displayed in the email
    my $color = shift;    #color to be displayed in the email
    my $face  = shift;    #font face to be displayed in the email

    my $html;
    if ( $Mode eq 'web' ) {
        $html = $msg;     #No adjustments.
    }
    elsif ( $Mode eq 'cmd' ) {
        $html = $msg;
        if ( $face =~ /bold/i ) {
            $html = "<b>$html</b>";
        }
        if ( $face =~ /italics/i ) {
            $html = "<i>$html</i>";
        }
        if ( $face =~ /underline/i ) {
            $html = "<u>$html</u>";
        }
        $html = "<font size='$size' color='$color'>$html</font>";
    }

    return $html;
}

# Check Mandatory fields in tables that are NULL or blank
#
# Return: List of primary ID's
################################
sub mandatory_field_check {
################################
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $table = $args{-table};    ## Table Name
    my $field = $args{-field};    ## Field Name
    my @primary_ids;

    ## Check if the field is mandatory
    my ($mandatory_field_info) = $dbc->Table_find( 'DBTable,DBField', 'Field_Name,Field_Type', "WHERE FK_DBTable__ID = DBTable_ID and DBTable_Name = '$table' and Field_Options like '%mandatory%' and Field_Name = '$field'" );
    my ( $mandatory_field, $field_type ) = split ',', $mandatory_field_info;
    ## Now query the database for any records that have NULL or blank value for this mandatory field
    if ($mandatory_field) {
        ## get the primary fiele for the table
        my $primary = join ',', &get_field_info( $dbc, $table, undef, 'Primary' );
        my $mandatory_condition = '';
        $mandatory_condition = "WHERE $mandatory_field IS NULL OR $mandatory_field = ''";
        if ( $field_type =~ /int/i ) {
            $mandatory_condition .= " OR $mandatory_field = 0";
        }
        @primary_ids = $dbc->Table_find( "$table", "$primary", $mandatory_condition );
    }
    return \@primary_ids;
}

##########################
sub perform_qty_units_checks {
##########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $tables       = $args{-tables};
    my $show_no_errs = $args{-show_no_errs};
    my $gen_list     = $args{-gen_list};
    my $Report       = $args{-report};
    my $FILE         = $args{-file};
    my $DAILY_LOG    = $args{-daily_log};
    my $link;

    if ( $Mode eq 'web' ) {
        $link = $thislink;
    }
    elsif ( $Mode eq 'cmd' ) {
        $link = $Home . "?Username=viewer&Pwd=viewer&Database=$dbase&Task=task4";
    }

    my $errors_found = 0;    #indicate whether errors were found.

    my @all_tables = Cast_List( -list => $tables, -to => 'array' );

    if ( param("Check All") ) {
        @all_tables = show_tables($dbc);
    }

    my $table_name_printed = 0;
    my $html_table;
    my $date = &today();
    $html_table = HTML_Table->new();
    $html_table->Set_Title( _adjust_font( "Results from Quantity Units checks ($date)", undef, undef, 'bold,underline' ) );
    $html_table->Set_Header_Colour('white');
    $html_table->Set_Class('Small');
    $html_table->Toggle_Colour('off');

    my $dbase = $dbc->{dbase};

    if ( $Mode eq 'cmd' ) {
        print "\n********************************************************************************************\n";
        print "Results from quantity units checks: (Database = $dbase)\n";
        print "********************************************************************************************\n";
    }

    my $total_errors = 0;

    my $condition = "where Field_Name like '\%_Units'";

    my @results = $dbc->Table_find( "DBField", "Field_Table,Field_name", $condition, -debug => 0 );
    $table_name_printed = 0;
    my $table_count = 0;
    my $field_count = 0;
    foreach my $result (@results) {    #1
        $table_name_printed = 0;

        my @fields          = split /,/, $result;
        my $unit_field_name = $fields[1];
        my $table_name      = $fields[0];
        my $qty_field_name  = $fields[1];
        if ( $table_name eq '' ) {
            print "DBField record for Field_name = $unit_field_name has an empty table_name field\n";
            next;
        }

        if ( $qty_field_name =~ /(.*)_Unit/ ) {

            $qty_field_name = $1;    #substr("_Unit",$-[0]);
        }
        $condition = "where Field_Table = '$table_name' and Field_Name = '$qty_field_name'";
        my ($count) = $dbc->Table_find( "DBField", "DBField_ID", $condition, -debug => 0 );
        if ( $count != 0 ) {         #2
                                     # if there's another field w/ the name qty_field_name in the same table

            $condition = " where $qty_field_name <> 0 and ($unit_field_name = '' or $unit_field_name is null)";
            my ($entry_count) = $dbc->Table_find( $table_name, "count(*)", $condition, -debug => 0 );

            # No Grows
            unless ( scalar($entry_count) == 0 ) {
                $field_count++;
                $total_errors = $total_errors + $entry_count;
                $table_name_printed = _print_table_name_header( $table_name, $table_name_printed, $html_table );
                my $message = "$qty_field_name: $entry_count record(s) have a quantity value but no units";
                $html_table->Set_Row( [ _adjust_font( $message, 2, 'red', undef ) ], 'lightyellow' );
                $Report->set_Warning($message);

                #   print "Table $table_name - $table_name, $unit_field_name is empty while $qty_field_name is not. ($entry_count) \n";
            }
        }    #2
        if ($table_name_printed) {
            $table_count++;

            $html_table->Set_Row( [''], 'vvvlightgrey' );    #Make a blank row to separate the database tables for easier viewing.
        }

    }    #1

    my $scope = $dbc->config('host') . '.' . $dbc->config('dbase');

    if ( $Mode eq 'web' ) {
        $html_table->Printout();
    }
    else {
        $html_table->Printout( $Configs{URL_temp_dir} . $qty_units_check_html );
        my $body = "<P>" . &Link_To( $url_root . $qty_units_check_html, 'Link to Cron Summary in alDente' );
        my $subject = "DBIntegrity: Quantity Unit Check Report ($scope : $table_count tables, $field_count fields, $total_errors errors found)";

        if ($total_errors) {
            alDente::Notification::Email_Notification( -to_address => $to_email, -from_address => $FROM_EMAIL, -subject => $subject, -body => $body, -content_type => "html" );
        }
    }

    if ($Report) {
        $Report->set_Message( "Tested quantity value checks: " . $table_count . " tables, " . $field_count . " fields, " . $total_errors . " errors found" );
    }

    if ($FILE) {

        print $FILE "<p ></p><a href=\"../tmp/DBIntegrity_qty_units_check.html\">DBIntegrity Quantity Unit Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";

    }

    if ($DAILY_LOG) {
        print $DAILY_LOG "<p ></p><a href=\"../tmp/DBIntegrity_qty_units_check.html\">DBIntegrity Quantity Unit Check Report ($table_count tables, $field_count fields, $total_errors errors found)</a></p>";
    }

    return ( $errors_found, $html_table );
}

########################
sub print_enum_tables {
########################
    #
    #Prints out a list of tables as options to perform foreign key checks on.
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sth;
    my @ary;

    my $dbase  = $dbc->{dbase};
    my @tables = show_tables($dbc);

    print "<H1 align=center><Font size=5> $dbase Database </Font></H1>\n";

    #print checkbox(-name=>'Include_Nulls',label=>'Include null, blank and zero values during foreign key checks.',-checked=>'0') . br;
    print checkbox( -name => 'Show_No_Errs', label => 'Display results with no errors as well.', -checked => '1' ) . br;
    print checkbox( -name => 'Gen_List', label => 'Generate a comma-delimited list of invalid enum field primary keys.', -checked => '0' ) . br . br;
    print submit( -name => 'Perform Check', -value => '1', -label => 'Perform Check', -style => 'background-color:yellow' );

    my $dbase_table = HTML_Table->new();
    $dbase_table->Set_Headers( [ "Options", "Tables" ] );
    $dbase_table->Set_Border(1);
    $dbase_table->Set_Alignment("center");

    print checkbox( -name => 'Toggle', -onclick => "ToggleCheckBoxes(document.Check_DBase_Integrity,'Select_All')" );

    foreach my $table (@tables) {
        $dbase_table->Set_Row( [ checkbox( -name => 'Table', -value => $table, -label => "" ), $table ] );
    }

    $dbase_table->Set_Class('small');
    $dbase_table->Printout();
}

########################
sub object_attribute_table_check {
########################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $Report = $args{-report};

    my @tables = $dbc->Table_find( 'DBTable', 'DBTable_Name', "where DBTable_Name like '%_Attribute'" );
    my $object_name;

    foreach my $table (@tables) {

        if ( $table =~ /^(.+)_Attribute$/ ) {
            $object_name = $1;
        }
        my ($foreign_key_name) = $dbc->foreign_key( -table => $object_name );

        my @check = $dbc->Table_find( "Attribute,$table", "Attribute_ID,Attribute_Name,Attribute_Class,$foreign_key_name", "where FK_Attribute__ID = Attribute_ID AND Attribute_Class <> '$object_name'" );

        foreach my $check (@check) {
            my ( $att_id, $att_name, $att_class, $object_id ) = split ',', $check;
            $Report->set_Error("$table has a record with attribute: $att_name, class: $att_class, and ${foreign_key_name}: $object_id!");

        }

        #Check time format
        my $table_id = "$table" . "_ID";
        my @check_date = $dbc->Table_find( "Attribute,$table", "Attribute_Value,$table_id", "where FK_Attribute__ID = Attribute_ID AND Attribute_Type IN ('Date','DateTime')" );

        for my $data (@check_date) {
            my ( $date, $id ) = split( ",", $data );
            my $new_date = convert_date( -date => $date, -format => 'SQL', -invalid => 1 );
            if ( $new_date eq 'invalid' ) { $Report->set_Error("$table has a record with invalid date/time format: $table_id: $id, Attribute_Value: $date"); }

            #elsif ( $new_date ne $date ) { $dbc->Table_update( $table, "Attribute_Value", "$new_date", "WHERE $table_id = $id", -autoquote => 1 ); }	## moved to cleanup_DB.pl on 2012-02-22
        }

    }

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

$Id: DBIntegrity.pm,v 1.22 2004/12/16 18:27:00 mariol Exp $ (Release: $Name:  $)

=cut

return 1;
