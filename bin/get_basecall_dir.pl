#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

use SDB::DBIO;
use RGTools::RGIO;
use RGTools::FTP;
use Illumina::Solexa_Analysis;
use SDB::CustomSettings;

use vars
    qw( %Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_runs $opt_flowcells $opt_flowcell_dir $opt_target_dir $opt_include $opt_include_raw $opt_file $opt_search_submission_path $opt_copy_from $opt_basecall_dir $opt_run_dir_suffix $opt_archive_host $opt_skip_prb $opt_run_file_type $opt_mode);

&GetOptions(
    'help|h|?'         => \$opt_help,
    'host=s'           => \$opt_host,
    'dbase|d=s'        => \$opt_dbase,
    'user|u=s'         => \$opt_user,
    'password|p=s'     => \$opt_password,
    'runs=s'           => \$opt_runs,
    'flowcells=s'      => \$opt_flowcells,
    'include=s'        => \$opt_include,          # the condition of including approved and Production/Test runs. Default 'Approved,Production'
    'flowcell_dir=s'   => \$opt_flowcell_dir,     # use the specified flowcell directory
    'mode=s'           => \$opt_mode,             # valid modes include: search_submission_path, copy_dir_no_raw, copy_dir_with_raw, copy_complete_dir,
    'archive_host=s'   => \$opt_archive_host,     # the archive host for rsync, this is used together with flag -copy_dir_no_raw.
    'target_dir=s'     => \$opt_target_dir,       # directory to store the SRF file
    'include_raw'      => \$opt_include_raw,      # flag to include raw data
    'copy_from=s'      => \$opt_copy_from,
    'basecall_dir=s'   => \$opt_basecall_dir,
    'run_dir_suffix=s' => \$opt_run_dir_suffix,
    'run_file_type'    => \$opt_run_file_type,    # the run file type, e.g. srf, fastq. Default is srf
);

## the following options are included in mode:
#    'search_submission_path'	=> \$opt_search_submission_path,
#    'copy_complete_dir'				=> \$opt_copy_complete_dir,               # flag to copy over the full flowcell directory
#    'copy_dir_no_raw'				=> \$opt_copy_dir_no_raw,               # flag to copy over the flowcell directory excluding raw data files
#    'copy_dir_with_raw'				=> \$opt_copy_dir_with_raw,               # flag to copy over the flowcell directory including raw data files

my $help               = $opt_help;
my $host               = $opt_host;
my $dbase              = $opt_dbase;
my $user               = $opt_user;
my $pwd                = $opt_password;
my $run_list           = $opt_runs;
my $flowcell_list      = $opt_flowcells;
my $include            = $opt_include || 'Approved,Production';
my $input_flowcell_dir = $opt_flowcell_dir;
my $mode               = $opt_mode || 'copy_dir_no_raw';

#my $search_submission_path = $opt_search_submission_path;
#my $copy_complete_dir = $opt_copy_complete_dir;
#my $copy_dir_no_raw = $opt_copy_dir_no_raw;
#my $copy_dir_with_raw = $opt_copy_dir_with_raw;
my $archive_host   = $opt_archive_host;
my $target_dir     = $opt_target_dir;
my $include_raw    = $opt_include_raw;
my $copy_from      = $opt_copy_from;
my $basecall_dir   = $opt_basecall_dir;
my $run_dir_suffix = $opt_run_dir_suffix || '';
my $run_file_type  = $opt_run_file_type || 'SRF';

if ($help) {
    &display_help();
    exit;
}

my $lock_file = $Configs{data_submission_workspace_dir} . "/.get_basecall_dir.lock";

# exit if locked
if ( -e "$lock_file" ) {
    print "The script is locked.\n";
    exit;
}

# write a lock file
try_system_command( -command => "touch $lock_file" );

my %flowcell_dirs;
$flowcell_dirs{'13233AAXX'} = '/projects/flowcellscratch/080118_SOLEXA4_0009_13233AAXX';
$flowcell_dirs{'13286AAXX'} = '/projects/flowcellscratch/080125_SOLEXA4_0011_13286AAXX';
$flowcell_dirs{'301CDAAXX'} = '/projects/flowcellscratch/080307_SOLEXA6_0003_301CDAAXX';
$flowcell_dirs{'2012CAAXX'} = '/projects/flowcellscratch/080314_SOLEXA4_0025_2012CAAXX';
$flowcell_dirs{'201FEAAXX'} = '/projects/flowcellscratch/080331_SOLEXA4_0030_201FEAAXX';
$flowcell_dirs{'20821AAXX'} = '/projects/flowcellscratch/080325_SOLEXA4_0028_20821AAXX';
$flowcell_dirs{'20820AAXX'} = '/projects/flowcellscratch/080407_SOLEXA4_0032_20820AAXX';
$flowcell_dirs{'3017YAAXX'} = '/projects/flowcellscratch/080328_SOLEXA6_0006_3017YAAXX';
$flowcell_dirs{'3019NAAXX'} = '/projects/flowcellscratch/080408_SOLEXA6_0008_3019NAAXX';

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};
$target_dir = $SUBMISSION_WORK_PATH if ( !$target_dir );
if ( !-d $target_dir ) {
    ## create the target directory if not exist
    try_system_command( -command => "mkdir $target_dir" );
}

