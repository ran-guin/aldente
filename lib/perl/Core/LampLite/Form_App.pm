##################
# Form_App.pm #
##################
#
#
package LampLite::Form_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################

## Standard modules required ##
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

use LampLite::Form_Views;
use LampLite::Form;

##############################
# global_vars                #
##############################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
			'Edit Records'  => 'edit_Records',
            'Save Edits' => 'save_Edits',
            'Save Field Info' => 'save_Edits',
        }
        
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}


####################
sub edit_Records {
####################
	my $self = shift;
	my $q = $self->query();
	my $id   = $q->param('ID');
	my $class = $q->param('Class');
	my $preset = $q->param('Preset');
	my $hidden = $q->param('Hidden');
	
	my %Set;
	foreach my $type ('Preset', 'Hidden', 'Default') {
	    if ($q->param($type)) {
	        my @fields = Cast_List(-list=>$q->param($type), -to=>'array');
	        foreach my $f (@fields) {
	            my $val = $q->param($f);
	            $Set{$type}{$f} = $val;
            }
	    }
	}
	
	my @ids = Cast_List(-list=>$id, -to=>'array');
	return $self->View->edit_Records(-ids=>$id, -table=>$class, -preset=>$Set{Preset}, -hidden=>$Set{Hidden}, -default=>$Set{Default});
}

########################
sub save_New_Records {
########################
    my $self = shift;
    my $dbc = $self->dbc();
    my $q = $self->query();

    my $table =  $q->param('Table');
    my $ids = $q->param('IDs');
    
    my $Field_Info = $dbc->field_info(-table=>$table, -debug=>1);
    my @fields = keys %$Field_Info if $Field_Info;   
    my @ids = Cast_List(-list=>$ids, -to=>'array');

    my %Values;
    my $index = 1;
    foreach my $id (@ids) {
        foreach my $field ( @fields ) {
            if (! defined $Field_Info->{$field} || ! defined $Field_Info->{$field}{DBField_ID} ) { next }
            ## using field management tables ##
            my $f_id = $Field_Info->{$field}{DBField_ID};
            my $v = '';
            if (defined $q->param("DBField-$f_id-$id") ) {
                $v = $q->param("DBField-$f_id-$id");
            }
            push @{$Values{$index++}}, $v;
        }
    }

    use LampLite::HTML;
    print HTML_Dump \@fields, \%Values; 
#    $dbc->append(-table=>$table, -fields=>\@fields, -values->\%Values);
    return "Saving new records...";
}

##################
sub save_Edits {
##################
    my $self = shift;
    my $dbc = $self->dbc();
    my $q = $self->query();
    
    my $table =  $q->param('Table');
    my $ids = $q->param('IDs');
    
    my $Field_Info = $dbc->field_info(-table=>$table);
    my @fields = keys %$Field_Info if $Field_Info;   
    my @ids = Cast_List(-list=>$ids, -to=>'array');

    my @fids;

    my $updated = 0;
    my $primary = $dbc->primary_field($table);
    my $index = 1;
    foreach my $id (@ids) {
        my  (@update_fields, @update_values);
        foreach my $field ( @fields ) {
            if ($field eq 'Loaded') { next }
            if (! defined $Field_Info->{$field} || ! defined $Field_Info->{$field}{DBField_ID} ) { next }
            ## using field management tables ##
            my $f_id = $Field_Info->{$field}{DBField_ID};
            push @fids, $Field_Info->{$field}{DBField_ID};
            my $v = '';
            if (defined $q->param("DBField-$f_id-$id") ) {
                $v = $q->param("DBField-$f_id-$id");
            }
            if ($field !~/\b$primary$/) {
                push @update_fields, $field;
                push @update_values, $v;
            }
            
            my $ftype = $Field_Info->{$field}{Field_Type};
            my $ftable = $Field_Info->{$field}{Field_Table};
            if ( $v && (my $type = $dbc->media_field($field)) )  {   ## make this into a method (also used in Form_Views) - eg my $media = $dbc->media_field($field) ... return '.jpg' 
                $v =~ /(.*)\.(.*)$/;
                my $extension = $2;
                require LampLite::File;
                
                if (!$dbc->config('media_data_dir')) { $dbc->error("Media data directory not defined (please ensure this path is defined in the directories.yml file)") }
                else {
                    my $path = create_dir($dbc->config('media_data_dir'), $dbc->config('dbase') . "/$ftable/$id");
                    my $link_path = create_dir($dbc->config('media_data_dir'), $dbc->config('dbase') . "/$ftable/$id");
                    my $local_filename = LampLite::File->archive_data_file( -filehandle => $v, -type => $extension, -path => $path, -name=>$v);
                    try_system_command("cd $path; ln -s '$v' $type.$extension; cd -;");  ## link type to file saved (sets default current file (eg Audio.mp3, Image.mp3), but maintains old files)
                }
            }
        }
        my $condition = "$primary = '$id'";
        $index++;
        if (@update_fields) {
            $updated += $dbc->update_DB(-table=>$table, -fields=>\@update_fields, -values=>\@update_values, -condition=>$condition, -autoquote=>1);
        }
    }
    $dbc->message("Updated $updated $table record(s)");
    return ;
}

return 1;
