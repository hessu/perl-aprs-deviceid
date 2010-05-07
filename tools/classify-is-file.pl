#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Ham::APRS::FAP qw(parseaprs);
use Ham::APRS::DeviceID qw(identify);

use Time::HiRes qw(sleep time);

my $lines = 0;
my $parse_ok = 0;
my $location_packet = 0;
my $identify_ok = 0;

my $start_t = time();

my $min_t;
my $max_t;

my %unid_format;
my %unid_dstcall;

my %id_format;
my %id_dstcall;

my %call;
my %call_id;

while (my $l = <>) {
	$l =~ s/[\r\n]+$//;
	if ($l =~ /^(\d+)\s+(.*)/) {
		$lines++;
		
		$min_t = $1 if (!defined $min_t || $1 < $min_t);
		$max_t = $1 if (!defined $max_t || $1 > $max_t);
		
		my %p;
		my $ret = parseaprs($2, \%p);
		next if ($ret != 1);
		
		$parse_ok++;
		
		next if (!defined $p{'type'} || $p{'type'} ne 'location');
		$location_packet++;
		$call{$p{'srccallsign'}} = 1;
		
		$ret = identify(\%p);
		
		if ($ret != 1) {
			$p{'format'} = 'NONE' if (!defined $p{'format'});
			$unid_format{$p{'format'}} = defined $unid_format{$p{'format'}} ? $unid_format{$p{'format'}} + 1 : 1;
			if ($p{'format'} ne 'mice') {
				$unid_dstcall{$p{'dstcallsign'}} = defined $unid_dstcall{$p{'dstcallsign'}} ? $unid_dstcall{$p{'dstcallsign'}} + 1 : 1;
			}
			next;
		}
		
		$identify_ok++;
		$call_id{$p{'srccallsign'}} = $p{'deviceid'};
		
		$id_format{$p{'format'}} = defined $id_format{$p{'format'}} ? $id_format{$p{'format'}} + 1 : 1;
		if ($p{'format'} ne 'mice') {
			$id_dstcall{$p{'dstcallsign'}} = defined $id_dstcall{$p{'dstcallsign'}} ? $id_dstcall{$p{'dstcallsign'}} + 1 : 1;
		}
	}
}

my $end_t = time();
my $dur_t = $end_t - $start_t;

printf("parsed $lines lines in %.3f s: %.0f lines/s\n", $dur_t, $lines / $dur_t);
printf("$parse_ok (%.1f %% of total lines) parsed correctly using FAP\n", $parse_ok / $lines * 100);
printf("$location_packet (%.1f %% of total, %.1f %% of parsed) were location packets\n", $location_packet / $lines * 100, $location_packet / $parse_ok * 100);
printf("$identify_ok (%.1f %% of location packets) were identified ok\n", $identify_ok / $lines * 100);

print "\n";
print "Unidentified in formats:\n";
foreach my $k (sort { $unid_format{$a} <=> $unid_format{$b} } keys %unid_format) {
	printf("    $k $unid_format{$k} (%.1f %%)\n", $unid_format{$k} / ($id_format{$k} + $unid_format{$k}) * 100);
}

print "\n";
print "Identified in formats:\n";
foreach my $k (sort { $id_format{$a} <=> $id_format{$b} } keys %id_format) {
	printf("    $k $id_format{$k} (%.1f %%)\n", $id_format{$k} / ($id_format{$k} + $unid_format{$k}) * 100);
}

print "\n";
print "Most common unidentified dstcalls:\n";
my $n = 0;
foreach my $k (sort { $unid_dstcall{$b} <=> $unid_dstcall{$a} } keys %unid_dstcall) {
	$n++;
	printf("    $k $unid_dstcall{$k}\n");
	last if ($n >= 50);
}

my @calls = keys %call;
my @calls_id = keys %call_id;

print "\n";
printf("%d unique srccalls with location packets, %d identified (%.1f %%)\n", $#calls+1, $#calls_id+1, ($#calls_id+1) / ($#calls+1) * 100);

my %sum = (
	'vendor' => {},
	'model' => {},
);
foreach my $c (keys %call_id) {
	my $h = $call_id{$c};
	foreach my $t ('vendor') {
		if (defined $h->{$t}) {
			$sum{$t}{$h->{$t}} = defined $sum{$t}{$h->{$t}} ? $sum{$t}{$h->{$t}} + 1 : 1;
		}
	}
	
	if (defined $h->{'vendor'} && defined $h->{'model'}) {
		my $vm = $h->{'vendor'} . ': ' . $h->{'model'};
		$sum{'model'}{$vm} = defined $sum{'model'}{$vm} ? $sum{'model'}{$vm} + 1 : 1;
	}
}

foreach my $t (sort keys %sum) {
	print "\n$t:\n";
	my $h = $sum{$t};
	foreach my $k (sort { $h->{$b} <=> $h->{$a} } keys %$h) {
		printf("  %d %s\n", $h->{$k}, $k);
	}
}

