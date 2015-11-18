#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Term::ReadKey;
use Time::Local;
use YAML qw(Load);

use RGTools::RGIO qw(Message date_time day_elapsed compare_data);
use SDB::CustomSettings;
use SDB::HTML qw(create_tree hspace);

########################
# CONSTANTS
########################
### script to run
my $run_script = "compareAPI_generic.pl";
my $xml_script1 = "xmldiff.pl";  # script for XML diff
my $xml_script2 = "xmlpp.pl";  # script needed by xmldiff.pl

### library paths
my $seqdb_lib_prod = "/opt/alDente/versions/production/lib/perl/";  # library path on lims02, production
my $xhost_lib_prod = "/usr/local/ulib/prod/alDente/lib/perl/";      # library path on xhost, production
my $seqdb_lib_beta = "/opt/alDente/versions/beta/lib/perl/";        # library path on lims02, beta
my $xhost_lib_beta = "/usr/local/ulib/beta/alDente/lib/perl/";      # library path on xhost, beta

### convert API log to test file
my $number_days_to_check_default = 7;
my $recent_days_to_exclude_default = 0;
my $fileLimit_default = 0;

### default test file
my $standard_default = $FindBin::RealBin . "/../conf/compareAPI_standard.txt";

### web file (option 2)
my $testing_dir = "API_testing";
my $result_dir = "API_test_results";
my $log_dir = "API_test_log";
my $file_dir = "API_test_files";
my $seqdb_html_dir = "/opt/alDente/www/htdocs/html/$testing_dir/";  # main directory of test results accessible by web
my $test_result_html_address = $URL_domain . "/SDB/html/$testing_dir/$result_dir/";  # web HTML address prefix for test results
my $test_log_html_address = $URL_domain . "/SDB/html/$testing_dir/$log_dir/";  # web HTML address prefix for test summaries

### API log (option 2)
my $API_log_dir = "/home/sequence/alDente/logs/alDente_API/";  # API log directory
my $unit_test_log_dir = "/home/sequence/alDente/logs/alDente_unit_test/";  # API unit test case directory
my $API_log = "API_usage.viewer-Guest.log";  # name of the API log that logs API calls called by this script

### API test file connection setting (option 0,2).  these options can be overridden
my $dbase_prod_default = "sequence";
my $dbase_beta_default = "seqdev";
my $host_prod_default = "lims01";
my $host_beta_default = "lims01";
my $LIMS_user_default = "Guest";
my $LIMS_password_default = "pwd";
my $DB_user_default = "viewer";
my $DB_password_default = "viewer";
my $debug_default = 0;

### others (option 2)
my $html_dir = "html";
my $reportCronJob_default = 0;  # swtich to report Cron job results by e-mail or not
my $check_name = "API_test";  # Cron job name
########################
use vars qw($opt_user $opt_dbase_prod $opt_dbase_beta $opt_host_prod $opt_host_beta $opt_debug $opt_input $opt_output $opt_choice $opt_prod_path $opt_beta_path $opt_report $opt_day $opt_number $opt_method $opt_temp_dir $opt_exclude_day);

&GetOptions(
	    'user=s' => \$opt_user,
	    'dbprod=s' => \$opt_dbase_prod,
	    'dbbeta=s' => \$opt_dbase_beta,
	    'hostprod=s' => \$opt_host_prod,
	    'hostbeta=s' => \$opt_host_beta,
	    'debug=s' => \$opt_debug,
	    'input=s' => \$opt_input,
	    'output=s' => \$opt_output, 
	    'choice=s' => \$opt_choice, 
	    'libprod=s' => \$opt_prod_path,
	    'libbeta=s' => \$opt_beta_path,
	    'report=s' => \$opt_report,
	    'day=s' => \$opt_day,
	    'exclude_day=s' => \$opt_exclude_day,
	    'number=s' => \$opt_number,
	    'method=s' => \$opt_method,
	    'temp=s' => \$opt_temp_dir
	    );

### get choice
my $option = $opt_choice;                                           # choice; 0: convert API log to test file, 1: run test file
&_print_message() if $option !~ /^(?:0|1|2)$/;
### get input file
my $infile = $opt_input;                                            # input file
if($infile eq undef){
    $infile = $standard_default if $option == 2;
    &_print_message() if $option != 2;
}
### get output file
my $outfile = $opt_output;                                          # output file
&_print_message() if $outfile eq undef && $option != 2;
### get API check days
my $exclude_recent_days = $opt_exclude_day || $recent_days_to_exclude_default; # for c=0 or 2, specify the most recent number of days that the API log will be ignored
my $num_days_to_check = $opt_day || $number_days_to_check_default;  # for c=0 or 2, specify the number of days in the past that the API log will be used
$num_days_to_check += $number_days_to_check_default if(!$opt_day && $opt_exclude_day && $opt_exclude_day >= $number_days_to_check_default);
if($exclude_recent_days >= $num_days_to_check && $num_days_to_check != 0){
    die "-exclude_day cannot to equal or greater than -day\n";
}
# get API limit
my $fileLimit = $opt_number || $fileLimit_default;                  # for c=0 or 2, specify the maximum number of test cases per API log
### get library paths
my $lib_prod = $opt_prod_path;                                      # production script library: "production" or user defined (default: "production")
my $lib_beta = $opt_beta_path;                                      # beta script library: "beta" or user defined (default: "beta")
### get cron job flag
my $reportCronJob = $opt_report || $reportCronJob_default;          # swtich to report Cron job results by e-mail or not
### get methods to check
my @methods_to_check = split(/,|\s+/,$opt_method);
my $methods_to_checkRef = \@methods_to_check;
### get temporary working directory
my $test_dir;
if($option == 1){                                                   # for option 1, get temporary working directory from output file
    $opt_output =~ /(.+)\//; 
    $test_dir = $1;
}
else{
    $test_dir = $opt_temp_dir;                                      # directory to store test files
    &_print_message() if $test_dir eq undef && $option == 2;
    $test_dir .= "/" if $test_dir !~ /\/$/;
}
my $test_result_dir = $test_dir . "$result_dir/";  # directory to store test resutls
my $test_log_dir = $test_dir . "$log_dir/";         # directory to store log results
my $test_file_dir = $test_dir . "$file_dir/";      # directory to store test files
### get connection settings
my %connection;
$connection{user} = $opt_user;
$connection{dbprod} = $opt_dbase_prod;
$connection{dbbeta} = $opt_dbase_beta;
$connection{hostprod} = $opt_host_prod;
$connection{hostbeta} = $opt_host_beta;
$connection{debug} = $opt_debug;
my $connectionRef = \%connection;

if(defined $connection{user} && $reportCronJob != 1){
    print "Enter password: ";
    ReadMode 'noecho';
    $connection{password} = ReadLine 0;
    chomp $connection{password};
    print "\n";
    ReadMode 'normal';
    die "$0: You must specify -password if -user is defined  " if $connection{password} eq undef || $connection{password} eq "";
}

### initialize directories for choice = 2
if($option == 2){
    &_clear_directory($test_dir);
    print "Creating directory:\n\t$test_dir\n\t$test_result_dir\n\t$test_log_dir\n\t$test_file_dir\n\n";
    `mkdir $test_dir` if(! -e $test_dir);
    `mkdir $test_result_dir` if(! -e $test_result_dir);
    `mkdir $test_log_dir` if(! -e $test_log_dir);
    `mkdir $test_file_dir` if(! -e $test_file_dir);
    `mkdir $unit_test_log_dir` if (! -e $unit_test_log_dir);
    `chmod -R ugo+rw $test_dir`;
    `chmod -R ugo+rw $test_result_dir`;
    `chmod -R ugo+rw $test_log_dir`;
    `chmod -R ugo+rw $test_file_dir`;
    `chmod -R ugo+rw $unit_test_log_dir`;
    print "Error: Cannot create directory $test_dir\n" if(! -e $test_dir);
    print "Error: Cannot create directory $test_result_dir\n" if(! -e $test_result_dir);
    print "Error: Cannot create directory $test_log_dir\n" if(! -e $test_log_dir);
    print "Error: Cannot create directory $test_file_dir\n" if(! -e $test_file_dir);
    print "Error: Cannot create directory $test_file_dir\n" if(! -e $unit_test_log_dir);
}

