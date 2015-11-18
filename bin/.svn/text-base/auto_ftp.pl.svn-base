#!/usr/local/bin/perl

##############################################################################################
# Quick program written to generate Trace file submissions based upon NCBI standard protocol.
#
#  This should be scalable eventually to handle various submission types.
##############################################################################################

## standard perl modules ##
use CGI qw(:standard fatalsToBrowser);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
## Local perl modules ##

# (generic modules)
use RGTools::RGIO;
use RGTools::Conversion;

use Net::FTP;

use strict;

##############################
# global_vars                #
##############################
use vars qw($testing $Connection $ftp);

#use vars qw($opt_t $opt_g $opt_l $opt_p $opt_r $opt_x $opt_f $opt_L $opt_X $opt_a $opt_R $opt_P $opt_v $opt_u $opt_O $opt_d $opt_c);
use vars qw($opt_limit $opt_library $opt_plate $opt_run $opt_group $opt_append $opt_compress $opt_remove $opt_include_poor $opt_force $opt_xml $opt_quiet);
use vars qw($opt_verbose $opt_update $opt_target $opt_date $opt_comment $opt_path $opt_name $opt_user $opt_password $opt_min_length $opt_submission_type $opt_trace_list_file);
use vars qw($opt_F $opt_R $opt_upload $opt_monitor $opt_volumes $opt_volume $opt_project $opt_get_logs $opt_count $opt_list $opt_directory);

#require "getopts.pl";
use Getopt::Long;
&GetOptions(
    'limit=s'           => \$opt_limit,
    'library=s'         => \$opt_library,
    'plate=s'           => \$opt_plate,
    'run=s'             => \$opt_run,
    'group=s'           => \$opt_group,
    'remove=s'          => \$opt_limit,
    'update=s'          => \$opt_update,
    'target=s'          => \$opt_target,
    'date=s'            => \$opt_date,
    'comment=s'         => \$opt_comment,
    'path=s'            => \$opt_path,
    'name=s'            => \$opt_name,
    'user=s'            => \$opt_user,
    'password=s'        => \$opt_password,
    'min_length=s'      => \$opt_min_length,
    'F=s'               => \$opt_F,
    'R=s'               => \$opt_R,
    'submission_type=s' => \$opt_submission_type,
    'trace_list_file=s' => \$opt_trace_list_file,
    'upload=s'          => \$opt_upload,
    'volume=s'          => \$opt_volume,
    'volumes=s'         => \$opt_volumes,
    'project=s'         => \$opt_project,
    'get_logs=s'        => \$opt_get_logs,
    'count=s'           => \$opt_count,
    'directory=s'       => \$opt_directory,
    ## booleans ##
    'monitor'      => \$opt_monitor,
    'compress'     => \$opt_compress,
    'quiet'        => \$opt_quiet,
    'verbose'      => \$opt_verbose,
    'remove'       => \$opt_remove,
    'append'       => \$opt_append,
    'xml'          => \$opt_xml,
    'force'        => \$opt_force,
    'include_poor' => \$opt_include_poor,
    'list'         => \$opt_list,
);

## parse input options ##
my $run_limit    = $opt_limit || 5000;                 ## limit of number of traces to group in one tarred file
my $library      = $opt_library;                       ## provide Library
my $plate_number = $opt_plate;                         ## provide plate number (or list / range) (optional with library)
my $run_id       = $opt_run;                           ## ... or provide run id (or list)
my $group_by     = $opt_group;                         ## group volumes
my $append       = $opt_append;                        ## append to current volume
my $compress     = $opt_compress;
my $remove       = '--remove_files' if $opt_remove;    ##
my $group;

my $include_poor = $opt_include_poor || 0;             ## include poor quality (no quality length) reads
my $min_length   = $opt_min_length   || 0;
my $force        = $opt_force        || 0;             ## force execution without feedback check.
my $xml          = $opt_xml;
my $verbose      = $opt_verbose;
my $update_volume       = $opt_update;                     ## indicate current volume if this for updating or appending
my $target_organization = $opt_target;
my $submission_date     = $opt_date || '';
my $comments            = $opt_comment || '';
my $path                = $opt_path || '.';
my $basename            = $opt_name || 'trace_files';
my $user                = $opt_user;
my $password            = $opt_password;
my $submission_type     = $opt_submission_type || 'new';
my $trace_list_file     = $opt_trace_list_file;
my $upload              = $opt_upload;
my $monitor             = $opt_monitor;
my $volume              = $opt_volume;
my $volumes             = $opt_volumes || 1;
my $quiet               = $opt_quiet;
my $get_logs            = $opt_get_logs;
my $project             = $opt_project;
my $count               = $opt_count;                      # number of times to try listing
my $list                = $opt_list;
my $directory           = $opt_directory;

