#!/usr/local/bin/perl

my $base_dir = "bin/t";

my @dir = `find $base_dir -type d`;

foreach my $dir (@dir) {
    my @files = split "\n", `ls $dir`;

    my $count = int(@files);
    
    print "Replace $count files within $dir\n";
}

exit;