### process options
if($option == 0){  # convert log file to test file
    &_write_test_file($infile,$outfile,$num_days_to_check,$fileLimit,$methods_to_checkRef,$exclude_recent_days);
    print "******************************************************\n";
    print "Output file located at\t$outfile\n";
    print "******************************************************\n";
    exit;
}

### load necessary libraries for options 1 and 2
# determine server
my $server;
if(-e $xhost_lib_prod && -e $xhost_lib_beta){
    $server = "xhost";
}
elsif(-e $seqdb_lib_prod && -e $seqdb_lib_beta){
    $server = "seqdb";
}
else{
    die "$0: cannot determine server.  ";
}

# get library path
my $prod_path = $lib_prod;
my $beta_path = $lib_beta;
if($server eq "xhost"){
    unshift(@INC,$xhost_lib_prod);
    $prod_path = $xhost_lib_prod unless defined $lib_prod;
    $beta_path = $xhost_lib_beta unless defined $lib_beta;
}
elsif($server eq "seqdb"){
    unshift(@INC,$seqdb_lib_prod);
    $prod_path = $seqdb_lib_prod unless defined $lib_prod;
    $beta_path = $seqdb_lib_beta unless defined $lib_beta;
}
else{
    &_print_message();
}

if($option == 1){
    my %arg;
    $arg{-infile} = $infile;
    $arg{-outfile} = $outfile;
    $arg{-connection} = $connectionRef;
    &_option_1(\%arg);
}
elsif($option == 2){
    require alDente::Cron;
    &_option_2($methods_to_checkRef);
}
exit;

#####################################################################################
##################################  Subroutines #####################################
#####################################################################################

##############################
# Append the correct script path for a command
##############################
sub _get_command{
    my $command = shift;
    my $path = $FindBin::Bin;
    $path .= "/" if $path !~ /\/$/;
    $command = $path . $command;
    return $command;
}

##############################
# Option 1
##############################
sub _option_1{
    my $arg = shift;
    my $infile = $$arg{-infile};
    my $outfile = $$arg{-outfile};
    my $connectionRef = $$arg{-connection};

    ### output file paths
    my $productionOutFile = $outfile . "_production.txt";
    my $betaOutFile = $outfile . "_beta.txt";
    my $differenceFile = $outfile . "_diff.txt";
    my $productionOutXML =  $outfile . "_production.xml";
    my $betaOutXML = $outfile . "_beta.xml";
    my $differenceFileXML = $outfile . "_diff.html";
    
    require Imported::XML::Dumper;
    
    if($infile eq undef || $outfile eq undef){
	&_print_message();
    }
    
    ### run production and beta scripts
    chdir($test_dir)||die "$0: cannot access directory $test_dir  ";

    my $prodCommand = "$run_script -file $infile -lib $prod_path -type production";
    $prodCommand .= " -user $$connectionRef{user}" if defined $$connectionRef{user};
    $prodCommand .= " -password $$connectionRef{password}" if defined $$connectionRef{password};
    $prodCommand .= " -dbase $$connectionRef{dbprod}" if defined $$connectionRef{dbprod};
    $prodCommand .= " -host $$connectionRef{hostprod}" if defined $$connectionRef{hostprod};
    $prodCommand .= " -debug $$connectionRef{debug}" if defined $$connectionRef{debug};

    my $betaCommand = "$run_script -file $infile -lib $beta_path -type beta ";
    $betaCommand .= " -user $$connectionRef{user}" if defined $$connectionRef{user};
    $betaCommand .= " -password $$connectionRef{password}" if defined $$connectionRef{password};
    $betaCommand .= " -dbase $$connectionRef{dbbeta}" if defined $$connectionRef{dbbeta};
    $betaCommand .= " -host $$connectionRef{hostbeta}" if defined $$connectionRef{hostbeta};
    $betaCommand .= " -debug $$connectionRef{debug}" if defined $$connectionRef{debug};

    my $prodCommand = &_get_command($prodCommand);
    my $betaCommand = &_get_command($betaCommand);

    my $productionOutput = `$prodCommand`;
    my $betaOutput = `$betaCommand`;

    ### print outputs
    open(PROD,">$productionOutFile")||die "Cannot open file $productionOutFile\n";
    open(BETA,">$betaOutFile")||die "Cannot open file $betaOutFile\n";
    open(DIFF,">$differenceFile")||die "Cannot open file $differenceFile\n";
    
    print BETA "#####################################################################\n\t\tBeta\n";
    print BETA "#####################################################################\n";
    print PROD "#####################################################################\n\t\tProduction\n";
    print PROD "#####################################################################\n";
    print BETA "$betaOutput";
    print PROD "$productionOutput";

    close(BETA);
    close(PROD);

    ### diff
    my $difference = `diff -y $productionOutFile $betaOutFile`;
    print DIFF $difference;
    close(DIFF);
    
    ### XML diff
    # first generate XML files
    
    my $dump = new XML::Dumper;
    my $productionXML = $dump->pl2xml($productionOutput);
    my $betaXML = $dump->pl2xml($betaOutput);
    
    open(PRODXML,">$productionOutXML")||die "Cannot open file $productionOutXML\n";
    open(BETAXML,">$betaOutXML")||die "Cannot open file $betaOutXML\n";
    
    print BETAXML "#####################################################################\n\t\tBeta\n";
    print BETAXML "#####################################################################\n";
    print PRODXML "#####################################################################\n\t\tProduction\n";
    print PRODXML "#####################################################################\n";
    print BETAXML "$betaXML";
    print PRODXML "$productionXML";
    
    close(PRODXML);
    close(BETAXML);
    
    print "Difference files:\nXML: $differenceFileXML\ntext: $differenceFile\n";
    
    open(XMLDIFF,">$differenceFileXML")||die "Cannot open file $differenceFileXML\n";
    
    my $command = &_get_command("$xml_script1 -p -H -t $productionOutXML $betaOutXML");
    my $script_to_copy = &_get_command("$xml_script2");
    ### copy xmlpp.pl to temporary working directory.  this is needed to resolve file permission issues when running this script as different users
    ### this is a script needed by xmldiff.pl
    `cp $script_to_copy .`;
    my $result = `$command`;
    # replace '&apos;' tags with '''
    $result =~ s/\&amp\;apos\;/\'/g;
    # replace '&gt;' tags with '>'
    $result =~ s/\&amp\;gt\;/>/g;
    # replace '&lt;' tags with '<'
    $result =~ s/\&amp\;lt\;/</g;
    # replace '&quot;' tags with '"'
    $result =~ s/\&amp\;quot\;/\"/g;
    # replace '<function> ... </function>' and <argument> ... </argument> tags with HTML font tags
    $result =~ s/<function>/<font style="BACKGROUND-COLOR: yellow" size="+2" color="black"><b>/g;
    $result =~ s/<argument>/<b>/g;
    $result =~ s/<\/function>/<\/font><\/b>/g;
    $result =~ s/<\/argument>/<\/b>/g;

    #print $result;
    print XMLDIFF $result;
    close(XMLDIFF);

    # change file permissions
    `chmod ugo+rw $differenceFile`;
    `chmod ugo+rw $differenceFileXML`;

    `rm -f $productionOutFile`;
    `rm -f $betaOutFile`;
    `rm -f $productionOutXML`;
    `rm -f $betaOutXML`;

    print "******************************************************\n";
    print "Diff file at $differenceFile\n";
    print "XML diff file at $differenceFileXML\n";
    print "******************************************************\n";
}

