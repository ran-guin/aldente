package LampLite::Build;

use base LampLite::DB_Object;

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
use RGTools::RGIO qw(filter_input Cast_List create_dir Call_Stack);

use LampLite::Build_Views;

my $BS = new Bootstrap;
my $q  = new LampLite::CGI;
##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################

##########################
sub create_config_file {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $setup_map = $args{-map};
    my $custom_config = $args{-file};
    
    if (!$setup_map) { 
        print $BS->error("No setup map to include in config file"); 
        return 0; 
    }
    
    my @keys = keys %{$setup_map};
    print $BS->message("Creating Configuration File: $custom_config");
    open my $FILE, ">>", $custom_config or print $BS->error("Error trying to writeto $custom_config");
    my $added = 0;
    foreach my $key (@keys) {
        my $pval = $q->param($key);
        if ($pval) {
            print $FILE "$key: $pval\n";
            $added++;
        }
    }
    print $BS->success("Added $added parameter settings to config file");
    return;
}

##########################
sub save_password_file {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $file = $args{-file};
    my $host = $args{-host};
    my $user = $args{-user};
    my $pwd  = $args{-pwd};
    my $confirm = $args{-confirm};

    print $BS->message("Saving Password File");

    if ($file && $host && $user && $pwd && ($pwd eq $confirm)) {
        print $BS->message("Writing to password file");
        open my $FILE, ">>", $file or print $BS->error("Error trying to write to $file");
        my $ok = print $FILE "$host:$user:$pwd\n";
        if ($ok) {  print $BS->success("Added $user access to $host in password file") }
        else { print $BS->error("Problem writing to $file") }
    }
    elsif (!$pwd || ($pwd ne $confirm) ) {
        print $BS->error("Password missing or doesn't match confirmation password");
    }
    else {
        print $BS->error("Missing necessary information: Host=$host; User=$user;");
    }
    return;
}

##########################
sub rebuild_core {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $host = $args{-host};
    my $user = $args{-user};
    my $password = $args{-password};
    my $dbase    = $args{-dbase};
    my $path     = $args{-path};
    my $sections     = $args{-sections} || [];
    my $include = $args{-include} || 'sql';   ## sql contain schema; txt files contain core data ##
    my $overwrite = $args{-overwrite};
    my $skip    = $args{-skip};
    my $debug = $args{-debug};
    
    my @sections = Cast_List(-list=>$args{-sections}, -to=>'array');
    my @include = Cast_List(-list=>$args{-include}, -to=>'array');
    my $overwrite = $args{-overwrite};

    my $including = int(@include) . " Section(s):";
    if (@include) { $including .= Cast_List(-list=>\@include, -to=>'OL') }
    
    if ($overwrite =~/Overwrite/) { print $BS->warning("Overwriting existing tables") } 
 
    my @rebuild_tables;
    my $success = 1;
    foreach my $section (@$sections) {
        my @files = split "\n",`ls $path/$section/*.$include`;
        
        my $included = "Loaded $include files:<P>";
        foreach my $file (@files) {
            my ($command, $table);

            if ($file =~/(.*)\/(\w+)\.$include$/) { $table = $2 }
            
            if ( $skip && $dbc->table_loaded($table) ) { $included .= " SKIP $table (already exists) <BR>" }
            else {
                if ($include =~ /sql/) { $command = "mysql -h $host -u $user -p$password $dbase < $file" }
                elsif ($table) { 
                    my $delete = "DELETE FROM $table;" if $overwrite; ## delete existing records before rebuilding ##
                    $command = "mysql -h $host -u $user -p$password $dbase -e \'$delete LOAD DATA LOCAL INFILE \"$file\" INTO TABLE $table IGNORE 1 LINES\' ";
                }
                else { $included . "Error parsing $file (?)<BR>"; next; }

                $included .= "$file";

                my $feedback = `$command`;
                if ($feedback) { 
                    $success = 0;    
                    $included .= $feedback;
                }
                else { $included .= " [OK]<BR>"}
            }
            
            push @rebuild_tables, $table;
            
            if ($debug && $command) { $included .= "[$command]<BR>" }
        }
        print $BS->message($included);
    }
    
    ## run dbfield_set to update field management tables automatically after updating Schema ## 
    my $tables = join ',', @rebuild_tables;
    my $rebuild = $FindBin::RealBin . '/../bin/dbfield_set.pl -host ' . $dbc->config('host') . ' -user patch_installer -tables $tables -dbase ' . $dbc->config('dbase');
    my $rebuild_message = `$rebuild`;
    
    if ($debug) { print $BS->message("$rebuild<BR>$rebuild_message<BR><BR>") }
       
    return $success;
}

