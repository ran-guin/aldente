package Process_Monitor::Manager;

################################################################################
#
# This module builds an HTML table summarising the final entries in logfiles created from objects in the RGTools::Process_Manager Module.
#
#  <SYNOPSIS>
#
# 1. Construct object with attributes of directory for all cron jobs and list of with all script names of cron jobs to be summarised and empty reports hash
#    my Manager = Process_Monitor::Manager->new(cron_dir =>'/cronjob_scripts/',
#					       cron_list => {'sys_monitor.pl', 'upgrade_DB.pl', ...});
#
#    $self->{reports}; #hash of reports
#
#
#
# 2. create $self->{reports}, the hash to store: (scriptname => [array of Process_Monitor objects])
#
# $self->generate_reports{
# #loop through $self->{cron_list}, calling get_report on each script name
#
# _get_script_reports(-script, -include){
# Foreach name:
#    i. find the logfile,
#    ii. count number of entries while obtaining the last entry in the logfile
#    iii. convert it to a Process_Monitor object
#    iv. add to @script_reports (array of recent logs determined by include)
# }
#
#  associate @script_reports with current key $script
# }
#
#
# 4. Use $self->{reports} to write the HTML table using create_HTML()
#
#
##  </SYNOPSIS>
#
#       OLD SYNOPSIS
#       my $base_dir = '<path to your cron log dir>';
#       my $manager = RGTools::Report::Manager->new(-base_dir=>$base_dir);
#
#       $manager->generate_summary(['upgrade_DB','hub_check','restore']);
#
#        is_deeply($self->{records}, \%test_reports, 'created hash containing reports successfully');
################################################################################
use strict;
use Data::Dumper;
use YAML;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use RGTools::HTML_Table;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

use SDB::CustomSettings;
use SDB::HTML;

use LampLite::Bootstrap;

use CGI qw(:standard);

use vars qw(%Configs);

my $BS = new Bootstrap();
###################
### Constructor ###
##################

### Customize ###
my $DEFAULT_EMAIL   = 'aldente@bcgsc.ca';
my $tmp_dir         = "/tmp/";
my $output_log_dir  = "dynamic/logs";
my $URL_details_dir = "dynamic/tmp";
my $URL_temp_dir    = $Configs{URL_temp_dir};
#################

##########
sub new {
##########

    my $this = shift;
    my %args = &filter_input( \@_, -args => 'cron_list, cron_dir, include', -mandatory => 'cron_list' );

    ### Initialization
    my $self = {};
    my $class = ref($this) || $this;
    bless $self, $class;

    ### Arguments
    $self->{cron_list} = $args{-cron_list} || {};
    $self->{schedule}  = $args{-schedule}  || {};
    $self->{include}   = $args{-include}   || 1;
    $self->{offset}    = $args{-offset}    || '0d';    ## ************** defaults to today, should be set to run as late as possible (eg. 23:50)
    $self->{report_generated} = date_time();
    $self->{notify}           = $args{-notify} || [$DEFAULT_EMAIL];
    $self->{cron_dir}         = $args{-cron_dir} || Process_Monitor::cron_dir( $self->{offset} );
    $self->{stats_dir}        = $args{-stats_dir} || Process_Monitor::stats_dir();
    $self->{log_dir}          = $args{-log_dir} || Process_Monitor::log_dir();
    $self->{dow}              = _day_of_week( $self->{offset} );                                    ## day of week
    $self->{configs}          = $args{-configs} || {};

    $URL_temp_dir ||= $self->{configs}->{URL_temp_dir};

    #  die();
    ### Hashes of reports and missing report
    $self->{reports} = {};

    $self->{stats_files} = {};

    # $self->{stats_file} = "$self->{stats_dir}/" . "$self->{script}" . '_stats.log';

    $self->{missing_reports} = {};

    ### Atrributes
    $self->{counters} = {};

    return $self;
}

