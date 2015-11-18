package Process_Monitor;

################################################################################
#
#
# This module is used to generate objects that describe scripts/cron jobs and notify the user in case
#   the script crashes.  This method should enable user to record:
#                        - messages
#                        - warnings
#                        - errors
#                        - details (all of the above, plus any additional text information)
#
#
#
# In the background we will also track:
#                                - time of execution
#                                - run time
#                                - number of succesful tests
#
# Information is stored in an object which is written to frozen to a YAML object
#
# Manager.pm thaws the YAML object, creates an HTML table with information for a given script and emails it to aliases stored in this Process Monitor object
#
# <SYNOPSIS> OUT OF DATE!!!
#
# The following lines should be included in any script we want to monitor.
#
#       my $repobj = RGTools::Report->new(-title=>'Test Write file script',
#                                         -notify=>'aldente@bcgsc.ca',
#                                        );
#
#       $repobj->set_Message('eg. Creating temp file...');     ## message generated
#       ...
#       $repobj->set_Warning('eg. No data found');             ## warning generated
#       ...
#       $repobj->set_Error('eg. Error');
#       ...
#       $repobj->set_Detail("Data: $data");               ## verbose list of details
#       ...
#       foreach my $index (@records) {
#           ...
#           $repobj->succeeded();                          ## keep track of successful loops
#       }
#
#       if($error) {
#             $repobj->set_error('disk full',-fatal=>1);   ## generate error (optional fatal flag)
#       }
#      $repobj->completed();
#
#     Notifying Errors:
#
#
# </SYNOPSIS>
#
################################################################################

use strict;
use Data::Dumper;
use YAML;

use RGTools::RGIO;
use RGTools::HTML_Table;
use RGTools::Process_Monitor::Manager;
use alDente::Notification;
use alDente::SDB_Defaults;
use SDB::CustomSettings;

use Benchmark;
use vars qw(%Configs);

my $HTML_dir = "dynamic/tmp";
my $url_file;
my $yellow_on_black = "\033[1m\033[33m\033[40m";
my $red_on_black = "\033[1m\033[31m\033[40m";
my $default_color = "\033[0m";
###################
### Constructor ###
###################
sub new {
###########
    my $this = shift;

    my %args = &filter_input(
        \@_,
        -args => 'title,notify,cron_dir',

        #        -mandatory => 'title'
    );

    my $force   = $args{-force};
    my $configs = $args{-configs};

    my $username = `whoami`;
    my $testing = defined $args{-testing} ? $args{-testing} : 0;
  
    my $log;
    if ( $username =~ /aldente/ ) { $log = 1 }
    elsif ($force) { $log = 0 }
    else {
        $log = 0;    ## logging not allowed unless aldente ##
        print "Logging suppressed.  (Run as aldente user to log data)\n";
#        if ( !$testing ) {
#            my $check = Prompt_Input( -type => 'char', -prompt => 'Continue(c) or Abort(a)' );
#            if ( $check ne 'c' ) {exit}
#        }
    }

    ### Handler to catch the error message the script died with
    $SIG{__DIE__} = sub { $SIG{DIE} = chomp_edge_whitespace( $_[0] ) };

    ### Initialization
    my $self = {};
    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{lock} = 0;
    ### Benchmarks
    $self->{Benchmark}{Start} = new Benchmark;

    $self->{_execution_time} = undef;

    ### Timestamps
    $self->{_start_time} = &date_time();
    $self->{_end_time}   = undef;

    ### Message storage
    $self->{messages}  = [];
    $self->{warnings}  = [];
    $self->{errors}    = [];
    $self->{details}   = [];
    $self->{succeeded} = 0;
    $self->{quiet}     = 0;
    $self->{success}   = 0;
    $self->{force}     = 0;
    $self->{url}       = "";

    my $script = $0;
    $script =~ s /^(.*)\/(.+?)$/$2/;
    $script =~ s/\.pl//g;

    if ( $args{-title} =~ /(.*).pl Script/ ) { $args{-title} = $1 }

    ### Arguments
    $self->{title}    = $args{-title} || $script;
    $self->{script}   = $script;
    $self->{log}      = $log;                       ## optionally suppress logging
    $self->{notify}   = [];
    $self->{no_email} = $args{-no_email};           ## optionally block sending emails

    if ($configs) { $self->{configs} = $configs }

    ### Notification list
    if ( $args{-notify} ) {
        $self->set_notify( $args{-notify} ) or return;
    }

    # Notify List
    
    if ($log) {
        $self->{cron_dir} = $args{-cron_dir} || $self->{configs}{cron_dir} || $self->cron_dir('-6h');
        if ( $args{-offset} ) { $self->{cron_dir} = $self->cron_dir("$args{-offset}"); }
    
        $self->{stats_dir} = $args{-stats_dir} || $self->stats_dir();
    }
    
    $self->{frequency} = $args{-frequency};
    $self->{quiet}     = $args{-quiet} if defined $args{-quiet};
    $self->{verbose}   = $args{-verbose} if defined $args{-verbose};
    $self->{temp}      = $args{-temp} || 0;                            ## When Process_Monitor is only temporary to allow better Messaging

    ### Runtime parameters
    $self->{pid}     = $$;
    $self->{_user}   = chomp_edge_whitespace(`whoami`);
    $self->{host}    = $ENV{HOSTNAME};
    $self->{testing} = $testing;

    #    $url_file = "$self->{script}" . timestamp() . ".htm";
    $self->{url} = $args{-url} || "";                                  # "$URL_domain/$URL_dir_name/$HTML_dir/$url_file";

    if ( $args{-variation} ) {
        $self->set_variation( $args{-variation} );
    }

    ###log_file location
    $self->{log_file} = "$self->{cron_dir}/" . $self->{title} . '.log';
    ###stats_file location
    #    $self->{stats_file} = "$self->{stats_dir}/" . $self->{title} . '_stats.log';
    return $self;
}

