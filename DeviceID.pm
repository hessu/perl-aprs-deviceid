
package Ham::APRS::DeviceID;

=head1 NAME

Ham::APRS::DeviceID - APRS device identifier

=head1 SYNOPSIS

  use Ham::APRS::FAP qw(parseaprs);
  use Ham::APRS::DeviceID;
  use Data::Dumper;
  
  my $aprspacket = 'OH2RDP>APZMDR,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220/RELAY,WIDE, OH2AP Jarvenpaa';
  my %packet;
  my $retval = parseaprs($aprspacket, \%packet);
  if ($retval == 1) {
  	Ham::APRS::DeviceID::identify(\%packet);
  	
  	if (defined $packet{'deviceid'}) {
  	    print Dumper($packet{'deviceid'});
  	}
  }

=head1 ABSTRACT

This module attempts to identify the manufacturer, model and 
software version of an APRS transmitter. It looks at details found
in the parsed APRS packet (as provided by Ham::APRS::FAP) and updates
the hash with the identification information, if possible.

=head1 DESCRIPTION

Unless a debugging mode is enabled, all errors and warnings are reported
through the API (as opposed to printing on STDERR or STDOUT), so that
they can be reported nicely on the user interface of an application.

This module requires a reasonably recent L<Ham::APRS::FAP> module.

=head1 EXPORT

None by default.

=head1 FUNCTION REFERENCE

=cut

use strict;
use warnings;

#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Ham::APRS::FAP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
##our %EXPORT_TAGS = (
##	'all' => [ qw(
##
##	) ],
##);

our @EXPORT_OK = (
##	@{ $EXPORT_TAGS{'all'} },
	'&identify',
);

##our @EXPORT = qw(
##	
##);

our $VERSION = '1.03';


# Preloaded methods go here.

# no debugging by default
my $debug = 0;

my %result_messages = (
	'unknown' => 'Unsupported packet format',
	'no_dstcall' => 'Packet has no destination callsign',
	'no_format' => 'Packet has no defined format',
	'mice_no_comment' => 'Mic-e packet with no comment defined',
	'mice_no_deviceid' => 'Mic-e packet with no device identifier in comment',
	'no_id' => 'No device identification found',
);

# these functions are used to report warnings and parser errors
# from the module

sub _a_err($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	$rethash->{'deviceid_resultcode'} = $errcode;
	$rethash->{'deviceid_resultmsg'}
		= defined $result_messages{$errcode}
		? $result_messages{$errcode} : $errcode;
	
	$rethash->{'deviceid_resultmsg'} .= ': ' . $val if (defined $val);
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID ERROR $errcode: " . $rethash->{'deviceid_resultmsg'} . "\n";
	}
	
	return 0;
}

sub _a_warn($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	push @{ $rethash->{'deviceid_warncodes'} }, $errcode;
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID WARNING $errcode: "
		    . (defined $result_messages{$errcode}
		      ? $result_messages{$errcode} : $errcode)
		    . (defined $val ? ": $val" : '')
		    . "\n";
	}
	
	return 0;
}


=over

=item debug($enable)

Enables (debug(1)) or disables (debug(0)) debugging.

When debugging is enabled, warnings and errors are emitted using the warn() function,
which will normally result in them being printed on STDERR. Succesfully
printed packets will be also printed on STDOUT in a human-readable
format.

When debugging is disabled, nothing will be printed on STDOUT or STDERR -
all errors and parsing results need to be collected from the returned
hash reference.

=back

=cut

sub debug($)
{
	my $dval = shift @_;
	if ($dval) {
		$debug = 1;
	} else {
		$debug = 0;
	}
}

my %response = (
	'd7' => {
		'vendor' => 'Kenwood',
		'model' => 'TH-D7',
		'class' => 'ht',
		'messaging' => 1,
	},
	'd72' => {
		'vendor' => 'Kenwood',
		'model' => 'TH-D72',
		'class' => 'ht',
		'messaging' => 1,
	},
	'd700' => {
		'vendor' => 'Kenwood',
		'model' => 'TM-D700',
		'class' => 'rig',
		'messaging' => 1,
	},
	'd710' => {
		'vendor' => 'Kenwood',
		'model' => 'TM-D710',
		'class' => 'rig',
		'messaging' => 1,
	},
	'vx8' => {
		'vendor' => 'Yaesu',
		'model' => 'VX-8',
		'class' => 'ht',
		'messaging' => 1,
	},
	'vx8g' => {
		'vendor' => 'Yaesu',
		'model' => 'VX-8G',
		'class' => 'ht',
		'messaging' => 1,
	},
	'ftm350' => {
		'vendor' => 'Yaesu',
		'model' => 'FTM-350',
		'class' => 'rig',
		'messaging' => 1,
	},
	'tt3' => {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak3',
		'class' => 'tracker',
	},
	'tt4' => {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak4',
		'class' => 'tracker',
	},
);

