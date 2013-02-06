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

# Getopt::Long::Configure ("bundling_override");
Getopt::Long::Configure ('pass_through');

my $man = 0;
my $help = 0;
my $make = 1;
my $check_mpc = 1;
my $clean = 0;
my $left_over_args;
my $ret;
my $type = "make";
($ret, $left_over_args) = GetOptions('clean' => \$clean,
                                     'check-mpc!' => \$check_mpc,
                                     'make' => \$make,
                                     'type=s' => \$type,
                                     'help|?' => \$help,
                                     'man' => \$man) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

if ($clean)
{
  $make = 0;
}

my($basePath) = (defined $FindBin::RealBin ? $FindBin::RealBin :
                                             File::Spec->rel2abs(dirname($0)));
if ($^O eq 'VMS') {
  $basePath = File::Spec->rel2abs(dirname($0)) if ($basePath eq '');
  $basePath = VMS::Filespec::unixify($basePath);
}

my $oldest_build_file;
my $newest_mpc_file;

sub is_build_file
{
  my $match = 0;

  if ($type =~ /^vc/)
  {
    $match = (/^.*\.dsp\z/s ||
                /^.*\.dsw\z/s ||
                /^.*\.vcproj\z/s ||
                /^.*\.sln\z/s);
  }
  else # ($type =~ /^make/)
  {
    $match = ( /^Makefile.*\z/s);
  }
  return $match;
}

sub check_file_date
{
  # print "checking $_\n";
  # my $file = $_;
  my $match = 0;

  if ($type =~ /^vc/)
  {
    $match = (/^.*\.dsp\z/s ||
                /^.*\.dsw\z/s ||
                /^.*\.vcproj\z/s ||
                /^.*\.sln\z/s);
  }
  else # ($type =~ /^make/)
  {
    $match = ( /^Makefile.*\z/s);
  }

  if ($match)
  {
    #print "Makefile : $_\n";
    my $file_date = stat $_;
    if ($oldest_build_file == 0 ||
        $file_date < $oldest_build_file)
    {
      $oldest_build_file = $file_date;
    }
  }

  $match = 0;

  $match = (/^.*\.mpc\z/s ||
                /^.*\.mwc\z/s);

  if ($match)
  {
    my $file_date = stat $_;
    if ($file_date > $newest_mpc_file)
    {
      $newest_mpc_file = $file_date;
    }
  }
}

sub check_mpc_up_todate
{
  my $dir = shift(@_);
  my $oldest_build_file = 0;
  my $newest_mpc_file = 0;
  # print "check mpc $dir\n";

  find(\&check_file_date, "$dir");

  my $rebuild_required = $newest_mpc_file > $oldest_build_file;
  return $rebuild_required;
}

sub clean_file
{
  my $file = shift(@_);
  print "Gonna clean $file\n";
}

sub clean_dir
{
  my $dir = shift(@_);
  my @files = <$dir/*>;
  foreach (@files) {
   print "Checking file $_\n";
   if (is_build_file())
    {
      clean_file($_);
    }
  }
}

sub make_dir
{

}

foreach my $file (@ARGV) {
  print "File is $file\n";
  if (-d $file)
  {
    if ($make)
    {
      if ($check_mpc && check_mpc_up_todate($file))
      {
        clean_dir($file);
        mpc_dir($file);
      }
      make_dir($file);
    }
    elsif ($clean)
    {
      clean_dir($file);
    }
  }
  elsif (-f $file)
  {
    if ($clean)
    {
      clean_file($file);
    }
    else
    {
      make_file($file);
    }
  }
  else
  {
    print "Unrecognised file / dir: $file\n";
    podusage(2);
  }
}

__END__
=head1 NAME
mpc_make.pl - Makes shizzle, whatever the weather
=head1 SYNOPSIS
[perl] mpc_make.pl [options] [file ...]
 Options:
  -help brief help message
  -man full documentation
=head1 OPTIONS
=over 8
=item B<-help>
Print a brief help message and exits.
=item B<-man>
Prints the manual page and exits.
=back
=head1 DESCRIPTION
B<This program> will read the given input file(s) and do something
useful with the contents thereof.
=cut;