######################
# Sets the log location of the script
######################
sub set_variation {
######################
    my $self      = shift;
    my $variation = shift;

    if ($variation) {
        $self->{variation} = $variation;
        $self->{title} .= '.' . $variation;
        $self->{log_file} = "$self->{cron_dir}/$self->{title}.log";

        #        $self->{stats_file} = "$self->{stats_dir}/$self->{script}_${variation}_stats.log";
    }
}

######################################
# Generate default cron directory
# (creates directory if necessary)
#
# Return: directory name
#############################
sub cron_dir {
#############################
    my $self = shift;
    my $offset = shift;
    my ($date) = split ' ', &date_time($offset);
    my ( $year, $month, $day ) = split '-', $date;

    my $log_dir = $self->log_dir();

    my $new_dir = "$log_dir/cron_logs/Process_Monitor/$year/$month/$day";
    unless ( -e $new_dir ) {
        `mkdir -m 775 -p "$new_dir"`;
    }

    return $new_dir;
}

###############
sub log_dir {
###############
    my $self = shift;   
    my $home = $self->{configs}{logs_data_dir};  ## load this from $dbc ...
    
    return $home;
}

#Return: directory name
####################
sub stats_dir {
####################
    my $self = shift;
    my $log_dir = $self->log_dir();
    my $new_dir = "$log_dir/Process_Monitor/stats";

    unless ( -e $new_dir ) {
        `mkdir -m 775 -p "$new_dir"`;
    }

    return $new_dir;
}

####################
sub set_notify {
####################
    my $self       = shift;
    my $target_ref = shift;

    foreach my $target ( Cast_List( -list => $target_ref, -to => 'array' ) ) {
        if ( $target =~ /\@/ ) {
            push @{ $self->{notify} }, $target;
        }
        elsif ( $target = undef ) {
            next;
        }
        else {
            print "*** Invalid address ($target) ***\n";
        }
    }
    return $self->{notify};
}

########################
sub start_sub_Section {
########################
    my $self = shift;

    return $self->start_Section( @_, -quiet => 1 );
}

########################
sub end_sub_Section {
########################
    my $self = shift;
    return $self->end_Section( @_, -quiet => 1 );
}

