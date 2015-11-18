#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
##############################
# Modules                    #
##############################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use SDB::DBIO;
use alDente::View_App;

#use SDB::Installation;
use SDB::CustomSettings qw(%Configs);
use vars qw($opt_string $opt_type $opt_user $opt_dbase $opt_host $opt_pass $opt_file_only $opt_s $opt_check $opt_grep $opt_debug $opt_t $opt_case_insensitive $opt_last_use);
use Getopt::Long;
##############################
# Input                      #
##############################

&GetOptions(
    'string=s'   => \$opt_string,
    'type=s'     => \$opt_type,
    'user=s'     => \$opt_user,
    'pass=s'     => \$opt_pass,
    'dbase=s'    => \$opt_dbase,
    'host=s'     => \$opt_host,
    's=s'        => \$opt_s,
    't=s'        => \$opt_t,
    'check=s'    => \$opt_check,
    'grep=s'     => \$opt_grep,
    'debug'      => \$opt_debug,
    'file_only'  => \$opt_file_only,
    'i'          => \$opt_case_insensitive,
    'last_use=s' => \$opt_last_use,
);
my $string = $opt_string || $opt_s;
my $type   = $opt_type   || $opt_t;
my $host   = $opt_host   || $Configs{PRODUCTION_HOST};
my $dbase  = $opt_dbase  || $Configs{PRODUCTION_DATABASE};
my $user   = $opt_user   || 'viewer';
my $pwd    = $opt_pass   || 'viewer';
my $check  = $opt_check;
my $grep     = $opt_grep;       ## options for changing the grep output (not really supported since the output format changes)...
my $debug    = $opt_debug;
my $last_use = $opt_last_use;

##############################
#   Data                     #
##############################
my @locations;
my @full_locations = (
    {   -path  => $FindBin::RealBin . "/../lib/perl/",
        -files => '*/*.pm',
        -title => 'Older Code',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Core/",
        -files => '*/*.pm',
        -title => 'Core Library',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Departments/",
        -files => '*/*.pm',
        -title => 'Main Departments',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Experiment/",
        -files => '*/*.pm',
        -type  => 'Perl',
        -title => 'Experiment',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Imported/",
        -files => '*.pm',
        -type  => 'Perl',
        -title => 'Imported Library 1',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Imported/",
        -files => '*/*.pm',
        -type  => 'Perl',
        -title => 'Imported Library 2',
    },
    {   -path  => $FindBin::RealBin . "/../lib/perl/Imported/",
        -files => '*/*/*.pm',
        -type  => 'Perl',
        -title => 'Imported Library 3',
    },
    {   -path  => $FindBin::RealBin . "/../Plugins/*/modules/",
        -files => '*.pm',
        -type  => 'Perl',
        -title => 'Plugin Code',
    },
    {   -path  => $FindBin::RealBin . "/../custom/*/modules/",
        -files => '*.pm',
        -type  => 'Perl',
        -title => 'Custom Code',
    },
    {   -path  => $FindBin::RealBin . "/../Options/*/modules/",
        -files => '*.pm',
        -type  => 'Perl',
        -title => 'Options Code',
    },
    {   -path  => $FindBin::RealBin . "/../custom/*/Departments/*/modules/",
        -files => '*/*.pm',
        -title => 'Custom Departments',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../bin/",
        -files => '*.pl',
        -title => 'Main Scripts',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../bin/*/",
        -files => '*.pl',
        -title => 'Secondary Scripts',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../cgi-bin/",
        -files => '*.pl',
        -title => 'CGI Scripts',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../cgi-bin/ajax/",
        -files => '*.pl',
        -title => 'AJAX Scripts',
        -type  => 'Perl',
    },
    {   -path  => $FindBin::RealBin . "/../bin/t/*/",
        -files => '*.t',
        -type  => 'Perl',
        -title => 'Unit Tests'
    },
    {   -path  => $FindBin::RealBin . "/../bin/t/*/*/",
        -files => '*.t',
        -type  => 'Perl',
        -title => 'Unit Tests 2'
    },
    ############
    {   -path  => $FindBin::RealBin . "/../conf/",
        -files => '*.conf',
        -type  => 'Conf',
        -title => 'Core Configuration Files',
    },
    {   -path  => $FindBin::RealBin . "/../custom/*/conf/",
        -files => '*.conf',
        -type  => 'Conf',
        -title => 'Custom Configuration Files',
    },
    ############
    {   -path  => $FindBin::RealBin . "/../www/js/",
        -files => '*.js',
        -type  => 'js',
        -title => 'Java Script',
    },
    ############
    {   -path  => $FindBin::RealBin . "/../install/patches/",
        -files => 'version_tracker.txt',
        -title => 'Core Version Tracker',
        -type  => 'Patches',
    },
    {   -path  => $FindBin::RealBin . "/../install/patches/custom/*/",
        -files => 'version_tracker.txt',
        -title => 'Custom Version Tracker',
        -type  => 'Patches',
    },
    {   -path  => $FindBin::RealBin . "/../install/patches/Core/*/",
        -files => '*.pat',
        -title => 'Core Patches',
        -type  => 'Patches',
    },
    {   -path  => $FindBin::RealBin . "/../custom/*/install/patches/*/",
        -files => '*.pat',
        -title => 'Custom Patches',
        -type  => 'Patches',
    },
    {   -path  => $FindBin::RealBin . "/../Plugins/*/install/patches/*/",
        -files => '*.pat',
        -title => 'Plugin Patches',
        -type  => 'Patches',
    },
    {   -path  => $FindBin::RealBin . "/../Options/*/install/patches/*/",
        -files => '*.pat',
        -title => 'Option Patches',
        -type  => 'Patches',
    },
    ############
    {   -path  => "/home/aldente/private/crontabs/",
        -files => '*.cron',
        -title => 'Option Cron Jobs',
        -type  => 'Cron',
    },
    ############
    {   -path  => $Configs{upload_template_dir} . '/' . $host . '/' . $dbase . '/',
        -files => '*/*.yml',
        -title => 'Templates',
        -type  => 'yml',
    },
    {   -path  => "/opt/alDente/www/dynamic/views/" . $dbase . '/Employee/*/*/',
        -files => '*.yml',
        -title => 'Employee Views',
        -type  => 'yml',
    },
    {   -path  => "/opt/alDente/www/dynamic/views/" . $dbase . '/Group/*/',
        -files => '*.yml',
        -title => 'Group Views 1',
        -type  => 'yml',
    },
    {   -path  => "/opt/alDente/www/dynamic/views/" . $dbase . '/Group/*/*/',
        -files => '*.yml',
        -title => 'Group Views 2',
        -type  => 'yml',
    },
    {   -path  => "/opt/alDente/www/dynamic/views/" . $dbase . '/Group/*/*/*/',
        -files => '*.yml',
        -title => 'Group Views 3',
        -type  => 'yml',
    },

);