##############################
# Option 2
##############################
sub _option_2{
    my $methods_to_checkRef = shift;

    my %args;
    $args{-test_result_dir} = $test_result_dir;
    $args{-test_log_dir} = $test_log_dir;
    $args{-test_file_dir} = $test_file_dir;
    $args{-test_result_html_address} = $test_result_html_address;
    $args{-test_log_html_address} = $test_log_html_address;
    $args{-API_log_dir} = $API_log_dir;
    $args{-API_log} = $API_log;
    $args{-html_dir} = $html_dir;
    $args{-num_past_days_to_run_API} = $num_days_to_check;
    $args{-fileLimit} = $fileLimit;
    $args{-manualFile} = $infile;
    $args{-script_dir} = $FindBin::Bin;
    $args{-method} = $methods_to_checkRef;
    $args{-exclude_recent_days} = $exclude_recent_days;

    my $time = RGTools::RGIO::date_time();
    $time =~ s/[\:\s]/\-/g;
    my $logFile = $test_log_dir . "API_test_" . $time . ".html";
    my $logFile_html = $test_log_html_address . "API_test_" . $time . ".html";
    
    ### run script
    chdir($FindBin::Bin)||die "$0: cannot access directory $FindBin::Bin  ";
    my $resultRef = &_option_2_main(\%args);

    ### upload files to web-accessible directories (only possible if running script on lims02)
    # create web directory if not exist
    if($server eq "seqdb"){
	`mkdir $seqdb_html_dir` if (! -e $seqdb_html_dir);
	`chmod -R ugo+rw $seqdb_html_dir`;

	my @upload_dir = ($test_result_dir,$test_log_dir);
	foreach (@upload_dir){
	    print "cp -rf $_ $seqdb_html_dir\n";
	    `cp -rf $_ $seqdb_html_dir`;
	}
    }
    else{
	print "Since you're running script on xhost, you must manually upload folders\n\t$test_result_dir (test result directory)\n\t$test_log_dir (test log directory)\nto web folder $seqdb_html_dir on lims02.\n";
    }
    
    ### generate Cron job e-mail
    if($reportCronJob){
	print "Sending e-mail...\n";
	my $link = "<HTML><HEAD><META HTTP-EQUIV=\"Refresh\" CONTENT=\"0;URL=$logFile_html\"><TITLE>Redirect</TITLE></HEAD></HTML>";
	my %Crons;
	$Crons{$check_name}{monitor} = '';
	$Crons{$check_name}{content} = 'html';
	$Crons{$check_name}{tested} = $$resultRef{tested};
	%Crons->{$check_name}{warnings} = $$resultRef{warnings};
	%Crons->{$check_name}{errors} = $$resultRef{errors};
	push(@{%Crons->{$check_name}{details}},$link);
    
	my $ok = _submit_results(\%Crons);
	if($ok){
	    print "Cron job successful.\n";
	}
	else{
	    print "Cron job unsuccessful.\n";
	}
    }
    print "Finished.\n";
    exit;
}

##############################
# Notify Cron job problems to admin
##############################
sub _submit_results{
    my $Crons = shift;
    my $ok = &alDente::Cron::parse_job_results(-job_results=>$Crons);
    return $ok;
}

##############################
# Help menu
##############################
sub _print_message{
    my $not_terminate = shift;
    print "\nUsage:  $0 -choice <choice (0, 1, or 2)>\t(plus other options)\n";
    print "\n===================================================\n";
    print "Options for -choice = 0 (convert API log to test file):\n";
    print "===================================================\n";
    print "  -input <input API log file>\n";
    print "  -output <output test file>\n";
    print "  -day <check API log in the past ? days          (optional, default is $number_days_to_check_default)>\n";
    print "  -exclude_day <exclude log in most recent ? days (optional, default is 0)>\n";
    print "  -number <max. number of test cases per log file (optional, default is $fileLimit_default)>\n";
    print "\ne.g.\t/home/echang/scripts/compareAPI.pl -input /home/echang/files/sample_API_log.txt -output /home/echang/files/sample_API_test_file.txt -choice 0 -day 10000 -number 10\n";
    print "\n===================================================\n";
    print "Options for -choice = 1 (run test file):\n";
    print "===================================================\n";
    print "  -input <input test file>\n";
    print "  -output <output result file (omit extension)>\n";
    print "  -libprod <production library path> (optional, default: $xhost_lib_prod (xhost) or $seqdb_lib_prod (seqdb))\n";
    print "  -libbeta <beta library path>       (optional, default: $xhost_lib_beta (xhost) or $seqdb_lib_beta (seqdb))\n";
    print "\n  ### API connection settings ###\n\n";
    print "  -hostprod <production DB host>     (optional, default: $host_prod_default)\n";
    print "  -hostbeta <beta DB host>           (optional, default: $host_beta_default)\n";
    print "  -dbprod <production DB>            (optional, default: $dbase_prod_default)\n";
    print "  -dbbeta <beta DB>                  (optional, default: $dbase_beta_default)\n";
    print "  -user <LIMS user>                  (optional, default: $LIMS_user_default) (*** password prompt ***)\n";
    print "  -debug <0/1>                       (optional, default: $debug_default)\n";
    print "\ne.g.\t/home/echang/scripts/compareAPI.pl -input /home/echang/files/API_test_scope.txt -output /home/echang/files/result -choice 1 -libbeta /opt/alDente/versions/echang/lib/perl/ -debug 1 -dbbeta sequence\n";
    print "\n===================================================\n";
    print "Options for -choice = 2 (automatic run):\n";
    print "===================================================\n";
    print "  -temp <temporary working directory> (*** User must have writing permission. ***)\n";
    print "  -report <0/1> switch to report Cron job result (optional, default: $reportCronJob_default)\n";
    print "  -method <method to be tested>      (optional. comma-delimited)\n";
    print "  -input <input standard test case file> (optional, default is $standard_default)\n";
    print "  -day <check API log in the past ? days (optional, default is $number_days_to_check_default)>\n";
    print "  -exclude_day <exclude log in most recent ? days (optional, default is $recent_days_to_exclude_default)>\n";
    print "  -number <max. number of test cases per log file (optional, default is $fileLimit_default)>\n";
    print "  -libprod <production library path> (optional, default: $xhost_lib_prod (xhost) or $seqdb_lib_prod (seqdb))\n";
    print "  -libbeta <beta library path>       (optional, default: $xhost_lib_beta (xhost) or $seqdb_lib_beta (seqdb))\n";
    print "\n  ### API connection settings ###\n\n";
    print "  -hostprod <production DB host>     (optional, default: $host_prod_default)\n";
    print "  -hostbeta <beta DB host>           (optional, default: $host_beta_default)\n";
    print "  -dbprod <production DB>            (optional, default: $dbase_prod_default)\n";
    print "  -dbbeta <beta DB>                  (optional, default: $dbase_beta_default)\n";
    print "  -user <LIMS user>                  (optional, default: $LIMS_user_default) (*** password prompt if -report = 0***)\n";
    print "  -debug <0/1>                       (optional, default: $debug_default)\n";
    print "\ne.g\t/home/echang/scripts/compareAPI.pl -input /home/echang/files/standard.txt -temp /home/echang/tmp -choice 2 -day 1 -number 10 -method get_rearray_data,get_sage_data -libbeta /opt/alDente/versions/echuah/lib/perl/\n";

    exit if ! $not_terminate;
}

