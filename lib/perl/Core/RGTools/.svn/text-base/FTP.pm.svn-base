################################################################################
#
# FTP.pm
#
# This module provides a set of tools for file transfer
################################################################################

package RGTools::FTP;

##############################
# superclasses               #
##############################
our @ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    run_rsync
    upload
);
@EXPORT_OK = qw(
    run_rsync
    upload
);

## Standard modules ##
use strict;
use Data::Dumper;
use Net::FTP;

## SDB modules ##
use SDB::CustomSettings;

## RGTools ##
use RGTools::RGIO;

##########################################################
# This method transfer files using rsync and check if the transfer is complete
#
# input:
#		-source_dir => the source dir
#		-dest_dir	=> the destination dir
#		-exclude	=> the exclude option to be given to rsync
#
# output:
#		return 1 if the file transfe is complete; return 0 otherwise.
#
# example:
#		my $success = run_rsync( -source_dir=>$source, -dest_dir=>$dest_dir, -exclude=>$exclude );
#
############################
sub run_rsync {
    my %args       = @_;
    my $host       = $args{-host};
    my $source_dir = $args{-source_dir};
    my $dest_dir   = $args{-dest_dir};
    my $exclude    = $args{-exclude};
    my $include    = $args{-include};
    my $recursive  = 1;
    $recursive = 0 if ( $args{-no_recursive} );
    my $no_data_ok    = $args{-no_data_ok};
    my $log_file      = $args{-log_file};
    my $extra_options = $args{-extra_options};
    my $report        = $args{-report};
    my $verbose       = defined $args{-verbose} ? $args{-verbose} : "vv";

    #my $rsync_cmd = "rsync -aHu --stats --exclude=.snapshot --exclude=s_8_0055.png --exclude=s_8_0055.csv /projects/sbs_pipeline01/42RCBAAXX/Bustard1.3.2_11-09-2009_aldente/qseq_error_plots /home/dcheng/LIMS_MISC/42RCBAAXX_test";
    my $rsync_args = "-Hu$verbose";
    if ($recursive) {
        $rsync_args .= 'a';
    }
    else {
        $rsync_args .= 'lptgoD';
    }
    if ($extra_options) {
        $rsync_args .= $extra_options;
    }
    $rsync_args .= " --stats $include $exclude $source_dir $dest_dir";
    my $rsync_cmd = "rsync $rsync_args";

    if ($host) {
        $rsync_cmd = "ssh $host \"$rsync_cmd\"";
    }
    print "$rsync_cmd\n";

    #first rsync
    #my ($stdout, $stderr) = try_system_command($rsync_cmd);
    #print "stdout: $stdout\nstderr:$stderr\n";
    my $stdout1 = `$rsync_cmd`;

    my $LOG;
    if ($log_file) {
        open $LOG, ">>$log_file" || die "Couldn't open $log_file for appending: $!";
    }

    #print "stdout: $stdout1\n";
    if ($log_file) { print $LOG "$stdout1\n" }

    my $first_transfer_size;
    my @results = split( "\n", $stdout1 );
    for my $result (@results) {
        if ( $result =~ /Total file size: (\d+) bytes/ ) { $first_transfer_size = $1; last; }
    }

    #print "size: $first_transfer_size\n";

    #second rsync to check
    #my ($stdout, $stderr) = try_system_command($rsync_cmd);
    #print "stdout: $stdout\nstderr:$stderr\n";
    my $stdout2 = `$rsync_cmd`;

    #print "stdout: $stdout2\n";
    if ($log_file) { print $LOG "$stdout2\n"; close($LOG) }

    my $second_transfer_size;
    my $second_number_of_file;
    my @results = split( "\n", $stdout2 );
    for my $result (@results) {
        if ( $result =~ /Number of files transferred: (\d)+/ ) { $second_number_of_file = $1; }
        if ( $result =~ /Total file size: (\d+) bytes/ ) { $second_transfer_size = $1; last; }
    }

    #print "size: $second_transfer_size\nnum:$second_number_of_file\n";

    #Check if rsync was done properly
    if ( $first_transfer_size == $second_transfer_size && $second_number_of_file == 0 && ( $first_transfer_size || $no_data_ok ) ) {

        #print "HERE\n";
        if ($report) {
            my $files = get_rsync_file_status( -output => $stdout1 );

            #print Dumper $files;
            if ( $files->{newer} && int( @{ $files->{newer} } ) > 0 ) {
                print "Warning: " . int( @{ $files->{newer} } ) . " files are more recent in $dest_dir. These files were not synchronized.\n";
                print Dumper $files->{newer};
            }

            if ( $files->{transferred} && int( @{ $files->{transferred} } ) > 0 ) {
                print int( @{ $files->{transferred} } ) . " files were transferred.\n";    ## this doesn't match the number from the rsync output, probably because it includes directories
            }

            #if ( $files->{unchanged} && int( @{ $files->{unchanged} } ) > 0 ) {
            #    print int( @{ $files->{unchanged} } ) . " files are up-to-date and thus no need to transfer.\n";
            #}

        }
        return 1;
    }
    else { return 0 }
}

