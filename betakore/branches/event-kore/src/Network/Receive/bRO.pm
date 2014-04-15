#############################################################################
#  OpenKore - Network subsystem												#
#  This module contains functions for sending messages to the server.		#
#																			#
#  This software is open source, licensed under the GNU General Public		#
#  License, version 2.														#
#  Basically, this means that you're allowed to modify and distribute		#
#  this software. However, if you distribute modified versions, you MUST	#
#  also distribute the source code.											#
#  See http://www.gnu.org/licenses/gpl.html for the full license.			#
#############################################################################
# bRO (Brazil)
package Network::Receive::bRO;
use strict;
use Log qw(warning);
use base 'Network::Receive::ServerType0';


# Sync_Ex algorithm developed by Fr3DBr

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0097' => ['private_message', 'v Z24 V Z*', [qw(len privMsgUser flag privMsg)]], # -1
	);
	
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
		'0871', '08A0', '07E4', '094A', '0899', '0949', '091B', '0943', '0946', '095B', 
		'089B', '096A', '08AC', '0895', '0919', '0893', '0364', '08AB', '0938', '0865', 
		'094B', '0931', '093B', '0928', '0873', '092E', '0921', '083C', '095C', '085B', 
		'095F', '089F', '0862', '091F', '085D', '08A2', '0939', '087E', '086C', '088D', 
		'0933', '0861', '08A4', '08A3', '08AD', '022D', '092A', '085E', '0884', '0942', 
		'089A', '091A', '0945', '093A', '094D', '0960', '092B', '08A7', '088F', '08AA', 
		'0878', '0366', '094F', '0951', '0963', '095D', '085F', '0815', '086A', '02C4', 
		'08A8', '0927', '0363', '092F', '0969', '086E', '0953', '088A', '0885', '0920', 
		'0890', '091E', '0877', '0879', '0941', '0964', '0892', '0959', '035F', '086F', 
		'0874', '0835', '085C', '092D', '0864', '0935', '087C', '094E', '0962', '093F', 
		'0929', '0438', '0863', '0926', '088C', '085A', '0947', '0936', '086D', '0918', 
		'0817', '0880', '095A', '08A5', '08A6', '091D', '0876', '0940', '0281', '0948', 
		'0944', '0437', '0898', '088B', '0802', '087D', '0369', '0925', '0889', '0896', 
		'0923', '0968', '094C', '0937', '0867', '0868', '089E', '0950', '0958', '095E', 
		'0952', '0917', '0866', '0811', '0360', '0894', '0883', '0882', '0957', '0965', 
		'0870', '0869', '093D', '0436', '087B', '0922', '0362', '0897', '0368', '08A1', 
		'089D', '0956', '08A9', '0872', '088E', '0930', '0819', '0202'
	};
	
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	return $self;
}

sub items_nonstackable {
	my ($self, $args) = @_;

	my $items = $self->{nested}->{items_nonstackable};

	if($args->{switch} eq '00A4' || $args->{switch} eq '00A6' || $args->{switch} eq '0122') {
		return $items->{type4};
	} elsif ($args->{switch} eq '0295' || $args->{switch} eq '0296' || $args->{switch} eq '0297') {
		return $items->{type4};
	} elsif ($args->{switch} eq '02D0' || $args->{switch} eq '02D1' || $args->{switch} eq '02D2') {
		return  $items->{type4};
	} else {
		warning("items_nonstackable: unsupported packet ($args->{switch})!\n");
	}
}

*parse_quest_update_mission_hunt = *Network::Receive::ServerType0::parse_quest_update_mission_hunt_v2;
*reconstruct_quest_update_mission_hunt = *Network::Receive::ServerType0::reconstruct_quest_update_mission_hunt_v2;

1;