###############################
sub confirm_access_settings {
###############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $Config = $args{-Config};
    my $password_file = $args{-password_file};
    
    my ($ok, $message, @set_users, @missing_users);

    if (!$dbc || !$dbc->{connected}) { return (0, 'No Database Connection') }
    elsif ( !$dbc->table_loaded('DB_Login') ) { return (0, 'DB_Login Table not defined') }
    else {
        my $access = $dbc->hash(-sql=>"SELECT DB_User FROM DB_Login ORDER BY DB_User");
        my @users = @{$access->{DB_User}} if $access && defined $access->{DB_User};
        if ( ! int(@users) ) { return (0, 'No Users defined in DB_Login') }
        
        my $mode = $Config->{mode};
        my $host = $dbc->{host};
        my $dbase = $dbc->{dbase};
        
        $message .= "Mode: $mode<P>Host: $host<P>Database: $dbase<P>";
        
        foreach my $i (0..$#users) {
            my $user = $access->{DB_User}->[$i];
            if ( `grep "^$host:$user" $password_file` ) {
                push @set_users, $user;
            }
            else {
                push @missing_users, $user;
            } 
        }
        $ok = 1;
    }
    
    $message .= "<B>Set Users:<B>" . Cast_List(-list=>\@set_users, -to=>'UL');
    if (@missing_users) { 
        $ok = 0; 
        $message .= "<P><B>Missing Users:<B>" . Cast_List(-list=>\@missing_users, -to=>'UL');
    }
    
    return  ($ok, $message, \@missing_users);
}

#############################
sub update_access_settings {
#############################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $users = $args{-users};
    my $password_file = $args{-password_file};
    my $grant = $args{-grant};
    my $dbase = $args{-dbase};
    my $rebuild = $args{-rebuild};

    my ($s, $i, $u, $d) = ('Y','Y','Y','Y');  ### default to full privileges for now... 
    
    use LampLite::DB_Access;
    
    my $added = 0;
    my $debug = 1;
    foreach my $user (@$users) {
        my $ok = LampLite::DB_Access::add_DB_user(-db_user=>$user, -dbase=>$dbase, -password=>rand(1000), -privileges=>[$s,$i,$u,$d],-append_login_file=>$password_file, -dbc=>$dbc, -grant=>$grant, -rebuild=>$rebuild);
        if ($ok) { 
            print $BS->message("Added $user to Password login file", -type=>'success');
            $added++;
        }
        else {
            print $BS->warning("Did not add $user to Password login file - may already be defined (<B>update password file manually or delete mysql.user entry to regenerate password</B>)");
        }
    }

    
    return $added;
}

