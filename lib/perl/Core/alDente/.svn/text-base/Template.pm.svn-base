###################################################################################################################################
# alDente::Template.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Template;
use base SDB::Template;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $quiet = $args{-quiet};

    my $self = {};    ## if object is NOT a DB_Object ... otherwise...
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc}   = $dbc;
    $self->{quiet} = $quiet;

    $self->{file};    ## full filename of imported file

    my $template_path = alDente::Tools::get_directory( -structure => 'HOST/DATABASE', -root => $Configs{upload_template_dir}, -dbc => $dbc );
    $self->{default_path} = $template_path;

    return $self;
}

###############
sub find_file {
###############
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $ext     = $args{-ext};
    my $custom  = $args{-custom};
    my $project = $args{-project};
    my $dbc     = $self->{dbc};

    my $template_path;
    if ( $custom || $project ) {
        $template_path = $self->get_Template_Path( -project_id => $project );
    }

    if ( $file !~ /\.$ext$/ ) { $file .= '.' . $ext }
    $file = "$template_path/$file";
    return $file;
}

1;
