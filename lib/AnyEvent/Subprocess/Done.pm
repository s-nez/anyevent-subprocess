package AnyEvent::Subprocess::Done;
use Moose;

use AnyEvent::Subprocess::Types qw(DoneDelegate);

with 'AnyEvent::Subprocess::Role::WithDelegates' => {
    type => DoneDelegate,
};

# $? is the exit_status, the argument to exit ("exit 0") is exit_value
# if the process was killed, exit_signal contains the signal that killed it
has 'exit_status' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'dumped_core' => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has [qw[exit_value exit_signal]] => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_exit_value {
    my $self = shift;
    return $self->exit_status >> 8;
}

sub _build_exit_signal {
    my $self = shift;
    return $self->exit_status & 127;
}

sub _build_dumped_core {
    my $self = shift;
    return $self->exit_status & 128;
}

1;

__END__

=head1 NAME

AnyEvent::Subprocess::Done - represents a completed subprocess run

=head1 SYNOPSIS

We are C<$done> in a sequence like:

   my $job = AnyEvent::Subprocess->new ( ... );
   my $run = $job->run;
   $run->delegate('stdin')->push_write('Hello, my child!');
   say "Running child as ", $run->child_pid;
   $run->kill(11) if $you_enjoy_that_sort_of_thing;
   my $done = $job->delegate('completion_condvar')->recv;
   say "Child exited with signal ", $done->exit_signal;
   say "Child produced some stdout: ",
       $done->delegate('stdout_capture')->output;

=head1 DESCRIPTION

An instance of this class is returned to your C<on_completion>
callback when the child process exists.

=head1 METHODS

=head2 delegate( $name )

Returns the delegate named C<$name>.

=head2 exit_status

C<$?> from waitpid on the child.  Parsed into the various fields
below:

=head2 exit_value

The value the child supplied to C<exit>.  (0 if "C<exit 0>", etc.)

=head2 exit_signal

The signal number the child was killed by, if any.

=head2 dumped_core

True if the child dumped core.

=head1 SEE ALSO

L<AnyEvent::Subprocess>

L<AnyEvent::Subprocess::Role::WithDelegates>