my %benchmarks;
my %flowcells;
my $run_count = 0;
my $manual    = 1;
my @order;
if ($run_list) {
    my @runs = Cast_List( -list => $run_list, -to => 'Array' );
    foreach my $run (@runs) {
        my ($flowcell_lane) = $dbc->Table_find( 'SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE FK_Run__ID = $run and FK_Flowcell__ID = Flowcell_ID" );
        my ( $flowcell, $lane ) = split ',', $flowcell_lane;
        $flowcells{$flowcell}{$lane}{run_id} = $run;

        #$flowcells{$flowcell}{$lane}{run_file_type} = [$run_file_type];
        $run_count++;
    }
}
elsif ($flowcell_list) {
    my @fcs = Cast_List( -list => $flowcell_list, -to => 'Array' );
    my $include_condition;
    if ( $include =~ /Approved/i ) {
        $include_condition .= " and Run_Validation = 'Approved'";
    }
    if ( $include =~ /Production/ ) {
        $include_condition .= " and Run_Test_Status = 'Production'";
    }
    if ( $include =~ /Test/ ) {
        $include_condition .= " and Run_Test_Status = 'Test'";
    }

    foreach my $fc (@fcs) {
        my %runs_info = $dbc->Table_retrieve(
            -table     => 'Flowcell,SolexaRun,Run',
            -fields    => [ 'Lane', 'FK_Run__ID' ],
            -condition => "WHERE Flowcell_Code = '$fc' and FK_Flowcell__ID = Flowcell_ID and FK_Run__ID = Run_ID" . $include_condition
        );
        my $index = 0;
        while ( defined $runs_info{FK_Run__ID}[$index] ) {
            my $run  = $runs_info{FK_Run__ID}[$index];
            my $lane = $runs_info{Lane}[$index];
            $flowcells{$fc}{$lane}{run_id} = $run;

            #$flowcells{$fc}{$lane}{run_file_type} = [$run_file_type];
            $run_count++;
            $index++;
        }
    }
}
else {    # if no run / flowcell specified, scan data submission work space run directories to gather requests
    $manual = 0;
    my $requests = &get_requests();
    print "Requests:\n";
    print Dumper $requests;
    foreach my $request (@$requests) {
        my $run = $request->{run_id};
        my ($flowcell_lane) = $dbc->Table_find( 'SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE FK_Run__ID = $run and FK_Flowcell__ID = Flowcell_ID" );
        my ( $flowcell, $lane ) = split ',', $flowcell_lane;
        $flowcells{$flowcell}{$lane}{run_id} = $run;

        #$flowcells{$fc}{$lane}{run_file_type} = [$request->{run_id}];
        $run_count++;
        $request->{flowcell} = $flowcell;
        $request->{lane}     = $lane;
        $request->{log}      = [];
        push @order, $request;
    }
}

unless (@order) {
    foreach my $fc ( keys %flowcells ) {
        foreach my $lane ( keys %{ $flowcells{$fc} } ) {
            my %request;
            $request{flowcell}      = $fc;
            $request{lane}          = $lane;
            $request{run_file_type} = $run_file_type;
            $request{run_id}        = $flowcells{$fc}{$lane}{run_id};
            $request{log}           = [];
            push @order, \%request;
        }
    }
}

my $request_count = scalar(@order);
my $fc_count      = keys %flowcells;
if ($request_count) {
    print "The following $request_count requests on $run_count runs on $fc_count flowcells will be processed:\n";
    print "Order\tFlowcell\tLane\tRun_id\tRun_file_type\n";
    my $count = 0;
    foreach my $request (@order) {
        $count++;
        print "$count\t$request->{flowcell}\t$request->{lane}\t$request->{run_id}\t$request->{run_file_type}\n";
    }
}

if ($input_flowcell_dir) {
    if ( $fc_count > 1 ) {
        print "You have more than 1 flowcells. The -flowcell_dir option is NOT valid!\n";
        exit;
    }
}

my %copied;
my %failed;
foreach my $request (@order) {
    print "Processing flowcell $request->{flowcell}, lane $request->{lane}, run $request->{run_id} ...\n";
    my $run          = $request->{run_id};
    my $run_data_dir = "$target_dir/Run$run" . $run_dir_suffix;
    if ( !-d $run_data_dir ) {
        print try_system_command( -command => "mkdir $run_data_dir" );
    }

    if ($basecall_dir) {
        &log(
            -request => $request,
            -message => "Basecall dir obtained from input: $basecall_dir"
        );
        &finish( -request => $request, -status => 'ready', -message => $basecall_dir );
        next;
    }

    my $fc = $request->{flowcell};
    my $flowcell_dir;
    if ($input_flowcell_dir) {
        $flowcell_dir = $input_flowcell_dir;    # use the specified flowcell directory if it is given
        &log( -request => $request, -message => "Use input flowcell dir: $flowcell_dir" );
    }
    elsif ( defined $flowcell_dirs{$fc} ) {     # use pre-defined flowcell directory
        $flowcell_dir = $flowcell_dirs{$fc};
        &log( -request => $request, -message => "Use pre-defined flowcell dir: $flowcell_dir" );
    }
    elsif ( $mode eq 'search_submission_path' ) {
        &log( -request => $request, -message => "Mode=search_submission_path" );
        if ( $failed{$fc} ) {
            &log(
                -request => $request,
                -message => "Could not decide which flowcell directory to use"
            );
            &finish( -request => $request, -status => 'failed' );
            next;
        }

        my $search_path        = $SUBMISSION_WORK_PATH;
        my @flowcell_directory = ();
        push @flowcell_directory, glob("$SUBMISSION_WORK_PATH/*$fc");
        my $count = @flowcell_directory;
        if ( $count > 1 ) {
            $failed{$fc} = 1;
            &log(
                -request => $request,
                -message => "WARNING: $count directories found for $fc under $SUBMISSION_WORK_PATH!"
            );
            &log(
                -request => $request,
                -message => "Cannot decide which directory to use. Please specify the flowcell directory!"
            );
            &finish( -request => $request, -status => 'failed' );
            next;
        }
        elsif ( $count == 1 ) {
            $flowcell_dir = $flowcell_directory[0];
            &log(
                -request => $request,
                -message => "Got flowcell dir from data submission workspace: $flowcell_dir"
            );
        }
    }
    elsif ( $mode =~ /copy/ ) {    # copy files from the flowcell directory to the temp dir and then process, remove it afterward.
        if ( $failed{$fc} ) {
            &log( -request => $request, -message => "Copy files failed" );
            &finish( -request => $request, -status => 'failed' );
            next;
        }

        if ( !$copied{$fc} ) {
            my @lanes = keys %{ $flowcells{$fc} };
            my $new_dir;
            if ( $mode eq 'copy_dir_no_raw' ) {    # copy only the required files, excluding noise and intensity files
                &log( -request => $request, -message => "Mode=copy_dir_no_raw" );
                $new_dir = &copy_flowcell_dir(
                    -flowcell     => $fc,
                    -lanes        => \@lanes,
                    -copy_from    => $copy_from,
                    -archive_host => $archive_host,
                    -request      => $request
                );
            }
            elsif ( $mode eq 'copy_dir_with_raw' ) {    # copy only the required files, including noise and intensity files
                &log( -request => $request, -message => "Mode=copy_dir_with_raw" );
                $new_dir = &copy_flowcell_dir(
                    -flowcell     => $fc,
                    -lanes        => \@lanes,
                    -raw          => 1,
                    -copy_from    => $copy_from,
                    -archive_host => $archive_host,
                    -request      => $request
                );
            }
            elsif ( $mode eq 'copy_complete_dir' ) {    # copy the full flowcell dir
                &log( -request => $request, -message => "Mode=copy_complete_dir" );
                $new_dir = &copy_complete_flowcell_dir(
                    -flowcell     => $fc,
                    -copy_from    => $copy_from,
                    -archive_host => $archive_host,
                    -request      => $request
                );
            }

            if ($new_dir) {
                $flowcell_dir = $new_dir;
                $copied{$fc} = $flowcell_dir;
                &log( -request => $request, -message => "Got new dir = $new_dir" );
            }
            else {    # the copy failed
                $failed{$fc} = 1;
                &log( -request => $request, -message => "Copy files failed" );
                &finish( -request => $request, -status => 'failed' );
                next;
            }
        }
        else {
            $flowcell_dir = $copied{$fc};
            &log( -request => $request, -message => "Flowcell dir has been copied" );
        }
    }
    else {            # go to the default flowcell directory
                      # leave it empty
        &log( -request => $request, -message => "Use default flowcell directory" );
    }

    my $lane          = $request->{lane};
    my $run_file_type = $request->{run_file_type};

    ## obtain the basecall dir from the flowcell directory
    my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $fc );
    my $current_basecall_dir = $solexa_analysis_obj->get_current_bustard_directory(
        -lane         => $lane,
        -flowcell_dir => $flowcell_dir
    );
    if ($current_basecall_dir) {
        &log(
            -request => $request,
            -message => "Basecall dir obtained: $current_basecall_dir"
        );
        &finish( -request => $request, -status => 'ready', -message => $current_basecall_dir );
    }
    else {
        &log( -request => $request, -message => "Failed in obtaining basecall dir" );
        &finish( -request => $request, -status => 'failed' );
    }
}    # END foreach $request

# remove lock file
try_system_command( -command => "rm $lock_file" );
exit;

#  function to update symbolic links
sub update_link {
    my %args = @_;
    my $dir  = $args{-dir};
    my $from = $args{-from};
    my $to   = $args{-to};

    my $message = '';

    $from =~ s|//|/|g;    # remove extra slash
    $to   =~ s|//|/|g;    # remove extra slash

    ## Data/current link
    my $current = $dir . "/Data/current";
    my $link    = readlink $current;
    $link =~ s|//|/|g;    # remove extra slash
    if ( $link =~ /$from/ ) {
        $link =~ s/$from/$to/g;

        # update the link
        `rm $current`;
        `ln -s $link $current`;
        $message .= "running ln -s $link $current\n";
    }

    ## current link in each lane sub directory
    opendir DIR, $dir;
    my @names = readdir DIR;
    foreach my $name (@names) {
        if ( $name =~ /[\w.]+\.L[1-8]$/ ) {
            my $current = $dir . "/$name/Data/current";
            my $link    = readlink $current;
            $link =~ s|//|/|g;    # remove extra slash
            if ( $link =~ /$from/ ) {
                $link =~ s/$from/$to/g;

                # update the link
                `rm $current`;
                `ln -s $link $current`;
                $message .= "running ln -s $link $current\n";
            }
        }
    }

    return $message;
}

sub copy_selected_files {
    my %args         = @_;
    my $fc           = $args{-flowcell};
    my $include_raw  = $args{-include_raw};
    my $copy_from    = $args{-copy_from};
    my $archive_host = $args{-archive_host};
    my $request      = $args{-request};
    my @lanes        = @{ $args{-lanes} };

=begin
		my @required_dirs = (
			{
				'name'		=> 'flowcell',
				'file_name'	=> '*',
				'exclude'	=> '',
			},
			{
				'name'		=> 'lane',
				'file_name'	=> '*.L',
				'exclude'	=> '',
				'sub_dir'	=> ['Data'],
			},
		
		);
=cut		

    my $stdout;
    my $stderr;
    my @from;
    my $source_flowcell_dir;

    if ($copy_from) {
        @from = ($copy_from);
    }
    else {
        my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $fc );
        @from = $solexa_analysis_obj->get_flowcell_directory();
    }

    my $count = @from;
    if ( $count < 1 ) {
        &log(
            -request => $request,
            -message => "WARNING: $fc - No flowcell directory found! Skipped!"
        );
        next;
    }
    elsif ( $count > 1 ) {
        my $fc_dir_list = join "\n", @from;

        my $latest_mod_time = 0;

        foreach my $fc_dir (@from) {
            if ( $fc_dir =~ /\/projects\/sbs_primary/ ) {
                my $mod_time = ( stat($fc_dir) )[9];    ## Get last modified time of directory

                if ( $mod_time > $latest_mod_time ) {
                    $latest_mod_time     = $mod_time;
                    $source_flowcell_dir = $fc_dir;
                }
            }

        }

        if ($source_flowcell_dir) {
            &log(
                -request => $request,
                -message => "WARNING: $fc - More than 1 flowcell directory found!\n$fc_dir_list\nUse $source_flowcell_dir\n",
            );
        }
        else {
            &log(
                -request => $request,
                -message => "WARNING: $fc - More than 1 flowcell directory found!\n$fc_dir_list\nCannot decide which dir to copy from! Skipped!",
            );
            next;
        }
    }
    else {
        $source_flowcell_dir = $from[0];
    }

    my $overwrite = 1;
    my $from_dir  = $source_flowcell_dir;
    my @items     = split /\//, $from_dir;
    my $to_dir    = $SUBMISSION_WORK_PATH . '/' . $items[$#items];

    #print "to_dir=$to_dir\n";

    ## use rsync to transfer files
    $from_dir = chop($from_dir) if ( $from_dir =~ m|.+/$| );    # remove the trailing slash
                                                                #my $complete = &run_rsync( -source_dir=>$from_dir, -dest_dir=>$SUBMISSION_WORK_PATH , -no_recursive=> 1 );

    my $all_complete = 1;
    my $from;
    my $to;
    my $include = "--include='.params'";

    ## copy from directly under flowcell dir
    $from = $from_dir . '/*';
    $to   = $to_dir;
    if ( !-d $to ) {
        &log(
            -request => $request,
            -message => "Tranferring files directly under $from_dir ..."
        );
        my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
        &log( -request => $request, -message => "$out\n$err" );
        $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
        my $complete = &run_rsync(
            -source_dir   => $from,
            -dest_dir     => $to,
            -no_recursive => 1,
            -include      => $include,
            -host         => $archive_host
        );
        $all_complete = $all_complete && $complete;
    }

    ## copy flowcell Data dir
    $from = $from_dir . '/Data';
    if ( -d $from ) {
        &log( -request => $request, -message => "Tranferring files directly under $from ..." );
        $from .= "/*";
        $to = $to_dir . '/Data';
        if ( !-d $to ) {
            my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
            &log( -request => $request, -message => "$out\n$err" );

            $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
            my $complete = &run_rsync(
                -source_dir   => $from,
                -dest_dir     => $to,
                -no_recursive => 1,
                -include      => $include,
                -host         => $archive_host
            );
            $all_complete = $all_complete && $complete;

            ## It seems "--include='.params'" doesn't work
            ## copy .params explicitly here
            $from .= $from_dir . '/Data/.params';
            if ( -e $from ) {
                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                $complete = &run_rsync(
                    -source_dir   => $from,
                    -dest_dir     => $to,
                    -no_recursive => 1,
                    -include      => $include,
                    -host         => $archive_host
                );
                $all_complete = $all_complete && $complete;
            }
        }

        ######################################################
        ## copy current dir
        my $current = $from_dir . '/Data/current';
        if ( -e $current ) {
            &log(
                -request => $request,
                -message => "Tranferring files directly under $current ..."
            );
            my $current_link = readlink $current;
            $current_link =~ s|//|/|g;    # remove extra slash
            &log( -request => $request, -message => "current_link=$current_link" );
            if ( $current_link !~ m|^/| ) {    # it is a relative path
                $current_link = $from_dir . "/Data/$current_link";
            }
            if ( -d $current_link ) {
                if ( $current_link =~ m|([^/]+/)*([^/]+)/?$| ) {
                    &log( -request => $request, -message => "current name=$2" );
                    my $current_dir  = $from_dir . "/Data/$2";
                    my $current_dest = $to_dir . "/Data/$2";
                    $to = $current_dest;
                    if ( -d $current_dir ) {
                        if ( !-d $to ) {
                            my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                            &log( -request => $request, -message => "$out\n$err" );

                            ## It seems "--include='.params'" doesn't work
                            ## copy .params explicitly here
                            $from = $current_dir . '/.params';
                            if ( -e $from ) {
                                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                my $complete = &run_rsync(
                                    -source_dir   => $from,
                                    -dest_dir     => $to,
                                    -no_recursive => 1,
                                    -include      => $include,
                                    -host         => $archive_host
                                );
                                $all_complete = $all_complete && $complete;
                            }

                            ## copy *.xml explicitly here
                            my $command = "find $current_dir -name '*.xml' -follow -maxdepth 1 -printf \"%f\n\" ";
                            &log(
                                -request => $request,
                                -message => "Running command $command"
                            );
                            ( $stdout, $stderr ) = try_system_command( -command => $command );
                            if ($stdout) {
                                $from = $current_dir . '/*.xml';
                                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                my $complete = &run_rsync(
                                    -source_dir   => $from,
                                    -dest_dir     => $to,
                                    -no_recursive => 1,
                                    -include      => $include,
                                    -host         => $archive_host
                                );
                                $all_complete = $all_complete && $complete;
                            }
                        }

                        ## copy files directly under current for each lane
                        foreach my $lane (@lanes) {
                            $from = $current_dir . "/s_$lane" . '_*';
                            my $exclude = '';
                            if ( !$include_raw ) {
                                $exclude .= "--exclude=s_$lane" . "_*_int.txt*";
                                $exclude .= " --exclude=s_$lane" . "_*_nse.txt*";
                            }
                            $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                            my $complete = &run_rsync(
                                -source_dir   => $from,
                                -dest_dir     => $to,
                                -no_recursive => 1,
                                -include      => $include,
                                -exclude      => $exclude,
                                -host         => $archive_host
                            );
                            $all_complete = $all_complete && $complete;

                        }

                        ##################################################
                        ## copy current/Matrix
                        my $matrix_dir = $current_dir . "/Matrix";
                        if ( -d $matrix_dir ) {
                            &log(
                                -request => $request,
                                -message => "Tranferring files directly under $matrix_dir ..."
                            );
                            $to = $current_dest . "/Matrix";
                            if ( !-d $to ) {
                                my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                                &log( -request => $request, -message => "$out\n$err" );
                            }
                            foreach my $lane (@lanes) {
                                $from = $matrix_dir . "/s_$lane" . '_*';
                                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                my $complete = &run_rsync(
                                    -source_dir   => $from,
                                    -dest_dir     => $to,
                                    -no_recursive => 1,
                                    -include      => $include,
                                    -host         => $archive_host
                                );
                                $all_complete = $all_complete && $complete;
                            }
                        }

                        ##################################################
                        ## copy current/Firecrest
                        my $firecrest_dir = $current_dir . "/Firecrest";
                        if ( -d $firecrest_dir ) {
                            &log(
                                -request => $request,
                                -message => "Tranferring files directly under $firecrest_dir ..."
                            );
                            $to = $current_dest . "/Firecrest";
                            if ( !-d $to ) {
                                my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                                &log( -request => $request, -message => "$out\n$err" );
                            }
                            foreach my $lane (@lanes) {
                                $from = $firecrest_dir . "/s_$lane" . '_*';
                                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                my $complete = &run_rsync(
                                    -source_dir   => $from,
                                    -dest_dir     => $to,
                                    -no_recursive => 1,
                                    -include      => $include,
                                    -host         => $archive_host
                                );
                                $all_complete = $all_complete && $complete;
                            }
                        }    # END $firecrest_dir

                        ##################################################
                        ## copy current/Bustard or current/BaseCalls
                        my @base_call_dirs = ( "Bustard*", "BaseCalls" );
                        foreach my $base_call_dir (@base_call_dirs) {

                            #my $command = "find $current_dir -name 'Bustard*' -type d -follow -maxdepth 1 -printf \"%f\n\" ";
                            my $command = "find $current_dir -name $base_call_dir -type d -follow -maxdepth 1 -printf \"%f\n\" ";
                            &log(
                                -request => $request,
                                -message => "Running command $command"
                            );
                            ( $stdout, $stderr ) = try_system_command( -command => $command );
                            if ($stdout) {
                                &log( -request => $request, -message => "$stdout" );
                                my @base_call_dirs_found = split /\n/, $stdout;
                                foreach my $base_call_dir_found (@base_call_dirs_found) {
                                    $to = $current_dest . "/$base_call_dir_found";
                                    &log(
                                        -request => $request,
                                        -message => "Tranferring files directly under $base_call_dir_found ..."
                                    );
                                    if ( !-d $to ) {
                                        my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                                        &log( -request => $request, -message => "$out\n$err" );

                                        ## copy *.xml explicitly here
                                        my $command = "find $current_dir/$base_call_dir_found -name '*.xml' -follow -maxdepth 1 -printf \"%f\n\" ";
                                        &log(
                                            -request => $request,
                                            -message => "Running command $command"
                                        );
                                        ( $stdout, $stderr ) = try_system_command( -command => $command );
                                        if ($stdout) {
                                            $from = $current_dir . "/$base_call_dir_found/*.xml";
                                            $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                            my $complete = &run_rsync(
                                                -source_dir   => $from,
                                                -dest_dir     => $to,
                                                -no_recursive => 1,
                                                -include      => $include,
                                                -host         => $archive_host
                                            );
                                            $all_complete = $all_complete && $complete;
                                        }
                                    }
                                    foreach my $lane (@lanes) {
                                        $from = $current_dir . "/$base_call_dir_found/s_$lane" . '_*';
                                        $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                        my $complete = &run_rsync(
                                            -source_dir   => $from,
                                            -dest_dir     => $to,
                                            -no_recursive => 1,
                                            -include      => $include,
                                            -host         => $archive_host
                                        );
                                        $all_complete = $all_complete && $complete;
                                    }

                                    ##################################################
                                    ## copy current/Bustard/Phasing
                                    my $phasing_dir = $current_dir . "/$base_call_dir_found/Phasing";
                                    if ( -d $phasing_dir ) {
                                        &log(
                                            -request => $request,
                                            -message => "Tranferring files directly under $phasing_dir ..."
                                        );
                                        $to = $current_dest . "/$base_call_dir_found/Phasing";
                                        if ( !-d $to ) {
                                            my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                                            &log(
                                                -request => $request,
                                                -message => "$out\n$err"
                                            );
                                        }
                                        foreach my $lane (@lanes) {
                                            $from = $phasing_dir . "/s_$lane" . '_*';
                                            $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                            my $complete = &run_rsync(
                                                -source_dir   => $from,
                                                -dest_dir     => $to,
                                                -no_recursive => 1,
                                                -include      => $include,
                                                -host         => $archive_host
                                            );
                                            $all_complete = $all_complete && $complete;
                                        }
                                    }

                                    ##################################################
                                    ## copy current/Bustard/Matrix
                                    my $matrix_dir = $current_dir . "/$base_call_dir_found/Matrix";
                                    if ( -d $matrix_dir ) {
                                        &log(
                                            -request => $request,
                                            -message => "Tranferring files directly under $matrix_dir ..."
                                        );
                                        $to = $current_dest . "/$base_call_dir_found/Matrix";
                                        if ( !-d $to ) {
                                            my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                                            &log(
                                                -request => $request,
                                                -message => "$out\n$err"
                                            );
                                        }
                                        foreach my $lane (@lanes) {
                                            $from = $matrix_dir . "/s_$lane" . '_*';
                                            $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                                            my $complete = &run_rsync(
                                                -source_dir   => $from,
                                                -dest_dir     => $to,
                                                -no_recursive => 1,
                                                -include      => $include,
                                                -host         => $archive_host
                                            );
                                            $all_complete = $all_complete && $complete;
                                        }

                                    }

                                }    # END foreach $base_call_dir_found
                            }
                        }    # END foreach $base_call_dir
                    }
                }
            }    # END if( -d $current_link )
        }

    }

    ## copy lane dirs
    foreach my $lane (@lanes) {
        my $file_name = "*.L$lane";
        my $command   = "find $from_dir -name '$file_name' -type d -follow -maxdepth 1 -printf \"%f\n\" ";
        &log( -request => $request, -message => "Running command $command" );
        ( $stdout, $stderr ) = try_system_command( -command => $command );
        if ($stdout) {
            my @lane_dirs = split /\n/, $stdout;
            foreach my $lane_dir (@lane_dirs) {
                $from = $from_dir . '/' . $lane_dir . '/*';
                $to   = $to_dir . '/' . $lane_dir;
                if ( !-d $to ) {
                    my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                    &log( -request => $request, -message => "$out\n$err" );
                }
                $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                my $complete = &run_rsync(
                    -source_dir   => $from,
                    -dest_dir     => $to,
                    -no_recursive => 1,
                    -include      => $include,
                    -host         => $archive_host
                );
                $all_complete = $all_complete && $complete;

                ## Data dir
                $from = $from_dir . '/' . $lane_dir . '/Data';
                $to   = $to_dir . '/' . $lane_dir . '/Data';
                if ( -d $from ) {
                    if ( !-d $to ) {
                        my ( $out, $err ) = try_system_command( -command => "mkdir $to" );
                        &log( -request => $request, -message => "$out\n$err" );
                    }
                    $from .= "/*";
                    $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                    my $complete = &run_rsync(
                        -source_dir   => $from,
                        -dest_dir     => $to,
                        -no_recursive => 1,
                        -include      => $include,
                        -host         => $archive_host
                    );
                    $all_complete = $all_complete && $complete;
                }
                else {
                    &log(
                        -request => $request,
                        -message => "WARNING: No $from found for copying!"
                    );
                }

                ## Old data has a different file structure. The seq files may be directly under each lane dir.
                ## In this case, simply copy the whole analysis directory over including raw files for simplicity.
                my $current = $from_dir . '/' . $lane_dir . '/Data/current';
                if ( -l $current ) {
                    my $current_link = readlink $current;
                    $current_link =~ s|//|/|g;    # remove extra slash
                                                  #print "current_link=$current_link\n";
                    if ( $current_link !~ m|^/| ) {    # it is a relative path
                        my $from = $from_dir . '/' . $lane_dir . "/Data/$current_link";
                        my $to   = $to_dir . '/' . $lane_dir . "/Data";
                        $from =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
                        my $complete = &run_rsync(
                            -source_dir   => $from,
                            -dest_dir     => $to,
                            -no_recursive => 0,
                            -host         => $archive_host
                        );
                        $all_complete = $all_complete && $complete;
                    }
                }
            }
        }
        else {
            &log( -request => $request, -message => "WARNING: No dirs found for lane $lane" );
        }
    }

    if ($all_complete) {
        &log( -request => $request, -message => "Copying flowcell directory completed!" );
    }
    else {
        &log(
            -request => $request,
            -message => "ERROR occurred in copying flowcell directory!"
        );

        #exit;
    }

    ## update the symbolic links
    my $msg = &update_link( -dir => $to_dir, -from => $from_dir, -to => $to_dir );
    &log( -request => $request, -message => $msg );

    return $to_dir;

}

#######################################################
# Retrieve the requests and sort the requests by time
#
# Usage		: my @requests =  @{get_requests()};
#
# Return	: array ref of the sorted requests. Each array item is a hash ref of the details of the request.
#######################################################
sub get_requests {
############################
    my %requests;

    my $command = "find $SUBMISSION_WORK_PATH -name 'Run*' -maxdepth 1 -printf \"%f\n\" ";
    my ( $output, $stderr ) = try_system_command( -command => $command );
    if ($output) {
        my @run_dirs = split /\n/, $output;
        foreach my $run_dir (@run_dirs) {
            $command = "find $SUBMISSION_WORK_PATH/$run_dir -name '.request_*' -maxdepth 1 -printf \"%f\n\" ";
            ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {
                ## get the run id
                if ( $run_dir =~ /Run(\d+)/ ) {
                    my $run_id = $1;
                    my @request_files = split /\n/, $output;
                    foreach my $request (@request_files) {
                        if ( $request =~ /request_(.*)/ ) {
                            my $run_file_type = $1;
                            $requests{$run_id}{$run_file_type} = 1;
                        }
                    }
                }
            }
        }
    }
    return &sort_requests( -requests => \%requests );
}

#######################################################
# Sort the requests by last modified time
#
# Usage		: my $sorted =  sort_requests( -requests => \%requests );
#
# Return	: array ref of the sorted requests. Each array item is a hash ref of the details of the request.
#######################################################
sub sort_requests {
############################
    my %args = filter_input( \@_, -args => 'requests' ) or err ("Improper input");
    my $requests = $args{-requests};

    my %when;
    foreach my $run_id ( keys %$requests ) {
        foreach my $type ( keys %{ $requests->{$run_id} } ) {
            my $request_file  = "$SUBMISSION_WORK_PATH/Run$run_id/.request_$type";
            my @last_mod_time = try_system_command( -command => "stat -c %Y $request_file" );
            my $last_mod_time = chomp_edge_whitespace( $last_mod_time[0] );
            my $key           = "$run_id" . '_' . $type;
            $when{$key}{time}          = $last_mod_time;
            $when{$key}{run_id}        = $run_id;
            $when{$key}{run_file_type} = $type;
        }
    }

    my @sorted = ();
    foreach my $key ( sort { $when{$a}{time} <=> $when{$b}{time} } keys %when ) {    # sort by request time
        my %request;
        $request{run_id}        = $when{$key}{run_id};
        $request{run_file_type} = $when{$key}{run_file_type};
        push @sorted, \%request;
    }

    return \@sorted;
}

sub copy_flowcell_dir {
    my %args = filter_input(
         \@_,
        -args      => 'flowcell,lanes,raw,copy_from,archive_host,request',
        -mandatory => 'flowcell,lanes'
    ) or err ("Improper input");
    my $fc           = $args{-flowcell};
    my $lanes        = $args{-lanes};
    my $with_raw     = $args{-raw};
    my $copy_from    = $args{-copy_from};
    my $archive_host = $args{-archive_host};
    my $request      = $args{-request};

    if ($with_raw) {
        &log( -request => $request, -message => "The -copy_dir_with_raw option is chosen" );
    }
    else { &log( -request => $request, -message => "The -copy_dir_no_raw option is chosen" ) }

    ## copy over the required files from the flowcell directory
    my $benchmark_copy_start = new Benchmark;
    my $new_dir              = &copy_selected_files(
        -flowcell     => $fc,
        -include_raw  => $with_raw,
        -copy_from    => $copy_from,
        -archive_host => $archive_host,
        -lanes        => $lanes,
        -request      => $request
    );
    my $benchmark_copy_end = new Benchmark;
    my $copy_time = timestr( timediff( $benchmark_copy_end, $benchmark_copy_start ) );
    &log( -request => $request, -message => "$fc copying time = [$copy_time] wallclock secs" );
    return $new_dir;
}

sub copy_complete_flowcell_dir {
    my %args = filter_input(
         \@_,
        -args      => 'flowcell,copy_from,archive_host,request',
        -mandatory => 'flowcell'
    ) or err ("Improper input");
    my $fc           = $args{-flowcell};
    my $copy_from    = $args{-copy_from};
    my $archive_host = $args{-archive_host};
    my $request      = $args{-request};

    &log( -request => $request, -message => "The -copy_complete_dir option is chosen" );
    ## copy over the full directory
    #my @from = $solexa_analysis_obj->get_flowcell_directory();
    my @from;
    if ($copy_from) {
        @from = ($copy_from);
    }
    else {
        my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $fc );
        @from = $solexa_analysis_obj->get_flowcell_directory();
    }
    my $count = @from;
    if ( $count < 1 ) {
        &log(
            -request => $request,
            -message => "WARNING: $fc - No flowcell directory found! Skipped!"
        );
        return 0;
    }
    elsif ( $count > 1 ) {

        &log(
            -request => $request,
            -message => "WARNING: $fc - More than 1 flowcell directory found! Cannot decide which dir to copy from! Skipped!"
        );
        return 0;
    }

    my $overwrite = 1;
    my $from_dir  = $from[0];
    my @items     = split /\//, $from_dir;
    my $to_dir    = $SUBMISSION_WORK_PATH . '/' . $items[$#items];

    #if( -e $to_dir && $overwrite ) {
    #	($stdout, $stderr ) = try_system_command(-command=>"rm -r $to_dir");
    #	print "$stdout";
    #	print "$stderr";
    #}

    ## use rsync to transfer files
    $from_dir = chop($from_dir) if ( $from_dir =~ m|.+/$| );    # remove the trailing slash
    my $benchmark_copy_start = new Benchmark;
    $from_dir =~ s|/gsc/archive|/archive_vault|g if ( $archive_host && $archive_host =~ /lhost/ );    # replace /gsc/archive with /archive_vault
    my $complete = &run_rsync(
        -source_dir => $from_dir,
        -dest_dir   => $SUBMISSION_WORK_PATH,
        -host       => $archive_host
    );
    my $benchmark_copy_end = new Benchmark;
    my $copy_time = timestr( timediff( $benchmark_copy_end, $benchmark_copy_start ) );
    &log( -request => $request, -message => "$fc copying time = [$copy_time] wallclock secs" );

    if ($complete) {
        &log( -request => $request, -message => "Copying flowcell directory completed!" );
    }
    else {
        &log(
            -request => $request,
            -message => "ERROR occurred in copying flowcell directory!"
        );

        #exit;
    }

    ## update the symbolic links
    my $msg = &update_link( -dir => $to_dir, -from => $from_dir, -to => $to_dir );
    &log( -request => $request, -message => $msg );

    return $to_dir;
}

#########
sub log {
########
    my %args    = filter_input( \@_, -args => 'request,message', -mandatory => 'message' );
    my $request = $args{-request};
    my $message = $args{-message};

    my $timestamp = &date_time();
    push @{ $request->{log} }, "$timestamp: $message" if ($request);
    print "$timestamp: $message\n";
    return;
}

######################
# This function does the final cleanup. It first writes the log to the log file, and then creates the status file
# It supports two valid statuses: ready,  failed

# Usage:	finish( -request => $request, -status => 'ready', -message => $msg );
#			finish( -request => $request, -status => 'failed' );
#
# Retrun:	None
######################
sub finish {
    my %args = filter_input(
         \@_,
        -args      => 'request,status,message',
        -mandatory => 'request,status'
    );
    my $request = $args{-request};
    my $status  = $args{-status};
    my $message = $args{-message};

    my $run_data_dir  = "$target_dir/Run" . $request->{run_id} . $run_dir_suffix;
    my $run_file_type = $request->{run_file_type};

    ## write the log to the file
    my $logs          = join "\n", @{ $request->{log} };
    my $log_file_name = "run" . $request->{run_id} . ".log";
    my $log_file      = "$run_data_dir/$log_file_name";
    if ( !-e $log_file ) {
        my $log_file_ok = RGTools::RGIO::create_file( -name => $log_file_name, -content => "$logs\n", -path => $run_data_dir, -chgrp => 'lims', -chmod => 'g+w' );
    }
    else {
        open my $LOG, ">>", "$log_file";
        print $LOG "$logs\n";
        close($LOG);
    }

    ## create status file
    my $filename;
    my $status_file;
    if ( $status =~ /ready/ ) {
        $filename = ".obtain_basecall_dir.ready" . "_$run_file_type";
    }
    elsif ( $status =~ /fail/ ) {
        $filename = ".obtain_basecall_dir.failed" . "_$run_file_type";
    }
    $status_file = "$run_data_dir/$filename";
    my $status_file_ok = RGTools::RGIO::create_file( -name => $filename, -content => $message, -path => $run_data_dir, -chgrp => 'lims', -chmod => 'g+w' );

    ## remove request file
    my $request_file = "$run_data_dir/.request_$run_file_type";
    if ( -e $request_file ) {
        try_system_command( -command => "rm -rf $request_file" );
    }
}

sub display_help {
    print <<HELP;

Syntax
======
get_basecall_dir.pl - This script gets the basecall dir for the use of creating run data files for data submission. It either grabs an existing basecall dir, or copy the flowcell dir to the data submission workspace and return the new basecall dir. The basecall dir that need to be returned is stored in the status file .obtain_basecall_dir.ready_\$type of each run data dir.

Arguments:
=====

-- required arguments --
-host			: specify database host, ie: -host limsdev02 
-dbase, -d		: specify database, ie: -d seqdev. 
-user, -u		: specify database user. 
-passowrd, -p		: password for the user account

-- choice arguments ( One and only one must be used ) --
-runs			: specify the run ids in comma separated list format
-flowcells		: specify flowcell codes in comma separated list format. All the runs of these flowcells will be processed.

-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-include			: specify the the condition of including approved and Production/Test runs. Default 'Approved,Production'
-include_raw		: flag to include raw data
-run_file_type		: specify he run file type, e.g. SRF, fastq. Default is SRF
-target_dir			: specify the directory to create the run data folder. Default is the data submission workspace directory that is specified in $Configs{data_submission_workspace_dir}.
-run_dir_suffix		: specify the suffix of the run data directory. 
-flowcell_dir		: use the files in the specified flowcell directory to create run data file
-bustard_dir		: use the files in the specified basecall directory to create run data file
-mode				: specify how to get the basecall dir. Valid modes include: search_submission_path, copy_dir_no_raw, copy_dir_with_raw, copy_complete_dir.
					  'search_submission_path'	- search the flowcell dirs from the data submission workspace
					  'copy_dir_no_raw'			- copy only the required files, excluding the raw files ( noise and intensity files ).
					  'copy_dir_with_raw'		- copy only the required files, including raw files ( noise and intensity files )
					  'copy_complete_dir'		- copy the full flowcell dir
					  The default mode is 'copy_dir_no_raw'.
-copy_from			: specify the source flowcell dir for copying
-archive_host		: the archive host for rsync to speed up the copy process. This is used when copying dir is needed ( mode: 'copy_dir_no_raw', 'copy_dir_with_raw', 'copy_complete_dir' ).
	
				  
Example
=======
get_basecall_dir.pl -host lims05 -d seqtest -u user -p xxxxxx -runs 10779,10881 -mode search_submission_path
get_basecall_dir.pl -host lims05 -d seqtest -u user -p xxxxxx -flowcells 616GYAAXX,600JAAAXX -mode copy_dir_no_raw -archive_host lhost01 


HELP

}
