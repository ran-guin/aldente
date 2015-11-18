#!/usr/local/bin/perl

use strict;

#use warnings;

use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use lib $FindBin::RealBin . "/../lib/perl/Imported";

#use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use Imported::CGI_App::Application;

use RGTools::Process_Monitor;
use RGTools::RGIO;
use RGTools::Code;

use SDB::Installation;
use SDB::DBIO;
use SDB::HTML;
use SDB::SVN;

use alDente::System;
use Date::Calc;

use LampLite::Config;

my $command = shift @ARGV;

my $Config = LampLite::Config->new( -bootstrap => 1, -initialize=>$FindBin::RealBin . '/../conf/personalize.cfg');
my %Configs = %{$Config->{config}};

my $cversion = $Configs{custom};

#print Dumper \@ARGV;
if ( $ARGV[0] eq '-m' && $ARGV[2] =~ /custom\/(\w+)/ ) {
    $cversion = $1;
}

my ( $prod_host, $prod_dbase ) = get_host_db( $cversion, 'PRODUCTION' );
my ( $beta_host, $beta_dbase ) = get_host_db( $cversion, 'BETA' );
my ( $dev_host,  $dev_dbase )  = get_host_db( $cversion, 'DEV' );
my ( $test_host, $test_dbase ) = get_host_db( $cversion, 'TEST' );

Message("Using custom version: $cversion");
### STATIC Variables ###
my $tag_dir = $Configs{tag_validation_dir};

##############################
# my $system = new alDente::System();
#
# $system->load($cversion);

#my $compare_dbase      = $system->{COMPARE_DEV_DATABASE}; ## dev_dbase
#my $compare_host       = $system->{COMPARE_DEV_HOST};     ## dev_host

my ( $compare_host, $compare_dbase ) = get_host_db( $cversion, 'DEV' );

my @Controlled_version = ( 'production', 'test', 'beta' );
my $user               = 'super_cron_user';
my $project            = 'LIMS';

my $baseline;
my $exe_file = $0;
if ( $exe_file =~ /^(.*\/versions\/)(\w+?)\b/ ) { $baseline = $1 . $2 }

my $debug;
if ( $ARGV[-1] eq '-debug' ) { $debug = 1; pop @ARGV; Message("ARGV: @ARGV"); }

if ( $command =~ /help/ || !$command ) { print help(); exit; }

my $root = '/opt/alDente/versions/';

my $wdp = try_system_command("bash_command pwd -P");
my $wdl = try_system_command("bash_command pwd -L");

chomp $wdp;
chomp $wdl;

if   ( $wdp =~ /^$root\b/ || $wdl =~ /^$root\b/ ) { }
else                                              { Message("Must run from version within root directory: $root (not: $wdp / $wdl) "); exit; }

$wdp =~ s/$root//;
$wdl =~ s/$root//;

my $SVN = new SDB::SVN();

# $SVN->load_options();

if ( $command eq 'diff' && int(@ARGV) == 1 ) {
    Message("*** Using svn diff wrapper on $wdp *** \n");

    print $SVN->svn_diff( @ARGV, -debug => $debug );
    exit;
}
elsif ( $command eq 'co' || $command eq 'checkout' ) {
    my $url  = shift @ARGV;
    my $path = shift @ARGV;
    checkout( -url => $url, -path => $path );
    exit;
}

