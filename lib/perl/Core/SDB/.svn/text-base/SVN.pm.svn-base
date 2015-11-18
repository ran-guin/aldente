############
# SVN.pm #
############
# This module facilitates some simple SVN based functionality
###################
package SDB::SVN;
use strict;
use warnings;

use Plugins::JIRA::Jira;

use RGTools::RGIO;    ## general tools module required
use RGTools::Conversion;

#use alDente::Validation;
use SDB::CustomSettings;
use SDB::DBIO;

#########
sub new {
#########
    my $this = shift;
    my $class = ref($this) || $this;

    my %args   = @_;

    my $self = {};
    bless $self, $class;

    return $self;
}

####################################
sub get_revision {
####################################
    my $self = shift;
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $command = "svn info $file";

    my @response = split /\n/, try_system_command($command);

    for my $line (@response) {
        if ( $line =~ /Last Changed Rev\:\s+(.+)/ ) {
            return $1;
        }
    }
    return;
}

####################################
sub get_repository_root {
####################################
    my $self = shift;
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $command = "svn info $file";

    my @response = split /\n/, try_system_command($command);
    for my $line (@response) {
        if ( $line =~ /Repository Root\:\s+(.+)/ ) {
            return $1;
        }
    }
    return;
}

# Simply test to ensure file compiles #
#####################
sub compile_test {
#####################
    my $self = shift;
    my $file  = shift;
    my $debug = shift;

    my $ok = try_system_command("/usr/local/bin/perl -c $file");
    if ($debug) { print $ok; }

    if ( $ok =~ /syntax OK/ ) { return 1 }
    else {
        unless ( $FindBin::RealBin =~ /SDB/ ) {
            Message("'perl -c $file' can not be compiled");
        }
    }

    return 0;
}

#######################
sub critique_code {
#######################
    my $self = shift;
    my %args        = filter_input( \@_, -args => 'files' );
    my $files       = $args{-files};
    my $severity    = $args{-severity} || 'stern';
    my $warning_msg = $args{-warning_message};

    my @file_list = Cast_List( -list => $files, -to => 'array' );
    Message("Critiquing perl files....");
    foreach my $module (@file_list) {
        my $critic   = try_system_command("critic.pl -file $module -severity $severity");
        my $warnings = try_system_command("get_warnings.pl -m $module -l");                 ## get local warnings
        Message("=== Critic ===\n");
        Message($critic);

        my $warning_count = 1;
        if ( $warnings =~ /Total Number of Warnings: (\d+)/ ) { $warning_count = $1 }

        Message("=== $warning_count Warnings ===");

        if ($warning_count) {
            Message($warnings);
            if ($warning_msg) { Message($warning_msg) }
        }
        Message("**********************************");
    }
    return;
}

####################################
sub get_svn_URL {
####################################
    my $self = shift;
    my %args     = filter_input( \@_ );
    my $file     = $args{-file};
    my $command  = "svn info $file";
    my @response = split "\n", try_system_command($command);

    for my $line (@response) {
        if ( $line =~ /URL\:\s+(.+)/ ) {
            return $1;
        }
    }
    return;
}

####################################
sub get_file_from_svn {
####################################
    my $self = shift;
    my %args     = filter_input( \@_ );
    my $file     = $args{-file};
    my $revision = $args{-revision};
    my $debug    = $args{-debug};

    my $url = $self->get_svn_URL( -file => $file );
    my $command = " svn cat $url ";
    $command .= " -r $revision" if $revision;

    Message $command if $debug;
    my $response = try_system_command($command);

    return $response;

}

####################################
sub update {
####################################
    my $self = shift;
    my %args     = filter_input( \@_ );
    my $file     = $args{-file};
    my $revision = $args{-revision};
    my $test     = $args{-test};
    my $quiet    = $args{-quiet};
    my $debug    = $args{-debug};
    
    my $command;
    $command = "svn up $file" if $file;
    $command .= " -r $revision" if $revision;
    
    Message $command unless $quiet;

    if ( !$test ) {
        my $response = try_system_command($command);
        if ($response) { Message $response unless $quiet; }
    }

    return;

}

####################################
sub add {
####################################
    my $self = shift;
    my %args  = filter_input( \@_ );
    my $file  = $args{-file};
    my $test  = $args{-test};
    my $debug = $args{-debug} || $test;

    unless ($file) {
        return;
    }

    my $command = "svn add $file";
    if ($debug) { Message $command }

    if ( !$test ) {
        my $response = try_system_command($command);
        if ($response) { Message $response }
    }

    return 1;

}

####################################
sub checkout {
####################################
    my $self = shift;
    my %args  = filter_input( \@_, -mandatory => 'url,path' );
    my $url   = $args{-url};
    my $path  = $args{-path};
    my $test  = $args{-test};
    my $debug = $args{-debug} || $test;

    Message "Please be patient, this takes a minute or two";
    my $command = "svn co $url $path";
    Message $command if $debug;

    if ( !$test ) {
        my $response = try_system_command($command);
        if ($response) { Message $response }
    }

    return;
}