my %fixed_dstcalls = (
	'APRS' => {
		'vendor' => 'unknown',
		'model' => 'unknown',
	},
	
	'AP1WWX' => {
		'vendor' => 'TAPR',
		'model' => 'T-238+',
		'class' => 'wx',
	},
	
	'APCLEY' => {
		'vendor' => 'ZS6EY',
		'model' => 'EYTraker',
		'class' => 'tracker',
	},
	'APCLWX' => {
		'vendor' => 'ZS6EY',
		'model' => 'EYWeather',
		'class' => 'wx',
	},
	'APCLEZ' => {
		'vendor' => 'ZS6EY',
		'model' => 'Telit EZ10 GSM application',
		'class' => 'tracker',
	},
	
	'APZMDR' => {
		'vendor' => 'Open Source',
		'model' => 'HaMDR',
		'class' => 'tracker',
		'os' => 'embedded',
	},
	'APJID2' => {
		'vendor' => 'Peter Loveall, AE5PL',
		'model' => 'D-Star APJID2',
		'class' => 'dstar',
	},
	
	'APDPRS' => {
		'vendor' => 'unknown',
		'model' => 'D-Star APDPRS',
		'class' => 'dstar',
	},
	
	'APERXQ' => {
		'vendor' => 'PE1RXQ',
		'model' => 'PE1RXQ APRS Tracker',
		'class' => 'tracker',
	},
	
	'APNK01' => {
		'vendor' => 'Kenwood',
		'model' => 'TM-D700',
		'class' => 'rig',
		'messaging' => 1,
		'version_regexp' => 1,
	},
	'APNK80' => {
		'vendor' => 'Kantronics',
		'model' => 'KAM',
		'version' => '8.0',
	},
	'APNKMP' => {
		'vendor' => 'Kantronics',
		'model' => 'KAM+',
	},
	'APAGW' => {
		'vendor' => 'SV2AGW',
		'model' => 'AGWtracker',
		'class' => 'software',
		'os' => 'Windows',
	},
	'PSKAPR' => {
		'vendor' => 'Open Source',
		'model' => 'PSKmail',
		'class' => 'software',
	},
	'APSK63' => {
		'vendor' => 'Chris Moulding, G4HYG',
		'model' => 'APRS Messenger',
		'class' => 'software',
		'os' => 'Windows',
	},
	'APN102' => {
		'vendor' => 'Gregg Wonderly, W5GGW',
		'model' => 'APRSNow',
		'class' => 'mobile',
		'os' => 'ipad',
	},
	'APRNOW' => {
		'vendor' => 'Gregg Wonderly, W5GGW',
		'model' => 'APRSNow',
		'class' => 'mobile',
		'os' => 'ipad',
	},
	'APZ186' => {
		'vendor' => 'IW3FQG',
		'model' => 'UIdigi',
		'class' => 'digi',
		'version' => '186'
	},
	'APZ18' => {
		'vendor' => 'IW3FQG',
		'model' => 'UIdigi',
		'class' => 'digi',
		'version' => '18'
	},
	'APZ19' => {
		'vendor' => 'IW3FQG',
		'model' => 'UIdigi',
		'class' => 'digi',
		'version' => '19'
	},
	'APKRAM' => {
		'vendor' => 'kramstuff.com',
		'model' => 'Ham Tracker',
		'class' => 'mobile',
		'os' => 'iphone',
	},
	'APK003' => {
		'vendor' => 'Kenwood',
		'model' => 'TH-D72',
		'class' => 'ht',
	},
);

