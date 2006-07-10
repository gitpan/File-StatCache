#!/usr/bin/perl -w
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

use strict;

use Test::More tests => 14;
use File::stat qw();

use File::StatCache qw( get_stat );

# Might need to adjust this for non-POSIX platforms like Win32
my $test_node = "/dev/null";

my $fs  = File::stat::stat( $test_node );
my $fsc = File::StatCache::get_stat( $test_node );

ok( defined $fsc, 'defined $fsc' );

is( $fsc->dev,     $fs->dev,     'dev'     );
is( $fsc->ino,     $fs->ino,     'ino'     );
is( $fsc->mode,    $fs->mode,    'mode'    );
is( $fsc->nlink,   $fs->nlink,   'nlink'   );
is( $fsc->uid,     $fs->uid,     'uid'     );
is( $fsc->gid,     $fs->gid,     'gid'     );
is( $fsc->rdev,    $fs->rdev,    'rdev'    );
is( $fsc->size,    $fs->size,    'size'    );
is( $fsc->atime,   $fs->atime,   'atime'   );
is( $fsc->mtime,   $fs->mtime,   'mtime'   );
is( $fsc->ctime,   $fs->ctime,   'ctime'   );
is( $fsc->blksize, $fs->blksize, 'blksize' );
is( $fsc->blocks,  $fs->blocks,  'blocks'  );

