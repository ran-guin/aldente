###################################################
# Unit_Test.pm
#
###################################################
package Unit_Test;

use RGTools::RGIO;
use SDB::HTML;

#use YAML qw(Load Dump freeze thaw);
use Data::Dumper;
use RGTools::Object;
use Benchmark;

@ISA = qw(Exporter Object);
require Exporter;
@EXPORT = qw(
    form_wrapped
    table_count
    row_count
    column_count
);

use strict;

###########
sub new {
###########
    my $this = shift;
    my %args = @_;

    my $path    = $args{-path};
    my $verbose = $args{-verbose};

    my $class   = ref($this) || $this;
    my $self    = Object->new();
    my $builder = Test::Builder->new();
    $self->{builder} = $builder;

    bless $self, $class;

    $self->{path}    = $path    if $path;
    $self->{verbose} = $verbose if $verbose;

    return $self;
}

# Return: True if input contains opening and closing form tags #
######################
sub form_wrapped {
######################
    my $string = shift;

    my $status;
    if ( $string =~ /<form\b/i ) {
        $status .= 'opened;';
    }
    if ( $string =~ /<\/form\b/i ) {
        $status .= 'closed;';
    }
    if ( $status eq 'opened;closed;' ) { $status = 'yes'; }

    return $status;
}

#####################
sub find_modules {
#####################
    my $self    = shift;
    my $dir     = shift;
    my $path    = $self->{path};
    my @modules = split "\n", `find $path/$dir -type f -maxdepth 1 -name *.pm`;
    map { ~s/^(.*)\/(.+?)(\.pm|)$/$2/; } @modules;
    return @modules;
}

###################
sub find_module {
###################
    my $self   = shift;
    my $module = shift;

    my $file = $self->get_file($module);
    if ( -e $file ) { return 1; }

    return 0;
}

####################
sub find_methods {
####################
    my $self   = shift;
    my $dir    = shift;
    my $module = shift;

    my $file    = $self->get_file("$dir/$module");
    my @methods = `grep "^sub " $file`;

    map { chomp; ~s/sub\s+(\w+)(.*?)$/$1/ } @methods;
    return @methods;
}

#################
sub get_file {
#################
    my $self   = shift;
    my $dir    = shift;
    my $module = shift || $dir;
    my $path   = $self->{path};

    if ( $module =~ /(\w+)::(\w+)(\.pm|)/ ) {
        $module = "$1/$2.pm";
    }
    elsif ( $module =~ /$path\/(\w+)\/(\w+)(\.pm|)$/ ) {
        $module = "$1/$2.pm";
    }
    elsif ( $module =~ /(\w+)\/(\w+)(\.pm|)$/ ) {
        $module = "$1/$2.pm";
    }
    elsif ( $dir ne $module ) {
        $module = "$dir/$module.pm";
    }

    else { print "** Strange module ($module in $dir ?)"; }
    return "$path/$module";
}
####################
sub get_unit_test {
####################
    my $self   = shift;
    my $dir    = shift;
    my $module = shift;

    my $file = $self->get_file( $dir, $module );
    my $block = `cat $file` if ( -e $file );

    my $unit_test = '';
    my @lines     = ();
    my $started   = 0;
    my $package;
    foreach my $line ( split "\n", $block ) {
        if ( $line =~ /package (.*);/i ) {
            $package = $1;
        }
        unless ( $started || $line =~ /sub unit_test/ ) {next}
        $started++;
        if ( $line =~ /\breturn / ) {
            $unit_test = join "\n", @lines;
            $unit_test .= $line;
            last;
        }
        else {
            push @lines, $line;
        }
    }

    return ( $package, $unit_test ) if $unit_test;
}

