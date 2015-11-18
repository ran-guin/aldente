################################################################################
# Report.pm
#
# This modules provides general reporting functions
#
################################################################################
################################################################################
# $Id: Report.pm,v 1.4 2004/11/30 01:43:50 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.4 $
#     CVS Date: $Date: 2004/11/30 01:43:50 $
################################################################################
package SDB::Report;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Report.pm - This modules provides general reporting functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides general reporting functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(Report Seq_Notes);

use vars qw(%Configs);
##############################
# standard_modules_ref       #
##############################

use CGI qw(standard);
use DBI;
use strict;
use RGTools::RGIO;
use SDB::HTML;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;

##############################
# global_vars                #
##############################
use vars qw($Data_log_directory $style);    ### style indicates 'html' or 'text'
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

########################
sub Report {
    ######################
    #
    # provide feedback on success of updating job.
    #
    #
    my $message       = shift;
    my $update_report = shift;

    my $nowtime = RGTools::RGIO::date_time();
    $nowtime =~ /(\d\d\d\d-\d\d-\d\d)/;
    my $date = $1;

    $update_report ||= "$Data_log_directory/Reports/SDB_Report_$date.log";

    my $REPORT;
    open( REPORT, ">>$update_report" ) or die "Error opening $update_report";
    print REPORT "$nowtime: $0\n********** **********\n";
    print REPORT "$message\n";
    close REPORT;

    print try_system_command("chmod 777 $update_report");    ### make world writable so anyone can append...

    return 1;
}

#####################
sub Seq_Notes {
    ###################
    #
    # Generate Log Notes and write to Error log file
    #

    my $preface     = shift;                                 # Preface message with this text
    my $message     = shift;                                 # message content
    my $local_style = shift;                                 # defaults to $style (global variable) or 'text'
    my $local_file  = shift;                                 # file to write to (defaults to $Data_log_directory/Notes/SDB_Note_(date)
    my $rewrite     = shift;                                 # rewrite log file (default = append)

    ( my $nowdate, my $nowtime ) = split / /, &RGTools::RGIO::date_time();
    $local_style ||= $style;
    $local_style ||= "text";

    ### set local_file to '0' if no file...
    unless ( defined $local_file ) { $local_file = "$Data_log_directory/Notes/SDB_Note_$nowdate"; }

    #  &Report("$preface: $message");   ### track all reports....

    ## if in html mode, write to log file

    my $linefeed;
    if ( $local_style =~ /html/i ) {
        $linefeed = "<BR>";
    }
    else { $linefeed = "\n"; }

    if ($local_file) {
        my $ERROR;
        if ($rewrite) {
            open ERROR, ">$local_file" or print "\nCannot open $local_file.\n";
        }
        else {
            open ERROR, ">>$local_file" or print "\nCannot open $local_file.\n";
        }
        print ERROR "$nowtime\n$preface\n$message\n";
        close ERROR;
        print "$nowtime\n$preface\n$message\n";
        print try_system_command("chmod 777 $local_file");    ### make world writable
    }
## or write to STDOUT
    else {
        print "$preface\n$message\n";
    }

    return 1;
}

#
# Load Report object(s) and generate using interface parameters
# Returns file(s) generated in last minute matching extract_file specification
#
# Return: File(s) generated (as an array)
#####################
sub load_DB_Report {
#####################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $Report    = $args{ -Report };                   ## optional Process Monitor report
    my $master    = $args{-master};
    my $slave     = $args{-slave};
    my $report_id = $args{-report_id};
    my $timestamp = $args{-timestamp} || timestamp();
    my $extension = $args{-extension} || '*';

    my $dbase = $args{-dbase} || $Configs{PRODUCTION_DATABASE};

    my %reports = $dbc->Table_retrieve(
        'Report',
        [ 'Report_ID', 'Parameter_String', 'Target', 'Extract_File', 'Report_Frequency', 'Report_Sent', "CASE WHEN DATE(AddDate(Report_Sent, INTERVAL Report_Frequency DAY)) > CURDATE() THEN 'NO' ELSE 'YES' END as Send" ],
        "WHERE Report_ID=$report_id"
    );

    my $temp_dir   = "dynamic/tmp";
    my $report_dir = "dynamic/share";

    my $full_temp_dir   = $Configs{Web_home_dir} . "/$temp_dir";
    my $full_report_dir = $Configs{$Web_home_dir} . "/$report_dir";

    my $index   = 0;
    my $string  = $reports{Parameter_String}[$index];
    my $extract = $reports{Extract_File}[$index];
    my $id      = $reports{Report_ID}[$index];
    $index++;

    ## replace standard tags in parameters string ##

    while ( $string =~ /<(\d*\s?)(HOUR|DAY|WEEK|MONTH|YEAR)S?>/i ) {
        my $replace = "$1$2";
        my $offset  = $1 || 1;
        my $unit    = $2;
        if ( $unit =~ /(today|now)/ ) { $offset = 0 }
        my $date = date_time("-$offset$unit");
        unless ( $unit =~ /(now|hour)/ ) { $date = substr( $date, 0, 10 ) }
        $string =~ s /<$replace[S]?>/$date/ig;
    }

    my $command = "/opt/alDente/versions/$Configs{version_name}/cgi-bin/barcode.pl Auto_Report=1 ";
    $command .= $string;
    $command .= " Timestamp=$timestamp";

    print "Executing: >$command\n";

    my $output = try_system_command($command);

    sleep(2);

    my @all_files;
    my @exts = Cast_List( -list => $extension, -to => 'array' );
    foreach my $ext (@exts) {
        my $name_pattern   = "*$extract" . '_' . "$timestamp*.$ext";
        my $search_command = "find '$Configs{Web_home_dir}/$temp_dir/' -name $name_pattern -ctime 0";    # add * after timestamp since a random number has been attached to the timestamp when the file is generated
        my @files = split "\n", `$search_command`;

        if ( !@files && -e "$Configs{Web_home_dir}/$temp_dir/$extract.cached.$ext" ) {
            $search_command =~ s/$timestamp/cached/;
            @files = split "\n", `$search_command`;
            if (@files) { Message("Using cached file...") }
        }
        if (@files) { push @all_files, @files; }
        else        { print "No files found ($search_command)" }

    }

    return @all_files;
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

$Id: Report.pm,v 1.4 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