my @dstcall_regexps = (
	[ 'APJI(\\d+)', {
		'vendor' => 'Peter Loveall, AE5PL',
		'model' => 'jAPRSIgate',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'APD(\\d+)', {
		'vendor' => 'Open Source',
		'model' => 'aprsd',
		'class' => 'software',
		'os' => 'Linux/Unix',
		'version_regexp' => 1,
	} ],
	[ 'AP4R(\\d+)', {
		'vendor' => 'Open Source',
		'model' => 'APRS4R',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'AP(\\d{3})D', {
		'vendor' => 'Painter Engineering',
		'model' => 'uSmartDigi D-Gate',
		'class' => 'dstar',
		'version_regexp' => 1,
	} ],
	[ 'AP(\\d{3})U', {
		'vendor' => 'Painter Engineering',
		'model' => 'uSmartDigi Digipeater',
		'class' => 'digi',
		'version_regexp' => 1,
	} ],
	[ 'APAF(\\d{2})', {
		'model' => 'AFilter',
		'version_regexp' => 1,
	} ],
	[ 'APAG(\\d{2})', {
		'model' => 'AGate',
		'version_regexp' => 1,
	} ],
	[ 'APAGW(\\d)', {
		'vendor' => 'SV2AGW',
		'model' => 'AGWtracker',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	[ 'APAX(\\d{2})', {
		'model' => 'AFilterX',
		'version_regexp' => 1,
	} ],
	[ 'APAH(\\d{2})', {
		'model' => 'AHub',
		'version_regexp' => 1,
	} ],
	[ 'APAW(\\d{2})', {
		'vendor' => 'SV2AGW',
		'model' => 'AGWPE',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	[ 'APBL(\\d{2})', {
		'vendor' => 'BigRedBee',
		'model' => 'BeeLine GPS',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APC(\\d{3})', {
		'vendor' => 'Rob Wittner, KZ5RW',
		'model' => 'APRS/CE',
		'class' => 'mobile',
		'version_regexp' => 1,
	} ],
	[ 'APCL(\\d{2})', {
		'vendor' => 'maprs.org',
		'model' => 'maprs',
		'class' => 'mobile',
		'version_regexp' => 1,
	} ],
	[ 'APDT(\\d{2})', {
		'vendor' => 'unknown',
		'model' => 'APRStouch Tone (DTMF)',
		'version_regexp' => 1,
	} ],
	[ 'APDF(\\d{2})', {
		'model' => 'Automatic DF units',
		'version_regexp' => 1,
	} ],
	[ 'APE(\\d{3})', {
		'model' => 'Telemetry devices',
		'version_regexp' => 1,
	} ],
	[ 'APFG(\\d{2})', {
		'vendor' => 'KP4DJT',
		'model' => 'Flood Gage',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'APGO(\\d{2})', {
		'vendor' => 'AA3NJ',
		'model' => 'APRS-Go',
		'class' => 'mobile',
		'version_regexp' => 1,
	} ],
	
	[ 'APHH(\d)', {
		'vendor' => 'Steven D. Bragg, KA9MVA',
		'model' => 'HamHud',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APHK(\\d{2})', {
		'vendor' => 'LA1BR',
		'model' => 'Digipeater/tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'API(\\d{3})', {
		'vendor' => 'Icom',
		'model' => 'unknown',
		'class' => 'dstar',
		'version_regexp' => 1,
	} ],
	
	[ 'APJA(\\d{2})', {
		'vendor' => 'K4HG & AE5PL',
		'model' => 'JavAPRS',
		'version_regexp' => 1,
	} ],
	[ 'APJE(\\d{2})', {
		'vendor' => 'Gregg Wonderly, W5GGW',
		'model' => 'JeAPRS',
		'version_regexp' => 1,
	} ],
	[ 'APJS(\\d{2})', {
		'vendor' => 'Peter Loveall, AE5PL',
		'model' => 'javAPRSSrvr',
		'version_regexp' => 1,
	} ],
	
	[ 'APK0(\\d{2})', {
		'vendor' => 'Kenwood',
		'model' => 'TH-D7',
		'class' => 'ht',
		'version_regexp' => 1,
	} ],
	[ 'APK1(\\d{2})', {
		'vendor' => 'Kenwood',
		'model' => 'TM-D700',
		'class' => 'rig',
		'version_regexp' => 1,
	} ],
	
	[ 'APAND(\\d)', {
		'vendor' => 'Open Source',
		'model' => 'APRSdroid',
		'os' => 'Android',
		'version_regexp' => 1,
	} ],
	[ 'APN3(\\d{2})', {
		'vendor' => 'Kantronics',
		'model' => 'KPC-3',
		'version_regexp' => 1,
	} ],
	[ 'APN9(\\d{2})', {
		'vendor' => 'Kantronics',
		'model' => 'KPC-9612',
		'version_regexp' => 1,
	} ],
	
	[ 'APND([0-9A-Z]{2})', {
		'vendor' => 'PE1MEW',
		'model' => 'DIGI_NED',
		'version_regexp' => 1,
	} ],
	
	[ 'APNM(\\d{2})', {
		'vendor' => 'MFJ',
		'model' => 'TNC',
		'version_regexp' => 1,
	} ],
	[ 'APNP(\\d{2})', {
		'vendor' => 'PacComm',
		'model' => 'TNC',
		'version_regexp' => 1,
	} ],
	
	[ 'APNT(\\d{2})', {
		'vendor' => 'SV2AGW',
		'model' => 'TNT TNC as a digipeater',
		'class' => 'digi',
		'version_regexp' => 1,
	} ],
	
	[ 'APNU([A-Z0-9]{2})', {
		'vendor' => 'IW3FQG',
		'model' => 'UIdigi',
		'class' => 'digi',
		'version_regexp' => 1,
	} ],
	[ 'APNU([0-9]{2}\\-[0-9])', {
		'vendor' => 'IW3FQG',
		'model' => 'UIdigi',
		'class' => 'digi',
		'version_regexp' => 1,
	} ],
	
	[ 'APNX(\\d{2})', {
		'vendor' => 'K6DBG',
		'model' => 'TNC-X',
		'version_regexp' => 1,
	} ],
	
	[ 'APOT([A-Z0-9]{2})', {
		'vendor' => 'Argent Data Systems',
		'model' => 'OpenTracker',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APPT([A-Z0-9]{2})', {
		'vendor' => 'JF6LZE',
		'model' => 'KetaiTracker',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APR(8\\d{2})', {
		'vendor' => 'Bob Bruninga, WB4APR',
		'model' => 'APRSdos',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	
	[ 'APRRT(\d)', {
		'vendor' => 'RPC Electronics',
		'model' => 'RTrak',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APRHH(\d)', {
		'vendor' => 'Steven D. Bragg, KA9MVA',
		'model' => 'HamHud',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APRX([0-3].)', {
		'vendor' => 'OH2MQK',
		'model' => 'aprx',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'APRX([4-9].)', {
		'vendor' => 'Bob Bruninga, WB4APR',
		'model' => 'APRSmax',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'APS(\\d{3})', {
		'vendor' => 'Brent Hildebrand, KH2Z',
		'model' => 'APRS+SA',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	
	
	[ 'APTT([0-9])', {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APT2([0-9]{2})', {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak2',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APT3([0-9A-Z]{2})', {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak3',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APT4([0-9A-Z]{2})', {
		'vendor' => 'Byonics',
		'model' => 'TinyTrak4',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APTW(\\d{2})', {
		'vendor' => 'Byonics',
		'model' => 'WXTrak',
		'class' => 'wx',
		'version_regexp' => 1,
	} ],
	
	[ 'APU(2\\d.)(.{0,1})', {
		'vendor' => 'Roger Barker, G4IDE',
		'model' => 'UI-View32',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	[ 'APU(1\\d.)', {
		'vendor' => 'Roger Barker, G4IDE',
		'model' => 'UI-View16',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	
	[ 'APVR(\\d{2})', {
		'vendor' => 'unknown',
		'model' => 'IRLP',
		'version_regexp' => 1,
	} ],
	[ 'APVE(\\d{2})', {
		'vendor' => 'unknown',
		'model' => 'EchoLink',
		'version_regexp' => 1,
	} ],
	
	[ 'APW(\\d{3})', {
		'vendor' => 'Sproul Brothers',
		'model' => 'WinAPRS',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	
	[ 'APWM(\\d{2})', {
		'vendor' => 'KJ4ERJ',
		'model' => 'APRSISCE',
		'class' => 'software',
		'os' => 'Windows CE',
		'version_regexp' => 1,
	} ],
	[ 'APWW(\\d{2})', {
		'vendor' => 'KJ4ERJ',
		'model' => 'APRSIS32',
		'class' => 'software',
		'os' => 'Windows',
		'version_regexp' => 1,
	} ],
	
	[ 'APX(\\d{3})', {
		'vendor' => 'Open Source',
		'model' => 'Xastir',
		'class' => 'software',
		'os' => 'Linux/Unix',
		'version_regexp' => 1,
	} ],
	
	[ 'APXR(\\d{2})', {
		'vendor' => 'G8PZT',
		'model' => 'Xrouter',
		'version_regexp' => 1,
	} ],
	
	[ 'APZG(\\d{2})', {
		'vendor' => 'OH2GVE',
		'model' => 'aprsg',
		'class' => 'software',
		'os' => 'Linux/Unix',
		'version_regexp' => 1,
	} ],
	
	[ 'APRG(\\d{2})', {
		'vendor' => 'OH2GVE',
		'model' => 'aprsg',
		'class' => 'software',
		'os' => 'Linux/Unix',
		'version_regexp' => 1,
	} ],
	
);

my %regexp_prefix;

#
# init code: compile the regular expressions to speed up matching
#

sub _compile_regexps()
{
	for (my $i = 0; $i <= $#dstcall_regexps; $i++) {
		my $dmatch = $dstcall_regexps[$i];
		my($regexp, $response) = @$dmatch;
		
		my $compiled = qr/^$regexp$/;
		$dstcall_regexps[$i] = [ $regexp, $response, $compiled ];
	}
}

#
# init: optimize regexps with an initial hash lookup
#

sub _optimize_regexps()
{
	my @left;
	
	for (my $i = 0; $i <= $#dstcall_regexps; $i++) {
		my $dmatch = $dstcall_regexps[$i];
		my($regexp, $response, $compiled) = @$dmatch;
		
		if ($regexp =~ /^([^\(]{2,5})(\(.*)$/) {
			if (!defined $regexp_prefix{$1} ) {
				$regexp_prefix{$1} = [ $dmatch ];
			} else {
				push @{ $regexp_prefix{$1} }, $dmatch;
			}
		} else {
			push @left, $dmatch;
			warn "optimize: leaving $regexp over\n";
		}
	}
	
	@dstcall_regexps = @left;
}

_compile_regexps();
_optimize_regexps();

=over

=item identify($hashref)

Tries to identify the device.

=back

=cut

sub identify($)
{
	my($p) = @_;
	
	$p->{'deviceid_resultcode'} = '';
	
	return _a_err($p, 'no_format') if (!defined $p->{'format'});
	return _a_err($p, 'no_dstcall') if (!defined $p->{'dstcallsign'});
	
	if ($p->{'format'} eq 'mice') {
		#warn Dumper($p);
		my $resp;
		#warn "comment: " . $p->{'comment'} . "\n";
		if (!defined $p->{'comment'}) {
			return _a_err($p, 'mice_no_comment');
		}
		if ($p->{'comment'} =~ s/^>(.*)=$/$1/) {
			$resp = 'd72';
		} elsif ($p->{'comment'} =~ s/^>//) {
			$resp = 'd7';
		} elsif ($p->{'comment'} =~ s/^\](.*)=$/$1/) {
			$resp = 'd710';
		} elsif ($p->{'comment'} =~ s/^\]//) {
			$resp = 'd700';
		} elsif ($p->{'comment'} =~ s/^`(.*)_\s*$/$1/) {
			$resp = 'vx8';
		} elsif ($p->{'comment'} =~ s/^`(.*)_"$/$1/) {
			$resp = 'ftm350';
		} elsif ($p->{'comment'} =~ s/^`(.*)_#$/$1/) {
			$resp = 'vx8g';
		} elsif ($p->{'comment'} =~ s/^\'(.*)\|3$/$1/) {
			$resp = 'tt3';
		} elsif ($p->{'comment'} =~ s/^\'(.*)\|4$/$1/) {
			$resp = 'tt4';
		}
		if ($resp) {
			$p->{'deviceid'} = $response{$resp};
			return 1;
		}
		return _a_err($p, 'mice_no_deviceid');
	}
	
	if (defined $fixed_dstcalls{$p->{'dstcallsign'}}) {
		$p->{'deviceid'} = $fixed_dstcalls{$p->{'dstcallsign'}};
		return 1;
	}
	
	foreach my $len (4, 3, 5, 2) {
		my $prefix = substr($p->{'dstcallsign'}, 0, $len);
		if (defined $regexp_prefix{$prefix}) {
			foreach my $dmatch (@{ $regexp_prefix{$prefix} }) {
				my($regexp, $response, $compiled) = @$dmatch;
				#warn "trying '$regexp' against " . $p->{'dstcallsign'} . "\n";
				if ($p->{'dstcallsign'} =~ $compiled) {
					#warn "match!\n";
					my %copy = %{ $response };
					$p->{'deviceid'} = \%copy;
					
					if ($response->{'version_regexp'}) {
						#warn "version_regexp set: $1 from " . $p->{'dstcallsign'} . " using " . $regexp . "\n";
						$p->{'deviceid'}->{'version'} = $1;
						delete $p->{'deviceid'}->{'version_regexp'};
					}
					
					return 1;
				}
			}
		}
	}
	
	return _a_err($p, 'no_id');
}


1;
__END__


=head1 SEE ALSO

APRS tocalls list, L<http://aprs.org/aprs11/tocalls.txt>

APRS specification 1.0.1, L<http://www.tapr.org/aprs_working_group.html>

APRS addendums, e.g. L<http://web.usna.navy.mil/~bruninga/aprs/aprs11.html>

The source code of this module - there are some undocumented features.

=head1 AUTHORS

Heikki Hannikainen, OH7LZB E<lt>hessu@hes.iki.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Heikki Hannikainen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