if ($type) {
    for my $entry (@full_locations) {
        if ( $entry->{-type} =~ /^$type$/i && $entry->{-type} ) {
            push @locations, $entry;
        }
    }
}
else {
    @locations = @full_locations;
}

##############################
#  Logic                     #
##############################

my $feedback;
unless ($string) {
    _help();
    exit;
}
my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1
);

if ( $check =~ /^ex/ ) {
    ## special case - check executing scripts ##
    my @hosts = split "\n", try_system_command("ls /home/aldente/private/crontabs/*.cron");

    Message("Checking Hosts: @hosts");
    foreach my $host (@hosts) {
        my $host_name;
        if ( $host =~ /^(.*)\/(\w+?)\./ ) { $host_name = $2 }
        my $found = try_system_command( "ps -auxwww | grep \"$string\"", -host => $host_name );
        print "\n$host_name\n**************\n$found\n===============\n\n";
    }
    print "Done.\n";
    exit;
}

Message "*******************************";
Message "****  Checking files ...   ****";
Message "*******************************";
for my $loc_counter ( 1 .. int(@locations) ) {
    my $path  = $locations[ $loc_counter - 1 ]{-path};
    my $files = $locations[ $loc_counter - 1 ]{-files};
    my $title = $locations[ $loc_counter - 1 ]{-title};

    if ($check) {
        if ( $path =~ /$check/ || $files =~ /$check/ || $title =~ /$check/ ) {
            if ($debug) { Message("checking $title: $path ($files)") }
        }
        else {

            #    Message("ignoring $title: $path ($files)");
            next;
        }
    }
    my @results = _grep_dir(
        -files   => $files,
        -path    => $path,
        -title   => $title,
        -string  => $string,
        -options => $grep
    );
    my $source = $title || "$path ($files)";

    show_results( \@results, $source, $path );
}

