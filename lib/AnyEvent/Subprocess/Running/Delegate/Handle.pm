package AnyEvent::Subprocess::Running::Delegate::Handle;
use AnyEvent::Subprocess::Handle;

use MooseX::Types::Moose qw(Str);
use AnyEvent::Subprocess::Types qw(Direction);
use namespace::autoclean;

use Moose;
with 'AnyEvent::Subprocess::Running::Delegate';

has 'direction' => (
    is            => 'ro',
    isa           => Direction,
    required      => 1,
    documentation => 'r when parent reads a pipe, w when parent writes to a pipe, rw for a socket',
);

has 'handle' => (
    is       => 'ro',
    isa      => 'AnyEvent::Subprocess::Handle',
    required => 1,
);

sub build_events {
    my $self = shift;

    if( $self->direction eq 'r' ){
        return $self->name;
    }

    return;
}

sub build_done_delegates {}
sub completion_hook {} # destroy handle?

sub BUILD {
    my ($self) = @_;

    if($self->direction eq 'r'){
        $self->handle->eof_condvar->cb(
            $self->event_sender_for($self->name),
        );
    }
}

1;