#########################
sub generate_reports {
#########################
    my $self  = shift;
    my $debug = shift;

    try_system_command("mkdir -m 775 $self->{cron_dir}");    #unless (-e ($self->{cron_dir}));
    print "Inspecting " . int( keys %{ $self->{cron_list} } ) . " log files in $self->{cron_dir}\n\n";

    my %list = %{ $self->{cron_list} };
    my %schedule = %{ $self->{schedule} } if $self->{schedule};

    #my @schedule_list = keys %schdule;

    foreach my $script ( keys %list ) {

        #        my $formatted_name = printf("%30s",$script);
        my @variations = Cast_List( -list => $list{$script}, -to => 'array' );
        if ( $variations[0] == 1 ) { @variations = ($script); }
        else {
            foreach my $variation (@variations) {
                if   ($variation) { $variation = "$script.$variation" }
                else              { $variation = $script }
            }
        }
        print "Variations: " . join "\n", @variations . "\n";

        foreach my $variation (@variations) {
            chomp $variation;

            if ( $schedule{$variation} ) {
                my @list = @{ $schedule{$variation} };
                my $dow  = $self->{dow};
                if ( !grep /^$dow$/, @list ) {next}
            }

            my $logfile = $variation;

            if ( -e "$self->{cron_dir}/$logfile" . '.log' ) {
                $self->{reports}{$logfile} = $self->_get_script_reports($logfile);
                my @details = split "\n", Dumper( $self->{reports}{$logfile} );
                my @warnings = grep /^warnings:\b/, @details;
                my @errors   = grep /^errors:\b/,   @details;
                print "\t\t" if ( @warnings || @errors );

                if ( $debug && ( int( keys %list ) == 1 ) ) {
                    print "** Warnings ** \n" . join "\n", @warnings if @warnings;
                    print "** Errors ** \n" . join "\n",   @errors   if @errors;
                }
                else {
                    print "** Warnings ** " if @warnings;
                    print "** Errors **"    if @errors;
                }

                print Dumper( \@errors ) if @errors;
                print "\n";
            }
            else {
                $self->{missing_reports}{$variation} = ["$logfile"];
                print "\t\t$self->{cron_dir}/$logfile.log NOT found.\n";
            }
        }
    }
    return 1;
}

################################
#
# Input: scriptname
#
# Output: array Process_Monitor objects for last entry in logfile
#
################################

###################
sub _get_script_reports {
###################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'logfile', -mandatory => 'logfile' );

    my $logfile = $args{-logfile};
    $logfile .= '.log';

    print "log file: $self->{cron_dir}/$logfile\n";
    open my $LOG, "$self->{cron_dir}/$logfile" or return undef;    # no log file found, shouldn't happen as should be in $self->{missing_reports}

    my $check_line;
    my $log_instance;
    my $yaml_instance;
    my @yaml_instances = [];
    $self->{counters}{$logfile} = 0;

    while ( $check_line = <$LOG> ) {
        if ( $check_line =~ /^Repeat Message/ ) {
            $self->{counters}{$logfile}++;
            next;
        }
        elsif ( $check_line =~ /(\*)START(\*)/ ) {
            $log_instance = '';
            next;
        }
        elsif ( $check_line =~ /(\*)END(\*)/ ) {
            $self->{counters}{$logfile}++;
            ## continue below ##
        }
        else {
            $log_instance .= $check_line;
            next;
        }

        if ( scalar(@yaml_instances) == $self->{include} ) {
            shift @yaml_instances;
        }

        $yaml_instance = YAML::thaw($log_instance);

        push @yaml_instances, $yaml_instance;

        $log_instance = "";
    }
    close $LOG;

    return \@yaml_instances;
}

##############################
# Create HTML table which summarises information from logfiles, 1 summary line based on most recent report per script unless user determines otherwise
##############################

