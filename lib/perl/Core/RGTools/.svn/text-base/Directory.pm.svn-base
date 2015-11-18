################################################################################
# Directory.pm
#
# This module auto-documents modules
#
###############################################################################
package Directory;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Directory.pm - This module auto-documents modules 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module auto-documents modules <BR>

=cut

##############################
# superclasses               #
##############################

## @ISA = qw(DB_Object);    create separate module if required... 

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::Views;

##############################
# global_vars                #
##############################
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

#
# Initialize object...
#
########
sub new {
########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my ($class) = ref($this) || $this;
    my ($self) = {};

    bless $self, $class;

    $self->{directory} = $args{-search} || $args{-directory};    ## directory of interest

    if ( $args{-search} ) {
        $self->search( -set => 1 );
    }                                                            ## search for details

    return $self;
}

##############################
# public_methods             #
##############################

###########
sub search {
###########
    #
    # Get list of files / directories etc.
    #
    my $self = shift;

    my %args = @_;

    my $type = $args{-type} || 'f';
    my $dir  = $args{-dir}  || $self->{directory};
    my $ext  = $args{-ext};
    my $set = $args{-set};             ## (re)set object attributes
    my $depth = $args{-depth} || 1;    ## depth to search

    my $name;
    if ($ext) { $name = "-name *$ext" }

    print "search ($dir/*$ext $type ($depth:$set)\n";

    my @files       = split "\n", `find $dir/ $name -type f -maxdepth $depth -printf '%f\n'`;
    my @directories = split "\n", `find $dir/ -type d -maxdepth $depth -printf '%f\n'`;
    my @links       = split "\n", `find $dir/ -type l -maxdepth $depth -printf '%f\n'`;

    my @found = split "\n", `find $dir/ $name -type $type -maxdepth $depth -printf '%f\n'`;

    if ($set) {
        $self->{files}       = \@files;
        $self->{directories} = \@directories;
        $self->{links}       = \@links;
    }
    return @found;
}

########################
sub generate_html_navigator {
########################
    my $self = shift;
    my %args = @_;

    my $files;
    my $ext;

    my $filename       = $args{-filename} || 'home';
    my $html_directory = $args{-html_dir} || '';                      ## output directory (for html file)
    my $html_URL       = $args{-html_URL} || '';                      ## return URL directory (for links)
    my $css_dir        = $args{-css_dir}  || '';                      ##
    my $dir            = $args{-dir}      || $self->{directory};
    my $extensions     = $args{-ext}      || ',pl,pm,js,help,html';
    my $uplink    = $args{-uplink};                                   ## provide link to previous level...
    my $recursive = $args{-recursive};

    my $local_filename = $filename;
    if ( $dir eq $self->{directory} ) {
        $local_filename = $dir;
    }                                                                 ## use directory name if first time through...

    my @all_extensions = split ',', $extensions;

    my $name;
    my @parse_extensions = ( 'pl', 'pm' );
    my %Files;
    foreach my $this_ext (@all_extensions) {
        if ($this_ext) { $name = "-iregex '.*\.$this_ext'" }
        else {
            $name     = "-iregex '[a-zA-Z0-9_\/]*'";
            $this_ext = '(no extension)';
        }
        $Files{$this_ext} = `find $dir/ $name -type f -maxdepth 1 -printf '%f,'`;

        print "\n***  $dir ($this_ext) ***\n";
        print qq{find $dir/ $name -type f -maxdepth 1 -printf '%f,'};
        print "\n";
        print $Files{$this_ext};
        print "\n****\n";
    }

    my @directories = split ",", `find $dir/ -type d -maxdepth 1 -printf '%f,'`;
    my @links       = split ",", `find $dir/ -type l -maxdepth 1 -printf '%f,'`;

    my $html_filename = "$dir";
    $html_filename =~ s/$self->{directory}//;    ## cut off base directory
    $html_filename =~ s/\//\./g;
    $html_filename =~ s/^[\.\s]+//g;
    if   ($html_filename) { $html_filename = "home.$html_filename"; }
    else                  { $html_filename = 'home' }

    open( FILES, ">$html_directory/$html_filename.dir.html" ) or die "cannot open $html_directory/$html_filename.help";

    if ($uplink) {
        print FILES "parent directories:   ...(home = $self->{directory})<P>";
        my $target = $uplink;
        if ( $target =~ /$html_URL\/(.*)\.dir\.html/ ) { $target = $1 }
        my $link = "<A Href=$html_URL/$target.dir.html><B>$target</B></A>";
        print FILES "$link<BR>\n";
        while ( $target =~ s/^(.+)\.(.+?)$/$1/ ) {
            my $link = "<A Href=$html_URL/$target.dir.html><B>$target</B></A>";
            print FILES "$link<BR>\n";
        }
        print FILES "<HR>";
    }

    my $readme;
    if ( -e "$dir/README" ) {
        $readme = `cat $dir/README`;
        $readme =~ s /\n/<BR>/g;
        print FILES "<B>README</B><P>$readme<P>";
    }

    print FILES "<H2>$local_filename Directories:</H2>\n";
    print "\n$dir : Directories\n******************\n";
    print FILES "(** indicates that a README file is included in the directory)<P>\n";
    print FILES "<UL>";
    foreach my $directory (@directories) {
        unless ($directory) {next}
        my $link = "<A Href=$html_URL/$html_filename.$directory.dir.html><B>";
        $link .= $directory;
        $link .= "</B></A>";
        print FILES "<LI>$link";

        if ( -e "$self->{directory}/$directory/README" ) {
            $readme = '**';
        }
        else { $readme = ''; }
        print FILES $readme;
    }
    print FILES "\n</UL></span>\n";

    print FILES "<H2>$local_filename Files:</H2>\n<UL>\n";

    my @files;
    foreach my $ext ( keys %Files ) {
        unless ( $ext && $Files{$ext} ) {next}
        print FILES "<h3>'$ext' Files:</h3>";
        foreach my $file ( split ",", $Files{$ext} ) {
            if ( grep /^$ext$/, @parse_extensions ) {
                my $link = "<A Href=$html_URL/$file.file.html><B>$file</B></A>";
                print FILES "\n<LI>$link";
                push( @files, $file );
            }
            else {
                print FILES "\n<LI>$file";
            }
        }
    }
    print FILES "\n</UL></span>\n";
    close(FILES);

    my $localuplink = "$html_URL/$html_filename.dir.html";

    ### Now build the directory file recursively.. ###
    foreach my $directory (@directories) {
        unless ($directory) {next}
        unless ( $directory =~ /^CVS$/ ) {
            $self->generate_html_navigator(
                -filename => $directory,
                -html_dir => $html_directory,
                -html_URL => $html_URL,
                -dir      => "$dir/$directory",
                -uplink   => $localuplink,
                -ext      => $ext
            );
        }
    }

    foreach my $file (@files) {
        $self->generate_html_info(
            -filename => $file,
            -dir      => $dir,
            -html_dir => $html_directory,
            -uplink   => $localuplink
        );
    }

    return;
}

