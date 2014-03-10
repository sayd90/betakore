#########################################################################
#  OpenKore - Teleport task
#  Copyright (c) 2007 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Teleport base task
package Task::Teleport;

use strict;
use Modules 'register';
use Time::HiRes qw(time);
use Scalar::Util;
use Carp::Assert;

use Task::WithSubtask;
use base qw(Task::WithSubtask);
use Globals qw($net $char %timeout);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_, autostop => 1, autofail => 1, mutexes => ['teleport']);
	$self->{emergency} = $args{emergency};
	$self->{retry}{timeout} = $timeout{ai_teleport_retry}{timeout} || 0.5;
	$self->{giveup}{timeout} = $args{giveupTime} || 3;
	
	my @holder = ($self);
	Scalar::Util::weaken($holder[0]);
	$self->{hooks} = Plugins::addHooks(
		['Network::Receive::map_changed', \&mapChange, \@holder],
		#['Network::Receive::map_change', \&mapChange, \@holder],
	);
	return $self;
}

sub DESTROY {
	my ($self) = @_;
	#Plugins::delHooks($self) if $self->{mapChangedHook};
	#Plugins::delHook($self->{mapChangeLocalHook}) if $self->{mapChangeLocalHook};
	#Plugins::delHook($self->{textHook}) if $self->{textHook};
	$self->SUPER::DESTROY();
}

sub activate {
	my ($self) = @_;
	$self->SUPER::activate();
}

sub interrupt {
	my ($self) = @_;
	$self->SUPER::interrupt();
} 

sub resume {
	my ($self) = @_;
	$self->SUPER::resume();
}

sub iterate {
	my ($self) = @_;
	return if (!$self->SUPER::iterate() || $net->getState() != Network::IN_GAME);
	if ($self->{mapChange}) {
		$self->setDone();
	}
}

sub mapChange {
	my (undef, undef, $holder) = @_;
	my $self = $holder->[0];
	$self->{mapChange} = 1;
}

1;