###################
sub create_HTML {
###################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'type,dir,note' );

    my $type     = $args{-type} || 'html';
    my $copy_dir = $args{-dir};
    my $note     = $args{-note};

    my @scripts         = keys %{ $self->{reports} };
    my @missing_scripts = keys %{ $self->{missing_reports} };
    my @missing_logs;
    my @headers = ( 'DATE', 'TEST', 'TOTAL RUNS', 'STATUS', 'RUN TIME', "SUCCESSFUL\nTESTS", 'MESSAGES', 'WARNINGS', 'ERRORS', 'DETAILS', 'ERROR LOG', "REPORT\nPAGE", "ERROR\nHISTORY", "WARNING\nHISTORY" );

    my $HTML = $note;

    $HTML .= "<BR>Generated: " . &convert_date( date_time(), 'Simple' );

    #    $HTML .= '<BR>by: ' . $0;
    $HTML .= hr();

    my $output;

    if ( @scripts || @missing_scripts ) {

        # set up the HTML table for Cron job summary
        my $attentions = HTML_Table->new( -width => 600 );
        $attentions->Set_Title("CRON JOB SUMMARY WARNINGS");
        $attentions->Set_Headers( \@headers, $Settings{HIGHLIGHT_CLASS} );

        my $err_table = HTML_Table->new( -width => 600 );
        $err_table->Set_Title("CRON JOB SUMMARY PROBLEMS");
        $err_table->Set_Headers( \@headers, $Settings{HIGHLIGHT_CLASS} );

        my $lst = HTML_Table->new( -width => 600 );
        $lst->Set_Title("CRON JOB SUMMARY PROBLEMS");
        $lst->Set_Headers( \@headers, $Settings{HIGHLIGHT_CLASS} );

        my $missing_lst = HTML_Table->new( -width => 200 );
        $missing_lst->Set_Title("MISSING CRON JOB LOGFILES");
        $missing_lst->Set_Headers( [ 'DATE', 'TEST', 'STATUS', 'STDOUT', 'STDERR', 'Cron Job(s)' ], $Settings{HIGHLIGHT_CLASS} );

        my ( $date, $test, $total_runs, $status, $runtime, $tested, $messages, $warnings, $errors, $details, $error_log, $report_page );

        my %script_numbers;

        foreach my $script ( sort @scripts ) {
            my @script_reports = @{ $self->{reports}{$script} };
            foreach my $script_report (@script_reports) {
                if ( ref $script_report eq 'ARRAY' ) {
                    push( @missing_logs, $script );
                    next;
                }
                $script_numbers{$script}{messages} = scalar( @{ $script_report->{messages} } );
                $script_numbers{$script}{warnings} = 1 if scalar( @{ $script_report->{warnings} } );
                $script_numbers{$script}{errors}   = 1 if scalar( @{ $script_report->{errors} } );
            }
        }
        my $first_ok = 1;
        foreach my $script ( sort { $script_numbers{$b}{errors} <=> $script_numbers{$a}{errors} || $script_numbers{$b}{warnings} <=> $script_numbers{$a}{warnings} || $a cmp $b } keys %script_numbers ) {

            if ( $script_numbers{$script}{errors} == 0 && $script_numbers{$script}{warnings} == 0 && $first_ok ) {
                $first_ok = 0;

                if (@missing_scripts) {

                    # set up the HTML table for missing logfiles

                    foreach my $missing_script (@missing_scripts) {

                        my @missing_script_reports = @{ $self->{missing_reports}{$missing_script} };

                        foreach my $missing_script_report (@missing_script_reports) {
                            my ( $date, $status );

                            $date = &date_time();

                            #set $test with script filename and remove .pl
                            $test = "$missing_script_report";
                            $test =~ s/\.pl//g;

                            $status = "MISSING";
                            $status = "<FONT size=-1 color=red><BLINK><B>$status</B></FONT>";
                            $status = Show_Tool_Tip( $status, "could not find $missing_script_report" );

                            my $logfile = tmp_copy( "$self->{log_dir}/$missing_script_report.log", "$missing_script_report.stdout", 'stdout', -alt => '(no stdout)', $copy_dir );    ## Link_To("$self->{log_dir}/$missing_script_report.log","std log");
                            my $errfile = tmp_copy( "$self->{log_dir}/$missing_script_report.err", "$missing_script_report.stderr", "stderr", -alt => '(no stderr)', $copy_dir );

                            ## Temporary ... display actual cron job using this script ##
                            my $cron_log_dir = "/home/aldente/private/crontabs/";
                            my $cron         = `grep '$missing_script_report' $cron_log_dir/*.cron`;
                            
                            my ($activated, $deactivated) = (0,0);
                            my @crons = split "\n", $cron;
                            foreach my $cronjob (@crons) {
                                if ($cronjob =~ /^\s*\#/) {
                                    $deactivated++;
                                    ## turned off ##
                                }
                                else {
                                    $activated++;
                                }
                            }
                            
                            $cron =~ s/$cron_log_dir\///;
                            $cron =~ s/\n/<hr>/g;
                            $cron = create_tree( -tree => { 'Cron Job(s)' => $cron } );
                            
                            if (!$activated) {
                                $status = "TURNED OFF";
                            }
                            $missing_lst->Set_Row( [ $date, $test, $status, $logfile, $errfile, $cron ] );
                            $missing_lst->Set_Alignment( 'center', 3 );
                            $missing_lst->Set_Alignment( 'center', 4 );
                            $missing_lst->Set_Alignment( 'center', 5 );
                        }
                    }
                }

                #     $HTML .= $lst->Printout(0);
                #        $HTML .= "<P><P><BR>";

                if (@missing_logs) {

                    # set up the HTML table for empty logfiles
                    my $empty_lst = HTML_Table->new( -width => 200 );
                    $empty_lst->Set_Title("EMPTY CRON JOB LOGFILES");
                    $empty_lst->Set_Headers( [ 'DATE', 'TEST', 'STATUS' ], $Settings{HIGHLIGHT_CLASS} );

                    foreach my $missing_log (@missing_logs) {

                        my ( $date, $status );

                        $date = &date_time();

                        #set $test with script filename and remove .pl
                        #$test = "$missing_script_report";
                        #$test =~ s/\.pl//g;

                        $status = "Empty";
                        $status = "<FONT size=-1 color=red><BLINK><B>$status</B></FONT>";

                        $empty_lst->Set_Row( [ $date, $missing_log, $status ] );
                        $empty_lst->Set_Alignment( 'center', 3 );
                        $empty_lst->Set_Alignment( 'center', 4 );
                        $empty_lst->Set_Alignment( 'center', 5 );
                    }
                    $HTML .= $empty_lst->Printout(0);
                }

                $lst = HTML_Table->new( -width => 600 );
                $lst->Set_Title("CRON JOB SUMMARY OK");
                $lst->Set_Headers( \@headers, $Settings{HIGHLIGHT_CLASS} );

            }

            my @script_reports = @{ $self->{reports}{$script} };
            foreach my $script_report (@script_reports) {
                my $var_type = ref($script_report);
                if ( $var_type eq 'ARRAY' ) {
                    unless (@$script_report) {
                            err ("$script has an empty report file\n");
                        push( @missing_logs, $script );
                        next;
                    }
                }
                $error_log   = "N/A";
                $report_page = "N/A";
                $date        = $script_report->{_end_time};

                #set $test with script filename and remove .pl
                $test = $script_report->{script};
                $test =~ s/\.pl//g;
                $test .= " - $script_report->{variation}" if ( $script_report->{variation} );

                ($runtime) = split ' ', $script_report->{_execution_time};
                $runtime .= "<BR> wallclock <BR> secs <BR>";

                $total_runs = $self->{counters}{$script};

                $status = 'OK';
                $tested = $script_report->{succeeded};

                $messages = scalar( @{ $script_report->{messages} } );

                if ( exists $script_report->{messages}[0] ) {
                    my $messages_string = Cast_List( -list => $script_report->{messages}, -to => 'string', -delimiter => "<BR>" );
                    $messages = Show_Tool_Tip( scalar( @{ $script_report->{messages} } ), $messages_string, -placement => 'right' );
                }

                $warnings = scalar( @{ $script_report->{warnings} } );
                if ( exists $script_report->{warnings}[0] ) {
                    my $warnings_string = Cast_List( -list => $script_report->{warnings}, -to => 'string', -delimiter => "<BR>" );
                    $warnings = Show_Tool_Tip( scalar( @{ $script_report->{warnings} } ), $warnings_string, -placement => 'right' );
                }

                $errors = scalar( @{ $script_report->{errors} } );
                if ( exists $script_report->{errors}[0] ) {
                    my $errors_string = Cast_List( -list => $script_report->{errors}, -to => 'string', -delimiter => "<BR>" );
                    $errors = Show_Tool_Tip( scalar( @{ $script_report->{errors} } ), $errors_string, -placement => 'right' );
                }

                $details = Cast_List( -list => $script_report->{details}, -to => 'String' );
                my $error_history_graph;
                my $warning_history_graph;
                my $fb;

                ## generate error file if it exists ##
                my $error_graph_file_name = Process_Monitor::error_graph( -title => $script_report->{script}, -subtitle => $script_report->{variation}, -type => 'Errors', -format => 'url' );
                if ($error_graph_file_name) {
                    $error_history_graph = create_tree( -tree => { 'Trend' => "<Img Src = $error_graph_file_name alt='No Error Plot'>" } );
                }
                else { $error_history_graph = 'no plot' }

                my $warning_graph_file_name = Process_Monitor::error_graph( -title => $script_report->{script}, -subtitle => $script_report->{variation}, -type => 'Warnings', -format => 'url' );
                if ($warning_graph_file_name) {
                    $warning_history_graph = create_tree( -tree => { 'Trend' => "<Img Src =$warning_graph_file_name alt='No Warning Plot'>" } );
                }
                else { $warning_history_graph = 'no plot' }

                $date = "<FONT size=-2>$date</FONT>";

                #set status here based on errors/warnings
                if ( exists $script_report->{warnings}[0] ) { $status = 'ATTENTION'; }

                if ( exists $script_report->{errors}[0] ) { $status = 'PROBLEM'; }

                if ( $script_report->{success} == 0 ) { $status = 'INCOMPLETE'; }

                my $log_path   = $self->{cron_dir};
                my $logfile    = $script . '.log';
                my $error_file = $script . '.err';

                #Call_Stack;
                #print "we are in create_HTML of manager, with log path: $self->{cron_dir}, logfile: $logfile, err file: $error_file\n";

                $details = tmp_copy( "$log_path/$logfile", "$logfile", 'details', $copy_dir );
                $details .= '<br>' . tmp_copy( "$self->{log_dir}/$script.log", "$script.stdout", 'stdout', $copy_dir );
                $details .= '<br>' . tmp_copy( "$self->{log_dir}/$script.err", "$script.stderr", 'stderr', $copy_dir );

                if ( $status eq 'INCOMPLETE' ) {
                    $error_log = tmp_copy( "$log_path/$error_file", "$error_file", 'error_log', $copy_dir );

                }
                else {
                }

                # where do we get the url from

                $report_page = "<a href = $script_report->{url}>report page</a>" unless ( $script_report->{url} eq "" );

                if ($errors) {
                    $status = "<FONT size=-1 color=red><BLINK><B>$status</B></BLINK></FONT>";
                    $err_table->Set_Row( [ $date, $test, $total_runs, $status, $runtime, $tested, $messages, $warnings, $errors, $details, $error_log, $report_page, $error_history_graph, $warning_history_graph ] );
                    $err_table->Set_Alignment( 'center', 3 );
                    $err_table->Set_Alignment( 'center', 4 );
                    $err_table->Set_Alignment( 'center', 5 );
                    $err_table->Set_Alignment( 'center', 6 );
                    $err_table->Set_Alignment( 'center', 7 );
                    $err_table->Set_Alignment( 'center', 8 );
                    $err_table->Set_Alignment( 'center', 9 );
                    $err_table->Set_Alignment( 'center', 10 );
                    $err_table->Set_Alignment( 'center', 11 );
                    $err_table->Set_Alignment( 'center', 12 );

                }
                elsif ( $status eq 'OK' ) {
                    $status = "<FONT size=-1 color=darkgreen><B>$status</B></FONT>";
                    $lst->Set_Row( [ $date, $test, $total_runs, $status, $runtime, $tested, $messages, $warnings, $errors, $details, $error_log, $report_page, $error_history_graph, $warning_history_graph ] );
                    $lst->Set_Alignment( 'center', 3 );
                    $lst->Set_Alignment( 'center', 4 );
                    $lst->Set_Alignment( 'center', 5 );
                    $lst->Set_Alignment( 'center', 6 );
                    $lst->Set_Alignment( 'center', 7 );
                    $lst->Set_Alignment( 'center', 8 );
                    $lst->Set_Alignment( 'center', 9 );
                    $lst->Set_Alignment( 'center', 10 );
                    $lst->Set_Alignment( 'center', 11 );
                    $lst->Set_Alignment( 'center', 12 );

                }
                elsif ( $status eq 'ATTENTION' ) {
                    $status = "<FONT size=-1 color=orangered><B>$status</B></FONT>";
                    $attentions->Set_Row( [ $date, $test, $total_runs, $status, $runtime, $tested, $messages, $warnings, $errors, $details, $error_log, $report_page, $error_history_graph, $warning_history_graph ] );
                    $attentions->Set_Alignment( 'center', 3 );
                    $attentions->Set_Alignment( 'center', 4 );
                    $attentions->Set_Alignment( 'center', 5 );
                    $attentions->Set_Alignment( 'center', 6 );
                    $attentions->Set_Alignment( 'center', 7 );
                    $attentions->Set_Alignment( 'center', 8 );
                    $attentions->Set_Alignment( 'center', 9 );
                    $attentions->Set_Alignment( 'center', 10 );
                    $attentions->Set_Alignment( 'center', 11 );
                    $attentions->Set_Alignment( 'center', 12 );
                }
                else {
                    $status = "<FONT size=-1 color=red><BLINK><B>$status</B></BLINK></FONT>";
                    $lst->Set_Row( [ $date, $test, $total_runs, $status, $runtime, $tested, $messages, $warnings, $errors, $details, $error_log, $report_page, $error_history_graph, $warning_history_graph ] );
                    $lst->Set_Alignment( 'center', 3 );
                    $lst->Set_Alignment( 'center', 4 );
                    $lst->Set_Alignment( 'center', 5 );
                    $lst->Set_Alignment( 'center', 6 );
                    $lst->Set_Alignment( 'center', 7 );
                    $lst->Set_Alignment( 'center', 8 );
                    $lst->Set_Alignment( 'center', 9 );
                    $lst->Set_Alignment( 'center', 10 );
                    $lst->Set_Alignment( 'center', 11 );
                    $lst->Set_Alignment( 'center', 12 );
                }

            }
        }

        my $link;
        $HTML .= "<P><P>";
        $HTML .= $missing_lst->Printout(0) . '<br>' if (@missing_scripts);
               
        if ( $err_table->rows() ) {
            $link = $self->print_out( -table => $err_table, -target => "Cron_Summary_Problems_Print." . timestamp() . ".html", -label => "Print" );
            $HTML .= "<P>$link<br>" . $err_table->Printout(0) . '<br>';
        }
        else { $HTML .= subsection_heading('No Cron Errors Found') }

        if ( $attentions->rows() ) {
            $link = $self->print_out( -table => $attentions, -target => "Cron_Summary_Warnings_Print." . timestamp() . ".html", -label => "Print" );
            $HTML .= "<P>$link<br>" . $attentions->Printout(0) . '<br>';
        }
        else { $HTML .= subsection_heading('No Cron Warnings Found') }

        if ( $lst->rows() ) {
            $link = $self->print_out( -table => $lst, -target => "Cron_Summary_OK_Print." . timestamp() . ".html", -label => "Print" );
            $HTML .= "<P>$link<br>" . $lst->Printout(0) . '<br>';
        }
        else { $HTML .= subsection_heading('No Problem-free tests found') }

        return $HTML;
    }
    return 0;
}

