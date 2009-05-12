package Log::UDP::Server;
use MooseX::POE;
with 'Data::Serializable';

use constant DATAGRAM_MAXLEN => 8192;

use IO::Socket::INET ();

=head1 NAME

Log::UDP::Server - a simple way to receive and handle structured messages via UDP

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Log::UDP::Server;

    my $server = Log::UDP::Server->new( handler => sub { warn( $_[0] ); } );
    $server->run();

=head1 DESCRIPTION

This module enables you to receive a message (simple string or complicated object)
over a UDP socket. An easy way to send a structured message is to use Log::UDP::Client.
The message received will automatically be handled by the specified callback.

=head1 EXPORT

This is an object-oriented module. It has no exports.

=cut

=head1 CLASS FIELDS

=head2 handler

The handler that is used to process each message as it is received.

=cut

has 'handler' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

=head2 server_address

The address you want to listen on.

=cut

has 'server_address' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '127.0.0.1'; },
);

=head2 server_port

The port you want to listen on.

=cut

has 'server_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 9999; },
);

=head2 server_socket

The listening socket used for communication.

=cut

has 'server_socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET',
    lazy => 1,
    builder => '_build_server_socket',
);

sub _build_server_socket {
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

=head1 FUNCTIONS

=head2 new

Instantiates a new server with the specified message handler.

=cut

=head2 run

Starts the server and listens for incoming datagrams on the specified socket.

=cut

sub run {
    POE::Kernel->run();
}

sub START {
    my ($self) = @_;
    POE::Kernel->select_read( $self->server_socket, "get_datagram" );
}

event get_datagram => sub {
    my ($self) = @_;

    my $remote_address = recv( $self->server_socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

    my ( $peer_port, $peer_addr ) = IO::Socket::INET::unpack_sockaddr_in($remote_address);
    my $human_addr = IO::Socket::INET::inet_ntoa($peer_addr);

    # Deserialize and call handler
    $self->handler->(
        $self->deserialize($message)
    );
};

=head1 INHERITED METHODS

=over

=item deserialize

=item deserializer

=item serialize

=item serializer

=item serializer_module

=item throws_exception

=back

All of these methods are inherited from L<Data::Serializable>. Read more about them there.

=cut

=head1 AUTHOR

Robin Smidsrød, C<< <robin at smidsrod.no> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-udp-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-UDP-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::UDP::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-UDP-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-UDP-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-UDP-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-UDP-Server/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robin Smidsrø.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Log::UDP::Server