#
# Usage:
#
#  $Build->filesystem_check(-file=>'config.yml')
#
# example of filesystem specification file:
# (permission levels can optionally be supplied for any given directory)
#
# data_root:
#     - private 0770
#         - logs 0775
#         - crontabs 0770
#     - public
#               
# /home/alDente/
#     - sessions
#
#
# Notes: 
#   Base level directories need to be exact data path or predefined variable (eg web_root defined as /opt/alDente/www/ in personalize.cfg file)
#   Downstream directories are all relative and created dynamically if update flag supplied
#   Config variables are automatically defined for all directories if $dbc supplied (eg $dbc->config('sessions_dir') is set to '/opt/alDente/wwww/private/sessions' ) 
#
# Return: ($success, $message);
########################
sub filesystem_check {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->dbc;
    my $setup = $args{-setup};
    my $overwrite = $args{-overwrite};
    my $file   = $args{-file};
    my $config = $args{-config};          ## existing configuration file which may specify values for variable names declared in directories file
    my $create = $args{-create};          ## create these directories ##
    my $debug = $args{-debug};
    
    my $data_root = $args{-data_root};  ## eg /home/data - root for archiving LIMS data files
    my $web_root = $args{-web_root};    ## eg /opt/alDente/ - full path for wwww directory accessible via web
    my $url_root = $args{-url_root};    ## "/SDB_beta" - relative path for files accessible via browser 
         
    if ($create) { $self->{create_directories} = $create }
    if ($config) { $self->{config} = $config }
                
    require YAML;
    if (-e $file) {
        my $ok;
        eval { $ok = YAML::LoadFile($file) };
        if ($ok) {

            $self->_check_dir(-tree=>$ok, -overwrite=>$overwrite, -setup=>$setup, -dbc=>$dbc);
        }
        else {
            print $BS->error($@);
        }
    }
    else {
        Call_Stack();
        print $BS->error("Could not find system configuration file: $file");
        return;
    }   
    
    my ($ok, $message) = $self->_filesystem_summary($setup);
    
    return ($ok, $message);
}

#
# Summarize directories and config variables that should be defined and return validation flag to indicate if they all exist 
#
# Return: ($success, $message)
##############################
sub _filesystem_summary {
##############################
    my $self = shift;
    my $setup = shift;
    
    my $message = '<h2>Filesystem Directories:</h2>';
    
    my @add = @{$self->{add_dir}} if $self->{add_dir};
    my $config = $self->{config};
    
    if ($setup) {
        $message .= "<U>Added</U>: " . Cast_List(-list=>\@add, -to=>'UL') . '<P>';        
    }

    my $ok = 1;
    my (@found, @missing);
    foreach my $add (@add) {
        my $dir = $add;
        my $permission;
        if ($add =~/(.+) \[(.*)\]/) { $dir = $1; $permission = $2 }
        
        if ($dir && -d $dir) {
            push @found, "$dir [$permission]";
        }
        elsif ($dir) {
            push @missing, "$dir [$permission]";
            $ok = 0;
        }
    }
    $message .= "<U>System Directories</U>:<P>" . Cast_List(-list=>\@found, -to=>'UL');
    
    if (@missing) { $message .= "<P>Need to Add:<P>" . Cast_List(-list=>\@missing, -to=>'UL') }
    
    $message .= "<U>Config Path Variables</U>:<P>";
    foreach my $key ( keys %$config) {
        $message .= "<font color='red'>$key</font>\t-> \t$config->{$key}<BR>";
    }
    
    return ($ok, $message);
    
}