##############################
# Option 2 main procedures
##############################
sub _option_2_main{
    my $args = shift;
    my $test_result_dir = $$args{-test_result_dir};
    my $test_log_dir = $$args{-test_log_dir};
    my $test_file_dir = $$args{-test_file_dir};
    my $test_result_html_address = $$args{-test_result_html_address};
    my $test_log_html_address = $$args{-test_log_html_address};
    my $API_log_dir = $$args{-API_log_dir};
    my $API_log = $$args{-API_log};
    my $html_dir = $$args{-html_dir};
    my $num_past_days_to_run_API = $$args{-num_past_days_to_run_API};
    my $fileLimit = $$args{-fileLimit};
    my $manualFile = $$args{-manualFile};
    my $logFileName = $$args{-logFileName};
    my $current_dir = $$args{-script_dir};
    my $methods_to_checkRef = $$args{-method};
    my $exclude_days = $$args{-exclude_recent_days};

    my $time = RGTools::RGIO::date_time();
    $time =~ s/[\:\s]/\-/g;
    print "***** Checking API logs within the last $num_past_days_to_run_API to $exclude_days days.\n";
    print "***** Running a maximum of $fileLimit queries for each log file.\n";

    ########## grab all API log files
    my @files;
    my $fileRef = \@files;
    &_file_grabber($API_log_dir,$fileRef);
    
    my %messages;  # grab API logs from API runs
    
    ########## delete previous test files
    &_clear_directory($test_file_dir);

    ########## read user input file
    my %standardInputs;
    my $standardInputsRef = \%standardInputs;
    &_split_user_file($standardInputsRef,$test_file_dir,$manualFile,$current_dir);

    #### get current month, year
    my $date = `date`;
    die "$0: weird date format $date  " if $date !~ /\w+\s+\w+\s+\d+\s+\d+\:\d+\:\d+\s+\w+\s+\d+/;
    $date =~ /\w+\s+(\w+)\s+\d+\s+\d+\:\d+\:\d+\s+\w+\s+(\d+)/;
    my $mon = $1;
    my $year = $2;
    
    #### run API for each small standard test file
    my %standardOutputs;
    foreach my $method (keys %standardInputs){
	my $ok_to_run = 0;
	my $methodCheckSize = @$methods_to_checkRef;
	foreach (@$methods_to_checkRef){
	    if($method =~ /$_/i){
		$ok_to_run = 1;
		last;
	    }
	}
	if($ok_to_run == 0 && $methodCheckSize > 0){
	    next;
	}
	$standardInputs{$method} =~ /.+\/(\S+)\.txt$/;
	my $outfile = $test_result_dir . $1;
	my $htmlfile = &_run_test_file($standardInputs{$method},$outfile,$current_dir,\%messages,$test_result_dir,$html_dir,$test_result_html_address,$API_log_dir,$mon,$year,$API_log);
	print "\t\tFinished running $standardInputs{$method}.\n";
	$standardOutputs{$method} = $htmlfile;
    }
    
    ########## generate a test file for each unique method-input combination, then run API
    my %data;
    my @outfiles;
    
    foreach my $file (@$fileRef){
	die "Weird file: $file  " if $file !~ /\/(\S+)$/;
	$file =~ /.+\/(\S+)$/;
	print "Processing file $file...\n";
	#### check file last modified date; if out of date, skip file
	next if -M $file > $num_past_days_to_run_API;
	next if -M $file < $exclude_days;
	#### generate a big test file for each log file
	my $outfile1 = $test_file_dir . $1 . "_test.txt";
	chdir($current_dir)||die "$0: cannot access directory $current_dir  ";
	print "\tGenerating test files for $file...\n";
	&_write_test_file($file,$outfile1,$num_days_to_check,$fileLimit,$methods_to_checkRef,$exclude_recent_days);

	#### split big test file into small test files with 1 method and 1 input for each 
	my $fileRef1 = &_split_file($outfile1,$test_file_dir);
	
	#### run API for each small test file
	foreach my $file1 (@$fileRef1){
	    die "$0: test file $file1 does not exists.  cannot run test file.  " if ! -e $file1;
	    $file1 =~ /.+\/(\S+)\.txt$/;
	    my $outfile2 = $test_result_dir . $1;
	    my $htmlfile = &_run_test_file($file1,$outfile2,$current_dir,\%messages,$test_result_dir,$html_dir,$test_result_html_address,$API_log_dir,$mon,$year,$API_log);
	    push(@outfiles,$htmlfile);
	    print "\t\tFinished running $file1.\n";
	}
	&_clear_directory($test_file_dir);
    }

    ########## parse XML diff file
    my $totalCount = @outfiles;
    my $warnCount = 0;
    my $okCount = 0;
    my $errorCount = 0;   
    my $noDataCount = 0;
    
    my $logFile = $logFileName || $test_log_dir . "API_test_" . $time . ".html";
    
    my %data;
    my %methodUsed;  # keep track of method used
    my %methodUsedCount;  # keep track of number of times a method was used
    
    foreach my $file (@outfiles){    
	my ($status,$message,$tipMessage) = &_parse_XML_diff($file);  # $status -- 0: OK, 1: warning, 2: error for beta, 3: error for production, 4: error for all
	$okCount++ if $status == 0;
	$noDataCount++ if $status == 5;
	$errorCount++ if $status >= 2 && $status < 5;
	$warnCount++ if $status == 1;
	
	$file =~ /.+\/(\S+)\.html$/;
	my $fileName = $1;
	die "$0: invalid file name: $fileName  " if $fileName !~ /^(.+)--(.+)_(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d)_(\w+)_([\d\w]+)_\d+_diff$/;
	$fileName =~ /^(.+)--(.+)_(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d)_(\w+)_([\d\w]+)_(\d+)_diff$/;
	my $module = $1;
	my $method = $2;
	my $date = $3;
	my $user = $4;
	my $time = $5;
	my $random = $6;

	# get method usage count and date information
	foreach my $key (keys %standardInputs){
	    if($method =~ /$key/i){
		if(exists $methodUsedCount{$key}){
		    $methodUsedCount{$key}++;
		}
		else{
		    $methodUsedCount{$key} = 1;
		}
		$methodUsed{$key} = $date if ((! exists $methodUsed{$key}) || (exists $methodUsed{$key} && RGTools::RGIO::day_elapsed($methodUsed{$key}) > RGTools::RGIO::day_elapsed($date)));
		last;
	    }
	}
	
	$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{message} = $message;# if $status != 0;
	$file =~ /.+\/(\S+)$/;
	$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{file} = $test_result_html_address . $1;# if $status != 0;
	$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{tip} = $tipMessage;
        #    `rm -f $file` if $status == 0;
    }

    ########## grab standard case output if a method was not called
    foreach my $method (keys %standardInputs){
	my $ok_to_run = 0;
	my $methodCheckSize = @$methods_to_checkRef;
	foreach (@$methods_to_checkRef){
	    if($method =~ /$_/i){
		$ok_to_run = 1;
		last;
	    }
	}
	if($ok_to_run == 0 && $methodCheckSize > 0){
	    next;
	}
	if(!exists $methodUsed{$method}){
	    my ($status,$message,$tipMessage) = &_parse_XML_diff($standardOutputs{$method});  # $status -- 0: OK, 1: warning, 2: error for beta, 3: error for production, 4: error for all, 5: no data
	    $okCount++ if $status == 0;
	    $noDataCount++ if $status == 5;
	    $errorCount++ if $status >= 2 && $status < 5;
	    $warnCount++ if $status == 1;
	    
	    $standardOutputs{$method} =~ /.+\/(\S+)\.html$/;
	    my $fileName = $1;
	    die "$0: invalid standard file name: $fileName  " if $fileName !~ /^(.+)--(.+)_(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d)_(\w+)_([\d\w]+)_\d+_diff$/;
	    $fileName =~ /^(.+)--(.+)_(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d)_(\w+)_([\d\w]+)_(\d+)_diff$/;
	    my $module = $1;
	    my $method = $2;
	    my $date = $3;
	    my $user = $4;
	    my $time = $5;
	    my $random = $6;
	    
	    $data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{message} = $message;# if $status != 0;
	    $standardOutputs{$method} =~ /.+\/(\S+)$/;
	    $data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{file} = $test_result_html_address . $1;# if $status != 0;
	    $data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{tip} = $tipMessage;
            #       `rm -f $standardOutputs{$method}` if $status == 0;
	    $methodUsed{$method} = "Never";
	    
	    # add method usage count info
	    $methodUsedCount{$method} = 1;
	}
    }
    
    my $resultRef = &_print_result_page($logFile,$okCount,$warnCount,$errorCount,$noDataCount,\%standardInputs,\%data,\%messages,$num_past_days_to_run_API,\%methodUsed,\%methodUsedCount,$time,$html_dir,$exclude_days,$test_result_dir);

    my $summaryPage = $test_log_html_address . "API_test_" . $time . ".html";
    print "\n\n*****************************************************\n";
    print "View summary page at:\n$summaryPage\n";
    print "*****************************************************\n";

    return $resultRef;
}