###############
sub run_test {
###############
    my $self                 = shift;
    my $dir                  = shift;
    my $module               = shift;
    my $dbc                  = shift;
    my $to_be_tested_methods = shift;
    my $test_output_file     = shift;
    my $failure_output_file  = shift;

    my @modules;
    if ($module) {
        @modules = Cast_List( -list => $module, -to => 'array' );
    }
    else {
        @modules = $self->find_modules($dir);
    }

    print "*" x 40 . "\n";
    print "Running unit_test on $dir modules\n" . "*" x 40 . "\n";
    print "Found " . int(@modules) . " modules...\n";
    foreach my $mod (@modules) {
        unless ($mod) {next}
        my @methods = $self->find_methods( $dir, $mod );
        print "$dir :: $mod (containing  " . int(@methods) . " methods)\n";
        my @missing_tests;
        my @included_tests;
        my ( $package, $local_unit_test ) = $self->get_unit_test( $dir, $mod );
        foreach my $method (@methods) {
            if ( grep /\b$method\b/m, $local_unit_test ) {
                push @included_tests, $method;
            }
            else {
                push @missing_tests, $method;
            }
        }
        unless ( grep /unit_test/, @methods ) {
            print " [No unit test found]\n";
            next;
        }

        print "found " . int(@methods) . " methods\n";

        if (@missing_tests) {
            print int(@missing_tests) . " methods/functions are lacking tests.\n";
            if ( $self->{verbose} ) {
                print "\nMethods not tested:\n";
                print "*" x 30 . "\n";
                print join "\n", @missing_tests;
                print "\n***\n";
            }
        }
        if (@included_tests) {
            print int(@included_tests) . " methods/functions are tested to some degree in unit_test.\n";

            #    print join "\n", @included_tests;
        }

        my $require = $self->get_file( $dir, $mod );
        print "** Require $require **\n";

        print "*" x 60 . "\n";
        print "* START ${dir}::$mod unit test on $package package *\n";
        print "*" x 60 . "\n";

        my $begin_module = new Benchmark;
        require $require;
        my $object  = $package;
        my $results = $object->unit_test(
            -connection => $dbc,
            -methods    => $to_be_tested_methods
        );
        my $end_module = new Benchmark;
        my $time_to_run = timediff( $end_module, $begin_module );

        print "Time to test package $package  <", timestr($time_to_run), "\n";

        is( $results, 'completed', 'Completed unit test' );

        print "*" x 40 . "\n";
        print "* END OF $mod unit test *\n";
        print "*" x 40 . "\n";
    }
    return 'completed';
}

# Redirect the test output to a file
####################
sub test_output {
####################
    my $self = shift;
    my %args = @_;
    my $file = $args{-file};
    $self->{builder}->output($file);
    return 1;
}

# Redirect the failure output to a file
#############################
sub failure_test_output {
#############################
    my $self = shift;
    my %args = @_;
    my $file = $args{-file};
    $self->{builder}->failure_output($file);
    return 1;
}

##########################
sub dump_Benchmarks {
##########################
    my %args       = &filter_input( \@_, -args => 'benchmarks,delimiter,start' );
    my $benchmarks = $args{-benchmarks};
    my $delimiter  = $args{-delimiter};
    my $start      = $args{-start} || 'start';
    my $end        = $args{-end} || 'end';
    my $format     = $args{'-format'} || 'text';
    my $mark       = $args{-mark};
    my $show       = $args{-show};                                                  ## benchmarks to show results for (defaults to all)

    my ( $prefix, $suffix ) = ( '', '' );
    if ( $format eq 'html' ) {
        $delimiter ||= '<BR>';
        $prefix = "<Font size=-2>";
        $suffix = "</Font><BR>";
    }
    else {
        $delimiter ||= "\n";
    }

    my %Benchmark = %$benchmarks if $benchmarks;

    my @keys = keys %Benchmark;

    my $starting_timestamp = $Benchmark{$start};
    my %benchmarks;
    
    foreach my $key (@keys) {
        my $timestamp = $Benchmark{$key};
        my $time      = timediff( $timestamp, $starting_timestamp );
        my $string    = timestr($time);
        
        $string =~s/(\d+) wallclock sec/$1 sec/;
        if ($string =~ /(\d+\.\d+) CPU/ ) { $string = "$1 : $string" }

        my $stamp = "$string.$key";
        if ( $show && ( $show =~ /\b$key\b/ ) ) {
            $benchmarks{"$stamp"} = "$prefix $key: $string. $suffix";
        }
        else { $benchmarks{"$stamp"} .= "$prefix $key: $string. $suffix" }
    }

    my $output;
    my $mark_index = 0;
    foreach my $key (
        sort {
            $a =~ /^(\d+)/;
            my $key_a = $1;
            $b =~ /^(\d+)/;
            my $key_b = $1;
            return $a <=> $b
        } keys %benchmarks
        )
    {
        my $delay = 0;
        if ( $key =~ /(\d+)/ ) { $delay = $1; }

        my ( $tag, $details ) = ( $benchmarks{$key}, '' );
        if ( $benchmarks{$key} =~ /(.+)\:(.+)\./ ) {
            $tag     = $1;
            $details = $2;
            chomp $details;
        }
        ## mark sections which have taken more than N seconds (supplied by mark parameter) ##
        while ( ( defined $mark->[$mark_index] ) && ( $delay > $mark->[$mark_index] ) ) {
            $output .= "**************  > " . $mark->[$mark_index] . " sec ****************" . $delimiter;
            $mark_index++;
        }
        if ( $format eq 'text' ) {
            $output .= "$delay sec -> $tag\t[$details]" . $delimiter;
        }
        else {
            $output .= "<B>$delay sec -> $tag</B> [$details]" . $delimiter;
        }
    }

    return $output;
}

