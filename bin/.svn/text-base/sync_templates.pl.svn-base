#!/usr/local/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::FTP;
use Data::Dumper;
use Getopt::Long;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw( $opt_help $opt_from $opt_to $opt_log $opt_type $opt_update $opt_ignore_custom  %Configs);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
&GetOptions(
    'help|h|?'      => \$opt_help,
    'from|f=s'      => \$opt_from,
    'to|t=s'        => \$opt_to,
    'type|t=s'      => \$opt_type,
    'log=s'         => \$opt_log,
    'update|u'      => \$opt_update,           # copy newer files from source to target
    'ignore_custom' => \$opt_ignore_custom,    # flag to ignore copy custom templates over
);

my $help = $opt_help;

my $from = uc($opt_from);
my $to   = uc($opt_to);

my $type          = $opt_type;
my $log           = $opt_log;
my $update        = $opt_update;
my $ignore_custom = $opt_ignore_custom;

if ($help) {
    &display_help();
    exit;
}

if ( $from ne 'PRODUCTION' && $from ne 'BETA' && $from ne 'DEV' && $from ne 'TEST' ) {
    print "\nUnrecognized -from argument entered!\n";
    &display_help();
    exit;
}
if ( $to ne 'PRODUCTION' && $to ne 'BETA' && $to ne 'DEV' && $to ne 'TEST' ) {
    print "\nUnrecognized -to argument entered!\n";
    &display_help();
    exit;
}
if ( $type !~ /view/i && $type !~ /template/i ) {
    print "\nUnrecognized -type argument entered!\n";
    &display_help();
    exit;
}

my $source_dir;
my $dest_dir;
if ( $type =~ /view/i ) {
    my $from_db_param = $from . '_DATABASE';
    my $to_db_param   = $to . '_DATABASE';
    $source_dir = "$Configs{views_dir}/$Configs{$from_db_param}/";
    $dest_dir   = "$Configs{views_dir}/$Configs{$to_db_param}/";
}
elsif ( $type =~ /template/i ) {
    my $from_host_param = $from . '_HOST';
    my $from_db_param   = $from . '_DATABASE';
    my $to_host_param   = $to . '_HOST';
    my $to_db_param     = $to . '_DATABASE';
    $source_dir = "$Configs{upload_template_dir}/$Configs{$from_host_param}/$Configs{$from_db_param}/";
    $dest_dir   = "$Configs{upload_template_dir}/$Configs{$to_host_param}/$Configs{$to_db_param}/";
}

my @source_files;
my $command = "find $source_dir -name '*.yml' -printf \"%P\n\"";
my ( $output, $stderr ) = try_system_command( -command => $command );
if ($output) {
    @source_files = split /\n/, $output;

    #print Dumper \@source_files;
}

&sync_files(
    -source_dir => $source_dir,
    -dest_dir   => $dest_dir,
    -files      => \@source_files,
    -log_file   => $log,
    -update     => $update,
    -type       => $type,
);