if ( !$type || $type =~ /database/i || $type =~ /dbase/i ) {

    Message "*******************************";
    Message "**** Checking database ... ****";
    Message "*******************************";

    if ( !$check || $check =~ /trigger/i ) {
        Message "Checking in DB_Trigger Table";
        my @results = $dbc->Table_find( 'DB_Trigger', 'Table_Name,Value', "WHERE Value LIKE '%$string%' " );
        show_results( \@results, 'Trigger' );
    }

    if ( !$check || $check =~ /(error|integrity)/i ) {
        Message "Checking in Error Check Table";
        my $condition = "WHERE Table_Name LIKE '%$string%' OR Field_Name  LIKE '%$string%'  OR Command_String  LIKE '%$string%' OR Comments LIKE '%$string%' ";
        my @results = $dbc->Table_find( 'Error_Check', 'Error_Check_ID,Table_Name', $condition );
        show_results( \@results, 'Error Check' );
    }

    if ( !$check || $check =~ /(attribute)/i ) {
        Message "Checking in Attribute Table";
        my $condition = "WHERE Attribute_Type LIKE '%$string%' OR Attribute_Name  LIKE '%$string%' ";
        my @results = $dbc->Table_find( 'Attribute', 'Attribute_Name', $condition );
        show_results( \@results, 'Attribute' );
    }

    if ( !$check || $check =~ /(field)/i ) {
        Message "Checking Fields";
        my $condition = "WHERE Prompt LIKE '%$string%' OR Field_Name  LIKE '%$string%'  ";
        my @results = $dbc->Table_find( 'DBField', 'Field_Table,Field_Name', $condition );
        show_results( \@results, 'Fields' );
    }

    if ( !$check || $check =~ /(table)/i ) {
        Message "Checking Tables";
        my $condition = "WHERE DBTable_Name LIKE '%$string%' OR DBTable_Title  LIKE '%$string%'";
        my @results = $dbc->Table_find( 'DBTable', 'DBTable_Name', $condition );
        show_results( \@results, 'Tables' );
    }

}
if ( !$debug ) {
    print "\n" . "*" x 128 . "\nNote:  To generate full line by line listing, add '-debug' flag\n" . "*" x 128 . "\n";
}

exit;

#####################
sub show_results {
#####################
    my $results = shift;
    my $source  = shift;
    my $path    = shift;

    if ( !int( @{$results} ) ) {return}
    print "* " . int( @{$results} ) . " references found in $source\n";

    my %Source;
    print "\n";
    foreach my $result (@$results) {
        if ( $result =~ /^(.+?)\:(.*)/ ) {
            my $file_name    = $1;
            my $file_content = $2;

            if ( $last_use && $source =~ /Views/ ) {
                my $time = &alDente::View_App::get_latest_usage( -file => $file_name );
                my ( $date, $timestamp ) = split( " ", $time );
                if ( $date lt $last_use || !$time ) {next}
                $file_name = "$time\t$file_name";
            }

            push @{ $Source{$file_name} }, $file_content;
        }
    }
    foreach my $key ( sort keys %Source ) {
        Message( "** $key : " . int( @{ $Source{$key} } ) . ' references' );
        if ($debug) {
            print "\n*** ";
            print join "\n*** ", @{ $Source{$key} };
            print "\n\n";
        }
    }

    print "\n";

    return;
}

#######################
sub _grep_dir {
#######################
    my %args    = filter_input( \@_ );
    my $file    = $args{-files};
    my $path    = $args{-path};
    my $string  = $args{-string};
    my $title   = $args{-title};
    my $options = $args{-options} || ' -nr';
    my @results;
    my @files;
    my %files;

    unless ($title) {
        my $loc = $FindBin::RealBin . "/../";
        $loc =~ s/\//\\\//g;
        if   ( $path =~ /$loc(.+)/ ) { $title = $1 }
        else                         { $title = $path }
    }
    if ($opt_case_insensitive) { $options .= 'i' }

    if ($debug) { Message "Checking in $title " }

    my $search_command = "grep $options  '$string' $path" . $file;
    Message $search_command;

    $feedback = try_system_command($search_command);
    $path =~ s/\*/\.\+?/g;

    # Message '---- '.$path;

    if ($opt_file_only) {
        my @found = split "\n", $feedback;
        for my $found (@found) {
            if ( $found =~ /$path(.+?):/ && !( $found =~ /Permission denied/ ) && !( $found =~ /No such file or directory/ ) ) {
                my $file_name = $1;
                if   ( $files{$file_name} ) { $files{$file_name}++ }
                else                        { $files{$file_name} = 1 }
            }
        }
        for my $key ( sort ( keys %files ) ) {
            push @files, $key . ' : ' . $files{$key};
        }
        return @files;
    }
    else {
        my @found = split "\n", $feedback;
        for my $found (@found) {
            if ( $found =~ /$path(.+)/ && !( $found =~ /Permission denied/ ) && !( $found =~ /No such file or directory/ ) ) {
                my $name = $1;
                if   ( !$last_use ) { push @results, $name }
                else                { push @results, $found }
            }
        }

        return @results;
    }
}

#######################
sub _help {
#######################
    print <<END;

     File:  find_string_usage.pl
     ###################
     Looks in places looking for usage of the string
     
     Usage:
     ###################
        find_string_usage.pl -string <STRING>
        find_string_usage.pl -s <STRING>
        find_string_usage.pl -s <STRING> -t perl
	find_string_usage.pl -s <STRING> -t yml -l 2011-10-01

    Options:
    ###################
        -i          Case Insensitive
        -check <source> Checks certain areas of the code (eg db, patch, trigger, integrity, custom)   
        -t          type (Perl, Conf,js, patches,cron,yml,database)
        -debug          Generates verbose output
        -l          filter views base on their last usage time (apply only to views, filter out views that do not have a greater last usage date)
END
    return;
}