#####################
sub generate_html_info {
#####################
    my $self = shift;
    my %args = @_;

    my $files;
    my $ext;

    my $filename       = $args{-filename} || 'directory_navigator';
    my $dir            = $args{-dir}      || $self->{directory};
    my $html_directory = $args{-html_dir} || '';                      ## output directory (for html file)
    my $uplink = $args{-uplink};                                      ## provide link to previous level...

    my @routines;
    if ( -e "$dir/$filename" ) {
        @routines = `grep '^sub [a-zA-Z]' $dir/$filename`;
    }

    my $File_object = Code->new("$dir/$filename");
    $File_object->generate_code();

    my $description = $File_object->description;
    $description =~ s /\n/<BR>/g;

    my @functions  = keys %{ $File_object->{public_functions} };
    my @methods    = @{ $File_object->get_methods( -verbose => 1, -format => 'html' ) };
    my @attributes = @{ $File_object->get_attributes( -verbose => 1, -format => 'html' ) };

    open( FILES, ">$html_directory/$filename.file.html" ) or die "cannot open $html_directory/$filename.file.html";

    if ($uplink) { print FILES "<A Href=$uplink><B>../</B></A><P>" }

    print FILES "<H2>$filename</H2>\n";
    print FILES "$description<P>";

    if (@attributes) {
        print FILES "<h3>Attributes</h3><UL>";
        foreach my $attribute (@attributes) {
            print FILES "<LI>$attribute:";
        }
        print FILES "</UL>";
    }
    if (@functions) {
        print FILES "<h3>Functions</h3><UL>";
        foreach my $function (@functions) {
            print FILES "<LI>$function:";
        }
        print FILES "</UL>";
    }
    if (@methods) {
        print FILES "<h3>Methods</h3><UL>";
        foreach my $method (@methods) {
            print FILES "<LI>$method:";
        }
        print FILES "</UL>";
    }

    return;
}

