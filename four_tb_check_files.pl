#! /usr/bin/perl
eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

require 5.006;

use strict;
use FindBin;
use File::Spec;
use File::Find;
use File::Basename;
use Getopt::Long;
use File::stat;
use Pod::Usage;

my $scriptname = basename($0);

# Getopt::Long::Configure ("bundling_override");
Getopt::Long::Configure ('pass_through');

my $man = 0;
my $help = 0;
my $left_over_args;
my $ret;

($ret, $left_over_args) = GetOptions('help|?' => \$help,
                                     'man' => \$man) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $command;

my @files = `ssh root\@nwb-devnas02 cd /volume1 && find Transfer -type f`;

foreach my $file (@files)
{
  if (! -e $file)
  {
    $command = "scp root\@nwb-devnas02:/volume1/$file $file";
    system($command) eq 0 or die "Error command: $command failed.";
    print "Copied $file OK!\n";
  }
}


exit (0);

__END__

=head1 NAME

four_tb_check_files.pl - Checks files are on the 4TB box

=head1 SYNOPSIS

[perl] four_tb_check_files.pl [options]

 Options:
  --help                      Brief help message
  --man                       Full documentation

=head1 OPTIONS

=over 8

=item B<--man>

The full docs. If you can't see the 'DESCRIPTION' below this right now then this is for you...!

=back

=head1 DESCRIPTION

This script checks the files in the NAS are in the 4TB box. If not it tries to copy them.