#
# - print out table content to a file in the temporary URL directory
# - generate link to temporary file
#
# <snip>
#  print_out($table,$target_filename,$label);
#
################
sub print_out {
################
    my %args   = filter_input( \@_, -args => 'table,target,label' );
    my $table  = $args{-table};
    my $target = $args{-target};
    my $label  = $args{-label} || $target;

    try_system_command("rm $URL_temp_dir/$target");
    $table->Printout("$URL_temp_dir/$target");
    try_system_command("chmod 664 $URL_temp_dir/$target");
    my $ref = "<a href='$URL_domain/$URL_dir_name/dynamic/tmp/$target'>$label</a>";
    return $ref;
}

#
# - copy file from filesystem to temporary URL directory
# - generate link to temporary file
#
# <snip>
#  tmp_copy($original_file,$target_filename,$label);
#
################
sub tmp_copy {
################
    my %args     = filter_input( \@_, -args => 'file,target,label,copy_dir' );
    my $file     = $args{-file};
    my $target   = $args{-target};
    my $label    = $args{-label} || $target;
    my $alt      = $args{-alt};
    my $copy_dir = $args{-copy_dir} || $URL_temp_dir;

    my $ref;
    if ( -f "$file" ) {
        try_system_command("cp $file $copy_dir/$target");
        try_system_command("chmod 664 $copy_dir/$target");
        my $content = `head $copy_dir/$target`;
        if ($content) {
            ## something in the file... ##
            if   ( $copy_dir eq $URL_temp_dir ) { $ref .= "<a href='$URL_domain/$URL_dir_name/dynamic/tmp/$target'>$label</a>"; }
            else                                { $ref .= "<a href='$target'>$label</a>"; }
        }
        else {
            ## nothing in the file ##
            $ref .= "($label empty)";
        }
    }
    elsif ($alt) { $ref .= Show_Tool_Tip( $alt, "$file" ) }

    return $ref;
}