######################
sub start_Section {
######################
    #
    # generates standard output header to enable easier parsing through logs
    #
    #
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'section' );
    my $section = $args{-section};
    my $quiet   = $args{-quiet};
    my $target  = $args{-target};
    my $highlight = !$quiet;    ## larger sections with borders and end

    if ( !$quiet ) {
        push @{ $self->{sections} }, $section;
    }

    $self->{section_count}++;
    my $header = "\n";

    if ($highlight) { $header .= "*" x 100 . "\n" }
    $header .= "* ";
    foreach my $level ( 2 .. $self->{section_count} ) { $header .= ". " }
    $header .= "<$section>\t" . date_time() . "\n";

    if ($highlight) { $header .= "*" x 100 . "\n" }

    $self->{section}{$section}{warnings} = [];
    $self->{section}{$section}{errors}   = [];

    print $header;
    return;
}

#
# generates standard output header to enable easier parsing through logs
#
# adds error & warning count indicators for each section
####################
sub end_Section {
####################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'section' );
    my $section = $args{-section};
    my $quiet   = $args{-quiet};

    my $highlight = !$quiet;    ## larger sections with borders and end

    if ( !$highlight ) { $self->{section_count}--; return; }    ## no end block for quiet sections (sub_sections)

    if ( !$quiet ) {
        my $last_section = pop @{ $self->{sections} };
        if ( $last_section ne $section ) { Message("Unstructured section.  $last_section finished - expected $section") }
    }

    my $header;
    $header .= "*" x 100 . "\n";
    $header .= "* ";
    foreach my $level ( 2 .. $self->{section_count} ) { $header .= ". " }
    $header .= "</$section>\t" . date_time() . "\n";

    foreach my $type ( 'errors', 'warnings' ) {
        $self->{section}{$section}{$type} = [] if ( !( defined $self->{section}{$section}{$type} ) );
    }

    if ($highlight) {
        $header .= '* ';
        $header .= int( @{ $self->{section}{$section}{errors} } ) . " Errors;\t";
        $header .= int( @{ $self->{section}{$section}{warnings} } ) . " Warnings;\n";
        $header .= "*" x 100 . "\n";
    }

    print $header;
    $self->{section_count}--;

    return;
}

####################
sub set_Comment {
####################
    my $self    = shift;
    my $comment = shift;

    unless ( $self->{quiet} ) { print "# $comment\n"; }

    return;
}

#
# Wrapper to handle mulitplexed message, warning, error information (useful if passed back from method or function)
#
#
#######################################
sub parse_message_warning_error {
#######################################
    my $self     = shift;
    
    my $msgs     = shift;    ## reference to array of messages
    my $warnings = shift;    ## reference to array of warnings
    my $errors   = shift;    ## reference to array of errors
    my $details  = shift;    ## reference to array of details
my %args      = filter_input( \@_ );
    my $target = $args{-target};	
	my $of_sys_monitor = $args{-of_sys_monitor};
    ## Report methods can easily be adjusted to avoid sending repeat warnings / errors or details below ##

    if ($msgs) {
   
    if ($target eq "printer")
    	{ 
    		print "\n Status\t|   Server\t|   Name/ID\t\t\|   Location[Type]\n";
    		print 	"---------------------------------------------------------------------------------\n";
    			}
        foreach my $m (@$msgs) { $self->set_Message($m, -target => $target, -of_sys_monitor => $of_sys_monitor) }
    }
    if ($warnings) {
        foreach my $w (@$warnings) { $self->set_Warning($w) }
    }
    if ($errors) {
        foreach my $e (@$errors) { $self->set_Error($e) }
    }
    if ($details) {
        foreach my $d (@$details) { $self->set_Detail($d) }
    }

    return;
}