# elsif ( $command eq 'test' ) {
#    my $ok = check_unit_tests( \@ARGV, -prompt => 'a' );
#}
elsif ( $command eq 'up' || $command eq 'update' ) {
    my $user = try_system_command('whoami');
    my @read_only_versions = ( 'production', 'beta', 'test' );
    if ( my @rov = grep /\b$wdp|$wdl\b/, @read_only_versions ) {
        Message "\n*** Error: cannot run update on '$rov[0]' - please use 'svn hotfix' wrapper ***\n";
        exit;
    }

    my @quoted = map {
        if   (/\s/) {"\"$_\""}
        else        {$_}
    } @ARGV;
    my $parameters = join ' ', @quoted;
    Message("svn $command $parameters");
    print try_system_command("svn $command $parameters");
    exit;
}
elsif ( $command eq 'hotfix' ) {
    my $command  = "whoami";
    my $response = try_system_command($command);
    if ( $response !~ /aldente/i ) {
        Message "Hotfix can only be done by aldente";
        exit;
    }
    hotfix();
    exit;
}
elsif ( $command eq 'tag' ) {
    my $test = 0;
    if ($debug) {
        $test = 1;
    }

    # Tagging Can only be done by alDente
    my $command  = "whoami";
    my $response = try_system_command($command);
    if ( $response !~ /aldente/i ) {
        Message "Tagging can only be done by aldente";
        exit;
    }

    my $branch;

    #####$system variable is created with generic conf file, not custom specific so for tagging, we need to fill with customs specific attributes
#    $system->load( -custom => $Configs{custom} );

    #$compare_dbase = $system->{COMPARE_DEV_DATABASE};
    #$compare_host  = $system->{COMPARE_DEV_HOST};

    ### Temporarily Solution
    # Tagging Must be done in beta branch
    if ( $FindBin::RealBin =~ /^.+\/(\w+)\/\w+$/ ) { $branch = $1 }
    else                                           { Message "Failed to find branch"; exit; }

    if ( $branch eq 'beta' ) {
        Message "Begining tagging process";
    }
    elsif ($test) {
        Message("Testing, $branch branch allowed");
    }
    else {
        Message "Tagging MUST be done in beta branch only";
        exit;
    }

    my $ok = tag( -test => $test );
    exit;
}
elsif ( $command eq 'last_tag_date' ) {

    my $last_tag_date = get_latest_tag_date();
    Message $last_tag_date;
    exit;
}
elsif ( $command eq 'commit' || $command eq 'jiralog' || $command eq 'test' ) {

    my ( $ticket, $message );

    if ( $command ne 'test' ) {
        $message = shift @ARGV;
        if ( $message =~ /^-m/ ) {
            $message = shift @ARGV;
            if ( !$message ) { help(); exit; }
        }
        else {
            help();
            exit;
        }

        ### Testing mode does not require ticket reference (no commits) ###
        if ( $message =~ /\b$project\-(\d+)\b/ ) {
            ## message already includes Jira reference ##
            $ticket = $project . '-' . $1;
        }
        else {
            ## enforce jira ticket format ##
            while ( $ticket !~ /(\d+)$/ ) {
                $ticket = Prompt_Input( -prompt => "\nPlease enter Proper JIRA ticket id (eg '1234' or 'LIMS-1234')\n", -format => '\d\d\d\d' );
                if ( $ticket eq 'xxxx' ) {last}    ## allow over-ride feature to streamline exceptional cases (TRIVIAL updates only) ##
            }
            if ( $ticket =~ /^\d/ ) { $ticket = $project . '-' . $ticket }
            if ( $ticket =~ /\d/ ) { $message .= "; $ticket" }
        }
    }

    my $files = join ' ', @ARGV;
    my %Files = get_file_type_list( -file => $files );

    ## enforce file specification ##
    while ( !$files ) {
        $files = Prompt_Input( -prompt => "\nPlease indicate target file(s) or directories to commit\n" );
    }

    Message("getting JIRA Ticket $ticket");
    my $jira = find_ticket($ticket);

    if ( $command eq 'jiralog' ) {
        log_time( -jira => $jira, -ticket => $ticket, -comment => $message );
    }
    elsif ( $command eq 'test' ) {
        my $validated = pre_commit_tests( -files => \%Files );
    }
    elsif ( $command eq 'commit' ) {
        my $dbc = new SDB::DBIO(
            -host    => $dev_host,
            -dbase   => $dev_dbase,
            -user    => $user,
            -connect => 1
        );

        my $validated = pre_commit_tests( -dbc => $dbc, -files => \%Files, -prompt => 1 );
        if ( !$validated ) { Message("Failed pre-commit tests - Aborting\n"); exit; }

        Message("Committing Changes for $ticket...");
        my $ok = commit_ticket( -ticket => $ticket, -files => \%Files, -comment => $message, -jira => $jira, -dbc => $dbc );
        if ( !$ok ) { Message("**  Error Committing Code **") }

        post_commit( -files => \%Files, -ticket => $ticket, -message => $message, -committed => $ok );

    }
    else {
        Message("'$command' not recognized");
        help();
    }

}
else {
    Message("Require Command ($command)");
    my @quoted = map {
        if   (/\s/) {"\"$_\""}
        else        {$_}
    } @ARGV;
    my $parameters = join ' ', @quoted;
    Message("svn $command $parameters");

    print `svn $command $parameters`;
    exit;
}

exit;

####################################################################################
###########################   INTERNAL FUNCTIONS   #################################
####################################################################################

######################### MAIN FUNCTIONS #########################
#######################
sub checkout {
#######################
    my %args = filter_input( \@_ );
    my $url  = $args{-url};
    my $path = $args{-path};
    my %input;

##### TEMP
    my @fields = ( 'DATABASE', 'SQL_HOST', 'URL_domain', 'custom', 'version_name', 'code_reviewer' );
    my @types  = ( 'database', 'database', 'web',        'web',    'web',          'web' );
##### TEMP SHOULD BE REPLACED WIH CONF FILE
    my $index;

    for my $field (@fields) {
        my $prompt = Prompt_Input( -prompt => "Please enter $field: " );
        $input{$field}{default} = '';
        $input{$field}{type}    = $types[$index];
        $input{$field}{value}   = $prompt;
        $index++;

        unless ($prompt) {
            Message "All enteries are mandatory. ";
            exit;
        }
    }
    my $content = get_file_content( -content => \%input );

    my $file = $path . "/conf/personalize.conf";
    $SVN->checkout( -url => $url, -path => $path );

    require IPC::Run3;
    IPC::Run3::run3( "chown -R :lims $path/conf/", \undef, \undef, \undef );
    IPC::Run3::run3( "chmod g+s $path/conf/",      \undef, \undef, \undef );

    create_conf_file( -file => $file, -content => $content );
    return;
}

