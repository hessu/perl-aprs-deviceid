
# detections based on mic-e type codes

use Test;

our @tests;

BEGIN {
	@tests = (
		#[ '\`abc123Rtext...', undef, undef, undef, ],
		[ '`0HioRHk/>text...', 'Kenwood', 'TH-D7', undef, ],
		[ '`0HioRHk/>123}text...', 'Kenwood', 'TH-D7', undef, ],
		[ '`0HioRHk/]text...', 'Kenwood', 'TM-D700', undef, ],
		[ '`0HioRHk/]";g}146.520MHznow listening=', 'Kenwood', 'TM-D710', undef, ],
		[ '`0HioRHk/]text...', 'Kenwood', 'TM-D700', undef, ],
		# with and without spaces .. these get mangled easily
		[ '`0HioRHk/`text..._ ', 'Yaesu', 'VX-8', undef, ], # correct
		[ '`0HioRHk/`text..._', 'Yaesu', 'VX-8', undef, ], # removed space
		[ '`0HioRHk/`text..._  ', 'Yaesu', 'VX-8', undef, ], # additional space
		[ '`0HioRHk/`text..._"', 'Yaesu', 'FTM-350', undef, ],
		[ '`0HioRHk/`text..._"', 'Yaesu', 'FTM-350', undef, ],
		[ '`0HioRHk/`text..._#', 'Yaesu', 'VX-8G', undef, ],
		[ '`0HioRHk/`text..._#  ', 'Yaesu', 'VX-8G', undef, ], # additional space
		[ '`0HioRHk/\'text...|3', 'Byonics', 'TinyTrak3', undef, ],
		[ '`0HioRHk/\'text...|4', 'Byonics', 'TinyTrak4', undef, ],
		[ '\'m=Il -/\'TT4 v0.63|4', 'Byonics', 'TinyTrak4', undef, ],
	);
	
	plan tests => ($#tests+1) * 4;
};

use Ham::APRS::FAP qw(parseaprs);
use Ham::APRS::DeviceID qw(identify);

my $srccall = 'OH7LZB';
my $dstcall = 'S8TSYP';

foreach my $test (@tests) {
	my($body, $vendor, $model, $version) = @$test;
	
	#warn "test $dstcall\n";
	
	my $header = "$srccall>$dstcall,TCPIP*,qAC,FOURTH";
	my $aprspacket = "$header:$body";
	
	#warn "packet: $aprspacket\n";
	
	my %h;
	my $retval = parseaprs($aprspacket, \%h);
	ok($retval, 1, "failed to parse packet");
	
	my $success = identify(\%h);
	
	ok(defined $h{'deviceid'}, 1, "device identification failed for $vendor - $model");
	ok($h{'deviceid'}{'vendor'}, $vendor, "wrong vendor for $vendor - $model");
	ok($h{'deviceid'}{'model'}, $model, "wrong model for $vendor - $model");
}
