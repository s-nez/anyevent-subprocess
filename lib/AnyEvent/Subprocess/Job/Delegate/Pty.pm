package AnyEvent::Subprocess::Job::Delegate::Pty;
use IO::Pty;
use namespace::autoclean;

use Moose;
use POSIX qw(dup2);

with 'AnyEvent::Subprocess::Job::Delegate';

has 'pty' => (
    is         => 'ro',
    isa        => 'IO::Pty',
    lazy_build => 1,
);

has 'slave_pty' => (
    is         => 'ro',
    lazy_build => 1,
);

has 'handle' => (
    is         => 'ro',
    isa        => 'AnyEvent::Subprocess::Handle',
    lazy_build => 1,
);

has 'handle_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
    default  => sub {
        require AnyEvent::Subprocess::Handle;
        return 'AnyEvent::Subprocess::Handle';
    },
);

sub __build_handle {
    my ($self, $fh, @rest) = @_;
    return $self->handle_class->new( fh => $fh, @rest );
}

has 'run_delegate_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
    default => sub {
        require AnyEvent::Subprocess::Running::Delegate::Handle;
        return 'AnyEvent::Subprocess::Running::Delegate::Handle';
    },
);

sub _build_pty {
    return IO::Pty->new;
}

sub _build_slave_pty {
    my $self = shift;
    return $self->pty->slave;
}

sub _build_handle {
    my $self = shift;

    return $self->__build_handle(
        $self->pty,
        _direction => 'rw',
        _name      => 'parent pty handle: '. $self->name,
    );
}

sub build_run_delegates {
    my $self = shift;
    return $self->run_delegate_class->new(
        name      => $self->name,
        direction => 'rw',
        handle    => $self->handle,
    );
}

sub parent_finalize_hook {
    my $self = shift;
    $self->pty->close_slave;
    #$self->pty->make_slave_controlling_terminal;
}

sub child_setup_hook {
    my $self = shift;

    $self->handle->do_not_want;

    AnyEvent::Util::fh_nonblocking $self->slave_pty, 0;

    dup2( fileno($self->slave_pty), fileno(\*STDIN) ) or confess $!;
    dup2( fileno($self->slave_pty), fileno(\*STDOUT) ) or confess $!;
    dup2( fileno($self->slave_pty), fileno(\*STDERR) ) or confess $!;
}

sub build_code_args {}
sub child_finalize_hook {}
sub parent_setup_hook {}

1;