=pod
#######################
sub dump_results {
#######################
    my $self = shift;

    my @scripts =  keys %{$self->{reports}};    
   
    my $headers = ("DATE\t\t\t TEST\t TOTAL RUNS\t STATUS\t RUN TIME\t SUCCESSFUL\nTESTS\t MES\t WARN\t ERR\t DETAILS\t\n\n");
    my $output .= $headers;
 
    if (@scripts) {
	my ($date,$test, $total_runs, $status, $runtime, $tested,$messages,$warnings,$errors,$details);

	foreach my $script (@scripts) {
	    my @script_reports = @{$self->{reports}{$script} };

	    foreach my $script_report (@script_reports) {

		$date = $script_report->{_end_time};

		#set $test with script filename and remove .pl
		$test = $script_report->{script};
	        $test =~ s/\.pl//g;
		
		($runtime) = split ' ', $script_report->{_execution_time};

		$total_runs = $self->{counters}{$script};
		
		$status = 'OK';
		$tested = $script_report->{succeeded};
		
		$messages = scalar(@{$script_report->{messages}});

		my ($verbose_messages, $verbose_warnings, $verbose_errors);
		
		if (exists $script_report->{messages}[0]) {
		    $verbose_messages = Cast_List(-list=>$script_report->{messages}, -to=>'string',-delimiter=>"<LI>");

		}

		$warnings = scalar(@{$script_report->{warnings}});
		if (exists $script_report->{warnings}[0]) {
		    $verbose_warnings = Cast_List(-list=>$script_report->{warnings}, -to=>'string',-delimiter=>"<LI>");

		}

		$errors = scalar(@{$script_report->{errors}});
		if (exists $script_report->{errors}[0]) {
		    $verbose_errors = Cast_List(-list=>$script_report->{errors}, -to=>'string',-delimiter=>"<LI>");
		}

		$details = Cast_List(-list=>$script_report->{details}, -to=>'String');
		
		my $log_path = $self->{cron_dir};  ## Process_Monitor log file		
		my $logfile = "$log_path/$script.log";
		$details = tmp_copy($log_path$logfile,"$script.log",'Details');
		
		my $stdout = "$self->{log_dir}/$script.log";
		$details .= '<br>' . tmp_copy($stdout,"$script.stdout",'stdout');

		my $stderr = "$self->{log_dir}/$script.err";		
		$details .= '<br>' . tmp_copy($stderr,"$script.stderr",'stderr');


		#set status here based on errors/warnings

		if(exists $script_report->{warnings}[0])
		{$status = 'ATTENTION';}

		if(exists $script_report->{errors}[0])
		{$status = 'PROBLEM';}

		if($script_report->{success} == 0)
		{$status = 'INCOMPLETE';}

		my $values = join "\t",$date,$test,$total_runs,$status,$runtime,$tested,$messages,$warnings,$errors;
		$values .= "\n\n";
		$output .= $values;

		$output .= (join "\n\n", "Messages:\n" . $verbose_messages, "Warnings:\n" . $verbose_warnings, "Errors:\n" . $verbose_errors . "\n");
		

	   } 
	}
		return $output;
    }
    return 0;
}
=cut