####################################
sub commit {
####################################
    my $self = shift;
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $test    = $args{-test};
    my $debug   = $args{-debug} || $test;
    my $message = $args{-message} || "GENERIC MESSAGE";
    unless ($file) {
        return;
    }

    my $command = "svn commit -m \"$message\" $file";
    Message $command if $debug;

    if ($test) { return 'Transmitting' }
    else {
        my $response = try_system_command($command);
        Message $response if $response;
        return $response;
    }

}
####################################
# Check if specified files or directories
# are (svn) out of date
# Return 1 if out of date, 0 if up to date
####################################
sub is_out_of_date {
####################################
    my $self = shift;
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};
    my $file  = $args{-file};

    my $command = "svn status -u $file";
    Message $command if $debug;

    my $response = try_system_command($command);
    Message $response if $debug;

    if   ( $response =~ /\*/ ) { return 1; }
    else                       { return 0; }
}

#################
sub svn_diff {
#################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'file' );
    my $dir      = $args{-dir}  || 'lib/perl';
    my $filename = $args{-file} || $dir;
    my $option = $args{-option};
    my $debug  = $args{-debug};
    my $output;

    my $svn_command = "svn diff -x-w -r HEAD $filename | grep '(working copy)' | grep -v \" grep '(working copy)'\"";    ## get all changed files (but ignore retrieval of this line)  ##
    my @all_diffs = split "\n", try_system_command($svn_command);

    if ( @all_diffs && $all_diffs[0] =~ /\bnot found\b/ ) { Message("path not found..."); return; }

    Message("Checking $filename");
    $output .= join "\n", @all_diffs;
    $output .= "\n";
    $output .= "*" x 128;
    $output .= "\n";

    my ( @adds, @updates, @changes, @details );
    foreach my $file (@all_diffs) {
        Message("*** check $file ***");
        if ( $file =~ /[\+\s]+([\S]+)/ ) { $file = $1 }
        else                             { Message("??? $file ???") }
        Message("*** now $file ***");
        my $status = try_system_command("svn status $file");

        if ( $status =~ /^\?/ ) {
            push @adds, $file;
        }
        elsif ($status) {
            my @diff = split "\n", try_system_command("svn diff -x-w $file");

            my @added   = grep {/^\+\s*\S/} @diff;    ## skip blank lines....
            my @removed = grep {/^\-\s*\S/} @diff;

            my @added_comments   = grep {/^\+\s*\#/} @added;
            my @removed_comments = grep {/^\-\s*\#/} @removed;

            ## generate counts for added & removed lines (as well as comment line counts) ##
            my $added_lines   = int(@added) - int(@added_comments) - 1;        ## exclude +++ line
            my $removed_lines = int(@removed) - int(@removed_comments) - 1;    ## exclude --- line
            my $more_comments = int(@added_comments);
            my $less_comments = int(@removed_comments);

            push @changes, "* $file:\nAdded $added_lines code lines + $more_comments comment lines;\nRemoved $removed_lines code lines + $less_comments comment lines;\n";
            push @details, @diff;
        }
        else { push @updates, $file }
    }

    $debug ||= ( int(@all_diffs) == 1 );                                       ## turn debug flag on if only one file

    if (@adds) {
        $output .= "\n*** SVN ADD ***\n";
        $output .= join "\n", @adds;
        $output .= "\n*******************\n";
    }
    if (@updates) {
        $output .= "\n*** SVN UPDATE ***\n";
        $output .= join "\n", @updates;
        $output .= "\n*******************\n";
    }
    if (@changes) {
        $output .= "\n*** SVN CHANGES ***\n";
        $output .= join "\n", @changes;
        if ($debug) { $output .= "\n"; $output .= join "\n", @details; }
        $output .= "\n*******************\n";
    }

    return $output;
}

####################
sub review_change {
####################
    my $self = shift;
    my %args    = filter_input( \@_, -mandatory => 'ticket,file' );
    my $ticket  = $args{-ticket};
    my $file    = $args{-file};
    my $comment = $args{-comment};

    $comment = $comment . " " . $file;

    my $jira_user     = 'limsproxy';
    my $jira_password = 'noyoudont';             ## <CONSTRUCTION> remove hardcoding
    my $jira_wsdl     = $Configs{'jira_wsdl'};

    my $jira_cr = Jira->new( -user => $jira_user, -password => $jira_password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
    $jira_cr->login();
    my $cr_id            = $jira_cr->get_crucible_review_id( -ticket_number => $ticket );
    my $repository       = 'GSC';
    my $changeset_id     = $self->get_revision( -file => $file );
    my $rev_from_fisheye = $jira_cr->get_rev_number_from_fisheye( -file => $file );

    print "\n";
    while ( $changeset_id != $rev_from_fisheye ) {
        $rev_from_fisheye = $jira_cr->get_rev_number_from_fisheye( -file => $file );
        print ".";
    }
    print "\n";

    if ($cr_id) {
        $jira_cr->addchangeset_crucible_review( -cr_id => $cr_id, -repository => $repository, -changeset_id => $changeset_id, -comment => $comment );

    }
    else {
        my $ticket_info_cr = $jira_cr->get_issue( -issue_id => $ticket );
        my $desc_cr        = $ticket_info_cr->{description};
        my $name           = $ticket_info_cr->{summary};                    #name of the crucible review is name of the ticket
        my $project_key    = 'CR';
        $jira_cr->create_crucible_review( -name => $name, -jira_key => $ticket, -project_key => $project_key, -description => $desc_cr, -changeset_id => $changeset_id, -repository => $repository, -comment => $comment );
    }

}

1;