#######################
sub tag {
#######################

    my %args = filter_input( \@_ );
    my $root = $FindBin::RealBin . "/..";
    my $test = $args{-test};

    # Update Beta Code and Save Revision
    if ( !$test ) {
        $SVN->update( -file => $root );
    }
    else {
        Message("Testing, update beta code skipped");
    }

    Message("Connecting to $beta_host : $beta_dbase") if ($test);
    my $dbc = new SDB::DBIO(
        -host    => $beta_host,
        -dbase   => $beta_dbase,
        -user    => $user,
        -connect => 1
    );

    my ($code_version) = $dbc->Table_find( 'Version', 'Version_Name', " WHERE Version_Status = 'In use'" );
    my $svn_revision = $SVN->get_revision( -file => $root );
    my $tag_dir = get_tag_validation_dir( -root => $root, -revision => $svn_revision, -code_version => $code_version );
    Message("root=$root\nsvn_revision=$svn_revision\ntag_dir=$tag_dir") if ($test);

    my $started_tags = find_available_tags( -type => 'started' );
    if ($started_tags) {
        Message "There is currently tagging in process.  Exiting ...";
        exit;
    }

    # Start Tagging Process
    SDB::Installation::tag( -type => 'start', -dir => $tag_dir, -revision => $svn_revision );

    # Instal All Commited Patches
    my $command = " $root/bin/upgrade_DB.pl -user $user -v $beta_dbase:$svn_revision -dbase $beta_dbase -host $beta_host -version $code_version  
            1> $tag_dir/upgrade.$beta_dbase:$svn_revision.$code_version.log 2> $tag_dir/upgrade.$beta_dbase:$svn_revision.$code_version.err";
    if ($test) {
        Message "Upgrading database ... (testing, skipped)";
        Message $command;
    }
    else {
        Message "Upgrading database ... ";
        Message $command;
        try_system_command($command);
    }

    my $last_tag_time = get_latest_tag_date();

    # Create of changes
    my $command = " $root/bin/create_closed_jira_report.pl -since '$last_tag_time' > $tag_dir" . "/changes_since_last_tag.html";
    try_system_command($command);
    Message $command;

    # Run Validation Tests
    Message "=============  Validation Tests =============";
    my $test_db = $compare_host . ":" . $compare_dbase;
    my $validation_test_pass;
    if ( !$test ) {
        $validation_test_pass = alDente::Validation::run_validation_tests( -dbc => $dbc, -output_dir => $tag_dir, -compare_db => $test_db, -revision => $svn_revision, -stage => 'Tag' );
    }
    else {
        $validation_test_pass = 1;
        Message("compare to $test_db");
        Message("Testing, validation tests skipped");
    }

    Message "=============================================";
    if ( !$validation_test_pass ) {
        SDB::Installation::tag( -type => 'failed', -dir => $tag_dir, -revision => $svn_revision );
        return;
    }

    #{ Message "All tests passed successfully.  " }

    delete_failed_tags();

    # Finalize Tag
    SDB::Installation::tag( -type => 'tag', -dir => $tag_dir, -revision => $svn_revision );

    Message "========== Rsync Alpha and Beta Code ========";
    if ( !$test ) {
        my $feedback;
        my $command = " rsync -avz --delete --exclude='personalize.cfg' /opt/alDente/versions/beta/ /home/aldente/WebVersions/beta/ 1>> /opt/alDente/www/dynamic/logs/beta_code_sync.log 2>/opt/alDente/www/dynamic/logs/beta_code_sync.err";
        $feedback = try_system_command($command);
        print "FB: $feedback";

        my $command = " rsync -avz --delete --exclude='personalize.cfg' /opt/alDente/versions/alpha/ /home/aldente/WebVersions/alpha/ 1>> /opt/alDente/www/dynamic/logs/alpha_code_sync.log 2>/opt/alDente/www/dynamic/logs/alpha_code_sync.err";
        $feedback = try_system_command($command);
        print "FB: $feedback";
    }
    else {
        Message("Testing, Rsync skipped");
    }

    return 1;

}

#
# Prior to commit:
#   * check svn is up to date
#   * test compilation
#   * run_validation_tests
#
# Return: 1 on success
#######################
sub pre_commit_tests {
#######################
    my %args   = filter_input( \@_ );
    my $files  = $args{-files};
    my $dbc    = $args{-dbc};
    my $prompt = $args{-prompt};

    my %Files = %$files;

    Message("Checking if files are up to date...");
    ## If specific files are specified, check if each file is up to date
    ## If only directory is specified, check if the directory is up to date

    my $file_list = hash_to_list( \%Files );

    my $is_out_of_date = $SVN->is_out_of_date( -file => $file_list );
    if ($is_out_of_date) {
        Message("Some of the files or directories that you have specified are out of date. Please svn up first.");
        return 0;
    }
    else { Message("Files are up to date"); }

    Message("Get file type list...");

    my $pm_files = $Files{pm};
    my $pl_files = $Files{pl};

    my @perl_files;
    if ($pm_files) { push @perl_files, @{$pm_files} }
    if ($pl_files) { push @perl_files, @{$pl_files} }

    compile_test($files);

    my $passed = check_unit_tests( -files => \@perl_files, -prompt => $prompt );

    ### validation tests
    if ( $dbc && $pm_files ) {
        Message "=============  Validation Tests =============";
        my $test_db = $compare_host . ":" . $compare_dbase;

        my $module_list = join ',', @{$pm_files};
        Message("Testing: $module_list\n");

        my $validation_test_pass = alDente::Validation::run_validation_tests( -dbc => $dbc, -compare_db => $test_db, -module => $module_list, -stage => 'Commit' );
        Message "=============================================";
        if ( !$validation_test_pass ) {return}
    }

    return $passed;
}

###################
sub compile_test {
###################
    my $files = shift;
    my %Files = %$files;

    ## Compile Test ##
    my @compile_tests = ( $FindBin::RealBin . '/../cgi-bin/barcode.pl' );
    if ( $Files{pl} ) { push @compile_tests, @{ $Files{pl} } }

    Message("Ensure code is compiling...");

    foreach my $compile_test (@compile_tests) {
        my $ok = $SVN->compile_test($compile_test);
        if ( !$ok ) { Message("Compilation failed for $compile_test - Aborting\n"); return 0; }
    }

    return 1;
}

#
# Commit code and update JIRA and update version tracker as required
#
#######################
sub commit_ticket {
#######################
    my %args    = filter_input( \@_, -mandatory => 'ticket,files,comment' );
    my $ticket  = $args{-ticket};
    my $files   = $args{-files};
    my $comment = $args{-comment};
    my $jira    = $args{-jira};
    my $dbc     = $args{-dbc};

    ### break all files into categories
    my $patch_pass;

    my %Files      = %$files;
    my $patch_list = $Files{pat};
    if ($patch_list) {
        Message "=============  Patch Section ================";
        $patch_pass = check_patch_status( -patches => $patch_list, -dbc => $dbc );
        unless ($patch_pass) {
            Message 'Failed patch section, exiting ... ';
            Message "=============================================";
            return;
        }
        Message "=============================================";
    }

    ### add patch to version tracker file
    if ( $patch_list && $patch_pass ) {
        my $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );
        my $vt_files = $install->get_Version_Tracker_Files();
        for my $vt_file (@$vt_files) {
            my $ok = $SVN->commit( -file => $vt_file, -message => "updating the version_tracker file" );
        }
    }

    ### commiting files and tags
    my $file_list = hash_to_list( \%Files );

    my $ok = $SVN->commit( -file => $file_list, -message => $comment );

    if ( $ok !~ /Transmitting/i ) {
        Message($ok);
        if ( !$ok ) { Message("svn version is already up to date for $file_list.  To simply log time for previously committed work, replace commit with 'jiralog' and run the same command") }
        return 0;
    }

    my $prompt;
    while ( $prompt !~ /^[nbx]$/i ) {
        $prompt = Prompt_Input( -prompt => "Have you tested the changes ? [n - No; b - basic testing; x - extensive testing" );

        my $level;
        if    ( $prompt =~ /b/i ) { $level = 'Basic' }
        elsif ( $prompt =~ /x/i ) { $level = 'Extensive' }
        if    ($level) {
            $jira->add_comment( -issue_id => $ticket, -comment => "$level Testing was completed" );
        }
    }

    SDB::Installation::record_commit( -files => $file_list, -ticket => $ticket, -root => $FindBin::RealBin );
    log_time( -jira => $jira, -ticket => $ticket, -comment => $comment );

    return 1;
}