##########################################################
# This method parses the rsync output and categorize the files base on their transfer status
# There are three categories:
#			-	transferred:	files that were transferred from source to destination
#			-	unchanged:		files that are the same in source and destination and no need to transfer
#			-	newer:			files that are more recent in destination. These files were not transferred
#
# input:
#		-output => the rsync output
#
# Return:
#		Hash ref of the categorized file names
############################
sub get_rsync_file_status {
    my %args = filter_input( \@_, -args => 'output', -mandatory => 'output' );
    my $output = $args{-output};

    my @lines = split( "\n", $output );
    my %files = (
        'transferred' => [],
        'unchanged'   => [],
        'newer'       => []
    );
    my $file_list_started = 0;
    my $file_list_ended   = 0;

    ## build file list
    my @file_list;
    for my $line (@lines) {
        if ( $line =~ /\[sender\] including file (.*) because of pattern/ ) {
            push @file_list, $1;
        }
    }
    my $file_list_built = int(@file_list) > 0 ? 1 : 0;

    for my $line (@lines) {
        if ( $line =~ /^delta-transmission/ ) {
            $file_list_started = 1;
            next;
        }
        if ( $line =~ /^total:/ ) {
            $file_list_ended = 1;
            last;
        }
        if ( $file_list_started && !$file_list_ended ) {
            if ( $line =~ /^(.+)\s+is uptodate$/ ) {
                my $file = $1;
                if ($file_list_built) {
                    if ( grep /^$file$/, @file_list ) { push @{ $files{unchanged} }, $file; }
                }
                else { push @{ $files{unchanged} }, $file }
            }
            elsif ( $line =~ /^(.+)\s+is newer$/ ) {
                my $file = $1;
                if ($file_list_built) {
                    if ( grep /^$file$/, @file_list ) { push @{ $files{newer} }, $file; }
                }
                else { push @{ $files{newer} }, $file }
            }
            else {
                my $file = $line;
                if ($file_list_built) {
                    if ( grep /^$file$/, @file_list ) { push @{ $files{transferred} }, $file; }
                }
                else { push @{ $files{transferred} }, $file }
            }
        }
    }
    return \%files;
}
#################################
# Create a FTP connection
#
# Usage:	my $ftp = _ftp_connect( -site => $site, -user => $user, -password => $password );
# 			my $ftp = _ftp_connect( -site => $site, -user => $user, -password => $password, -directory => $dir );
#
# Return:	FTP object reference
#################
sub _ftp_connect {
#################
    my %args = filter_input(
         \@_,
        -args      => 'site,user,password,directory',
        -mandatory => 'site,user,password'
    );
    my $site         = $args{-site} || '';
    my $ftp_user     = $args{-user};
    my $ftp_password = $args{-password};
    my $directory    = $args{-directory} || '';    # destination directory

    my $connected = 0;
    my $try       = 0;
    my $max       = 100;
    print "Trying to connect to $site.  (will try $max times before aborting)\n";
    my $ftp;
    while ( $try < $max ) {
        $try++;
        print "$try..";
        sleep 5 if $try;

        $ftp->quit if $ftp;
        $ftp = Net::FTP->new( $site, Debug => 0 ) or next;

        $ftp->login( $ftp_user, $ftp_password ) or next;
        $ftp->binary();
        $ftp->cwd($directory)                                 if $directory;
        print "\n** changing to $directory directory **...\n" if $directory;

        $connected++;
        last;
    }

    unless ($connected) {
        print "No connection enabled..\n\nAborting\n\n";
        $ftp->quit;
        return 0;
    }

    print "Connection established.\n\n";
    return $ftp;
}

