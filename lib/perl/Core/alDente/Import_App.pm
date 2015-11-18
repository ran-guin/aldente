###################################################################################################################################
# Sequencing::Statistics.pm
#
#
#
#
###################################################################################################################################
package alDente::Import_App;
use base SDB::Import_App;
use strict;


## RG Tools
use RGTools::RGIO;
## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Import;
use alDente::Import_Views;
use vars qw( %Configs);

#####################
sub setup {
#####################
    my $self = shift;
    $self->start_mode('entry_page');
    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'entry_page'                => 'entry_page',
        'Upload File to Publish'    => 'upload_file',
        'Upload Link to Publish'    => 'upload_Link',
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');
    $self->param(
        'View'  => alDente::Import_Views -> new( -dbc => $dbc ),
        'Threshold'  => '100000000' #### IN BYTES
    );
    
    return $self;
}

#####################
sub entry_page {
#####################
    my $self = shift;
    my $dbc     = $self-> param('dbc');
    my $view    = $self -> param('View');
    my $output;
    return $output;
}   



#####################
sub upload_file {
#####################
    my $self        = shift;
    my $dbc         = $self -> param('dbc');
    my $view        = $self -> param('View');
    my $file_h      = $q    -> param('input_file_name') ;

    my $project     = get_Table_Param(-dbc=>$dbc, -field=>'FK_Project__ID', -convert_fk=>1); 
    my $library     = get_Table_Param(-dbc=>$dbc, -field=>'FK_Library__Name', -convert_fk=>1);

    my $THRESHOLD   = $self -> param('Threshold');
      
    my $path = _get_Published_path (-library => $library , -project => $project , -dbc => $dbc) ;
    unless ($path) {      Message "Library and project do not match";  return; }
    
    my $under_treshold = SDB::Import::check_size_validity(-threshold => $THRESHOLD, -file =>  $file_h);
    
    if ($under_treshold){   SDB::Import::copy_file_to_system( -file => $file_h, -path => $path, -mode => 0774)  }
    else {
        Message " The Size of the file is too large to be uploaded. You need to copy a link of it.";
        return $view -> upload_link_page ();
    }
    
    
    return ;
}

#####################
sub upload_Link {
#####################
    my $self        = shift;
    my $dbc         = $self -> param('dbc');
    my $view        = $self -> param('View');
    my $file        = $q    -> param('link_path');
    
    my $project     = get_Table_Param(-dbc=>$dbc, -field=>'FK_Project__ID', -convert_fk=>1); 
    my $library     = get_Table_Param(-dbc=> $dbc, -field=>'FK_Library__Name', -convert_fk=>1);
    
    my $path = _get_Published_path (-library => $library , -project => $project , -dbc => $dbc) ;
    unless ($path) {      
        Message "Library and project do not match";  
        return $view -> upload_link_page ();
    }

    my $target_name = SDB::Import::get_Target_file_name (-file => $file, -path => $path );
    unless ($target_name){
         return $view -> upload_link_page ();
    }
    
    my $link = SDB::Import::create_link (-target => $target_name , -source => $file);
    unless ($link){
         return $view -> upload_link_page ();
    }
    
    return;
}



####################################################################################
#   Internal functions
####################################################################################


#############################
sub _get_Published_path {
#############################
    my %args    = &filter_input(\@_);
    my $dbc     = $args {-dbc};
    my $library = $args {-library};
    my $project = $args {-project};

    if ($library && $project) {
        my $lib_project = $dbc -> Table_find ('Project,Library','Project_Name',"WHERE Library_Name = '$library'");
        if ($lib_project eq $project){
            return $Configs{project_dir}.'/'.$project .'/'.$library.'/published';
        }
        else {
            Message "Library $library does not belong to project $project.  Please select only library or project.";
            return ;
        }
    }
    elsif ($library) {
        my ($lib_project) = $dbc -> Table_find ('Project,Library','Project_Name',"WHERE FK_Project__ID=Project_ID AND Library_Name = '$library'");
        return $Configs{project_dir}.'/'.$lib_project .'/'.$library.'/published';
    }
    elsif ($project) {
        return $Configs{project_dir}.'/'.$project .'/published';
    }
    else {
        Message "No library or project provided.";
        return;
    }    
    
}

1;