#
# After the commit:
#   * Critique the code (commit separately)
#   * run perltidy (commit separately)
#
###################
sub post_commit {
###################
    my %args      = filter_input( \@_ );
    my $files     = $args{-files};
    my $committed = $args{-committed};
    my $ticket    = $args{-ticket};
    my $message   = $args{-message};

    my %Files = %$files;

    my $ok = 1;

    my @perl_files;
    if ( $Files{pm} ) { push @perl_files, @{ $Files{pm} } }
    if ( $Files{pl} ) { push @perl_files, @{ $Files{pl} } }

    if ($committed) {
        Message("(committed)");

        my $message_cr = "\nDo you want to create a crucible review for the code changes? (Y/N)";
        my $prompt = Prompt_Input( -prompt => $message_cr );
        if ( $prompt eq 'Y' || $prompt eq 'y' ) {
            $SVN->review_change( -ticket => $ticket, -file => $files, -comment => $message );
        }
        Message("Script is done...");

        foreach my $tidy_file (@perl_files) {
            if ( !$tidy_file ) {next}

            print "\n\n*** Running Perltidy ...***\n\n";
            my $tidied = try_system_command("perltidy.pl -file $tidy_file -overwrite -swap -html");
            print $tidied;
            if ( $tidied =~ /successfully tidied/ ) {
                ## commit tidied version of code ##
                my $ok = $SVN->commit( -file => $tidy_file, -message => "perltidy only" );
                ## Delete temp files created by perltidy (Except .ERR files) ##
                delete_Tidy_files( -file => $tidy_file );
            }

            $ok = compile_test($files);
        }

    }
    else { Message("(not committed)") }

    Message("Critiquing code.... (status: $ok)");
    $SVN->critique_code( -files => \@perl_files, -severity => 'gentle', -warning_message => "*** Please Fix these code issues now and recommit code ***" );
    return $ok;
}

#######################
sub hotfix {
#######################
    my %args        = filter_input( \@_ );
    my $root        = "/opt/alDente/versions/";
    my $test_branch = $root . 'test';
    my $prod_branch = $root . 'alpha';
    my $test        = 1;

    my $test_rev = $SVN->get_revision( -file => $test_branch );
    my $prod_rev = $SVN->get_revision( -file => $prod_branch );

    if ( $prod_rev > $test_rev ) {
        Message "Warning: Current Production Revision [$prod_rev] is higher than Test Revision [$test_rev]";
    }

    my ( $tag_choice, $update_rev ) = prompt_tag_choice( -revision => $test_rev );
    unless ($tag_choice) {return}

    my $dbc = new SDB::DBIO(
        -host    => $Configs{TEST_HOST},
        -dbase   => $Configs{TEST_DATABASE},
        -user    => $user,
        -connect => 1
    );
    my $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );
    my $patch_version = $install->get_last_patch_version( -revision => $update_rev, -root => $test_branch );
    my $hotfix_dir = $install->get_hot_fix_dir( -revision => $update_rev );

    upgrade_db( -dbase => $Configs{TEST_DATABASE}, -host => $Configs{TEST_HOST}, -version => $patch_version, -dir => $hotfix_dir, -test => $test );
    $SVN->update( -revision => $update_rev, -file => $test_branch, -test => $test );

    # Run Validation Tests
    Message "=============  Validation Tests =============";
    my $test_db = $compare_host . ":" . $compare_dbase;
    my $validation_test_pass;
    if ( !$test ) {
        $validation_test_pass = alDente::Validation::run_validation_tests( -dbc => $dbc, -output_dir => $hotfix_dir, -compare_db => $test_db, -revision => $update_rev, -stage => 'Hotfix' );
    }
    else {
        $validation_test_pass = 1;
    }

    if ( !$validation_test_pass ) {
        Message "Failed Validation Tests!! exiting ...";
        exit;
    }
    else {
        Message "Finished test sucessfully";
    }
    Message "=============================================";

    ## ask if ready to hotfix production
    Message "";
    Message "Are you sure you wish to update production code [  $prod_branch to revision $update_rev] and production database [ $prod_host:$prod_dbase to patch version $patch_version]?";

    my $prompt = Prompt_Input( -prompt => "Type 'YES' to continue" );
    if ( $prompt ne 'YES' ) {exit}

    # update production database
    my $dbc = new SDB::DBIO(
        -host    => $prod_host,
        -dbase   => $prod_dbase,
        -user    => $user,
        -connect => 1
    );
    my $prd_hotfix_dir = $install->get_hot_fix_dir( -revision => $update_rev, -type => 'production' );

    upgrade_db( -dbase => $prod_dbase, -host => $prod_host, -version => $patch_version, -dir => $prd_hotfix_dir, -test => $test );

    # udpate production code

    $SVN->update( -revision => $update_rev, -file => $prod_branch, -test => $test );
    Message "Hotfix was sucessfull";

    return;

}