#########################################
# FTP given files to specified site. It creates FTP connection by calling ftp_connect() automatically
#
# Usage:	my $count = _ftp_upload( -site => $site, -user => $user, -password => $password, -files => ['file1','file2'] );
# 			my $count = _ftp_upload( -site => $site, -user => $user, -password => $password, -source_directory => '/tmp/upload_dir' ); # this will upload all the files under /tmp/upload_dir
# 			my $count = _ftp_upload( -site => $site, -user => $user, -password => $password, -source_directory => '/tmp/upload_dir', -extension => 'xml' ); # this will upload all the files under /tmp/upload_dir with extension .xml
# 			my $count = _ftp_upload( -site => $site, -user => $user, -password => $password, -files => ['file1','file2'], -target_directory => 'incoming' ); # this will put the files to the destination dir "incoming/"
#
# Return:	Scalar, number of files uploaded
###############
sub _ftp_upload {
###############
    my %args = filter_input(
         \@_,
        -args      => 'site,user,password,target_directory,files,source_directory,extension,quiet',
        -mandatory => 'site,user,password'
    );
    my $site         = $args{-site} || '';
    my $ftp_user     = $args{-user};
    my $ftp_password = $args{-password};
    my $target_dir   = $args{-target_directory} || '';
    my $files        = $args{-files};                    # array reference
    my $source_dir   = $args{-source_directory};
    my $extension    = $args{-extension};
    my $quiet        = $args{-quiet};

    my $ftp = &_ftp_connect(
        -site      => $site,
        -user      => $ftp_user,
        -password  => $ftp_password,
        -directory => $target_dir
    );

    my @files;
    if ($files) {
        push @files, @$files;
    }

    if ($source_dir) {    ## get all the files under this dir
        my $name_pattern = "*";
        $name_pattern .= ".$extension" if ($extension);
        push @files, glob("$source_dir/$name_pattern");
    }

    my $uploaded = 0;
    print "Source contents:\n*********************\n" if ( !$quiet );
    foreach my $file (@files) {
        my ( $out, $err ) = try_system_command("ls $file");
        print "$out\n" if ( $out && !$quiet );
        print "$err\n" if ( $err && !$quiet );
        my $ok = $ftp->put($file);
        $uploaded++ if ($ok);
    }

    my @ls = $ftp->dir or return $uploaded;
    print "Target contents:\n*********************\n" if ( !$quiet );
    print join "\n", @ls if ( !$quiet );
    $ftp->quit;
    return $uploaded;
}

