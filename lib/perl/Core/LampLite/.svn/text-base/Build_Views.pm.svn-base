package LampLite::Build_Views;

use base LampLite::Views;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Build.pm - Wrapper for building LampLite UI

=head1 SYNOPSIS <UPLINK>

Assumes checked out version of LampLite + RGTools

#

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use LampLite::CGI;
use LampLite::Bootstrap;
use LampLite::Form;
use SDB::HTML;

use RGTools::RGIO qw(filter_input Cast_List);

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################
my $BS = new Bootstrap;
my $q  = new LampLite::CGI;

###################
sub setup_config {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    my $map = $args{-map};
    my $update = $args{-update};
    my $Config = $args{-Config};
    my $Form = new LampLite::Form();

    my $validate;
    foreach my $param (keys %{$map}) {
        my $mapped = $map->{$param};
        my ($type, $placeholder);

        if ($mapped =~ /^enum/i) { $type = $mapped }
        else { $placeholder = $mapped}

        my $value = $Config->{config}{$param};
        if ($update && $mapped =~/^enum\((.*)\)/) { 
            my @options = split ",", $1;
            $value = $q->radio_group(-name=>$param, -values=>\@options, -class=>'form-control');
        }
        elsif ($update) { $value = $q->textfield(-name=>$param, -placeholder=>"-- $mapped --", -class=>'form-control wide-txt') }
        
        $Form->append($param, $value);
        $validate .= set_validator(-name=>$param, -mandatory=>1);
    }
    if ($update) {
        $Form->append('', $q->submit(-name=>'Create initial configuration file', -class=>'Std Action', -onclick=>"return validateForm(this.form);"));
    }

    return $Form->generate(-wrap=>1, -include=>$validate);
}

####################
sub system_config {
####################
    my $self = shift;
    my %args = filter_input(\@_);
    my $map = $args{-map};
    my $update = $args{-update};
    my $Config = $args{-Config};
          
    my $Form = new LampLite::Form();
    my $validate;
    foreach my $param (keys %{$map}) {
        my $mapped = $map->{$param};
        my ($type, $placeholder);

        if ($mapped =~ /^enum/i) { $type = $mapped }
        else { $placeholder = $mapped}

        my $value = $Config->{config}{$param};
        if ($update) { $value = $q->textfield(-name=>$param, -placeholder=>"-- $placeholder --", -class=>'form-control wide-txt') }
        
        $Form->append($param, $value);
        $validate .= set_validator(-name=>$param, -mandatory=>1);
    }

    if ($update) {
        $Form->append('', $q->submit(-name=>'Update System config file', -class=>'Std Action', -onclick=>"return validateForm(this.form);"));
    }

    return $Form->generate(-wrap=>1, -include=>$validate);    
}

############################
sub update_password_file {
############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $file = $args{-file};
    my $host = $args{-host};
    my $user = $args{-user};
    
    my $Form = new LampLite::Form(-title=>"Password File Specification");
    my $validate;
    
    $Form->append('File: ', $q->textfield(-name=>'File', -default=>$file, -force=>1, -class=>'wide-txt'));
    $Form->append('Host: ', $q->textfield(-name=>'Host', -default=>$host, -force=>1) );
    $Form->append('mySQL user: ', $q->textfield(-name=>'User', -default=>$user, -force=>1));
    $Form->append('mySQL password: ', $q->password_field(-name=>'Pwd', -default=>'', -force=>1));
    $Form->append('Confirm password: ', $q->password_field(-name=>'Confirm Pwd', -default=>'', -force=>1));
        
    $Form->append('', $q->submit(-name=>'Update Password file', -class=>'Action', -onclick=>"return validateForm(this.form);"));

    return $Form->generate(-wrap=>1, -include=>$validate);    
}