#######################
sub search_directories {
#######################
    my $self = shift;
    my %args = @_;

    my $dir   = $args{-directory} || $self->{directories};
    my $ext   = $args{-ext}       || '';
    my $depth = $args{-depth}     || 1;                      ## depth to search

    my @exclude_dirs = ('CVS');

    print "Search directories:\n";
    print "$dir : ";
    print join "\n", @{$dir};
    print "$dir : ";
    print join "\n", @{ $self->{directories} };
    print "\nDONE\n";

    foreach my $directory ( @{$dir} ) {
        print "$directory..\n";
        my $dir_name;
        if ( $directory =~ /^$self->{directory}\/+(.*)/ ) {
            $dir_name = $1;
        }
        else {
            print "$directory in unrecognized format ?\n";
            next;
        }
        if ( $dir_name =~ /\/CVS$/ ) {
            next;
        }    ## skip this directory if only CVS directory
        if ( $dir_name =~ /^auto/ ) {
            next;
        }    ## skip this directory if only auto directory
        if ( grep /^$dir_name$/, @exclude_dirs ) {
            next;
        }    ## skip this directory if in exclusion list

        if ( -e "$directory/README" ) {
            $self->{dir_info}->{$dir_name}->{description} = `cat $dir/README`;
        }
        else {
            print "Please update description (add README file) for $directory directory\n";
            $self->{dir_info}->{$dir_name}->{description} = 'incomplete documentation';
        }

        my $name = "*$ext";

        my @files = split "\n", `ls $directory/$name`;
        $self->{dir_info}->{$dir_name}->{files} = \@files;
        $self->search_perl_files(
            -files     => \@files,
            -ext       => $ext,
            -directory => $dir_name
        );
    }
    return;
}