##############################
# Print results for option 2
##############################
sub _print_result_page{
    my $logFile = shift;
    my $okCount = shift;
    my $warnCount = shift;
    my $errorCount = shift;
    my $noDataCount = shift;
    my $standardInputs = shift;
    my $data = shift;
    my $messages = shift;
    my $num_past_days_to_run_API = shift;
    my $methodUsed = shift;
    my $methodUsedCount = shift;
    my $time = shift;
    my $html_dir = shift;
    my $exclude_days = shift;
    my $test_result_dir = shift;

    my $text = "";
    my %result;
    my @warnings;
    my @errors;
    my $testNum = $okCount+$warnCount+$errorCount+$noDataCount;

    ########## print log file
    my $main_table = HTML_Table->new(-title=>'API Test (' . $time . ')');

    my %hugetree;
    foreach my $status (sort (keys %$data)){
	my %bigtree;
	my $category_size = 0;
	my $category;
	$category = "OK" if $status == 0;
	$category = "Warnings" if $status == 1;
	$category = "Errors (beta)" if $status == 2;
	$category = "Errors (production)" if $status == 3;
	$category = "Errors (all)" if $status == 4;
	$category = "No Data" if $status == 5;
	foreach my $module (sort (keys %{$$data{$status}})){
	    foreach my $method (sort (keys %{$$data{$status}->{$module}})){
		my $method_size = 0;
		my %tree;
		foreach my $user (sort (keys %{$$data{$status}->{$module}->{$method}})){
		    foreach my $date (sort (keys %{$$data{$status}->{$module}->{$method}->{$user}})){
			foreach my $random (keys %{$$data{$status}->{$module}->{$method}->{$user}->{$date}}){
			    $category_size++;
			    $method_size++;

			    my $message = $$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{message}; # error message
			    my $tipMessage = $$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{tip};  # mySQL statement
			    if($message =~ /error/i){
				push(@errors,"$module\t$method\t$user\t$date\t$message\n");
			    }
			    elsif($message =~ /warning/i){
				push(@warnings,"$module\t$method\t$user\t$date\t$message\n");
			    }
			    my $short_message = $message;
			    $short_message = substr($message,0,50) . "..." if length($message) > 50;
			    my $name = "<b>" . $user . hspace(5) . $date . "</b>" . hspace(5) . "<font color=\"green\">" . $short_message . "</font>";
			    my $file = $$data{$status}->{$module}->{$method}->{$user}->{$date}->{$random}->{file};
			    $file =~ /.+\/(\S+)_diff.$html_dir$/;
			    my $logfile = $$messages{$1};
			    my $stuff = "<A HREF=\"$file\">View Details</A>" . hspace(5);
			    $stuff .= "<A HREF=\"$logfile\">API Log</A>" if $status > 0;
			    $stuff .= "<BR>MySQL:<BR>$tipMessage" if $tipMessage ne "";
			    $stuff .= "<BR><font color=\"blue\">$message</font>" if $message ne "OK";
			    $tree{$name} = $stuff;

			    ##################################
			    # Building API Unit Test Cases for OK cases
			    ##################################
			    if($status == 0){ # if OK, create a unit test case
				my $new_case = "$unit_test_log_dir/$module-$method" . "_$date" . "_$user.case";
				next if(-e $new_case);
				###### compare with all other method cases to make sure it's not a duplicate
			
				# extract test input and output for the new test case
				my @input0;
				my @output0;
				my ($file) = $file =~ /.+\/(\S+)$/;
				$file = "$test_result_dir/$file";
				print "Examining file $file for API unit test...\n";
				open(READ0,"$file")||die "Cannot open file $file ";
				while(<READ0>){
				    if($_ =~ /i n p u t/i){
					my $line = <READ0>;
					$line =~ /<font .+?>(\s*)(?:<b>)?(.+?)<\/font>/;
					push(@input0,$2);
					my $spaces = length($1);
					while(<READ0>){
					    last if($_ =~ /-------------------------------------/);
					    $_ =~ /^<font .+?>(.+?)<\/font>$/;
					    push(@input0,substr($1,$spaces));
					}
				    }
				    elsif($_ =~ /r e s u l t/i){
					my $line = <READ0>;
					$line =~ /<font .+?>(\s*)(?:<b>)?(.+?)<\/font>/;
					push(@output0,$2);
					my $spaces = length($1);
					while(<READ0>){
					    last if($_ =~ /-------------------------------------/);
					    $_ =~ /<font .+?>(.+?)<\/font>/;
					    push(@output0,substr($1,$spaces));
					}
					last;
				    }
				}
				close(READ0);
				# convert input and output to objects
				next if(scalar(@input0) == 0 || scalar(@output0) == 0);  # no results
				my $input0 = join("\n",@input0);
				$input0 .= "\n";
				my $input0obj = YAML::Load($input0);

				my $output0 = join("\n",@output0);
				$output0 .= "\n";
				my $output0ojb = YAML::Load($output0);

				my @cases = `ls -tl $unit_test_log_dir/$method* | grep -v '~'`;
				my $identical = 0;
				foreach (@cases){
				    # for existing test case, extract test input
				    my ($file1) = $_ =~ /\s(\S+)$/;
				    my @input1;
				    open(READ1,"$file1")||die "Cannot open file $file1\n";
				    while(<READ1>){
					if($_ =~ /\*\*\*input\*\*\*/i){
					    while(<READ1>){
						last if($_ =~ /\*\*\*output\*\*\*/i);
						push(@input1,$_);
					    }
					    last;
					}
				    }
				    close(READ1);
				    # convert input to object
				    my $input1 = join("",@input1);
				    my $input1obj = YAML::Load($input1);
				    # compare existing test case with new case to make sure they are different
				    my @comments;				    
				    my $same = compare_data(1=>$input0obj,
							    2=>$input1obj,
							    -comment=>\@comments
							    );

				    # if case is same, abort the new test case
				    if($same){
					$identical ||= $same;
					last;
				    }
				}

				if(!$identical){
				    print "Building new case $new_case\n";
				    open(WRITE,">$new_case")||die "Cannot open file $new_case\n";
				    print WRITE "***INPUT***\n";
				    print WRITE $input0;
				    print WRITE "***OUTPUT***\n";
				    print WRITE $output0;
				    close(WRITE);
				    `chmod ugo+rw $new_case`;
				}
			    }
			}
		    }
		}
		my $tree = create_tree(-tree=>\%tree,-tab_width=>100,-print=>0,-dir=>'Vertical');
		$bigtree{"<b>$module" . '::' . "$method</b> ($method_size)"} = $tree;
	    }
	}
	my $bigtree = create_tree(-tree=>\%bigtree,-tab_width=>100,-print=>0,-dir=>'Vertical');
	$hugetree{"<font color=\"red\"><b>$category</b></font> ($category_size)"} = $bigtree;
    }
    my $hugetree = create_tree(-tree=>\%hugetree,-tab_width=>100,-print=>0,-dir=>'Vertical');
    $main_table->Set_Row([$hugetree]);

    # method usage stats
    my $method_usage = HTML_Table->new(-title=>"Method usage in past $num_past_days_to_run_API to $exclude_days days");
    $method_usage->Set_Headers(['Method','Times Used','Last Used']);
    foreach my $method (sort (keys %$standardInputs)){
	$method_usage->Set_Row([$method,$$methodUsedCount{$method},$$methodUsed{$method}]);
    }
    $main_table->Set_Row([$method_usage->Printout(0)]);

    # Cron job
    $result{errors} = \@errors;  # used by alDente Cron.pm
    $result{warnings} = \@warnings;  # used by alDente Cron.pm
    $result{tested} = $testNum;  # used by alDente Cron.pm
    $result{content} = 'html';  # used by alDente Cron.pm
    
    # print log
    open(LOG,">$logFile")||die "$0: cannot open file $logFile.  ";
    my $content;
    $content .= "<LINK rel=stylesheet type='text/css' href='/SDB/css/links.css'>\n";
    $content .= "<LINK rel=stylesheet type='text/css' href='/SDB/css/style.css'>\n";
    $content .= "<LINK rel=stylesheet type='text/css' href='/SDB/css/colour.css'>\n";
    $content .= "<script src='/SDB/js/SDB.js'></script>\n";
    $content .= "<script src='/SDB/js/onmouse.js'></script>\n";
    $content .= "<script src='/SDB/js/DHTML.js'></script>\n";
    $content .= "<script src='/SDB/js/alDente.js'></script>\n";
    $content .= $main_table->Printout(0);
    print LOG $content;
    close(LOG);
#    `perl -pi -e 's/SDB_echang_test/SDB_echang/g' $logFile`;
    `chmod ugo+rw $logFile`;

    return \%result;
}

