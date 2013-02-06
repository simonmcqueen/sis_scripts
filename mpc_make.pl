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
my $make = '1';
my $check_mpc = '';
my $clean = '';
my $carryon = '';
my $exhaustive = 0;
my $left_over_args;
my $ret;
my $type = "make";
($ret, $left_over_args) = GetOptions('clean!' => \$clean,
                                     'check-mpc!' => \$check_mpc,
                                     'carryon!' => \$carryon,
                                     'exhaustive' => \$exhaustive,
                                     'make!' => \$make,
                                     'type=s' => \$type,
                                     'help|?' => \$help,
                                     'man' => \$man) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

if ($clean)
{
  $make = 0;
  if ($carryon eq '')
  {
    $carryon = 1;
  }
}

if ($make && $check_mpc eq '')
{
    $check_mpc = 1;
}

my($basePath) = (defined $FindBin::RealBin ? $FindBin::RealBin :
                                             File::Spec->rel2abs(dirname($0)));
if ($^O eq 'VMS') {
  $basePath = File::Spec->rel2abs(dirname($0)) if ($basePath eq '');
  $basePath = VMS::Filespec::unixify($basePath);
}

# See check_file_date - variables used to work out if
# we need to regenerate build files using MPC
my $oldest_build_file;
my $newest_mpc_file;

# Match a top-level build file on $_. e.g. a solution or
# a Makefile. These are what you would normally invoke to build
# some shizzle.
sub is_workspace_file
{
  my $match = 0;

  if ($type =~ /^vc/)
  {
    $match = (/^.*\.dsw\z/s ||
              /^.*\.sln\z/s);
  }
  else # ($type =~ /^make/)
  {
    $match = ( /^Makefile\z/s);
  }
  return $match;
}

# Match a 'lesser' build file on $_ e.g. a *.vcproj
# or Makefile.foo_lib. These would normally only be called from
# an encompassing 'top-level' build file as they specify
# dependency order.
sub is_project_file
{
  my $match = 0;

  if ($type =~ /^vc/)
  {
    $match = (/^.*\.dsp\z/s ||
              /^.*\.vcproj\z/s ||
              /^.*\.vcxproj\z/s);
  }
  else # ($type =~ /^make/)
  {
    $match = (/^Makefile\.*\z/s);
  }
  return $match;
}

# Record the modification time of $_ if
# it is the oldest generated file or the most recently
# modified mpc meta build file.
sub check_file_date
{
  #print "checking $File::Find::name\n";
  # my $file = $_;
  my $match = 0;

  $match = (is_workspace_file ||
                is_project_file);

  if ($match)
  {
    my $sb = stat($_);
    my $file_date = $sb->mtime;
    if ($oldest_build_file == 0 ||
        $file_date < $oldest_build_file)
    {
      print "Makefile date : $file_date $_\n";
      $oldest_build_file = $file_date;
    }
  }

  $match = 0;

  $match = (/^.*\.mpc\z/s ||
            /^.*\.mwc\z/s ||
            /^.*\.mpb\z/s ||
            /^.*\.mwb\z/s);

  if ($match)
  {
    my $sb = stat($_);
    my $file_date = $sb->mtime;
    if ($file_date > $newest_mpc_file)
    {
      print "MPC File date : $file_date $_\n";
      $newest_mpc_file = $file_date;
    }
  }
}

# Recursively check the passed directory to see if its
# generated build files are in need of regeneration
sub check_mpc_up_todate
{
  my $dir = shift(@_);
  $oldest_build_file = 0;
  $newest_mpc_file = 0;
  # print "check mpc $dir\n";

  find(\&check_file_date, "$dir");

  my $rebuild_required = $newest_mpc_file > $oldest_build_file;
  print "$scriptname: Detected MPC rebuild required...\n" if $rebuild_required;
  return $rebuild_required;
}

