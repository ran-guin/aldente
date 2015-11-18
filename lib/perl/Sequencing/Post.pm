###############################################################
#
#  Sequencing::Post
#
# This program updates the sequence SQL database by
# running phred and extracting sequence and quality information
# from generated phred files.
#
# "You don't see many rabbits being walked down the street,
#  and you don't see cats on leads."
#
###############################################################
package Sequencing::Post;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Post.pm - Sequencing::Post

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
SDB::Post<BR>This program updates the sequence SQL database by<BR>running phred and extracting sequence and quality information<BR>from generated phred files.<BR>"You don't see many rabbits being walked down the street,<BR>and you don't see cats on leads."<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;

##############################
# standard_modules_ref       #
##############################

use strict;
use POSIX qw(strftime);
use Statistics::Descriptive;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use Sequencing::Tools qw(SQL_phred);
use Sequencing::Sequence;
use alDente::Container;
use Sequencing::Sample_Sheet;
use alDente::SDB_Defaults;
use Sequencing::Read;
use SDB::Report;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;

##############################
# global_vars                #
##############################
our @ISA = qw(Exporter);
use vars qw($project_dir $Connection);
use vars qw($URL_dir $mirror);
use vars qw($testing $Web_log_directory $Data_log_directory $vector_directory $run_maps_dir);
use vars qw($phred_dir $trace_dir $edit_dir $poly_dir);
use vars qw($trace_file_ext1 $failed_trace_file_ext1);
use vars qw($trace_file_ext1 $failed_trace_file_ext2);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
our @EXPORT = qw(
    get_run_info
    get_mirrored_data
    get_analyzed_data
    zip_trace_files
    run_phred
    run_crossmatch
    parse_screen_file
    parse_phred_scores
    check_phred_version
    screen_contaminants
    create_colour_map
    init_clone_sequence_table
    update_datetime
    update_source
    clear_phred_files
    get_run_statistics
    update_run_statistics
    create_temp_screen_file
);
my $vseq;
my @fields;
my @values;
my $stop       = 0;
my $stamp      = &RGTools::RGIO::timestamp();
my $log_file   = $Web_log_directory . "/update_sequence/update_$stamp";
my $PHRED_FILE = "/opt/alDente/software/sequencing/phred/current/phred";
my $phred_version;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

######################
sub get_run_info {
######################
    # get a whole bunch of information from the SQL database based on run id
    # and store it in a nice hash

    my $dbc = shift || $Connection;
    my $sequence_id = shift;

    my %ri;    # ri stands for Run Info
    $ri{'sequence_id'} = $sequence_id;

    # get Run and Equipment info
    my %sequence_info = $dbc->Table_retrieve(
        'SequenceRun,Run,RunBatch,Equipment,Plate,Branch',
        [   'Run_ID as run_id',
            'FK_Plate__ID as plate_id',
            'Branch_Code as chemcode',
            'Run_Directory as subdirectory',
            'Equipment_ID as Mid',
            'Equipment_Name as Mname',
            'RunBatch.FK_Employee__ID as user_id',
            'FKPrimer_Solution__ID as primer_id',
            'To_Days(NOW()) - To_Days(Run_DateTime) as days_ago'
        ],
        "WHERE SequenceRun.FK_Run__ID=Run_ID AND FK_RunBatch__ID=RunBatch_ID AND Run.FK_Plate__ID=Plate_ID AND Plate.FK_Branch__Code=Branch_Code AND Run_ID=$ri{'sequence_id'} AND RunBatch.FK_Equipment__ID=Equipment_ID  Order by Run_DateTime"
    );

    # get just slice info - separate query because &Table_find returns a comma-delimited list, and the slice column is also comma-delimited
    my @slice_info = $dbc->Table_find( 'Run,SequenceRun', 'Slices', "where FK_Run__ID=Run_ID AND Run_ID=$ri{'sequence_id'} Order by Run_DateTime" );

    if ( scalar( @{ $sequence_info{'run_id'} } ) == 1 ) {
        unless ( $sequence_info{'run_id'}[0] =~ /[1-9]/ ) {
            Seq_Notes( $0, $ri{'sequence_id'} . " Error: NULL Query generated", 'text', $log_file );
            return {};
        }
    }
    else {
        my $found = scalar( @{ $sequence_info{'run_id'} } );
        Seq_Notes( $0, "Warning: Strange number of finds ($found) for Run" . $ri{'sequence_id'}, 'text', $log_file );
        return {};
    }

    #  ($ri{'plate_id'}, $ri{'chemcode'}, $ri{'subdirectory'}, $ri{'Mid'}, $ri{'Mname'}, $ri{'user_id'},$ri{'primer_id'}) = split ',', $sequence_info[0];
    foreach my $key ( keys %sequence_info ) {
        $ri{$key} = $sequence_info{$key}[0];
    }
    print HTML_Dump( \%ri );

    if ( ( $slice_info[0] eq 'NULL' ) || ( $slice_info[0] eq "" ) ) {
        $ri{'num_slices'} = 0;
    }
    else {
        my @slices = split ',', $slice_info[0];
        $ri{'num_slices'} = scalar(@slices);
    }

## Establish Sequencer type ##
    if ( $ri{'Mname'} =~ /^MB(\d+)$/ ) {
        $ri{'Mtype'} = 'Megabace';
    }
    elsif ( $ri{'Mname'} =~ /^D3\d\d\d-/ ) {
        $ri{'Mtype'} = 'ABI';
    }
    else {
        Seq_Notes( $0, $ri{'sequence_id'} . "Error: Unrecognized Machine Name ($ri{'Mname'})", 'text', $log_file );
    }

    my %Info = &Table_retrieve(
        $dbc,
        'Machine_Default,Sequencer_Type',
        [ 'Local_Samplesheet_dir', 'Local_Data_Dir', 'TraceFileExt', 'FailedTraceFileExt', 'FileFormat', 'RunDirectory', 'Capillaries' ],
        "where FK_Sequencer_Type__ID=Sequencer_Type_ID AND FK_Equipment__ID = $ri{'Mid'}"
    );

    my $local_drive = $mirror_dir . '/' . $Info{Local_Data_Dir}[0];
    my $archived    = $local_drive;
    $archived =~ s /\/mirror\//\/archive\//;

    my $local_sample_sheets = $Info{Local_Samplesheet_dir}[0];

    # get Employee name
    $ri{'user'} = join ',', $dbc->Table_find( 'Employee', 'Employee_Name', "where Employee_ID = " . $ri{'user_id'} );

    # get plate info
    $ri{'parents'} = alDente::Container::get_Parents( -dbc => $dbc, -id => $ri{'plate_id'}, -format => 'list', -simple => 1 );
    my @plate_info
        = $dbc->Table_find( 'Plate,Library,Library_Plate', "Library_Name,Plate_Number,Plate.Parent_Quadrant,FK_Project__ID,Plate_Size", "WHERE FK_Library__Name = Library_Name and FK_Plate__ID = Plate_ID and Plate_ID in ($ri{'plate_id'})", 'Distinct' );
    ( $ri{'library'}, $ri{'plate_number'}, $ri{'quadrant'}, $ri{'proj_id'}, $ri{'plate_size'}, $ri{'vector'} ) = split ',', $plate_info[0];
    ( $ri{'vector'} ) = $dbc->Table_find( 'LibraryVector,Vector, Vector_Type', "Vector_Type_Name", "WHERE FK_Library__Name = '$ri{'library'}' and FK_Vector__ID = Vector_ID and FK_Vector_Type__ID = Vector_Type_ID" );

    if ( scalar(@plate_info) > 1 ) {

        # changed to non-fatal error caused by multiple Vectors per Library (straight-join problem)
        Seq_Notes( $0, $ri{'sequence_id'} . " Warning: more than one Plate or Vector found", 'text', $log_file );

        #    return {};
    }
    if ( !$ri{'quadrant'} ) { $ri{'quadrant'} = ""; }

    $ri{'project_dir'} = join ',', $dbc->Table_find( 'Project', 'Project_Path', 'where Project_ID="' . $ri{'proj_id'} . '"' );
    $ri{'path'}        = $project_dir . '/' . $ri{'project_dir'} . '/' . $ri{'library'};
    $ri{'savedir'}     = "$ri{'path'}/AnalyzedData";
    $ri{'basename'}    = $ri{'library'} . '-' . $ri{'plate_number'} . $ri{'quadrant'};
    $ri{'chemcode'}    = "." . $ri{'chemcode'};

    # Information dependant on 96 or 384 wells
    my $info = join ',', $dbc->Table_find( 'MultiPlate_Run', 'FKMaster_Run__ID,MultiPlate_Run_Quadrant', "where FK_Run__ID=$ri{'sequence_id'}" );

    # yes, this run is part of a multi-plate run
    if ( $info =~ /\d+/ ) {
        ( $ri{'Master_id'}, $ri{'Master_quadrant'} ) = split ',', $info;
        my $basename = join ',', $dbc->Table_find( 'Run', 'Run_Directory', "where Run_ID=$ri{'Master_id'}" );

        #<Construction> This run directory name parsing needs to be updated
        my ($lib) = $dbc->Table_find( 'Run,Plate', 'FK_Library__Name', "where Run_ID=$ri{'Master_id'} and FK_Plate__ID = Plate_ID" ); #$ri{'library'};
        $basename =~ m/^($lib\-[\d]+[a-zA-Z]?)(\.[\w]+)(.*)/;
        $ri{'Master_basename'} = $1;
        $ri{'Master_chemcode'} = $2;
        $ri{'Master_version'}  = $3;

        my @sub_runs;
        my %sub_384_name;
        @sub_runs = $dbc->Table_find( 'MultiPlate_Run', 'FK_Run__ID,MultiPlate_Run_Quadrant', "where FKMaster_Run__ID = $ri{'Master_id'}" );
        foreach my $sub_run (@sub_runs) {
            ( my $id, my $thisquad ) = split ',', $sub_run;
            ( $sub_384_name{$thisquad} ) = $dbc->Table_find( 'Run', 'Run_Directory', "where Run_ID = $id" );
        }
        $ri{'sub_384_name'}      = \%sub_384_name;
        $ri{'convert_96_to_384'} = 'YES';

        $ri{'files_required'} = int(@sub_runs) * 96;
    }

    # no, this run was just a lone 96 or 384 well run
    else {
        $ri{'Master_basename'}   = $ri{'basename'};
        $ri{'Master_chemcode'}   = $ri{'chemcode'};
        $ri{'Master_quadrant'}   = $ri{'quadrant'};
        $ri{'convert_96_to_384'} = 'NO';

        # if the plate size is 384, check how many quadrants are used
        if ( $ri{'plate_size'} =~ /(\d+)/ ) {
            my $plate_size = $1;
            if ( $plate_size =~ /384/ ) {
                my ($quads) = $dbc->Table_find( "Library_Plate", "Sub_Quadrants", "WHERE FK_Plate__ID='$ri{'plate_id'}'" );
                if ( $quads =~ /none/ ) {

                    # failsafe: none quadrants should NEVER happen
                    $ri{'files_required'} = $plate_size;
                }
                else {
                    my @quad_array = split ',', $quads;
                    my $quad_count = scalar(@quad_array);
                    if ( $quad_count > 4 ) {
                        $quad_count = 4;
                    }

                    # failsafe: if no quadrants are defined, set quadrant count to 4 anyway
                    if ( $quad_count == 0 ) {
                        $quad_count = 4;
                    }
                    $ri{'files_required'} = $quad_count * 96;
                }
            }
            else {

                # plate is 96-well
                $ri{'files_required'} = $plate_size;
            }
        }
        else {
            Seq_Notes( $0, $ri{'sequence_id'} . " Error in Plate Size ($ri{'plate_size'})", 'text', $log_file );
            return {};
        }
    }
    if ( $ri{'subdirectory'} =~ /^$ri{'basename'}$ri{'chemcode'}([.]\d+)/ ) {
        $ri{'version'} = $1;
    }
    elsif ( $ri{'subdirectory'} =~ /^$ri{'basename'}$ri{'chemcode'}/ ) {
        $ri{'version'} = "";
    }
    elsif ( !( $ri{'files_required'} == 384 ) ) {
        Seq_Notes( $0, $ri{'sequence_id'} . " Error in subdirectory name ($ri{'subdirectory'} (ne $ri{'Master_basename'}$ri{'Master_chemcode'}) ?)", 'text', $log_file );
        return {};
    }
    unless ( $info =~ m/,/ ) { $ri{'Master_version'} = $ri{'version'}; }

    $ri{'longname'} = $ri{'basename'} . $ri{'chemcode'} . $ri{'version'};

    #
    # Megabace files look like:  'Basename.WELL.Chemcode.Version'
    # 3700 files look like:      'Basename.Chemcode.Version_WELL'
    #
    #

    ### NEW - more generic retrieval of run information from Machine_Default, Sequencer_Type Tables ###
    if (1) {
        $ri{'trace_file_ext'}        = $Info{TraceFileExt}[0];
        $ri{'failed_trace_file_ext'} = $Info{FailedTraceFileExt}[0];
        if ( $Info{Capillaries}[0] =~ /\d+/ ) {
            $ri{'wells_per_slice'} = $Info{Capillaries}[0];
        }
        else {
            $ri{'wells_per_slice'} = 0;
        }

        #    $ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}*
        my $directory_format = $Info{RunDirectory}[0];

        $directory_format =~ s/\.//g;                               ### the .s are only used as separators in the description
        $directory_format =~ s/PLATE/$ri{'Master_basename'}/;
        $directory_format =~ s/CHEMISTRY/$ri{'Master_chemcode'}/;
        $directory_format =~ s/VERSION/$ri{'Master_version'}/;

        my $Master_file_format = $Info{FileFormat}[0];              ### for MASTER file
        $Master_file_format =~ s/\.//g;                             ### the .s are only used as separators in the description

        my $file_format = $Master_file_format;                      ### for file (in case different from MASTER)

        $Master_file_format =~ s/PLATE/$ri{'Master_basename'}/;
        $Master_file_format =~ s/CHEMISTRY/$ri{'Master_chemcode'}/;
        $Master_file_format =~ s/VERSION/$ri{'Master_version'}/;

        $file_format =~ s/PLATE/$ri{'basename'}/;
        $file_format =~ s/CHEMISTRY/$ri{'chemcode'}/;
        $file_format =~ s/VERSION/$ri{'version'}/;

        if ( $file_format =~ /(.*)WELL(.*)/ ) {
            $ri{'pre_well'}  = $1;
            $ri{'post_well'} = $2;
        }
        else {
            $ri{'pre_well'}  = $file_format;
            $ri{'post_well'} = '_';
        }
        print "* Expecting $file_format: ($Master_file_format)\n";

        $Master_file_format =~ s/WELL/\?\?\?/;
        $file_format        =~ s/WELL/\?\?\?/;

        $ri{'mirrored'} = "$local_drive/$directory_format/$Master_file_format";
        $ri{'archived'} = "$archived/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}.rid*/$Master_file_format";

        #    $ri{'raw_datafiles'} = "$local_drive/*/$ri{'Master_basename'}???$ri{'Master_chemcode'}$ri{'Master_version'}";
        $ri{'E_ss_dir'} = $local_sample_sheets;
    }

    else {

        # It's a Megabace
        if ( $ri{'Mtype'} eq 'Megabace' ) {
            $ri{'trace_file_ext'}        = $trace_file_ext1;
            $ri{'failed_trace_file_ext'} = $failed_trace_file_ext1;
            $ri{'mirrored'}              = "$local_drive/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}*/$ri{'Master_basename'}???$ri{'Master_chemcode'}$ri{'Master_version'}";
            $ri{'archived'}              = "$archived/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}.rid*/$ri{'Master_basename'}???$ri{'Master_chemcode'}$ri{'Master_version'}";

            #    $ri{'raw_datafiles'} = "$local_drive/*/$ri{'Master_basename'}???$ri{'Master_chemcode'}$ri{'Master_version'}";
            $ri{'E_ss_dir'}  = $local_sample_sheets;
            $ri{'pre_well'}  = $ri{'basename'};
            $ri{'post_well'} = $ri{'chemcode'} . $ri{'version'};
        }
        elsif ( $ri{'Mtype'} eq 'ABI' ) {

            # else assume it's a 3700
            $ri{'trace_file_ext'}        = $trace_file_ext2;
            $ri{'failed_trace_file_ext'} = $failed_trace_file_ext2;
            $ri{'archived'}              = "$archived/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}.rid*/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}" . "_" . "*";
            $ri{'mirrored'}              = "$local_drive/Run*/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}" . "_" . "*";
            $ri{'E_ss_dir'}              = $local_sample_sheets;
            $ri{'pre_well'}              = $ri{'basename'} . $ri{'chemcode'} . $ri{'version'} . "_";
            $ri{'post_well'}             = "_";
        }
        else { return; }
    }

    $ri{'phred_outfile'} = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/phredscores";
    $ri{'log_file'}      = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/update.log";
    $ri{'screen'}        = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/screen";

    my $data = "\n***** Run $ri{'sequence_id'} Details: *****\n";
    foreach my $key ( keys %ri ) {
        if ( $key =~ /sub_384_name/i ) {    ### this key is a hash itself....
            $data .= "$key\t=\t";
            foreach my $subkey ( keys %{ $ri{$key} } ) {
                $data .= "$ri{$key}{$subkey},";
            }
            chop $data;
            $data .= "\n";
        }
        else { $data .= "$key\t=\t$ri{$key}\n"; }
    }

    return \%ri;
}

