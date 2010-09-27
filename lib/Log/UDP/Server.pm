use strict;
use warnings;
use 5.006; # Found with Perl::MinimumVersion

package Log::UDP::Server;
use MooseX::POE;
with 'Data::Serializable' => { -version => '0.40.0' };

# ABSTRACT: A simple way to receive and handle structured messages via UDP

use IO::Socket::INET ();
use Readonly;

=constant $DATAGRAM_MAXLEN : Int

Maximum UDP packet size. Set to 8192 bytes.

=cut

Readonly::Scalar our $DATAGRAM_MAXLEN => 8192;

=attr handler : CodeRef

The handler that is used to process each message as it is received.

=cut

has 'handler' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

=attr server_address : Str

The address you want to listen on.

=cut

has 'server_address' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '127.0.0.1'; },
);

=attr server_port : Int

The port you want to listen on.

=cut

has 'server_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 9999; },
);

=attr server_socket : IO::Socket::INET

The listening socket used for communication.

=cut

has 'server_socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    builder => '_build_server_socket',
);

sub _build_server_socket { ## no critic qw(Subroutines::ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;

    # Create socket
    my $socket = IO::Socket::INET->new(
        Proto     => 'udp',
        LocalPort => $self->server_port,
        LocalAddr => $self->server_address,
    );

    # Croak on error
    unless ( $socket ) {
        die("Unable to bind to " . $self->server_address . ":" . $self->server_port . ": $!\n");
    }

    return $socket;
}

=method run

Starts the server and listens for incoming datagrams on the specified socket.

=cut

sub run {
    POE::Kernel->run();
    return 1; # OK
}

=method START

Initializes the C<get_datagram> event on C<server_socket>.

=cut

sub START {
    my ($self) = @_;
    POE::Kernel->select_read( $self->server_socket, "get_datagram" );
    return 1; # OK
}

=event get_datagram

Will execute the coderef in C<handler> with the deserialized message as the
first argument.

=cut

event get_datagram => sub {
    my ($self) = @_;

    my $remote_address = recv( $self->server_socket, my $message = "", $DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

    my ( $peer_port, $peer_addr ) = IO::Socket::INET::unpack_sockaddr_in($remote_address);
    my $human_addr = IO::Socket::INET::inet_ntoa($peer_addr);

    # Deserialize and call handler
    $self->handler->(
        $self->deserialize($message)
    );
};

1;

__END__

=head1 SYNOPSIS

    use Log::UDP::Server;

    my $server = Log::UDP::Server->new( handler => sub { warn( $_[0] ); } );
    $server->run();

=head1 DESCRIPTION

This module enables you to receive a message (simple string or complicated object)
over a UDP socket. An easy way to send a structured message is to use Log::UDP::Client.
The message received will automatically be handled by the specified callback.

=head1 INHERITED METHODS

=for :list
* deserialize
* deserializer
* serialize
* serializer
* serializer_module
* throws_exception

All of these methods are inherited from L<Data::Serializable>. Read more about them there.