###########################
# Upload files using ascp protocol
#
# Usage:	my $count = _ascp_upload( -site => $site, -user => $user, -private_key => $pkey, -files => ['file1','file2'] );
# 			my $count = _ascp_upload( -site => $site, -user => $user, -private_key => $pkey, -source_directory => '/tmp/upload_dir' ); # this will upload all the files under /tmp/upload_dir
# 			my $count = _ascp_upload( -site => $site, -user => $user, -private_key => $pkey, -source_directory => '/tmp/upload_dir', -extension => 'xml' ); # this will upload all the files under /tmp/upload_dir with extension .xml
# 			my $count = _ascp_upload( -site => $site, -user => $user, -private_key => $pkey, -files => ['file1','file2'], -target_directory => 'incoming' ); # this will put the files to the destination dir "incoming/"
#
# 			my $count = _ascp_upload( -site => $site, -user => $user, -private_key => $pkey, -data_encryption => 1, -files => ['file1','file2'] ); # data will remain encrypted during transmission
# 			my $count = _ascp_upload( -site => $site, -user => $user, -password => $pwd, -files => ['file1','file2'] ); # use password to establish connection instead of private key
#
# Return:	Scalar, number of files uploaded
#############################
sub _ascp_upload {
####################
    my %args = filter_input(
         \@_,
        -args      => 'site,user,password,private_key,data_encryption,target_directory,files,source_directory,extension,quiet,test',
        -mandatory => 'site'
    );
    my $site            = $args{-site} || '';
    my $user            = $args{-user};
    my $password        = $args{-password};
    my $private_key     = $args{-private_key};
    my $target_dir      = $args{-target_directory} || '';
    my $files           = $args{-files};                    # array reference
    my $source_dir      = $args{-source_directory};
    my $extension       = $args{-extension};
    my $quiet           = $args{-quiet};
    my $data_encryption = $args{-data_encryption};          # if data need to be encrypted during transmission
    my $test            = $args{-test};

    my @files;
    if ($files) {
        push @files, @$files;
    }

    if ($source_dir) {                                      ## get all the files under this dir
        my $name_pattern = "*";
        $name_pattern .= ".$extension" if ($extension);
        push @files, glob("$source_dir/$name_pattern");
    }

    my @uploaded = ();
    foreach my $file (@files) {
        my $command = "/home/aldente/private/software/Aspera_Connect/current/bin/ascp ";
        $command .= " -i $private_key " if ($private_key);
        $command .= " -Q";
        $command .= 'T'                 if ( !$data_encryption );
        $command .= "r -m 10M -l 100M $file $user\@$site:$target_dir";
        if ($test) {
            Message("Test: (command NOT run) $command ...\n");
        }
        else {
            Message("running command $command ...\n") if ( !$quiet );
            if ( !$private_key && $password ) {
                my $input = "echo $password";
                $command = $input . "|" . $command;
            }
            ## Odd! Nothing returned from try_systyem_command() here! I got an empty file when I tried to pipe the ouput to a file. So I can't determine if the upload is successful.
            print try_system_command( -command => $command );    ## try grep "100%" from putput to determine if the upload is successful
        }

        push @uploaded, $file;
    }

    return \@uploaded;
}

#############################################
# Upload files using a specified protocol. It supports two types of protocols currently: FTP and FASP
#
# Usage:	my $count = upload( -protocol => 'FTP', -site => $site, -user => $user, -password => $password, -files => ['file1','file2'] );
# 			my $count = upload( -protocol => 'FTP', -site => $site, -user => $user, -password => $password, -source_directory => '/tmp/upload_dir' ); # this will upload all the files under /tmp/upload_dir
# 			my $count = upload( -protocol => 'FTP', -site => $site, -user => $user, -password => $password, -source_directory => '/tmp/upload_dir', -extension => 'xml' ); # this will upload all the files under /tmp/upload_dir with extension .xml
# 			my $count = upload( -protocol => 'FTP', -site => $site, -user => $user, -password => $password, -files => ['file1','file2'], -target_directory => 'incoming' ); # this will put the files to the destination dir "incoming/"
#
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -private_key => $pkey, -files => ['file1','file2'] );
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -private_key => $pkey, -source_directory => '/tmp/upload_dir' ); # this will upload all the files under /tmp/upload_dir
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -private_key => $pkey, -source_directory => '/tmp/upload_dir', -extension => 'xml' ); # this will upload all the files under /tmp/upload_dir with extension .xml
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -private_key => $pkey, -files => ['file1','file2'], -target_directory => 'incoming' ); # this will put the files to the destination dir "incoming/"
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -private_key => $pkey, -data_encryption => 1, -files => ['file1','file2'] ); # data will remain encrypted during transmission
# 			my $count = _ascp_upload( -protocol => 'FASP', -site => $site, -user => $user, -password => $pwd, -files => ['file1','file2'] ); # use password to establish connection instead of private key
#
# Return:	Scalar, number of files uploaded
#############################################
sub upload {
#################
    my %args = &filter_input(
         \@_,
        -args      => 'protocol,site,user,password,private_key,target_directory,files,source_directory,extension,quiet,data_encryption,test',
        -mandatory => 'protocol,site'
    );
    my $protocol = $args{-protocol};

    if ( $protocol =~ /FASP/i ) {    # Aspera
        return &_ascp_upload(%args);
    }
    elsif ( $protocol =~ /FTP/i ) {
        return &_ftp_upload(%args);
    }
}

return 1;
