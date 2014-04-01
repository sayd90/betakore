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
		'0920', '089D', '0936', '0918', '0924', '0887', '0882', '0875', '0937', '0923', 
		'0963', '0868', '0436', '07E4', '0928', '0940', '0893', '0954', '095D', '0360', 
		'0364', '0942', '0872', '0811', '022D', '085D', '08A7', '0869', '0943', '08A3', 
		'092E', '0922', '087F', '08AC', '0877', '085E', '08A4', '094E', '08A0', '0890', 
		'0959', '089E', '0363', '0967', '096A', '08A1', '0367', '089A', '0891', '0919', 
		'092B', '0955', '0867', '0953', '0819', '087A', '0879', '0939', '086D', '085C', 
		'087B', '0931', '08A8', '0941', '091A', '0944', '0946', '08A9', '035F', '0889', 
		'0895', '0965', '0951', '0802', '0870', '086F', '0817', '094A', '086C', '0896', 
		'0897', '08AB', '0899', '0961', '0962', '093B', '0863', '094D', '091C', '0933', 
		'094B', '0815', '093C', '0281', '0957', '0888', '083C', '0883', '0917', '0202', 
		'088B', '0362', '0926', '0368', '0950', '0925', '091B', '0935', '0968', '0365', 
		'0966', '0437', '0873', '0945', '0932', '0862', '087D', '07EC', '0929', '095F', 
		'0871', '0960', '0838', '0361', '093D', '0860', '087E', '02C4', '0438', '088F', 
		'0884', '091E', '0366', '093E', '0938', '0927', '0874', '0885', '0948', '023B', 
		'08A6', '0861', '08A5', '0952', '092C', '0866', '093A', '0921', '095E', '0969', 
		'0878', '0881', '095B', '0835', '093F', '095A', '0865', '0369', '0876', '085F', 
		'092A', '087C', '0898', '085B', '092D', '089C', '092F', '0892'
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