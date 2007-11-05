######################################################################
# Test suite for X10::Home
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use X10::Home;
use Test::More;
use File::Temp qw(tempfile);

plan tests => 3;

SKIP: {
  skip "No /dev/ttyS0 found", 3 unless -e "/dev/ttyS0";

  my $eg = "eg";
  $eg = "../eg" unless -d $eg;
  
  my $x = X10::Home->new(
      conf_file => "$eg/x10.conf"
  );
  
  my($fh, $filename) = tempfile(UNLINK => 1);
  
  my $pid;
  
  foreach my $i (1..3) {
  
      if(!defined ($pid = fork())) {
          die "fork error";
      } elsif($pid == 0) {
          critical($i);
          exit 0;
      } else {
      }
  }
  
  while(wait() > 0) { ; }
  
  close $fh;
  open F, "<$filename" or die "Cannot open $filename";
  
  for (1..3) {
      my $first  = <F>;
      my $second = <F>;
      is($first, $second, "in/out sequence");
  }
  
  close F;
  
  sub critical {
      my $number = shift;
  
      $x->lock();
      syswrite $fh, "$number\n";
      select undef, undef, undef, .1;
      syswrite $fh, "$number\n";
      $x->unlock();
  }
}