#####################################################################
# make page allowing for display of messages, warnings and errors
#####################################################################

#############################
#
#
# Return: Array(message (body), link (link to URL for temporary file))
#############################
sub create_summary_page {
#############################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'file,dir' );
    my $file     = $args{-file};
    my $copy_dir = $args{-dir};
    my $note     = $args{-note};

    my $path     = '';
    my $filename = $file;

    if ( $file =~ /^(.*)\/(.*?)$/ ) {
        $path     = $1;
        $filename = $2;

        unless ( -d $path ) {
            $file = $Configs{URL_temp_dir} . '/' . $filename;
        }
    }

    my $path      = $self->{configs}->{path}      || $Configs{path};
    my $js_files  = $self->{configs}->{js_files}  || $Configs{js_files};
    my $css_files = $self->{configs}->{css_files} || $Configs{css_files};

    my $msg = &LampLite::HTML::initialize_page( -path => "/$path", -css_files => $css_files, -js_files => $js_files, -min_width => 1200, -suppress_content_type => 1 );    ## generate Content-type , body tags, load css & js files ... ##
    $msg .= $BS->open();
    $msg .= $BS->header( -right => 'Go to ' . Link_To( "http://limsmaster.bcgsc.ca/SDB/cgi-bin/alDente.pl", 'alDente' ) );
    $msg .= "<br>" . "<div id='navtxt' class='navtext'></div>\n<BR>";
    $msg .= $self->create_HTML( 'html', $copy_dir, -note => $note );

    $msg .= $BS->close();
    $msg .= &LampLite::HTML::initialize_page();

    #content of the email
    #print "what's msg in create_summary_page: $msg, html: $tmp_dir/$summary_page\n";

    my $write = "$URL_temp_dir/$filename";

    my $HTML;
    try_system_command("rm $write");
    open $HTML, ">>", $write or print "COULD NOT OPEN $write\n";
    print {$HTML} $msg;
    close $HTML;

    my $url_link = $Configs{URL_domain} . '/dynamic/tmp/' . $filename;

    try_system_command("cp $write $url_link");
    print "Copied $write -> $url_link.\n";

    ## keep static link to latest cron summary ##
    if ( $filename =~ /Cron_Summary/ ) {
        try_system_command("ln -sf $write $URL_temp_dir/Latest_Cron_Summary.html");
    }

    return ( $msg, $url_link );

}

