###################################################################################################################################
#
#
#
#
###################################################################################################################################
package alDente::System_Views;
use base alDente::Object_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Graph;
use RGTools::Conversion;

## alDente modules
use alDente::System;
use alDente::SDB_Defaults;

use vars qw( %Configs );


######################
# Constructor
##############
sub new {
##############	
    my $this  = shift;
    my %args  = filter_input( \@_ );
    my $model = $args{-model};
	my $dbc   = $args{-dbc};
	
    my $self  = {};
    $self->{'dbc'} = $dbc;
    my ($class) = ref $this || $this;
    bless $self, $class;
	
	return $self;	
}


#############################
sub display_Entry_Page {
#############################
    my $self = shift;
    my $host = shift;

    my %args = &filter_input(\@_);
    my $System = $self->{'System'};

    my $page ;
    my %layers;

    Message("This is retrieving a number of detailed log files.  Please be patient....");
    print '<p ></p>';

    $layers{'Data Volumes'} = $self ->  show_Volumes($host);
    $layers{'Directories'} =  $self -> show_Directories($host) ;
    $layers{'Warnings'}    = $self -> show_highlights('dirs') . '<HR>' . $self->show_highlights('vols');
    $page .= &define_Layers(-layers=>\%layers,-format=>'tab',-tab_width=>100);

    return $page ;
}