####################
sub set_Message {
####################
    my $self    = shift;
    
    my $message = shift;
    my $now     = &date_time();
    my %args      = filter_input( \@_ );
    my $target = $args{-target};
my $of_sys_monitor = $args{-of_sys_monitor};
if( $of_sys_monitor eq 'sys_monitor'){ push @{ $self->{details} },  $message;}
else {
	push @{ $self->{messages} }, $message;
    push @{ $self->{details} },  $message;
	}
if ($target eq "printer"){
    my @v2 = split /,/, $message;
    my $size = @v2;
    unless ( $self->{quiet} ) { 
    if ($size eq 4){ print   " @v2[2]\t|   @v2[3]\t|   @v2[0]\t\t|   @v2[1]\n"; }
    else 	   { print   " @v2[($size-2)]\t|   @v2[($size-1)]\t|   @v2[0]\t\t|   @v2[1..($size-3)]\n"; }
    
    }
}
else {
   unless ( $self->{quiet} ) { print "$message\n";}
   }
    return;
}

####################
sub set_Warning {
####################
    my $self    = shift;
    my $warning = shift;
    my $now     = &date_time();
    push @{ $self->{warnings} }, $warning;
    push @{ $self->{details} },  $warning;

    if ( $self->{sections}->[-1] ) { push @{ $self->{section}{warnings} }, $warning }

    unless ( $self->{quiet} ) { print "$yellow_on_black WARNING! $default_color $warning\n"; }
  
    return;
}

#################
sub get_Warnings {
#################
    my $self    = shift;
    my $section = shift;

    my $warnings;
    if ($section) {
        if ( defined $self->{section}{$section}{warnings} ) {
            $warnings = $self->{section}{$section}{warnings};
        }
    }
    else {
        $warnings = $self->{warnings};
    }
    return $warnings;
}

##################
sub set_Error {
##################
    # need to call _send_notification() for error reporting

    my $self  = shift;
    my $error = shift;
    my $fatal = shift;
    my $now   = &date_time();

    push @{ $self->{errors} },  $error;
    push @{ $self->{details} }, $error;

    if ( $self->{sections}->[-1] ) { push @{ $self->{section}{errors} }, $error }

    unless ( $self->{quiet} ) { print "$red_on_black ERROR!! $default_color $error\n"; }

    return;
}

#################
sub get_Errors {
#################
    my $self    = shift;
    my $section = shift;

    my $errors;
    if ($section) {
        if ( defined $self->{section}{$section}{errors} ) {
            $errors = $self->{section}{$section}{errors};
        }
    }
    else {
        $errors = $self->{errors};
    }
    return $errors;
}

##################
sub set_Detail {
##################
    my $self   = shift;
    my $detail = shift;
    my $now    = &date_time();

    push @{ $self->{details} }, $detail;

    if ( $self->{verbose} ) { print "DETAIL: $detail\n" }
}

#####################
#
# A method that counts total number of successful actions as defined by user
#
# count parameter enables this method to be called automatically with a count value that may increment the success rate by N
# it may also be called with a count of 0, which is determined to be a failure...
#
# Return: current count of success instances
#####################
sub succeeded {
#####################
    my $self  = shift;
    my $count = shift;

    if ( defined $count ) { $self->{succeeded} += $count }
    elsif ( $count == 0 ) { return 0 }
    else                  { $self->{succeeded}++ }

    return $self->{succeeded};
}

#####################
#
# A method that MUST be executed at the end of a script, otherwise the script is assumed to be crashing or not exiting properly
#####################
sub completed {
#####################
    my $self = shift;
    $self->set_Message( 'Script completed successfully ' . date_time() );
    $self->{success}   = 1;
    $self->{_end_time} = &date_time();
}

