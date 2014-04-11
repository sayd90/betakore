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
		'094E', '089C', '0943', '091A', '089D', '094A', '0925', '0956', '08A4', '0819', 
		'0890', '086B', '0896', '02C4', '022D', '0363', '0802', '0868', '0879', '093A', 
		'088C', '0967', '087B', '093C', '0815', '08A6', '0886', '0893', '0961', '0369', 
		'0436', '0888', '0870', '087F', '0873', '0869', '0281', '091F', '089F', '088D', 
		'0367', '08A7', '0954', '093D', '0437', '095F', '07E4', '083C', '0899', '08AB', 
		'092F', '093B', '0862', '094B', '0885', '0892', '0935', '089E', '08A3', '08A9', 
		'0963', '0927', '08A0', '0938', '093E', '0937', '092A', '08AA', '0817', '0920', 
		'0948', '0951', '0360', '092D', '0898', '08A1', '086E', '0947', '0866', '094F', 
		'086F', '092E', '0945', '0864', '0926', '0932', '0928', '093F', '0929', '0202', 
		'0838', '0876', '085E', '0936', '08A8', '0918', '0944', '088A', '0953', '0865', 
		'0891', '095C', '0811', '085D', '0887', '085A', '0874', '0364', '0877', '0955', 
		'091D', '091E', '0924', '0889', '0968', '0878', '087D', '0867', '0362', '088F', 
		'094D', '088E', '08AC', '0882', '087C', '089A', '0942', '0894', '0941', '0438', 
		'088B', '0835', '085C', '087A', '0949', '0861', '0895', '035F', '094C', '023B', 
		'0930', '0923', '0946', '092B', '0959', '095D', '0366', '095E', '086A', '086D', 
		'0922', '0969', '085B', '0361', '0871', '0368', '0958', '0934', '0863', '0966', 
		'0952', '07EC', '0884', '0365', '08A2', '087E', '0860', '08AD'
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