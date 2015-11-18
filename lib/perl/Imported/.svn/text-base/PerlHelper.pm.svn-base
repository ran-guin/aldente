package Imported::PerlHelper;

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(Printnl Writelog);

use Benchmark;
#use POSIX qw/strftime/;
use POSIX qw();
use File::Basename;
use strict;
use Fcntl ':flock'; # import LOCK_* constants

sub Date {

  my $arg = shift || ();
  my $date = "";
  my $time = "";
  if(defined $arg->{date}) {
    if($arg->{date}) {
      #@@@$date = strftime "%d-%m-20%y",localtime;
    }
  } else {
      #@@@$date = strftime "%d-%m-20%y",localtime;
  }
  if(defined $arg->{time}) {
    if($arg->{time}) {
      #@@@$time = strftime "%H:%M:%S",localtime;
    }
  }else{
    #@@@$time = strftime "%H:%M:%S",localtime;
  }
  my $sep = "";
  if($date ne "" && $time ne "") {
    $sep = " ";
  }
  return $date.$sep.$time;

}

sub Printnl {
  print @_;
  print "\n";
}

sub WriteLog {

  my $logfile = shift;
  my $line    = shift;
  my $header  = shift || '';
  my $flag    = shift || 'append';
  if($flag eq "append") {
    open(LOG,">>$logfile");
  } else {
    open(LOG,">$logfile");
  }
  flock(LOG,LOCK_EX);
  seek(LOG,0,2);
  print LOG "$header";
  print LOG $line;
  flock(LOG,LOCK_UN);
  close(LOG);

}

sub Mail {

  my $to  = shift;
  my $from   = shift;
  my $subject = shift;
  my $body = shift;
  my $MAILMAN = "/usr/lib/sendmail -t -n -f\"$from\"";
  open(POSTAL,"| $MAILMAN");
  print POSTAL "To: $to\n";
  print POSTAL "Subject: $subject\n";
  print POSTAL "\n";
  print POSTAL $body;
  close(POSTAL);
}


sub IsIn {

  my $value = shift;
  my @array = @_;
  my $elem;
  foreach $elem (@array) {
    if($value =~ /^$elem$/i) {
      return 1;
    }
  }
  return 0;

}

sub List {

  return join(", ",sort @_);

}

sub MonthNum {

  my $mon = shift;
  my @months = ("January","February","March","April","May","June","July","August","September","October","November","December");
  for(my $j=0;$j<@months;$j++) {
    if($months[$j] eq $mon) {
      return sprintf("%02d",$j+1);
    }
  }
  return 0;
}


sub PrintBenchmarkDiff {
  
  my $comment=shift;
  my $t0=shift;
  my $t1=shift;
  my $diff = timestr(timediff($t1,$t0));
  $diff =~ s/.*=\s*(.*?)\s*CPU.*/$1 sec/;
  print "<span class=vdarkblue> BENCH: $comment $diff</span><BR>";
}

sub ToBase36 {

  my $num    = shift;
  my $start  = shift || 65;
  my $unit   = $num%36;
  my $single = int($num/36);
  
  return chr($start+$unit).chr($start+$single);

}


sub FromBase36 {

  my $num    = shift;
  my $start  = shift || 65;
  print substr($num,1,1);
  my $unit   = ord(substr($num,0,1))-$start;
  my $single = ord(substr($num,1,1));
  print "$unit $single";
  return $single*36+$unit;

}

sub MakeInteger {

  my $array = shift;
  my $i;
  for($i=0;$i<@{$array};$i++) {
    $array->[$i] = int($array->[$i]);
  }
}

sub PrintFormFields {

  my $key;
  my $param = shift;
  print "<table border=0 cellspacing=0>";
  print "<tr><td class=darkred align=center><b>Field</td><td class=darkred align=center><b>Value</td></tr>";
  foreach $key (keys %{$param}) {
    print "<tr><td>";
    print "<span class=small><b>$key</b></span>";
    print "</td><td>";
    print "<span class=small>",$param->{$key},"</span>";
    print "</td></tr>";
  }
  print "</table>";
}


1;
