################################################################################
#
# Errors.pm
#
# This module handles errors,
# and provides safer/quicker versiions of standard calls (eg. safe_glob)
#
################################################################################
################################################################################
# $Id: Errors.pm,v 1.2 2003/11/27 19:42:52 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2003/11/27 19:42:52 $
################################################################################
# Ran Guin (2001) - rguin@bcgsc.bc.ca
#
package SDB::Errors;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Errors.pm - This module handles errors, 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles errors, <BR>and provides safer/quicker versiions of standard calls (eg. safe_glob) <BR>Ran Guin (2001) - rguin@bcgsc.bc.ca<BR>

=cut

##############################
# superclasses               #
##############################
use vars qw(%Configs);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################

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

###################
sub safe_glob {
###################
    #
    # a variation on glob() which is safer, more efficient...
    #
    my $search_path = shift || '.';
    my $pattern     = shift || '*';
    my $ext         = shift || '';

    $pattern =~ s/\*/\[\\S\]\*/g;    ### convert na*me to na[\S]*me
    $ext     =~ s/\*/\[\\S\]\*/g;    ### convert na*me to na[\S]*me

    my $PATH1;
    my @files = ();
    if ( opendir( PATH1, $search_path ) ) {
        while ( my $file = readdir(PATH1) ) {
            unless ( $file =~ /$pattern/ ) { next; }
            push( @files, "$search_path/$file" ) if ( $file =~ /$ext$/ );
        }
    }

    return @files;
}

#
# Method used to log deprecated usage of a method.
#
# eg.  at line which is supposed to be deprecated:
#
#      Errors::log_deprecated_usage('old_method_name')
#
# This is used to ensure that there is a record showing when (and the Call_Stack pathway) for any instances where a method that is thought to be deprecated is still used.
#
# Return:  NULL
############################
sub log_deprecated_usage {
############################
    my %args   = RGTools::RGIO::filter_input( \@_, -args => 'title,return' );
    my $title  = $args{-title};
    my $return = $args{ -return };
    my $force  = $args{-force};     ## optionally force logging even when temporarily turned off ##
    my $debug  = $args{-debug};

    if ($title eq 'Connection') {
        if ($return) {
            $return->debug_message("Deprecated use of Connection object");
        }
        else {
            Message("Error: undefined connection object");
            Call_Stack();
        }
    }
    
    if (!$force) {
        # temporary turn off logging to avoid performance hit until conflicts resolved       
        ## Comment out line below to turn logging back on during testing period ##
        return $return;
    }

    #    my $log_file = $Configs{data_log_dir} . '/usage_conflicts.log';
    my $log_file = "/home/aldente/private/logs/usage_conflicts.log";

    my $stack = RGTools::RGIO::Call_Stack( -quiet => 1 );
    my $timestamp = RGTools::RGIO::date_time();

    my $title = "$title\t$timestamp";
    my $log = join "\n\t", @$stack;

    require Digest::MD5;
    my $checksum = Digest::MD5::md5_hex($log);

    my $tracked = `grep $checksum $log_file`;    ## check to see if this usage path has already been tracked ##
    if ( !$tracked ) {
        ## only log it if it is unique instance ##
        if ($debug) { Message("Warning: deprecated use of method noted\n$log\nlogged to $log_file") }
        open my $FILE, '>>', $log_file;
        print $FILE "$title\n\t$checksum\n\t$log\n";
        close $FILE;
    }

    return $return;
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

$Id: Errors.pm,v 1.2 2003/11/27 19:42:52 achan Exp $ (Release: $Name:  $)

=cut

return 1;