####################################
sub display_Graph {
####################################
    my $self = shift;
    my %args = &filter_input(\@_);
    my $directory  = $args {-directory};
    my $host    = $args {-host};
    my $ymax    = $args{-ymax};
    my $height  = $args{-height};
    my $type    = $args{-type};

    if ($ymax =~ /[GMTP]$/) { $ymax = get_number($ymax) / 1000 }
   
    ## Add threshold line to graph at ymax ##

    my $System = $self->{'System'};

    my $page = "<h2>$directory Space Usage History</h2>";
    
    my $size_file;       
    my ($xcol, $ycol);
    if ($type eq 'dirs') { 
	($xcol, $ycol) = (0,1);   ## graph Date vs Size for dirs stats file 
	$size_file = $System->get_stat_file(-dir=>$directory, -host=>$host); ##rebuild_sizes_file($host,$directory);    
    }
    else { 
	($xcol, $ycol) = (0, 5);  ## graph Date vs Used % for Volume stats file 
	$size_file = $System->get_stat_file(-volume=>$directory, -host=>$host); ##rebuild_sizes_file($host,$directory);    
    }

    if ($size_file !~ /\/$host\//) { return }

    my $output_file = "$size_file.$type." . timestamp;
    $output_file =~s/.*(\/.+)$/$1/;  ## just get name of file 


	
    my $x_label_skip = 6;
    ## add parameter to generate_graph below to hide label in graph if requested ##

    if (-e $size_file) {
	&Graph::generate_graph(-file=>$size_file, -xcol => $xcol, -ycol => $ycol, -ymax=>$ymax, -ysize=>$height, -x_label_skip=>$x_label_skip, -output_file=>"$Configs{URL_temp_dir}/$output_file", -title=>"$host : $directory usage");
	$page .= "<IMG SRC='/dynamic/tmp/$output_file.gif'/>";
    }
    else {
	$page .= "Could not find size file:  $size_file";
    }
    return $page;
}

#
# # TEMPORARY ##
#
# Rebuild appropriate sizes log file from date-logged size.stats files 
#
# Return: name of file logging stats for given volume/directory
############################
sub rebuild_sizes_file {
############################
    my $host      = shift;
    my $size_file = shift;
    my $debug     = shift || 0;
    my $overwrite = shift || 0;
    
    if (!$size_file) { return }

    $size_file =~s/\/$//;         ## truncate last directory separator 
    my $grep = "grep -r '$size_file/ ' $Configs{Sys_monitor_dir}"; # /home/aldente/private/logs/sys_monitor";

    my @hosts;

    if ($host) {
	@hosts = ($host);
    }
    elsif ($size_file =~s/$Configs{Data_home_dir}//) {
	@hosts = ('shared');
    }
    else {
		@hosts = alDente::System::get_all_hosts();
	if ($size_file !~/^\//) { $size_file = '/' . $size_file }   ## add / before directory name for local files (should NOT be necessary if passed in correctly)
    }

    $size_file =~s /\//::/g;    ## compress file paths to single files ##
    $size_file =~s /\/\.\//\//g;

    my @files;
    foreach my $host (@hosts) { 
	my $local_size_file = "$Configs{Sys_monitor_dir}/$host/dirs/$size_file.space";

	if (-e $local_size_file) { 
	    ## already generated ##
	    Message("Found $local_size_file");
	    if (!$overwrite) { push @files, $local_size_file; next; }
	}
	
	my $grep_command = $grep;
	if ($host ne 'shared') { $grep_command .= " | grep $host" }

	my @sizes = split "\n", `$grep_command`;
	Message("Found " . int(@sizes) . " records...(rebuilding $local_size_file from $size_file logs)");
	
	if (int(@sizes) < 1) { Message("$grep_command --> NO DATA"); next; }  ## no data 

	open my $FILE, '>', $local_size_file or Message("Warning: CANNOT OPEN $local_size_file");	
	print $FILE "Date\tSize(K)\n" or Message("Warning: CANNOT WRITE to $local_size_file");
	my $lastdate;
	foreach my $size (@sizes) {
	    ## parse out date and append to build up a new stats file ##
	    if ( $size =~ /2009\/(\d+)\/(\d+)\/size\.stats:(\S+)\s+([\d\.]+)(\w?)\b/ ) {
		my $date = "2009-$1-$2";
		my $size = $4;
		my $units = $5;

		if ($units) { $size = get_number("$size$units") / 1000 }  ## convert to K

		if ($lastdate eq $date) { next }  ## repeat entry for the same date ###
		print $FILE "$date\t$size\n";
		$lastdate = $date;
	    }
	}
	close $FILE;
	`chgrp lims $local_size_file`;
	`chmod 775 $local_size_file`;
	push @files, $local_size_file;
    }
    
    return @files;
}

#############################################
sub show_Volumes {
#############################################
    my $self = shift;
    my $host = shift;

    my $System = $self->{System};
    
    my @hosts;

    if ($host) { @hosts = ($host) }
    else {
	@hosts = $System->get_all_hosts();
	push @hosts, 'shared';
    }
    
    my %view_layer;

    for my $host (@hosts) {
        $view_layer{$host} = $self ->  show_usage_table(-host => $host, -type=>'vols');
    }
    my $page    = create_tree( -tree => \%view_layer, -tab_width => 100, -print => 0 );
    return $page ;
}

###########################################
sub show_Directories {
###########################################
    my $self    = shift;
    my $host    = shift;

    my $System  = $self->{System};

    my @hosts;
    if ($host) { @hosts = ($host) }
    else {
	@hosts = $System->get_all_hosts();
	push @hosts, 'shared';
    }

    my %view_layer;

    for my $host (@hosts) {
        $view_layer{$host} = $self -> show_usage_table(-host => $host, -type=>'dirs');
    }
    
    my $page    = create_tree( -tree => \%view_layer, -tab_width => 100, -print => 0 );
    return $page ;
}


#
# This generates an HTML table view for a list of data files 
#
# It could be separated into context specfic methods, but the differences are limited to a small block of code and can be more easily standardized with this one method 
#
# Return: table printout
##########################
sub show_usage_table {
##########################
    my $self = shift;
    my %args = &filter_input(\@_,-mandatory=>'host');
    my $type  = $args{-type};
    my $host   = $args {-host};
    my $follow  = $args{-follow};

    my $System = $self->{'System'};

    my $table = HTML_Table->new( -width => 400, -border => 1, -title=>"Logged Usage for $host $type");
    my $highlight;

    my @list;

    if ($type eq 'dirs') { 
	@list = $System->get_logged_files_list(-host => $host, -silent => 1, -type => $type ) 
	# @list = keys  %{ $System->get_watched_directories(-scope=>$host, -follow=>$follow) };
    }
    else { @list = $System->get_logged_files_list(-host => $host, -silent => 1, -type => $type ) }

    Message("Found " . int(@list) . " logged $host $type size files");
    my $header;
    foreach my $path ( sort @list) {

	my $stat_file;
	if ($type eq 'dirs') { $stat_file =  $System->get_stat_file(-dir=>$path, -host=>$host) }
	else { $stat_file =  $System->get_stat_file(-volume=>$path, -host=>$host) }

	($header, my $row, my $highlight) = $self->reformat_data(-file=>$stat_file, -path=> $path, %args);
	
	if ($highlight) { 
	    ## keep track of various types of warnings for summary if required ##
	    push @{$self->{highlight}{$type}}, [['Host', @$header], [$host, @$row], $highlight];
	}

	$table->Set_Row( $row, $highlight);
    }
    
    if ($header) { $table->Set_Headers($header) }
    return  $table -> Printout(0) ;
}

#
# Simple wrapper to display any accumulated warning messages of various types 
#
# 
# Return: Table showing warnings generated for given type 
########################
sub show_highlights {
########################
    my $self = shift;
    my $type = shift;

    my $table = HTML_Table->new( -width => 400, -border => 1, -title=>"$type Usage Warnings");
    
    if (defined $self->{highlight}{$type}) {
	foreach my $highlight ( @{ $self->{highlight}{$type} } ) {
	    my ($header, $row, $highlight) = @$highlight;
	    $table->Set_Headers($header);  ## redundant, but should be ok... 
	    $table->Set_Row($row, $highlight);
	}	
	return $table->Printout(0);
    }
    else {
	return "No $type warnings";
    }

}

#
# Reformats data from logged statistics file for viewing in a standard table.
#
# This could be easily adjusted slightly to use 'grep' rather than 'tail' to retrieve data (ie grepping for a certain date or for a certain directory name)
# This may also allow stats to be retrieved from the full du log that is generated daily (ie aside from watched directories)...
# (in this case the row value returned could be an array of arrays (rather than an array of scalars)
#
# Return: headers (ref), row (ref), highlight (row option for HTML_Table)
########################
sub reformat_data {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc           = $self->{'dbc'};
    my  $stat_file = $args{-file};
    my $type = $args{-type};
    my $path = $args{-path};
    my $host = $args{-host};
    my $graphs  = $args{-graph};
    
    my $System = $self->{System};

    my $link;
    my (@csv_header, @csv_data);
    if (-e $stat_file) {
	## retrieve headers and last row of data from log stat files ##
	@csv_header = split /\s+/, get_csv_data($stat_file, -head=>1)->[0];  ## this is preferable to declaring headers below, but files do not have headers at this stage...
	@csv_data   = split /\s+/, get_csv_data($stat_file, -tail=>1)->[0];
    }
    else { @csv_data = ('N/A','?'); $link = '-'; }  ## Message("NOT watching $path ($stat_file)"); }
    
    my ($size, $warning_size, $error_size, $highlight);
    if ($type eq 'vols') {
	## data specific to disk usage statistics log (from df) ##
	@csv_header = ('Date_Recorded','Volume','Size(K)','Used','Available','Use %','Mounted_on');  ## this info should come from the file directly 

	$size = $csv_data[5];
	$size =~s/%//;
#	if ($size =~ /[GMT]$/) { $size = get_number($size) / 1000 }  ## convert to k	
#	if ($size > 1) { $csv_data[5] = number($size * 1024) }  ## convert to readable for table ... 
	
	$warning_size = 85;   ## warning when % usage exceeds this value
	$error_size = 100;    ## error when % usage exceeds this value
    }
    elsif ($type eq 'dirs') {
	## data specific to data directory usage logs (from du ) ##
	unshift @csv_data, $path;
	@csv_header = ('Directory','Date_Recorded', 'Size(K)');     ## this info should come from the file directly 
	
	$size = $csv_data[2]; 
	if ($size =~ /[GMT]$/) { $size = get_number($size) / 1000 }  ## convert to k	
	
	if ($size > 1) { $csv_data[2] = number($size * 1024) }  ## convert to readable for table ... 

	$warning_size = $System -> get_directory_limit(-host=> $host, -dir => $path, -type => 'warning');
	$error_size   = $System -> get_directory_limit (-host=> $host, -dir => $path, -type => 'error');
	
	push @csv_data, $warning_size, $error_size;
	push @csv_header, 'Warning', 'Error';
	
	if ($path =~ /\*/) {
	    push @csv_data, &Link_To( $dbc->config('homelink'), "View Subdirectories", "&cgi_application=alDente::System_App&rm=Display+Sub_Directories&Dir_Name=$path&Host=$host" ) ;
	    push @csv_data, &Link_To( $dbc->config('homelink'), "(with Graphs)", "&cgi_application=alDente::System_App&rm=Display+Sub_Directories&Dir_Name=$path&Host=$host&Graphs=1" ) ;	    
	}
    }
    
    ## highlight rows if monitored sizes exceed indicated warning / error thresholds ##
    if ($error_size =~ /[GMT]$/) { $error_size = get_number($error_size) / 1000 }   
    if ($warning_size =~ /[GMT]$/) { $warning_size = get_number($warning_size) / 1000 }
    

    if ($size > $error_size) { $highlight = 'lightredbw' }
    elsif ($size > $warning_size ) { $highlight = 'mediumyellowbw' }

    my $ymax = $error_size;
    if ($size > $ymax) { $ymax = $size }
    
    if ($graphs) { 
	my $graph = $self -> display_Graph(-directory => $path, -host => $host, -ymax=>$ymax, -type=>$type, -height=>100);
	#if ($graph !~/Could not find/) { 
	push @csv_data, $graph;
	#}
    } 
    
    $link ||= &Link_To( $dbc->config('homelink'), 'Graph', "&cgi_application=alDente::System_App&rm=Display+Directory+History&Dir_Name=$path&Host=$host&Ymax=$ymax&Type=$type", -tip=>"display $type graph") ;  ## link to graph trend
    
    return (['',@csv_header], [$link, @csv_data], $highlight);
}

# Move to File system tools 
#########################
sub get_csv_data {
########################
    my %args = filter_input(\@_, -args=>'path');

    my $path = $args{-path};
    my $tail = $args{-tail};
    my $head = $args{-head};
    my $grep = $args{-grep};

    my $command;
    if ($tail)    {	 $command = "tail $path -n $tail" }
    elsif ($head) { $command = "head $path -n $head" }
    elsif ($grep) { $command = "grep '$grep' $path" } 
    else { $command = "cat $path" }

    my @found = split "\n", try_system_command($command);
    
    if ($found[0] =~ /(No such file or directory|Permission denied)/ ) { 
	Message("Warning: @found"); @found = (); return (); 
    }
    return \@found;
}

1;