#############################
# Destructor
#
# Make sure the object finalized before quiting
# If not, notify the user right away about script not exiting properly
##################
sub DESTROY {
##################
    my $self    = shift;
    my $testing = $self->{testing};
    my $temp    = $self->{temp};
    $self->{_end_time} ||= &date_time();
    $self->{Benchmark}{End} = new Benchmark;
    $self->{_execution_time} = timestr( timediff( $self->{Benchmark}{End}, $self->{Benchmark}{Start} ) );

    unless ( $self->{success} || $temp ) {
        if ( !defined $self->{lock} || $self->{lock} ) {    #lock is not used or locked successfully
            $self->set_Error( "Script ended unexpectedly\n" . $SIG{DIE} );
        }
    }

    if ( $self->{lock} ) {
        $self->remove_lock();
        $self->set_Message( 'Lock file removed successfully ' . date_time() );
    }

    if ( $self->{log} ) {
        if ( $self->{force} || $self->_is_different ) {
            $self->_write_to_log() unless $testing;
        }
        else {
            $self->_log_repeat_message() unless $testing;
        }

        unless ($testing) {
            $self->_write_to_stats_file();
            ## Create graph here
            $self->generate_stats_graphs();

            if ( exists $self->{errors}[0] ) {
                unless ( $self->{no_email} ) {
                    $self->_send_notification();
                }
            }
        }
    }

    $self->set_Detail("Process Monitor Completed");
    return;
}

#######################
### Private Methods ###
#######################

# Return: 1 if current object differs from most recent object (based upon keys below)
##########################
sub _is_different {
##########################
    my $self = shift;

    my @keys         = qw(warnings errors messages succeeded success);
    my $last_message = $self->_get_last_message();

    unless ($last_message) { return 1 }
    foreach my $key (@keys) {
        unless ( compare_objects( $self->{$key}, $last_message->{$key} ) ) {
            return 1;
        }
    }
    return 1;
}

###################
sub _get_last_message {
###################

    my $self = shift;
    open my $LOG, "$self->{log_file}" or return;    # no log file found

    my $check_line;
    my $log_instance;
    my $yaml_instance;

    while ( $check_line = <$LOG> ) {
        if ( $check_line =~ /^Repeat Message/ ) {
            next;
        }
        elsif ( $check_line =~ /(\*)START(\*)/ ) {
            $log_instance = '';
            next;
        }
        elsif ( $check_line =~ /(\*)END(\*)/ ) {
        }
        else {
            $log_instance .= $check_line;
            next;
        }
    }

    $yaml_instance = YAML::thaw($log_instance);

    close $LOG;
    return $yaml_instance;
}

###################
#
# Saves the object in YAML format in Cron directory
#
###################
sub _write_to_log {
###################
    my $self   = shift;
    my $brief  = simplify($self);
    my $object = YAML::freeze($brief);

    if ( !$self->{log} ) { return 1 }
    open my $LOG, ">>$self->{log_file}" or die("Could not open $self->{log_file}");
    try_system_command("chmod 664 $self->{log_file}");
    print {$LOG} "**START**\n";
    print {$LOG} $object;
    print {$LOG} "**END**\n";
    close $LOG;
    print "writing to log file:\n$self->{log_file}\n";
    return 1;
}

#################
#
# $self->_write_to_stats_file();
#
#
#
###############################
sub _write_to_stats_file {
###############################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'errors' );
    my $errors   = $args{-errors} || int( @{ $self->{errors} } );       ## optionally supply specific error count
    my $warnings = $args{-warnings} || int( @{ $self->{warnings} } );
    my $subtitle = $args{-subtitle};                                    ## optionally supply subtitle to current filename to track with higher granularity
    my $quiet    = $args{-quiet};

    if ( !$self->{log} ) { return 1 }

    my $file = $self->error_graph( -subtitle => $subtitle, -format => 'log' );

    if ( !$quiet ) { $self->set_Message("adding entry to stats file: $file") }

    open my $STATS, '>>', $file or die "Could not open stats file: $file\nError: $!";
    if ( !( try_system_command "grep 'Time' '$file'" ) ) {
        print {$STATS} "Date\tTime\tErrors\tWarnings\n";
    }

    my $time = $self->{_end_time} || date_time();
    my ( $date, $end_time ) = split '\s', $time;

    my $newline = "$date\t$end_time\t$errors\t$warnings\n";
    if ( !( try_system_command "grep '$date' '$file'" ) ) {
        print {$STATS} "$newline";
    }
    else {
        my $success = replace_last_line( -file => $file, -newline => "$newline" );
        if ( !$success ) {
            $self->set_Message("Warning: last line of file $file was not replaced with desired alternative; Stats file is not up to date");
        }
        elsif ( !$quiet ) {
            $self->set_Message("Replaced previous entry (for today) in stats file");
        }
    }
    return 1;

}