###########################
sub get_mirrored_data {
###########################
    my %args = @_;

    my $dbc   = $args{'dbc'};
    my $force = $args{force} || 0;         # bypass sanity check for number of files
    my %ri    = %{ $args{'run_info'} };    # we need to be passed a valid Run Info hash ref

    my $command = "ls $ri{'mirrored'}$ri{'trace_file_ext'}";
    my @trace_files = split "\n", try_system_command(qq{$command});

    my $notes = '';

    #if ($trace_files[0] =~/no such file/i) {
    #	$notes .= "\n** fIX \n";
    #	&fix_link($command,"$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}",$ri{'Mname'});
    #    } else {	$notes .= "\n** NO fIX \n"; }

    my %Directory;
    foreach my $found (@trace_files) {
        if ( $found =~ /No such file/ ) { $notes .= "Nothing in $ri{'mirrored'}$ri{'trace_file_ext'}\n"; last; }
        if ( $found =~ /(.*)\/(.+)/ ) {
            $Directory{$1}++;
        }
    }

    my $moved = 0;
    foreach my $directory ( keys %Directory ) {
        my $files         = $Directory{$directory};
        my $target        = $directory;
        my $rid           = 0;
        my $run_directory = '';
        my $dir;
        my $subdirectory;
        $target =~ s/mirror/archive/g;    ### change path to archive directory...

        if ( $target =~ /(.*)\/(.*)$/ ) {
            $run_directory = $2;
        }

        ### get runid if it is specified..
        if ( $target =~ /_(\d+)$/ ) {
            $rid = $1;
        }
        $ri{'rid'} = $rid || 0;
        $ri{'RunDirectory'} = $run_directory;
        $notes .= "Target: $target ($run_directory : $rid)\n";

        if ( $target =~ /(.*)\/(.*)/ ) { $dir = $1; }

        my @list = glob("$directory/*.ab*");
        if ( int(@list) && ( $list[0] =~ /(.*)\/(\w+\.?\w+\.?\-\d*)(.*)\.ab[d|1]$/ ) ) {
            $subdirectory = $2;
        }

        # sanity check the number of files (should be 96 or 16)
        $notes .= "D:$directory -> T:$target (DIR:$dir)\n";
        my $symlink = qq{$dir/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}.rid$rid.$files};
        unless ( $dir && $subdirectory ) { next; }
        if ( -e "$target" ) {
            my $fback = `mv $directory/*.* --target-directory=$target --update`;    ### copy newer files if any...
            $notes .= "Moved $directory/*.* -> $target.\n";
            $notes .= "Updated: $fback.\n";
            $notes .= "Target exists, attempting to create symlink: $symlink\n";

            # make sure permissions are set to 664
            `chmod -R 775 $target`;

            # if the target archive run directory exists but the symlink is not there, create the symlink
            unless ( -e "$symlink" ) {
                if ( ( $files != 96 ) && ( $files != 16 ) ) {
                    $notes .= "Number of files is not 16 or 96 per directory -  not creating symlink\n";
                    next;
                }
                my $cmd = "ln -s $target $symlink";
                $notes .= "Command:\n$cmd\n";
                `$cmd`;
                $notes .= "linked\n";
            }
        }
        else {
            my $fback = `mv $directory $target`;    ### move entire directory over
                                                    # make sure permissions are set to 664
            `chmod -R 775 $target`;
            $notes .= "Moved -> $target.\n:$fback.\n";

            # if the target archive run directory exists but the symlink is not there, create the symlink
            $notes .= "Attempting to create symlink: $symlink\n";
            if ( ( -e $target ) && ( !( -l $symlink ) ) ) {
                if ( ( $files != 96 ) && ( $files != 16 ) ) {
                    $notes .= "Number of files is not 16 or 96 per directory -  not creating symlink\n";
                    next;
                }
                my $cmd = "ln -s $target $symlink";
                $notes .= "Command:\n$cmd\n";
                `$cmd`;

                #		`ln -s $target qq{$dir/$ri{'Master_basename'}$ri{'Master_chemcode'}$ri{'Master_version'}.rid$rid.$files}`;
                $notes .= "linked\n";
            }
            else { $notes .= "Not linked (no files found)\n"; }
            $moved++;
        }
    }

    if ($moved) { $notes .= "Moved $moved directories to archive directory"; }

    if ($force) {
        Seq_Notes( "", "Forcing analysis regardless of number of files found", 'text', $ri{'log_file'} );
    }
    return $moved;
}

##############
# sub fix_link {
##############
#     my $command = shift;
#     my $fullname = shift;
#     my $machine_name = shift;
#
#     if ($machine_name =~/3730/) { $machine_name =~s/D/d/; }
#
#     $command =~s/mirror/archive/;
#     $command =~s/\/Run/\/Run_${machine_name}_2004-01-2/i;
#
#     foreach my $rep ('A01','B01','A02','B02') {
#	 my $next_command = $command;
#	 $next_command =~s/_\*\.ab1/\*_$rep\*/;
#	 print "\n** Check '$next_command' **\n";
#	 my $dir1 = try_system_command(qq{$next_command});
#	 if ($dir1 =~/(.*\/)(Run.*?_)(\d+)\/(\S+)/) {
#	     my $dir = $1;
#	     my $fulldir = $1.$2.$3;
#	     my $rid = $3;
#	     my $cmd = "ls $fulldir | wc";
#	     my $wc = `$cmd`;
#	     $wc =~s/(\d+)(.*)/$1/;
#	     $wc += 0;
#	     my $name = "$fullname.rid$rid.$wc";
#	    print "Name: $name\n";
#	    print "WC: $wc.\n";
#	     print "\n*** DIR: $dir1 ($rid:$wc)\n";
#	     my $cmd = "ln -s $fulldir $dir/$name";
#	     try_system_command($cmd);
#	 } else {
#	     print "** $dir1 ? \n";
#	 }
#     }
# }

