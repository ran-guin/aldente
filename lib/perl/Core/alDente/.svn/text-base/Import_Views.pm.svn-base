###################################################################################################################################
# Sequencing::Import_View.pm
#
#
#
#
###################################################################################################################################
package alDente::Import_Views;
use base SDB::Import_Views;

use strict;
use CGI qw(:standard);
use alDente::Import;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Import;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
## alDente modules
use vars qw( $Connection %Configs );

######################################
sub display_Import_Document_box {
######################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = HTML_Table->new();
    my $text  = "Please select either the library <B>OR</B> the project.";
    ## prompt for delimiter options ##
    my @deltrs = ( 'Tab', 'Comma' );

    $table->Set_Row( [ "Delimited input file:", filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ) ] );
    $table->Set_Row( [ submit( -name => 'rm', -label => 'Upload File to Publish', -class => 'Std' ) ] );

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'uploader' ) 
        . $text
        . &SDB::HTML::query_form( -dbc => $dbc, -fields => [ 'Library.FK_Project__ID', 'Plate.FK_Library__Name' ], -db_action => 'reference search' )
        . hidden( -name => 'cgi_application', -value => 'alDente::Import_App' )
        . $table->Printout(0)
        . end_form();
    return $page;
}

#####################
sub upload_link_page {
#####################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->{dbc};
    my $table     = HTML_Table->new();
    my $help_text = "Make sure your file is visible to the system. Then write full path and file name in the box";
    ## prompt for delimiter options ##
    $table->Set_Row( [ textfield( -name => 'link_path', -size => 20, -maxlength => 120 ) ] );
    $table->Set_Row( [ submit( -name => 'rm', -label => 'Upload Link to Publish', -class => 'Std' ) ] );

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'uploader' )
        . &SDB::HTML::query_form( -dbc => $dbc, -fields => [ 'Library.FK_Project__ID', 'Plate.FK_Library__Name' ], -action => 'reference search' )
        . $help_text
        . vspace()
        . hidden( -name => 'cgi_application', -value => 'alDente::Import_App' )
        . $table->Printout(0)
        . end_form();
    return $page;
}

############################################################
sub display_Published_Documents {
############################################################
    my %args    = filter_input( \@_, -args => 'files' );
    my $files   = $args{-files};
    my $dbc     = $args{-dbc};
    my $public  = $args{-public};
    my $prj_dir = $Configs{project_dir};
    my @files   = @$files if $files;

    my $table = HTML_Table->new( -width => 400, -border => 1 );
    $table->Set_Headers( [ 'Project', 'Library', 'Files' ] );
    $table->Set_Title("Published Documents");

    for my $file (@files) {
        my $project;
        my $library;
        my $file_name;
        if ( $file =~ /$prj_dir\/(.+)\/(.+)\/published\/(.+)$/ ) {
            my ($proj_id) = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name = '$1'" );
            if ($public) {
                $project = $1;
                $library = $2;
            }
            else {
                $project = alDente::Tools::alDente_ref(
                    -dbc   => $dbc,
                    -table => 'Project',
                    -id    => $proj_id
                );
                $library = alDente::Tools::alDente_ref(
                    -dbc   => $dbc,
                    -table => 'Library',
                    -name  => $2
                );
            }
            $file_name = $3;
        }
        elsif ( $file =~ /$prj_dir\/(.+)\/published\/(.+)$/ ) {
            my ($proj_id) = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Name = '$1'" );
            if ($public) {
                $project = $1;
            }
            else {
                $project = alDente::Tools::alDente_ref(
                    -dbc   => $dbc,
                    -table => 'Project',
                    -id    => $proj_id
                );
            }
            $library   = '-';
            $file_name = $2;
        }

        my $link .= alDente::Import::get_File_Link( -file => $file, -title => $file_name );

        $table->Set_Row( [ $project, $library, $link ] );
    }

    return $table->Printout(0);
}

#
1;