#
# Retrieve the error graph URL
#
# -format => graph, log, or URL (returns graph file, log file, or URL file name)
#
#
########################
sub error_graph {
########################
    my %args     = &filter_input( \@_, -args => 'subtitle', -self => 'Process_Monitor' );
    my $self     = $args{-self};
    my $subtitle = $args{-subtitle};
    my $type     = $args{-type} || 'Errors';
    my $format   = $args{'-format'} || 'file';                                              ## or URL
    my $title    = $args{-title};
    my $path     = $args{-path};

    $title ||= $self->{title};
    if ($subtitle) { $title .= '.' . $subtitle; }

    my $file;
    if ( $format =~ /url/i ) {

        #	if (-f "$path/$title.stats.$type.gif") {#
        $file = "../../dynamic/cron_stats/$title.stats.$type.gif";

        #	}
    }
    elsif ( $format =~ /graph/i ) {
        $path ||= $self->{stats_dir};
        $file = "$path/$title.stats.$type.gif";
    }
    else {
        $path ||= $self->{stats_dir};
        $file = "$path/$title.stats";
    }

    return $file;
}

#####################
sub create_HTML_page {
#####################
    my $self    = shift;
    my $content = shift;

    $url_file = "$self->{title}" . timestamp() . ".htm";
    if ( !$self->{url} ) {
        $self->{url} = "$Configs{URL_domain}/$Configs{URL_dir_name}/$HTML_dir/$url_file";
    }

    my $HTML_location = "$Configs{URL_temp_dir}/$url_file";
    my $HTML_file;

    open $HTML_file, ">>$HTML_location" or die("Could not open $HTML_location");
    print {$HTML_file} $content;
    close $HTML_file;
}

#################
sub simplify {
#################
    my $self = shift;

    my %simplified;
    my @keys = qw(script _start_time _end_time _execution_time host _user messages warnings errors details succeeded success notify url variation);

    foreach my $key (@keys) {
        $simplified{$key} = $self->{$key};
    }

    return \%simplified;
}

#####################
sub _log_repeat_message {
#####################
    my $self = shift;

    if ( !$self->{log} ) { return 1 }

    open my $LOG, ">>$self->{log_file}" or die("Could not open $self->{log_file}");
    print {$LOG} "Repeat Message Logged At: $self->{_end_time} \n";
    close $LOG;
    print "writing to log file...\n";
    print "log file: $self->{log_file}\n";
    return 1;
}

########################
#
#sends notification of error

########################
sub _send_notification {
########################
    # need to send notification of error
    my $self = shift;
    return if $self->{testing};    ## shouldnt be in here if testing mode anyway

    my $cron_list = { $self->{title} => 1 };

    #    if ( $self->{variation} ) {
    #        $cron_list = { $self->{title} => [ $self->{title} . '_' . $self->{variation} ] };
    #    }

    my $Error_Report = new Process_Monitor::Manager( -cron_list => $cron_list, -include => 1, -cron_dir => $self->{cron_dir}, -stats_dir => $self->{stats_dir}, -configs => $self->{configs} );

    #  $Error_Report->generate_stats_graphs( -script => $self->{script}, -stats_file => $self->{stats_file} );
    $Error_Report->generate_reports();

    my $note;
    if ( $self->{_execution_time} ) {
        $note .= "<B>Execution Time</B>: $self->{_execution_time}<BR>";
    }
    else {
        $note = "<B>Run</B>: $self->{_start_time} ... $self->{_end_time}<BR>";
    }

    $Error_Report->send_summary( $self->summary_page, -note => $note );

    return 1;
}

######################
sub summary_page {
######################
    my $self = shift;

    my $summary_name = $self->{title};    # "Cronjobs_";
    if ( !$summary_name ) {
        $summary_name = "$0_";
        $summary_name =~ s /^(.*)\/(.+?)$/$2/;
        $summary_name =~ s/\.pl//g;
    }

    my $summary_page = $summary_name . '.' . timestamp() . ".html";

    my $link_to_summary = "${URL_domain}/${URL_dir_name}/dynamic/tmp";

    return "$link_to_summary/$summary_page";
}

