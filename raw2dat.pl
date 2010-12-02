#! /usr/bin/perl -w

=pod
	translate .raw (binary) data to .dat format
=cut

package myPerl;

use strict;
use warnings;

use Carp;
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

####

# module variables
my $opt_bits = 16;
my $opt_endian = 'little';
my $opt_format = 'binary';
my $opt_output = undef;
my $opt_force = false;
my $opt_help = false;

my $m_fin;     # input file name
my $m_fout;    # output file name

####

main();

####

sub usage {
	my $exitcode = shift || 0;

	print << 'EOF';
usage:
	raw2dat --force --bits [8|16|32] --endian [big|little] --output filename filename

		--bits   (8|16|32) -bit word [16]
		--endian [little]
		--output output filename
		--force  overwrite existed output file
		--help   print this message
EOF

	exit($exitcode);
}

sub main
{
	# command line
	my $rz = GetOptions(
		"help"     => \$opt_help,
		"force"    => \$opt_force,
		"bits=i"   => \$opt_bits,
		"endian=s" => \$opt_endian,
		"output=s" => \$opt_output,
	);
	$m_fin = shift @ARGV;
	usage() if (!$rz or $opt_help or !defined($m_fin)); # exit
	
	if (!defined($opt_output)) { $m_fout = $m_fin . '.dat'; }
	else { $m_fout = $opt_output; }
	
	if ((-e $m_fout) && (!$opt_force)) {
		print "Overwrite '$m_fout'?[y/n*] : ";
		my $ans = <STDIN>;
		if (!(defined($ans) && ($ans =~ m/^y$/i))) {
			print "Task abort!\n";
			exit(0);
		}
	}
	
	# ready files
	my $hin;
	my $hou;
	open($hin, "<$m_fin") || die "Failed opening file '$m_fin'.";
	binmode($hin);
	open($hou, ">$m_fout") || die "Failed opening file '$m_fout'.";
	
	# ready parameters
	my $fmtin;
	my $fmtou;
	my $lenmsk;
	if (8 == $opt_bits) { # 8-bit
		$fmtin = 'C*';
		$fmtou = "%02x\n";
		$lenmsk = 0;
	} elsif (16 == $opt_bits) { # 16-bit
		$fmtin = ('little' eq $opt_endian) ? 'S*' : 'n*';
		$fmtou = "%04x\n";
		$lenmsk = 1;
	} elsif (32 == $opt_bits) { # 32-bit
		$fmtin = ('little' eq $opt_endian) ? 'L*' : 'N*';
		$fmtou = "%08x\n";
		$lenmsk = 3;
	} else {
		die 'Unsupported width.';
	}
	
	# convert now
	my ($sz, $buf);
	$sz = sysread($hin, $buf, 0x1000);
	while ($sz) {
		if ($sz & $lenmsk) { die "Size not word aligned!"; }
		my @words = unpack($fmtin, $buf);	
		foreach (@words) {
			print $hou sprintf($fmtou, $_);
		}
		$sz = sysread($hin, $buf, 0x1000);
	}

	# finish
	close($hin);
	close($hou);
	
	print "'$m_fin' => '$m_fout' done!\n";
}
