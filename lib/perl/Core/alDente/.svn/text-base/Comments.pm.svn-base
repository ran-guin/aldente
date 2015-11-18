##############################################
#
# $ID$
#
# CVS Revision: $Revision: 1.2 $
#     CVS Date: $Date: 2003/11/27 19:37:58 $
#
##############################################
#
# This package allows comments and suggestions to be passed
# to the administrator as required.
#
#
package alDente::Comments;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Comments.pm - $ID$

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
$ID$<BR>This package allows comments and suggestions to be passed<BR>to the administrator as required.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw(comment_form);
@EXPORT_OK = qw(
    comment_form
);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;
use Benchmark;
use strict;
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw ($homefile);    ### homefile is a link to the current Comment page

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

#######################
sub comment_form {
#######################

    my $cfile = shift;

    print h1("Comment Form");

    print h2("Enter a comment or Request here:");

    my $user    = param('User');
    my $dbase   = param('Database');
    my $project = param('Project');
    my $banner  = param('Banner');

    print start_form( -action => $homefile ), hidden( -name => 'User', -value => $user ), hidden( -name => 'Database', -value => $dbase ), hidden( -name => 'Project', -value => $project ), hidden( -name => 'Banner', -value => $banner ),
        hidden( -name => 'Bugs', -value => 1 ), textarea( -name => 'Comment', -rows => 5, -cols => 60 ), "<BR>", "Your Initials: ", textfield( -name => 'Initials', -size => 5 ), " ", submit( -name => 'Submit Comment' ), end_form;

    if ( param('Submit Comment') ) {
        open( CFILE, ">>$cfile" ) or print "Error opening $cfile";
        my $comment = param('Comment');
        $comment =~ s/\n/ /g;
        $comment =~ s/\t/ /g;

        my $initials = param('Initials');
        my $reply    = "";
        my $today    = &today();

        if ( $initials eq 'ADM' ) {    ### administrator
            $reply   = $comment;
            $comment = "";
        }
        print CFILE "$today\t$comment\t$initials\t$reply\n";
    }
    close(CFILE);

    &list_comments($cfile);
    return 1;
}

########################
sub list_comments {
########################

    my $cfile = shift;

    my $Comments = HTML_Table->new();
    my @headers = ( 'Date', 'Comments', 'Initials', 'Responses' );
    $Comments->Set_Headers( \@headers );

    open( CFILE, "$cfile" ) or print "Error opening $cfile";
    while (<CFILE>) {
        my $line = $_;

        my @row = split '\t', $line;
        $Comments->Set_Row( \@row );
    }
    close(CFILE);
    $Comments->Printout();
    return 1;
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

$Id: Comments.pm,v 1.2 2003/11/27 19:37:58 achan Exp $ (Release: $Name:  $)

=cut

return 1;
