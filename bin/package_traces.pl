#!/usr/local/bin/perl

##############################################################################################
# Quick program written to package compressed Trace files 
##############################################################################################

## standard perl modules ##
use CGI qw(:standard fatalsToBrowser);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);
use Storable;
use Statistics::Descriptive;
use Data::Dumper;
use Digest::MD5;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Net::FTP;

use strict;

## Local perl modules ##

# (generic modules)
use RGTools::RGIO;
use RGTools::Conversion;

# (SQL database modules)
 
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

# (alDente modules)
use alDente::Run;
use alDente::Container;
use alDente::Clone;
use alDente::SDB_Defaults;

# (Sequencing specific modules)
use Sequencing::Sequencing_API;

# (locally imported modules)
use Imported::XML::Dumper;

##############################
# global_vars                #
##############################
use vars qw($testing $Connection $ftp);
#use vars qw($opt_t $opt_g $opt_l $opt_p $opt_r $opt_x $opt_f $opt_L $opt_X $opt_a $opt_R $opt_P $opt_v $opt_u $opt_O $opt_d $opt_c);
use vars qw($opt_limit $opt_include $opt_library $opt_plate $opt_run $opt_group $opt_append $opt_compress $opt_remove $opt_include_poor $opt_force $opt_xml $opt_quiet $opt_verbose $opt_update $opt_target $opt_date $opt_comment $opt_path $opt_name $opt_user $opt_password $opt_min_length $opt_submission_type $opt_trace_list_file $opt_F $opt_R $opt_upload $opt_monitor $opt_project $opt_volumes $opt_volume $opt_sample $opt_type $opt_measure $opt_measure_by $opt_copy_traces);

#require "getopts.pl";
use Getopt::Long;
&GetOptions('limit=s'     => \$opt_limit,
	    'library=s'     => \$opt_library,
	    'plate=s'     => \$opt_plate,
	    'run=s'     => \$opt_run,
	    'group=s'     => \$opt_group,
	    'remove=s'     => \$opt_limit,
	    'update=s'     => \$opt_update,
	    'target=s'     => \$opt_target,
	    'date=s'     => \$opt_date,
	    'comment=s'     => \$opt_comment,
	    'path=s'     => \$opt_path,
	    'name=s'     => \$opt_name,
            'user=s'        => \$opt_user,
            'password=s'    => \$opt_password,
	    'min_length=s'  => \$opt_min_length,
	    'F=s'           => \$opt_F,
	    'R=s'           => \$opt_R,
            'submission_type=s'    => \$opt_submission_type,
            'trace_list_file=s'    => \$opt_trace_list_file,
            'upload=s'    => \$opt_upload,
	    'volume=s'   => \$opt_volume,
	    'volumes=s'   => \$opt_volumes,
            'project=s'    => \$opt_project,
            'sample=s'    => \$opt_sample,
	    'type=s'      => \$opt_type,
	    'include=s'   => \$opt_include,
	                                       ## booleans ##
            'monitor'    => \$opt_monitor,
	    'compress'     => \$opt_compress,
	    'quiet'     => \$opt_quiet,
	    'verbose'     => \$opt_verbose,
	    'remove'     => \$opt_remove,
	    'append'     => \$opt_append,
            'xml'         => \$opt_xml,
            'force'       => \$opt_force,
            'include_poor'    => \$opt_include_poor,
	    'measure' =>\$opt_measure,
	    'measure_by'=>\$opt_measure_by,
	    'copy_traces'=>\$opt_copy_traces,
            );

## parse input options ##
my $type      = $opt_type;
my $include   = $opt_include || 'production,approved';  ## indicate runs to be included (defaults to production, approved.
my $run_limit = $opt_limit || 5000;            ## limit of number of traces to group in one tarred file
my $library = $opt_library;                      ## provide Library  
my $plate_number = $opt_plate;                 ## provide plate number (or list / range) (optional with library)
my $run_id       = $opt_run;                 ## ... or provide run id (or list) 
my $sample       = Cast_List(-list=>$opt_sample,-to=>'string');     ## ... or provide sample ids 
my $group_by  = $opt_group;                    ## group volumes 
my $append    = $opt_append;                   ## append current volume
my $compress       = $opt_compress;
my $remove = '--remove_files' if $opt_remove;   ## 
my $group;

my $include_poor = $opt_include_poor || 0;     ## include poor quality (no quality length) reads
my $min_length   = $opt_min_length || 0;
my $force = $opt_force || 0;                   ## force execution without feedback check.
my $xml  = $opt_xml;
my $verbose = $opt_verbose;
my $update_volume = $opt_update;                ## indicate current volume if this for updating or appending 
my $target_organization = $opt_target;
my $submission_date = $opt_date || &date_time();
my $comments = $opt_comment || '';
my $path = $opt_path || '.';
my $basename = $opt_name || $opt_library || 'trace_files';  ## default to library name if entire library submitted (default)
my $user = $opt_user || 'viewer';
my $password = $opt_password || 'viewer';
my $submission_type = $opt_submission_type || 'new';
my $trace_list_file = $opt_trace_list_file;
my $upload = $opt_upload;
my $monitor = $opt_monitor;
my $project = $opt_project;
my $volumes = $opt_volumes || 1;
my $volume = $opt_volume || '';
my $quiet = $opt_quiet || 1;             ## always quiet !! (?)
my $measure = $opt_measure;# || 'quality_length';
my $measure_by = $opt_measure_by || 'CLONE_ID';
my $copy_traces = $opt_copy_traces || 1;
#my $key_field = 'PRIMER_CODE';
my $key_field = 'TRACE_END';
## Check if measure is valid?

## Default file extension for TraceInfo
my $ext = 'txt';
if ($xml) { $ext = 'xml' }       ## adapt file extension if xml format specified

my $dbase = 'sequence';   ## production database
my $host  = 'lims01';   ## slave
my $user  = 'viewer';
my $password = 'viewer';

## initialize variables ##
my $target = $opt_target;
my $log       = "$target.log";

Message("Connecting to $host:$dbase as $user");
my $API = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-DB_password=>$password,-DB_user=>$user,-debug=>1);
my $dbc = $API->connect_to_DB();

Message("Getting $library trace files -> $target");
$API->get_trace_files(-library=>$library,-copy=>$target);
Message("Copied files to $target");

Message("To compress try 'tar -czvf $target.tgz $target'");

$API->disconnect();
exit;
