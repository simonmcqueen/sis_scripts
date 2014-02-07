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
my $tag = '';
my $left_over_args;
my $ret;

($ret, $left_over_args) = GetOptions('tag=s' => \$tag,
                                     'help|?' => \$help,
                                     'man' => \$man) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

if ($tag eq '')
{
  pod2usage(2);
  die "Must specify a tag";
}

$| = 1;

my $command = '';

my $cvs_root = ':ext:sm@cvssrv.prismtech.com/home/cvs';

my @cvs_repos = (
  'autobuild',
  'autobuild-xml',
  'interoptests',
  'interopold',
  'jacorb141',
  'jacorb20',
  'jacorb23',
  'jacorb23-os-miop',
  'jacorb30',
  'main',
  'newcdmw',
  'ofccm',
  'ofccm_v0',
  'recording',
  'ofscripts',
  'sic',
  'tao13',
  'tao14',
  'tao151',
  'tao161',
  'tao206',
  'tao211',
  'testresults',
  'v3',
  'xampler',
  'v4',
  'v5'
  );

$ENV{CVSROOT} = $cvs_root;

foreach my $repo (@cvs_repos)
{
  print "Tagging $repo...\n";
  $command = "cvs co $repo";
  system($command) eq 0 or die "Error command: $command failed.";
  $command = "cvs tag -R $tag $repo";
  system($command) eq 0 or die "Error command: $command failed.";
  $command = "rm -rf $repo";
  system($command) eq 0 or die "Error command: $command failed.";
}

$cvs_root = ':pserver:sm@repository.prismtech.com:/usr/local/cvs';

@cvs_repos = (
  '3rdpartytools',
  'hughes',
  'OrbAda',
  'OrbAda_Release',
  'orbriverjava',
  'hsqldb_171',
  'ofj',
  'ofthreads',
  'testresults',
  'docs',
  'metrics'
  );

$ENV{CVSROOT} = $cvs_root;

foreach my $repo (@cvs_repos)
{
  print "Tagging $repo...\n";
  $command = "cvs co $repo";
  system($command) eq 0 or die "Error command: $command failed.";
  $command = "cvs tag -R $tag $repo";
  system($command) eq 0 or die "Error command: $command failed.";
  $command = "rm -rf $repo";
  system($command) eq 0 or die "Error command: $command failed.";
}

exit (0);

__END__

=head1 NAME

cvs_pt_tag_all.pl - Tags CVS

=head1 SYNOPSIS

[perl] cvs_pt_tag_all.pl [options] files/dirs

 Options:
  --tag                       A tag to apply
  --help                      Brief help message
  --man                       Full documentation

=head1 OPTIONS

=over 8

=item B<--tag>

A tag string.

=item B<--man>

The full docs. If you can't see the 'DESCRIPTION' below this right now then this is for you...!

=back

=head1 DESCRIPTION

This script tags repository.prismtech.com and cvssrv.prismtech.com