##############################
# Notify the problems to admin
##############################
sub send_summary {
######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'file,dir' );

    my ( $msg, $link ) = $self->create_summary_page(%args);

    $msg .= "<P>" . &Link_To( $link, 'Link to Cron Summary in alDente' );

    my $to_address;

    foreach my $address ( @{ $self->{notify} } ) {
        $to_address .= "$address";
    }

    my $from_address = "System_Monitor";

    my $subject;
    my @list  = keys %{ $self->{cron_list} };
    my $count = @list;
    if ( $count > 1 ) {
        $subject = "System Monitor - Cron Summary";
    }
    else {
        if   ( ref $self->{cron_list}{ $list[0] } eq 'ARRAY' ) { $subject = "System Monitor - " . $self->{cron_list}{ $list[0] }[0]; }
        else                                                   { $subject = "System Monitor - " . $list[0]; }
    }

    if ($msg) {
        #my $header = "Content-type: text/html\n\n$java_header\n";
        my $header = "html";
        my $ok     = LampLite::Notification::Email_Notification(
            -to_address   => $to_address,
            -from_address => $from_address,
            -subject      => $subject,
            -message => $msg,
            -content_type => 'html',
        );

        # check if notification has been sent successfully and make an entry in the summary log
        unless ($ok) {
            return "Notification Failure";
        }

        #	my $note = "Email notification sent successfully on $now\n";
        #	my $summary_log	= _write_to_log (-logName=>$summaryLogName,-logContent=>$note,-logAppend=>1);
    }

    return $msg;
}