##############################
# Run each samll test case for Option 2
##############################
sub _run_test_file{
    my $infile = shift;
    my $outfile = shift;
    my $current_dir = shift;
    my $messageRef = shift;
    my $test_result_dir = shift;
    my $html_dir = shift;
    my $test_result_html_address = shift;
    my $API_log_dir = shift;
    my $mon = shift;
    my $year = shift;
    my $own_log = shift;

    chdir($current_dir)||die "$0: cannot access directory $current_dir  ";
    print "\t\tRunning test file $infile...\n";
    #####################
    my %arg;
    $arg{-infile} = $infile;
    $arg{-outfile} = $outfile;
    $arg{-connection} = $connectionRef;
    &_option_1(\%arg);

    my $htmlfile = $outfile. "_diff.$html_dir";
    die "$0: running test file... output file $htmlfile does not exists.  run did not succeeed.  " if ! -e $htmlfile;
    $htmlfile =~ /.+\/(\S+)_diff.$html_dir$/;
    my $messageFile_html = $test_result_html_address . $1 . "_diff.$html_dir" . "_log.$html_dir";
    $$messageRef{$1} = $messageFile_html;
    my $messageFile = $htmlfile . "_log.$html_dir";

    # get the API log for the command that was just run
    my $API_log_file = $API_log_dir . $mon . "_" . $year . "/" . $own_log;
    die "$0: log file $API_log_file does not exist.  " if ! -e $API_log_file;
    my $log = `tail -n 300 $API_log_file`;
    open(MSG,">$messageFile")||die "$0: cannot open file $messageFile.  ";
    print MSG "<HTML>\n";
    print MSG "\t<BODY bgcolor=\"\#FFFFFF\" >\n";
    print MSG "\t\t<PRE>\n";
    print MSG &_get_last_log($log);
    print MSG "\t\t</PRE>\n";
    print MSG "\t</BODY>\n";
    print MSG "</HTML>\n";
    close(MSG);
    `chmod ugo+rw $messageFile`;

    # delete all files except XML diff HTML files
    `rm -f $infile`;
    chdir($test_result_dir)||die "$0: cannot access directory $test_result_dir  ";
    `rm -f *.txt`;
    `rm -f *.xml`;
    `rm -f *.diff`;

    return $htmlfile;
}

##############################
# Get the last API log (option 2)
##############################
sub _get_last_log{
    my $line = shift;
    my @lines = split(/\n/,$line);
    my @case;

    foreach (@lines){
	@case = () if $_ =~ /^\d\d\d\d-\d\d-\d\d \d\d\:\d\d\:\d\d/;
	push(@case,$_);
    }
    my $newline = join("\n",@case);
    return $newline;
}    

##############################
# Split user input standard test case file (option 2)
##############################
sub _split_user_file{
    my $outRef = shift;
    my $output_dir = shift;
    my $manualFile = shift;
    my $current_dir = shift;

    chdir($current_dir)||die "$0: cannot access directory $current_dir.  ";
    open(USER,"$manualFile")||die "$0: cannot open user file $manualFile.  ";
    
    my @header;

    while(<USER>){
	chomp;

	if($_ =~ /\[scope\]/){  # start of scope
	    push(@header,$_);
	    my @case;
	    my $headerLine;
	    my $method;
	    my $autoCase = 0;

	    while(<USER>){
		chomp;
		if($_ =~ /^\#method/ || $_ =~ /====/){  # end of a test case
		    my $methodLine = $_;
		    if($method ne undef){  # case not empty
			# generate a unique random number for file name
			my $fileName;
			while(1){
			    my $lower = 1000000;
			    my $upper = 9999999;
			    my $random = &_random_number($lower,$upper);
			    $fileName = $output_dir . "Sequencing_API" . "--" . $method . "_" . "0000-00-00-00-00-00"  . "_". "standard" . "_" . "x" . "_" . $random . ".txt";
			    last if ! -e $fileName;			    
			}
			open(WRITE,">$fileName")||die "$0: cannot open file $fileName  ";
			foreach (@header){
			    print WRITE "$_\n";
			}
			print WRITE "$headerLine\n" if $autoCase == 0;
			foreach (@case){
			    print WRITE "$_\n";
			}
			print WRITE "\n====\n";
			close(WRITE);
			`chmod ugo+rw $fileName`;
			$$outRef{$method} = $fileName;

			# erase case
			$autoCase = 0;
			@case = ();
			$headerLine = undef;
			$method = undef;
		    }
		    if($methodLine =~ /====/){  # end of scope
			last;
		    }
		    die "$0: unknown method line $methodLine  " if $methodLine !~ /^\#method\=\w+/;
		    $methodLine =~ /^\#method\=(\w+)/;
		    $method = $1;
		}
		elsif($_ =~ /^auto/){
		    $autoCase = 1;
		    push(@case,$_);
		    while(<USER>){
			chomp;
			if($_ =~ /----/){
			    push(@case,$_);
			    last;
			}
			push(@case,$_);
		    }
		}
		elsif($_ =~ /^\(\w+\)/){  # header line
		    $headerLine = $_;
		}
		else{
		    push(@case,$_) if $_ ne "";
		}
	    }
	}
	else{
	    push(@header,$_);
	}
    }
    close(USER);
}