######################### SECONDARY FUNCTIONS #########################
####################
sub delete_Tidy_files {
####################
    my %args       = filter_input( \@_ );
    my $file       = $args{-file};
    my @post_fixes = ( '.tdy', '.utdy' );

    for my $pf (@post_fixes) {
        my $tdy_file = $file . $pf;
        if ( -e $tdy_file ) {
            my $response = try_system_command("rm $tdy_file");
            Message $response if $response;
        }
    }

    Message 'Removed extra perltidy files ...';
    return;

}

####################
sub upgrade_db {
####################
    my %args    = filter_input( \@_ );
    my $dbase   = $args{-dbase};
    my $host    = $args{-host};
    my $version = $args{-version};
    my $test    = $args{-test};
    my $debug   = $args{-debug} || $test;
    my $dir     = $args{-dir} || $Configs{URL_temp_dir};

    Message "Upgrading database $dbase on $host to version $version";
    my $command = $FindBin::RealBin . "/upgrade_DB.pl -user $user -v $dbase:$version -dbase $dbase -host $host -version $version 1> $dir/upgrade.$host:$dbase.log 2> $dir/upgrade.$host:$dbase.err";
    Message $command if $debug;

    if ( !$test ) {
        my $result = try_system_command($command);
        Message $result if $result;
    }

    return;

}

####################
sub delete_failed_tags {
####################
    Message "Removing Failed tags";
    my @failed = find_available_tags( -type => 'failed', -directory => 1 );
    for my $dir (@failed) {
        my $command = "rm -r $dir";
        Message "** Removing directory:  $dir";
        my $result = try_system_command($command);
        Message $result if $result;
    }
    return 1;
}

####################
sub get_latest_tag_date {
####################
    my @tags        = find_available_tags();
    my $latest_time = 0;

    if ( scalar(@tags) < 1 ) {
        @tags = find_available_tags( -all => 'yes' );
    }

    foreach my $tag (@tags) {
        $tag =~ /^(\d{12})/;
        if ( $1 > $latest_time ) {
            $latest_time = $1;
        }
    }

    my $year   = substr( $latest_time, 0,  4 );
    my $month  = substr( $latest_time, 4,  2 );
    my $day    = substr( $latest_time, 6,  2 );
    my $hour   = substr( $latest_time, 8,  2 );
    my $minute = substr( $latest_time, 10, 2 );

    #my ($next_year, $next_month, $next_day) = Date::Calc::Add_Delta_Days($year, $month, $day, 1);

    my $last_tag_time = "$year-$month-$day $hour:$minute";

    return $last_tag_time;
}

####################
sub find_available_tags {
####################
    my %args          = filter_input( \@_ );
    my $type          = $args{-type} || 'tag';
    my $get_directory = $args{-directory};       ## return the Full directory path of the tag instead of the tag file
    my $larger_than   = $args{-larger_than};     ## only return revision larger than this
    my $smaller_than  = $args{-smaller_than};    ## only return revision smaller than this
    my $all           = $args{-all};             ## if defined, return tags from previous releases as well

    my $path;
    my @tags;
    my @dir_tags;
    my $command;

    if ( defined $all ) {
        $path    = $Configs{tag_validation_dir};
        $command = "ls $path" . "/*/*/*." . $type;
    }
    else {
        $path    = get_tag_validation_dir();
        $command = "ls $path" . "*/*." . $type;
    }

    my @results = split /\s/, try_system_command($command);

    for my $result (@results) {
        if ( $result =~ /^.+\/rev\_(\d+)\/(.+)\.$type$/ ) {
            my $dir  = 'rev_' . $1;
            my $file = $2;
            my $rev  = $1;
            if ( $larger_than  && $rev < $larger_than )  {next}
            if ( $smaller_than && $rev > $smaller_than ) {next}
            push @dir_tags, $path . $dir;
            push @tags,     $file;
        }
    }

    if ($get_directory) {
        return @dir_tags;
    }
    else {
        return @tags;
    }

}

####################
sub prompt_tag_choice {
####################
    my %args     = filter_input( \@_, -mandatory => "revision" );
    my $revision = $args{-revision};
    my @tags     = find_available_tags( -larger_than => $revision );

    unless ( $tags[0] ) {
        Message "There are no NEW tags available (Your version: $revision)";
        exit;
    }

    while (1) {
        my $index;
        my @revs;
        Message "===============================================";
        for my $tag (@tags) {
            if ( $tag =~ /^(\d+)\_\_rev\_(\d+)$/ ) {
                my $timestamp = $1;
                my $rev       = $2;
                my $year      = substr( $timestamp, 0, 4 );
                my $month     = substr( $timestamp, 4, 2 );
                my $day       = substr( $timestamp, 6, 2 );
                $index++;
                Message "$index - Tag $index: revision $rev (Tagged on $year-$month-$day)";
                push @revs, $rev;
            }
        }
        Message "A - Abort";
        Message "===============================================";
        my $prompt = Prompt_Input( -prompt => "Please select the version you wish to update to" );

        if ( $prompt =~ /^A/i ) {exit}
        if ( $prompt <= $index && $prompt =~ /^\d+$/ && $prompt ) {
            return ( $tags[ $prompt - 1 ], $revs[ $prompt - 1 ] );
        }
        Message "Invalid Choice";
    }

    return;
}

####################
sub create_conf_file {
####################
    my %args    = filter_input( \@_ );
    my $content = $args{-content};
    my $file    = $args{-file};

    open my $TEMP, '>', $file or die "CANNOT OPEN $file";

    my $command  = "echo '$content' >> $file ";
    my $response = try_system_command($command);
    Message $response if $response;

    close $TEMP;
    return;
}

####################
sub get_file_content {
####################
    my %args    = filter_input( \@_ );
    my $content = $args{-content};

    my %content;
    if ($content) { %content = %$content }

    my $file = "<configs>\n";
    for my $item ( keys %content ) {
        $file .= "  <" . $item . ' default="' . $content{$item}{default} . '" type="' . $content{$item}{type} . '" value="' . $content{$item}{value} . '" />' . "\n";
    }

    $file .= "</configs>";

    return $file;
}

