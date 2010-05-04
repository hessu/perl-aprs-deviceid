
package Ham::APRS::DeviceID;

=head1 NAME

Ham::APRS::DeviceID - APRS device identifier

=head1 SYNOPSIS

  use Ham::APRS::FAP qw(parseaprs);
  use Ham::APRS::DeviceID;
  my $aprspacket = 'OH2RDP>APZMDR,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220/RELAY,WIDE, OH2AP Jarvenpaa';
  my %packetdata;
  my $retval = parseaprs($aprspacket, \%packetdata);
  if ($retval == 1) {
  	Ham::APRS::DeviceID::identify(\%packetdata);
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

our $VERSION = '1.00';


# Preloaded methods go here.

# no debugging by default
my $debug = 0;

my %result_messages = (
	'unknown' => 'Unsupported packet format',
	
);

# these functions are used to report warnings and parser errors
# from the module

sub _a_err($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	$rethash->{'resultcode'} = $errcode;
	$rethash->{'resultmsg'}
		= defined $result_messages{$errcode}
		? $result_messages{$errcode} : $errcode;
	
	$rethash->{'resultmsg'} .= ': ' . $val if (defined $val);
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID ERROR $errcode: " . $rethash->{'resultmsg'} . "\n";
	}
}

sub _a_warn($$;$)
{
	my ($rethash, $errcode, $val) = @_;
	
	push @{ $rethash->{'warncodes'} }, $errcode;
	
	if ($debug > 0) {
		warn "Ham::APRS::DeviceID WARNING $errcode: "
		    . (defined $result_messages{$errcode}
		      ? $result_messages{$errcode} : $errcode)
		    . (defined $val ? ": $val" : '')
		    . "\n";
	}
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


my %fixed_dstcalls = (
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
		'class' => 'wx',
	},
	
	'APU25N' => {
		'vendor' => 'Roger Barker, G4IDE',
		'model' => 'UI-View32',
		'class' => 'software',
		'os' => 'Windows',
	},
	'APU16N' => {
		'vendor' => 'Roger Barker, G4IDE',
		'model' => 'UI-View16',
		'class' => 'software',
		'os' => 'Windows',
	},
	
	'APZMDR' => {
		'vendor' => 'HaMDR',
		'model' => 'HaMDR',
		'class' => 'tracker',
		'os' => 'embedded',
	},
	'APJID2' => {
		'vendor' => 'D-Star',
		'model' => 'D2',
		'class' => 'dstar',
	},
	
	'APOT([A-Z0-9]{2})' => {
		'vendor' => 'Argent Data Systems',
		'model' => 'OpenTracker',
		'class' => 'tracker',
	},
	
	'APDPRS' => {
		'model' => 'D-Star DPRS',
		'class' => 'dstar',
	},
	
	'APERXQ' => {
		'vendor' => 'PE1RXQ',
		'model' => 'PE1RXQ APRS Tracker',
		'class' => 'tracker',
	},
	
	'APNK01' => {
		'vendor' => 'Kenwood',
		'model' => 'D-700',
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
);

my @dstcall_regexps = (
	[ 'APJI(\\d+)', {
		'vendor' => 'D-Star',
		'model' => 'unknown',
		'class' => 'dstar',
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
	[ 'APC(\\d{3})', {
		'vendor' => 'Rob Wittner, KZ5RW',
		'model' => 'APRS/CE',
		'class' => 'mobile',
		'version_regexp' => 1,
	} ],
	[ 'APDT(\\d{2})', {
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
	[ 'APHK(\\d{2})', {
		'vendor' => 'LA1BR',
		'model' => 'Digipeater/tracker',
		'version_regexp' => 1,
	} ],
	
	[ 'APJA(\\d{2})', {
		'model' => 'JavAPRS',
		'version_regexp' => 1,
	} ],
	[ 'APJE(\\d{2})', {
		'model' => 'JeAPRS',
		'version_regexp' => 1,
	} ],
	[ 'APJI(\\d{2})', {
		'model' => 'jAPRSIgate',
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
		'model' => 'TH-D700',
		'class' => 'rig',
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
	
	[ 'APND(\\d{2})', {
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
	
	[ 'APNU(\\d{2})', {
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
	
	[ 'APRX([0-3].)', {
		'vendor' => 'OH2MQK',
		'model' => 'aprx',
		'class' => 'software',
		'version_regexp' => 1,
	} ],
	[ 'APRX([4-9].)', {
		'model' => 'APRSmax',
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
		'model' => 'TinyTrack3',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APT4([0-9A-Z]{2})', {
		'vendor' => 'Byonics',
		'model' => 'TinyTrack4',
		'class' => 'tracker',
		'version_regexp' => 1,
	} ],
	[ 'APTW(\\d{2})', {
		'vendor' => 'Byonics',
		'model' => 'WXTrak',
		'class' => 'wx',
		'version_regexp' => 1,
	} ],
	
	[ 'APU(2\\d.)', {
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
	
	[ 'APVR(\d{2})', {
		'model' => 'IRLP',
		'version_regexp' => 1,
	} ],
	[ 'APVE(\d{2})', {
		'model' => 'EchoLink',
		'version_regexp' => 1,
	} ],
	
);

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

_compile_regexps();

=over

=item identify($hashref)

Tries to identify the device.

=back

=cut

sub identify($)
{
	my($p) = @_;
	
	if (defined $fixed_dstcalls{$p->{'dstcallsign'}}) {
		$p->{'deviceid'} = $fixed_dstcalls{$p->{'dstcallsign'}};
		return 1;
	}
	
	foreach my $dmatch (@dstcall_regexps) {
		my($regexp, $response, $compiled) = @$dmatch;
		#warn "trying '$regexp' against " . $p->{'dstcallsign'} . "\n";
		if ($p->{'dstcallsign'} =~ $compiled) {
			#warn "match!\n";
			$p->{'deviceid'} = $response;
			return 1;
		}
	}
	
	return 0;
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
