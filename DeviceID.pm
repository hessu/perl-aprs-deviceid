
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


1;
__END__


=head1 SEE ALSO

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