####################
sub find_ticket {
####################
    my $ticket = shift;

    eval {"require Plugins::JIRA::Jira"};

    my $user      = 'limsproxy';
    my $password  = 'noyoudont';             ## <CONSTRUCTION> remove hardcoding
    my $jira_wsdl = $Configs{'jira_wsdl'};

    my $jira = Jira->new( -user => $user, -password => $password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
    my $login = $jira->login();

    my $ticket_info = $jira->get_issue( -issue_id => $ticket );

    my $desc    = $ticket_info->{description};
    my $summary = $ticket_info->{summary};
    my $status  = $ticket_info->{status};
    my $title   = "** Ticket: $summary [$status] **";
    print "$title\n";
    print "*" x length($title);
    if ($desc) { print "\n$desc\n" }
    print "*" x length($title);
    print "\n";
    return $jira;
}

#############
sub help {
#############

    print <<HELP;

Syntax:

svn commit -m '<message>' <file1> <file2>

svn diff <file> 

Options:

svn jiralog -m '<message>'     <--- use 'jiralog' instead of 'commit' to log time for already committed code

svn diff <file> -debug         <--- prints detailed diffs for all files (default if only one file diff found)

HELP

    return;
}

####################################
sub check_patch_status {
####################################
    my %args    = filter_input( \@_ );
    my $patches = $args{-patches};       ## comma deliminated list of patches (may or may not contain .pat postfix)
    my $dbc     = $args{-dbc};

    my $failed;

    my $dbc_cmp = new SDB::DBIO(
        -host    => $compare_host,
        -dbase   => $compare_dbase,
        -user    => $user,
        -connect => 1
    );

    for my $patch ( @{$patches} ) {
        my $patch_name;

        if   ( $patch =~ /.*\/(.+)\.pat/ ) { $patch_name = $1 }
        else                               { $patch_name = $patch }
        my $dev_status = SDB::Installation::get_Patch_Status( undef, -name => $patch_name, -dbc => $dbc );
        my $cmp_status = SDB::Installation::get_Patch_Status( undef, -name => $patch_name, -dbc => $dbc_cmp );
        Message "Patch $patch_name is $dev_status on $dev_dbase";
        Message "Patch $patch_name is $cmp_status on $compare_dbase";
        if ( $dev_status !~ /Installed/ ) {
            Message "Patch $patch_name should be installed on $dev_dbase before you can proceed.";
            return;
        }
        if ( $cmp_status eq 'not found' ) {
            Message "Installing patch $patch_name on $compare_dbase";
            install_patch( -dbc => $dbc_cmp, -file => $patch_name . ".pat" );
            $cmp_status = SDB::Installation::get_Patch_Status( undef, -name => $patch_name, -dbc => $dbc_cmp );
            Message "Patch $patch_name is now $cmp_status on $compare_dbase";
        }

        if ( $cmp_status ne 'Installed' ) {
            return;
        }
    }
    return 1;
}

#############################
sub install_patch {
#############################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $file       = $args{-file};
    my $confirmed  = $args{-confirmed};
    my $install    = new SDB::Installation( -dbc => $dbc, -simple => 1 );
    my $patch_info = $install->get_patch_info( -file => $file );
    my $patch_version;

    if ($patch_info) {
        my %info;
        if ($patch_info) { %info = %$patch_info }
        my $patch_name   = $info{PATCH};
        my $package_name = $info{PACKAGE};
        my $category     = $info{CATEGORY};
        my $version      = $info{VERSION};
        my $prompt;

        if ( !$package_name ) { Message "No Package found fo patch $file" }
        if ( !$category )     { Message "No Category found fo patch $file" }
        if ( !$version )      { Message "No Version found fo patch $file" }
        if ( $package_name && $category && $version ) {
            Message "$patch_name - $version -  $package_name [ $category ] ";
            my $message = "Do you wish to install this patch? (Y/N)";
            $prompt = Prompt_Input( -prompt => $message ) unless $confirmed;
        }
        else {
            exit;
        }
        if ( ( $prompt =~ /^y$/i || $confirmed ) ) {
            $patch_version = $install->install_Patch(
                -patch         => $patch_name,
                -package       => $package_name,
                -category      => $category,
                -version       => $version,
                -group_version => $patch_version
            );
        }
        else {
            Message "You have chosen to exit";
            exit;
        }
    }
    else {
        Message "Could not complete the installation of $file";
        exit;
    }

}

#######################
sub get_file_type_list {
#######################
    # Input:
    #   Space seperated list of
    # output:
    #   hash of file types
    #   keys: type of file
    #   values: comma seperated list of files
#######################

    my %args  = filter_input( \@_ );
    my $files = $args{-file};

    my @files = split /\s/, $files;
    my @pm;
    my @other;
    my @pat;

    my %result;
    for my $file (@files) {
        if ( $file =~ /\.(\w+)$/ ) {
            push @{ $result{$1} }, $file;
        }
    }

    return %result;
}

#
# Reverse conversion of hash to delimited string;
#
#
###################
sub hash_to_list {
###################
    my $hash = shift;
    my $delim = shift || ' ';

    my %Files = %$hash;
    my $file_list;
    foreach my $type ( keys %Files ) {
        if ( $file_list && @{ $Files{$type} } ) { $file_list .= ',' }
        $file_list .= join ',', @{ $Files{$type} };
    }
    $file_list =~ s/,/$delim/g;

    return $file_list;
}

#######################
sub get_tag_validation_dir {
#######################
    # Check to see if directory exists
    #
#######################
    my %args         = filter_input( \@_ );
    my $root         = $args{-root};
    my $revision     = $args{-revision};
    my $code_version = $args{-code_version};
    my $path         = $Configs{tag_validation_dir};

    if ( !$revision && $root ) {
        $revision = $SVN->get_revision( -file => $root );
    }

    if ( !$code_version ) {
        $code_version = SDB::Installation::get_current_version();
    }

    my $dir;
    if ($revision) {
        $dir = &create_dir( -path => $path . "/$code_version", -subdirectory => "rev_" . $revision );
    }
    else {
        $dir = $path . "/$code_version/";
    }
    return $dir;
}

#
# Log time to jira ticket
#
#
##################
sub log_time {
##################
    my %args    = filter_input( \@_, -mandatory => 'jira,ticket,comment' );
    my $jira    = $args{-jira};
    my $ticket  = $args{-ticket};
    my $comment = $args{-comment};

    my $log = '';

    # enforce logged time format ##
    while ( $log !~ /^\d+[mhd]/ ) {
        $log = Prompt_Input( -prompt => "\nPlease log time in hours or days (eg 4h or 2d)  To update estimate add second argument for remaining estimate (eg '2h 1h')\n" );
    }

    my $new_estimate;
    if ( $log =~ /^(\d\w+)\s+(\d+\w+)/ ) {
        $log          = $1;
        $new_estimate = $2;
    }

    my $ticket_info = $jira->get_issue( -issue_id => $ticket );
    my $status = $ticket_info->{status};

    if ( $status eq Jira::status('Closed') ) {
        $jira->update_status( -issue_id => $ticket, -action => 'Reopen', -add_comment => 'reopen only to log time' );
        Message("Reopening ticket to log time");
    }

    #elsif ( $status eq Jira::status('Open') ) {
    #    $jira->update_status( -issue_id => $ticket, -action => 'Start Progress' );
    #    Message("Starting Progress for ticket");
    #}

    my $logged = $jira->log_time( -issue_id => $ticket, -log_time => $log, -comment => $comment, -new_estimate => $new_estimate );

    #    Message("Logged: $logged.");

    if ( $status eq Jira::status('Closed') ) {
        Message("Re-closing issue");
        $jira->update_status( -issue_id => $ticket, -action => 'Close' );
    }

    return;
}

#
# wrapper to check that a given file has unit tests applicable to committed changes
#
# (finds all subroutines modified, and ensures that unit test has also been updated for each)
# (option should be available to skip unit tests manually for specific functions, but only if specified)
#
# Return: 1 on success
###########################           GOTAA BE MOVED TO VALDIATION
sub check_unit_tests {
###########################
    my %args   = filter_input( \@_, -args => 'files' );
    my $files  = $args{-files};
    my $prompt = $args{-prompt};                          ## flag to enable prompt for user to skip specific tests if desired (or preset to s(kip) or a(bort) on failure ##

    if ( ref $files eq 'SCALAR' ) { $files = [$files] }

    print "\nChecking Unit Tests\n********************\n";
    my $ok = 1;

    my $failed = 0;
    foreach my $file (@$files) {
        my @subs = get_changed_subs($file);
        Message("Check $file");
        if (@subs) {
            print "Changes found in:\n********************\n";
            print join "\n", @subs;
            print "\n\n";
        }

        my %Run_modes;
        if ( $file =~ /_App\./ ) { %Run_modes = %{ Code::get_run_modes($file) } }

        my @failed;
        foreach my $sub (@subs) {
            ## ignore main body changes for pl files (subroutines may be moved to module for unit testing)
            if ( $file =~ /\.pl/ && $sub eq 'main' ) {next}

            my $passed = find_unit_tests( -file => $file, -method => $sub, -prompt => $prompt, -run_modes => \%Run_modes );
            if ( !$passed ) {
                push @failed, "$file : $sub";
                $ok = 0;
                $failed++;
            }
        }

        if (@failed) {
            print "*" x 48;
            print "\nFailed unit test check for " . int(@failed) . " method(s)/run_mode(s)\n";
            print "*" x 48;
            print "\n";
        }
    }

    if ($failed) {
        Message("\n************************\n**  FAILED UNIT TESTS **\n************************\n");
        return 0;
    }
    else {
        Message("\n\n********* Unit Tests OK ***********\n\n");
    }

    return $ok;
}

#
# Find methods changed within commit using svn diff
# (uses 'sub ...' to find method prior to change made)
#
# Return: array of modified methods
###########################         GOTAA BE MOVED TO VALDIATION
sub get_changed_subs {
###########################
    my $file = shift;

    my @lines = split "\n", `cat $file`;
    my @diffs = split "\n", `svn diff -x-w $file`;

    my ( @changed_subs, @added_subs, @removed_subs, @pointers );

    my ( $pointer, $add_lines );

    my $change_found = 0;
    foreach my $diff_line (@diffs) {
        ## increment each line found UNLESS it has been removed from target file #

        if ( $diff_line =~ /\@\@\s+\-(\d+)\,(\d+)\s+\+(\d+),(\d+)/ ) {
            ## formatted svn diff output indicating line specs for block of code changed  ##
            $change_found++;
            $add_lines = 0;
            $pointer   = $3;
        }
        elsif ( $diff_line !~ /^\-\s+/ ) { $add_lines++ }

        if ( $pointer && $diff_line =~ /^[\+|\-](.*)$/ ) {
            my $changed_line = $1;
            if ( $changed_line !~ /\w+/ && $changed_line =~ /^\s*\#/ ) {
                ## ignore comment lines or blank lines ##
                next;
            }

            ## found changed line following diff ##
            push @pointers, $pointer + $add_lines;
            ## clear pointer (so that we only find one subroutine per change block)
            $pointer   = 0;
            $add_lines = 0;
        }
        elsif ( !$pointer ) {
            ## pointer turned off ... still need to check for start of additional subroutine in change block ... ##
            if ( $diff_line =~ /^[\+]\s*sub (\w+)/ ) {
                ## internally added subroutine ##
                push @added_subs, $1;
                $pointer = $pointers[-1];    ## reset pointer so that we include subroutines below and above if required ##
            }
            elsif ( $diff_line =~ /^[\-]\s*sub (\w+)/ ) {
                ## keep track of subs removed (no need to include unless moved in which case they should also appear as added)
                push @removed_subs, $1;
                $pointer = $pointers[-1];    ## reset pointer so that we include subroutines below and above if required ##
                ## do not increment add_lines since this line is not in the commited file ##
            }
            elsif ( $diff_line =~ /^sub (\w+)/ ) {
                push @changed_subs, $1;
                $pointer = $pointers[-1];    ## reset pointer so that we include subroutines below and above if required ##
            }
        }
    }

    foreach my $pointer (@pointers) {
        ## add methods based upon list opointers to line changes

        ## go down to end of comment section (in case change is in pre-sub comment block ##
        while ( $lines[ $pointer++ ] =~ /^\s*\#/ ) { }

        while ($pointer) {
            ## go up one line at a time to find the most recent 'sub ' ##
            if ( $lines[ $pointer-- ] =~ /^sub (\w+)/ ) {
                if ( !grep /$1/, @changed_subs, @added_subs ) { push @changed_subs, $1 }
                last;
            }
        }
        if ( !$pointer && !grep /^main$/, @changed_subs ) { push @changed_subs, 'main' }
    }

    return @changed_subs, @added_subs;
}

#
# Given a file (or list of methods) and method (optional), find the unit tests to make sure they exist.
#
# Return: list of unit_tests run successfully (or '1' if skipped; '0' on failure)
##########################      GOTAA BE MOVED TO VALDIATION
sub find_unit_tests {
##########################
    my %args      = filter_input( \@_ );
    my $files     = $args{-files};
    my $file      = $args{-file} || '';
    my $sub       = $args{-method} || '';
    my $prompt    = $args{-prompt};         ## flag to allow prompt for user to skip unit tests if desired...
    my $run_modes = $args{-run_modes};

    #   Message("Look for active block: $file::$sub\n");
    if ($file) { $files = [$file] }

    my @tested;
    my $passed   = 1;
    my $no_tests = 0;

    foreach my $test_file (@$files) {
        my $original = $test_file;
        $test_file =~ s/lib\/perl/bin\/t/;

        if ( $test_file =~ /\.pl/ ) {
            if ( $sub eq 'main' ) {
                Message("Main block of scripts do not require unit tests...");
                next;
            }
            else {
                Message("${sub}() method found - should this be moved to a module?");
                next;
            }
        }
        elsif ( $test_file =~ /\.(css|js)$/ ) {
            Message("* Please ensure $1 directory path includes latest version *");
            next;
        }
        elsif ( $test_file !~ /\.pm/ ) {
            Message("$test_file - does not require unit test ?");
            next;
        }

        if ( $sub eq 'main' ) {
            Message("Main block of scripts do not require unit tests...");
            next;
        }

        ### Note App modules should now have unit tests as well (block excluding them was removed)
        $test_file =~ s/modules\//t\//;
        $test_file =~ s/\.pm$/\.t/;

        if ( !-e $test_file ) {
            my $add_test_file = Prompt_Input( -type => 'char', -prompt => "Create new test file for $original: ($test_file) ?" );
            if ( $add_test_file =~ /y/i ) {
                my $setup = "$baseline/bin/setup_test.pl";
                print "Generating test file: $setup -module $original\n";
                `$setup -module $original`;
            }
            print "skipping ($add_test_file)\n";
        }

        if ( -e $test_file && $test_file =~ /_App\./ ) {
            foreach my $run_mode ( keys %{$run_modes} ) {
                my $target = $run_modes->{$run_mode};
                if ( $target eq $sub ) {
                    my $test = "grep test_run_mode $test_file | grep \"=>'$run_mode'\"";

                    # Message("Test: $test");
                    ## this run mode calls a changed method - should be tested ##
                    if   ( my $ok = `$test` ) { }                                                       # Message("Found $run_mode test") }
                    else                      { Message("* Missing $run_mode test"); $no_tests = 1; }
                }
            }
        }
        elsif ( -e $test_file ) {
            my $diffs = try_system_command("\svn diff $test_file");
            if ($sub) {
                my $sub_found = `grep "'$sub'" $test_file | grep can_ok`;
                my $sub_changed = ( $diffs =~ /\b$sub\b/ );

                if ( !$sub_found ) { Message("* Missing $sub block in $test_file\n"); $no_tests = 1; }
                elsif ( !$sub_changed ) { Message("$test_file\n*********************\n*** No diffs in $sub test block *** \n"); $no_tests = 1; }

                my $diff_found = `grep "'$sub'" $test_file | grep -v can_ok`;
                if ( !$diff_found && !$no_tests ) { Message("* No $sub tests added in ${test_file}\n"); $no_tests = 1; }
            }
            if ( !$diffs && !$no_tests ) { Message("*** No diffs in $test_file tests *** "); $no_tests = 1; }

            my @run_test = split "\n", try_system_command("perl $test_file -method $sub");
            if ( $run_test[-1] =~ /1\.\.(\d+)/ ) {
                Message("$test_file Passed $1 tests");
                push @tested, $test_file;
            }
            else {
                Message("*** $test_file FAILED unit tests - Aborting.... ***\n");
                return 0;
            }
        }
        else {
            Message("File $test_file not found...");
            $passed = 0;
        }

        if ($no_tests) {
            Message("\n** Note: update unit test automatically by calling bin/setup_test.pl -module $file -append\n");
            if ($prompt) {
                while ( $prompt !~ /c|a/ ) {
                    $prompt = Prompt_Input( -type => 'char', -prompt => "Continue without updating unit test or Abort to update unit test (c/a) ? " );
                    print "\n";
                }
                if ( $prompt eq 'c' ) { Message("\nContinue without updating unit test for $test_file... \n"); $passed = 1; }
                else                  { Message("\nAborting\n"); exit; }
            }
        }
    }

    if ( $passed && @tested ) { $passed = join ' ', @tested }    ## return tested files if applicable..
    return $passed;
}

##################
sub get_host_db {
##################
    my $version = shift;
    my $mode    = shift;

#    my $configs = SDB::Installation::load_custom_config($version);
    return ( $Configs{"${mode}_HOST"}, $Configs{"${mode}_DATABASE"});

}

return 1;