##############################
# Delete all files in a directory
##############################
sub _clear_directory{
    my $dir = shift;
    print "Clearing directory $dir...\n";
    `rm -rf $dir` if -e $dir;
#    die "$0: cannot delete directory $dir  " if chdir($dir);
    `mkdir $dir`;
#    die "$0: cannot make directory $dir  " if ! -e $dir;
    `chmod -R ugo+wr $dir`;
    chdir($dir)||die "$0: cannot access directory $dir  ";
}

##############################
# Parse an XML diff file (option 2)
##############################
sub _parse_XML_diff{
    my $file = shift;
    
    open(READ,"$file")||die "$0: cannot open file $file.  ";
    my $failFlag = 0;
    my $warnFlag = 0;
    my $noDataFlag = 0;
    my %failedVersion;
    my %mysql;

    while(<READ>){
	chomp;
	if($_ =~ /I N P U T/){  # input data dumper
	    while(<READ>){
		chomp;
		if($_ =~ /---------------------------/){  # end of input
		    last;
		}
	    }
	}
	elsif($_ =~ /error/i){  # failure
	    $failFlag = 1;
	    if($_ =~ /\"gray\"/){  # for both beta and production
		$_ =~ /error: (.+)<?/i;
		$failedVersion{production} = $1;
		$failedVersion{beta} = $1;
	    }
	    elsif($_ =~ /\"red\"/){  # for production
		$_ =~ /error: (.+)<?/i;
		$failedVersion{production} = $1;
	    }
	    elsif($_ =~ /\"green\"/){  # for beta
		$_ =~ /error: (.+)<?/i;
		$failedVersion{beta} = $1;
	    }
	    else{
		die "$0: unknown diff file failure.  ";
	    }
	}
	elsif($_ =~ /MySQL/i){
	    die "$0: Weird line format $_.  " if $_ !~ /MySQL statement \= .+<?/;
	    $_ =~ /MySQL statement \= (.+)<?/;
	    my $query = $1 . "\;";
	    $mysql{beta} = $query if $_ =~ /\"green\"/;
	    $mysql{production} = $query if $_ =~ /\"red\"/;
	    $mysql{all} = $query if $_ =~ /\"gray\"/;
	}
	elsif($_ =~ /R E S U L T/){  # results data dumper
	    while(<READ>){
		chomp;
		if($_ =~ /-------------------------------------/){  # end of results
		    last;
		}
		elsif($_ =~ /\"red\"|\"green\"/){  # difference between beta and production
		    $warnFlag = 1;
		}
		elsif($_ =~ /\"gray\"/ && $_ =~ /\$VAR1 = \{\}|\$VAR1 = undef|\$VAR1 = \[\]|\-\-\- \{\}/){
		    $noDataFlag = 1;
		}
	    }
	}
    }
    close(READ);

    my $tipMessage = "";
    $tipMessage .= hspace(5) . "<b>Beta:</b>" . hspace(5) . $mysql{beta} . "<BR>" if exists $mysql{beta};
    $tipMessage .= hspace(5) . "<b>Production:</b>" . hspace(5) . $mysql{production} . "<BR>" if exists $mysql{production};
    $tipMessage .= hspace(5) . "<b>All:</b>" . hspace(5) . $mysql{all} . "<BR>" if exists $mysql{all};

    if($failFlag == 1){
	if(exists $failedVersion{production} && exists $failedVersion{beta}){
	    if($failedVersion{production} eq $failedVersion{beta}){
		return (4,"Error: $failedVersion{production}",$tipMessage);
	    }
	    else{
		return (4, "Error: production - $failedVersion{production}; beta - $failedVersion{beta}",$tipMessage);
	    }
	}
	elsif(exists $failedVersion{production}){
	    return (3, "Error: $failedVersion{production}",$tipMessage);
	}
	elsif(exists $failedVersion{beta}){
	    return (2, "Error: $failedVersion{beta}",$tipMessage);
	}
	else{
	    die "$0: unknown error handling.  ";
	}
    }
    elsif($warnFlag == 1){
	return (1, "Warning: difference",$tipMessage);
    }
    elsif($noDataFlag == 1){
	return (5, "No data",$tipMessage);
    }
    else{
	return (0, "OK",$tipMessage);
    }
}

##############################
# Split a test file into small test files with individual test cases (option 2)
##############################
sub _split_file{
    my $file = shift;
    my $test_file_dir = shift;
    my @files;

    open(READ, "$file")||next;
    my @header;
    while(<READ>){
	chomp;
	if($_ =~ /\[scope\]/){  # start of scope
	    push(@header,$_);
	    my @case;
	    my %info;
	    &_initialize_hash(\%info);

	    while(<READ>){
		chomp;
		if($_ =~ /----/){  # end of a test case
		    push(@case,$_);
		    foreach (keys %info){
			die "$0: test case information field $_ is undefined  " if $info{$_} eq undef;
		    }
    		    
		    # generate a unique random number for file name
		    my $fileName;
		    
		    while(1){
			my $lower = 1000000;
			my $upper = 9999999;
			my $random = &_random_number($lower,$upper);
			
			$fileName = $test_file_dir . $info{module} . "--" . $info{method} . "_" . $info{date} . "_". $info{user} . "_" . $info{time} . "_" . $random . ".txt";
			last if ! -e $fileName;			    
		    }

		    open(WRITE,">$fileName")||die "$0: cannot open file $fileName  ";
		    foreach (@header){
			print WRITE "$_\n";
		    }
		    foreach (@case){
			print WRITE "$_\n";
			if($_ =~ /^\#time/){
			    print WRITE "\t'-limit' => 4,\n";  # limit number of results to prevent huge queries
			}
		    }
		    print WRITE "\n====\n";
		    close(WRITE);
		    `chmod ugo+rw $fileName`;
		    push(@files,$fileName);

		    @case = ();
		    &_initialize_hash(\%info);
		    next;
		}
		elsif($_ =~ /====/){  # end of scope
		    last;
		}
		elsif($_ =~ /^\#user/){
		    $_ =~ /^\#user\: (.+)/;
		    $info{user} = $1;
		}
		elsif($_ =~ /^\#module/){
		    $_ =~ /^\#module\: (.+)/;
		    $info{module} = $1;
		}
		elsif($_ =~ /^\#date/){
		    $_ =~ /^\#date\: (.+)/;
		    $info{date} = $1;
		    $info{date} =~ s/\:|\s/-/g;
		}
		elsif($_ =~ /^\#time/){
		    $_ =~ /^\#time\: (.+)/;
		    $info{time} = $1;
		}
		elsif($_ =~ /^\#method/){
		    $_ =~ /^\#method\: (.+)/;
		    $info{method} = $1;
		    $info{method} =~ s/\(|\)//g;
		}
		push(@case,$_);
	    }
	}
	else{
	    push(@header,$_);
	}
    }
    close(READ);
    return \@files;
}

##############################
# Generate a random number (option 2)
##############################
sub _random_number{
    my $lower = shift;
    my $upper = shift;

    return int(rand($upper-$lower+1))+$lower;
}

##############################
# Initialize a hash (option 2)
##############################
sub _initialize_hash{
    my $hashRef = shift;
    $$hashRef{user} = undef;
    $$hashRef{module} = undef;
    $$hashRef{date} = undef;
    $$hashRef{time} = undef;
    $$hashRef{method} = undef;
}

