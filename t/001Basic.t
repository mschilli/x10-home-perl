######################################################################
# Test suite for X10::Home
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Test::More;
use X10::Home;

plan tests => 1;

SKIP: {
  skip "No /dev/ttyS0 found", 1 unless -e "/dev/ttyS0";

  my $eg = "eg";
  $eg = "../eg" unless -d $eg;

  my $x10 = X10::Home->new(
      conf_file => "$eg/x10.conf"
  );
  
  is($x10->{receivers}->{'office_lights'}->{code}, "K10", "Receiver Code");
} 
