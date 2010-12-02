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
	dat2raw --force --bits [8|16|32] --endian [big|little] --output filename filename

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
	
	if (!defined($opt_output)) { $m_fout = $m_fin . '.raw'; }
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
	my $fmtout;
	my $lenmsk;
	if (8 == $opt_bits) { # 8-bit
		$fmtout = 'C';
	} elsif (16 == $opt_bits) { # 16-bit
		$fmtout = ('little' eq $opt_endian) ? 'S' : 'n';
	} elsif (32 == $opt_bits) { # 32-bit
		$fmtout = ('little' eq $opt_endian) ? 'L' : 'N';
	} else {
		die 'Unsupported width.';
	}
	
	# convert now
	while (<$hin>) {
		chomp;
		next if ('' eq $_);
		
		my $value = hex($_);
		my $code = pack($fmtout, $value);
		syswrite($hou, $code, length($code));
	}

	# finish
	close($hin);
	close($hou);
	
	print "'$m_fin' => '$m_fout' done!\n";
}