##############################
# grab the paths of all files in a folder and its subfolders
##############################
sub _file_grabber{
    my $root_dir = shift;
    my $filesRef = shift;

    chdir($root_dir)||die "$0: cannot access directory $root_dir  ";
    my @files = `ls -l`;
    shift(@files);  # get rid of first element
    foreach my $file (@files){
	chomp $file;
	die "$0: weird file: $file  " if $file !~ /\s+\S+$/;
	$file =~ /\s+(\S+)$/;
	my $value = $1;
	if($file =~ /^d/){  # directory
	    my $directory = $root_dir . $value . "/";
	    &_file_grabber($directory,$filesRef);
	}
	else{  # a file
	    my $file_path = $root_dir . $value;
	    push(@$filesRef, $file_path);
	}
    }
}

##############################
# parse an API log (option 0, 2)
##############################
sub _parse_log{
    my $file = shift;
    my $num_days_to_check = shift;
    my $fileLimit = shift;  # number of test cases per log file
    my $methods_to_checkRef = shift;
    my $exclude_recent_days = shift;

    print "\t### Checking API from $file in the past $num_days_to_check to $exclude_recent_days days, maximum $fileLimit number of queries.\n\n";

    open(READ,"$file")||die "$0: Cannot open file $file.  ";
    my @data;	# an array of query records
    my %record;	# current record
    
    while(<READ>){
	chomp;
	if($_ =~ /^Query:/){	# end of a record, save and reset everything
	    # integrity check
	    my @keys = ('module','method','user','time','date','case');
	    my $okFlag = 1;
	    foreach (@keys){
		if($record{$_} eq undef || $record{$_} eq ""){
		    if($_ eq "time"){
			$record{$_} = "x";
			next;
		    }
		    $okFlag = 0;
		}
	    }	
	    if($okFlag){
		# check record date to see if it is out of date
		my $ok_to_test_record = check_date(-date=>$record{date}, -day_to_check=>$num_days_to_check);  # check if test case was used within specified date
		$ok_to_test_record &&= !check_date(-date=>$record{date}, -day_to_check=>$exclude_recent_days);  # check if test case was too recent
		# check to see if method is the one user wants to test
		my $ok_to_test_record1 = 0;
		my $methodCheckSize = @$methods_to_checkRef;
		if($methodCheckSize > 0){
		    foreach (@$methods_to_checkRef){
			if($record{method} =~ /$_/i){
			    $ok_to_test_record1 = 1;
			    last;
			}
		    }
		}

		if($ok_to_test_record && ($ok_to_test_record1 == 1 || $methodCheckSize == 0)){
		    # add record
		    my %tempRecord = %record;
		    push(@data,\%tempRecord);
		}
		# check number of records
		my $recordSize = @data;
		last if $recordSize >= $fileLimit;
	    }
	    %record = ();
	}
	elsif($_ =~ /^File: /){  # script running the query
	    $_ =~ /^File: (.+)/;
	    $record{file} = $1;
	}
	elsif($_ =~ /^\*\* Source \*\*/){	# calling method
	    my $firstCallingMethod;
	    my $callingModule;
	    while(<READ>){
		chomp;
		if($_ !~ /^[\w\d] \=\> /){
		    last;1
		}
		elsif($_ !~ /\'main\:\:/){
		    if($_ =~ /^[\w\d] \=\> [\w\d\-\.\/]+/){
			next;
		    }
		    elsif($_ !~ /Sequencing|alDente/i){
			next;
		    }
		    if($_ !~ /([\w\d\-\(\)]+)\:\:([\w\d\-\(\)]+)\'/){  # does not fit regex, skip
#			die "$0: Weird regex format: $_  ";
			next;
		    }
		    $_ =~ /([\w\d\-\(\)]+)\:\:([\w\d\-\(\)]+)\'/;
		    if(index($record{file},$1) != -1 || $firstCallingMethod =~ /$2/i){ # exclude any user's own script or similar method with different letter case
			next;
		    }
		    $firstCallingMethod = $2;
		    $callingModule = $1;
		    $firstCallingMethod = "get_sample_data" if $firstCallingMethod =~ /get_Clone_data/;
		}
	    }
	    $record{module} = $callingModule;
	    $record{method} = $firstCallingMethod;
	}
	elsif($_ =~ /^User: /){	# user
	    $_ =~ /^User: (.+)/;
	    $record{user} = $1;
	}
	elsif($_ =~ /Executed query in /){	# query duration
	    $_ =~ /Executed query in (\d+) second/;
	    $record{time} = $1;
	}
	elsif($_ =~ /^\d\d\d\d\-\d\d\-\d\d \d\d\:\d\d\:\d\d/){	# query date
	    $_ =~ /^(\d\d\d\d\-\d\d\-\d\d \d\d\:\d\d\:\d\d)/;
	    my $date = $1;
	    $date =~ s/\s|\:/-/g;
	    $record{date} = $date;
	}
	elsif($_ =~ /^\$VAR/){	# start of Data Dumper
	    my @lines;
	    while(<READ>){
		chomp;
		if($_ =~ /\;/){	# end of data structure
		    push(@lines,$_);
		    last;
		}
		push(@lines,$_);
	    }
	    pop(@lines);  # remove last line of dumper
	    $record{case} = \@lines;
	}
    }	
    close(READ);
    return \@data;
}

##############################
# write an API test file (option 0, 2)
##############################
sub _write_test_file{
    my $file = shift;
    my $outFile = shift;
    my $num_days_to_check = shift;
    my $fileLimit = shift;
    my $methods_to_checkRef = shift;
    my $exclude_recent_days = shift;

    my $data = &_parse_log($file,$num_days_to_check,$fileLimit,$methods_to_checkRef,$exclude_recent_days);
    
    my $dataSize = @$data;
    return if $dataSize < 1;
    open(WRITE,">$outFile")||die "$0: Cannot open file $outFile.  ";
    print WRITE "\#\t$file\n";
    print WRITE "[database]\n";
    print WRITE "(production)\tdbase=$dbase_prod_default\thost=$host_prod_default\tLIMS_user=$LIMS_user_default\tLIMS_password=$LIMS_password_default\tDB_user=$DB_user_default\tDB_password=$DB_password_default\tdebug=$debug_default\n";
    print WRITE "(beta)\tdbase=$dbase_beta_default\thost=$host_beta_default\tLIMS_user=$LIMS_user_default\tLIMS_password=$LIMS_password_default\tDB_user=$DB_user_default\tDB_password=$DB_password_default\tdebug=$debug_default\n";
    print WRITE "====\n";
    print WRITE "[scope]\n\n";

    foreach (@$data){
	my $caseRef = $$_{case};
	my $module = $$_{module};
	my $method = $$_{method};
	my $user = $$_{user};
	my $date = $$_{date};
	my $time = $$_{time};
	
	print WRITE "auto     $method\n";
	print WRITE "\#user: $user\n";
	print WRITE "\#module: $module\n";
	print WRITE "\#method: $method\n";
	print WRITE "\#date: $date\n";
	print WRITE "\#time: $time\n";

	foreach (@$caseRef){
	    print WRITE "\#" if $_ =~ /concat/;  # this solves an API problem trying to split the contents of concat by comma and putting stuff into @field_list
	    print WRITE "$_\n";
	}
	print WRITE "----\n\n";
    }
    print WRITE "====\n";
    close(WRITE);
    `chmod ugo+rw $outFile`;
}

##############################
# check whether a date is within x days from the current time
##############################
sub check_date{  
    my %args = @_;
    my $olddate = $args{-date};
    my $days_to_check = $args{-day_to_check};

    return 1 if $days_to_check eq undef;

    my $daysElapsed = day_elapsed($olddate);
    return 1 if $daysElapsed < $days_to_check;
    return 0;
}
