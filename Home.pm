###########################################
package X10::Home;
###########################################

use strict;
use warnings;
use YAML qw(LoadFile);
use Log::Log4perl qw(:easy);
use Device::SerialPort;

our $VERSION = "0.01";

my @CONF_PATHS = (
    glob("~/.x10.conf"),
    "/etc/x10.conf",
);
my $CONF_FILE = "x10.conf";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        conf_paths => \@CONF_PATHS,
        conf_file  => undef,
        commands   => {
          on     => "J",
          off    => "K",
          status => undef,
        },
        %options,
    };

    bless $self, $class;

    $self->init();

    return $self;
}

###########################################
sub init {
###########################################
    my($self) = @_;

    if(defined $self->{conf_file}) {
        $self->{conf} = LoadFile( $self->{conf_file} );
    } else {
        for my $path (@{ $self->{conf_paths} }) {
            my $full = "$path/$CONF_FILE";
            if(-f $full) { 
                $self->{conf} = LoadFile( $full );
            }
        }
    }

    LOGDIE "No configuration file found (searched ", 
           join (", ", @{ $self->{conf_paths} }), 
           ")" unless defined $self->{conf};

    $self->{conf}->{device}   ||= "/dev/ttyS0";
    $self->{conf}->{module}   ||= "ControlX10::CM11";
    $self->{conf}->{baudrate} ||= 4800;

    eval "require $self->{conf}->{module}";

    $self->{serial} = Device::SerialPort->new(
        $self->{conf}->{device}, undef);

    $self->{serial}->baudrate($self->{conf}->{baudrate});

    $self->{receivers} = {
        map { $_->{name} => $_ } @{$self->{conf}->{receivers}} };

    1;
}

###########################################
sub send {
###########################################
    my($self, $receiver, $cmd) = @_;

    if(! exists $self->{receivers}->{$receiver}) {
        ERROR "Unknown receiver '$receiver'";
        return undef;
    }

    if(! exists $self->{commands}->{$cmd}) {
        ERROR "Unknown command '$cmd'";
        return undef;
    }

    my($house_code, $unit_code) = split //,
        $self->{receivers}->{$receiver}->{code}, 2;

    my $send = "$self->{conf}->{module}" . "::" . "send";

    no strict 'refs';

    DEBUG "Addressing HC=$house_code UC=$unit_code";
    $send->($self->{serial}, $house_code . $unit_code);

    DEBUG "Sending command $cmd $self->{commands}->{$cmd}";
    $send->($self->{serial},
                  $house_code .
                  $self->{commands}->{$cmd});

    1;
}

1;

__END__

=head1 NAME

X10::Home - Configure X10 for your Home

=head1 SYNOPSIS

    # /etc/x10.conf Configuration File
    module: ControlX10::CM11
    device: /dev/ttyS0
    receivers:  
      - name: bedroom_lights
        code: K15
        desc: Bedroom Lights

    use X10::Home;
    my $x10->X10::Home->new();
      # Address services by name
    $x10->send("bedroom_lights", "on");

=head1 DESCRIPTION

C<X10::Home> lets you set parameters of all your home X10 devices in a
single configuration file. After that's done, applications can access
them by name and without worrying about details like "house codes",
"unit codes", "serial ports", X10 commands and other low-level details.

For example, to switch the bedroom lights on, simply use

    use X10::Home;
    my $x10->X10::Home->new();
    $x10->send("bedroom_lights", "on");

and

    $x10->send("bedroom_lights", "off");

to switch them off again.

C<X10::Home> uses the C<ControlX10::CM11> or C<ControlX10::CM17> CPAN
modules under the hood to send actual X10 commands via the
computer's serial port.

=head2 Configuration File

Upon initialization, C<X10::Home> will search a configuration file
in the following locations (in the order listed):

=over 4

=item *

If C<X10::Home::new()> gets called with the C<conf_file> parameter
set, the configuration will be read from C<conf_file>.

=item * 

C<~/.x10.conf> (in the user's local home directory) if present

=item *

C</etc/x10.conf> if present

=back

The configuration file is written in YAML format and looks like this:

    # /etc/x10.conf Configuration File

    module:   ControlX10::CM11
    device:   /dev/ttyS0
    baudrate: 4800

    receivers:  
      - name: bedroom_lights
        code: K15
        desc: Bedroom Lights
      - name: living_room_lights
        code: K16
        desc: Living Room Lights

The C<module> parameter specifies which X10 low-level module
to use C<ControlX10::CM11> or C<ControlX10::CM17>, it defaults
to C<ControlX10::CM11>.

The C<device> parameter specifies the device entry of the serial port 
to use, it defaults to C</dev/ttyS0>. This can be C</dev/ttyS4> or
C</dev/ttyS5> if a serial PCI card gets plugged into the computer.

The C<baudrate> is the baud rate to be used to communicate over the serial 
port. It defaults to 4800.

The C<receivers> parameter specifies an array of receivers. The reason
why this is an array an not a hash is that certain applications like to
display all available receivers in a predefined order. Receivers are
hashed internally by C<X10::Home> for quick lookups, though.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>
