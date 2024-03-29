#########################################################################
#  OpenKore - Packet Receiveing
#  This module contains functions for Receiveing packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO
# See http://subversion.assembla.com/svn/ClientSide/Packets/Packet_db/packets_2011-08-16aRagexeRE.txt

package Network::Receive::kRO::RagexeRE_2011_08_16a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2010_11_24a);
use Globals qw(%items_lut %timeout %charSvrSet);
use Log qw(debug);
use Misc qw(center);
use Translation;
use Utils qw(formatNumber swrite);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		#'08B9' => ['account_id', 'x4 a4 x2', [qw(accountID)]], # 12
		'08B9' => ['login_pin_code_request', 'V a4 v', [qw(seed accountID flag)]],
		'08CA' => ['cashitem', 'v3 a*', [qw(len amount tabcode itemInfo)]],#-1
		'082D' => ['received_characters_info', 'x2 C5 x20 a*', [qw(normal_slot premium_slot billing_slot producible_slot valid_slot charInfo)]],
		
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}
	my %handlers = qw(
		account_id 08B9
	);
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	return $self;
}

sub received_characters_info {
	my ($self, $args) = @_;

	$charSvrSet{normal_slot} = $args->{normal_slot} if (exists $args->{normal_slot});
	$charSvrSet{premium_slot} = $args->{premium_slot} if (exists $args->{premium_slot});
	$charSvrSet{billing_slot} = $args->{billing_slot} if (exists $args->{billing_slot});
	$charSvrSet{producible_slot} = $args->{producible_slot} if (exists $args->{producible_slot});
	$charSvrSet{valid_slot} = $args->{valid_slot} if (exists $args->{valid_slot});

	$timeout{charlogin}{time} = time;
}
my %cashitem_tab = (
	0 => 'New',
	1 => 'Stock',
	2 => 'Rent',
	3 => 'Caps',
	4 => 'Potions',
	5 => 'Scrolls',
	6 => 'Decoration',
	7 => 'Expense',
);

sub cashitem {
	my ($self, $args) = @_;
	my $tabcode = $args->{tabcode};
	my $jump = 6;
	my $unpack_string  = "v V";
	debug TF("%s\n" .
		"#   Name                               Price\n",
		center(' Tab: ' . $cashitem_tab{$tabcode} . ' ', 44, '-')), "list";
	for (my $i = 0; $i < length($args->{itemInfo}); $i += $jump) {
		my ($ID, $price) = unpack($unpack_string, substr($args->{itemInfo}, $i));
		my $name = $items_lut{$ID};
		debug(swrite(
			"@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>C",
			[$i, $name, formatNumber($price)]),
			"list");

		}
}

1;

=pod
//2011-08-16aRagexeRE
0x01FD,15,repairitem,2
0x023B,26,friendslistadd,2
0x0361,5,hommenu,2:4
0x088F,36,storagepassword,0
0x0288,-1,cashshopbuy,4:8
0x0802,26,partyinvite2,2
0x022D,19,wanttoconnection,2:6:10:14:18
0x0369,7,actionrequest,2:6
0x083C,10,useskilltoid,2:4:6
0x0439,8,useitem,2:4
0x0281,-1,itemlistwindowselected,2:4:8
0x0365,18,bookingregreq,2:4:6
0x0803,4
0x0804,14,bookingsearchreq,2:4:6:8:12
0x0805,-1
0x0806,2,bookingdelreq,0
0x0807,4
0x0808,14,bookingupdatereq,2
0x0809,50
0x080A,18
0x080B,6
0x0815,-1,reqopenbuyingstore,2:4:8:9:89
0x0817,2,reqclosebuyingstore,0
0x0360,6,reqclickbuyingstore,2
0x0811,-1,reqtradebuyingstore,2:4:8:12
0x0819,-1,searchstoreinfo,2:4:5:9:13:14:15
0x0835,2,searchstoreinfonextpage,0
0x0838,12,searchstoreinfolistitemclick,2:6:10
0x0437,5,walktoxy,2
0x035F,6,ticksend,2
0x0202,5,changedir,2:4
0x07E4,6,takeitem,2
0x0362,6,dropitem,2:4
0x07EC,8,movetokafra,2:4
0x0364,8,movefromkafra,2:4
0x0438,10,useskilltopos,2:4:6:8
0x0366,90,useskilltoposinfo,2:4:6:8:10
0x08AD,6,getcharnamerequest,2
0x0368,6,solvecharname,2 
=cut