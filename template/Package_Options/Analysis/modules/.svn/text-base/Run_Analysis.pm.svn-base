###################################################################################################################################
# Template::Run_Analysis.pm
#
#
#
#
###################################################################################################################################
package Template::Run_Analysis;

use strict;
use CGI qw(:standard);
use FindBin;
use Data::Dumper;
use XML::Simple;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use RGTools::RGIO;
use RGTools::Conversion;
use SDB::CustomSettings;
use SDB::DB_Object;
use SDB::DBIO;
use SDB::HTML;
use alDente::Run;
use alDente::Tools;
use Template::Run;
use vars qw($user_id $homelink %Configs);



#######################
#Constructor          #
#######################
sub new {
#######################
    my $this = shift;

    my %args = @_;

    ### Initialization
    my $self = {};
    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{dbc}            = $args{-dbc};
    $self->{testing}        = $args{-testing};
    
	$self->{image_analysis_type} = '';
    $self->{data_directory} = '';
    $self->{version}        = '';

    $self->{log} = [];
    
    return $self;
}

1;
