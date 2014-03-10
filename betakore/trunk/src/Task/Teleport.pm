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
use Globals qw($net %config $char $messageSender $taskManager $accountID %timeout);
use Utils qw(timeOut);
use Utils::Exceptions;

use AI;
use Task::UseSkill;
use Task::ErrorReport;

use Log qw(debug);

use enum qw(
	STARTING
	USE_TELEPORT
	WAITING_FOR_WARPLIST
	GOT_WARP_LIST
	WAITING_FOR_MAPCHANGE
);

use enum qw(
	SKILL
	ITEM
	CHAT
);

use enum qw(
	RANDOM
	RESPAWN
);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_, autostop => 0, autofail => 0, mutexes => ['teleport']);
	$self->{emergency} = $args{emergency};
	# $self->{retry}{timeout} = $timeout{ai_teleport_retry}{timeout} || 0.5; unused atm
	$self->{type} = $args{type};
	$self->{respawnMap} = $args{respawnMap} || $config{saveMap} || 'prontera';
	$self->{respawnMap} = $self->{respawnMap}.'.gat';
	if ($self->{type} == RANDOM) {
		$self->{useSkill} = $args{useSkill} || $config{teleportAuto_useSkill} || 1;
	} elsif ($self->{type} == RESPAWN) {
		$self->{useSkill} = $args{useSkill} || !$config{teleportAuto_useItemForRespawn} || 1;
	} else {
		ArgumentException->throw(sprintf("Unknown teleport type value %s.", $self->{type}));
	}
	
	$self->{emergency} = $args{emergency};
	
	
	my @holder = ($self);
	Scalar::Util::weaken($holder[0]);
	$self->{hooks} = Plugins::addHooks(
		['Network::Receive::map_changed', \&mapChange, \@holder], 
		['packet/warp_portal_list', \&warpPortalList, \@holder]
	);
	debug "Starting Teleport Task \n", 'teleport';
	return $self;
}

sub warpPortalList {
	my (undef, undef, $holder) = @_;
	my $self = $holder->[0];
	$timeout{ai_teleport_delay}{time} = time;
	$self->{state} = GOT_WARP_LIST;
	$self->{portal_list} = 1
}

sub DESTROY {
	my ($self) = @_;
	Plugins::delHooks($self->{hooks}) if $self->{hooks};
	$self->SUPER::DESTROY();
}

sub activate {
	my ($self) = @_;
	$self->{state} = STARTING;
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
	if ($self->{type} == RANDOM) {
		teleport_random(@_);
	} elsif ($self->{type} == RESPAWN) {
		teleport_respawn(@_);
	}
}

sub teleport_respawn {
	my ($self) = @_;
	if ($self->{mapChange}) {
		$self->setDone();
	} elsif ($self->{state} == GOT_WARP_LIST && (timeOut($timeout{ai_teleport_delay}) || $self->{emergency})) {
		$messageSender->sendWarpTele(26, $self->{respawnMap});
		$self->{state} = WAITING_FOR_MAPCHANGE;
	} elsif ($self->{state} == STARTING) {
		if ($self->{useSkill} && !$char->{muted}) {
			if ($char->{skills}{AL_TELEPORT}) {
				$self->{method} = SKILL;
				$self->{state} = USE_TELEPORT;
			} else {
				# TODO: check if something needs to be equipped
				# fallback to ITEM method
				$self->{method} = ITEM;
			}
		} else {
			$self->{item} = $char->inventory->getByNameID(602) || $char->inventory->getByNameID(12324);
			if ($self->{item}) {
				$self->{method} = ITEM;
				$self->{state} = USE_TELEPORT;
			} else {
				# exit and throw error
			}
		}	
	} elsif ($self->{state} == USE_TELEPORT) {
		if ($self->{method} == SKILL) {
			if (!$self->getSubtask() && (!$self->{skillTask})) {
				my $skill = new Skill(handle => 'AL_TELEPORT', level => 2);
				my $task = new Task::UseSkill (
					actor => $skill->getOwner,
					skill => $skill,
				);
				$self->setSubtask($task);
				$self->{skillTask} = $task;
			}
			if (!$self->getSubtask() && !$self->{skillTask}->getError()) {
				# success
				$self->{state} = WAITING_FOR_WARPLIST;
			} elsif (!$self->getSubtask() && $self->{skillTask}->getError()) {
				undef $self->{skillTask}; # retry
			}
		} elsif ($self->{method} == ITEM) {
			$messageSender->sendItemUse($self->{item}->{index}, $accountID);
			$self->{state} = WAITING_FOR_MAPCHANGE;
		}
	}
}

sub teleport_random {
	my ($self) = @_;
	if ($self->{mapChange}) {
		$self->setDone();
	} elsif ($self->{state} == GOT_WARP_LIST && (timeOut($timeout{ai_teleport_delay}) || $self->{emergency})) {
		$messageSender->sendWarpTele(26, "Random");
		$self->{state} = WAITING_FOR_MAPCHANGE;
	} elsif ($self->{state} == STARTING) {
		if ($self->{useSkill} && !$char->{muted}) {
			if ($char->{skills}{AL_TELEPORT}) {
				$self->{method} = SKILL;
				$self->{state} = USE_TELEPORT;
			} elsif (!$self->{fallback}) {
				# TODO: check if something needs to be equipped
				# fallback to ITEM method
				$self->{fallback} = 1;
				$self->{method} = ITEM;
			} else {
				# fail and throw error
			}
		} else {
			$self->{item} = $char->inventory->getByNameID(601) || $char->inventory->getByNameID(12323);
			if ($self->{item}) {
				$self->{method} = ITEM;
				$self->{state} = USE_TELEPORT;
			} elsif (!$self->{fallback}) {
				$self->{fallback} = 1;
				$self->{method} = SKILL;
			} else {
				# fail and throw error
			}
		}	
	} elsif ($self->{state} == USE_TELEPORT) {
		if ($self->{method} == SKILL) {
			if (!$self->getSubtask() && (!$self->{skillTask})) {
				my $skill = new Skill(handle => 'AL_TELEPORT', level => 1);
				my $task = new Task::UseSkill (
					actor => $skill->getOwner,
					skill => $skill,
				);
				$self->setSubtask($task);
				$self->{skillTask} = $task;
			}
			if (!$self->getSubtask() && !$self->{skillTask}->getError()) {
				# success
				$self->{state} = WAITING_FOR_WARPLIST;
			} elsif (!$self->getSubtask() && $self->{skillTask}->getError()) {
				undef $self->{skillTask}; # retry
			}
		} elsif ($self->{method} == ITEM) {
			$messageSender->sendItemUse($self->{item}->{index}, $accountID);
			$self->{state} = WAITING_FOR_MAPCHANGE;
		}
	}
}

sub mapChange {
	my (undef, undef, $holder) = @_;
	my $self = $holder->[0];
	$self->{mapChange} = 1;
}

1;