############################
sub update_access {
############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $file = $args{-file};
    my $host = $args{-host};
    my $users = $args{-users};
        
    my $Form = new LampLite::Form(-title=>"Password File Specification");
    my $validate = 
        $q->hidden(-name=>'Password File', -value=>$file, -force=>1)
        . $q->hidden(-name=>'Host', -value=>$host, -force=>1);
        
    foreach my $user (@$users) {
        $validate .= $q->hidden(-name=>'Missing', -value=>$user, -force=>1);
    }
    
    $Form->append('File: ', $file);
    $Form->append('Host: ', $host );
    
    $Form->append('Missing: ', Cast_List(-list=>$users, -to=>'UL') );
        
    $Form->append('', $q->submit(-name=>'Update Access Settings', -class=>'Action', -onclick=>"return validateForm(this.form);"));
    $Form->append('', $q->checkbox(-name=>'Regenerate Existing User Records', -checked=>0, -force=>1) . ' (Admin only)');

    return $Form->generate(-wrap=>1, -include=>$validate);    
}

############################
sub update_schema_prompt {
############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $host = $args{-host};
    my $dbase = $args{-dbase};
    my $sections = $args{-sections} || [];
    
    my $Form = new LampLite::Form(-title=>"Setup LampLite Database Management Schema");
    my $validate;
    $Form->append('<h2>Rebuild Database</h2>');
    $Form->append('Host: ', $q->textfield(-name=>'Host', -default=>$host, -force=>1) );
    $Form->append('Database: ', $q->textfield(-name=>'Database', -default=>$dbase, -force=>1) );
    
    $Form->append(' ', '<hr>' );
    $Form->append(' ', '<B>Sections to Install/Rebuild:</B>' );

    my $include;
    foreach my $section (@$sections) {
        $include .= $q->checkbox(-name=>"Core_Sections", -label=>$section, -value=>$section, -force=>1) . '<BR>';
    }

    $Form->append('Include: ', $include );


    $Form->append('Scope: ', $q->checkbox(-name=>'Schema', -checked=>1, -label=>'Schema') .  ' ' . $q->checkbox(-name=>'Data', -checked=>1, -label=>'Data') );
    $Form->append(' ', '<hr>' );
    
    my $default = 'Skip';
    $Form->append('If Table exists: ', $q->radio_group(-name=>'On_Duplicate', -values=>['Overwrite'], -default=>$default), -force=>1 );
    $Form->append('', $q->radio_group(-name=>'On_Duplicate', -values=>['Skip'], -default=>$default), -force=>1 );
    
    $Form->append('', $q->submit(-name=>'Rebuild Core', -class=>'Action', -onclick=>"return validateForm(this.form);"));

    return $Form->generate(-wrap=>1, -include=>$validate);    
}

####################
sub show_tables {
####################
    my $self = shift;
    my $dbc = shift;
    
    my $hash = $dbc->hash(
        -table=>'DBTable',
        -fields=>["CASE WHEN DBTable_Type IS NULL THEN 'Unclassified' WHEN DBTable_Type = '' THEN 'unclassified' ELSE DBTable_Type END AS Table_Type", 'Scope', 'Group_Concat(DBTable_Name ORDER BY DBTable_Name) as Tables'], 
        -group=>'Scope, Table_Type',
        -order=>'Table_Type',
    );
    my $types = SDB::HTML::display_hash(-dbc=>$dbc,  -hash=>$hash, -return_html=>1, -list_in_folders=>'Tables', -title=>'Current Database Tables', -layer=>'Scope');

    return $types;
}

############
sub test {
############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'name');
    my $name = $args{-name};
    
    my $Form = new LampLite::Form();
    $Form->append('', $q->submit(-name=>$name, -class=>'Std', -onclick=>"return validateForm(this.form);"));
    
    my $test = $Form->generate(-wrap=>1);

    return $test;
}

########################
sub filesystem_update {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
 
    my $Form = new LampLite::Form(-title=>"Setup Filesystem Directories");
    my $validate;

    my $default = 'Skip Existing Directories';
    
    $Form->append('', $q->radio_group(-name=>'Overwrite', -values=>['Skip Existing Directories'], -default=>$default, -force=>1 ));
    $Form->append('', $q->radio_group(-name=>'Overwrite', -values=>['Overwrite Existing Directories'], -default=>$default, -force=>1 ));
    
    $Form->append('', $q->submit(-name=>'Update File System Directories', -class=>'Action', -onclick=>"return validateForm(this.form);"));

    return $Form->generate(-wrap=>1, -include=>$validate);    
    
}

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

2014-06-20

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