#
# Method to check current filesystem to see if it matches configuration filesystem specs
# (updates object file attributes):
#    * root_directories
#    * add_dir - directories added
#    * config   - config variables defined 
#
#
# Return: NULL
########################
sub _check_dir {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->dbc;
    my $subdir = $args{-subdir};
    my $config = $args{-config};
    my $tree = $args{-tree};
    my $path   = $args{-path};
    my $permission = $args{-permission} || '0775';
    my $create_dir = defined $args{-create_dir} ? $args{-create_dir} : 1;
    my $setup = $args{-setup};
    my $root  = $args{-root};
    my $debug = $args{-debug};

    my $create = $self->{config}{create_directories} || [];
    my $url_root = 'url_root';    
    
#    if ( $subdir eq $url_root && $dbc && $dbc->config($url_root) ) { 
#        ## do not create directories for url_root directories (pointing to svn committed files) ##
#        $subdir = $dbc->config($url_root);   ## Add '/' (but first remove addition of '/' in referencing code)  ## set directory to relative directory based on url_root ##
#        $create_dir = 0;
#    }  
    my $full_path = $path;
        
    my $dir;
    if (ref $tree eq 'HASH') {
            foreach my $key (keys %$tree) {
                $self->_check_dir(-tree=>$tree->{$key}, -setup=>$setup, -path=>$path, -subdir=>$key, -permission=>$permission, -dbc=>$dbc, -create_dir=>$create_dir, -root=>$root);
            }            
    }
    elsif (ref $tree eq 'ARRAY') {
        if (!$path && $subdir) { push @{$self->{root_directories}}, $subdir }

        if ($subdir =~s/ (\d+)//) { $permission = $1 }   ## truncate permission specifications from subdirectories if applicable and track as permission variable ##

        if ($subdir && !$path) { 
            if (grep /^$subdir$/, @$create) { $create_dir = 1 }
            $path = $self->{config}->{$subdir} || $subdir; 
            $root = $subdir;
        }
        elsif ($subdir) { $path .= "/$subdir" }

        my $alias;
        
        if ($create_dir) { $self->_add_dir($path, $subdir, $permission, -setup=>$setup) }
         
         
        foreach my $key ( @$tree ) {
            $self->_check_dir(-tree=>$key, -setup=>$setup, -path=>$path, -permission=>$permission, -dbc=>$dbc, -create_dir=>$create_dir, -root=>$root);       
        }
        
        if ($subdir) { $dir = $subdir }
    }
    else { $dir = $tree }
    
    if ($tree =~s/ (\d+)//) {
        $permission = $1;
    } 
    if ($create_dir) { 
        ## optional methods to log updates to object attributes (to access for feedback) ##
        $self->_add_dir($full_path, $dir, $permission, -setup=>$setup);
    }
    
    $self->_set_config($full_path, $dir, -dbc=>$dbc, -root=>$root);

    return;
}

###############
sub _add_dir {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'path, dir,permission');
    my $path  = $args{-path};
    my $dir  = $args{-dir};
    my $permission = $args{-permission};
    my $setup = $args{-setup};              ## Add directories if they are missing ... run during setup process.  (not normally run since directories should already all exist)

    if (!$path) { return }
    if (!$dir) { return }
    if (ref $dir) { return }
    
    if ($path =~/\//) { return }  ## relative path ... cannot create directories within relative paths ##
    
    if ($setup) {
        my ($link) = grep /\/$dir\b/, @{$self->{add_dir}};
        if ($link) { 
            $link =~s/ \[.*\]//;
            `ln -s $link $path/$dir`;
        }
        elsif (! -e "$path/$dir" ) {
            create_dir($path, $dir, $permission);
        }
        `chmod $path/$dir $permission`;
    }
    
    if ( ! grep /^$path\/$dir /, @{$self->{add_dir}} ) { 
        push @{$self->{add_dir}}, "$path/$dir [$permission]";
     }
    
    return 1;
}

##################
sub _set_config {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'path, dir');
    my $path  = $args{-path};
    my $dir = $args{-dir} || '';
    my $dbc = $args{-dbc} || $self->dbc;
    my $root = $args{-root};
    
    my $value = $path;
    if ($value !~/\/$dir$/) { $value .= "/$dir" }
     
     my $suffix = 'dir';
     if ($root =~/^(\w+)_root/) { 
         $suffix = $1 . '_dir';
     }
     else {
         $suffix = 'dir';
     }
     
     my $config = $dir . '_' . $suffix;
        
    if (!$path || !$dir || ref $dir) { return }

    if (defined $self->{config}{$config}) {
        return $self->{config}{$config};
    }
    
    if (defined $value) { 
        if ($dbc) { $dbc->config($config, $value) }
        $self->{config}{$config} = $value;
    }
    return $self->{config}{$config};
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
