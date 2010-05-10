
# detections based on destination callsign

use Test;

our @tests;

BEGIN {
	@tests = (
		[ 'APZMDR', 'Open Source', 'HaMDR', undef, ],
		[ 'APOTC1', 'Argent Data Systems', 'OpenTracker', undef, ],
		[ 'AP123U', 'Painter Engineering', 'uSmartDigi Digipeater', undef, ],
	);
	
	plan tests => ($#tests+1) * 4;
};

use Ham::APRS::FAP qw(parseaprs);
use Ham::APRS::DeviceID qw(identify);

my $srccall = "OH7LZB";
my $body = "!I0-X;T_Wv&{-Aigate testing";

foreach my $test (@tests) {
	my($dstcall, $vendor, $model, $version) = @$test;
	
	#warn "test $dstcall\n";
	
	my $header = "$srccall>$dstcall,TCPIP*,qAC,FOURTH";
	my $aprspacket = "$header:$body";
	
	my %h;
	my $retval = parseaprs($aprspacket, \%h);
	ok($retval, 1, "failed to parse a packet with dstcall of $dstcall");
	
	my $success = identify(\%h);
	ok(defined $h{'deviceid'}, 1, "device identification failed with dstcall of $dstcall");
	ok($h{'deviceid'}{'vendor'}, $vendor, "wrong vendor for dstcall $dstcall");
	ok($h{'deviceid'}{'model'}, $model, "wrong model for dstcall $dstcall");
}