#############
sub _day_of_week {
#############
    my %args   = &filter_input( \@_, -args => 'offset' );
    my $offset = $args{-offset};
    my @list   = localtime();
    my $dow    = $list[6];
    if ( $offset =~ /^\-(\d+)d$/i ) {
        $dow -= $1;
    }
    elsif ( $offset =~ /^(\d+)d$/i || $offset =~ /^\+(\d+)d$/i ) {
        $dow += $1;
    }
    else {

        # Give warning message
    }
    my $cr_day = $dow % 7 || 7;
    return $cr_day;
}

# <snip>
# my $graph_gif = $self->generate_stats_graphs(-script=>$script,-stats_file=>$stats_file,-day_count=>$day_count);
# </snip>
###########################
sub generate_stats_graphs_old {
###########################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'script,stats_file' );
    my $script     = $args{-script};
    my $stats_file = $args{-stats_file};
    my $day_count  = $args{-day_count} || 30;                                  ## Show data for past 7 days by default;

    $self->{stats_files}{$script} = $stats_file;

    foreach my $stat_type ( 'Errors', 'Warnings' ) {
        my $x_column_name = "Date";
        my $y_column_name = "$stat_type";
        my $output_file   = "$stats_file" . ".$stat_type" . ".gif";

        ## graph asthetics:
        my $xsize     = 100;
        my $ysize     = 150;
        my $bar_width = 5;
        my $colour    = "red" if ( $stat_type =~ /error/i );
        $colour = "blue" if ( $stat_type =~ /warning/i );
        my $title         = "$stat_type " . "-$day_count" . 'd';
        my $y_label       = '';                                    ## "Days since today";
        my $x_label       = '';                                    ## "$stat_type";
        my $y_column_name = "Date";
        my $y_column_name = "$stat_type";

        require RGTools::Graph;
        my $graphed = Graph::generate_graph(
            -title         => $title,
            -output_file   => "$output_file",
            -file          => "$stats_file",
            -tail_lines    => $day_count,
            -x_column_name => "$x_column_name",
            -y_column_name => "$y_column_name",
            -x_label       => "$x_label",
            -y_label       => "$y_label",
            -xsize         => $xsize,
            -ysize         => $ysize,
            -bar_width     => $bar_width,
            -colour        => $colour,
            -nominal_x     => 1,
            -x_label_skip  => 1,
            -y_label_skip  => 1
        );

        if ( $graphed == 0 ) {
            return 0;
        }

        $self->{stats_graphs}{$script}{$stat_type} = $output_file;

    }

    return 1;

}

return 1;