=comment
    my %args = &filter_input(\@_,args=>'to,subject,body',-mandatory=>'to,subject,body');

    open my $LOG, ">>$self->{log_file}" or die ("Could not open $self->{log_file}",
						return 0
						);


    my $notification_time = &date_time();
    print {$LOG} "Notification sent at: &date_time() \n";    
    close $LOG;

    print "sending notification...\n";

    return 1;
 }
=cut

# <snip>
# my $graph_gif = $self->generate_stats_graphs(-script=>$script,-stats_file=>$stats_file,-day_count=>$day_count);
# </snip>
###############################
sub generate_stats_graphs {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'title,subtitle' );
    my $title     = $args{-title} || $self->{title};
    my $subtitle  = $args{-subtitle};
    my $day_count = $args{-day_count} || 30;                          ## Show data for past 30 days by default;
    my $path      = $args{-path} || $self->{stats_dir};

    #    $self->{stats_files}{$title} = $title;

    foreach my $stat_type ( 'Errors', 'Warnings' ) {
        my $stats_file = $args{-file} || $self->error_graph( -title => $title, -subtitle => $subtitle, -type => $stat_type, -format => 'file', -path => $path );

        my $x_column_name = "Date";
        my $y_column_name = "$stat_type";
        my $output_file   = $self->error_graph( -title => $title, -subtitle => $subtitle, -type => $stat_type, -format => 'graph', -path => $path );

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

        try_system_command("chmod 664 $output_file");

        if ($graphed) {
            `chgrp aldente $output_file`;
            Message("Graphed $graphed from $stats_file -> $output_file...\n");
        }
        if ( $graphed eq '0' ) {
            return 0;
        }
    }
    return 1;

}
########################
#
# creates HTML table with exit message, current data and notification to rescue.
#
########################
sub _report_incomplete {
########################
    my $self = shift;

    ### Script is not exiting properly ie. dying...
    my $et = HTML_Table->new( -title => "Script '$self->{title}' crash info" );
    $et->Set_Row( [ 'Start Time', $self->{_start_time} ] );

    #    $et->Set_Row(['Elapsed Time', end-start]);
    $et->Set_Row( [ 'End Time',     $self->{_end_time} ] );
    $et->Set_Row( [ '',             '' ] );
    $et->Set_Row( [ 'Exit Message', "<b><font color=red>$SIG{DIE}</font></b>" ] );
    $et->Set_Row( [ 'Messages',     join( '<br>', @{ $self->{messages} } ) ] );
    $et->Set_Row( [ 'Warnings',     join( '<br>', @{ $self->{warnings} } ) ] );
    $et->Set_Row( [ 'Errors',       join( '<br>', @{ $self->{errors} } ) ] );
    $self->_send_notification(
        -to      => $self->{notify},
        -subject => "System Monitor: Save '$self->{script}' from dying!",
        -body    => $et->Printout(0)
    );
}

######################
#	Write a lock file
#
#	Return: 1 if success, 0 if the file already exist (that means an instance of the scripe is running)
#######################
sub write_lock {
#######################
    my $self = shift;

    my $lock_file = $self->log_dir() . '/'. $self->{title} . '.lock';
    if ( -e $lock_file ) {
        $self->{lock} = 0;
        $self->set_Message("Lock file exists [$lock_file] - wait or delete file to enable execution");
        return 0;
    }
    else {
        # create a lock file
        open my $LOCK, '>', "$lock_file";
        close $LOCK;
        $self->set_Message("Created lock file $lock_file");
        $self->{lock} = 1;
        return $lock_file;
    }
}

######################
# Remove the lock file
######################
sub remove_lock {
    my $self = shift;

    my $lock_file = $self->log_dir() . '/'. $self->{title} . '.lock';
    if ( -e $lock_file ) {
        try_system_command( -command => "rm $lock_file" );
    }
    return;
}

1;