sub sync_files {
    my %args     = @_;
    my $from     = $args{-source_dir};
    my $to       = $args{-dest_dir};
    my $files    = $args{-files};        # specify the files need to be synced, otherwise all files (*.*) under the source dir will be included
    my $log_file = $args{-log_file};
    my $update   = $args{-update};
    my $type     = $args{-type};

    my $LOG;
    if ($log_file) {
        my $ok = open $LOG, ">>$log_file";
        if ( !$ok ) {
            die "Couldn't open $log_file for appending: $!";
        }
    }

    my @from_files;
    if ( defined $files ) {
        @from_files = @$files;
    }
    else {
        my $command = "find $from -name '*.*' -printf \"%P\n\"";
        my ( $output, $stderr ) = try_system_command( -command => $command );
        if ($output) {
            @from_files = split /\n/, $output;
        }

    }
    if ($log_file) {
        print $LOG "File list:\n";
        print $LOG join "\n", @from_files;
    }

    my @nonexist;
    my %changed = (
        'newer'          => [],
        'older'          => [],
        'same_timestamp' => [],
        'unknown'        => [],
    );
    my @unchanged;
    my @ignored;

    my $command;
    my $output;
    my $stderr;
    foreach my $file (@from_files) {
        my $source_file = "$from/$file";
        my $target_file = "$to/$file";

        ## ignore custom templates if ignore_custom flag is on
        if ( $ignore_custom && $type =~ /template/ && $file =~ /^[^Core]/ ) {
            push @ignored, $file;
            next;
        }

        if ( -f $target_file ) {    # target file exists
            ## diff
            $command = "diff \"$source_file\" \"$target_file\"";
            ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {          ## different
                ## compare the time stamp
                my $t_source;
                my $t_target;
                ( $output, $stderr ) = try_system_command( -command => "stat -c %Y \"$source_file\"" );    # get last modification time
                if ($output) { $t_source = $output; chomp($t_source) }
                ( $output, $stderr ) = try_system_command( -command => "stat -c %Y \"$target_file\"" );    # get last modification time
                if ($output) { $t_target = $output; chomp($t_target) }

                if ( defined $t_source && defined $t_target ) {
                    if    ( $t_source > $t_target ) { push @{ $changed{newer} },          $file }
                    elsif ( $t_source < $t_target ) { push @{ $changed{older} },          $file }
                    else                            { push @{ $changed{same_timestamp} }, $file }
                }
                else {
                    push @{ $changed{unknown} }, $file;                                                    # unable to compare timestamp
                }
            }
            else {                                                                                         ## no difference
                push @unchanged, $file;
            }
        }
        else {
            push @nonexist, $file;
        }
    }

    print "\n\n====== Total ", int(@from_files), " files are checked ======\n";
    if ($log_file) { print $LOG "\n\n====== Total ", int(@from_files), " files are checked ======\n" }

    if ( int(@unchanged) ) {
        print "\n", int(@unchanged), " files are unchanged\n";
        if ($log_file) { print $LOG "\n", int(@unchanged), " files are unchanged\n" }

        #print "\t", join "\n\t", @unchanged;
    }
    if ( int(@nonexist) ) {
        print "\n", int(@nonexist), " files do not exist in $to, need to copy over\n";
        print "\t", join "\n\t", @nonexist;
        if ($log_file) {
            print $LOG "\n", int(@nonexist), " files do not exist in $to, need to copy over\n";
            print $LOG "\t", join "\n\t", @nonexist;
        }
        if ($update) {
            print "\n\t";
            if ($log_file) { print $LOG "\n\t" }
            foreach my $file (@nonexist) {
                ## ignore custom templates
                if ( $ignore_custom && $type =~ /template/ && $file =~ /^[^Core]/ ) {
                    print "\tIgnored: $file\n";
                    print $LOG "\tIgnored: $file\n";
                    next;
                }

                my $full_name = "$to/$file";
                my $path;
                my $file_name;
                if ( $full_name =~ /(.*)\/([^\/]+)$/ ) {
                    $path      = $1;
                    $file_name = $2;
                }
                print "path=$path, file_name=$file_name\n";
                if ( $path && $file_name ) {
                    if ( !-d $path ) { RGTools::RGIO::create_dir( $path, -mode => 764 ); Message("trying to create dir $path") }
                    $command = "cp -a '$from/$file' '$to/$file'";
                    ( $output, $stderr ) = try_system_command( -command => $command );
                    if ($stderr) {
                        print "\tError while executing command: $command\n$stderr\n";
                        if ($log_file) { print $LOG "\tError while executing command: $command\n$stderr\n" }
                    }
                    else {
                        print "\tSuccess: $command\n";
                        if ($log_file) { print $LOG "\tSuccess: $command\n" }
                    }
                }
            }
        }
    }
    my $newer_count          = int( @{ $changed{newer} } );
    my $older_count          = int( @{ $changed{older} } );
    my $same_timestamp_count = int( @{ $changed{same_timestamp} } );
    my $unknown_count        = int( @{ $changed{unknown} } );
    my $changed_count        = $newer_count + $older_count + $same_timestamp_count + $unknown_count;
    my $ignored_count        = int(@ignored);

    if ( $changed_count > 0 ) {
        print "\n\n-- $changed_count files are changed --\n";
        if ($log_file) { print $LOG "\n\n-- Total $changed_count files are changed --\n" }
        if ($newer_count) {
            print "$newer_count files are newer in $from:\n";
            print "\t", join "\n\t", @{ $changed{newer} };
            if ($log_file) {
                print $LOG "$newer_count files are newer in $from:\n";
                print $LOG "\t", join "\n\t", @{ $changed{newer} };
            }

            if ($update) {
                print "\n\t";
                if ($log_file) { print $LOG "\n\t" }
                foreach my $file ( @{ $changed{newer} } ) {
                    ## ignore custom templates
                    #if( $ignore_custom && $type =~ /template/ && $file =~ /^[^Core]/ ) {
                    #	print "\tIgnored: $file\n";
                    #	print $LOG "\tIgnored: $file\n";
                    #	next;
                    #}

                    my $full_name = "$to/$file";
                    my $path;
                    my $file_name;
                    if ( $full_name =~ /(.*)\/([^\/]+)$/ ) {
                        $path      = $1;
                        $file_name = $2;
                    }
                    if ( $path && $file_name ) {
                        if ( !-d $path ) { RGTools::RGIO::create_dir( $path, -mode => 764 ) }
                        $command = "cp -a '$from/$file' '$to/$file'";
                        ( $output, $stderr ) = try_system_command( -command => $command );
                        if ($stderr) {
                            print "\tError while executing command: $command\n$stderr\n";
                            if ($log_file) { print $LOG "\tError while executing command: $command\n$stderr\n" }
                        }
                        else {
                            print "\tSuccess: $command\n";
                            if ($log_file) { print $LOG "\tSuccess: $command\n" }
                        }
                    }
                }
            }
        }
        if ($older_count) {
            print "\n$older_count files are older in $from:\n";
            print "\t", join "\n\t", @{ $changed{older} };
            if ($log_file) {
                print $LOG "\n$older_count files are older in $from:\n";
                print $LOG "\t", join "\n\t", @{ $changed{older} };
            }
        }
        if ($same_timestamp_count) {
            print "\n$same_timestamp_count files have the same timestamp in $from and $to:\n";
            print "\t", join "\n\t", @{ $changed{same_timestamp} };
            if ($log_file) {
                print $LOG "\n$same_timestamp_count files have the same timestamp in $from and $to:\n";
                print $LOG "\t", join "\n\t", @{ $changed{same_timestamp} };
            }
        }
        if ($unknown_count) {
            print "\n$unknown_count files cannot compare timestamps:\n";
            print "\t", join "\n\t", @{ $changed{unknown} };
            if ($log_file) {
                print $LOG "\n$unknown_count files cannot compare timestamps:\n";
                print $LOG "\t", join "\n\t", @{ $changed{unknown} };
            }
        }
    }

    if ( $ignored_count > 0 ) {
        print "\n$ignored_count custom files are ignored:\n";
        print "\t", join "\n\t", @ignored;
        if ($log_file) {
            print $LOG "\n$ignored_count custom files are ignored:\n";
            print $LOG "\t", join "\n\t", @ignored;
        }
    }

    print "\n\n";
    if ($log_file) { print $LOG "\n\n" }

}

sub display_help {
    print <<HELP;

Syntax
======
sync_templates.pl - This script syncs the version specific views or template files between version directories

Arguments:
=====

-- required arguments --
-from	: specify the code version of the source. Available options: 'PRODUCTION', 'BETA', 'DEV', 'TEST'.
-to		: specify the code version of the destination. Available options: 'PRODUCTION', 'BETA', 'DEV', 'TEST'.
-type	: specify the type of template to rsync. Two available options: 'view' and 'template'.

-- optional arguments --
-help, -h, -?		: displays this help. 
-log				: specify the log file. 
-update, -u			: flag to copy the newer files over from source dir to destination dir	
-ignore_custom		: flag to ignore template files that are not in the Core directory
				  
Example
=======
sync_templates.pl -from production -to dev -type view
sync_templates.pl -from beta -to production -type template -ignore_custom -log /home/aldente/private/tmp/sync_prod_dev.log
sync_templates.pl -from production -to beta -type template -ignore_custom -log /home/aldente/private/tmp/sync_prod_dev.log -u

HELP

}