my $volume_name = $basename;

my $dbase = 'sequence';
my $host  = 'lims02';

## initialize variables ##
my $target = "$path/$basename";
my $log    = "$target.log";

## option to just upload files in the upload directory (eg  -upload BE000_test.tar.gz)
if ( $upload || $list ) {
    my $uploaded = _ftp_upload( -site => 'ftp.ncbi.nlm.nih.gov', -source_directory => $directory, -file => $upload, -list => $list, -quiet => $quiet );
    print "\nFinished ftp tasks (uploaded $uploaded files)\n";
    exit;
}
elsif ($monitor) {
    _ftp_monitor( -site => 'ftp.ncbi.nlm.nih.gov', -tries => $count, -quiet => $quiet );
    exit;
}
else {
    help();
}

if ($get_logs) {
    my $ftp = _ftp_connect( -site => 'ftp.ncbi.nlm.nih.gov', -directory => "logs", -debug => !$quiet );
    $ftp->cwd($get_logs) or die "Directory $get_logs does not exist\n(Try later)...\n\n";

    my $downloaded = 0;
    my @ls         = $ftp->dir or last;
    my @files      = _list_dir( \@ls );
    foreach my $file (@files) {
        if ( $file =~ /(\S+)\s+\[/ ) { $file = $1; }

        print &date_time . "\n";
        print "Attempting to download $file..\n";
        print "uploaded.  " . date_time . "\n";
        $downloaded += $ftp->get($file);
    }
    print "Downloaded $downloaded files.\n";
    $ftp->quit if $ftp;
    exit;
}

### Initialize variables ###
my $max_volume       = $volume + $volumes - 1;
my @volumes          = ( $volume .. $max_volume );    ## (1..$volumes);
my $compressed       = 0;
my $total_compressed = 0;

if ($compress) {
    unless ( -e "tar_files/upload/" ) { Message("tar_files/upload/ directory not found. (create or move to project directory)"); exit; }
    foreach my $vol (@volumes) {
        ###### Intentions #######
        my $vol_name = $volume_name . "_" . $vol;
        if ( $volumes == 1 ) { $vol_name = $volume_name }    ## Don't worry about a suffix if only one volume..

        print "Volume $vol ($vol_name)\n";
##	`tar -zcvf tar_files/upload/$vol_name.q.tar.gz $vol_name/`;
##	print "(compressed $vol_name)\n";
##	$total_compressed += $compressed;
    }

    foreach my $vol (@volumes) {
        my $vol_name = $volume_name . "_" . $vol;

        unless ($project) { Message("Error - must supply project name "); exit; }

        #	_edit_traceinfo("/home/sequence/Submissions/ncbi/$project/$vol_name/TRACEINFO.xml",$vol);
        #	next;

        ###### COMPRESS #######
        print "Compressing Volume $vol ($vol_name)";

        `tar -zcvf tar_files/upload/$vol_name.qs.tar.gz $vol_name/`;
        print "(compressed $vol_name)\n";
        $total_compressed += $compressed;
    }
    print "Compressed $total_compressed Files into tar_files/upload directory\n\n";
    exit;
} ## end if ($compress)

#################
sub _ftp_connect {
#################
    my %args      = @_;
    my $site      = $args{-site} || '';
    my $user      = $args{-user} || "bccagsc_trc";
    my $password  = $args{-password} || 'BE7TTmvz';
    my $directory = $args{-directory} || '';
    my $debug     = $args{-debug};

    my $connected = 0;
    my $try       = 0;
    my $max       = 100;
    print "Trying to connect to $site.  (will try $max times before aborting)\n";

    while ( $try < $max ) {
        $try++;
        print "$try..";
        sleep 2 if $try;

        #    print "(logging in)..\n";
        $ftp->quit if $ftp;
        $ftp = Net::FTP->new( $site, Debug => $verbose, BlockSize => 32768, Timeout => 1200 ) or next, $ftp->message;

        $ftp->login( $user, $password ) or next, $ftp->message;

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
} ## end sub _ftp_connect

###############
sub _ftp_monitor {
###############
    my %args  = @_;
    my $tries = $args{-tries} || 2;
    my $sleep = $args{ -sleep } || 5;
    my $quiet = $args{-quiet};

    my $ftp = _ftp_connect( %args, -directory => 'uploads', -debug => !$quiet );

    foreach my $try ( 1 .. $tries ) {
        my @ls = $ftp->dir or return;

        #	print &date_time . "\n****************\n";
        print _list_dir( \@ls );
        sleep $sleep;
    }

    $ftp->quit;
    return;
} ## end sub _ftp_monitor

##############
# Upload given files to specified site.
#
###############
sub _ftp_upload {
###############
    my %args       = @_;
    my $site       = $args{-site} || '';
    my $file       = $args{-file};
    my $user       = $args{-user};
    my $list       = $args{-list};                            ## simply generate current directory of uploaded files
    my $password   = $args{-password};
    my $source_dir = $args{-source_directory};
    my $extension  = $args{-extension} || 'tar.gz';
    my $target_dir = $args{-target_directory} || 'uploads';
    my $quiet      = $args{-quiet};

    $source_dir .= "/" if $source_dir;

    my @files = Cast_List( -list => $file, -to => 'array' );
    if ( ( int(@files) == 1 ) && `find $source_dir$files[0] -type d ` ) {    ## get all files in upload directory if not specified..
        $files[0] =~ s /\/$//;
        $source_dir .= $files[0];
        @files = glob("$source_dir/*.$extension");
        print "Uploading files in $source_dir directory:\n";
        print join "\n", @files;
        print "\n\n";
    }
    elsif ( !$list ) {
        print "Uploading:\n";
        print join "\n", @files;
        print "\n\n";
    }

    my $ftp;
    my $uploaded = 0;
    foreach my $file (@files) {

        #    print "Attempting to upload $file..\n";

        unless ($list) {
            print date_time . "\n";

            $ftp = _ftp_connect( -site => $site, -user => $user, -password => $password, -directory => $target_dir, -debug => !$quiet );
            my $bin = $ftp->binary() or print "could not set binary mode", $ftp->message;
            $ftp->put($file) || "Could not get $file\n", $ftp->message;
            $ftp->quit;

            print "uploaded $file.  " . date_time . "\n";
            $uploaded++;
        }
    }
    if ($list) {
        $ftp = _ftp_connect( -site => $site, -user => $user, -password => $password, -directory => $target_dir, -debug => !$quiet ) or print "couldn't connect", $ftp->message;
    }
    my @ls = $ftp->dir if $ftp;
    print _list_dir( \@ls, $source_dir ) if @ls;

    $ftp->quit if $ftp;
    return $uploaded;

} ## end sub _ftp_upload

#############
sub _list_dir {
#############
    my $list = shift;
    my $source_dir = shift || '.';
    my $quiet;

    my @ls = @$list;

    my $output = "Target contents:\n*****************\n" unless $quiet;

    foreach my $file (@ls) {
        my @details = split /\s+/, $file;
        my $size    = $details[4];
        my $file    = $details[8];
        my $kb      = int( $size / 100 ) / 10;
        my $mb      = int( $size / 100000 ) / 10;
        $output .= "$file [$size] ";

        my $source_details = `ls -l $source_dir/$file`;
        my @S_details      = split /\s+/, $file;
        my $S_size         = $S_details[4];
        my $S_file         = $S_details[8];
        $output .= " Source: $S_size : $S_file.";

        if    ( $mb >= 1 ) { $output .= " = $mb Mbytes\n" }
        elsif ( $kb >= 1 ) { $output .= " = $kb Kbytes\n" }
        else               { $output .= "\n"; }
    }
    return $output;
} ## end sub _list_dir

###########
sub help {
###########
    print <<HELP;
    
    Usage:
    *******
    
    auto_ftp.pl -list  -upload ./tar_files/              (generate directory listing for current uploads directory at ftp target site)
    auto_ftp.pl -directory ./tar_files -file file.tar.gz     (upload all files in given directory - defaults to current directory)
    auto_ftp.pl -upload ABC.tar.gz                        (upload a single file - looks in current directory)
    
HELP

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

2004-06-28

=head1 REVISION <UPLINK>

$Id: trace_bundle.pl,v 1.18 2004/11/19 19:09:50 rguin Exp $ (Release: $Name:  $)

=cut

