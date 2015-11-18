###################################################################################################################################
# SVN::SVN_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::SVN_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use SDB::SVN;
use SDB::Installation;
use vars qw(%Configs);

my $tag_dir   = '/home/aldente/private/logs/tag_validation';
my $docs_link = $Configs{URL_domain} . '/' . $Configs{URL_dir_name} . '/dynamic/logs/tag_validation/';

######################
# Constructor
##############
sub new {
##############
    my $this  = shift;
    my %args  = filter_input( \@_ );
    my $model = $args{-model};
    my $dbc   = $args{-dbc};

    my $self = {};
    $self->{'dbc'} = $dbc;
    my ($class) = ref $this || $this;
    bless $self, $class;

    return $self;
}

##################
sub view_Tags {
##################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $version = $args{-version};

    if ( !$version ) {
        $version = $dbc->config('CODE_VERSION');
    }
    my $output = '<h2>Tags Available</h2>';

    my @tags = split "\n", `ls $tag_dir/$version/`;
    my @all_versions = sort ( split "\n", `find $tag_dir/ -maxdepth 1 -type d -printf "%P\n"` );
    @all_versions = SDB::Installation::version_sort( \@all_versions );

    my $index = 0;
    my ( $previous_version, $next_version );
    foreach my $ver (@all_versions) {
        if ( $ver eq $version ) {
            if ($index) {
                $previous_version = Link_To( $dbc->config('homelink'), "Previous Version: $all_versions[$index-1]; ", "&cgi_application=SDB::SVN_App&rm=Show Tags&Version=$all_versions[$index-1]" );
            }
            if ( $#all_versions > $index ) {
                $next_version = Link_To( $dbc->config('homelink'), "Next Version: $all_versions[$index+1]; ", "&cgi_application=SDB::SVN_App&rm=Show Tags&Version=$all_versions[$index+1]" );

                #	last;
            }
        }
        $index++;
    }

    if ( !$previous_version ) {
        $previous_version = Link_To( $dbc->config('homelink'), "Previous Version: $all_versions[$index-1]; ", "&cgi_application=SDB::SVN_App&rm=Show Tags&Version=$all_versions[$index-1]" );
    }

    my $Summary = new HTML_Table( -title => "Valid Tags Available for version $version" );
    $Summary->Set_Headers( [ 'SVN Revision', 'Changes', 'Change Document', 'Validation_Tests', 'Status', 'Timestamp', 'Tickets', 'Training' ] );

    my ( $revision, $last_revision ) = ( 0, 0 );
    foreach my $tag (@tags) {
        if ( $tag =~ /rev\_(\d+)/ ) { $last_revision = $revision; $revision = $1; }
        else                        {next}

        #my $changes_doc = get_tag_doc(-version=>$version, -revision=>$revision, -link=>'Change Document', -alt=>'no change document available', -pattern=>'release_changes*');
        my $changes_doc;
        if   ( SDB::Installation::greater_version( $version, '3.3' ) eq '3.3' ) { $changes_doc = Link_To( '', 'Change Document', "http://www.bcgsc.ca/wiki/display/lims/Hotfix+Patch+$version" ); }
        else                                                                    { $changes_doc = Link_To( '', 'Change Document', "http://www.bcgsc.ca/wiki/display/lims/Upgrade+Release+$version" ); }
        my $tickets_doc      = get_tag_doc( -version => $version, -revision => $revision, -link => 'Ticket Summary',   -alt => 'no ticket summary avail',   -pattern => 'changes*' );
        my $validation_tests = get_tag_doc( -version => $version, -revision => $revision, -link => 'Validation Tests', -alt => 'no validation tests avail', -pattern => 'Validation*' );

        my $tickets_list = get_tickets_list( -version => $version, -from => $last_revision, -to => $revision, -link => "JIRA Tickets ($last_revision -> $revision)", -alt => 'no ticket list avail' );
        my ( $status, $timestamp ) = get_tag_status( -version => $version, -revision => $revision );
        my $training_status = get_training_status( -version => $version, -revision => $revision );

        $Summary->Set_Row( [ $revision, $tickets_doc, $changes_doc, $validation_tests, $status, $timestamp, $tickets_list, $training_status ] );
    }

    $output .= $previous_version;
    $output .= $Summary->Printout(0);
    $output .= $next_version;

    return $output;
}