###########################
sub get_analyzed_data {
###########################
    # Get analyzed data files from sequence

    my %args     = @_;
    my $dbc      = $args{'dbc'};
    my %ri       = %{ $args{'run_info'} };         # we need to be passed a valid Run Info hash ref
    my $force    = $args{'force'} || 0;
    my $reversal = $args{'reversal'} || 0;
    my $source   = $args{'source'} || 'archive';

    my $p;                                         # printed

    $p .= "Getting trace files.\n";

    my @trace_files  = glob "$ri{'archived'}$ri{'trace_file_ext'}";
    my @failed_files = glob "$ri{'archived'}$ri{'failed_trace_file_ext'}";
    my $num_files    = scalar @trace_files;
    my $failed       = int(@failed_files);

    # check
    my $wait_ok            = 2;                        ## allow 2 days before generating warning.
    my $incomplete_warning = 'Warning (non-fatal)';    ## non-fatal suffix suspends warning message ##
    if ( $ri{'days_ago'} > $wait_ok ) { $incomplete_warning = 'Warning' }    ## don't set to warning unless run generated more than 2 days ago ##

    ### force=2 for any number of files, or force=1 for 96 wells reqd
    if ( $force > 1 && $num_files ) {
        Seq_Notes( "", "Forcing analysis regardless of number of files found ($num_files found)", 'text', $ri{'log_file'} );
    }
    elsif ( ( ( $num_files + $failed ) >= 96 ) && $force ) {
        Seq_Notes( "", "Forcing analysis of single quadrant", 'text', $ri{'log_file'} );
    }
    elsif ( $ri{'num_slices'} > 0 ) {

        # if there are slices, then the allowable number of files is $ri{num_slices} * $ri{'wells_per_slice'}
        # fail if '$wells_per_slice' == 0
        if ( $ri{'wells_per_slice'} == 0 ) {
            $p .= "Warning: Database does not define wells per slice";
            Seq_Notes( $0, "Warning: Database does not define wells per slice", 'text', $ri{'log_file'} );
            return $p;
        }
        my $allowable_files = $ri{'num_slices'} * $ri{'wells_per_slice'};

        if ( ( $num_files + $failed ) < $allowable_files ) {

            $p .= "$incomplete_warning: (only $num_files/$allowable_files (+$failed) $ri{'archived'}$ri{'trace_file_ext'}) - $ri{'days_ago'} days old. (F=$force)";
            Seq_Notes( $0, "$incomplete_warning: (only $num_files/$allowable_files $ri{'archived'}$ri{'trace_file_ext'}) - $ri{'days_ago'} days old. (F=$force)", 'text', $ri{'log_file'} );
            return $p;
        }

        Seq_Notes( "", "Analyzing $ri{num_slices} slices", 'text', $ri{'log_file'} );
        Seq_Notes( "Detected $num_files possible files\n", int(@failed_files) . " failed files detected", 'text', $ri{'log_file'} );
    }

    #    elsif ($num_files + $failed < $ri{'files_required'}) {
    #	 # if there are < 4 quadrants and the plate size is 384-well
    #    }
    elsif ( $num_files + $failed < $ri{'files_required'} ) {
        $p .= "$incomplete_warning: (only $num_files/$ri{'files_required'} (+$failed) $ri{'archived'}$ri{'trace_file_ext'})  - $ri{'days_ago'} days old (F=$force)";
        Seq_Notes( $0, "$incomplete_warning: (only $num_files/$ri{'files_required'} $ri{'archived'}$ri{'trace_file_ext'})  - $ri{'days_ago'} days old. (F=$force)", 'text', $ri{'log_file'} );
        return $p;
    }
    else {
        Seq_Notes( "Detected $num_files possible files\n", int(@failed_files) . " failed files detected", 'text', $ri{'log_file'} );
    }

    # make trace, phd, and edit directories...
    $p .= "Making $ri{'savedir'}/$ri{'longname'} directories.\n";

    my $check;
    unless ( -e "$ri{'savedir'}/$ri{'longname'}" ) {
        &try_system_command("mkdir $ri{'savedir'}/$ri{'longname'}");
    }
    unless ( -e "$ri{'savedir'}/$ri{'longname'}/$trace_dir" ) {
        $check = try_system_command("mkdir $ri{'savedir'}/$ri{'longname'}/$trace_dir");
    }
    unless ( -e "$ri{'savedir'}/$ri{'longname'}/$edit_dir" ) {
        try_system_command("mkdir $ri{'savedir'}/$ri{'longname'}/$edit_dir");
    }
    unless ( -e "$ri{'savedir'}/$ri{'longname'}/$phred_dir" ) {
        try_system_command("mkdir $ri{'savedir'}/$ri{'longname'}/$phred_dir -m 777");
    }
    unless ( -e "$ri{'savedir'}/$ri{'longname'}/$poly_dir" ) {
        try_system_command("mkdir $ri{'savedir'}/$ri{'longname'}/$poly_dir");
    }

    if ( ( $check =~ /File exists/ ) && $ri{'savedir'} && $ri{'longname'} ) {
        print "(Directory structure already exists)\n";
        print try_system_command("rm -f $ri{'savedir'}/$ri{'longname'}/$trace_dir/*.ab*") if ( $ri{'longname'} && $trace_dir );
        print "(Deleted existing files)";
    }
    else { print $check; }

####### Print Details to update.log file #############
    my $data = "\n***** Run $ri{'sequence_id'} Details: *****\n";
    foreach my $key ( keys %ri ) {
        if ( $key =~ /sub_384_name/i ) {    ### this key is a hash itself....
            $data .= "$key\t=\t";
            foreach my $subkey ( keys %{ $ri{$key} } ) {
                $data .= "$ri{$key}{$subkey},";
            }
            chop $data;
            $data .= "\n";
        }
        else { $data .= "$key\t=\t$ri{$key}\n"; }
    }
    Seq_Notes( "Info:", $data, 'text', $ri{'log_file'} );
##################

    ### first empty directory...
    `rm -f $ri{'savedir'}/$ri{'longname'}/$trace_dir/*` if ( $ri{'longname'} && $trace_dir );

    # if 384 well
    if ( $ri{'convert_96_to_384'} =~ /YES/i ) {
        $p .= "Mapping to 384 well.\n";
        $p .= link_96_to_384( run_info => $args{'run_info'}, dbc => $dbc, reversal => $reversal );
    }
    else {
        if ($reversal) { }
        my @files = glob("$ri{'archived'}$ri{'trace_file_ext'}");
        if ( $files[0] =~ /$ri{'longname'}/ ) {
            foreach my $file (@files) {
                if ( $file =~ /$ri{'longname'}.*_?([A-P]\d\d)[_\-]*([x\d]*)/ ) {
                    my $well      = $1;
                    my $capillary = $2;
                    $args{'run_info'}{'capillary'}{$well} = $capillary;
                    symlink $file, "$ri{'savedir'}/$ri{'longname'}/$trace_dir/$ri{'longname'}_$well$ri{'trace_file_ext'}";

                    #		  print ">> LINK $file -> $ri{'longname'}_$well\n";
                }
                else { print "$file ignored (?)\n"; }
            }
            print "> LINKED: files in $ri{'archived'}$ri{'trace_file_ext'} <- $ri{'longname'}_<WELL>.\n";
        }
        else {
            my $msg = "Trace files not available ($files[0]) in $ri{'archived'}...$ri{'trace_file_ext'} yet.\n";
            print $msg;
            $p .= $msg;
        }
    }
    return $p;
}