###################
sub search_perl_files {
###################
    my $self = shift;
    my %args = @_;

    my $dir_name  = $args{-directory} || $self->{directory};
    my $file_list = $args{-files}     || $self->{files};
    my $ext       = $args{-ext}       || '';

    foreach my $file ( @{$file_list} ) {
        if ( $file =~ /$self->{directory}\/(.*\/)(.+$ext)$/ ) {
            my $dir      = $1;
            my $filename = $2;

            my $output = `grep -B 100 'use strict' $file`;
            if ( $output =~ /$filename[\n\s\#]+([a-zA-Z].*?)\n/ ) {
                $self->{file_info}->{$filename}->{description} = $1;    ### get first string of text after file name
            }
            $self->{file_info}->{$filename}->{directory} = $dir;

            print "$filename :\n $self->{file_info}->{$filename}->{description}\n";
            my @routines = `grep '^sub ' $file`;
            foreach my $routine (@routines) {
                my $name;
                if ( $routine =~ /sub (.*)\s*\{/ ) { $name = $1 }
                push( @{ $self->{file_info}->{$filename}->{routines} }, $name );

                #		print "+ $name\n";
            }
        }
    }
    return;
}

################
sub generate_HTML {
################
    my $self = shift;
    my %args = @_;

    my $files;
    my $ext;

    my $html_directory = $args{-html_dir} || '';    ## output directory (for perldocs)
    my $html_URL       = $args{-html_URL} || '';    ## output directory (for perldocs)
    my $css_dir        = $args{-css_dir}  || '';

    unless ($files) {
        print "Are you sure you want to regenerate ALL html files? (y/n)";
        my $ans = Prompt_Input( -type => 'char' );
        unless ( $ans =~ /y|Y/ ) { exit; }
    }

    my $directory = $self->{directory};

    foreach my $module ( keys %{ $self->{dir_info} } ) {
        open( FILES, ">$html_directory/$module" . "_modules.help" ) or die "cannot open $html_directory/$module" . "_modules.help";

        print FILES "<H2>$module Modules</H2>\n<P>\n";
        my $readme = `cat $directory/$module/README`;
        $readme =~ s /\n/<BR>/g;
        unless ( $readme =~ /no such/i ) {
            print FILES $readme;
        }
        print FILES "\n<span class=small><UL>\n";

        foreach my $file ( @{ $self->{dir_info}->{$module}->{files} } ) {
            if ( $file =~ /.*\/(.*?)$/ ) { $file = $1 }
            my $link        = "<A Href=$html_URL>$file</A>";
            my $description = $self->{file_info}->{$file}->{description};
            $description =~ s/\n/<BR>/g;
            print FILES "\n<LI>$link : $description";
        }
        print FILES "\n</UL></span>\n";
        close(FILES);
        print "Wrote to $module" . "_modules.help (link urldir of $0)\n";
    }

    return;
}

##################
sub generate_perldoc {
##################
    #
    # unfinished...
    #
    my $self = shift;
    my %args = @_;

    my $files = $args{-files};
    my $ext;

    my $help            = $args{-help};               ## generate help files
    my $perldoc         = $args{-perldoc} || '';      ## css directory
    my $css_dir         = $args{-css_dir} || '';
    my $html_directory  = $args{-html_dir} || '';     ## output directory (for perldocs)
    my $image_directory = $args{-image_dir} || '';    ## output directory (for perldocs)

    $self->{css_dir}   = $css_dir;
    $self->{image_dir} = $image_directory;
    $self->{html_dir}  = $html_directory;

    if ( $perldoc && !$files ) {
        print "Are you sure you want to insert Perldoc to and re-organize ALL source files? (y/n)";
        my $ans = Prompt_Input( -type => 'char' );
        unless ( $ans =~ /y|Y/ ) { exit; }
    }

    my %List;                                         ## use only specified list if given...
    if ($files) {
        foreach my $file ( split /,/, $files ) {
            $List{$file} = 1;
        }
    }

    foreach my $dir ( keys %{ $self->{dir_info} } ) {
        foreach my $file ( @{ $self->{dir_info}->{files} } ) {
            unless ( $file =~ /.pm$/ ) {
                next;
            }                                         ## only build code for pl & pm files ##
            if ( $perldoc && ( !$files || exists $List{$file} ) ) {
                _build_code( "$dir/$file", $self->{directories} );
                $self->_build_perldoc( $dir, $file );
            }
        }
    }
    return;
}

##############################
# public_functions           #
##############################
#####################
sub find_Files {
#####################
    my %args     = filter_input(\@_);
    my $pattern  = $args{-pattern};
    my @final;
    my $command  = "ls $pattern";
    my @lines    = split "\n" , try_system_command($command);
    
    for my $line (@lines) {
        unless ($line) {next}
        if ($line =~ /permission denied/i ) { next }
        if ($line =~ /not found/i ) {next}
        if ($line =~ /No such file/i ) {next}    
        push @final, $line;
    }
    return @final;
    
}

###################
sub create_link {
#############################
# Copies File to given destination
# (input is not file path but file handle)
#############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'target,source', -mandatory => 'target,source' );
    my $source = $args{-source};
    my $target = $args{-target};

    my $command = "ln -s $source $target";
    
    my $response = try_system_command("$command");
    if ($response){
        Message "Command: $command";
        Message "Response: $response";
    }
    return $target;
}

##############################
# private_methods            #
##############################

#####################
sub _build_perldoc {
#####################
    #
    # Runs the pod2html program to convert perldoc into HTML help files
    #
    my $self = shift;
    my $dir  = shift;
    my $file = shift;

    my $html_dir  = $self->{html_dir};
    my $image_dir = $self->{image_dir};
    my $css_dir   = $self->{css_dir};

    my $infile  = "$dir/$file";
    my $outfile = "$html_dir/$file.html";

    my $command = "/usr/bin/pod2html --infile=$infile --outfile=$outfile -css=$css_dir";

    print try_system_command($command);

    # Add uplinks to the perldoc HTML generated...
    if ( -f $outfile ) {
        my $img_dir = $image_dir;
        $img_dir =~ s/\//\\\//g;
        my $localuplink = "&nbsp;<a href='#top'><img src=\\/$img_dir\\/uplink.png><\\/a>";
        $command = "/usr/bin/perl -i -pe 's/(<[L|l][I|i]>.*)\\s*&lt;UPLINK&gt;(.*<\\/[L|l][I|i]>)/\$1\$2/g' $outfile";
        print try_system_command($command);
        $command = "/usr/bin/perl -i -pe 's/(<[H|h]\\d{1}>.*)&lt;UPLINK&gt;(.*<\\/[H|h]\\d{1}>)/\$1$localuplink\$2/g' $outfile";
        print try_system_command($command);
        print "$dir/$file: Perldoc HTML generated ($outfile).\n";
    }
    else {
        print "***$dir/$file: Perldoc HTML not generated.\n";
    }
}

##############################
# private_functions          #
##############################

#
# Code to build Perldoc documentation and associated html files...
#
#####################
sub _build_code {
#####################
    #
    # Re-organize the code and insert perldoc into code
    #
    my $file = shift;    # Source file to insert Perldoc and re-organize [String]
    my $dirs = shift;

    my $code = Code->new($file);
    $code->define_custom_modules( -dirs => $dirs );
    $code->generate_code( -perldoc => 1 );
    $code->save_code( -overwrite => 1 );

    print "$file: Perldoc inserted and code re-organized.\n";
}

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

$Id: Directory.pm,v 1.6 2004/08/27 18:26:51 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
