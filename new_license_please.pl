#! /usr/bin/perl
# $Id: new_license_please.pl,v 1.2 2008/11/04 17:37:00 tao Exp $
# This script updates the OpenFusion CORBA services license
# stored on tao.prismtech.com (which is used by all the various
# TAO builds) with a new file that is node unlocked and which
# will expire a week hence.

use File::Path;
use File::Basename;
use Cwd;

use strict;

# CVSROOT to go looking for the v4/etc module in
my $cvs_root = ":ext:tao\@cvssrv.prismtech.com/home/cvs";
# Where to SCP the finished license to
my $license_to_replace = "tao\@tao:~/license.lic";
#Where the FlexLM signing thing is found on this machine
my $flexlm_on_here = "/usr/local/flexlm/v11.3/sun4_u8/lmcrypt";

my $tmp_dir = "tmp_new_license_please";
my $raw_license = "$tmp_dir/license.lic";
my $modified_license = "$tmp_dir/tmp_new_license.lic";

$ENV{'CVS_RSH'} = 'ssh';
$ENV{'PATH'} = '/usr/local/bin:' . $ENV {'PATH'};

chdir dirname $0;

my $where_are_we = getcwd ();

print "We are in $where_are_we\n";

rmtree ($tmp_dir);

mkdir ($tmp_dir) || die gmtime () . " Error: Unable to create temp directory $tmp_dir.\n";

print gmtime () . " Getting license from CVS....\n";

if (system ("/usr/local/bin/cvs -Q -z9 -d $cvs_root export -d $tmp_dir -r HEAD v4/etc 2>&1"))
{
  die gmtime () . " Error executing cvs export\n";
}

if ( ! (-e $raw_license && -r $raw_license))
{
  die gmtime () . " Error: $raw_license does not exist or is not readable\n";
}

open(FILE,$raw_license) || die ("Error: Cannot open file $raw_license to read");
my(@fcont) = <FILE>;
close FILE;

print gmtime () . " Creating new license $modified_license...\n";

# Local time + a week (604800 secs)
(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst)
  = localtime(time + 604800);

# Convert to FlexLM date style
my @abbr = qw( jan feb mar apr may jun jul aug sep oct nov dec );
$year += 1900;
my $date = "$mday-$abbr[$mon]-$year";

open(FOUT,">$modified_license") || die("Error: Cannot open file $modified_license to write");
foreach my $line (@fcont) {
    $line =~ s/permanent/$date/g;
    $line =~ s/10\.1\.\*\.\*/\*\.\*\.\*\.\*/g;
    print FOUT $line;
}
close FOUT;

# Generate a new signature
print gmtime () . " Signing new license $modified_license....\n";
my $flex_lm_output = ``;

if (system ("$flexlm_on_here $modified_license"))
{
  die gmtime () . " Error: some sort of titsup running $flexlm_on_here $modified_license";
}

print gmtime () . " Copying new license to $license_to_replace....\n";

if (system ("scp -Cq $modified_license $license_to_replace"))
{
  die gmtime () . " Error: failed to copy new license to $license_to_replace";
}

print gmtime () . " Finished successfully (hopefully) !!!\n";

rmtree ($tmp_dir);
