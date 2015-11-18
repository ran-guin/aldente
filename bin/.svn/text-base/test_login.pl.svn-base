#!/usr/local/bin/perl

use strict;
use FindBin;

my $login_file =  $FindBin::RealBin . '/../conf/mysql.login';
use lib $FindBin::RealBin . '/../lib/perl/Core';
#use warnings;


use RGTools::RGIO;

## This is a file solely for testing if Eclipse and LIMS svn can work together harmonly.
## This file will be removed once the test is done.

my $fix = Prompt_Input('c','Prompt user to reset password on conflict?');

my @hosts = ('lims05','limsdev04','lims07');
print "OPEN $login_file\n\n";

my (%Users, %Failed);
my @tests = split "\n", `cat $login_file`;
foreach my $test (@tests) {
    my ($host, $user, $password) = split ':', $test;
    
    if (! grep /^$host$/, @hosts) { next } 
    print "Connect $user to $host\t";
    my $connect = "mysql -u $user -h $host -p$password";

    if (!$password) { print "NO PWD\n" }
    else {
        my $ok = `$connect -e 'select 123'`;
        my $test = "[TEST: $connect]";
        if ($ok =~ /123/xms) { 
            print "ok  $test\n";
            $Users{$host}++;
        }
        else { 
            print "FAILED [TEST: $connect]\n";
            push @{$Failed{$host}}, $user;

            if ($fix =~/y/i) {
                my $char = Prompt_Input('c',"Reset mysql.user password ?");
                if ($char =~/y/i) { reset_password($host, $user, $password) }
            }
        }
    }
}

print "\n\nSummary\n*****************\n";
foreach my $host (@hosts) {
    print "*** $host *** \t$Users{$host} USERS VALIDATED\n";
    if ($Failed{$host}) {
        print "FAILED User Connections: ";
        print "\n\t* ";
        print join "\n\t* ", @{$Failed{$host}};
        print "\n";
    }
}

exit;

#####################
sub reset_password {
#####################
    my $host = shift;
    my $user = shift;
    my $password = shift;
   
    my $admin_pwd = Prompt_Input('string', 'Enter aldente_admin password for access');
    my $reset = "UPDATE mysql.user SET Password = Password('$password') WHERE User = '$user'";
    print "\n$reset\n";
    my $ok = `mysql -u aldente_admin -h $host -p$admin_pwd -e "$reset"`;
    return;
}

    