################################
## Customized testing methods ##
################################

#######################
sub table_count {
#######################
    my $string = shift;

    my $count = 0;
    while ( $string =~ s /<TABLE\b//i ) { $count++ }
    return $count;
}

#######################
sub row_count {
#######################
    my $string = shift;

    my $count = 0;
    while ( $string =~ s /<TR\b//i ) { $count++ }
    return $count;
}

##################
sub column_count {
##################
    my $string = shift;
    my $count  = 0;

    $string =~ s/\n/ /g;
    my $max = 0;
    while ( $string =~ /^(.*?)<TR (.*?)<\/TR>(.*)$/xmsi ) {
        my $row = $2;
        $string = $3;

        my $count2 = 0;
        while ( $row =~ s /<T[HD]\b//i ) { $count2++ }
        if ( $count2 > $max ) { $max = $count2 }
    }

    return $max;

}

#####################################################
# Return: $rows,$cols (size of HTML Table in string)
#######################
sub table_size {
#######################
    my $string = shift;

    my $col_count   = 0;
    my $row_count   = 0;
    my $cols_in_row = 0;
    my $count       = 0;
    while ( $string =~ s/<(TR\b.*?<\/TR)>/$1/ixms ) {
        my $row = $1;
        $row_count++;
        while ( $row =~ s /<TD\b//i ) { $cols_in_row++ }
        if ( $cols_in_row > $count ) { $count = $cols_in_row }
        $cols_in_row = 0;
    }

    return ( $row_count, $col_count );
}

#
# Accessor to simplify the unit testing for App modules.
#
# Usage (within the bin/t test file):
#   test_run_mode( $cgi_app, $run_mode, $Params);
#
#   eg: test_run_mode('Object_App','Search Object', { 'Object_Class' => 'Employee' });
#
# Return: page returned by run_mode
###################
sub test_run_mode {
###################
    my %args = filter_input(\@_, -args=>'dbc,cgi_app,rm', -mandatory=>'cgi_app');
     
    my $dbc = $args{-dbc};
    my $cgi_application = $args{-cgi_app};
    my $rm  = $args{-rm};
    my $Params = $args{-Params} || {};
    
    $ENV{CGI_APP_RETURN_ONLY} = 1;
 
    eval "require $cgi_application";
    
    use CGI;
    my $cgi_app = $cgi_application->new( PARAMS => { dbc => $dbc });
    
    ## set cgi_app & run mode parameters directly ##
    my $q = $cgi_app->query();
    $q->param('rm', $rm);
    $q->param('cgi_application', $cgi_application);
    
    if ($Params)  {
        foreach my $key (keys %$Params) {
            $q->param($key, $Params->{$key});
        }
    }
    
    my $page = $cgi_app->run($rm);

    return $page;
}

return 1;
