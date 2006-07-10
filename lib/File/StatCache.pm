#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  (C) Paul Evans, 2006 -- leonerd@leonerd.org.uk

package File::StatCache;

use strict;

my $VERSION;
$VERSION = "0.01";

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
   get_stat
   stat

   get_item_mtime
);

use File::stat;

=head1 Name

C<File::StatCache> - a caching wrapper around the C<stat()> function

=head1 Overview

This module implements a cache of information returned by the C<stat()>
function. It stores the result of a C<stat()> syscall, to avoid putting excess
load on the host's filesystem in case many calls would be generated.

=head1 Timeout

By default the cache for any given filename will time out after 10 seconds; so
any request for information on the same name after this time will result in
another C<stat()> syscall, ensuring fresh information. This timeout is stored
in the package variable C<$File::StatCache::STATTIMEOUT>, and can be
modified by other modules if required.

=cut

my %laststattime;
my %stat_cache;

# Make $STATTIMEOUT externally visible, so other modules change it
our $STATTIMEOUT = 10;

=head1 Functions

=cut

=head2 C<B<sub> get_stat( I<$path>; I<$now> )>

=over 4

=over 8

=item C<I<$path>>

The path to the filesystem item to C<stat()>

=item C<I<$now>>

Optional. The time to consider as the current time

=item Returns

An object reference to a C<File::stat> object or C<undef>

=back

This function wraps a call to C<File::stat::stat()>, and caches the result. If
the requested file was C<stat()>ed within C<$STATTIMEOUT> seconds, it will not
be requested again, but the previous result (i.e. an object reference or
C<undef>) will be returned.

The C<I<$now>> parameter allows some other time than the current time to be
used, rather than re-request it from the kernel using the C<time()> function.
This allows a succession of tests to be performed in a consistent way, to
avoid a race condition.

=back

=cut

sub get_stat($;$)
# This stat always returns a File::stat object.
{
   my ( $path, $now ) = @_;

   $now = time() if( !defined $now );

   if ( !exists $laststattime{$path} ) {
      # Definitely new
      my $itemstat = File::stat::stat( $path );
      $laststattime{$path} = $now;
      if ( !defined $itemstat ) {
         return undef;
      }
      return $stat_cache{$path} = $itemstat;
   }

   if ( $now - $laststattime{$path} > $STATTIMEOUT ) {
      # Haven't checked it in a while - check again
      my $itemstat = File::stat::stat( $path );
      $laststattime{$path} = $now;
      if ( !defined $itemstat ) {
         delete $stat_cache{$path};
         return undef;
      }
      return $stat_cache{$path} = $itemstat;
   }

   if ( !exists $stat_cache{$path} ) {
      # Recently checked, and it didn't exist
      return undef;
   }

   # Recently checked; exists
   return $stat_cache{$path};
}

sub _stat($)
# The real call from outside - return an object or list as appropriate
{
   my ( $path ) = @_;

   my $stat = get_stat( $path );

   if( defined $stat ) {
      return $stat unless wantarray;

      # Need to construct the full annoying 13-element list
      return (
         $stat->dev,
         $stat->ino,
         $stat->mode,
         $stat->nlink,
         $stat->uid,
         $stat->gid,
         $stat->rdev,
         $stat->size,
         $stat->atime,
         $stat->mtime,
         $stat->ctime,
         $stat->blksize,
         $stat->blocks,
      );
   }
   else {
      return wantarray ? () : undef;
   }
}

=head2 C<B<sub> stat( I<$path> )>

=over 4

=over 8

=item C<I<$path>>

The path to the filesystem item to C<stat()>

=item Returns in scalar context

An object reference to a C<File::stat> object or C<undef>

=item Returns in list context

A 13-element list with fields as the core C<stat()> function would, or an
empty list

=back

This is a drop-in replacement for either the perl core C<stat()> function or
the C<File::stat::stat> function, depending whether it is called in list or
scalar context. It behaves identically to either of these functions, except
that it returns cached results if the cached value is recent enough.

Note that in the case of failure (i.e. C<undef> in scalar context, empty in
list context), the value of C<$!> is not reliable as the reason for error.
Error results are not currently cached.

=back

=cut

# Need to work around perl's warning of "Subroutine stat redefined at..."

no warnings;
*stat = \&_stat;
use warnings;

=head2 C<B<sub> get_item_mtime( I<$path>; I<$now> )>

=over 4

=over 8

=item C<I<$path>>

The path to the filesystem item to C<stat()>

=item C<I<$now>>

Optional. The time to consider as the current time

=item Returns

A scalar containing the item's last modification time, or C<undef>

=back

This function is equivalent to

 (scalar get_stat( $path, $now ))->mtime

=back

=cut

sub get_item_mtime($;$)
{
   my ( $path, $now ) = @_;

   my $itemstat = get_stat( $path, $now );
   return $itemstat->mtime if defined $itemstat;
   return undef;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 Limitations

=over 4

=item *

The shortcut tests (e.g. C<-f>, C<-r>, etc..) will not work with this module.

=item *

The "last results" filename C<_> cannot be used; the following code will not
work with this module:

  my @stats = stat( _ );

=back

=head1 Bugs

=over 4

=item *

The value of C<$!> is not preserved for per-file failures. When C<undef> or
the empty list are returned, the C<$!> value may not indicate the reason for
this particular failure.

=back

=head1 Author

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt>

=cut