##########################
sub zip_trace_files {
##########################
    #  ZIP up ESD, rsd files (tar, gunzip)
    my %args = @_;
    my $dbc  = $args{'dbc'};
    my %ri   = %{ $args{'run_info'} };    # we need to be passed a valid Run Info hash ref

    my $p;
    my @rsd_files = <$ri{'savedir'}/$ri{'longname'}/*.rsd>;
    my @ESD_files = <$ri{'savedir'}/$ri{'longname'}/*.ESD>;

    if ( scalar(@rsd_files) > 1 ) {
        $p .= "\nTgzing rsd files\n";
        `tar uvzf $ri{'savedir'}/$ri{'longname'}/$ri{'longname'}.rsd.tgz --remove-files $ri{'savedir'}/$ri{'longname'}/*.rsd`;
    }
    else {
        Seq_Notes( $0, "No rsd files to compress", 'text', $ri{'log_file'} );
    }

    if ( scalar(@ESD_files) > 1 ) {
        $p .= "\nTgzing ESD files...\n";
        `tar uvzf $ri{'savedir'}/$ri{'longname'}/$ri{'longname'}.ESD.tgz --remove-files $ri{'savedir'}/$ri{'longname'}/*.ESD`;
    }
    else {
        Seq_Notes( $0, "No ESD files to compress", 'text', $ri{'log_file'} );
    }

    return $p;
}

####################################
sub init_clone_sequence_table {
####################################
    #
    # Initialize Clone_Sequence table
    #
    my %args = @_;
    my $dbc  = $args{'dbc'} || $Connection;
    my $ri   = $args{'run_info'};

    my $p;

    my @copy_fields = ( 'Unused_Wells', 'No_Grows', 'Slow_Grows', 'Problematic_Wells', 'Empty_Wells', 'Plate_Size', 'Plate.Parent_Quadrant' );
    my %info              = &Table_retrieve( $dbc, 'Plate,Library_Plate', \@copy_fields, "WHERE FK_Plate__ID=Plate_ID AND Plate_ID=$ri->{'plate_id'}" );
    my $unused_wells      = $info{Unused_Wells}[0];
    my $problematic_wells = $info{Problematic_Wells}[0];
    my $empty_wells       = $info{Empty_Wells}[0];
    my $NG_wells          = $info{No_Grows}[0];
    my $SG_wells          = $info{Slow_Grows}[0];
    my $size              = $info{Plate_Size}[0];
    my $quadrant          = $info{Parent_Quadrant}[0];

    my $SG        = 0;
    my $NG        = 0;
    my $endLetter = 'H';
    my $endNumber = 12;

    if ( $ri->{'plate_size'} =~ /384/ ) {
        $endLetter = 'P';
        $endNumber = 24;
    }

    my $found = join ',', $dbc->Table_find( 'Clone_Sequence', 'FK_Run__ID', "where FK_Run__ID=$ri->{'sequence_id'}", 'Distinct' );

    ## Delete current records if they already exist
    if ( $found =~ /$ri->{'sequence_id'}/ ) {
        print "DELETE current entries\n";
        $p .= "delete from Clone_Sequence where FK_Run__ID=$ri->{'sequence_id'}";
        &delete_record( $dbc, 'Clone_Sequence', 'FK_Run__ID', $ri->{'sequence_id'} );
    }
    else { print "No current entries\n"; }

    my @new_fields = ( 'FK_Run__ID', 'Well', 'Growth', 'FK_Sample__ID' );
    my %Data;

    my $Container = alDente::Container->new( -dbc => $dbc, -id => $ri->{'plate_id'} );
    my %Parents = alDente::Container::get_Parents( -dbc => $dbc, -id => $ri->{'plate_id'}, -format => 'hash', -simple => 1 );
    my $original = $Parents{original};

    my $records = 0;

    my %well_lookup = &Table_retrieve( $dbc, 'Well_Lookup', [ 'Plate_384', 'Plate_96', 'Quadrant' ] );
    my %well_lookup_hash;
    my $i;
    while ( defined( $well_lookup{Plate_384}[$i] ) ) {
        $well_lookup_hash{ $well_lookup{Quadrant}[$i] }{ $well_lookup{Plate_96}[$i] } = $well_lookup{Plate_384}[$i];
        $i++;
    }

    ## STORE which wells are problematic, no grows and empty wells!
    #  This is for the
    #

    for my $letter ( 'A' .. $endLetter ) {
        for my $wnum ( 1 .. $endNumber ) {
            my $Growth;
            my $ignore = 0;    ## flag to indicate well to ignore for stats.

            ## skip unused wells <CONSTRUCTION> - set $Growth = 'Unused' ##
            if ( $unused_wells =~ /\b$letter$wnum\b/ || $unused_wells =~ /\b$letter\Q0\E$wnum\b/ ) {
                $Growth = "Unused";
                $ignore = $Growth;    ## exclude from stats
                                      #$Growth = "No Grow";

            }
            elsif ( $NG_wells =~ /\b$letter$wnum\b/ || $NG_wells =~ /\b$letter\Q0\E$wnum\b/ ) {
                $Growth = "No Grow";
                $ignore = $Growth;     ## exclude from stats
            }
            elsif ( $SG_wells =~ /\b$letter$wnum\b/ || $SG_wells =~ /\b$letter\Q0\E$wnum\b/ ) {
                $Growth = "Slow Grow";
                $ignore = 0;             ## include in stats
            }
            elsif ( $problematic_wells =~ /\b$letter$wnum\b/ || $problematic_wells =~ /\b$letter\Q0\E$wnum\b/ ) {
                ## <CONSTRUCTION> : mark Growth as 'Problematic' or 'Empty' if well labelled as such ??
                $Growth = "Problematic";
                $ignore = $Growth;         ## exclude from stats
                                           #$Growth = "No Grow";

            }
            elsif ( $empty_wells =~ /\b$letter$wnum\b/ || $empty_wells =~ /\b$letter\Q0\E$wnum\b/ ) {
                $Growth = "Empty";
                $ignore = $Growth;         ## exclude from stats
                                           #$Growth = "No Grow";
            }
            else {
                $Growth = "OK";
            }
            ## <CONSTRUCTION> : critical - general include should be "in ('OK','Slow Grow') instead of " != 'No Grow' ".

            if ( $wnum < 10 ) { $wnum = '0' . $wnum; }
            my $well = $letter . $wnum;

            my $original_well;
            if ($quadrant) {
                $original_well = $well_lookup_hash{$quadrant}{$well};

                #($original_well) = $dbc->Table_find('Well_Lookup','Plate_384',"WHERE Quadrant = '$quadrant' AND Plate_96 = '$well'");
            }
            else {
                $original_well = $well;
            }

            print "map $original_well -> $well ($quadrant)\t" if $quadrant;

            my $sample_id = &alDente::Container::get_Parents( -dbc => $dbc, -id => $original, -format => 'sample_id', -well => $original_well, -simple => 1 );

            my @values = ( $ri->{'sequence_id'}, $well, $Growth, $sample_id );
            unless ( $sample_id || $ignore ) { Message("** sample id missing for $ri->{'sequence_id'} : $well ?? **\n"); }
            $Data{ ++$records } = \@values;
            print "** Add @values..\n";

            $ri->{'ignore_read'}{$well} = $ignore;
            $NG                         = 0;
            $SG                         = 0;         # reset for next well
        }
    }

    print "\n********* CALLING BATCH APPEND **********************\n";
    my $new;
    if ($records) {
        $new = $dbc->simple_append( -table => 'Clone_Sequence', -fields => \@new_fields, -values => \%Data, -autoquote => 1 );

        # print "DATA" . Dumper (\%Data);
        #my %info = $dbc->Table_retrieve("Clone_Sequence", ["LEFT(Well,1)", "Count(*)","Sequence_Length"], "WHERE FK_Run__ID = $ri->{'sequence_id'} group by LEFT(Well,1)");
        #print Dumper \%info;
    }

    my $count;

    $count = scalar( @{ $new->{Clone_Sequence}->{newids} } ) if $new->{Clone_Sequence}->{newids};
    Seq_Notes( "", "$count Clone_Sequence records created ($ri->{'sequence_id'})\n", 'text', $ri->{'log_file'} );
    print "COUNT $count Clone_Sequence records";
    $ri->{'analysis_time'} = &date_time();    ### initialize SequenceAnalysis_DateTime to date 00:00:00 ###
    my $seq_run_id = join ',', $dbc->Table_find( 'SequenceRun', 'SequenceRun_ID', "WHERE FK_Run__ID=$ri->{'sequence_id'}" );

    &delete_record( $dbc, 'SequenceAnalysis', 'FK_SequenceRun__ID', $seq_run_id );
    $dbc->Table_append_array( 'SequenceAnalysis', [ 'FK_SequenceRun__ID', 'SequenceAnalysis_DateTime' ], [ $seq_run_id, $ri->{'analysis_time'} ], -autoquote => 1 );

    return $p;
}

####################
sub run_phred {
####################
    #
    # Generate Phred scores
    #
    my %args      = @_;
    my $dbc       = $args{'dbc'} || $Connection;
    my $phredfile = $args{'phredfile'};
    my %ri        = %{ $args{'run_info'} };

    if ($phredfile) {
        $PHRED_FILE = $phredfile;
    }

    my $p;

    my ( $site, $seq );

    ## get Cloniong Site info (Cloning Site, Direction)

    my $direction = $dbc->Table_find( 'Vector_TypePrimer,Primer,Solution,LibraryVector,Vector,Run,SequenceRun,Plate,Stock,Stock_Catalog', 'Direction',
        "where FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and Vector_TypePrimer.FK_Vector_Type__ID=Vector.FK_Vector_Type__ID and Vector_ID = LibraryVector.FK_Vector__ID and Primer_ID = FK_Primer__ID and Primer.Primer_Name=Stock_Catalog_Name and FKPrimer_Solution__ID = Solution_ID and FK_Run__ID=Run_ID AND Run_ID=$ri{'sequence_id'} and FK_Plate__ID = Plate_ID"
    );

    if ( ( $direction =~ m/\S/ ) && !( $direction =~ m/,/ ) ) {
        if    ( $direction =~ m/^5/i ) { $site = "FK5Prime_Enzyme__ID" }
        elsif ( $direction =~ m/^F/i ) { $site = "FK5Prime_Enzyme__ID" }
        elsif ( $direction =~ m/^3/i ) { $site = "FK3Prime_Enzyme__ID" }
        elsif ( $direction =~ m/^R/i ) { $site = "FK3Prime_Enzyme__ID" }
        else                           { $site = "FK5Prime_Enzyme__ID" }    ## default for 'N/A' direction

        ($seq) = $dbc->Table_find( 'Vector_Based_Library,Enzyme', 'Enzyme_Sequence', "where FK_Library__Name = '$ri{'library'}' AND $site = Enzyme_ID" );
        print " ** Using $seq for Restriction Site\n";

        #      while ($seq =~s /([agtcAGTCnN])\((\d+)\)/$1 x $2/e) {}  ### replace AN(5)G with ANNNNNG
        #      if ((!$seq || $seq=~/NULL/) && $site=~/^[AGTCNagtcn]+$/) {
        #	  $seq = $site;
        #	  print "using $site for Restriction Site sequence\n";
        #      }
    }
    else {
        $seq = '';
        print " ** No Restriction Site specified\n";

        ( my $primer ) = $dbc->Table_find( 'Solution,Stock,Stock_Catalog', 'Stock_Catalog_Name', "where FK_Stock_Catalog__ID= Stock_Catalog_ID AND FK_Stock__ID=Stock_ID and Solution_ID = $ri{'primer_id'}" );

        unless ( ( $primer =~ /Custom|None/ ) || ( $ri{'vector'} =~ /No Vector|None/i ) ) {
            my $msg = "\n******* Error (Run $ri{'sequence_id'}): Vector/Primer Direction ($primer <-> $ri{'vector'}) not defined ********\n";
            unless ( $args{'force'} ) { $msg .= "(Forced Analysis..continuing..)\n"; return $msg; }
        }
    }

    $ENV{PHRED_PARAMETER_FILE} = $phredpar;
    my $command2 = phred_command( $seq, "$ri{'savedir'}/$ri{'longname'}/$trace_dir/", $ri{'phred_outfile'}, "$ri{'savedir'}/$ri{'longname'}/$phred_dir/" );
    $p .= $command2 . "\n";
    Seq_Notes( "", "Generating Phred Files", 'text', $ri{'log_file'} );
    print "\n******* Running Phred: \n** **\n** $command2 \n**\n*******\n";

    my @stdout = split "\n", try_system_command("$command2 2>&1");
    foreach (@stdout) {

        #    $p .= " $_";
        if (/trace data missing/) {
            my @parse;
            my $x;
            my $message = $_;
            if ( $ri{'trace_file_ext'} =~ /abd/i ) {
                $message =~ /chromat_dir\/(.*)/i;
                @parse = split /\./, $1, 2;
                $x = $parse[0];
                if ( $x =~ /(.+)(.{3})$/ ) { $x = $2 }
            }
            elsif (/unknown chemistry\s*(\S+)/) {
                $p .= "Error: UNKNOWN CHEMISTRY : $1\n";
            }
            elsif ( $ri{'trace_file_ext'} =~ /ab1/ ) {
                $message =~ /chromat_dir\/(.*)/i;
                @parse = split /\_/, $1;
                $x = $parse[1];
                if ( $x =~ /(.+)(.{3})$/ ) { $x = $2 }
            }
            else { $x = '?'; }
            $p .= add_note( $dbc, 'Clone_Sequence', $ri{'sequence_id'}, $x, "trace data missing" );
        }
    }

    #  close(PROC);

    # save command that generated files
    $phred_version = try_system_command("$PHRED_FILE -V");
    $phred_version =~ m/version:?\s*(\S+)/i;
    $phred_version = $1;

    my $phred_file = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/phred_command";
    print "\nPhred -> $phred_file.\n";

    open( PHRED, "> $phred_file" ) or warn "Error opening $phred_file";
    print PHRED "Version $phred_version\n";
    print PHRED "Phred parameter file: $phredpar";
    print PHRED "Command: $command2";
    print PHRED "\n";
    close(PHRED) or warn "cannot close";

    &Seq_Notes( "", "Done\n", 'text', $ri{'log_file'} );

    return $p;
}

##########################
sub run_crossmatch {
    ####################################
    #   Generate Cross-matches         #
    ####################################

    my %args                 = @_;
    my $dbc                  = $args{'dbc'};
    my $vector_sequence_file = $args{'vector_sequence_file'};
    my %ri                   = %{ $args{'run_info'} };

    chdir "$ri{'savedir'}/$ri{'longname'}" or return 0;
    my $command1 = cross_match_command( "phd_dir/phredscores", "phd_dir/tmp_vfile", "phd_dir/screen", 1 );
    &Seq_Notes( "", "Generating Cross Match Files with command:\n$command1\n", 'text', $ri{'log_file'} );

    print try_system_command(qq{$command1});    ### generates screen file...

    #  For debugging purposes...
    #  print "Sleepingggggggggggggggggggggggggggg... Overwrite the phredscores.screen file within 10 seconds.\n";
    #  sleep 10;
    print "\n** Finished **\n";

    ## leave vector sequence undefined to screen for all vectors
    my $full_cross_match = cross_match_command( "phd_dir/phredscores", undef, "phd_dir/full_screen" );

    print try_system_command(qq{$full_cross_match});    ### generates screen file...
    &Seq_Notes( "", "Generating Full Cross Match Files with command:\n$full_cross_match\n", 'text', $ri{'log_file'} );
    parse_screen_file( run_info => \%ri, dbc => $dbc, file => "$ri{'savedir'}/$ri{'longname'}/$phred_dir/full_screen" );

    # save command that generated files
    my $xm_version = `cross_match`;
    $xm_version =~ m/version:?\s*(\S+)/i;
    $xm_version = "Version $1";

    open( XMatch, ">$ri{'savedir'}/$ri{'longname'}/$phred_dir/cross_match_command" ) or warn "Error opening cross_match_command";
    print XMatch $xm_version;
    print XMatch $command1 . "\n";
    close(XMatch);

    ## Save a vector / quality trimmed version of the fasta file for general use (also used to blast against contaminants)
    print &generate_fasta_file( -run_id => $ri{'sequence_id'}, -file => $ri{'savedir'} . '/' . $ri{'longname'} . "/$phred_dir/phredscores.trimmed" );

    return "** Finished Running Crossmatch ** ..\n";
}

#######################
#
# <CONSTRUCTION> move to general API function for Sequencing
# We should back fill all runs to include this file (to allow for generating contamination checks for prior data)
#
#############################
sub generate_fasta_file {
#############################
    my %args = &filter_input( \@_, -args => 'run_id,file,trim', -mandatory => 'run_id' );

    my $run_id      = $args{-run_id};
    my $file        = $args{-file} || 'Run$run_id.fasta';
    my $trim        = $args{-trim};
    my $trim_cutoff = $args{-trim_cutoff} || 1;

    my $bin_home = $FindBin::RealBin;
    my $ok       = `$bin_home/fasta.pl -R $run_id -A -o $file -QT $trim_cutoff -C 50 -user viewer -password viewer 2>$file.err`;    ## <CONSTRUCTION> -remove viewer ..

    return $ok;
}

############################
sub parse_screen_file {
############################
    my %args = @_;
    my %ri   = %{ $args{'run_info'} };
    my $file = $args{'file'};
    my $dbc  = $args{'dbc'} || $Connection;

    #  95  0.00 9.74 0.00  TL00224aA08.EA.abd       82   235 (514)  C pOTB7_LL005   (1646)   179    11
    # 291  0.59 2.07 1.18  TL00224aA08.EA.abd      248   585 (164)  C pOTB7.seq   (5)  1810  1470

    print "\nREADING $file\n*************************\n";

    #\s+(\d+)\s+(\d+)\s+\(\d+\)\s+

    my %Screen;
    open( Xmatch, $file ) or warn "Error opening screen file";
    while (<Xmatch>) {
        my $line = $_;
        my $name;
        my $start;
        my $stop;
        my $dir;
        my $match;

        if ( $line =~ /[\d\.]+\s+[\d\.]+[\d\.]+\s+[\d\.]+\s+(\S*)\s+(\d+)\s+(\d+)\s+[\(]\d+[\)]\s+C (\S*)\s+\(/ ) {
            $name  = $1;
            $start = $2;
            $stop  = $3;
            $dir   = 'C';
            $match = $4;
        }
        elsif ( $line =~ /[\d\.]+\s+[\d\.]+[\d\.]+\s+[\d\.]+\s+(\S*)\s+(\d+)\s+(\d+)\s+[\(]\d+[\)]\s+(\S*)\s+\d/ ) {
            $name  = $1;
            $start = $2;
            $stop  = $3;
            $dir   = 'C';
            $match = $4;
        }
        if ( $match =~ /(.*)\.seq$/ ) { $match = $1; }

        $name =~ s/$ri{'chemcode'}//;
        if ( $name =~ /$ri{'library'}(\S*)([A-P]{1}\d{2})[\._]/ ) {
            my $well = $2;
            $Screen{$well}[0] = $match;
            $Screen{$well}[1] = $start;
            $Screen{$well}[2] = $stop;
            $Screen{$well}[3] = $dir;
        }
        next;
    }

    #### first delete old records of matches... ####

    my ($count) = $dbc->Table_find( 'Cross_Match', "count(*)", "Where FK_Run__ID=$ri{'sequence_id'}" );
    if ($count) {
        &delete_record( $dbc, 'Cross_Match', 'FK_Run__ID', $ri{'sequence_id'} );
    }

    my $timestamp = &RGTools::RGIO::timestamp();
    ( my $today ) = split ' ', &date_time();

    my $matches;
    foreach my $key ( keys %Screen ) {
        unless ( $key =~ /[a-zA-Z]{1}\d{2}/ ) { next; }
        my $well  = $key;
        my $match = $Screen{$well}[0];
        my $start = $Screen{$well}[1];
        my $stop  = $Screen{$well}[2];
        my $dir   = $Screen{$well}[3];

        #### convert to 0 index for start and stopping positions.

        $dbc->Table_append_array( 'Cross_Match', [ 'FK_Run__ID', 'Well', 'Match_Name', 'Match_Start', 'Match_Stop', 'Match_Direction', 'Cross_Match_Date' ], [ $ri{'sequence_id'}, $well, $match, $start - 1, $stop - 1, $dir, $today ], -autoquote => 1 );

        $matches .= "$match ($start -> $stop) $dir\n";
    }
    my $msg = "Screened for Vector\n*****************\n" . $matches . "\n**********************\n";
    Seq_Notes( $0, $msg, $ri{'log_file'} );

    return 1;
}

##############################
sub screen_contaminants {
##############################
    my %args     = @_;
    my $dbc      = $args{'dbc'} || $Connection;
    my %ri       = %{ $args{'run_info'} };
    my $path     = $args{'path'};
    my $re_blast = $args{'blast'} || 0;

    my ($today) = split ' ', &date_time();

    my @contam_list;
    my $e_threshold     = "1e-1";
    my $score_threshold = 0;        ### use only one threshold preferably...

    my $E_value_string = "Score";
    my $skip_lines     = 1;         ## blank lines after E_value_string before E_value...

    my $results      = '';
    my @contaminants = glob("$vector_directory/contaminants/*.seq");
    foreach my $contaminant (@contaminants) {
        my $name;
        if ( $contaminant =~ /(.*)\/(.+?)\.seq$/ ) { $name = $2; }
        unless ( -e "$path/phredscores" ) { print "** Warning: $path/phredscores NOT Detected\n"; next; }
        unless ( -e "$contaminant" )      { print "** Warning: $contaminant NOT Detected\n";      next; }
        my $command = "/opt/alDente/software/sequencing/BLAST2/blastall -p blastn -d $contaminant -i $path/phredscores.trimmed -e $e_threshold";

        if ( !$re_blast && ( -e "$path/blast.$name" ) ) {
            print "Using Previously generated blast results\n";
        }
        else {
            `$command 1> $path/blast.$name 2>$path/blast.$name.err`;
        }
        if ( -e "$path/blast.$name" ) {
            `echo \"$command\" >> $path/blast_contaminants_command`;
            print "Blast:\n**********\n$command > $path/blast.$name\n\n";

            #### first delete old records of matches... ####
            &delete_record( $dbc, 'Contaminant', 'FK_Run__ID', $ri{'sequence_id'} );

            $results .= "Blast against $name " . &RGTools::RGIO::now() . "\n******************************************\n";
            my $found = 0;

            my $Blast_Results = Sequencing::Read::parse_blastall( -file => "$path/blast.$name", -chemcode => $ri{'chemcode'}, -library => $ri{'library'}, -E_threshold => $e_threshold, -score_threshold => $score_threshold );

            if ( $Blast_Results->{matches} ) {
                foreach my $match ( 1 .. $Blast_Results->{matches} ) {
                    my $c_name = $Blast_Results->{contaminant}[ $match - 1 ];
                    my $well   = $Blast_Results->{well}[ $match - 1 ];
                    my $score  = $Blast_Results->{score}[ $match - 1 ];
                    my $prob   = $Blast_Results->{probablity}[ $match - 1 ];

                    my ($fk_contaminant) = $dbc->Table_find( 'Contamination', 'Contamination_ID', "where Contamination_Name like '$c_name' and Contamination_Alias like '$name'" );
                    unless ( $fk_contaminant > 0 ) {    ### or else add a new entry to the Contamination Table...

                        $fk_contaminant = $dbc->Table_append_array( 'Contamination', [ 'Contamination_Name', 'Contamination_Alias' ], [ $c_name, $name ], -autoquote => 1 );

                        unless ($fk_contaminant) { $fk_contaminant = ''; }
                    }
                    my $added = $dbc->Table_append_array( 'Contaminant', [ 'FK_Run__ID', 'Well', 'E_value', 'Score', 'FK_Contamination__ID', 'Detection_Date' ], [ $ri{'sequence_id'}, $well, $prob, $score, $fk_contaminant, $today ], -autoquote => 1 );

                    unless ($added) { print $DBI::errstr; }
                    &add_note( $dbc, 'Clone_Sequence', $ri{'sequence_id'}, $well, "(E=$prob)" );
                }
            }
            $results .= $Blast_Results->{summary};

            #	if ($path && $name) {`rm -f $path/blast.$name`;}  ### clear out the blasted file...

            Seq_Notes( "Contaminant Screened:", $results, 'text', $ri{'log_file'} );
        }
        else {
            print "$path/blast.$name NOT DETECTED";
        }
    }
    return $results;
}

###########################
sub create_colour_map {
###########################
    #
    # Generate Colour map for Run
    #

    my %args = @_;
    my $dbc  = $args{'dbc'} || $Connection;
    my %ri   = %{ $args{'run_info'} };

    my $p;
    my $colour_file = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/Run$ri{'sequence_id'}.png";

    my $P20 = &SQL_phred(20);

    my @info = $dbc->Table_find_array( 'Clone_Sequence', [ $P20, 'Well', 'Growth' ], "where FK_Run__ID=$ri{'sequence_id'} Order by Well" );

    my $endLetter = 'H';
    my $endNumber = 12;
    if ( $ri{'plate_size'} =~ /384/ ) { $endLetter = 'P'; $endNumber = 24; }

    my @matrix;
    my $index     = 0;
    my $row_index = 0;
    foreach my $row ( 'A' .. $endLetter ) {
        my @col = map {0} ( 1 .. $endNumber );
        foreach my $col ( 1 .. $endNumber ) {
            my $well_name;
            if   ( $col > 9 ) { $well_name = $row . $col; }
            else              { $well_name = $row . "0" . $col; }
            ( my $value, my $well, my $growth ) = split ',', $info[$index];
            if ( $well eq $well_name ) {
                ## <CONSTRUCTION> mark problematic / empty / unused wells in a distinguishing manner...
                if ( $growth !~ /(Slow Grow|OK)/i ) {
                    $matrix[$row_index][ $col - 1 ] = -2;
                }

                #	elsif ($growth=~/Slow Grow/i) {
                #	  $matrix[$row_index][$col-1] = $value;
                #	}
                else {
                    $matrix[$row_index][ $col - 1 ] = $value;
                }
                $index++;
            }
            else {
                $matrix[$row_index][ $col - 1 ] = 'NULL';
            }
            if ($value) {
                $p .= "$well_name ($row_index,$col) => " . $matrix[$row_index][ $col - 1 ] . "=" . $value . "\n";
            }
        }
        $row_index++;
    }

    ##### make 60 x 40 map... ####
    &Views::Draw_Map( $colour_file, undef, undef, \@matrix, 5, 1 );    ## 5 pixels/well, last parameter for border
                                                                       #my $link = `ln -sf $colour_file $run_maps_dir/Run$ri{'sequence_id'}.png`;
                                                                       #$p .= "($link)\n";

    return $p;
}

#########################
sub update_datetime {
#########################
    #
    #  Update database with Run DateTime
    #

    my %args   = @_;
    my $dbc    = $args{'dbc'} || $Connection;
    my %ri     = %{ $args{'run_info'} };
    my $state  = $args{'State'};
    my $Report = $args{'Report'};

    my $p;

    my ($filename) = glob("$ri{'savedir'}/$ri{'longname'}/$trace_dir/*$ri{'trace_file_ext'}");
    if ( !$filename ) {    ## try looking for an uppercase extension ??...
        my $trace_file_ext_uc = uc( $ri{'trace_file_ext'} );
        ($filename) = glob("$ri{'savedir'}/$ri{'longname'}/$trace_dir/*$trace_file_ext_uc");
    }

    $p .= "File: $filename\n";
    print "\n** File: $filename.\n";

    if ($filename) {
        my $secs     = ( stat($filename) )[9];
        my $datetime = date_time($secs);

        unless ($secs) {
            $p .= "\nNo Stats: Broken Link ?\n";
            print "\nNo Stats: Broken Link ?\n";
            return;
        }
        unless ( $ri{'sequence_id'} =~ /[1-9]/ ) { print "\nNo Run_ID ?\n"; return; }

        print "\n$filename TIMESTAMPED: $datetime\n";
        $p .= "Timestamp = $datetime\n";

        ( my $current_state ) = $dbc->Table_find( 'Run', 'Run_Status', "where Run_ID=$ri{'sequence_id'}" );

        my @fields = ('Run_DateTime');
        my @values = ($datetime);
        if ($state) {
            if ( $current_state =~ s/(Initiated|In Process|Data Acquired|Expired)/$state/i ) {
                ## only change status to analyzed if the current one is set to 'In Process'
                ## <CONSTRUCTION> need method to clear analysis results if reanalysis requested ##
                $p .= "State changed to $state\n";
                print "State changed to $state\n";
                push( @fields, 'Run_Status' );
                push( @values, $state );
            }
            else {
                print "State fixed as $current_state\n** NOT reset to $state ** (set state to 'In Process' if necessary to re-analyze)\n";
                $p .= "State fixed as $current_state\n** NOT reset to $state ** (set state to 'In Process' if necessary to re-analyze)\n";
                return $p;
            }
        }
        my $ok = $dbc->Table_update_array( 'Run', \@fields, \@values, "where Run_ID=$ri{'sequence_id'}", -autoquote => 1 );
        if ($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }

        if ( $ok == 1 ) {
            Seq_Notes( "", "Run $ri{'sequence_id'} updated with Run Time ($datetime)", 'text', $ri{'log_file'} );

            ## update Quantity Used for matrix and Buffer Solutions
            my $matrix_used;
            ## <CONSTRUCTION> - get these amounts from Machine_Defaults somehow...
            if ( $ri{'Mtype'} eq 'ABI' ) {
                $matrix_used = 5;    #### 5 ml used per sample sheet
            }
            elsif ( $ri{'Mtype'} eq 'Megabace' ) {
                $matrix_used = 4.2;    #### 4.2 ml used per sample sheet
            }

            my $buffer_used = 50;      ##### roughly 50 ml used per sample sheet.

            #	my $solutions = join ',', $dbc->Table_find('Run','FKMatrix_Solution__ID,FKBuffer_Solution__ID',"where Run_ID=$ri{'sequence_id'}");
            #	(my $matrix,my $buffer) = split ',', $solutions;
            my ($matrix) = alDente::Equipment::get_MatrixBuffer( $dbc, 'Matrix', $ri{'Mid'} );
            my ($buffer) = alDente::Equipment::get_MatrixBuffer( $dbc, 'Buffer', $ri{'Mid'} );

            if ( $matrix =~ /[1-9]/ ) {
                $dbc->Table_update_array( 'Solution', ['Quantity_Used'], ["Quantity_Used+$matrix_used"], "where Solution_ID = $matrix" );
                if ($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }

            }
            if ( $buffer =~ /[1-9]/ ) {
                $dbc->Table_update_array( 'Solution', ['Quantity_Used'], ["Quantity_Used+$buffer_used"], "where Solution_ID = $buffer" );
                if ($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }
            }
        }
        else { Seq_Notes( $0, "Warning: Run DateTime not Updated (may already be set)", 'text', $ri{'log_file'} ); }
    }
    else {
        Seq_Notes( $0, "Error: $ri{'savedir'}/$ri{'longname'}/$trace_dir/*$ri{'trace_file_ext'} not found", 'text', $ri{'log_file'} );
    }

    return $p;
}

#########################
sub update_source {
#########################
    #
    #  Update database with Run DateTime
    #

    my %args = @_;
    my $dbc  = $args{'dbc'};
    my %ri   = %{ $args{'run_info'} };

    my $plate_id = $ri{'plate_id'};

    my $Plate = alDente::Container->new( -dbc => $dbc, -id => $plate_id );
    my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => 'A02' );

    if ( int( @{ $Ancestry{rearray_sources} } ) ) {
        my %Samples = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => 'A01' );
        my $sample = $Ancestry{sample};
        print "Sample: $sample.\n";
    }
    elsif ( $Ancestry{original} ) {
        my $original = $Ancestry{original};
        print "Found original: $original\n";
    }
    else {
        print "NO ORIGINAL ? \n";
    }

    return;
}

############################
sub clear_phred_files {
############################
    #
    # unlink old phred files
    #

    my %args = @_;
    my $dbc  = $args{'dbc'};
    my %ri   = %{ $args{'run_info'} };

    my $p;
    my $pattern = "$ri{'savedir'}/$ri{'longname'}/phd_dir/*.phd.1";

    my @clear_files = glob($pattern);
    $p .= "Clearing Phred files: $pattern\n";

    foreach my $file (@clear_files) {
        unlink $file;
    }

    return $p;
}

#############################
sub parse_phred_scores {
#############################
    #
#########################################################
    #   Parse Phred Scores (sequence, scores, Chem, Dye)    #
#########################################################
    #
    # get sequence, sequence quality from 'phred' files.
    #
    #
    my %args = @_;
    my $dbc = $args{'dbc'} || $Connection;

    #my %ri = %{ $args{'run_info'} };
    my $ri                    = $args{'run_info'};
    my $mask_restriction_site = $args{'mask_restriction_site'};
    if ($mask_restriction_site) {
        $mask_restriction_site = 'Yes';
    }
    else {
        $mask_restriction_site = 'No';
    }
    my $reversal = $args{'reversal'} || 0;
    my $Report = $args{'Report'};
    my $p;

    #print "DUMPER Of RI" . Dumper \%ri;

    my ( $sample, $plate_suffix );
    my ( $wrow, $num, $well, $letter );

    my $screen = "$ri->{'phred_outfile'}.screen";

    Seq_Notes( $0, "Parsing Phred Scores for plate $ri->{'plate_id'} ...\n", 'text', $ri->{'log_file'} );
    Seq_Notes( $0, "Reading from $screen", 'text', $ri->{'log_file'} );

    my @fields = ( 'Sequence', 'Sequence_Length', 'Quality_Left', 'Quality_Length', 'Vector_Left', 'Vector_Right', 'Vector_Quality', 'Vector_Total', 'Clone_Sequence_Comments', 'FK_Note__ID', 'Capillary', 'Peak_Area_Ratio' );

    open( SCREEN, $screen ) or return "Error: cannot open ${screen}.screen file";

    #die("Error opening Screen file: $screen: $!\n");
    my $parsed_notes = "Parsing Scores for $ri->{'sequence_id'}\n********************\n";
    my $clone;
    my @Q20;    ### array of Phred 20 quality values for each run..
    my @SL;     ### array of sequence length values for each run..

    my $success = 100;    ## Success Quality

    open( BP,   ">$ri->{'savedir'}/$ri->{'longname'}/$phred_dir/phred.bps" );
    open( QUAL, ">$ri->{'savedir'}/$ri->{'longname'}/$phred_dir/phred.qs" );
    open( PEAK, ">$ri->{'savedir'}/$ri->{'longname'}/$phred_dir/phred.pks" );

    while (<SCREEN>) {
        my $label = $_;
        $p .= $label;     # extract header line
        if ( $label =~ /^>(\S*)\s+(\d+)\s+(\d+)\s+(\d+)\s+[a-zA-Z]{3}\s*$/ ) {
            $clone = $1;
            my $total_length   = $2;
            my $Ql             = $3;
            my $quality_length = $4;
            my $Qr             = $quality_length + $Ql - 1;
            my $trimmed_length = 0;
            my @comments       = ();
            my $note_id        = 'NULL';
            my $error          = '';
            my @warnings       = ();

            my $cap     = 'xxx';
            my $prewell = $ri->{'pre_well'};
            $prewell =~ s/\-/\\-/g;
            if ( $clone =~ m/[$prewell][_\-]*([A-Z]\d\d)$ri->{'trace_file_ext'}$/ ) {
                $well = $1;
                if ( !( defined $ri->{'capillary'}{$well} ) ) {
                    $parsed_notes .= "Missing capillary definition for well $well in ri hash - skipping\n";
                    $error = "Name Format Error";
                }
                else {
                    $cap = $ri->{'capillary'}{$well};
                }
            }
            else {
                $parsed_notes .= "Error recognizing format of $clone (not $ri->{'pre_well'}+(well) ) - skipping\n";
                $error = "Name Format Error";
            }

            #<CONSTRUCTION> FIX this.... should not skip to next...
            #            if ($ri{'growth'}{$well} =~ /(OK|Slow Grow)/i) {
            #                print "\n============================================================\n";
            #                print "SKIPPPING $ri{growth}{$well}";
            #                print "\n============================================================\n";
            #                next;
            #            }

            ### critical comments at this stage require skipping to next record...(no stats provided)
            if ($error) {
                $p .= add_note( $dbc, 'Clone_Sequence', $ri->{'sequence_id'}, $well, $error );
                next;
            }

            $p .= "Length (of $clone): $total_length";

            my $line;
            if ($total_length) { $line = <SCREEN>; }
            else {
                $error   = 'Empty Read';
                $note_id = 5;
            }
            chop $line;
            my $total_read   = length($line);
            my $screened_seq = $line;

            # Read the rest of the sequence
            while ( $total_read < $total_length ) {
                $line = <SCREEN>;
                chop $line;
                $screened_seq .= $line;
                $total_read += length($line);
            }

            # Calculate Vector Left, Vector Right
            my $Vl         = -1;
            my $Vr         = -1;
            my $Vq         = 0;
            my $Vt         = 0;
            my $trim_left  = -1;
            my $trim_right = -1;

            if ( $quality_length > 0 ) {
                my $left_seq = substr $screened_seq, 0, $Ql;
                my $right_seq = substr $screened_seq, $Qr + 1;
                if ( $left_seq  =~ /[xX]$/ ) { $Vl = $Ql - 1; }
                if ( $right_seq =~ /^[xX]/ ) { $Vr = $Qr; }
                my $ll = length($left_seq);
                my $rl = length($right_seq);

                #	           print "\nLeft: $left_seq ($ll)\n";
                #	           print "\nRight: $right_seq ($rl)\n";

## quality region
                my $mid_seq = substr $screened_seq, $Ql, $quality_length;
                if ( $mid_seq =~ m/^([xX]*)([actgACTGnN]+)([xX]*)$/ ) {
                    $trimmed_length = length($2);
                    if ($1) { $Vl = length($1) + $Ql - 1; }
                    if ($3) { $Vr = $Ql + length($1) + length($2); }
                    $Vq = length($1) + length($3);
                }
                elsif ( $mid_seq =~ m/^([xX]+)$/ ) {
                    $trimmed_length = 0;
                    $Vl             = $total_length - 1;
                    $Vr             = 0;
                    $Vq             = $quality_length;
                    push( @warnings, 'Vector Only' );
                    $note_id = 3;
                }
                else {
                    my $format;
                    $Vq = 0;
                    my $IEseq = $mid_seq;
                    while ($IEseq) {
                        if ( $IEseq =~ /^([agtcAGTCnN]+)(.*)$/ ) {
                            $IEseq = $2;
                            $format .= "N(" . length($1) . ")";
                        }
                        elsif ( $IEseq =~ /^([xX]+)(.*)$/ ) {
                            $Vq += length($1);
                            $IEseq = $2;
                            $format .= "X(" . length($1) . ")";
                        }
                        else {
                            last;
                        }
                    }
                    print "Vector segment found: $format. (Qleft:$Ql)\n";
                    $note_id = 4;
                    push( @warnings, 'Vector Segment' );
                    push( @comments, $format );
                }

                if ( $Vr > 0 ) { $Vt += $total_length - $Vr + 1; }
                if ( $Vl > 0 ) { $Vt += $Vl + 1; }

                if ( $Vt > $total_length ) {
                    $Vt = $total_length;
                    $Vl = $total_length;
                    $Vr = 0;
                }
            }
            elsif ( $total_length > 0 ) {
                $Vl             = -1;
                $Vr             = -1;
                $Vq             = 0;
                $Vt             = 0;
                $Ql             = -1;
                $Qr             = -1;
                $quality_length = 0;
                $note_id        = 1;
                push( @warnings, 'Poor Quality' );
            }
            else {
                $error          = 'Empty Read';
                $quality_length = 0;
                $total_length   = 0;
                $p .= add_note( $dbc, 'Clone_Sequence', $ri->{'sequence_id'}, $well, $error );
            }

            my $fail       = 0;
            my $phred_file = "$ri->{'savedir'}/$ri->{'longname'}/$phred_dir/$clone.phd.1";

            open( PFILE, $phred_file ) or $fail = 1;

            print PEAK ">$clone\n";
            print QUAL ">$clone\n";
            print BP ">$clone\n";
            ## open phred files to get scores

            if ($fail) {
                $parsed_notes .= "Error opening phred file: $phred_file: $!\n";
                next;
            }

            my @hist    = map {0} ( 0 .. 99 );
            my @trimmed = map {0} ( 0 .. 99 );
            my ( @bps, @qs, @peaks );

            my $peak_area_ratio_max = 0.2;    ## set threshold for warning about high peak area ratios.
            my $peak_ratio          = 0;
            while (<PFILE>) {
                $line = $_;
                if ( $line =~ /^TRIM:\s+(\d+)\s+(\d+)\s+(\d+[.]?\d+)/ ) {
                    $trim_left  = $1;
                    $trim_right = $2;
                }
                elsif ( $line =~ /^TRACE_PEAK_AREA_RATIO:\s+(\d+[.]?\d+)/ ) {
                    $peak_ratio = $1;
                    push( @warnings, 'High Peak Area Ratio' ) if ( $peak_ratio > $peak_area_ratio_max );
                }
                elsif ( $line =~ /^BEGIN_DNA/ ) {
                    while (<PFILE>) {
                        if (/(\w)\s+(\d+)\s+(\d+)/) {
                            push( @bps,   $1 );
                            push( @qs,    $2 );
                            push( @peaks, $3 );
                        }
                    }
                    if (/^END_DNA/) {last}
                }
            }
            print PEAK join ' ', @peaks;
            print PEAK "\n";

            print BP join ' ', @bps;
            print BP "\n";

            print QUAL join ' ', @qs;
            print QUAL "\n";

            my $total_score = "";
            my $total_seq   = "";
            my @all_scores;
            my $length = 0;

            my $index         = 1;
            my $trimmed_left  = $Ql;
            my $trimmed_right = $Qr;
            if ( $Vl > $Ql ) { $trimmed_left = $Vl; }
            if ( ( $Vr >= 0 ) && ( $Vr < $Qr ) ) { $trimmed_right = $Vr; }

            for ( my $i = 0; $i < scalar(@bps); $i++ ) {
                my $seq_bp = $bps[$i];
                my $score  = $qs[$i];
                if ( ( $index >= $trimmed_left ) && ( $index <= $trimmed_right ) ) {
                    $trimmed[$score]++;
                }
                $total_seq .= $seq_bp;
                push( @all_scores, $score );
                $hist[$score]++;
                $length++;
            }

            # Check for Repeating sequences
            my $insert = substr( $total_seq, $trimmed_left, $trimmed_right - $trimmed_left + 1 );    ## changed Version 2.40 to use Vector trimmed insert.
            my $repeat;
            my $repeat_comment = '';
            my $repeat_length  = 2;
            while ( !$repeat && $repeat_length < 5 ) {
                ( $repeat, $repeat_comment ) = &check_for_repeating_sequence( $insert, $repeat_length );
                $repeat_length++;
            }

            if ( $repeat && $insert ) {
                $note_id = 6;
                $p .= "** Add note: $repeat_comment to $ri->{'sequence_id'} $well\n";
                push( @warnings, "Recurring String" );
                push( @comments, "$repeat_comment" );
            }
            elsif ($repeat_comment) {
                push @comments, $repeat_comment;
            }

            $p .= "Tr=$trim_right($Qr), Tl=$trim_left($Ql), PR=$peak_ratio; Qlength=$quality_length, (trimmed = $trimmed_length), Vl=$Vl, Vr=$Vr, Vq=$Vq; Vt=$Vt\n";

            #  Generate CUMULATIVE histogram
            my $packed_scores = pack "C*", @all_scores;
            my $cum_hist      = 0;
            my $cum_trimmed   = 0;
            my @chist         = map {0} ( 0 .. 99 );
            my @ctrimmed      = map {0} ( 0 .. 99 );
            for my $index ( 0 .. 99 ) {
                $cum_hist += $hist[ 99 - $index ];
                $chist[ 99 - $index ] = $cum_hist;

                $cum_trimmed += $trimmed[ 99 - $index ];
                $ctrimmed[ 99 - $index ] = $cum_trimmed;
            }

            ### specially stored stats for Q20 (avg, median, mean) and total length) ###
            # Only Q20 for normal and SG wells will be included. i.e. don't want to count Q20 from NGs and unused wells.

#	    my $query_well = $well;
#            $query_well =~ s/([A-Z])0(\d)/$1$2/; #Need to convert A02 to A2, B07 to B7, etc before querying the Plate table.
#                my ($count) = $dbc->Table_find('Plate,Library_Plate','Count(*)',"where  FK_Plate__ID=Plate_ID AND Plate_ID = " . $ri{'plate_id'} . " and (No_Grows regexp '[[:<:]]$query_well\[[:>:]]' or Unused_Wells regexp '[[:<:]]$query_well\[[:>:]]')");

            #unless ($ri{'ignore_read'}{$well}) {
            #    push(@Q20,$chist[20]);
            #}

            if ( $ri->{'ignore_read'}{$well} ) {
                print "****************IGNORED READ ************************\n";
                print "Well $well ignored because of reason: $ri->{'ignore_read'}{$well}";
            }
            else {
                push( @Q20, $chist[20] );
            }

            my $hist_values    = pack "S*", @chist;
            my $trimmed_values = pack "S*", @ctrimmed;

            my $warning = join ',', @warnings;
            my $comment = join ',', @comments;
            if ($warning) {
                $p .= "Warnings: $warning";
                add_note( $dbc, 'Clone_Sequence', $ri->{'sequence_id'}, $well, $warning );
            }

            if ($comment) {
                $p .= "Comments: $comment";
                add_note( $dbc, 'Clone_Sequence', $ri->{'sequence_id'}, $well, $comment );
            }

            @values = ( $total_seq, $length, $Ql, $quality_length, $Vl, $Vr, $Vq, $Vt, $comment, $note_id, $cap, $peak_ratio );

            # update Clone_Sequence

            if ( !$dbc->Table_update_array( 'Clone_Sequence', \@fields, \@values, "where FK_Run__ID = $ri->{'sequence_id'} and Well='$well'", -autoquote => 1 ) ) {

                if ($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }

                $parsed_notes .= "Warning: nothing updated (could be UNUSED Wells ?): $DBI::errstr\n";
                #### show command if it didn't work.. ###
                $dbc->Table_update_array( 'Clone_Sequence', \@fields, \@values, "where FK_Run__ID = $ri->{'sequence_id'} and Well='$well'", -autoquote => 1 );
                if ($DBI::errstr) {
                    $Report->set_Error($DBI::errstr);
                }

            }

            else {
                my $thisnote;
                my $thiscomment;
                if ($warning) { $thisnote = "\tW: $warning"; }
                if ($error)   { $thisnote = "\t** Error: $error"; }
                if ( $comment =~ /\S/ ) { $thiscomment = "\tC: $comment"; }
                $parsed_notes .= "$well:\t$length\t$quality_length$thisnote$thiscomment\n";
                push( @SL, $length );
            }

            # update with histogram
            if ( !Table_binary_update( $dbc, 'Clone_Sequence', 'Phred_Histogram', $hist_values, "where FK_Run__ID = $ri->{'sequence_id'} and Well='$well'" ) ) {
                $parsed_notes .= "Warning: histogram not updated: $DBI::errstr\n";
            }

            # update with quality histogram
            if ( !Table_binary_update( $dbc, 'Clone_Sequence', 'Quality_Histogram', $trimmed_values, "where FK_Run__ID = $ri->{'sequence_id'} and Well='$well'" ) ) {
                $parsed_notes .= "Warning: quality histogram not updated: $DBI::errstr\n";
            }

            # update with Scores
            if ( !Table_binary_update( $dbc, 'Clone_Sequence', 'Sequence_Scores', $packed_scores, "where FK_Run__ID = $ri->{'sequence_id'} and Well='$well'" ) ) {
                $parsed_notes .= "Warning: Scores not updated: $DBI::errstr\n";
            }

            $p .= "Updated $well\n";
        }
        close(PFILE);
    }
    close(SCREEN);

    close(BP);
    close(QUAL);
    close(PEAK);
    #### Transaction ####

    $ri->{'analysis_time'} = &RGTools::RGIO::date_time();

    my $seq_run_id = join ',', $dbc->Table_find( 'SequenceRun', 'SequenceRun_ID', "WHERE FK_Run__ID=$ri->{'sequence_id'}" );

    $dbc->Table_update_array( 'SequenceAnalysis', [ 'SequenceAnalysis_DateTime', 'Phred_Version', 'mask_restriction_site' ], [ $ri->{'analysis_time'}, $phred_version, $mask_restriction_site ], "where FK_SequenceRun__ID=$seq_run_id", -autoquote => 1 );

    if ($DBI::errstr) {
        $Report->set_Error($DBI::errstr);
    }

    #  $p .= "Updating Run Statistics...\n";

    #  &update_run_statistics($dbc,$ri{'sequence_id'},\@Q20,\@SL);
    &get_run_statistics( $dbc, [ $ri->{'sequence_id'} ] );

    Seq_Notes( $0, $parsed_notes, 'text', $ri->{'log_file'} );

    Seq_Notes( "", "Done parsing the phred scores ($ri->{'sequence_id'})\n", 'text', $ri->{'log_file'} );

    return $p;
}

#############################
sub get_run_statistics {
#############################
    my $dbc    = shift || $Connection;
    my $runs   = shift;
    my $Report = shift;

    my @list    = @$runs;
    my $success = 100;      ## define success as runs with contiguous 'quality' (~Q20) > 100 ##

    my $include_wells = "'OK','Slow Grow'";
    if ( int(@list) ) { print "from @list"; }
    my $updated = 0;

    foreach my $run_id (@list) {

        #my %info = $dbc->Table_retrieve("Clone_Sequence", ["LEFT(Well,1)", "Count(*)","Sequence_Length"], "WHERE FK_Run__ID = $run_id group by LEFT(Well,1)");
        #print Dumper \%info;

        my $fixed = &delete_record( $dbc, 'Clone_Sequence', 'FK_Run__ID', $run_id, "Sequence_Length=-2" );    ## get rid of invalid reads...
        Message("Deleting $fixed unanalyzed runs");
        my @Q20 = $dbc->Table_find_array( 'Clone_Sequence', [ SQL_phred(20) ], "where FK_Run__ID = $run_id AND Growth IN ($include_wells) Order by Well" );
        my @SL = $dbc->Table_find( 'Clone_Sequence', 'Sequence_Length', "where FK_Run__ID = $run_id AND Growth IN ($include_wells) Order by Well" );
        my $count = int(@SL);

        my ($All_data) = $dbc->Table_find( 'Clone_Sequence', 'count(*),Sum(Sequence_Length)', "where FK_Run__ID=$run_id" );
        my ( $all_reads, $all_bp ) = split ',', $All_data;

        my ($NG) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth like 'No Grow'" );
        my ($SG) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth like 'Slow Grow'" );
        my ($EW) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth like 'Empty'" );
        my ($PW) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth like 'Problematic'" );
        ## <CONSTRUCTION> important : add problematic / empty wells ...
        my ($successful)  = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth IN ($include_wells) AND Quality_Length >= $success" );
        my ($Tsuccessful) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID=$run_id AND Growth IN ($include_wells) AND Quality_Length - Vector_Quality >= $success" );

        my ($info)
            = $dbc->Table_find_array( 'Clone_Sequence', [ 'Avg(Vector_Quality)', 'Sum(Vector_Quality)', 'Avg(Quality_Length)', 'Sum(Quality_Length)', 'Sum(Vector_Total)' ], "where FK_Run__ID=$run_id AND Growth IN ('OK','Slow Grow') Order by Well" );
        my ( $QVmean, $QVtotal, $QLmean, $QLtotal, $Vtotal ) = split ',', $info;
        print "\n*****\nfound: $QVmean..$QVtotal..$QLmean..$QLtotal..$Vtotal;\n";

        my %args;
        $args{NGs}                      = $NG          || 0;
        $args{SGs}                      = $SG          || 0;
        $args{EWs}                      = $EW          || 0;
        $args{PWs}                      = $PW          || 0;
        $args{successful_reads}         = $successful  || 0;
        $args{trimmed_successful_reads} = $Tsuccessful || 0;
        $args{AllReads}                 = $all_reads   || 0;
        $args{AllBPs}                   = $all_bp      || 0;
        $args{QVmean}                   = $QVmean      || 0;
        $args{QVtotal}                  = $QVtotal     || 0;
        $args{QLmean}                   = $QLmean      || 0;
        $args{QLtotal}                  = $QLtotal     || 0;
        $args{Vtotal}                   = $Vtotal      || 0;

        ### update warning countss ### (keys should all be field in SequenceAnalysis table) #####

        my %Warning;
        $Warning{PoorQualityWarnings}     = 'Poor';
        $Warning{VectorSegmentWarnings}   = 'Segment';
        $Warning{RecurringStringWarnings} = 'String';
        $Warning{VectorOnlyWarnings}      = 'Vector Only';
        $Warning{ContaminationWarnings}   = 'Contamination';
        $Warning{PeakAreaRatioWarnings}   = 'High Peak Area Ratio';

        foreach my $key ( keys %Warning ) {
            my $find = $Warning{$key};
            my ($found) = $dbc->Table_find( 'Clone_Sequence', 'count(*)', "where FK_Run__ID = $run_id and Read_Warning like '%$find%'" );
            $found ||= 0;
            $args{$key} = $found;
        }

        &update_run_statistics( $dbc, $run_id, \@Q20, \@SL, \%args, $Report );

        print "Updated Run $run_id ($count reads)\n";
        $updated++;
    }
    return $updated;
}

################################
sub update_run_statistics {
################################
    my $dbc        = shift || $Connection;
    my $run_id     = shift;
    my $q20ref     = shift;
    my $slref      = shift;
    my $parameters = shift;
    my $Report     = shift;

    my %args;
    if ($parameters) {
        %args = %{$parameters};
    }

    #    print "ARGS" . Dumper \%args;
    #    my %ri = %{ $args{'run_info'} };
    my @Q20;
    if ($q20ref) { @Q20 = @$q20ref; }
    my @SL;
    if ($slref) { @SL = @$slref; }

    my $Qstat = Statistics::Descriptive::Full->new();
    $Qstat->add_data(@Q20);

    my $q20mean   = $Qstat->mean();
    my $q20median = $Qstat->median();
    my $q20max    = $Qstat->max();
    my $q20min    = $Qstat->min();
    my $q20total  = $Qstat->sum();

    my $Lstat = Statistics::Descriptive::Full->new();
    $Lstat->add_data(@SL);
    my $SLmean   = $Lstat->mean();
    my $SLmedian = $Lstat->median();
    my $SLmax    = $Lstat->max();
    my $SLmin    = $Lstat->min();
    my $SLtotal  = $Lstat->sum();
    my $count    = $Lstat->count();

    my ($sequence_run_id) = $dbc->Table_find( 'SequenceRun', 'SequenceRun_ID', "WHERE FK_Run__ID=$run_id" );

    ### all stats generally exclude No Grows ###
    my @fields = ( 'FK_SequenceRun__ID', 'Q20mean', 'Q20median', 'Q20max', 'Q20min', 'Q20total', 'SLmean', 'SLmedian', 'SLmax', 'SLmin', 'SLtotal', 'Wells' );

    my @values = ( $sequence_run_id, $q20mean, $q20median, $q20max, $q20min, $q20total, $SLmean, $SLmedian, $SLmax, $SLmin, $SLtotal, $count );
    unless ( $SLmax =~ /\d/ ) { print "No Data yet for $run_id ?\n"; return; }

    foreach my $key ( keys %args ) {    ### add extra fields (NGs, SGs, QVmean, QVtotal ...
        unless ($key) {next}
        my $value = $args{$key};
        push( @fields, $key );
        push( @values, $value );
        print "\n$key=$value\n";
    }

    $dbc->Table_update_array( 'SequenceAnalysis', \@fields, \@values, "where FK_SequenceRun__ID=$sequence_run_id", -autoquote => 1 );

    if ($DBI::errstr) {
        $Report->set_Error($DBI::errstr);
    }

    my $q20_packed = pack "S*", @Q20;
    &Table_binary_update( $dbc, 'SequenceAnalysis', 'Q20array', $q20_packed, "where FK_SequenceRun__ID = $sequence_run_id" );
    if ($DBI::errstr) {
        $Report->set_Error($DBI::errstr);
    }

    my $sl_packed = pack "S*", @SL;
    &Table_binary_update( $dbc, 'SequenceAnalysis', 'SLarray', $sl_packed, "where FK_SequenceRun__ID = $sequence_run_id" );
    if ($DBI::errstr) {
        $Report->set_Error($DBI::errstr);
    }

    ## dump run information to a run_details file ##
    #    open(FILE,"$ri{'savedir'}/$ri{'longname'}/$phred_dir/run_details.txt") or return;  ## return if this directory not available..
    #    print FILE Dumper(\%ri);

    return;
}

#####################
sub check_phred_version {
#####################
    #
    # Simply return current version of phred being used.
    #
    my $version = `$PHRED_FILE -V`;
    if   ( $version =~ /version:(.*)/ ) { return $1 }
    else                                { return $version }
}

#########
#
# Private Subroutines
#
#######################
sub phred_command {
#######################
    # generates the phred command used to analyze the sequence

    my $sequence    = shift;
    my $directory   = shift;    # filename
    my $output_file = shift;    # output filename
    my $phd         = shift;    # output into phred directory...

    my $qual_file = $output_file;
    $qual_file =~ /(.*)phredscores(.*)$/;
    $qual_file = "$1phredscores.qual";

    my $pc = "$PHRED_FILE -id $directory -qa $qual_file";
    $pc .= " -st fasta -sa $output_file -qt mix  -pd $phd -p";
    if   ( $sequence =~ /[a-zA-Z]+/ ) { $pc .= " -trim_alt $sequence "; }
    else                              { $pc .= " -trim_alt \"\""; }

    return $pc;
}

################################
sub cross_match_command {
    ##############################
    #
    # generates the command used to run 'cross-match'
    #
    my $phred_file      = shift;    ### name of phred file to run cross-match on
    my $vector_sequence = shift;    ### name of vector sequence file (default to fasta file containing all vectors)
    my $output_file     = shift;    ### where to put the results when done..
    my $generate_screen = shift;    ### generate phredscores.screen
    $vector_sequence ||= "$vector_directory/vector";
    my $options = " -minmatch 12 -minscore 20";
    if ($generate_screen) {
        $options .= " -screen";
    }
    my $cmc = "/opt/alDente/software/sequencing/phrap/cross_match $phred_file $vector_sequence $options > $output_file";

    return $cmc;
}

#################
sub add_note {
    #####################
    #
    # Add a Note regarding a Run run
    #
    # (used to flag runs with:
    #   Poor Quality
    #   only Vector Data
    #   Repeating strings
    #   Empty Read data
    #   Indexing Errors.. (ie. finite Vector found inside insert)
    #

    #
    # Temporary: fix to only comment when comments NOT in list of Warnings/Errors...
    #

    my $dbc         = shift || $Connection;
    my $table       = shift;
    my $sequence_id = shift;
    my $well        = shift;
    my $comments    = shift;

    my @add_comments;
    my $p;
    my $note_id = 'NULL';

    my @warnings = ();
    my $error;

    print "** ADD NOTE: Run$sequence_id;$well;$comments.\n";

    if ( $comments =~ /trace data missing/ ) {
        $note_id = 2;
        $error   = 'trace data missing';
    }
    elsif ( $comments =~ /Empty Read/ ) {
        $note_id = 5;
        $error   = 'Empty Read';
    }
    elsif ( $comments =~ /Name Format Error/i ) {

        #      push(@add_comments,$1);
        #      $note_id = 6;
        $error = 'Analysis Aborted';
    }
    if ( $comments =~ /Poor Quality/ ) {
        $note_id = 1;
        push( @warnings, 'Poor Quality' );
    }
    if ( $comments =~ /Vector Only/ ) {
        $note_id = 3;
        push( @warnings, 'Vector Only' );
    }
    if ( $comments =~ /Vector Segment/ ) {

        #      push(@add_comments,$1);
        $note_id = 4;
        push( @warnings, 'Vector Segment' );
    }
    if ( $comments =~ /Recurring String/i ) {

        #      push(@add_comments,$1);
        #      my $repeat = $1;
        $note_id = 6;
        push( @warnings, 'Recurring String' );

        #      push(@add_comments,$repeat);
    }
    if ( $comments =~ /\(E=(\S+?)\)/ ) {
        my $evalue = $1;
        push( @add_comments, "(E=$evalue)" );
        push( @warnings,     'Contamination' );
    }

###########
    my $warning = join ',', @warnings;

    if ( $error || $warning ) {    ### otherwise leave comments intact...
        $comments = join '; ', @add_comments;    ### clears comments if only warning or error.
    }

    my %Current_Notes = &Table_retrieve( $dbc, "Clone_Sequence", [ 'Clone_Sequence_Comments as Comments', 'Read_Warning as Warning', 'Read_Error as Error', 'Well' ], "where FK_Run__ID=$sequence_id and Well='$well'" );

    my $current_comment = $Current_Notes{Comments}[0];
    my $current_warning = $Current_Notes{Warning}[0];
    my $current_error   = $Current_Notes{Error}[0];

    my @fields;
    my @values;

    if ($note_id) {
        push( @fields, 'FK_Note__ID' );
        push( @values, $note_id );
    }

    if ($error) {

        #      print "*** Error Noted ***\n+";
        if ( !$current_error ) {
            @fields = ( 'FK_Note__ID', 'Read_Error' );
            @values = ( $note_id, $error );
        }
        elsif ( $current_error =~ /$error/ ) { }    ## already commented...
        else {
            @fields = ( 'FK_Note__ID', 'Read_Error' );
            @values = ( $note_id, "$current_error,$error" );
        }
    }

    elsif ($warning) {

        #      print "*** Warning Noted ($warning) ***\n+";
        if ( !$current_warning ) {
            @fields = ( 'FK_Note__ID', 'Read_Warning' );
            @values = ( $note_id, $warning );
        }
        elsif ( $current_warning =~ /$warning/ ) { }
        else {
            @fields = ( 'FK_Note__ID', 'Read_Warning' );
            @values = ( $note_id, "$current_warning,$warning" );
        }
    }

    if ( $comments =~ /\S/ ) {
        if ( $current_comment =~ /$comments/ ) { }    ## already commented...
        elsif ($current_comment) {
            push( @fields, 'Clone_Sequence_Comments' );
            push( @values, "$current_comment; $comments" );
        }
        else {
            push( @fields, 'Clone_Sequence_Comments' );
            push( @values, "$comments" );
        }
    }

    if ( int(@values) ) {
        my $updated = $dbc->Table_update_array( "Clone_Sequence", \@fields, \@values, "where FK_Run__ID=$sequence_id and Well='$well'", -autoquote => 1 );
        $p = "$comments - ($updated updated) $sequence_id-$well";
    }

    return $p;
}

#######################
sub link_96_to_384 {
#######################
    #
    # This routine symbolic links 96 well plates to 384 well sequence runs
    #

    my %args     = @_;
    my $dbc      = $args{'dbc'} || $Connection;
    my %ri       = %{ $args{'run_info'} };
    my $reversal = $args{'reversal'} || 0;

    my $p;
    my $command;

    my $quad = $ri{'Master_quadrant'};

    ######## get Master filename
    ######## get applicable quadrant
    #    $datafiles =~/(\.{5}\d+[a-zA-Z]?)(\.\w+)(\.?\d*)/;
    #    my $Mb = $1; my $Mc = $2; my $Mv = $3;

    my $startLetter = 'A';
    my $endLetter   = 'P';
    my $startNum    = 1;
    my $endNum      = 24;

    ### map 384 to 96 well if necessary...
    my %quad96;
    my %W96;

    my @info = $dbc->Table_find( 'Well_Lookup', 'Plate_384,Plate_96,Quadrant' );

    foreach my $well (@info) {
        ( my $p384, my $p96, my $quad ) = split ',', $well;
        if ( $p384 =~ /([a-zA-Z])(\d+)/ ) {
            my $row   = uc($1);
            my $col   = $2 + 0;
            my $index = $row . $col;
            $W96{$index}    = $p96;
            $quad96{$index} = $quad;
        }
    }
    $p .= "Mapped 96 -> 384 well.\n\n";

    my @quadrants = ( 'a', 'b', 'c', 'd' );

    my $source = $ri{'archived'};
    $source =~ s /\/mirror\//\/archive\//;
    my @files = glob "$source$ri{'trace_file_ext'}";

    #    print "found:".join ',',@files;

    my $index       = 0;
    my $transferred = 0;
    my $found       = 0;
    foreach my $row ( $startLetter .. $endLetter ) {
        foreach my $col ( $startNum .. $endNum ) {
            my $well384 = $row . $col;
            my $thisquad;
            my $well96;
            my $well = $well384;
            $well =~ m/([a-zA-Z])(\d+)/;
            my $num = $2 + 0;
            if ( $num < 10 ) { $well = $1 . '0' . $num; }

            if ($reversal) {
                $well384 = &alDente::Well::well_complement( $well384, 384 );
            }

######## ALWAYS convert_96_to_384.. ? #############
            if ( $ri{'convert_96_to_384'} ) {
                $thisquad = $quad96{$well384};
                $well96   = $W96{$well384};
            }
            else {    ## no conversion...
                $thisquad = '';
                $well96   = $well384;
            }
            if ( $reversal =~ /partial/i ) {    ### revert back to original quadrant...
                if    ( $thisquad =~ /a/ ) { $thisquad = 'd'; }
                elsif ( $thisquad =~ /b/ ) { $thisquad = 'c'; }
                elsif ( $thisquad =~ /c/ ) { $thisquad = 'b'; }
                elsif ( $thisquad =~ /d/ ) { $thisquad = 'a'; }
            }

            #      $p .= "***** $well\n";
            if ( $thisquad ne $quad ) {

                #	$p .= "($thisquad ne $quad)";
                next;
            }
            $well384 =~ m/([a-zA-Z])(\d+)/;
            my $num_384 = $2 + 0;
            if ( $num_384 < 10 ) { $well384 = $1 . '0' . $num_384; }

            my $temp_longname = ${ $ri{'sub_384_name'} }{$thisquad};
            my $temp_basename = $temp_longname;
            $temp_basename =~ s/(.*?)\.(.*)/$1/;    ## remove chemistry/version

            my ( $file, $new_file );
            if ( $ri{'Mtype'} eq 'ABI' ) {
                $new_file = "$ri{'savedir'}/$temp_longname/$trace_dir/$temp_longname" . "_$well96" . $ri{'trace_file_ext'};
            }
            elsif ( $ri{'Mtype'} eq 'Megabace' ) {
                $new_file = "$ri{'savedir'}/$ri{'longname'}/$trace_dir/$temp_basename$well96$ri{'post_well'}" . $ri{'trace_file_ext'};
            }
            else { $p = "Error in Sequencer type ($ri{'Mtype'})"; return $p; }

            my $file_template = $ri{'archived'};
            if ( $file_template =~ m/\/(.*?)$/ ) { $file_template = $1; }
            $file_template = substr( $file_template, 0, 10 );

            foreach my $thisfile (@files) {
                if ( $thisfile =~ /$ri{'Master_basename'}$ri{'Master_chemcode'}(.*)\/$ri{'Master_basename'}$ri{'Master_chemcode'}(.*)$well/ ) {
                    $file = $thisfile;
                    last;
                }
            }

            if ( $file =~ m/_\-_(\d+)\./ ) {
                my $cap = $1;
                $new_file =~ s/___xxx/___$cap/;    # replace xxx with the capillary number
            }

            if ( $index =~ /^(1|96|192|288|384)$/ ) {
                print "** $index ** LINK file $file\n-> $new_file ($well) = $well96.\n";
            }
            if ( $file && ( $new_file =~ /\w/ ) ) {
                unlink $new_file;

                # get the original well
                $new_file =~ /([A-P]\d\d)$ri{'trace_file_ext'}$/;
                my $well = $1;

                # get the capillary
                $file =~ /([x\d]*)$ri{'trace_file_ext'}*$/;
                my $capillary = $1;
                $args{'run_info'}{'capillary'}{$well} = $capillary;

                my $ok = symlink $file, $new_file;
                if ($ok) { $found++ }
                else {
                    $p .= "Error: Failure linking: $file to $new_file\n";
                }
                $transferred++;
            }
            else {
                $p .= "$ri{'archived'}$well*$ri{'trace_file_ext'} ($row$col:$thisquad.$well96) not found\n";
            }
            $index++;
        }
    }

    # Seq_Notes($0, "\n** Transferred $transferred (of $index) files\n$p",'text',$ri{'log_file'});
    $p .= "Found $found.\n";
    $p .= "Transferred $transferred.\n";
    return $p;
}

#########################################
sub check_for_repeating_sequence {
#########################################
    #
    #  Check for repeating string given repetition length.
    #
    #  (ie 'atatatatat' has a repetition length of 2.
    #
    #  To qualify:
    #
    #   Total string length should be at least 5 x the repetition length
    #
    #   The non-repeating portion of the string reduces to less than twice the repetition length (with the repeating section removed)
    #
    my $sequence = shift;    ### input sequence string
    my $length   = shift;    ### specify length of repeating sequence to check for

    my $Slength = length($sequence);

    if ( $Slength < $length * 2 ) { return ( 0, "Way too short to check for repeats (<" . 2 * $length . ")" ) }

    my $seq = substr( $sequence, $length, $length );    ### pull out N chars (offset by N)
    $sequence =~ s/$seq//g;

    if ( $Slength > 5 * $length ) {
        if ( length($sequence) < ( $length * 2 ) ) {
            my $times = ( $Slength - length($sequence) ) / $length;
            return ( 1, "$seq($times)" );
        }
        else { return ( 0, '' ) }
    }
    else { return ( 0, "Too short to check for repeats (<" . 5 * $length . ")" ) }
}

#
#
#
#
#################################
sub create_temp_screen_file {
#################################
    my $dbc                   = shift;
    my $plate_id              = shift;
    my $temp_screen_file      = shift;
    my $mask_restriction_site = 1;

    ## Find the vector sequence file for the plate:
    my @vector_sequence_file = Table_find(
        $dbc,
        'Plate,LibraryVector,Vector,Vector_Type',
        'Vector_Type.Vector_Sequence_File',
        "WHERE Plate_ID = $plate_id and Plate.FK_Library__Name = LibraryVector.FK_Library__Name and FK_Vector__ID = Vector_ID and Vector_Type_ID = FK_Vector_Type__ID"
    );

    ## find the restriction sites defined for the library
    my @library_info
        = Table_find( $dbc, 'Plate,Library,Vector_Based_Library', 'Library_Name,FK3Prime_Enzyme__ID,FK5Prime_Enzyme__ID', "WHERE Plate.FK_Library__Name = Library_Name and Vector_Based_Library.FK_Library__Name = Library_Name and Plate_ID = $plate_id" );

    my ( $library, $restriction_site_3prime, $restriction_site_5prime ) = split ',', $library_info[0];

    ## create temporary vector sequence file

    open( TFILE, ">$temp_screen_file" ) or die "error opening $temp_screen_file";

    my $vectors_added = 0;
    foreach my $vector_file (@vector_sequence_file) {
        if ( -e "$vector_directory/$vector_file" && $vector_file ) {
            my ( $found_sequence, $header ) = parse_vector_file($vector_file);
            if ($found_sequence) {
                ## check for restriction site based on the plate,library
                my $restriction_3prime_seq;
                if ($restriction_site_3prime) {
                    ($restriction_3prime_seq) = Table_find( $dbc, 'Vector_Based_Library,Enzyme', 'Enzyme_Sequence', "where FK_Library__Name = '$library' AND $restriction_site_3prime = Enzyme_ID" );
                }
                my $restriction_5prime_seq;
                if ($restriction_site_5prime) {
                    ($restriction_5prime_seq) = Table_find( $dbc, 'Vector_Based_Library,Enzyme', 'Enzyme_Sequence', "where FK_Library__Name = '$library' AND $restriction_site_5prime = Enzyme_ID" );
                }
                my @restriction_sequences;
                if ($restriction_3prime_seq) {
                    push( @restriction_sequences, $restriction_3prime_seq );
                }
                if ($restriction_5prime_seq) {
                    push( @restriction_sequences, $restriction_5prime_seq );
                }
                ( $found_sequence, $mask_restriction_site ) = mask_restriction_site( $found_sequence, \@restriction_sequences, $mask_restriction_site );

                print TFILE ">$header\n";
                print TFILE "$found_sequence\n";
                if ( $found_sequence && $header ) {
                    $vectors_added++;
                }
            }

        }
    }
    close(TFILE);
    if ( $vectors_added < 1 ) {
        try_system_command( -command => "cp $vector_directory/vector $temp_screen_file" );
    }

    return $mask_restriction_site;
}
###########################
sub mask_restriction_site {
###########################
    my $found_sequence        = shift;
    my $restriction_sequences = shift;
    my $mask_restriction_site = shift;
    my @restriction_sequences = @{$restriction_sequences};

    if (@restriction_sequences) {
        ## find the sequences that match

        my $String = String->new( -text => $found_sequence );
        $String->find_matches( -searches => \@restriction_sequences, -group => 1 );
        my $index = 0;
        my $new_sequence;
        while ( defined $String->{matches}->{sections}->{ ++$index } ) {
            my @matches = @{ $String->{matches}->{sections}->{$index}->{matches} };

            my $substring = $String->{matches}->{sections}->{$index}->{text};
            if ( int(@matches) == 0 ) {
                $new_sequence .= $substring;
            }
            else {
                ## Set the mask restriction site to false
                ## match found.  restriction site is not masked.
                $mask_restriction_site = 0;
            }
        }
        ## modify the vector sequence based on the restriction site

        $found_sequence = $new_sequence;
    }
    return ( $found_sequence, $mask_restriction_site );
}

# Parse the vector file for the sequence and header information
#
#
#
##########################
sub parse_vector_file {
##########################
    my $file       = shift;
    my $name       = shift;
    my $Report     = shift;
    my $check_name = shift;

    open( VFILE, "$vector_directory/$file" ) or die "error opening $file for reading (in $vector_directory)";
    my $found_sequence = '';
    my $header         = <VFILE>;
    if ( $header =~ /^>([^\|]+)/ ) {
        my $label = $1;
        xchomp($label);
        if ( $name && ( $label !~ /\Q$name\E/i ) ) {
            $Report->set_Warning("Header name ($label) doesn't match Vector name ($name) in $file.");
        }
    }
    else {
        $Report->set_Error("Incorrect/missing header in $file sequence file:\n$header\n");
        return 0;
    }
    while (<VFILE>) {
        if (/^>/) {
            $Report->set_Error("Multiple vectors in one file ($file) (must be separated).");
            return 0;
        }    ## more than one sequence in file..
        elsif (/^([agtcn\s]+)$/i) { $found_sequence .= $1 }
        else {
            $Report->set_Error("Unrecognized characters found in ($file) where sequence expected: $_.");
            return 0;
        }
    }
    $found_sequence =~ s /\s//g;    ## remove any linebreaks / spaces ...
    close(VFILE);

    return ( $found_sequence, $header );
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

2003-11-27

=head1 REVISION <UPLINK>

$Id: Post.pm,v 1.110 2004/12/06 20:07:13 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
