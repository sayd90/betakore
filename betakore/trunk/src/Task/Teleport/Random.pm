#########################################################################
#  OpenKore - Teleport Random task
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
# MODULE DESCRIPTION: Teleport Random task
package Task::Teleport::Random;

use strict;
use Modules 'register';
use base qw(Task::Teleport);
use Globals qw($net $char $messageSender $taskManager $accountID %timeout);
use AI;
use Task::UseSkill;
use Task::ErrorReport;

use enum qw(
	STARTING
	USE_TELEPORT
	WAITING_FOR_WARPLIST
	WAITING_FOR_MAPCHANGE
);

use enum qw(
	SKILL
	ITEM
	CHAT
);


sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);
	my @holder = ($self);
	Scalar::Util::weaken($holder[0]);
	$self->{useSkill} = $args{useSkill};
	$self->{hooks} = Plugins::addHooks(
		['packet/warp_portal_list', sub { $holder[0]->{portal_list} = 1 }],
	);
	$self->{state} = STARTING;
	return $self;
}

sub iterate {
	my $self = shift;
	$self->SUPER::iterate();
	if ($self->{state} == STARTING) {
		if ($self->{useSkill} && !$char->{muted}) {
			if ($char->{skills}{AL_TELEPORT}) {
				$self->{method} = SKILL;
			} elsif (Actor::Item::scanConfigAndCheck('teleportAuto_equip')) {
				Actor::Item::scanConfigAndEquip('teleportAuto_equip');
			}
		} else {
			$self->{item} = $char->inventory->getByNameID(601) || $char->inventory->getByNameID(12323);
			if ($self->{item}) {
				$self->{method} = ITEM;
			}
		}
		$self->{state} = USE_TELEPORT;
	} elsif ($self->{state} == USE_TELEPORT) {
		if ($self->{method} == SKILL) {
			if (defined AI::findAction('attack')) {
				AI::clear("attack");
				$char->sendAttackStop;
			}
			my $skill = new Skill(handle => 'AL_TELEPORT');
			my $skillTask = new Task::UseSkill(
				actor => $skill->getOwner,
				skill => $skill,
				priority => Task::USER_PRIORITY
			);
			my $task = new Task::ErrorReport(task => $skillTask);
			$self->setSubtask($task);
			
			$self->{state} = WAITING_FOR_WARPLIST;
		} elsif ($self->{method} == ITEM) {
			$messageSender->sendItemUse($self->{item}->{index}, $accountID);
			$self->{state} = WAITING_FOR_MAPCHANGE;
		} else {
			# error
		}
	} elsif ($self->{state} == WAITING_FOR_WARPLIST && $self->{portal_list}) {
		$messageSender->sendWarpTele(26, "Random");
		$self->{state} = WAITING_FOR_MAPCHANGE;
	}
}

1;