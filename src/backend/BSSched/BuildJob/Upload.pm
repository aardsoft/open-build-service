# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#

package BSSched::BuildJob::Upload;

use strict;
use warnings;

use BSUtil;
use BSSched::BuildResult;

=head1 NAME

BSSched::BuildJob::Upload - A Class to handle upload jobs

=head1 SYNOPSIS

=cut

=head2 jobfinished - process an upload job

 TODO: add description

=cut

sub jobfinished {
  my ($ectx, $job, $js) = @_;

  my $gctx = $ectx->{'gctx'};
  my $myarch = $gctx->{'arch'};
  my $changed = $gctx->{'changed_med'};
  my $myjobsdir = $gctx->{'myjobsdir'};
  my $info = readxml("$myjobsdir/$job", $BSXML::buildinfo, 1);
  my $jobdatadir = "$myjobsdir/$job:dir";
  if (!$info || ! -d $jobdatadir) {
    print "  - $job is bad\n";
    return;
  }
  if ($info->{'arch'} ne $myarch) {
    print "  - $job has bad arch\n";
    return;
  }
  my $projid = $info->{'project'};
  my $repoid = $info->{'repository'};
  my $packid = $info->{'package'};
  my $projpacks = $gctx->{'projpacks'};
  if (!$projpacks->{$projid}) {
    print "  - $job belongs to an unknown project\n";
    return;
  }
  my $pdata = ($projpacks->{$projid}->{'package'} || {})->{$packid};
  if (!$pdata) {
    print "  - $job belongs to an unknown package, discard\n";
    return;
  }
  my $prp = "$projid/$repoid";
  my $gdst = "$gctx->{'reporoot'}/$prp/$myarch";
  my $dst = "$gdst/$packid";
  mkdir_p($dst);
  print "  - $prp: $packid uploaded\n";
  my $useforbuildenabled = 1;
  $useforbuildenabled = BSUtil::enabled($repoid, $projpacks->{$projid}->{'useforbuild'}, $useforbuildenabled, $myarch);
  $useforbuildenabled = BSUtil::enabled($repoid, $pdata->{'useforbuild'}, $useforbuildenabled, $myarch);
  my $prpsearchpath = $gctx->{'prpsearchpath'}->{$prp};
  BSSched::BuildResult::update_dst_full($gctx, $prp, $packid, $jobdatadir, undef, $useforbuildenabled, $prpsearchpath);
  $changed->{$prp} = 2 if $useforbuildenabled;
  my $repounchanged = $gctx->{'repounchanged'};
  delete $repounchanged->{$prp} if $useforbuildenabled;
  $repounchanged->{$prp} = 2 if $repounchanged->{$prp};
  $changed->{$prp} ||= 1;
  unlink("$gdst/:repodone");
}

1;