#
# Retrieve standard tag_revision document
#
# Return: filename or link to file
#########################
sub get_tag_doc {
#########################
    my %args     = filter_input( \@_, -args => 'revision' );
    my $version  = $args{-version};
    my $revision = $args{-revision};
    my $link     = $args{ -link };
    my $pattern  = $args{-pattern};
    my $alt      = $args{-alt};

    my $search = "ls $tag_dir/$version/rev_$revision/$pattern";
    my ($doc) = split "\n", `$search`;

    if ( !$doc ) { return Show_Tool_Tip( $alt, "nothing found from: '$search'" ); }

    if ($link) {
        $doc =~ s/^(.*)\/tag_validation\///;    ## truncate path of original file...
        return Link_To( $docs_link, $link, $doc );
    }
    else {
        return $doc;
    }
}

##########################
sub get_tickets_list {
##########################
    my %args     = filter_input( \@_, -args => 'revision' );
    my $revision = $args{-revision};
    my $version  = $args{-version};
    my $from     = $args{-from};
    my $to       = $args{-to};
    my $link     = $args{ -link };
    my $alt      = $args{-alt};

    my $installed_tag_dir = $Configs{web_dir} . "/../install/tags/$version";

    my @tickets = split "\n", `ls $installed_tag_dir`;

    my $tickets_doc;
    foreach my $ticket (@tickets) {
        chomp $ticket;

        my @files = split "\n", `ls $installed_tag_dir/$ticket/`;
        my $relevant_changes;
        foreach my $file (@files) {
            my ( $timestamp, $sub_revision ) = ( 0, 0 );
            if ( $file =~ /(\d+)__rev_(\d+)/ ) {
                $timestamp    = $1;
                $sub_revision = $2;
            }
            else {next}
            if ( $sub_revision < $from || $sub_revision > $to ) { next; }

            my @file_changes = split "\n", `cat $installed_tag_dir/$ticket/$file`;
            my $changes = $sub_revision . '<UL>';
            foreach my $file_change (@file_changes) {
                $changes .= '<LI>' . $file_change;
            }
            $changes          .= '</UL>';
            $relevant_changes .= '<LI>' . $changes;
        }

        if ($relevant_changes) { $tickets_doc .= "<B>$ticket<B><UL>$relevant_changes</UL><BR>" }
    }

    if ( !$tickets_doc ) { return $alt }

    if ($link) {
        return create_tree( -tree => { $link => $tickets_doc } );
    }
    else {
        return $tickets_doc;
    }
}

########################
sub get_tag_status {
########################
    my %args     = filter_input( \@_ );
    my $version  = $args{-version};
    my $revision = $args{-revision};

    my @files = split "\n", `ls $tag_dir/$version/rev_$revision/`;
    my ( $status, $timestamp ) = ( 'undef', 0 );

    if ( grep /\.start/,  @files ) { $status = 'initiated' }
    if ( grep /\.failed/, @files ) { $status = 'failed' }
    if ( grep /\.tag/,    @files ) { $status = 'confirmed' }

    my $max_datetime = 0;
    foreach my $file (@files) {
        if ( $file =~ /\b(\d+)\_\_rev\_$revision\b/ ) {
            if ( $1 > $max_datetime ) {
                $max_datetime = $1;
                $timestamp = RGTools::Conversion::convert_date( $1, 'Mon-DD / YYYY (HOUR:MINUTE)' );
            }
        }
    }
    return ( $status, $timestamp );
}

# show logs from training sessions which should be tied to each tagged version
#############################
sub get_training_status {
#############################
    my %args     = filter_input( \@_ );
    my $version  = $args{-version};
    my $revision = $args{-revision};

    my $training = 'no training sessions logged';

    return $training;
}

1;
