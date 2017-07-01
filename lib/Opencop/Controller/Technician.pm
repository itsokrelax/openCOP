package Opencop::Controller::Technician;
use Mojo::Base 'Mojolicious::Controller';

sub dashboard{
	my $self = shift;

	$self->stash(
		js => ['/js/private/queue.js'],
		styles => ['/styles/private/queue.css'],
		queues => $self->ticket->queue_overview($self->session('user_id'))
	);
}
1;