sub call_build_file
{
  my $mode = shift(@_);
  print "$scriptname: Proceeding to $mode $File::Find::name...\n";
  my $ret = 0;
  if ($type =~ /^vc/)
  {

  }
  else # ($type =~ /^make/)
  {
    my $clean = '';
    if (lc $mode eq 'clean')
    {
        $clean = 'realclean';
    }
    $ret = system("make $clean -f $_")
  }

  if ($ret)
  {
    if (lc $mode ne 'clean' &&  !$carryon)
    {
        die "ERROR: Trying to $mode $File::Find::name !!!\n";
    }
    else
    {
        print STDERR "$scriptname: ERROR/non zero return trying to $mode $File::Find::name. Keeping calm and carrying on.\n";
    }
  }
}

sub if_build_file_clean
{
  if (is_workspace_file ||
      ($exhaustive && is_project_file))
  {
    call_build_file('clean', $_);
  }
}

sub clean_dir
{
  my $dir = shift(@_);
  find(\&if_build_file_clean, "$dir");
}

sub if_build_file_make
{
  if (is_workspace_file ||
      ($exhaustive && is_project_file))
  {
    call_build_file('make', $_);
  }
}

sub make_dir
{
  my $dir = shift(@_);
  find(\&if_build_file_make, "$dir");
}

sub mpc_dir
{
  my $dir = shift(@_);
  my @mpc_args = @_;
  my $ret = 0;

  unshift(@mpc_args, '--type', "$type");

  my $command = "mwc.pl @mpc_args\n";
  print STDERR "$scriptname: Regenerating MPC files: $command\n";
  $ret = system($command);
  die "$scriptname: ERROR: Trying to run: $command !!!\n" if $ret;
}

my @ARGS_LEFT;

foreach my $file (@ARGV) {
  print "File is $file\n";
  if (-d $file)
  {
    print "$scriptname: Processing directory $file...\n";
    if ($check_mpc && check_mpc_up_todate($file))
    {
        clean_dir($file);
        mpc_dir($file, @ARGV);
    }
    if ($clean)
    {
      clean_dir($file);
    }
    if ($make)
    {
      # @ARGS_LEFT = @ARGV;
      make_dir($file, @ARGV);
    }
  }
  elsif (-f $file)
  {
    if ($clean)
    {
      call_build_file('clean', $file);
    }
    if ($make)
    {
      call_build_file('build', $file);
    }
  }
  else
  {

    #print "Unrecognised file / dir: $file\n";
    #podusage(2);
  }
}

exit (0);

__END__

=head1 NAME

mpc_make.pl - Makes, cleans, or remakes your shizzle, whatever the weather.

=head1 SYNOPSIS

[perl] mpc_make.pl [options] [files/dirs]

 Options:
  --check-mpc / --nocheck-mpc When making a directory check build files up to date first, clean & regenerate if not.
  --clean                     Clean the project file or directory
  --carryon / --nocarryon     If a build error is encountered, stop dead or keep going.
  --exhaustive                Build every damn thing in sight.
  --make                      Build the project file or directory.
  --type                      The type of build file e.g. vc8, vc9, make, etc.. (see mwc.pl --help)
  --help                      Brief help message
  --man                       Full documentation

=head1 OPTIONS

=over 8

=item B<--check-mpc / --nocheck-mpc>

When making a directory check build files up to date first, clean & regenerate if not. Default is to B<--check-mpc> if action is B<--make>. Only works on directories.

=item B<--clean>

Clean the project file or directory. This action will occur automatically on directories if B<--check-mpc> is set, B<--make> is the action and the buildfiles are out of date.

=item B<--carryon / --nocarryon>

If a build error is encountered making a particular file, stop dead or keep going onto further buildfiles. Default --nocarryon when making.

=item B<--exhaustive>

If the action is --make and we are processing a directory then find B<all> buildfiles therein and build them. Build equivalent of take off and nuke the site from orbit. B<Warning>: may cause false positive errors, but sometimes it's the only way to be sure. Default: B<off>.

=item B<--make>

Build the project file or directory. This is the default action if none is specified.

=item B<--type>

Set the type of project to be built. Defaults to B<make> if not set. See B<mwc.pl --help>.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut;
